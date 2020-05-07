import 'package:watcher/watcher.dart';
import 'package:dartgen/dartgen.dart' as dartgen;

main(List<String> arguments) {
  dartgen.generateModel("lib/models");
  dartgen.generateConstant("lib/constants");
  dartgen.generateIndex("lib/component");
  dartgen.generateIndex("lib/mutations");
  dartgen.generateIndex("lib/screens");
  dartgen.generateIndex("lib/framework");
  dartgen.generateIndex("lib/utils");

  var watcher = DirectoryWatcher("lib");
  print("Watching changes..");
  watcher.events.listen((event) {
    if (event.path.endsWith("index.dart")) return;

    print(event);

    if (event.path.startsWith("lib/models")) {
      dartgen.generateModel("lib/models");
    }

    if (event.path.startsWith("lib/constants")) {
      dartgen.generateConstant("lib/constants");
    }

    if (event.path.startsWith("lib/component")) {
      dartgen.generateIndex("lib/component");
    }

    if (event.path.startsWith("lib/mutations")) {
      dartgen.generateIndex("lib/mutations");
    }

    if (event.path.startsWith("lib/screens")) {
      dartgen.generateIndex("lib/screens");
    }

    if (event.path.startsWith("lib/framework")) {
      dartgen.generateIndex("lib/framework");
    }

    if (event.path.startsWith("lib/utils")) {
      dartgen.generateIndex("lib/utils");
    }
  });
}
