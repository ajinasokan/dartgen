import 'dart:io';
import 'package:strings/strings.dart';
import 'package:slugify/slugify.dart';
import 'package:path/path.dart' as p;
import '../models/index.dart';
import '../generators/generator.dart';
import '../utils.dart';
import 'dart:convert';

class FileEmbedGenerator extends Generator {
  final GeneratorConfig? config;
  String? _lastGenerated;

  FileEmbedGenerator({this.config});

  @override
  void init() {
    process(config!.dir);
  }

  @override
  bool shouldRun(WatchEvent event) => event.path.startsWith(config!.dir!);

  @override
  bool isLastGenerated(String path) => path == _lastGenerated;

  @override
  void resetLastGenerated() => _lastGenerated = null;

  @override
  void process(String? path) {
    log('Embed: ${config!.dir} ');
    final outFileName = config!.outputFile ?? 'index.dart';
    var filesPaths = listFiles(config!.dir!, config!.recursive!, true);

    var relativePaths =
        filesPaths.map((i) => p.relative(i!, from: config!.dir)).toList();
    relativePaths.remove(outFileName);
    if (relativePaths.isEmpty) return null;

    final outFilePath = p.join(config!.dir!, outFileName);

    try {
      var output = formatCode(filesPaths.map((i) {
        final relFilePath = p.relative(i!, from: config!.dir);
        if (relFilePath == outFileName) return '';

        final fileName = p.basename(relFilePath);
        final slug = slugify(fileName, delimiter: '');
        return 'final $slug = \'' +
            Strings.toEscaped(File(i)
                .readAsStringSync(encoding: Utf8Codec(allowMalformed: true))) +
            '\';\n';
      }).join(''));

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
