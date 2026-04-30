import '../dartgenerate.dart';
import '../models/index.dart';
import '../code_replacer.dart';

class ModelGenerator extends Generator {
  final GeneratorConfig config;
  final String formatterVersion;
  final EnumGenerator? enumGenerator;
  String? _lastGenerated;

  ModelGenerator({
    required this.config,
    required this.formatterVersion,
    this.enumGenerator,
  });

  @override
  void init() {
    var darts = listFiles(config.dir!, config.recursive!);
    if (darts.isEmpty) return;

    darts.forEach((dartFile) => process(dartFile!));
  }

  @override
  bool shouldRun(WatchEvent event) =>
      event.path.startsWith(config.dir!) && event.type != ChangeType.REMOVE;

  @override
  bool isLastGenerated(String path) => path == _lastGenerated;

  @override
  void resetLastGenerated() => _lastGenerated = null;

  @override
  void process(String dartFile) {
    log('Model: $dartFile ');

    var replacer = CodeReplacer(fileReadString(dartFile));

    var code = parseDartFile(dartFile);
    if (code == null) return null;

    var enums = enumGenerator?.names ?? {};
    var classElements = getClasses(code);

    for (var classElement in classElements) {
      var meta = getTag(classElement);
      if (meta != 'model') continue;

      var metaArgs = getTagArgs(classElement);
      var className = classElement.name.lexeme;

      List<ClassMember> fields = classElement.members;

      final processes = <_FieldProcessor>[
        ConstructFields(className: className),
        MapOfFields(className: className, enums: enums),
        JsonOfFields(className: className),
        SerializeFields(enums: enums),
        CloneFields(className: className, enabled: metaArgs.contains('clone')),
        PatchFields(
            className: className, enabled: metaArgs.contains('patchWith')),
      ];

      for (var process in processes) {
        for (var member in fields) {
          if (process.isGenerated(member)) {
            replacer.space(member.offset, member.length);
          }
        }
      }

      var output = '';
      for (var process in processes) {
        output += process.generate(fields);
      }

      replacer.add(classElement.offset + classElement.length - 1, 0, output);
    }

    try {
      var output = formatCode(replacer.process(), formatterVersion);
      if (fileWriteString(dartFile, output)) {
        logDone();
      } else {
        logNoChange();
      }
    } catch (e) {
      print(e);
      return;
    }

    _lastGenerated = dartFile;
  }
}

abstract class _FieldProcessor {
  final primitives = <String>[
    'String',
    'num',
    'double',
    'bool',
    'int',
    'dynamic'
  ];

  bool isGenerated(ClassMember member);

  String generate(List<ClassMember> members);
}

class MapOfFields extends _FieldProcessor {
  final Set<String> enums;
  final String className;

  MapOfFields({
    required this.enums,
    required this.className,
  });

  @override
  bool isGenerated(ClassMember member) {
    return member is MethodDeclaration &&
        (getMethodName(member) == 'toMap' ||
            getMethodName(member) == 'fromMap' ||
            getMethodName(member) == 'patch');
  }

