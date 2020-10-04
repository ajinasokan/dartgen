import 'dart:convert';

@pragma('model')
class GeneratorConfig {
  @pragma('json:dir')
  String dir;

  @pragma('json:type')
  String type;

  @pragma('json:recursive')
  bool recursive = false;

  GeneratorConfig({
    this.dir,
    this.type,
    this.recursive,
  }) {
    init();
  }

  void init() {
    if (recursive == null) recursive = false;
  }

  void patch(Map _data) {
    if (_data == null) return null;
    dir = _data["dir"];
    type = _data["type"];
    recursive = _data["recursive"];
    init();
  }

  factory GeneratorConfig.fromMap(Map data) {
    if (data == null) return null;
    return GeneratorConfig()..patch(data);
  }

  Map<String, dynamic> toMap() => {
        "dir": dir,
        "type": type,
        "recursive": recursive,
      };
  String toJson() => json.encode(toMap());
  Map<String, dynamic> serialize() => {
        "dir": dir,
        "type": type,
        "recursive": recursive,
      };

  factory GeneratorConfig.clone(GeneratorConfig from) => GeneratorConfig(
        dir: from.dir,
        type: from.type,
        recursive: from.recursive,
      );

  factory GeneratorConfig.fromJson(String data) =>
      GeneratorConfig.fromMap(json.decode(data));
}
