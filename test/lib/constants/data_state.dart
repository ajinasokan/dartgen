@pragma('enum')
class Color {
  static const Red = Color('red');
  static const Green = Color('green');

  static const keys = <String>['Red'];
  static const values = <String>['red'];
  static const items = <Color>[Red];

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

@pragma('enum')
class DataState {
  static const Valid = DataState('valid');
  static const Invalid = DataState('invalid');
  static const InProgress = DataState('inprogress');

  static const keys = <String>['Valid', 'Invalid', 'InProgress'];
  static const values = <String>['valid', 'invalid', 'inprogress'];
  static const items = <DataState>[Valid, Invalid, InProgress];

  final String value;
  const DataState(this.value);

  @override
  bool operator ==(Object o) => o is DataState && value == o.value;

  @override
  int get hashCode => value.hashCode;

  DataState operator +(DataState o) => DataState(value + o.value);

  @override
  String toString() => value;
}

@pragma('enum')
class ActionState {
  static const Valid = ActionState('valid');
  void check() {
    print("");
  }

  String get def => '';

  static const keys = <String>['Valid'];
  static const values = <String>['valid'];
  static const items = <ActionState>[Valid];

  final String value;
  const ActionState(this.value);

  @override
  bool operator ==(Object o) => o is ActionState && value == o.value;

  @override
  int get hashCode => value.hashCode;

  ActionState operator +(ActionState o) => ActionState(value + o.value);

  @override
  String toString() => value;
}
