import 'dart:convert';

@pragma('model')
class Address {
  @pragma("json:street")
  String street;

  Address({
    this.street,
  });

  void patch(Map _data) {
    if (_data == null) return null;
    street = _data["street"];
  }

  factory Address.fromMap(Map data) {
    if (data == null) return null;
    return Address()..patch(data);
  }

  Map<String, dynamic> toMap() => {
        "street": street,
      };
  String toJson() => json.encode(toMap());
  Map<String, dynamic> serialize() => {
        "street": street,
      };

  factory Address.clone(Address from) => Address(
        street: from.street,
      );

  factory Address.fromJson(String data) => Address.fromMap(json.decode(data));
}