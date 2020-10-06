import 'dart:io';
import 'package:watcher/watcher.dart';
import 'package:dartgen/dartgen.dart';
import 'package:dartgen/models/index.dart';
import 'package:path/path.dart' as path;

void main(List<String> arguments) {
  final configFile = File('dartgen.json');

  Config config;
  if (configFile.existsSync()) {
    config = Config.fromJson(configFile.readAsStringSync());
  } else {
    config = defaultConfig;
    print(config.toJson());
  }

  final enumGen = EnumGenerator();
  final modelGen = ModelGenerator(enumGenerator: enumGen);
  final indexGen = IndexGenerator();

  // generate constants first so that models can make use of it
  config.generators.sort((a, b) => a.type == 'constant' ? -1 : 1);

  config.generators.forEach((g) {
    switch (g.type) {
      case 'model':
        incrementalProcess(g.dir, g.recursive, modelGen.process);
        break;
      case 'constant':
        incrementalProcess(g.dir, g.recursive, enumGen.process);
        break;
      case 'index':
        print('Processing index of ${g.dir}');
        var darts = listFiles(g.dir, g.recursive)
            .map((i) => relativePath(i, g.dir))
            .toList();
        indexProcess(g.dir, darts, indexGen.process);
        break;
      default:
    }
  });

  var watcher = DirectoryWatcher(config.dir);

  print('Watching changes..');

  String lastFile;
  watcher.events.listen((event) {
    // TODO: replace this with output file name from config
    if (event.path.endsWith('index.dart')) return;

    // dont generate for the file that was the output of last run
    if (event.path == lastFile) {
      lastFile = null;
      return;
    }

    print(event);

    config.generators.forEach((g) {
      if (!event.path.startsWith(g.dir)) {
        return;
      }
      try {
        switch (g.type) {
          case 'model':
            if (event.type != ChangeType.REMOVE) {
              modelGen.process(event.path);
            }
            break;
          case 'constant':
            if (event.type != ChangeType.REMOVE) {
              enumGen.process(event.path);
            }
            break;
          case 'index':
            var paths = listFiles(g.dir, g.recursive)
                .map((i) => relativePath(i, g.dir))
                .toList();
            indexProcess(g.dir, paths, indexGen.process);
            break;
          default:
        }
      } catch (e, s) {
        print(e);
        print(s);
      }
    });

    lastFile = event.path;
  });
}

void indexProcess(
  String dir,
  List<String> paths,
  String Function(List<String>) process,
) {
  try {
    var output = formatCode(process(paths));
    saveFile(path.join(dir, 'index.dart'), output);
  } catch (e) {
    print(e);
    return;
  }
}

Map<String, int> _lastModified = {};
void incrementalProcess(
  String dir,
  bool recursive,
  String Function(String) process,
) {
  var darts = listFiles(dir, recursive);
  if (darts.isEmpty) return;

  darts.forEach((dartFile) {
    _lastModified[dartFile] ??= 0;
    if (lastModTime(dartFile) <= _lastModified[dartFile]) {
      return;
    }

    try {
      var output = formatCode(process(dartFile));
      saveFile(dartFile, output);
    } catch (e) {
      print(e);
      return;
    }

    _lastModified[dartFile] = lastModTime(dartFile);
  });

  print('Done: $dir');
}

Config get defaultConfig => Config(
      dir: 'lib',
      generators: [
        GeneratorConfig(dir: 'lib/models', type: 'model'),
        GeneratorConfig(dir: 'lib/constants', type: 'constant'),
        GeneratorConfig(dir: 'lib/component', type: 'index'),
        GeneratorConfig(dir: 'lib/mutations', type: 'index'),
        GeneratorConfig(dir: 'lib/screens', type: 'index'),
        GeneratorConfig(dir: 'lib/framework', type: 'index'),
        GeneratorConfig(dir: 'lib/utils', type: 'index'),
      ],
    );
