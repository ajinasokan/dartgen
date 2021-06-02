import 'dart:io';
import 'dart:async';
import '../bin/main.dart' as bin;
import 'package:test/test.dart';

void main() {
  test('enum generation', () {
    writeFile(
      'lib/constants/colors.dart',
      readFile('lib/samples/colors_in.txt'),
    );
    runGenerator();
    shouldCodeMatch(
      readFile('lib/constants/colors.dart'),
      readFile('lib/samples/colors_out.txt'),
    );
  });

  test('model generation', () {
    writeFile(
      'lib/models/address.dart',
      readFile('lib/samples/address_in.txt'),
    );
    writeFile(
      'lib/models/person.dart',
      readFile('lib/samples/person_in.txt'),
    );
    runGenerator();
    shouldCodeMatch(
      readFile('lib/models/person.dart'),
      readFile('lib/samples/person_out.txt'),
    );
  });

  test('model generation patchWith', () {
    writeFile(
      'lib/models/store.dart',
      readFile('lib/samples/store_in.txt'),
    );
    runGenerator();
    shouldCodeMatch(
      readFile('lib/models/store.dart'),
      readFile('lib/samples/store_out.txt'),
    );
  });

  test('index generation', () {
    writeFile(
      'lib/models/index.dart',
      '',
    );
    runGenerator();
    shouldCodeMatch(
      readFile('lib/models/index.dart'),
      readFile('lib/samples/index_out.txt'),
    );
  });
}

// run generator but hide all print statements
void runGenerator() {
  runZoned(
    () => bin.main([]),
    onError: (e) => throw e,
    zoneSpecification: ZoneSpecification(
      print: (_, __, ___, ____) {},
    ),
  );
}

// compare code. remove all whitespaces to make the matching work
// TODO: use the analayzer to build this instead of regex
void shouldCodeMatch(String a, String b) {
  expect(
    a.replaceAll(RegExp(r'\s'), ''),
    b.replaceAll(RegExp(r'\s'), ''),
  );
}

// FS helpers
void writeFile(String path, String content) => File(path)
  ..createSync()
  ..writeAsStringSync(content);

String readFile(String path) => File(path).readAsStringSync();
