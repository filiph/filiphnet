# filiph.net 

[![Build Status](https://travis-ci.org/filiph/filiphnet.svg?branch=master)](https://travis-ci.org/filiph/filiphnet)

Code for Filip Hracek's personal homepage.

Use `make` to build and deploy this. For example:

```
$ make serve
```

This will build the project and will serve it on localhost.

To deploy:

```
$ make deploy
```


## Dart 3 workaround

I don't want to spend time upgrading to null safety at the moment.

To build the site in the meantime:

```shell
$ ./dart2-sdk/bin/dart pub get
$ ./dart2-sdk/bin/dart --enable-asserts tool/spanify.dart \
          --html src/index.template.html \
          src/text.md \
          > web/index.html
$ ./dart2-sdk/bin/dart pub global run webdev build
$ cp -R ./old/* ./build
$ firebase deploy
```
