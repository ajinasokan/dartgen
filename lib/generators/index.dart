import '../utils.dart';

void generateIndex(String dir) {
  var darts = listFiles(dir).map((i) => fileName(i));
  if (darts.length == 0) return;

  var exports = darts.map((i) => "export '$i';");
  String output = exports.join('\n');
  output = formatCode(output);
  saveFile('lib/framework/index.dart', output);
  print("Done: $dir");
}
