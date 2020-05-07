class Config {
  @pragma('json:dir')
  String dir;

  @pragma('json:generators')
  List<Generator> generators = [];
}

class Generator {
  @pragma('json:dir')
  String dir;

  @pragma('json:type')
  String type;
}
