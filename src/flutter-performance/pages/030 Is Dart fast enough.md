---
title: "Chapter 3: Is Dart fast enough?"
description: A brief look at programming language performance.
created: 2025-03-03T08:00:00.000Z
publish: true
---

%% ## Is Dart fast enough? %%

Yes, it is.

%% ## Can you elaborate?

Yes. %%

...

Alright, look. If I was playing a wise performance guru, I would say something like:

> Does it even make sense to talk about the performance of a _programming language?_ Programming languages are abstractions! Only concrete programs, compiled with concrete compilers and executed on concrete hardware, can have a notion of performance.

Then I'd nod to my own wisdom, stroke my long white beard, and close my eyes to meditate on the meaning of "benchmark."

And I would be correct, of course! We all know that there does not exist a single ranking of programming languages by speed. But I hope we can also agree that, roughly speaking and with a lot of handwaving, that some programming languages _are_ more performant than others.

In most ways that matter, C++ *is* more performant than Python, for example. Implementing the same algorithm in C++ and in Python will *generally* lead to a faster program in C++, and a slower one in Python. I bet there are special cases in which Python is, in fact, faster or less resource-intensive than C. But — they're rare. There's a reason why real-time simulations are almost exclusively written in C++ and not a more high-level language like Python.

Most people also understand the idea of trade-offs. You can trade a bit of performance for some ease of use, security, portability, or speed of development. And that can obviously be fine because otherwise, if it wasn't fine, every app _ever_ would be written either in assembly or in C.

If you ever looked into programming language performance, you've probably seen _The Computer Language Benchmarks Game_.[^1] This is a website that has a number of benchmarks implemented in a variety of programming languages, and shows statistics on them in order to "give a simple idea of each language's general performance".

%% https://salsa.debian.org/benchmarksgame-team/benchmarksgame/-/tree/master/public/data?ref_type=heads for row data %%

From this site you get graphs like these:[^2]

![[fastest-elapsed.svg]]

![[fastest-more-elapsed.svg]]

[^2]: https://benchmarksgame-team.pages.debian.net/benchmarksgame/box-plot-summary-charts.html

Maybe you've seen them before. The most shallow reading of these graphs tells us this about general programming language performance:

- C and C++ and Rust are the fastest programming languages
- The following two languages, Chapel and C#, are both about 2x slower than C.
- The next cluster of 10 languages is about 3x to 5x slower than C and includes Fortran, Julia, Java, Go and Swift.
- The cluster just after that is about 5x to 7x slower and includes OCaml, Dart and Javascript (Node.js).
- Racket is next, more than 10x slower than C.
- The graph is capped by 7 languages, including PHP (40x slower), Ruby (50x slower), Python (60x) and Lua (90x slower).

But, and this is a big "but", it's important to understand what the benchmarks are measuring. 

%% (comics: Big but. Hehe. rolls eyes) %%

The benchmarks are measuring the elapsed time of long-running computations such as Mandelbrot, Fannkuch or an N-body physics simulation. So, if you're working on a high performance scientific simulation, for example, then the data above are relevant and yes, in that case you should go with C or Rust rather than Dart.

But if you're reading this book, chances are you're either programming apps, servers, or games. And therefore most of your code doesn't deal with multi-second uninterrupted parallel CPU computations. You're not computing the digits of π. You're building UIs and serving data. The benchmarks above don't really apply then.

For example, let's say you're about to write some server-side code and you have a choice between C# and PHP. Looking at the data above, you could get the idea that C# is obviously the better choice, performance-wise. I mean, C# is apparently about 20x faster than PHP, right? How could the data be any more clear?

Yet, in 2022, a blogpost called [Yes, PHP Is Faster Than C#](https://withinboredom.info/2022/03/16/yes-php-is-faster-than-c/) made the rounds on the internet, and it made a pretty convincing argument that, at least in reading files (a common task for web servers), PHP is faster than C#. Soon, a C# blogger responded to this with a pretty convincing argument that, no, actually, C# is faster.[^3] But only for smaller files and only if you know what C# API to avoid, and _especially_ if you know how to do vectorization. That's a far cry from "C# is 20x faster than PHP".

My point is not that PHP is faster than C#. It's not, and measuring simple file access is at least as shallow a benchmark as anything in _The Benchmark Game_. My point is that the numbers from benchmarks such as _The Benchmark Game_ simply don't translate neatly to real-world app performance.

There _are_ stabs at better real-world benchmarks out there, though they're not as well-known as _The Benchmark Game_. For example, _The Programming Language Benchmarks_[^progbench] project measures things like JSON serialization and deserialization, and HTTP servers, and RegEx. Here, Dart tends to be in the middle of the pack, behind Rust and D, comparable to Go and C# and Typescript, and faster than Python, Java, and Kotlin.

But even *these* benchmarks are far from useful. Because most languages implement things like JSON serialization and HTTP and RegEx *internally*, in a lower level language. When you parse JSON in JavaScript, for example, the actual parsing is done by code written in C++. So unless your app is a thin wrapper around a JSON parser, and you're parsing huge JSON files every frame, you don't care.

[^progbench]: https://programming-language-benchmarks.vercel.app/

Ideally, we'd have something like _The Benchmark Game_ or _The Programming Language Benchmarks_, but with apps instead of long-running batch jobs. Have a representative set of typical, complex apps. Implement them in C, Rust, Java, Swift, Dart, JavaScript, ideally using a variety of frameworks. Then measure their performance.

%% (comic: go app go!) %%

But I have a feeling this is never going to happen. There just aren't enough motivated developers to put the work into implementing so many versions of so many otherwise-useless apps. The programs in _The Benchmark Game_ are all at most a few hundreds of lines of code. That's just not going to be enough to build complex-enough apps, especially if you're using something like C or Rust.

The next best thing is to compare *game* performance, and that's actually something I did in 2024.[^gameperf] I wanted to compare Flutter, in terms of performance, to the most important game engines out there: Unity and Godot. I designed a simple "game" to exercise the most important muscles a game developer might want in a game engine, such as the ability to track and update many game objects at once.

Flutter (and therefore also Dart) actually did pretty well. Unity is a game engine written in C++ with game logic written in C#. Godot is also a C++ game engine, with game logic written in GDScript (a proprietary programming language similar to Python in syntax but optimized for speed). Again, if you look back at the results from _The Benchmark Game_, you might assume that Unity and Godot will wipe the floor with Flutter.

I'm not going to repeat all my findings here but, suffice to say, Flutter was actually holding up quite well next to the big boys. It was able to track more than enough game objects without missing frames (more than Godot, in fact) and it was more battery-efficient.

![[image9 1.png]]

![[image6 1.png]]

And, not surprisingly, it was several times faster at startup.

![[image3 1.png]]

So yes, Dart is fast enough. Sure, there are areas in which other languages compare favorably to Dart. But unless you're doing something very special, you won't have issues with that. Your bottlenecks are probably going to be somewhere else than in the programming language.

[^gameperf]: https://filiph.net/text/benchmarking-flutter-flame-unity-godot.html

[^3]: https://dev.to/goaty92/in-response-to-yes-php-is-faster-than-c-2a2g


[^1]: https://benchmarksgame-team.pages.debian.net/benchmarksgame/index.html