  @override
  String generate(List<ClassMember> members) {
    var toMap = '';
    var patcher = '';

    var usingToDouble = false;
    var usingToDecimal = false;
    final toDouble =
        'final toDouble = (val) => val == null ? null : val * 1.0;\n';
    final toDecimal =
        'final toDecimal = (val) => val == null ? null : Decimal.parse(val.toString());\n';

    for (var member in members) {
      if (!(member is FieldDeclaration)) continue;
      if (!getTag(member).contains('json')) continue;

      final key = getTag(member).split(':')[1].replaceAll('"', '');
      final isNullable = member.fields.type?.question != null;
      final dot = isNullable ? '?.' : '.';
      final typeName = (member.fields.type as NamedType).name.toString();
      final typeArgs =
          (member.fields.type as NamedType).typeArguments?.arguments;
      final leftType = (typeArgs?.elementAtOrNull(0) as NamedType?);
      final leftName = leftType?.name.toString() ?? 'dynamic';
      final leftDot = (leftType?.question?.toString() ?? '') + '.';
      final leftExcl = leftType?.question == null ? '!' : '';
      final rightType = (typeArgs?.elementAtOrNull(1) as NamedType?);
      final rightName = rightType?.name.toString() ?? 'dynamic';
      final rightDot = (rightType?.question?.toString() ?? '') + '.';
      final rightExcl = rightType?.question == null ? '!' : '';

      final type = member.fields.type
          .toString()
          .replaceAll('\$', '')
          .replaceAll('?', '');
      final name = member.fields.variables.first.name.lexeme;
      final initializer = member.fields.variables.first.initializer;

      if ([
        'String',
        'num',
        'bool',
        'int',
        'dynamic',
        'Map<String, dynamic>',
        'List<dynamic>'
      ].contains(type)) {
        toMap += "'$key': $name,\n";
        patcher += "$name = _data['$key']";
      } else if (type == 'double') {
        toMap += "'$key': $name,\n";
        patcher += "$name = toDouble(_data['$key'])";
        usingToDouble = true;
      } else if (type == 'Decimal') {
        toMap += "'$key': $name${dot}toDouble(),\n";
        patcher += "$name = toDecimal(_data['$key'])";
        usingToDecimal = true;
      } else if (enums.contains(type)) {
        toMap += "'$key': $name${dot}value,\n";
        patcher += "$name = $type.parse(_data['$key'])";
      } else if (typeName == 'Map') {
        // Determine if key needs string conversion for JSON serialization
        final isKeyString = leftName == 'String';
        final needsKeyConversion = !isKeyString && ['num', 'bool', 'int', 'double'].contains(leftName);

        // Helper to convert key to string in toMap
        final keyToString = needsKeyConversion ? 'k.toString()' : 'k';

        // Helper to parse key from string in patcher
        String parseKey(String keyType) {
          switch (keyType) {
            case 'int':
              return 'int.parse(k)';
            case 'double':
              return 'double.parse(k)';
            case 'num':
              return 'num.parse(k)';
            case 'bool':
              return "k == 'true'";
            default:
              return 'k as $keyType';
          }
        }

        final parsedKey = needsKeyConversion ? parseKey(leftName) : 'k as $leftName';

        if (['String', 'num', 'bool', 'dynamic'].contains(rightName)) {
          // For primitive values
          if (needsKeyConversion || leftName == 'dynamic') {
            toMap += "'$key': $name${dot}map<String, dynamic>((k,v) => MapEntry($keyToString, v)),\n";
          } else {
            toMap += "'$key': $name,\n";
          }
          patcher +=
              "$name = (_data['$key'] as Map?)?.map<$leftName, $rightName>((k, v) => MapEntry($parsedKey, v as $rightName))";
        } else if (rightName == 'int') {
          if (needsKeyConversion || leftName == 'dynamic') {
            toMap += "'$key': $name${dot}map<String, dynamic>((k,v) => MapEntry($keyToString, v)),\n";
          } else {
            toMap += "'$key': $name,\n";
          }
          patcher +=
              "$name = (_data['$key'] as Map?)?.map<$leftName, $rightName>((k, v) => MapEntry($parsedKey, v ~/ 1))";
        } else if (rightName == 'double') {
          if (needsKeyConversion || leftName == 'dynamic') {
            toMap += "'$key': $name${dot}map<String, dynamic>((k,v) => MapEntry($keyToString, v)),\n";
          } else {
            toMap += "'$key': $name,\n";
          }
          patcher +=
              "$name = (_data['$key'] as Map?)?.map<$leftName, $rightName>((k, v) => MapEntry($parsedKey, v * 1.0))";
        } else if (enums.contains(rightName)) {
          toMap +=
              "'$key': $name${dot}map<String, dynamic>((k,v) => MapEntry($keyToString, v${rightDot}value)),\n";
          patcher +=
              "$name = (_data['$key'] as Map?)?.map<$leftName, $rightName>((k, v) => MapEntry($parsedKey, $rightName.parse(v)$rightExcl))";
        } else if (rightName == 'List') {
          // Handle Map<K, List<V>> types
          final listValueType = (rightType?.typeArguments?.arguments.elementAtOrNull(0) as NamedType?);
          final listValueName = listValueType?.name.toString() ?? 'dynamic';
          final listValueDot = (listValueType?.question?.toString() ?? '') + '.';
          final listValueExcl = listValueType?.question == null ? '!' : '';
          // Get the full type string for the List (e.g., "List<Address>")
          final fullListType = rightType.toString().replaceAll('\$', '').replaceAll('?', '');

          if (['String', 'num', 'bool', 'dynamic', 'int', 'double'].contains(listValueName)) {
            if (needsKeyConversion || leftName == 'dynamic') {
              toMap += "'$key': $name${dot}map<String, dynamic>((k,v) => MapEntry($keyToString, v)),\n";
            } else {
              toMap += "'$key': $name,\n";
            }
            patcher +=
                "$name = (_data['$key'] as Map?)?.map<$leftName, $fullListType>((k, v) => MapEntry($parsedKey, (v as List?)?.cast<$listValueName>() ?? []))";
          } else if (enums.contains(listValueName)) {
            toMap +=
                "'$key': $name${dot}map<String, dynamic>((k,v) => MapEntry($keyToString, v${rightDot}map((i) => i${listValueDot}value).toList())),\n";
            patcher +=
                "$name = (_data['$key'] as Map?)?.map<$leftName, $fullListType>((k, v) => MapEntry($parsedKey, (v as List?)?.map((i) => $listValueName.parse(i)$listValueExcl).toList().cast<$listValueName>() ?? []))";
          } else {
            toMap +=
                "'$key': $name${dot}map<String, dynamic>((k,v) => MapEntry($keyToString, v${rightDot}map((i) => i${listValueDot}toMap()).toList())),\n";
            patcher +=
                "$name = (_data['$key'] as Map?)?.map<$leftName, $fullListType>((k, v) => MapEntry($parsedKey, (v as List?)?.map((i) => $listValueName.fromMap(i)$listValueExcl).toList().cast<$listValueName>() ?? []))";
          }
        } else {
          toMap +=
              "'$key': $name${dot}map<String, dynamic>((k,v) => MapEntry($keyToString, v${rightDot}toMap())),\n";
          patcher +=
              "$name = (_data['$key'] as Map?)?.map<$leftName, $rightName>((k, v) => MapEntry($parsedKey, $rightName.fromMap(v)$rightExcl))";
        }
      } else if (typeName == 'List') {
        if (['String', 'num', 'bool', 'dynamic'].contains(leftName)) {
          toMap += "'$key': $name,\n";
          patcher += "$name = _data['$key']?.cast<$leftName>()";
        } else if (leftName == 'int') {
          toMap += "'$key': $name,\n";
          patcher +=
              "$name = _data['$key']?.map((i) => i ~/ 1).toList().cast<int>()";
        } else if (leftName == 'double') {
          toMap += "'$key': $name,\n";
          patcher +=
              "$name = _data['$key']?.map((i) => i * 1.0).toList().cast<double>()";
        } else if (enums.contains(leftName)) {
          toMap +=
              "'$key': $name${dot}map((i) => i${leftDot}value).toList(),\n";
          patcher +=
              "$name = _data['$key']?.map((i) => $leftName.parse(i)$leftExcl).toList().cast<$leftName>()";
        } else {
          toMap +=
              "'$key': $name${dot}map((i) => i${leftDot}toMap()).toList(),\n";
          patcher +=
              "$name = _data['$key']?.map((i) => $leftName.fromMap(i)$leftExcl).toList().cast<$leftName>()";
        }
      } else {
        toMap += "'$key': $name${dot}toMap(),";
        patcher += "$name = $type.fromMap(_data['$key'])";
      }

      patcher += ' ?? ${initializer ?? name};\n';
    }

    return '''
    void patch(Map? _data) { if(_data == null) return;
      ${usingToDouble ? toDouble : ''}
      ${usingToDecimal ? toDecimal : ''}
      $patcher
    }

    static $className? fromMap(Map? data) { if(data == null) return null; return $className()..patch(data); }

    Map<String, dynamic> toMap() => {
      $toMap
    };    
    ''';
  }
}

