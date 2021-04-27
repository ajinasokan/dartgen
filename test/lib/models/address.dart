import 'dart:convert';

@pragma('model')
class Address {
  @pragma('json:street')
  String street = '';

  Address();

  Address.build({
    required this.street,
  });

  void patch(Map? _data) {
    if (_data == null) return;

    street = _data['street'] ?? '';
  }

  static Address? fromMap(Map? data) {
    if (data == null) return null;
    return Address()..patch(data);
  }

  Map<String, dynamic> toMap() => {
        'street': street,
      };
  String toJson() => json.encode(toMap());
  static Address? fromJson(String data) => Address.fromMap(json.decode(data));
  Map<String, dynamic> serialize() => {
        'street': street,
      };
}
