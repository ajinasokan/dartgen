import 'utils.dart';

void main() {
  var comps = listFiles('../components').map((i) => fileName(i));

  // var imports = comps.map((i) => "import '$i';");
  var exports = comps.map((i) => "export '$i';");
  //imports.join('\n') + '\n' +
  String output = exports.join('\n');
  output = formatCode(output);
  saveFile('../components/index.dart', output);
  print("Components.. Done.");
}
