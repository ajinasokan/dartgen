import '../utils.dart';
import '../code_replacer.dart';
import 'generator.dart';
import '../models/generator.dart';

class EnumGenerator extends Generator {
  final GeneratorConfig? config;
  final Set<String> names = {};
  String? _lastGenerated;

  EnumGenerator({this.config});

  @override
  void init() {
    var darts = listFiles(config!.dir!, config!.recursive!);
    if (darts.isEmpty) return;

    darts.forEach((dartFile) => process(dartFile!));
  }

  @override
  bool shouldRun(WatchEvent event) =>
      event.path.startsWith(config!.dir!) && event.type != ChangeType.REMOVE;

  @override
  bool isLastGenerated(String path) => path == _lastGenerated;

  @override
  void resetLastGenerated() => _lastGenerated = null;

  @override
  void process(String path) {
    log('Enum: $path ');
    var replacer = CodeReplacer(fileReadString(path));
    var code = parseDartFile(path)!;

    getClasses(code).forEach((classItem) {
      var enumName = getClassName(classItem);
      names.add(enumName);

      var meta = getTag(classItem);
      if (meta != 'enum') return;

      var keys = <String>[];
      var values = <String>[];
      var items = <String>[];

      var methodsToDelete = <String>[
        '==',
        '+',
        'toString',
        'hashCode',
        'parse'
      ];
      var fieldsToDelete = <String>['value', 'keys', 'values', 'items'];
      classItem.members.forEach((field) {
        if (field is ConstructorDeclaration) {
          replacer.space(field.offset, field.length);
        } else if (field is FieldDeclaration &&
            fieldsToDelete.contains(getFieldName(field))) {
          replacer.space(field.offset, field.length);
        } else if (field is MethodDeclaration &&
            methodsToDelete.contains(getMethodName(field))) {
          replacer.space(field.offset, field.length);
        } else if (field is FieldDeclaration && field.fields.isConst) {
          var constant = getFieldName(field);
          var value = getConstructorInput(field)!;

          items.add(constant);
          keys.add("'" + constant + "'");
          values.add("'" + value + "'");
        }
      });

      var template = '''
static const keys = <String>[${keys.join(",")}];
static const values = <String>[${values.join(",")}];
static const items = <$enumName>[${items.join(",")}];

final String value;
const $enumName(this.value);

static $enumName? parse(String? v) => v == null ? null : $enumName(v);

@override
bool operator ==(Object o) => o is $enumName && value == o.value;

@override
int get hashCode => value.hashCode;

$enumName operator +($enumName o) => $enumName(value + o.value);

@override
String toString() => value;
  ''';

      replacer.add(classItem.offset + classItem.length - 1, 0, template);
    });

    try {
      var output = formatCode(replacer.process());
      if (fileWriteString(path, output)) {
        logDone();
      } else {
        logNoChange();
      }
    } catch (e) {
      print(e);
      return;
    }

    _lastGenerated = path;
  }
}
