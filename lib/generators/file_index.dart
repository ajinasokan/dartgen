import 'package:path/path.dart' as p;
import '../generators/generator.dart';
import '../models/index.dart';
import '../utils.dart';

class FileIndexGenerator extends Generator {
  final GeneratorConfig config;
  final String formatterVersion;
  String? _lastGenerated;

  FileIndexGenerator({
    required this.config,
    required this.formatterVersion,
  });

  @override
  void init() {
    process(config.dir);
  }

  @override
  bool shouldRun(WatchEvent event) =>
      event.path.startsWith(config.dir!) && event.type != ChangeType.MODIFY;

  @override
  bool isLastGenerated(String path) => path == _lastGenerated;

  @override
  void resetLastGenerated() => _lastGenerated = null;

  @override
  void process(String? path) {
    log('Index: ${config.dir} ');
    final outFileName = config.outputFile ?? 'index.dart';
    var paths = listFiles(config.dir!, config.recursive!)
        .map((i) => p.relative(i!, from: config.dir))
        .toList();
    paths.remove(outFileName);
    if (paths.isEmpty) return null;
    final exports = paths.map((i) => "export '$i';");
    final outFilePath = p.join(config.dir!, outFileName);

    try {
      var output = formatCode(exports.join('\n'), formatterVersion);
      if (fileWriteString(outFilePath, output)) {
        logDone();
      } else {
        logNoChange();
      }
    } catch (e) {
      print(e);
      return;
    }

    _lastGenerated = outFilePath;
  }
}
