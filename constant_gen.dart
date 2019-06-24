import 'utils.dart';

void main() {
  var darts = listFiles('lib/constants');

  if (darts.length == 0) return;

  String output = '''
  class Enumeration {
    final String value;
    const Enumeration(this.value);
  
    operator ==(Object other) =>
        other is Enumeration ? value == other.value : false;
  
    @override
    int get hashCode => value.hashCode;
  
    operator +(Enumeration other) => value + other.value;
  
    @override
    String toString() => value;
  }
  ''';

  darts.forEach((dartFile) {
    var code = readFile(dartFile);

    getClasses(code).forEach((classItem) {
      var enumName = getClassName(classItem);
      List<String> keys = [];
      List<String> values = [];
      List<String> items = [];

      output += '''
        class $enumName extends Enumeration { 
          const $enumName(value) : super(value);
          
      ''';
      classItem.members.forEach((field) {
        var constant = getFieldName(field);
        var value = getFieldValue(field);

        output += 'static const $constant = const $enumName($value);';

        items.add(constant);
        keys.add('"' + constant + '"');
        values.add(value);
      });

      output += 'static const List<String> keys = [${keys.join(",")}];';
      output += 'static const List<String> values = [${values.join(",")}];';
      output += 'static const List<$enumName> items = [${items.join(",")}];';

      output += '}';
    });
  });

  output = formatCode(output);
  saveFile('lib/constants/index.dart', output);
  print("Constants.. Done.");
}
