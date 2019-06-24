import 'utils.dart';

void main() {
  var comps = listFiles('lib/components').map((i) => fileName(i));

  if (comps.length == 0) return;

  // var imports = comps.map((i) => "import '$i';");
  var exports = comps.map((i) => "export '$i';");
  //imports.join('\n') + '\n' +
  String output = exports.join('\n');
  output = formatCode(output);
  saveFile('lib/components/index.dart', output);
  print("Components.. Done.");
}
