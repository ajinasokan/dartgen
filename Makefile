export LC_ALL=en_US.UTF-8

generators:
	mkdir -p lib/generators-aot
	dart2aot lib/generators/model_gen.dart lib/generators-aot/model_gen
	dart2aot lib/generators/screen_gen.dart lib/generators-aot/screen_gen
	dart2aot lib/generators/component_gen.dart lib/generators-aot/component_gen
	dart2aot lib/generators/constant_gen.dart lib/generators-aot/constant_gen
	dart2aot lib/generators/mutation_gen.dart lib/generators-aot/mutation_gen
	dart2aot lib/generators/watcher.dart lib/generators-aot/watcher

all:
	@parallel dartaotruntime ::: lib/generators-aot/screen_gen lib/generators-aot/mutation_gen lib/generators-aot/component_gen lib/generators-aot/model_gen lib/generators-aot/constant_gen

screen:
	@dartaotruntime lib/generators-aot/screen_gen

mutation:
	@dartaotruntime lib/generators-aot/mutation_gen

component:
	@dartaotruntime lib/generators-aot/component_gen

model:
	@dartaotruntime lib/generators-aot/model_gen

constant:
	@dartaotruntime lib/generators-aot/constant_gen

watch:
	@dartaotruntime lib/generators-aot/watcher
