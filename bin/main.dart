import 'dart:io';
import 'package:dartgen/generators/generator.dart';
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

  // generate constants first so that models can make use of it
  config.generators.sort((a, b) => a.type == 'constant' ? -1 : 1);

  EnumGenerator _lastEnumGen;
  final generators = config.generators.map((config) {
    Generator g;
    if (config.type == 'constant') {
      g = EnumGenerator(config: config);
      _lastEnumGen = g;
    } else if (config.type == 'model') {
      g = ModelGenerator(config: config, enumGenerator: _lastEnumGen);
    } else if (config.type == 'index') {
      g = IndexGenerator(config: config);
    }
    try {
      g.init();
    } catch (e, s) {
      print('Generator init failed with exception: $e $s');
    }
    return g;
  }).toList();

  if (arguments.contains('watch')) watch(config, generators);
}

void watch(Config config, List<Generator> generators) {
  var watcher = DirectoryWatcher(config.dir);

  print('Watching changes..');

  generators.forEach((g) => g.resetLastGenerated());

  watcher.events.listen((event) {
    generators.forEach((g) {
      if (g == null) return;
      if (!g.shouldRun(event)) return;
      if (g.isLastGenerated(event.path)) {
        g.resetLastGenerated();
        return;
      }

      try {
        g.process(event.path);
      } catch (e, s) {
        print('Generator failed with exception: $e $s');
      }
    });
  });
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
