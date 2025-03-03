clean:
	rm -rf ./build

serve: build
	npx superstatic .

deploy: clean build
	firebase deploy
	@echo "Visit https://filiph.net"

build: copy_web htmlgen_blog htmlgen_flutter_performance copy_old

copy_web: spanify
	mkdir -p build
	cp -R ./web/* ./build

copy_old:
	cp -R ./old/* ./build

spanify:
	dart --enable-asserts tool/spanify.dart \
	  --html src/index.template.html \
	  src/index.md \
	  > web/index.html

htmlgen_blog:
	dart --enable-asserts tool/htmlgen.dart \
      htmlgen-blog.toml \
      --generate-rss

htmlgen_flutter_performance:
	dart --enable-asserts tool/htmlgen.dart \
      htmlgen-flutter-performance.toml \
      --generate-rss

