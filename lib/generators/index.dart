import 'package:dartgen/generators/generator.dart';

class IndexGenerator extends DirectoryGenerator {
  @override
  String process(List<String> paths) {
    if (paths.isEmpty) return null;
    var exports = paths.map((i) => "export '$i';");
    return exports.join('\n');
  }
}
