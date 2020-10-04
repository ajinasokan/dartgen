
run:
	cd test; dart ../bin/main.dart

local:
	pub global activate --source path .

git:
	pub global activate --source git https://github.com/ajinasokan/dartgen
