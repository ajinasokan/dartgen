import '../utils.dart';
import '../code_replacer.dart';

Map<String, int> _lastModified = {};

void generateConstantDir(String dir, bool recursive) {
  var darts = listFiles(dir, recursive);
  if (darts.isEmpty) return;

  darts.forEach((dartFile) => generateConstant(dartFile));

  print('Done: $dir');
}

void generateConstant(String dartFile) {
  _lastModified[dartFile] ??= 0;
  if (lastModTime(dartFile) <= _lastModified[dartFile]) {
    return;
  }
  print('Processing $dartFile');
  var replacer = CodeReplacer(fileContents(dartFile));
  var code = readFile(dartFile);

  getClasses(code).forEach((classItem) {
    var enumName = getClassName(classItem);
    var meta = getTag(classItem);
    if (meta != 'enum') return;

    var keys = <String>[];
    var values = <String>[];
    var items = <String>[];

    var methodsToDelete = <String>['==', '+', 'toString', 'hashCode'];
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
        var value = getConstructorInput(field);

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

  var output = formatCode(replacer.process());
  saveFile(dartFile, output);

  _lastModified[dartFile] = lastModTime(dartFile);
}
