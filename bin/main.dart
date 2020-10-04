import 'dart:io';
import 'package:watcher/watcher.dart';
import 'package:dartgen/dartgen.dart';
import 'package:dartgen/models/index.dart';

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

  config.generators.forEach((g) {
    switch (g.type) {
      case 'model':
        incrementalProcess(g.dir, g.recursive, modelGen.process);
        break;
      case 'constant':
        incrementalProcess(g.dir, g.recursive, enumGen.process);
        break;
      case 'index':
        var darts = listFiles(g.dir, g.recursive);
        indexGen.process(darts);
        break;
      default:
    }
  });

  var watcher = DirectoryWatcher(config.dir);

  print('Watching changes..');

  String lastFile;
  watcher.events.listen((event) {
    if (event.path.endsWith('index.dart')) return;
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
            indexGen.process(paths);
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
