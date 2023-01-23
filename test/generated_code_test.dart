import 'package:test/test.dart';

import 'lib/constants/index.dart';
import 'lib/models/index.dart';
import 'lib/files/index.dart';

void main() {
  test('enum values', () {
    expect(Color.Green.value, 'green');
    expect(Color.Red.value, 'red');
  });

  test('enum parse null', () {
    expect(Color.parse(null), null);
    expect(Color.parse('abcd')!.value, 'abcd');
  });

  test('enum iterables', () {
    expect(Color.keys[0], 'Red');
    expect(Color.values[1], 'green');
    expect(Color.items[1], Color.Green);
  });

  test('file embeds', () {
    expect(eulatxt, 'MIT License');
  });

  test('model encode', () {
    expect(Person().toJson(),
        '{"name":null,"int":null,"addresses":[],"new_addresses":[],"dress_color":null}');
  });

  test('model decode', () {
    expect(
        Person.fromJson(
                '{"name":null,"int":null,"addresses":[{"street":"street"}],"dress_color":null}')!
            .addresses
            .first
            .street,
        'street');
  });

  test('model parse null', () {
    expect(Person.fromMap(null), null);
  });
}
