import 'dart:convert';

@pragma('model', 'patchWith,clone,serialize')
class Store {
  @pragma('json:street')
  String? street;

  Store();

  Store.build({
    this.street,
  });

  void patch(Map? _data) {
    if (_data == null) return;
    street = _data['street'] ?? street;
  }

  static Store? fromMap(Map? data) {
    if (data == null) return null;
    return Store()..patch(data);
  }

  Map<String, dynamic> toMap() => {
        'street': street,
      };
  String toJson() => json.encode(toMap());
  Map<String, dynamic> serialize() => {
        'street': street,
      };

  void patchWith(Store clone) {
    street = clone.street;
  }

  static Store clone(Store from) => Store.build(
        street: from.street,
      );

  static Store? fromJson(String data) => Store.fromMap(json.decode(data));
}
