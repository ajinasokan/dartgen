import 'dart:convert';
import 'generator.dart';

@pragma('model')
class Config {
  @pragma('json:dir')
  String dir;

  @pragma('json:generators')
  List<GeneratorConfig> generators = [];

  Config({
    this.dir,
    this.generators,
  }) {
    init();
  }

  void init() {
    if (generators == null) generators = [];
  }

  void patch(Map _data) {
    if (_data == null) return null;
    dir = _data['dir'];
    generators = (_data['generators'] ?? [])
        .map((i) => GeneratorConfig.fromMap(i))
        .toList()
        .cast<GeneratorConfig>();
    init();
  }

  factory Config.fromMap(Map data) {
    if (data == null) return null;
    return Config()..patch(data);
  }

  Map<String, dynamic> toMap() => {
        'dir': dir,
        'generators': generators?.map((i) => i.toMap())?.toList(),
      };
  String toJson() => json.encode(toMap());
  Map<String, dynamic> serialize() => {
        'dir': dir,
        'generators': generators.map((dynamic i) => i?.serialize()).toList(),
      };

  factory Config.fromJson(String data) => Config.fromMap(json.decode(data));
}
