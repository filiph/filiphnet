clean:
	rm -rf ./build

serve: build
	firebase serve

deploy: build
	firebase deploy
	@echo "Visit https://filiph.net"

build: pub copy_old

pub:
	pub build

copy_old:
	cp -R ./old/* ./build/web
