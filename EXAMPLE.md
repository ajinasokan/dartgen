# Example

Take following file structure:

```
.
├── dartgen.json
└── lib
    ├── constants
    │   └── colors.dart
    ├── files
    │   ├── EULA.txt
    │   └── image.svg
    └── models
        ├── address.dart
        └── person.dart
```

Contents of `dartgen.json`:

```json
{
    "dir": "lib",
    "generators": [
        { "dir": "lib/models", "type": "model" },
        { "dir": "lib/models", "type": "index" },
        { "dir": "lib/constants", "type": "constant" },
        { "dir": "lib/files", "type": "embed" }
    ]
}
```

After `dartgen` executes it will make following modifications:

`lib/constants/colors.dart`:

```dart
@pragma('enum')
class Color {
  static const Red = Color('red');
  static const Green = Color('green');

  /* START GENERATED CODE */
  static const keys = <String>['Red', 'Green'];
  static const values = <String>['red', 'green'];
  static const items = <Color>[Red, Green];

  final String value;
  const Color(this.value);

  @override
  bool operator ==(Object o) => o is Color && value == o.value;

  @override
  int get hashCode => value.hashCode;

  Color operator +(Color o) => Color(value + o.value);

  @override
  String toString() => value;
  /* END GENERATED CODE */
}
```

`lib/models/address.dart`:

```dart
import 'dart:convert';

@pragma('model')
class Address {
  @pragma('json:street')
  String street;

  /* START GENERATED CODE */
  Address({
    this.street,
  });

  void patch(Map _data) {
    if (_data == null) return null;
    street = _data['street'];
  }

  factory Address.fromMap(Map data) {
    if (data == null) return null;
    return Address()..patch(data);
  }

  Map<String, dynamic> toMap() => {
        'street': street,
      };
  String toJson() => json.encode(toMap());
  Map<String, dynamic> serialize() => {
        'street': street,
      };

  factory Address.fromJson(String data) => Address.fromMap(json.decode(data));
  /* END GENERATED CODE */
}
```

`lib/models/index.dart`:

```dart
export 'address.dart';
export 'person.dart';
```

`lib/files/index.dart`:

```dart
final eulatxt = 'MIT License';
final imagesvg =
    '<!DOCTYPE html>\n<html>\n<body>\n\n<svg height=\"100\" width=\"100\">\n  <circle cx=\"50\" cy=\"50\" r=\"40\" stroke=\"black\" stroke-width=\"3\" fill=\"red\" />\n  Sorry, your browser does not support inline SVG.  \n</svg> \n \n</body>\n</html>\n';
```