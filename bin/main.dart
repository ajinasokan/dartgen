import 'dart:io';
import 'package:watcher/watcher.dart';
import 'package:dartgen/dartgen.dart' as dartgen;
import 'package:dartgen/models/index.dart';

void main(List<String> arguments) {
  final configFile = File('dartgen.json');
  Config config;
  if (configFile.existsSync()) {
    config = Config.fromJson(configFile.readAsStringSync());
  } else {
    config = Config(
      dir: 'lib',
      generators: [
        Generator(dir: 'lib/models', type: 'model'),
        Generator(dir: 'lib/constants', type: 'constant'),
        Generator(dir: 'lib/component', type: 'index'),
        Generator(dir: 'lib/mutations', type: 'index'),
        Generator(dir: 'lib/screens', type: 'index'),
        Generator(dir: 'lib/framework', type: 'index'),
        Generator(dir: 'lib/utils', type: 'index'),
      ],
    );
    print(config.toJson());
  }

  config.generators.forEach((g) {
    switch (g.type) {
      case 'model':
        dartgen.generateModelDir(g.dir, g.recursive);
        break;
      case 'constant':
        dartgen.generateConstantDir(g.dir, g.recursive);
        break;
      case 'index':
        dartgen.generateIndex(g.dir, g.recursive);
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
              dartgen.generateModel(event.path);
            }
            break;
          case 'constant':
            if (event.type != ChangeType.REMOVE) {
              dartgen.generateConstant(event.path);
            }
            break;
          case 'index':
            dartgen.generateIndex(g.dir, g.recursive);
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
