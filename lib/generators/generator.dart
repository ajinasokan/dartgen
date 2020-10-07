import 'package:watcher/watcher.dart' show WatchEvent;
export 'package:watcher/watcher.dart' show WatchEvent, ChangeType;

abstract class Generator {
  void init();
  bool shouldRun(WatchEvent event);
  bool isLastGenerated(String path);
  void resetLastGenerated();
  void process(String path);
}
