<a href="https://zerodha.tech"><img src="https://zerodha.tech/static/images/github-badge.svg" align="right" /></a>

# DartGen

An inline generator collection for Dart. Generate JSON serializers, enums with mapped values and iterables, export index etc. for your Flutter or Dart projects.

Unlike the standard code generators DartGen doesn't produce `.g.dart` files. Instead the code is inserted into the actual definition itself. This is very similar to how `dartfmt` works. This can also be compared to how Java IDEs generate the getters and setters for fields. The objective of this flow is to keep the project clean and make codebase more readable.

## Features

- Generate enums with serializers.
- Generate model serializers. You can add enums inside these models as well.
- Generate index from a directory. This file will export all the `.dart` files.
- Embed files from a directory.
- Watches for file changes.
- Config file to setup multiple generators.
- Option to enable recursive travel of dirs.

## Install

From git:

```shell
$ pub global activate --source git https://github.com/ajinasokan/dartgen
```

Make sure you [set the $PATH](https://dart.dev/tools/pub/cmd/pub-global#running-a-script-from-your-path) for pub. To verify run:

```shell
$ dartgen

No dartgen.json found in this directory.

Example config:
{
  "dir": "lib",
  "generators": [
      { "dir": "lib/models", "type": "model" },
      { "dir": "lib/models", "type": "index" },
      { "dir": "lib/constants", "type": "constant" },
      { "dir": "lib/constants", "type": "index" },
  ],
}
```

To run in watch mode:

```shell
$ dartgen watch
```

## Config

```json
{
    "dir": "lib",
    "generators": [
        { "dir": "lib/models", "type": "model" },
        { "dir": "lib/models", "type": "index" },
        { "dir": "lib/constants", "type": "constant" },
        { "dir": "lib/constants", "type": "index" },
        { "dir": "lib/components", "type": "index", "recursive": true },
        { "dir": "lib/screens", "type": "index", "recursive": true },
        { "dir": "lib/svgs", "type": "embed" }
    ]
}
```

Explanation:

`.dir` directory to watch file changes. Run `dartgen watch` to take this into consideration.

`.generators` list of all generators to run. This can be `model`, `constant`, `index` or `embed` generators. You can have more than one kind of generator executing in same directory.

`.generators.dir` sets the directory to run a particular generator.

`.generators.type` sets the type of the generator to run in the above directory.

`.generators.recursive` sets whether to run this generator recursively in the directory.

An example of usage can be found [here](EXAMPLE.md) and in `/test` directory.

## Code Generation

The generation process takes the code and the annotations inside it as the input and generates the appropriate code and injects back to the code. Clearly this is mutation of the code, just like how `dartfmt` is. Hence it is adviced to have your code version controlled, with git or by any other means, so that you can reverse if the generation caused any damage.

### Generating models

Code you write should look like this:

```dart
import 'dart:convert';

@pragma('model')
class Address {

  @pragma('json:street_name')
  String streetName = "NA";

}
```

`@pragma('model')` tells DartGen to generate model for this class. This includes constructor, map conversion, json conversion and serialization methods. `@pragma('json:street_name')` on a field gives the alias for that field in the json. If you don't specify an alias like this it will not be part of the serialization. You can specify a default value for the field. This will be used if you didn't initialize the field, the field doesn't exist or if the field is null in the json.

You can use all the data types that are supported in json, lists and maps of them, other models and enums with serializers generated by DartGen and Decimal.

Optionally you can add `@pragma('model', 'patchWith,clone')` flags to generate field patching and cloning methods. This clone method only does shallow clones. If you have to do deep clones you can use `toJson` and `fromJson` methods.

You can keep additional methods in the models and they will be kept intact.

### Generating enums

Define your enums like this:

```dart
@pragma('enum')
class Color {
  static const Red = Color('red');
  static const Green = Color('green');
}
```

DartGen wil generate the iterators, equivalence checks etc. These enums will be identified during the model generation. So they will be serialized properly.

### Generating index of exports

If you have a really large project its easier if all the dart files are exported. Dart is very good at handling cyclic imports given there are no name collisions.

If you enable index generation in a directory by defining in the `dartgen.json` it will generate `index.dart` in that directory with:

```dart
export 'address.dart';
export 'person.dart';
```

If you are in watch mode this will be automatically updated on addition/deletion of files.

### Embedding files

This is useful if you want to embedd small textual files like SVG, HTML, CSV etc. Embedding in the code instead of assets will help you access this synchronously and instantaneously. Bear in mind, if the file size is really big it will also increase the app's binary size which can result in slower load times.

You can enable embedding generator in `dartgen.json` for a directory and it will generate `index.dart` with:

```dart
final eulatxt = 'MIT License';
final imagesvg =
    '<!DOCTYPE html>\n<html>\n<body>\n\n<svg height=\"100\" width=\"100\">\n  <circle cx=\"50\" cy=\"50\" r=\"40\" stroke=\"black\" stroke-width=\"3\" fill=\"red\" />\n  Sorry, your browser does not support inline SVG.  \n</svg> \n \n</body>\n</html>\n';
```

## License

DartGen is licensed under the MIT license