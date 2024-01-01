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

## Write new articles

Make sure that `htmlgen.toml` points to the right file paths
(Obsidian vault). Then just create a new Obsidian note in that path
that looks something like this:

```markdown
---
description: The description of the article
date: August 2023
created: 2023-08-07T08:00:00.000Z
publish: true
---

Contents of article go here. You can use _the usual_ Markdown plus extensions
you're used to from places like GitHub.

You can also add images, either through normal Markdown tags,
or by dragging them into the Obsidian window as an embed:

![[image.png]]

That's all!
```
