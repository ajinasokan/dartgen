import 'dart:convert';
import 'address.dart';
import '../constants/colors.dart';

@pragma('model')
class Person {
  @pragma('json:name')
  String? name;

  @pragma('json:int')
  int? age;

  @pragma('json:address')
  Address address = Address.preset();

  @pragma('json:dress_color')
  Color? dressColor;

  Person({
    this.name,
    this.age,
    required this.address,
    this.dressColor,
  });

  Person.preset();

  void patch(Map? _data) {
    if (_data == null) return;
    name = _data['name'] ?? name;
    age = _data['int'] ?? age;
    address = Address.fromMap(_data['address']) ?? Address.preset();
    dressColor = Color.parse(_data['dress_color']) ?? dressColor;
  }

  static Person? fromMap(Map? data) {
    if (data == null) return null;
    return Person.preset()..patch(data);
  }

  Map<String, dynamic> toMap() => {
        'name': name,
        'int': age,
        'address': address?.toMap(),
        'dress_color': dressColor?.value,
      };
  String toJson() => json.encode(toMap());
  Map<String, dynamic> serialize() => {
        'name': name,
        'age': age,
        'address': address?.serialize(),
        'dressColor': dressColor?.value,
      };

  static Person? fromJson(String data) => Person.fromMap(json.decode(data));
}
