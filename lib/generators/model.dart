import 'package:dartgen/dartgen.dart';
import 'package:dartgen/generators/generator.dart';
import 'package:dartgen/models/index.dart';

import '../utils.dart';
import '../code_replacer.dart';

class ModelGenerator extends Generator {
  final GeneratorConfig? config;
  final EnumGenerator? enumGenerator;
  String? _lastGenerated;

  ModelGenerator({
    this.config,
    this.enumGenerator,
  });

  @override
  void init() {
    var darts = listFiles(config!.dir!, config!.recursive!);
    if (darts.isEmpty) return;

    darts.forEach((dartFile) => process(dartFile!));
  }

  @override
  bool shouldRun(WatchEvent event) =>
      event.path.startsWith(config!.dir!) && event.type != ChangeType.REMOVE;

  @override
  bool isLastGenerated(String path) => path == _lastGenerated;

  @override
  void resetLastGenerated() => _lastGenerated = null;

  @override
  void process(String dartFile) {
    print('Model: $dartFile');

    var replacer = CodeReplacer(fileReadString(dartFile));

    var code = parseDartFile(dartFile);
    if (code == null) return null;

    final primitives = <String>[
      'String',
      'num',
      'double',
      'bool',
      'int',
      'dynamic'
    ];

    var constants = enumGenerator?.names ?? {};
    var classElements = getClasses(code);

    for (var classElement in classElements) {
      var meta = getTag(classElement);
      if (meta != 'model') continue;
      var metaArgs = getTagArgs(classElement);

      var className = classElement.name.name.replaceAll('_', '');

      List<ClassMember> fields = classElement.members;

      var serialize = '';
      var toMap = '';
      var constructor = '';
      var usingToDouble = false;
      var usingToDecimal = false;
      final toDouble =
          'final toDouble = (val) => val == null ? null : val * 1.0;\n';
      final toDecimal =
          'final toDecimal = (val) => val == null ? null : Decimal.parse(val.toString());\n';
      var patcher = '';
      var extraCode = '';
      var clone = '';
      var patchWith = '';

      var output = StringBuffer();

      var methodsToDelete = <String>[
        'toMap',
        'toJson',
        'serialize',
        'patch',
        'patchWith',
        'init',
      ];
      var staticMethodsToDelete = <String>[
        'fromMap',
        'fromJson',
        'clone',
      ];
      var fieldsToDelete = <String>[];
      for (var member in fields) {
        if (member is ConstructorDeclaration &&
            (member.name == null || member.name.toString() == 'build')) {
          replacer.space(member.offset, member.length);
          continue;
        } else if (member is MethodDeclaration &&
            isStatic(member) &&
            staticMethodsToDelete.contains(getMethodName(member))) {
          replacer.space(member.offset, member.length);
          continue;
        } else if (member is MethodDeclaration &&
            methodsToDelete.contains(getMethodName(member))) {
          replacer.space(member.offset, member.length);
          continue;
        } else if (member is FieldDeclaration &&
            fieldsToDelete.contains(getFieldName(member))) {
          replacer.space(member.offset, member.length);
          continue;
        } else if (member is FieldDeclaration) {
          final isNullable =
              member.fields.type.toString().replaceAll('\$', '').contains('?');
          final type = member.fields.type
              .toString()
              .replaceAll('\$', '')
              .replaceAll('?', '');
          final name = member.fields.variables.first.name.name;
          final initializer = member.fields.variables.first.initializer;

          clone += '$name: from.$name,';
          patchWith += '$name = clone.$name;\n';

          if (isNullable) {
            constructor += 'this.$name,\n';
          } else {
            constructor += 'required this.$name,\n';
          }

          if (primitives.contains(type)) {
            serialize += "'$name': $name,";
          } else if (type == 'Type') {
            serialize += "'$name': 'Type<$name>',";
          } else if (type == 'double') {
            serialize += "'$name': $name,";
          } else if (type == 'Decimal') {
            serialize += "'$name': $name?.toDouble(),";
          } else if (constants.contains(type)) {
            serialize += "'$name': $name?.value,";
          } else if (type.contains('Map<')) {
            var types = type
                .substring(4, type.lastIndexOf('>'))
                .split(',')
                .map((e) => e.trim())
                .toList();

            var type1 = '?.serialize()';
            var type2 = '?.serialize()';

            if (primitives.contains(types[0].trim())) type1 = '';
            if (primitives.contains(types[1].trim())) type2 = '';

            if (types[0].startsWith('List<')) {
              var listPrimitive =
                  types[0].replaceAll('List<', '').replaceAll('>', '');
              if (primitives.contains(listPrimitive)) {
                type1 = '';
              }
            }

            if (types[1].startsWith('List<')) {
              var listPrimitive =
                  types[1].replaceAll('List<', '').replaceAll('>', '');
              if (primitives.contains(listPrimitive)) {
                type2 = '';
              }
            }

            if (type1 == '' && type2 == '') {
              serialize += "'$name': $name,";
            } else {
              serialize +=
                  "'$name': $name?.map((k, v) => MapEntry(k$type1, v$type2)),";
            }
          } else if (type == 'Map') {
            serialize += "'$name': $name,";
          } else if (type.contains('List<')) {
            var listPrimitive =
                type.replaceAll('List<', '').replaceAll('>', '');

            if (primitives.contains(listPrimitive)) {
              serialize += "'$name': $name,";
            } else if (constants.contains(listPrimitive)) {
              serialize +=
                  "'$name': $name?.map((dynamic i) => i?.value).toList(),";
            } else {
              serialize +=
                  "'$name': $name?.map((dynamic i) => i?.serialize()).toList(),";
            }
          } else {
            if (isNullable) {
              serialize += "'$name': $name?.serialize(),";
            } else {
              serialize += "'$name': $name.serialize(),";
            }
          }

          if (!getTag(member).contains('json')) continue;

          var key = getTag(member).split(':')[1].replaceAll('"', '');

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
            toMap += "'$key': $name?.toDouble(),\n";
            usingToDecimal = true;
          } else if (constants.contains(type)) {
            toMap += "'$key': $name?.value,\n";
            patcher += "$name = $type.parse(_data['$key'])";
          } else if (type.contains('Map<')) {
            var types = type.substring(4, type.lastIndexOf('>')).split(',');
            toMap += "'$key': $name,\n";
            patcher +=
                "$name = _data['$key'].map<${types[0]}, ${types[1]}>((k, v) => MapEntry(k as ${types[0]}, v as ${types[1]}))";
          } else if (type.contains('List<')) {
            var listPrimitive =
                type.replaceAll('List<', '').replaceAll('>', '');
            if (['String', 'num', 'bool', 'dynamic'].contains(listPrimitive)) {
              toMap += "'$key': $name,\n";
              patcher += "$name = _data['$key']?.cast<$listPrimitive>()";
            } else if (listPrimitive == 'int') {
              toMap += "'$key': $name,\n";
              patcher +=
                  "$name = _data['$key']?.map((i) => i ~/ 1)?.toList()?.cast<int>()";
            } else if (listPrimitive == 'double') {
              toMap += "'$key': $name,\n";
              patcher +=
                  "$name = _data['$key']?.map((i) => i * 1.0)?.toList()?.cast<double>()";
            } else if (constants.contains(listPrimitive)) {
              toMap += "'$key': $name?.map((i) => i.value)?.toList(),\n";
              patcher +=
                  "$name = _data['$key']?.map((i) => $listPrimitive.parse(i))?.toList()?.cast<$listPrimitive>()";
            } else {
              toMap += "'$key': $name?.map((i) => i.toMap())?.toList(),\n";
              patcher +=
                  "$name = _data['$key']?.map((i) => $listPrimitive.fromMap(i))?.toList()?.cast<$listPrimitive>()";
            }
          } else {
            if (isNullable) {
              toMap += "'$key': $name?.toMap(),";
            } else {
              toMap += "'$key': $name.toMap(),";
            }
            patcher += "$name = $type.fromMap(_data['$key'])";
          }

          patcher += ' ?? ${initializer ?? name};\n';
        }
      }

      output.writeln('\n$className();');

      if (constructor.isNotEmpty) {
        output.writeln('\n$className.build({');
        output.write(constructor);
        output.writeln('});');
      } else {
        output.writeln('\n$className();');
      }

      output.writeln('\nvoid patch(Map? _data) { if(_data == null) return;');
      if (usingToDouble) output.write(toDouble);
      if (usingToDecimal) output.write(toDecimal);
      output.write(patcher);
      output.writeln('}');

      output.writeln(
          '\static $className? fromMap(Map? data) { if(data == null) return null; return $className()..patch(data); }');

      output.writeln('\nMap<String, dynamic> toMap() => {');
      output.write(toMap);
      output.writeln('};');
      output.writeln('String toJson() => json.encode(toMap());');
      output.writeln('Map<String, dynamic> serialize() => {$serialize};');
      if (metaArgs.contains('patchWith')) {
        output.writeln('\nvoid patchWith($className clone) { $patchWith }');
      }
      if (metaArgs.contains('clone')) {
        output.writeln(
            '\static $className clone($className from) => $className.build($clone);');
      }
      output.writeln(extraCode);
      output.writeln(
          'static $className? fromJson(String data) => $className.fromMap(json.decode(data));');

      // output.writeln('}');

      replacer.add(
          classElement.offset + classElement.length - 1, 0, output.toString());
    }

    try {
      var output = formatCode(replacer.process());
      fileWriteString(dartFile, output);
    } catch (e) {
      print(e);
      return;
    }

    _lastGenerated = dartFile;
  }
}
