abstract class FileGenerator {
  String process(String path);
}

abstract class DirectoryGenerator {
  String process(List<String> paths);
}
