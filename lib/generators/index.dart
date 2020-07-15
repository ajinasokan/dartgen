import '../utils.dart';

void generateIndex(String dir, bool recursive) {
  var darts = listFiles(dir, recursive).map((i) => relativePath(i, dir));
  if (darts.length == 0) return;

  var exports = darts.map((i) => "export '$i';");
  String output = exports.join('\n');
  output = formatCode(output);
  saveFile(dir + '/index.dart', output);
  print("Done: $dir");
}
