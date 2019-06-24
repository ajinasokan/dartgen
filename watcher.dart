import 'package:watcher/watcher.dart';
import 'model_gen.dart' as modelGen;
import 'constant_gen.dart' as constantGen;
import 'component_gen.dart' as componentGen;
import 'mutation_gen.dart' as mutationGen;
import 'screen_gen.dart' as screenGen;
import 'framework_gen.dart' as frameworkGen;

void main() {
  modelGen.main();
  constantGen.main();
  componentGen.main();
  mutationGen.main();
  screenGen.main();
  frameworkGen.main();

  var watcher = DirectoryWatcher("lib");
  print("Watching changes..");
  watcher.events.listen((event) {
    if (event.path.endsWith("index.dart")) return;

    print(event);

    if (event.path.startsWith("lib/models")) modelGen.main();

    if (event.path.startsWith("lib/constants")) constantGen.main();

    if (event.path.startsWith("lib/component")) componentGen.main();

    if (event.path.startsWith("lib/mutations")) mutationGen.main();

    if (event.path.startsWith("lib/screens")) screenGen.main();

    if (event.path.startsWith("lib/framework")) frameworkGen.main();
  });
}
