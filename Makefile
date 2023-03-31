clean:
	rm -rf ./build

serve: build
	superstatic .

deploy: build
	firebase deploy
	@echo "Visit https://filiph.net"

build: pub copy_old

pub: spanify
	webdev build

copy_old:
	cp -R ./old/* ./build

spanify:
	dart --enable-asserts tool/spanify.dart \
	  --html src/index.template.html \
	  src/text.md \
	  > web/index.html
