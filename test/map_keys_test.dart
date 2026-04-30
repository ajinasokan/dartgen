import 'package:test/test.dart';
import 'dart:convert';
import 'dart:io';
import 'package:dartgenerate/dartgenerate.dart';
import 'package:dartgenerate/models/index.dart';
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

    final json = person.toJson();

    final decoded = jsonDecode(json) as Map<String, dynamic>;
    final addressMapFromJson = decoded['address_map'] as Map<String, dynamic>;

    expect(addressMapFromJson.keys.first, isA<String>());
    expect(addressMapFromJson.keys.first, '1');

    final personFromJson = Person.fromJson(json);

    expect(personFromJson!.addressMap.keys.first, isA<int>());
    expect(personFromJson.addressMap.keys.first, 1);
    expect(personFromJson.addressMap[1]!.length, 2);
    expect(personFromJson.addressMap[1]![0].street, '123 Main St');
    expect(personFromJson.addressMap[2]!.length, 1);
    expect(personFromJson.addressMap[2]![0].street, '789 Pine Rd');
  });

  test('generator emits map key and nullable/generic serialize handling', () {
    final tempDir = Directory.systemTemp.createTempSync('dartgen_map_keys_');
    try {
      Directory('${tempDir.path}/lib/models').createSync(recursive: true);
      final sample = File('${tempDir.path}/lib/models/sample.dart')
        ..writeAsStringSync('''
@pragma('model')
class Address {
  String street = '';
}

@pragma('model')
class GenericBox<T> {
  Map<String, T> values = {};
  List<T?> items = [];
}

@pragma('model')
class NullableListHolder {
  List<Address?> addresses = [];
}
''');

      ModelGenerator(
        config: GeneratorConfig.build(
          dir: '${tempDir.path}/lib/models',
          recursive: false,
          type: 'model',
        ),
        formatterVersion: '3.7.0',
      ).process(sample.path);

      final generated = sample.readAsStringSync();
      expect(
        generated,
        contains("'values': values.map<String, dynamic>("),
      );
      expect(
        generated,
        contains("MapEntry(k, (v as dynamic)?.serialize())"),
      );
      expect(
        generated,
        contains("items.map((i) => (i as dynamic)?.serialize()).toList()"),
      );
      expect(
        generated,
        contains("addresses.map((i) => i?.serialize()).toList()"),
      );
    } finally {
      tempDir.deleteSync(recursive: true);
    }
  });
}
