import 'dart:convert';
import 'address.dart';

@pragma('model')
class Person {
  @pragma('json:name')
  String name;

  @pragma('json:int')
  int age;

  @pragma('json:address')
  Address address;

  Person({
    this.name,
    this.age,
    this.address,
  });

  factory Person.fromMap(Map data) {
    if (data == null) return null;
    return Person(
      name: data["name"],
      age: data["int"],
      address: Address.fromMap(data["address"]),
    );
  }

  Map<String, dynamic> toMap() => {
        "name": name,
        "int": age,
        "address": address.toMap(),
      };
  String toJson() => json.encode(toMap());
  Map<String, dynamic> serialize() => {
        "name": name,
        "age": age,
        "address": address?.serialize(),
      };

  factory Person.clone(Person from) => Person(
        name: from.name,
        age: from.age,
        address: from.address,
      );

  factory Person.fromJson(String data) => Person.fromMap(json.decode(data));
}
