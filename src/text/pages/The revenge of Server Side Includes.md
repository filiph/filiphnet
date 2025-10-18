---
title: "The revenge of Server Side Includes (SSI)"
description: How a technology from 1993 makes so much sense for today's "Indie Small Web".
created: 2025-05-06T09:00:00.000Z
date: May 2025
social_image: https://filiph.net/text/imgs/Screenshot%202025-05-06%20at%2018.09.19.png
publish: true
---

You may be familiar with the recent trend of "Indie Small Web". It's the idea that, if you have valuable content worth sharing, you put it on your own bespoke website instead of feeding it to a huge media corporation for them to monetize it.

For example, if you have insightful commentary on something in your area of expertise, instead of writing a Facebook post, you put it on your own website. If you create an online course, you don't put it on Udemy or YouTube, you put it on your own website. And so on.

Now, this assumes you _have_ a website, or that you are able to build it. This obviously gives "Indie Small Web" a bit of a barrier to entry. That said, it was _at least_ as hard to make personal websites 20 years ago — before all of the Twitters and Facebooks and YouTubes came to dominate the web by making it easier to share content — and yet personal websites did exist back then.

## The appeal of static files

I've made a bunch of small websites and pages in the past several years. Here's a sampling:

- A [web page](https://starmap2d.appspot.com/) with my "accurate" 2d map of stars
- A [web page](https://giantrobotgame.com/) for my GIANT ROBOT GAME game
- A [web page](https://filiph.net/fuzzy/) showing how fuzzy logic might be useful for web analytics
- [Another one](https://filiph.net/eshop-ai/) showing STRIPS planning for e-commerce
- A [site](https://selfimproving.dev/) where I (slowly) write a book
- A [Czech website](https://stav-mobilniho-webu.appspot.com/) showing my research on mobile-friendliness of the Czech web
- Another [Czech website](https://www.blanictiroboti.cz/) for a comic book I'm writing
- Yet another Czech website that I plan to "launch" in a few days from now
- This very website + blog

All of these are static. The servers they're running on do nothing other than serving HTML files and associated resources (such as images). There's no dynamic functionality to any of these.

This is important because of a few reasons:

1. Dynamic websites (such as the ones that use PHP or Ruby on Rails) can be hacked. I don't have the resources to deal with that. And since it's a small bespoke website, I can't "outsource" this problem to someone else.
2. Static files can be easily cached, making it simple to keep your indie site fast to load. And load times are paramount these days.
3. It's super easy to find hosting for static websites.

When I'm making a website, it's very rare that I ever miss dynamism. In the past, I'd want some way for people to leave a comment. But these days, there are so many better ways to discuss that this use case for dynamic sites is obsolete.

## The problem

Oftentimes, I literally just write the content in HTML by hand. HTML was meant to be authored by humans, and although it's not ideal by any means, it's quite possible to just write in HTML and have a nice-looking result in reasonable time. A good editor can help with the boilerplate.

**But** there's a catch. Once you're writing more than one page, you'll inevitably start repeating yourself. As a developer, it feels dirty to have so many copies of basically the same code all over the place. It's not "DRY" and I constantly fear that I'll fix a problem in one file but will forget to update another one.

Wouldn't it be great to have some kind of system that lets me define templates like this ...

```html
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <title>$TITLE</title>
    ...
```

... and get a bunch of HTML (and JSON and XML) files?

## Static site generators & templating languages

The obvious answer to this problem is to use a static site generator with a templating language. There's Jekyll and Liquid, Hugo and Go templates, Gatsby and JSX. There are "standalone" templating languages like Mustache that you can easily use in a number of static site generators, including custom ones.

If you truly need something like Jekyll or Hugo, then by all means, use it. But my experience has been that these technologies are really only worth it above certain complexity threshold.

For the cases where you need structured data in `.yaml` files, something like Jekyll is fantastic, and well worth the additional complexity and longer build times.

But when I look at my "Indie Small Web" projects, the vast majority of them don't need this.

All I need is:

- simple "mail merge" templating
- ability to include one file in another file (surprisingly hard to do in some templating languages)
- ability to convert Markdown to HTML

That's it.

## `m4`

Looking at the other end of the complexity spectrum, one can choose [`m4`](https://en.wikipedia.org/wiki/M4_(computer_language)). This is a tiny macro processor that is easy to install on Unix-based systems and has been part of the Unix ecosystem since 1977 (written by K&R, no less). It does text substitution and file inclusion, so it checks 2 of the three requirements above. Conversion to Markdown could be done in a separate step, with another command line tool.

I went this route for a bit, but `m4` suffers from the usual ailments of ancient Unix tools. Its syntax is sometimes delightfully simple but other times, it's arcane. 

* Do you want to avoid printing newlines after directives? Use `divert(-1)dnl` but don't forget to `divert(0)dnl` once you're ready to output some lines again.
* How do you express string literals in `m4`? The starting character is a backtick, and the closing one is a single quote: <code><pre>`I am not kidding.'</pre></code>
* What's the syntax of expanding a macro? You literally just include the exact string of the macro name for it to register.

   ```text
   define(`OP', `Filip Hráček')dnl
   The full name of the original poster is OP.
   But beware, the macro will expand anywhere. OOPS!
   ```

After a while of using `m4`, I saw so many potential foot-guns that I decided to look elsewhere.


## Server Side Includes

Back in the 1993, before PHP, Ruby or Java, there was this super simple templating language for servers called [Server Side Includes (SSI)](https://en.wikipedia.org/wiki/Server_Side_Includes). It had only a few simple directives that were hard to miss even in old editors without syntax highlighting. For example:

```html
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <title><!--#echo var="TITLE" --></title>
</head>
<body>

    <!--#include file="content.html" -->

</body>
</html>
```

Guess what? For a simple static site, this is _perfect!_ You get very obvious syntax that's hard to overlook. You get an easy way to include other files. And since the semantics are so limited, there's less chance you'll over-engineer your tiny little website.

It's also a long-lived syntax (that's still supported in servers like nginx and Apache).

I'm gradually converting all my small sites to using SSI.

![[Screenshot 2025-05-06 at 18.09.19.png]]

## Caveats

I want to be absolutely clear about one thing: I'm not using SSI to serve dynamic content. I only run `ssi` at build time, and then serve the generated static files.

I also decided to write [my own `ssi` tool](https://github.com/filiph/ssi). It's 221 lines of code in 8 files. It's naive code, sure, but frankly, I don't see any immediate need to make it more robust. It does the job and it runs very fast.

My "Indie Small Web" sites tend to be built using a `Makefile`. Here, too, I place a premium on simplicity and longevity (`make` has survived since 1976 so, according to the Lindy Effect, it's likely to survive for many more decades to come).

A typical `Makefile` for a site can look like this:

```text
.PHONY: build serve install

serve: build
	cd web && python3 -m http.server

build:
    ssi src/index.definitions.txt src/header.shtml \
      src/index.md src/footer.shtml \
      > web/index.html
    ssi src/other.definitions.txt src/header.shtml \
      src/other.md src/footer.shtml \
      > web/other.html
    # ... more files ...

install:
	dart pub global activate --source git https://github.com/filiph/ssi --git-ref main
```

(My `ssi` tool takes inspiration from `m4` in that it concatenates the input files given to it. So you can have variable declarations in `index.definitions.txt`, a common header template in `header.shtml`, Markdown content in `index.md`, and a common footer in `footer.shtml`. This is just one way to do this, though. You could have a single `index.shtml` file with definitions and include directives — and I often do just that.)

Notice how I don't even bother with things like Makefile's source file dependencies. `make` just runs the whole build process every time I ask it to, without trying to optimize which files to update and which ones to leave be. This is because we're talking about small sites, and the tool finishes in about 10 milliseconds per invocation. That means I can have my IDE set up to run `make build` on every save of any file in my project, and the response is still immediate — even without dependency graph build optimization.

## Is this approach for you?

I wanted to share my experience with building static "Indie Small Web" sites because — generally speaking — blogposts on this topic tend to overcomplicate things. As I said above, it's probably okay to just write straight HTML, even if you have more than one file. It might be worth it to bring in something like `m4` or `ssi` if you, like me, have lots of tiny sites. But I wonder how often people _really_ need Jekyll or Firebase or Webpack to get their content out there. I think it's mostly overkill, and acting as if it's "the norm" is not helping.

That said, what do I know? The approach has worked for me so far but I have no idea whether it will hold up in the future, and of course I can't claim it will work as well for anyone other than myself.

My hope is that I get a person or two excited to try building their own little garden on the internet. And, frankly, I don't really care what technology they'll use for that.

