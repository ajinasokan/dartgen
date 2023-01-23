import 'dart:convert';

@pragma('model')
class GeneratorConfig {
  @pragma('json:dir')
  String? dir;

  @pragma('json:type')
  String? type;

  @pragma('json:recursive')
  bool? recursive = false;

  @pragma('json:output_file')
  String? outputFile;

  GeneratorConfig();

  GeneratorConfig.build({
    this.dir,
    this.type,
    this.recursive,
    this.outputFile,
  });

  void patch(Map? _data) {
    if (_data == null) return;

    dir = _data['dir'] ?? dir;
    type = _data['type'] ?? type;
    recursive = _data['recursive'] ?? false;
    outputFile = _data['output_file'] ?? outputFile;
  }

  static GeneratorConfig? fromMap(Map? data) {
    if (data == null) return null;
    return GeneratorConfig()..patch(data);
  }

  Map<String, dynamic> toMap() => {
        'dir': dir,
        'type': type,
        'recursive': recursive,
        'output_file': outputFile,
      };
  String toJson() => json.encode(toMap());
  static GeneratorConfig? fromJson(String data) =>
      GeneratorConfig.fromMap(json.decode(data));
}
