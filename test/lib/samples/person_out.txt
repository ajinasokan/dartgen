import 'dart:convert';
import 'address.dart';
import '../constants/colors.dart';

@pragma('model')
class Person {
  @pragma('json:name')
  String? name;

  @pragma('json:int')
  int? age;

  @pragma('json:addresses')
  List<Address> addresses = [];

  @pragma('json:new_addresses')
  List<Address>? newAddresses = [];

  @pragma('json:dress_color')
  Color? dressColor;

  Person();

  Person.build({
    this.name,
    this.age,
    required this.addresses,
    this.newAddresses,
    this.dressColor,
  });

  void patch(Map? _data) {
    if (_data == null) return;

    name = _data['name'] ?? name;
    age = _data['int'] ?? age;
    addresses = _data['addresses']
            ?.map((i) => Address.fromMap(i)!)
            .toList()
            .cast<Address>() ??
        [];
    newAddresses = _data['new_addresses']
            ?.map((i) => Address.fromMap(i)!)
            .toList()
            .cast<Address>() ??
        [];
    dressColor = Color.parse(_data['dress_color']) ?? dressColor;
  }

  static Person? fromMap(Map? data) {
    if (data == null) return null;
    return Person()..patch(data);
  }

  Map<String, dynamic> toMap() => {
        'name': name,
        'int': age,
        'addresses': addresses.map((i) => i.toMap()).toList(),
        'new_addresses': newAddresses?.map((i) => i.toMap()).toList(),
        'dress_color': dressColor?.value,
      };
  String toJson() => json.encode(toMap());
  static Person? fromJson(String data) => Person.fromMap(json.decode(data));
  Map<String, dynamic> serialize() => {
        'name': name,
        'age': age,
        'addresses': addresses.map((dynamic i) => i?.serialize()).toList(),
        'newAddresses':
            newAddresses?.map((dynamic i) => i?.serialize()).toList(),
        'dressColor': dressColor?.value,
      };
}
