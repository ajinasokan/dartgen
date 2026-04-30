import 'dart:io';

import 'package:analyzer/dart/analysis/features.dart';
import 'package:analyzer/dart/analysis/utilities.dart' as analyzer;
import 'package:dartgenerate/dartgenerate.dart';
import 'package:dartgenerate/models/index.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

void main() {
  test('index generation skips part files', () {
    final tempDir = Directory.systemTemp.createTempSync('dartgen_index_');
    final currentDir = Directory.current;
    try {
      final libDir = Directory('${tempDir.path}/lib')
        ..createSync(recursive: true);
      Directory('${libDir.path}/src').createSync();
      final bom = String.fromCharCode(0xfeff);

      File('${libDir.path}/main.dart').writeAsStringSync('''
library sample;

part 'src/detail.dart';
part 'src/annotated_detail.dart';
part 'src/named_detail.dart';
''');
      File('${libDir.path}/helper.dart').writeAsStringSync('''
// This comment should not make the file look like a part file:
// part of 'main.dart';

const text = 'part of a string';

class Helper {}
''');
      File('${libDir.path}/normal.dart').writeAsStringSync('''
/*
 * part of comments should not be treated as a directive.
 */
class Normal {}
''');
      File('${libDir.path}/annotated_normal.dart').writeAsStringSync(r'''
@pragma('note', "part of '../main.dart';")
class AnnotatedNormal {}
''');
      File('${libDir.path}/src/detail.dart').writeAsStringSync('''
// Leading comments are valid before a part-of directive.
part of '../main.dart';

class Detail {}
''');
      File('${libDir.path}/src/annotated_detail.dart').writeAsStringSync('''
${bom}@pragma(
  'note',
  {
    'text': "part of '../main.dart';",
    'nested': [
      {'value': '(not a group end)'},
    ],
  },
)
part of '../main.dart';

class AnnotatedDetail {}
''');
      File('${libDir.path}/src/named_detail.dart').writeAsStringSync('''
part /* comments between tokens are legal */ of sample;

class NamedDetail {}
''');

      Directory.current = tempDir;
      FileIndexGenerator(
        config: GeneratorConfig.build(
          dir: 'lib',
          recursive: true,
          type: 'index',
        ),
        formatterVersion: '',
      ).process('lib');

      expect(
        File('${libDir.path}/index.dart').readAsStringSync(),
        """
export 'annotated_normal.dart';
export 'helper.dart';
export 'main.dart';
export 'normal.dart';
""",
      );
    } finally {
      Directory.current = currentDir;
      tempDir.deleteSync(recursive: true);
    }
  });

  test('index generation matches analyzer part-of directives', () {
    final tempDir = Directory.systemTemp.createTempSync('dartgen_index_');
    final currentDir = Directory.current;
    try {
      final libDir = Directory('${tempDir.path}/lib')
        ..createSync(recursive: true);
      Directory('${libDir.path}/src').createSync();

      final files = {
        'owner.dart': '''
library owner;

part 'src/uri_part.dart';
part 'src/annotated_part.dart';
''',
        'normal.dart': 'class Normal {}',
        'comment_lookalike.dart': '''
// part of 'owner.dart';
class CommentLookalike {}
''',
        'annotation_lookalike.dart': r'''
@pragma('note', "${"part of 'owner.dart';"}")
class AnnotationLookalike {}
''',
        'src/uri_part.dart': '''
#!/usr/bin/env dart
/* outer /* nested */ comment */
part of '../owner.dart';

class UriPart {}
''',
        'src/annotated_part.dart': r'''
@pragma(
  'note',
  {
    'text': "${"part of '../owner.dart';"}",
    'nested': [
      {'value': "(not a group end)"},
    ],
  },
)
part /* comments between tokens are legal */ of owner;

class AnnotatedPart {}
''',
      };

      for (final entry in files.entries) {
        final file = File(p.join(libDir.path, entry.key))
          ..createSync(recursive: true);
        file.writeAsStringSync(entry.value);
      }

      Directory.current = tempDir;
      FileIndexGenerator(
        config: GeneratorConfig.build(
          dir: 'lib',
          recursive: true,
          type: 'index',
        ),
        formatterVersion: '',
      ).process('lib');

      expect(
        File('${libDir.path}/index.dart').readAsStringSync(),
        _expectedIndexFromAnalyzer(libDir),
      );
    } finally {
      Directory.current = currentDir;
      tempDir.deleteSync(recursive: true);
    }
  });
}

String _expectedIndexFromAnalyzer(Directory libDir) {
  final paths = libDir
      .listSync(recursive: true)
      .whereType<File>()
      .map((file) => file.path)
      .where((path) => p.extension(path) == '.dart')
      .where((path) => p.basename(path) != 'index.dart')
      .where((path) {
        final result = analyzer.parseFile(
          path: path,
          featureSet: FeatureSet.latestLanguageVersion(),
          throwIfDiagnostics: false,
        );
        return result.unit.directives.whereType<PartOfDirective>().isEmpty;
      })
      .map((path) => p.relative(path, from: libDir.path))
      .toList()
    ..sort();

  if (paths.isEmpty) return '';
  return '${paths.map((path) => "export '$path';").join('\n')}\n';
}
