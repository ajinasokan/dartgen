import 'utils.dart';

void main() {
  var darts = listFiles('lib/screens').map((i) => fileName(i));
  if (darts.length == 0) return;

  var exports = darts.map((i) => "export '$i';");
  String output = exports.join('\n');
  output = formatCode(output);
  saveFile('lib/screens/index.dart', output);
  print("Screens.. Done.");
}
