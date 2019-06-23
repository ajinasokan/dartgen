import 'package:analyzer/analyzer.dart';

import 'utils.dart';

String mutationsPath = scriptPath('../mutations/');
List<String> mutationTypes = [];

class Mutation {
  const Mutation();
}

String mutationGen(List<FunctionDeclaration> mutations, String namespace) {
  var output = new StringBuffer();

  for (FunctionDeclaration mutation in mutations) {
    var paramsWithType = mutation.functionExpression.parameters.toString();

    var params = "";
    if (paramsWithType.startsWith("({")) {
      params = mutation.functionExpression.parameters.parameters
          .map((i) => i.identifier.toString() + ":" + i.identifier.toString())
          .join(',');
    } else {
      params = mutation.functionExpression.parameters.parameters
          .map((i) => i.identifier.toString())
          .join(',');
    }

    var returnType = mutation.returnType.toString();
    var mutationName = mutation.name.toString().replaceAll('_', '');
//    var mutationGeneric = '';
//    if (mutation.returnType.childEntities.length > 1) {
//      TypeArgumentList generics =
//          mutation.returnType.childEntities.toList()[1] as TypeArgumentList;
//      mutationGeneric = '<' + generics.arguments[0].toString() + '>';
//    }

    mutationTypes.add(mutationName);
    if (returnType == 'void') {
      output.writeln('Future<$returnType> ' +
          mutationName +
          ' $paramsWithType async { $namespace.${mutationName}($params); notify(Mutations.${mutationName}); }');
    } else if (returnType == 'Future<void>') {
      output.writeln('$returnType ' +
          mutationName +
          ' $paramsWithType async { await $namespace.${mutationName}($params); notify(Mutations.${mutationName}); }');
    } else if (returnType.startsWith('Future<Request')) {
      // async Request
      var reqType = returnType.substring(7, returnType.length - 1);
      output.writeln('Future<void> ' +
          mutationName +
          ' $paramsWithType async { $reqType out = await $namespace.${mutationName}($params); if(out == null) return; notify(Mutations.${mutationName});' +
          ' out.onSuccess = ${mutationName}Success; out.onFail = ${mutationName}Fail; await out.send();  }');
    } else if (returnType.startsWith('Request')) {
      // sync Request
      output.writeln('Future<void> ' +
          mutationName +
          ' $paramsWithType async { $returnType out = $namespace.${mutationName}($params); if(out == null) return; notify(Mutations.${mutationName});' +
          ' out.onSuccess = ${mutationName}Success; out.onFail = ${mutationName}Fail; await out.send();  }');
    } else {
      output.writeln('$returnType ' +
          mutationName +
          ' $paramsWithType { $returnType out = $namespace.${mutationName}($params); notify(Mutations.${mutationName}); return out; }');
    }
  }

  return '$output';
}

void main() {
  var darts = listFiles('../mutations');
  String output = '';

  output += "import 'dart:io';";
  output += "import 'dart:async';";
  output += "import 'package:kite/constants/index.dart';";
  output += "import 'package:kite/models/index.dart';";
  output += "import 'package:kite/framework/http.dart';";
  output += "import 'package:kite/framework/redux.dart';";

  String mutationCode = '';
  mutationTypes.clear();
  darts.forEach((dartFile) {
    var name = fileName(dartFile).replaceAll('.dart', '');
    var namespace = name + 'Mutations';
    var code = readFile(dartFile);

    output += "import '$name.dart' as ${namespace};\n";

    mutationCode += mutationGen(getMethods(code), namespace);
  });

  output += mutationCode;

  String types = 'enum Mutations{';
  types += mutationTypes.join(',');
  types += '}';

  output += types;

  output = formatCode(output);
  saveFile('../mutations/index.dart', output);
  print("Mutations.. Done.");
}