class JsonOfFields extends _FieldProcessor {
  final String className;

  JsonOfFields({
    required this.className,
  });

  @override
  String generate(List<ClassMember> members) {
    return '''
    String toJson() => json.encode(toMap());
    static $className? fromJson(String data) => $className.fromMap(json.decode(data));
    ''';
  }

  @override
  bool isGenerated(ClassMember member) {
    return member is MethodDeclaration &&
        (getMethodName(member) == 'toJson' ||
            getMethodName(member) == 'fromJson');
  }
}

class SerializeFields extends _FieldProcessor {
  final Set<String> enums;

  SerializeFields({
    required this.enums,
  });

  @override
  String generate(List<ClassMember> members) {
    var serialize = '';

    for (var member in members) {
      if (!(member is FieldDeclaration)) continue;

      final isNullable = member.fields.type?.question != null;
      final dot = isNullable ? '?.' : '.';
      final type = member.fields.type
          .toString()
          .replaceAll('\$', '')
          .replaceAll('?', '');
      final name = member.fields.variables.first.name.lexeme;

      if (primitives.contains(type)) {
        serialize += "'$name': $name,";
      } else if (type == 'Type') {
        serialize += "'$name': 'Type<$name>',";
      } else if (type == 'double') {
        serialize += "'$name': $name,";
      } else if (type == 'Decimal') {
        serialize += "'$name': $name${dot}toDouble(),";
      } else if (enums.contains(type)) {
        serialize += "'$name': $name${dot}value,";
      } else if (type.contains('Map<')) {
        var types = type
            .substring(4, type.lastIndexOf('>'))
            .split(',')
            .map((e) => e.trim())
            .toList();

        final keyType = types[0].trim();
        final valueType = types[1].trim();

        // Check if value type is nullable (from original type string)
        final originalValueType = (member.fields.type as NamedType)
            .typeArguments
            ?.arguments
            .elementAtOrNull(1);
        final isValueNullable = originalValueType?.question != null;
        final valueDot = isValueNullable ? '?.' : '.';

        // Determine if key needs string conversion for JSON serialization
        final isKeyString = keyType == 'String';
        final needsKeyConversion =
            !isKeyString && ['num', 'bool', 'int', 'double'].contains(keyType);
        final keyExpr = needsKeyConversion ? 'k.toString()' : 'k';

        var valueExpr = 'v${valueDot}serialize()';

        if (primitives.contains(valueType)) {
          valueExpr = 'v';
        } else if (enums.contains(valueType)) {
          valueExpr = 'v${valueDot}value';
        } else if (valueType.startsWith('List<')) {
          var listPrimitive =
              valueType.replaceAll('List<', '').replaceAll('>', '');
          if (primitives.contains(listPrimitive)) {
            valueExpr = 'v';
          } else if (enums.contains(listPrimitive)) {
            valueExpr = 'v${valueDot}map((i) => i.value).toList()';
          } else {
            valueExpr = 'v${valueDot}map((i) => i.serialize()).toList()';
          }
        }

        if (!needsKeyConversion && valueExpr == 'v') {
          serialize += "'$name': $name,";
        } else {
          serialize +=
              "'$name': $name${dot}map<String, dynamic>((k, v) => MapEntry($keyExpr, $valueExpr)),";
        }
      } else if (type == 'Map') {
        serialize += "'$name': $name,";
      } else if (type.contains('List<')) {
        final dotMap = isNullable ? '?.map' : '.map';
        final listPrimitive = type.replaceAll('List<', '').replaceAll('>', '');

        if (primitives.contains(listPrimitive)) {
          serialize += "'$name': $name,";
        } else if (enums.contains(listPrimitive)) {
          serialize += "'$name': $name$dotMap((i) => i.value).toList(),";
        } else {
          serialize += "'$name': $name$dotMap((i) => i.serialize()).toList(),";
        }
      } else {
        if (isNullable) {
          serialize += "'$name': $name?.serialize(),";
        } else {
          serialize += "'$name': $name.serialize(),";
        }
      }
    }

    return 'Map<String, dynamic> serialize() => {$serialize};';
  }

