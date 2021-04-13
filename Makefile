
run:
	cd test; dart ../bin/main.dart

.PHONY: test
test:
	cd test; dart dartgen_test.dart
	cd test; dart generated_code_test.dart

local:
	pub global activate --source path .

git:
	pub global activate --source git https://github.com/ajinasokan/dartgen
