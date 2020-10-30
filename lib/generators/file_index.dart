import 'package:dartgen/generators/generator.dart';
import 'package:dartgen/models/index.dart';
import 'package:path/path.dart' as p;
import '../utils.dart';

class FileIndexGenerator extends Generator {
  final GeneratorConfig config;
  String _lastGenerated;

  FileIndexGenerator({this.config});

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
    final outFileName = config.outputFile ?? 'index.dart';
    var paths = listFiles(config.dir, config.recursive)
        .map((i) => p.relative(i, from: config.dir))
        .toList();
    paths.remove(outFileName);
    if (paths.isEmpty) return null;
    final exports = paths.map((i) => "export '$i';");
    final outFilePath = p.join(config.dir, outFileName);

    try {
      var output = formatCode(exports.join('\n'));
      fileWriteString(outFilePath, output);
    } catch (e) {
      print(e);
      return;
    }

    _lastGenerated = outFilePath;
  }
}
