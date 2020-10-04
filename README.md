# DartGen

An inline generator collection for Dart. Unlike the standard code generators DartGen doesn't produce `.g.dart` files instead the code is inserted into the actual definition itself. This is very similar to how `dartfmt` works. This can also be compared to how Java IDEs generate the getters and setters for fields. The objective of this flow is to keep the project clean and make codebase more readable.

## Features

- Generate enums with serializers.
- Generate model serializers. You can add enums inside these models as well.
- Generate index from a directory. This file will export all the `.dart` files.
- Watches for file changes.
- Config file to setup multiple generators.
- Option to enable recursive travel of dirs.

## Sample Config

```json
{
    "dir": "lib",
    "generators": [
        { "dir": "lib/models", "type": "model" },
        { "dir": "lib/models", "type": "index" },
        { "dir": "lib/constants", "type": "constant" },
        { "dir": "lib/constants", "type": "index" },
        { "dir": "lib/components", "type": "index", "recursive": true },
        { "dir": "lib/screens", "type": "index", "recursive": true }
    ]
}
```