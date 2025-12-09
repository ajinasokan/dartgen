import 'dart:io';
import 'package:glob/glob.dart';
import 'package:dart_style/dart_style.dart';
import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:pub_semver/pub_semver.dart' show Version;

export 'package:analyzer/dart/ast/ast.dart';

List<String?> listFiles(String path,
    [bool recursive = false, bool allFiles = false]) {
  final files = <String?>[];
  try {
    var dir = Directory(path);

    final dartFile = allFiles ? Glob('**') : Glob('**.dart');

    List contents = dir.listSync(recursive: recursive);

    for (var fileOrDir in contents) {
      if (dartFile.matches(fileOrDir.path)) {
        files.add(fileOrDir.path);
      }
    }
  } catch (e) {
    print('Exception while listing files: $e');
  }
  files.sort();
  return files;
}

String fileReadString(String path) => File(path).readAsStringSync();

bool fileWriteString(String path, String data) {
  var fileString = "";
  try {
    fileString = fileReadString(path);
  } catch (e) {
    // file doesn't exist, write it
  }
  if (fileString != data) {
    File(path).writeAsStringSync(data);
    return true;
  } else {
    return false;
  }
}

void log(String content) {
  stdout.write(content);
}

void logDone() => logln('\x1b[92mDONE\x1b[0m');
void logNoChange() => logln('\x1b[36mNO CHANGE\x1b[0m');

void logln(String content) {
  stdout.write(content + '\n');
}

CompilationUnit? parseDartFile(String path) {
  try {
    return parseString(content: fileReadString(path)).unit;
  } catch (e) {
    return null;
  }
}

List<ClassDeclaration> getClasses(CompilationUnit code) {
  return code.childEntities
      .whereType<ClassDeclaration>()
      .toList()
      .cast<ClassDeclaration>();
}

List<FunctionDeclaration> getMethods(CompilationUnit code) {
  return code.childEntities
      .whereType<FunctionDeclaration>()
      .toList()
      .cast<FunctionDeclaration>();
}

String getClassName(ClassDeclaration classdec) {
  return classdec.name.lexeme;
}

bool isStatic(MethodDeclaration field) {
  return field.isStatic;
}

String getMethodName(MethodDeclaration field) {
  return field.name.lexeme;
}

String getFieldName(FieldDeclaration field) {
  return field.fields.variables.first.name.lexeme;
}

String getFieldType(FieldDeclaration field) {
  return field.fields.type.toString();
}

String getFieldValue(FieldDeclaration field) {
  return field.fields.variables.first.initializer.toString();
}

String? getConstructorInput(FieldDeclaration field) {
  var mi = field.fields.variables.first.initializer as MethodInvocation;
  var val = mi.argumentList.arguments.first as SimpleStringLiteral;
  return val.stringValue;
}

String formatCode(String code, String version) {
  ;
  return DartFormatter(
    languageVersion: switch (version) {
      '' => Version(3, 0, 0),
      _ => Version.parse(version),
    },
  ).format(code);
}

String getTag(Declaration i) {
  if (i.metadata.isEmpty) return '';

  final annotation = i.metadata[0];
  if (annotation.name.toString() != 'pragma') return '';
  final val = annotation.arguments!.arguments[0] as SimpleStringLiteral;

  return val.value;
}

List<String> getTagArgs(Declaration i) {
  if (i.metadata.isEmpty) return [];

  final annotation = i.metadata[0];
  if (annotation.name.toString() != 'pragma') return [];
  if (annotation.arguments!.arguments.length < 2) return [];
  final val = annotation.arguments!.arguments[1] as SimpleStringLiteral;

  return val.value.split(',');
}
