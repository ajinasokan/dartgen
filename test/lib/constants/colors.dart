@pragma('enum')
class Color {
  static const Red = Color('red');
  static const Green = Color('green');

  static const keys = <String>['Red', 'Green'];
  static const values = <String>['red', 'green'];
  static const items = <Color>[Red, Green];

  final String value;
  const Color(this.value);

  @override
  bool operator ==(Object o) => o is Color && value == o.value;

  @override
  int get hashCode => value.hashCode;

  Color operator +(Color o) => Color(value + o.value);

  @override
  String toString() => value;
}
