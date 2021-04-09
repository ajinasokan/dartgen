import 'dart:io';
import 'package:dartgen/generators/generator.dart';
import 'package:watcher/watcher.dart';
import 'package:dartgen/dartgen.dart';
import 'package:dartgen/models/index.dart';

void main(List<String> arguments) {
  final configFile = File('dartgen.json');

  Config? config;
  if (configFile.existsSync()) {
    config = Config.fromJson(configFile.readAsStringSync());
  } else {
    print("""No dartgen.json found in this directory.

Example config:
{
  "dir": "lib",
  "generators": [
      { "dir": "lib/models", "type": "model" },
      { "dir": "lib/models", "type": "index" },
      { "dir": "lib/constants", "type": "constant" },
      { "dir": "lib/constants", "type": "index" },
  ],
}""");
    return;
  }

  // generate constants first so that models can make use of it
  config!.generators!.sort((a, b) => a.type == 'constant' ? -1 : 1);

  EnumGenerator? _lastEnumGen;
  final generators = config.generators!.map((config) {
    Generator? g;
    if (config.type == 'constant') {
      g = EnumGenerator(config: config);
      _lastEnumGen = g as EnumGenerator?;
    } else if (config.type == 'model') {
      g = ModelGenerator(config: config, enumGenerator: _lastEnumGen);
    } else if (config.type == 'index') {
      g = FileIndexGenerator(config: config);
    } else if (config.type == 'embed') {
      g = FileEmbedGenerator(config: config);
    }
    try {
      g!.init();
    } catch (e, s) {
      print('Generator init failed with exception: $e $s');
    }
    return g;
  }).toList();

  if (arguments.contains('watch')) watch(config, generators);
}

void watch(Config config, List<Generator?> generators) {
  var watcher = DirectoryWatcher(config.dir!);

  print('Watching changes..');

  generators.forEach((g) => g!.resetLastGenerated());

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
