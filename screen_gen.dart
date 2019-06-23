import 'package:analyzer/analyzer.dart';

import 'utils.dart';

String screensPath = scriptPath('../screens/');
List<String> screenTypes = [];

String screenGen(List<ClassDeclaration> screens, String namespace) {
  if (screens.length == 0) return "";

  var output = new StringBuffer();

  for (ClassDeclaration screen in screens) {
    String animDecl = "";
    String animVar = "";

//    if (screen.extendsClause.superclass.name.toString() == "SheetScreen") {
//      animDecl = "final OverlayEntry sheet; final BuildContext ctx;";
//      animVar = "this.sheet, this.ctx";
//    }

    if (screen.extendsClause.superclass.name.toString() == "TabScreen") {
      animDecl = "final TabController tabController;";
      animVar = "this.tabController";
    }

    var className = screen.name.name.replaceAll('_', '');

    output.writeln('class $className extends  StatefulWidget {');
    output.writeln('''
      $animDecl
      const $className($animVar); // : super(key: Navigation.getKey(Screens.$className));
      @override
      State<StatefulWidget> createState() {
        var screen = $namespace.$className($animVar);
        screen.screenName = Screens.$className;
        Navigation.screenHandles[Screens.$className] = screen;
        subscribe(screen, screen.listenTo);
        return screen;
      }
    ''');

    screenTypes.add(className);

    output.writeln('}');
  }

  return '$output';
}

void main() {
  var darts = listFiles('../screens');
  String output = '';

  output += "import 'package:flutter/material.dart';";
  output += "import 'package:kite/framework/index.dart';";
  output += "import 'package:kite/framework/navigation.dart';";

  String widgetCode = '';
  screenTypes.clear();
  darts.forEach((dartFile) {
    var name = fileName(dartFile).replaceAll('.dart', '');
    var namespace = name + 'Screen';
    var code = readFile(dartFile);

    output += "import '$name.dart' as $namespace;\n";

    widgetCode += screenGen(getClasses(code), namespace);
  });

  output += widgetCode;

  String types = 'enum Screens {';
  types += screenTypes.join(',');
  types += '}';

  output += types;

  output = formatCode(output);
  saveFile('../screens/index.dart', output);
  print("Screens.. Done.");
}
