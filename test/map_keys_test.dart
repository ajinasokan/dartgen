import 'package:test/test.dart';
import 'dart:convert';
import 'lib/models/person.dart';
import 'lib/models/address.dart';

void main() {
  test('Map with int keys - serialization roundtrip', () {
    // Create a person with addressMap having int keys
    final person = Person.build(
      name: 'John Doe',
      age: 30,
      addresses: [],
      addressMap: {
        1: [
          Address.build(street: '123 Main St'),
          Address.build(street: '456 Oak Ave'),
        ],
        2: [
          Address.build(street: '789 Pine Rd'),
        ],
      },
    );

    // Serialize to JSON
    final json = person.toJson();
    print('Serialized JSON: $json');

    // Verify JSON has string keys (required by JSON spec)
    final decoded = jsonDecode(json) as Map<String, dynamic>;
    final addressMapFromJson = decoded['address_map'] as Map<String, dynamic>;

    // JSON keys should be strings
    expect(addressMapFromJson.keys.first, isA<String>());
    expect(addressMapFromJson.keys.first, '1');

    // Deserialize back to Person
    final personFromJson = Person.fromJson(json);

    // Verify the map keys are restored as ints
    expect(personFromJson!.addressMap.keys.first, isA<int>());
    expect(personFromJson.addressMap.keys.first, 1);
    expect(personFromJson.addressMap[1]!.length, 2);
    expect(personFromJson.addressMap[1]![0].street, '123 Main St');
    expect(personFromJson.addressMap[2]!.length, 1);
    expect(personFromJson.addressMap[2]![0].street, '789 Pine Rd');
  });
}
