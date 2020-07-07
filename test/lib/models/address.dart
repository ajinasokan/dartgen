import 'dart:convert';

@pragma('model')
class Address {
  @pragma("json:street")
  String street;

  Address({
    this.street,
  });

  factory Address.fromMap(Map data) {
    if (data == null) return null;
    return Address(
      street: data["street"],
    );
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
