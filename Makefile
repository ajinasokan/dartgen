
run:
	cd test; dart ../bin/main.dart

.PHONY: test
test:
	cd test; dart dartgen_test.dart
	cd test; dart generated_code_test.dart

local:
	dart pub global activate --source path .

git:
	dart pub global activate --source git https://github.com/ajinasokan/dartgen

pub:
	dart pub global activate dartgenerate

deactivate-old:
	dart pub global deactivate dartgen