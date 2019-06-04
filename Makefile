
run:
	@go run main.go

install:
	go build main.go
	mv main ~/go/bin/dartgen

test:
	go run main.go model example/model.dart
	go run main.go enum example/enum.dart
	go run main.go index example