import 'dart:io';
import 'package:path/path.dart';
import 'package:glob/glob.dart';
import 'package:analyzer/analyzer.dart';
import 'package:dart_style/dart_style.dart';
import 'package:dart_style/src/source_visitor.dart';

export 'package:analyzer/analyzer.dart';

// String scriptPath(String path) {
//   return normalize(dirname(Platform.script.toFilePath()) + '/' + path);
// }

List<String> listFiles(String path, [bool recursive = false]) {
  List<String> files = [];
  try {
    var dir = new Directory(path);

    final dartFile = new Glob("**.dart");

    List contents = dir.listSync(recursive: recursive);

    for (var fileOrDir in contents) {
      if (dartFile.matches(fileOrDir.path) &&
          basename(fileOrDir.path) != 'index.dart') {
        files.add(fileOrDir.path);
      }
    }
  } catch (e) {}
  files.sort();
  return files;
}

String relativePath(String path, String from) {
  return relative(path, from: from);
}

String fileName(String path) {
  return basename(path);
}

String fileContents(String path) {
  return File(path).readAsStringSync();
}

int lastModTime(String path) {
  return File(path).lastModifiedSync().millisecondsSinceEpoch;
}

CompilationUnit readFile(String path) {
  try {
    return parseDartFile(path);
  } catch (e) {
    return null;
  }
}

CompilationUnit readString(String code) {
  try {
    return parseCompilationUnit(code);
  } catch (e) {
    return null;
  }
}

void saveFile(String path, String data) {
  File(path).writeAsStringSync(data);
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

String getMethodName(MethodDeclaration field) {
  return field.name.name;
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

String getConstructorInput(FieldDeclaration field) {
  var mi = field.fields.variables.first.initializer as MethodInvocation;
  var val = mi.argumentList.arguments.first as SimpleStringLiteral;
  return val.stringValue;
}

String formatCode(String code) {
  return DartFormatter().format(code);
}

// String formatUnit(CompilationUnit unit) {
//   var source = SourceCode(source, uri: uri, isCompilationUnit: true);
//   var visitor = SourceVisitor(this, lineInfo, source);
//   var output = visitor.run(unit);
//   return output.text;
// }

String getTag(Declaration i) {
  if (i.metadata.length == 0) return '';

  Annotation ann = i.metadata[0];

  if (ann.name.toString() != 'pragma') return '';

  SimpleStringLiteral val = ann.arguments.arguments[0];

  return val.value;
}

String getTagArgs(Declaration i) {
  if (i.metadata.length == 0) return '';

  Annotation ann = i.metadata[0];

  if (ann.name.toString() != 'pragma') return '';

  if (ann.arguments.arguments.length < 2) return '';

  SimpleStringLiteral val = ann.arguments.arguments[1];

  return val.value;
}
