import 'dart:convert';

class Config {
  String dir;
  List<Generator> generators;

  Config({
    this.dir,
    this.generators,
  }) {
    if (generators == null) generators = [];
  }

  factory Config.fromMap(Map data) {
    if (data == null) return null;
    return Config(
      dir: data["dir"],
      generators: (data["generators"] ?? [])
          .map((i) => new Generator.fromMap(i))
          .toList()
          .cast<Generator>(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      "dir": dir,
      "generators": generators.map((i) => i.toMap()).toList(),
    };
  }

  String toJson() => json.encode(toMap());
  Map<String, dynamic> serialize() => {
        "dir": dir,
        "generators": generators.map((dynamic i) => i?.serialize()).toList(),
      };

  factory Config.clone(Config from) => Config(
        dir: from.dir,
        generators: from.generators,
      );

  factory Config.fromJson(String data) => new Config.fromMap(json.decode(data));
}

class Generator {
  String dir;
  String type;

  Generator({
    this.dir,
    this.type,
  }) {}

  factory Generator.fromMap(Map data) {
    if (data == null) return null;
    return Generator(
      dir: data["dir"],
      type: data["type"],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      "dir": dir,
      "type": type,
    };
  }

  String toJson() => json.encode(toMap());
  Map<String, dynamic> serialize() => {
        "dir": dir,
        "type": type,
      };

  factory Generator.clone(Generator from) => Generator(
        dir: from.dir,
        type: from.type,
      );

  factory Generator.fromJson(String data) =>
      new Generator.fromMap(json.decode(data));
}
