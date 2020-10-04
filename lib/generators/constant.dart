import '../utils.dart';
import '../code_replacer.dart';
import 'generator.dart';

class EnumGenerator extends FileGenerator {
  Set<String> names = {};

  @override
  String process(String path) {
    print('Processing $path');
    var replacer = CodeReplacer(fileContents(path));
    var code = readFile(path);

    getClasses(code).forEach((classItem) {
      var enumName = getClassName(classItem);
      names.add(enumName);

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

    return replacer.process();
  }
}
