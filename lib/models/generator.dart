import 'dart:convert';

@pragma('model')
class Generator {
  @pragma('json:dir')
  String dir;

  @pragma('json:type')
  String type;

  @pragma('json:recursive')
  bool recursive = false;

  Generator({
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

  factory Generator.fromMap(Map data) {
    if (data == null) return null;
    return Generator()..patch(data);
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

  factory Generator.clone(Generator from) => Generator(
        dir: from.dir,
        type: from.type,
        recursive: from.recursive,
      );

  factory Generator.fromJson(String data) =>
      Generator.fromMap(json.decode(data));
}
