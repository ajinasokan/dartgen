import 'package:dartgen/generators/generator.dart';
import 'package:dartgen/models/index.dart';
import '../utils.dart';

class IndexGenerator extends Generator {
  final GeneratorConfig config;
  String _lastGenerated;

  IndexGenerator({this.config});

  @override
  void init() {
    process(config.dir);
  }

  @override
  bool shouldRun(WatchEvent event) =>
      event.path.startsWith(config.dir) && event.type != ChangeType.MODIFY;

  @override
  bool isLastGenerated(String path) => path == _lastGenerated;

  @override
  void resetLastGenerated() => _lastGenerated = null;

  @override
  void process(String path) {
    print('Index: ${config.dir}');
    var paths = listFiles(config.dir, config.recursive)
        .map((i) => relativePath(i, config.dir))
        .toList();
    if (paths.isEmpty) return null;
    final exports = paths.map((i) => "export '$i';");
    final outFile = config.dir + '/index.dart';

    try {
      var output = formatCode(exports.join('\n'));
      saveFile(outFile, output);
    } catch (e) {
      print(e);
      return;
    }

    _lastGenerated = outFile;
  }
}