  @override
  bool isGenerated(ClassMember member) {
    return member is MethodDeclaration && getMethodName(member) == 'serialize';
  }
}

class CloneFields extends _FieldProcessor {
  final String className;
  final bool enabled;

  CloneFields({
    required this.className,
    required this.enabled,
  });

  @override
  String generate(List<ClassMember> members) {
    var clone = '';
    if (!enabled) return clone;

    for (var member in members) {
      if (!(member is FieldDeclaration)) continue;
      final name = member.fields.variables.first.name.lexeme;
      clone += '$name: from.$name,';
    }
    return 'static $className clone($className from) => $className.build($clone);';
  }

  @override
  bool isGenerated(ClassMember member) {
    return member is MethodDeclaration && getMethodName(member) == 'clone';
  }
}

class PatchFields extends _FieldProcessor {
  final String className;
  final bool enabled;

  PatchFields({
    required this.className,
    required this.enabled,
  });

  @override
  String generate(List<ClassMember> members) {
    var patchWith = '';
    if (!enabled) return patchWith;

    for (var member in members) {
      if (!(member is FieldDeclaration)) continue;
      final name = member.fields.variables.first.name.lexeme;
      patchWith += '$name = clone.$name;\n';
    }
    return 'void patchWith($className clone) { $patchWith }';
  }

  @override
  bool isGenerated(ClassMember member) {
    return member is MethodDeclaration && getMethodName(member) == 'patchWith';
  }
}

class ConstructFields extends _FieldProcessor {
  final String className;

  ConstructFields({
    required this.className,
  });

  @override
  String generate(List<ClassMember> members) {
    var constructor = '';
    for (var member in members) {
      if (!(member is FieldDeclaration)) continue;
      final name = member.fields.variables.first.name.lexeme;
      final isNullable = member.fields.type?.question != null;
      if (isNullable) {
        constructor += 'this.$name,\n';
      } else {
        constructor += 'required this.$name,\n';
      }
    }
    return '''
      $className();

      $className.build({
        $constructor
      });
      
    ''';
  }

  @override
  bool isGenerated(ClassMember member) {
    return member is ConstructorDeclaration &&
        (member.name == null || member.name.toString() == 'build');
  }
}
