package main

import (
	"fmt"
	"io/ioutil"
	"os"
	"path"
	"regexp"
	"strings"

	"github.com/ajinasokan/util"
)

var log = fmt.Println

const serializeTmpl = `
	{{.Name}}({
{{range .Fields }}    {{.Type}} {{.Name}},{{"\n"}}{{ end }}	}) {
{{range .Fields }}    this.{{.Name}} = {{.Name}} ?? this.{{.Name}};{{"\n"}}{{ end }}	}

	void patch(Map<String, dynamic> data) {
{{range .Fields }}    this.{{.Name}} = {{.FromMap}} ?? this.{{.Name}};{{"\n"}}{{ end }}	}

  Map<String, dynamic> toMap() {
    return {
{{range .Fields }}      "{{.Key}}": {{.ToMap}},{{"\n"}}{{ end }}    };
  }

  static {{.Name}} fromMap(Map<String, dynamic> data) {
    if (data == null) return null;
		return {{.Name}}(
{{range .Fields }}      {{.Name}}: {{.FromMap}},{{"\n"}}{{ end }}    );	
  }

  static {{.Name}} fromJSON(String data) => fromMap(json.decode(data));
  String toJSON() => json.encode(toMap());
  `

const enumerationTmpl = `
  final String value;
  const {{.Name}}(this.value);
{{range .Fields}}  static const {{.Name}} = const {{$.Name}}("{{.Key}}");{{"\n"}}{{ end }}
	operator ==(Object o) => o is {{.Name}} && value == o.value;
	operator +({{.Name}} o) => value + o.value;
	int get hashCode => value.hashCode;
	String toString() => value;
	`

var primitives = []string{"String", "num", "bool", "int", "double", "dynamic", "Map<String, dynamic>"}

type classDef struct {
	Name       string
	Serialize  bool
	Definition string
	Fields     []fieldDef
}

type fieldDef struct {
	Type    string
	Name    string
	Key     string
	FromMap string
	ToMap   string
}

func main() {
	args := os.Args[1:]
	if len(args) < 2 {
		log("Not enough args")
		return
	}
	generator := args[0]
	files := args[1:]

	if generator == "model" {
		for _, file := range files {
			generateModel(file)
		}
	} else if generator == "enum" {
		for _, file := range files {
			generateEnum(file)
		}
	} else if generator == "index" {
		generateIndex(files[0])
	} else {
		log("Invalid generator")
	}
}

func generateIndex(dirName string) {
	out := ""
	files, _ := ioutil.ReadDir(dirName)
	for _, file := range files {
		if strings.HasSuffix(file.Name(), ".dart") && file.Name() != "index.dart" {
			out += "export \"" + file.Name() + "\";\n"
		}
	}
	outFile := path.Join(dirName, "index.dart")
	util.WriteTextFile(outFile, out)
}

func generateEnum(fileName string) {
	log("Processing", fileName)

	out, _ := util.ReadTextFile(fileName)

	//CLASSES TO SERIALIZE
	classExp := regexp.MustCompile(`(?is)@pragma."enum".\s+class\s*(.*?)\s*{.*?static.const.map.*?{(.*?)}.*?//GENERATED`)
	rawClasses := classExp.FindAllStringSubmatch(out, -1)

	for _, class := range rawClasses {
		c := classDef{
			Name:       class[1],
			Serialize:  true,
			Definition: class[2],
		}

		log("Enumeration added for", c.Name)

		fieldExp := regexp.MustCompile(`(?is)"(.*?)".*?"(.*?)",`)
		rawFields := fieldExp.FindAllStringSubmatch(c.Definition, -1)
		for _, field := range rawFields {
			f := fieldDef{
				Name: field[1],
				Key:  field[2],
			}
			c.Fields = append(c.Fields, f)
		}
		enumeration := util.ExecTemplate(enumerationTmpl, c)

		// REPLACE
		genExp := regexp.MustCompile(`(?is)(class\s` + c.Name + `\s)(.*?)(//GENERATED)(.*?)(//GENERATED)`)
		if c.Serialize {
			out = genExp.ReplaceAllString(out, "${1}${2}${3}"+enumeration+"${5}")
		} else {
			out = genExp.ReplaceAllString(out, "${1}${2}${3}\n  ${5}")
		}
	}

	util.WriteTextFile(fileName, out)
}

func generateModel(fileName string) {
	log("Processing", fileName)

	out, _ := util.ReadTextFile(fileName)

	//CLASSES TO SERIALIZE
	classExp := regexp.MustCompile(`(?is)@pragma."model".\s+class\s*(.*?)\s+.*?{(.*?)//GENERATED`)
	rawClasses := classExp.FindAllStringSubmatch(out, -1)

	for _, class := range rawClasses {
		c := classDef{
			Name:       class[1],
			Serialize:  true,
			Definition: class[2],
		}

		log("Serializer added for", c.Name)

		fieldExp := regexp.MustCompile(`(?is)@pragma\(.json:.(.*?)..\)\s+((.*?)(<.*?>){0,1})\s+(.*?)((\s*=\s*(.*?))|.{0});`)
		rawFields := fieldExp.FindAllStringSubmatch(c.Definition, -1)
		c.Fields = make([]fieldDef, 0)
		for _, field := range rawFields {
			// for i, item := range field {
			// 	log(i, item)
			// }
			f := fieldDef{
				Type: field[2],
				Name: field[5],
				Key:  field[1],
			}
			if util.SliceContainsString(primitives, f.Type) {
				f.FromMap = `data["` + f.Key + `"]`
				f.ToMap = f.Name
			} else if strings.HasPrefix(f.Type, "List<") {
				listType := f.Type[5 : len(f.Type)-1]
				if util.SliceContainsString(primitives, listType) {
					f.FromMap = `data["` + f.Key + `"]`
					f.ToMap = f.Name
				} else {
					f.FromMap = `data["` + f.Key + `"]`
					f.FromMap += "\n" + `          ?.map((i) => ` + listType + `.fromMap(i))`
					f.FromMap += "\n" + `          ?.toList()`
					f.FromMap += "\n" + `          ?.cast<` + listType + `>()`
					f.ToMap = f.Name + "?.map((i) => i?.toMap())?.toList()"
				}
			} else {
				f.FromMap = f.Type + `.fromMap(data["` + f.Key + `"])`
				f.ToMap = f.Name + "?.toMap()"
			}
			c.Fields = append(c.Fields, f)
		}
		serialize := util.ExecTemplate(serializeTmpl, c)

		// REPLACE
		genExp := regexp.MustCompile(`(?is)(class\s` + c.Name + `\s)(.*?)(//GENERATED)(.*?)(//GENERATED)`)
		if c.Serialize {
			out = genExp.ReplaceAllString(out, "${1}${2}${3}"+serialize+"${5}")
		} else {
			out = genExp.ReplaceAllString(out, "${1}${2}${3}\n  ${5}")
		}
	}

	util.WriteTextFile(fileName, out)
}
