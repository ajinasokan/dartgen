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

  @pragma('json:address_map')
  Map<int, List<Address>> addressMap = {};

  @pragma('json:dress_color')
  Color? dressColor;

  Person();

  Person.build({
    this.name,
    this.age,
    required this.addresses,
    this.newAddresses,
    required this.addressMap,
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
    addressMap = (_data['address_map'] as Map?)?.map<int, List<Address>>(
            (k, v) => MapEntry(
                int.parse(k),
                (v as List?)
                        ?.map((i) => Address.fromMap(i)!)
                        .toList()
                        .cast<Address>() ??
                    [])) ??
        {};
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
        'address_map': addressMap.map<String, dynamic>(
            (k, v) => MapEntry(k.toString(), v.map((i) => i.toMap()).toList())),
        'dress_color': dressColor?.value,
      };
  String toJson() => json.encode(toMap());
  static Person? fromJson(String data) => Person.fromMap(json.decode(data));
  Map<String, dynamic> serialize() => {
        'name': name,
        'age': age,
        'addresses': addresses.map((i) => i.serialize()).toList(),
        'newAddresses': newAddresses?.map((i) => i.serialize()).toList(),
        'addressMap': addressMap.map<String, dynamic>((k, v) =>
            MapEntry(k.toString(), v.map((i) => i.serialize()).toList())),
        'dressColor': dressColor?.value,
      };
}
