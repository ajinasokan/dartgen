import 'dart:io';
import 'package:path/path.dart';
import 'package:glob/glob.dart';
import 'package:analyzer/analyzer.dart';
import 'package:dart_style/dart_style.dart';

export 'package:analyzer/analyzer.dart';

// String scriptPath(String path) {
//   return normalize(dirname(Platform.script.toFilePath()) + '/' + path);
// }

List<String> listFiles(String path) {
  List<String> files = [];
  try {
    var dir = new Directory(path);

    final dartFile = new Glob("**.dart");

    List contents = dir.listSync();

    for (var fileOrDir in contents) {
      if (dartFile.matches(fileOrDir.path) &&
          basename(fileOrDir.path) != 'index.dart') {
        files.add(fileOrDir.path);
      }
    }
  } catch (e) {}

  return files;
}

String fileName(String path) {
  return basename(path);
}

CompilationUnit readFile(String path) {
  try {
    return parseDartFile(path);
  } catch (e) {
    return null;
  }
}

void saveFile(String path, String data) {
  new File(path).writeAsString(data);
}

List<ClassDeclaration> getClasses(CompilationUnit code) {
  return code.childEntities
      .where((i) => i is ClassDeclaration)
      .toList()
      .cast<ClassDeclaration>();
}

List<FunctionDeclaration> getMethods(CompilationUnit code) {
  return code.childEntities
      .where((i) => i is FunctionDeclaration)
      .toList()
      .cast<FunctionDeclaration>();
}

String getClassName(ClassDeclaration classdec) {
  return classdec.name.name;
}

String getFieldName(FieldDeclaration field) {
  return field.fields.variables.first.name.name;
}

String getFieldType(FieldDeclaration field) {
  return field.fields.type.toString();
}

String getFieldValue(FieldDeclaration field) {
  return field.fields.variables.first.initializer.toString();
}

String formatCode(String code) {
  try {
    return new DartFormatter().format(code);
  } catch (e) {
    return code;
  }
}

String getTag(Declaration i) {
  if (i.metadata.length == 0) return '';

  Annotation ann = i.metadata[0];

  if (ann.name.toString() != 'pragma') return '';

  SimpleStringLiteral val = ann.arguments.arguments[0];

  return val.value;
}
