import '../utils.dart';
import '../code_replacer.dart';

Map<String, int> _lastModified = {};

List<String> getConstants() {
  List<String> constants = [];
  var darts = listFiles('lib/constants');

  darts.forEach((dartFile) {
    var code = readFile(dartFile);

    getClasses(code).forEach((classItem) {
      var enumName = getClassName(classItem);
      constants.add(enumName);
    });
  });

  return constants;
}

void serializerGen(CodeReplacer replacer, List<ClassDeclaration> classElements,
    String namespace) {
  var constants = getConstants();

  for (ClassDeclaration classElement in classElements) {
    var meta = getTag(classElement);
    if (meta != 'model') return;

    var className = classElement.name.name.replaceAll('_', '');
    var classNameWithT = className;
    if (classElement.typeParameters != null) {
      classNameWithT += classElement.typeParameters.toString();
    }

    var extendsTo = classElement.extendsClause?.superclass?.name?.name;
    // if (extendsTo == null) {
    //   output.writeln('class $classNameWithT {');
    // } else {
    //   output.writeln('class $classNameWithT extends $extendsTo {');
    // }
    // output
    //     .writeln('class $classNameWithT extends $namespace.$classNameWithT {');

    List<ClassMember> fields = classElement.members;
    // classElement.members.where((i) => getTag(i).contains('json'));

    String serialize = '';
    String toMap = '';
    String fromMap = '';
    String constructor = '';
    String initializer = '';
    String patcher = '';
    String extraCode = '';
    String clone = '';

    var output = StringBuffer();

    var methodsToDelete = <String>['toMap', 'toJson', 'serialize'];
    var fieldsToDelete = <String>[];
    for (ClassMember member in fields) {
      if (member is ConstructorDeclaration) {
        replacer.space(member.offset, member.length);
        continue;
      } else if (member is FieldDeclaration &&
          fieldsToDelete.contains(getFieldName(member))) {
        replacer.space(member.offset, member.length);
        continue;
      } else if (member is MethodDeclaration &&
          methodsToDelete.contains(getMethodName(member))) {
        replacer.space(member.offset, member.length);
        continue;
      } else if (member is FieldDeclaration) {
        FieldDeclaration field = member as FieldDeclaration;

        var type = field.fields.type.toString().replaceAll('\$', '');
        var name = field.fields.variables.first.name.name;

        // output.writeln('$type $name;');
        constructor += 'this.$name,\n';
        clone += '$name: from.$name,';

        if (field.fields.variables.first.childEntities.length == 3) {
          if (constants.contains(type)) {
            initializer += 'if($name?.value == null) ';
          } else {
            initializer += 'if($name == null) ';
          }
          initializer += field.fields.variables.first.toString() + ';';
        }

        if (["String", "num", "bool", "int", "dynamic"].contains(type)) {
          serialize += '"$name": $name,';
        } else if (type == 'double') {
          serialize += '"$name": $name,';
        } else if (type == 'Decimal') {
          serialize += '"$name": $name?.toDouble(),';
        } else if (constants.contains(type)) {
          serialize += '"$name": $name?.value,';
        } else if (type.contains("Map<")) {
          var types = type.substring(4, type.lastIndexOf(">")).split(",");

          var type1 = "?.serialize()";
          var type2 = "?.serialize()";

          if (["String", "num", "bool", "int", "dynamic", "List<dynamic>"]
              .contains(types[0].trim())) type1 = "";
          if (["String", "num", "bool", "int", "dynamic", "List<dynamic>"]
              .contains(types[1].trim())) type2 = "";

          if (type1 == "" && type2 == "") {
            serialize += '"$name": $name,';
          } else {
            serialize +=
                '"$name": $name.map((k, v) => MapEntry(k$type1, v$type2)),';
          }
        } else if (type == 'Map') {
          serialize += '"$name": $name,';
        } else if (type.contains("List<")) {
          var listPrimitive = type.replaceAll('List<', '').replaceAll('>', '');

          if (["String", "num", "bool", "dynamic"].contains(listPrimitive)) {
            serialize += '"$name": $name,';
          } else if (constants.contains(listPrimitive)) {
            serialize +=
                '"$name": $name.map((dynamic i) => i?.value).toList(),';
          } else {
            serialize +=
                '"$name": $name.map((dynamic i) => i?.serialize()).toList(),';
          }
        } else {
          serialize += '"$name": $name?.serialize(),';
        }

        if (!getTag(field).contains('json')) continue;

        var key = getTag(field).split(':')[1].replaceAll('"', '');

        if ([
          "String",
          "num",
          "bool",
          "int",
          "dynamic",
          "Map<String, dynamic>",
          "List<dynamic>"
        ].contains(type)) {
          toMap += '"$key": $name,\n';
          fromMap += '$name: data["$key"],\n';
          patcher += '$name = _data["$key"];\n';
        } else if (type == 'double') {
          toMap += '"$key": $name,\n';
          fromMap += '$name: data["$key"] * 1.0,\n';
          patcher += '$name = _data["$key"] * 1.0;\n';
        } else if (type == 'Decimal') {
          toMap += '"$key": $name?.toDouble(),\n';
          fromMap += '$name: Decimal.parse(data["$key"].toString()),\n';
          patcher += '$name = Decimal.parse(_data["$key"].toString());\n';
        } else if (constants.contains(type)) {
          toMap += '"$key": $name?.value,\n';
          fromMap += '$name: $type(data["$key"]),\n';
          patcher += '$name = $type(_data["$key"]);\n';
        } else if (type.contains("Map<")) {
          var types = type.substring(4, type.lastIndexOf(">")).split(",");

          toMap += '"$key": $name,\n';
          fromMap +=
              '$name: data["$key"].map<${types[0]}, ${types[1]}>((k, v) => MapEntry(k as ${types[0]}, v as ${types[1]})),\n';
          patcher +=
              '$name = _data["$key"].map<${types[0]}, ${types[1]}>((k, v) => MapEntry(k as ${types[0]}, v as ${types[1]}));\n';
        } else if (type.contains("List<")) {
          var listPrimitive = type.replaceAll('List<', '').replaceAll('>', '');
          if (["String", "num", "bool", "dynamic"].contains(listPrimitive)) {
            toMap += '"$key": $name,\n';
            fromMap += '$name: (data["$key"] ?? []).cast<$listPrimitive>(),\n';
            patcher +=
                '$name = (_data["$key"] ?? []).cast<$listPrimitive>();\n';
          } else if (listPrimitive == "int") {
            toMap += '"$key": $name,\n';
            fromMap +=
                '$name: (data["$key"] ?? []).map((i) => i ~/ 1).toList().cast<int>(),\n';
            patcher +=
                '$name = (_data["$key"] ?? []).map((i) => i ~/ 1).toList().cast<int>();\n';
          } else if (listPrimitive == "double") {
            toMap += '"$key": $name,\n';
            fromMap +=
                '$name: (data["$key"] ?? []).map((i) => i * 1.0).toList().cast<double>(),\n';
            patcher +=
                '$name = (_data["$key"] ?? []).map((i) => i * 1.0).toList().cast<double>();\n';
          } else if (constants.contains(listPrimitive)) {
            toMap += '"$key": $name.map((i) => i.value).toList(),\n';
            fromMap +=
                '$name: (data["$key"] ?? []).map((i) => new $listPrimitive(i)).toList().cast<$listPrimitive>(),\n';
            patcher +=
                '$name = (_data["$key"] ?? []).map((i) => new $listPrimitive(i)).toList().cast<$listPrimitive>();\n';
          } else {
            toMap += '"$key": $name.map((i) => i.toMap()).toList(),\n';
            fromMap +=
                '$name: (data["$key"] ?? []).map((i) => $listPrimitive.fromMap(i)).toList().cast<$listPrimitive>(),\n';
            patcher +=
                '$name = (_data["$key"] ?? []).map((i) => $listPrimitive.fromMap(i)).toList().cast<$listPrimitive>();\n';
          }
        } else {
          toMap += '"$key": $name.toMap(),';
          fromMap += '$name: $type.fromMap(data["$key"]),\n';
          patcher += '$name = $type.fromMap(_data["$key"]);\n';
        }
      }
    }

    if (constructor.isNotEmpty) {
      output.writeln('\n$className({');
      output.write(constructor);
      if (initializer.isNotEmpty) {
        output.writeln('}){');
        output.writeln(initializer);
        output.writeln('}');
      } else {
        output.writeln('});');
      }
    } else {
      output.writeln('\n$className();');
    }

    if (extendsTo == "Response") {
      output.writeln('\nvoid parse() {\n var _data = this.json(); \n');
      output.write(patcher);
      output.writeln('}');
    }

    output.writeln(
        '\nfactory $className.fromMap(Map data) { if(data == null) return null; return $className(');
    output.write(fromMap);
    output.writeln('); }');
    output.writeln('\nMap<String, dynamic> toMap() => {');
    output.write(toMap);
    output.writeln('};');
    output.writeln('String toJson() => json.encode(toMap());');
    output.writeln('Map<String, dynamic> serialize() => {$serialize};');
    output.writeln(
        '\nfactory $className.clone($className from) => $className($clone);');
    output.writeln(extraCode);
    output.writeln(
        'factory $className.fromJson(String data) => $className.fromMap(json.decode(data));');

    // output.writeln('}');

    replacer.add(
        classElement.offset + classElement.length - 1, 0, output.toString());
  }
}

void generateModel(String dir) {
  var darts = listFiles(dir);
  if (darts.length == 0) return;

  darts.forEach((dartFile) {
    _lastModified[dartFile] ??= 0;
    if (lastModTime(dartFile) <= _lastModified[dartFile]) {
      return;
    }
    print(dartFile);
    var replacer = CodeReplacer(fileContents(dartFile));

    var code = readFile(dartFile);
    if (code == null) return;

    var namespace = fileName(dartFile).replaceFirst(".dart", "");
    serializerGen(replacer, getClasses(code), namespace);

    var output = formatCode(replacer.process());
    saveFile(dartFile, output);

    _lastModified[dartFile] = lastModTime(dartFile);
  });

  print("Done: $dir");
}
