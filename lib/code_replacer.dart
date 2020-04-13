class CodeReplacer {
  final String code;
  final _replaces = <List<dynamic>>[];

  CodeReplacer(this.code);

  void add(int start, int len, String newCode) {
    _replaces.add([start, len, newCode]);
  }

  void space(int start, int len) {
    _replaces.add([start, len, ' ' * len]);
  }

  String process() {
    var out = '$code';
    for (var i = 0; i < _replaces.length; i++) {
      var replace = _replaces[i];

      int start = replace[0];
      int len = replace[1];
      String newCode = replace[2];

      out = out.replaceRange(start, start + len, newCode);

      if (newCode.length != len) {
        for (var j = i + 1; j < _replaces.length; j++) {
          _replaces[j][0] += newCode.length - len;
        }
      }
    }
    return out;
  }
}
