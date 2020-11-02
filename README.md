# DartGen

An inline generator collection for Dart. Unlike the standard code generators DartGen doesn't produce `.g.dart` files instead the code is inserted into the actual definition itself. This is very similar to how `dartfmt` works. This can also be compared to how Java IDEs generate the getters and setters for fields. The objective of this flow is to keep the project clean and make codebase more readable.

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