import 'dart:io';
import 'package:watcher/watcher.dart';
import 'package:dartgen/dartgen.dart' as dartgen;
import 'package:dartgen/models/index.dart';

void main(List<String> arguments) {
  final configFile = File("dartgen.json");
  Config config;
  if (configFile.existsSync()) {
    config = Config.fromJson(configFile.readAsStringSync());
  } else {
    config = Config(
      dir: "lib",
      generators: [
        Generator(dir: "lib/models", type: "model"),
        Generator(dir: "lib/constants", type: "constant"),
        Generator(dir: "lib/component", type: "index"),
        Generator(dir: "lib/mutations", type: "index"),
        Generator(dir: "lib/screens", type: "index"),
        Generator(dir: "lib/framework", type: "index"),
        Generator(dir: "lib/utils", type: "index"),
      ],
    );
  }

  config.generators.forEach((g) {
    switch (g.type) {
      case "model":
        dartgen.generateModel(g.dir);
        break;
      case "constant":
        dartgen.generateConstant(g.dir);
        break;
      case "index":
        dartgen.generateIndex(g.dir);
        break;
      default:
    }
  });

  var watcher = DirectoryWatcher(config.dir);

  print("Watching changes..");

  watcher.events.listen((event) {
    if (event.path.endsWith("index.dart")) return;

    print(event);

    config.generators.forEach((g) {
      if (!event.path.startsWith(g.dir)) {
        return;
      }
      try {
        switch (g.type) {
          case "model":
            dartgen.generateModel(g.dir);
            break;
          case "constant":
            dartgen.generateConstant(g.dir);
            break;
          case "index":
            dartgen.generateIndex(g.dir);
            break;
          default:
        }
      } catch (e, s) {
        print(e);
        print(s);
      }
    });
  });
}
