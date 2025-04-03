import 'dart:convert';
import 'generator.dart';

@pragma('model')
class Config {
  @pragma('json:formatter_version')
  String formatterVersion = '';

  @pragma('json:dir')
  String dir = '';

  @pragma('json:generators')
  List<GeneratorConfig> generators = [];

  Config();

  Config.build({
    required this.formatterVersion,
    required this.dir,
    required this.generators,
  });

  void patch(Map? _data) {
    if (_data == null) return;

    formatterVersion = _data['formatter_version'] ?? '';
    dir = _data['dir'] ?? '';
    generators = _data['generators']
            ?.map((i) => GeneratorConfig.fromMap(i)!)
            .toList()
            .cast<GeneratorConfig>() ??
        [];
  }

  static Config? fromMap(Map? data) {
    if (data == null) return null;
    return Config()..patch(data);
  }

  Map<String, dynamic> toMap() => {
        'formatter_version': formatterVersion,
        'dir': dir,
        'generators': generators.map((i) => i.toMap()).toList(),
      };
  String toJson() => json.encode(toMap());
  static Config? fromJson(String data) => Config.fromMap(json.decode(data));
  Map<String, dynamic> serialize() => {
        'formatterVersion': formatterVersion,
        'dir': dir,
        'generators': generators.map((dynamic i) => i?.serialize()).toList(),
      };
}
