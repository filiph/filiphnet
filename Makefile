clean:
	rm -rf ./build

serve: build
	firebase serve

deploy: build
	firebase deploy
	@echo "Visit https://filiph.net"

build: pub copy_old

pub: spanify
	pub build

copy_old:
	cp -R ./old/* ./build/web

spanify:
	dart -c tool/spanify.dart --html src/index.template.html src/text.md \
	  > web/index.html
