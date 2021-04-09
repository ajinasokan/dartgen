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

  GeneratorConfig({
    this.dir,
    this.type,
    this.recursive,
    this.outputFile,
  }) {
    init();
  }

  void init() {
    if (recursive == null) recursive = false;
  }

  void patch(Map _data) {
    if (_data == null) return null;
    dir = _data['dir'];
    type = _data['type'];
    recursive = _data['recursive'];
    outputFile = _data['output_file'];
    init();
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
  Map<String, dynamic> serialize() => {
        'dir': dir,
        'type': type,
        'recursive': recursive,
        'outputFile': outputFile,
      };

  static GeneratorConfig? fromJson(String data) =>
      GeneratorConfig.fromMap(json.decode(data));
}
