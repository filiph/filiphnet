---
title: "Making my 1970's-style renderer multi-threaded"
description: "A tech deep dive into multi-threading in Flutter & Dart."
created: 2025-11-21T09:00:00.000Z
date: November 2025
social_image: https://filiph.net/text/imgs/Screenshot 2025-11-21 at 15.00.07.png
publish: true
---

The following article describes a Flutter use case that is so niche that I wouldn't be surprised if I'm literally the only person who has it at this point.

Still, I personally love to read deeply technical articles even when their usefulness for me is unclear at best — so I decided to write this anyway. 

## Use case

My game is mostly 2D, but it includes a retro 3D renderer. From the start of working on the game, I wanted a specific look which I'm going to call "a combination of 1970s sci-fi aesthetic and modern military UI".

<video width="50%" playsinline autoplay muted loop>
<source src="giant-robot-game-renderer.mp4" type="video/webm" />
Download the
<a href="imgs/giant-robot-game-renderer.mp4">WEBM</a>
video.
</video>

For this aesthetic, a "normal", modern 3D renderer just wouldn't work. So I decided to create a software (non-GPU) 3d renderer mostly from scratch. This allowed me to have complete control over every aspect of the final look of the 3d objects, and since we live in the 21st century, our contemporary computers are more than capable of running the renderer at high framerates.

## Single-threaded beginnings

As a rule, I try to build every prototype feature single threaded first before adding the complexity of concurrency. 

Since we're talking about 1970s graphics running on 2020s computers, I was able to keep the renderer single-threaded, _on the main thread_, for something like 2 years.

Then again, a 3d renderer is a 3d renderer, so I didn't completely ignore performance during that time. 

One cool thing about Flutter is that you get access to some low level drawing APIs, including `Canvas.drawVertices`. This method allows you to send a list of triangles (with various colors and/or textures) basically straight to the GPU. Perfect for my use case. 

Pretty soon after implementing the initial 3d renderer, I addressed the fact that I'm creating a new list of triangles every frame. That means a lot of memory allocation and garbage collection. So I went with the slightly more low-level method of creating lists in Dart: `TypedData`.

Dart classes like `Float32List` (which is a subclass of `TypedData`) allow you to allocate a continuous block of memory. In this case, a continuous array of 32-bit floating point numbers. In contrast to how you would do it normally (with `List<double>`), you and the compiler have an understanding that this is really a continuous block of numbers, it can't be split, it can't be appended (without copying), and it contains only plain values (no boxed values). Sometimes, this is exactly what you want — it's fast, simple, and already in a format that other parts of the computer (e.g., the GPU) understand.

So far, so good. You can hear me talk about `drawVertices` and typed data buffers in this talk:

<iframe width="560" height="315" src="https://www.youtube-nocookie.com/embed/pD38Yyz7N2E?si=g2kNxZnlS_WGyIR-" title="YouTube video player" frameborder="0" allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture; web-share" referrerpolicy="strict-origin-when-cross-origin" allowfullscreen></iframe>

So, now we have a software 3d renderer written in Dart (a high level GC'd language) that blits triangles to the screen while allocating almost no memory from frame to frame. For a modern PC, the performance is more than acceptable. 

## Road to multi-threading 

But then I realize I would sometimes like to show many independent 3D models at once. And I'm also adding more and more game logic, including marching square computations for multiple heightmaps on every frame. And I never wanted the game to be exclusive to modern machines - I want the game to be playable on potatoes.

![[Screenshot 2025-11-21 at 15.00.07.png]]

I do some profiling and, on Widows (which I expect to be my main audience), the renderers take something like 20-30% of CPU time. Even with the optimizations above. That's a lot for something that's an aesthetic choice and not crucial to the game's simulation. And remember, this is all still happening on the main thread (`Canvas.drawVertices` can't be called from anywhere else).

So, it's time to move the 3D renderer to a separate thread.

## Shared memory in Dart

Dart's concurrency model is based on *isolates*. The following is a gross simplification, but Dart isolates are threads that don't share any mutable memory (i.e., they're _isolated_). The features is inspired by [Erlang's processes](https://www.erlang.org/docs/23/reference_manual/processes) and by the web platform's [WebWorkers](https://html.spec.whatwg.org/multipage/workers.html).

The isolation is a fantastic feature because shared mutable memory is a major source of really-hard-to-debug bugs. If you don't believe me, the next time you're with a C++ or Java programmer, casually mention the word `thread` or `mutex` and see their eyes twitch.

With isolate-based concurrency, you don't need to deal with deadlocks and concurrent modification bugs because your "threads" (isolates) can only communicate by sending each other messages. These messages are always deeply copied, so you can't accidentally trample on another isolate's collection, for example. You get your own copy.

This works great for many use cases. 

- You want to compute something? Just send the input of the computation to an isolate: it will take it, run the computation, and send the result back when it's done.
- Want to extract some information from a giant JSON file on disk? Just send the path to an isolate: it will read the bytes, decode them to a `String`, parse it, find what you need, and send the information back packaged as a nice Dart object.
- Want to download an image, make a non-trivial transformation to its bytes, and receive the result? No problem. Just send the URL to an isolate: it will download the bytes, do the transformation, and send you the result. An astute reader might wonder: so the transformed data are copied from isolate to isolate? By default, yes. But you can use something called `TransferableTypedData` to basically transfer the ownership of the resulting bytes — no copying involved.

But then there's my use case. I could prepare the typed data buffers inside an isolate, but then by sending them to the main isolate, I either have to copy them, or I have to transfer their ownership. So I'd have to start anew for every new frame, allocating a new block of memory. That's something I want to avoid.

## FFI to the rescue

Thankfully, while Dart itself tries to keep you away from the foot-gun that is shared memory, it also has to talk to other systems that don't have such luxury. Notably, the C foreign function interface (FFI) — a standard way by which different programming languages communicate with each other using the lowest common denominator of C function calling.

Without leaving Dart, you can allocate memory on the native heap and ask Dart to free it once you don't need it anymore:

```dart
import 'package:ffi/ffi.dart';

const n = 40;
final pointer = malloc.allocate<Int64>(n * Int64List.bytesPerElement);
final array = pointer.asTypedList(n, finalizer: malloc.nativeFree);
```

I learned this API [from mraleph (Slava Egorov) on the Flutter Forum](https://forum.itsallwidgets.com/t/how-does-the-dart-vm-manage-os-threads-under-the-hood-when-multiple-isolates-are-created/3506/8?u=filip). Forums, btw, are treasure troves of information and deep technical discussions. (Full disclosure: I'm a mod on the aforementioned forum and it was kind of my idea to start it. But I happily give all credit to the person who _actually_ started it, Hillel Coren of *It's All Widgets* fame, and to [all the other people](https://forum.itsallwidgets.com/u?order=post_count&period=all) who are active there.) Seriously, if you want to keep your sanity, I can highly recommend limiting your time on social media and instead joining a focused forum.

Anyway, now we have a way to share mutable arrays across isolate boundaries:

- The `array` object above is of type `Int64List`. Except it's backed by memory outside the Dart heap.
- As long as `array` is reachable, the memory will be allocated. Afterwards, Dart calls `malloc.nativeFree` to free the block of memory. (This means that you probably want to assign the array to a field of some long-living object — otherwise the memory will get freed as soon as `array` is no longer in scope.)
- You can send the `pointer` to another isolate. The pointer is just a memory address, so copying it while sending is basically free.
- The other isolate can also call `pointer.asTypedList(n)` (_without_ the finalizer) to get its own buffer, backed by the same block of memory.
- This also means you should send the `n` to the other isolate, so it knows how large the buffer is.

## Putting shared mutable memory to work

So, now that we have a way to punch a hole (as Slava puts it) into Dart's concurrency isolation model, how do we actually make it work?

Here's how:

- When the widget that renders 3D (I call it `Retro3D`) is added to the Flutter widget tree, it first loads the bytes of the 3D file from assets. (`AssetBundle` is not available outside the main isolate, AFAIK.)
- Then it constructs an `IsolateRenderer` (a completely custom class) and asks it to `initialize()` with the file bytes and some initial, immutable information about the scene.
- The `IsolateRenderer` spawns the worker isolate and sends the data over with the initial message. It then starts waiting for messages from the worker isolate.
- Inside the worker isolate, the bytes of the 3D file are parsed into a 3D scene.
- The worker isolate counts the number of vertices and faces in the scene. This informs the size of arrays that will be needed for the draw calls. (For example, for `n` vertices, you need a `Float32List` of `n*2` elements — two 2D coordinates per each vertex. Similarly, for `m` triangles, you need an `Int32List` of `m*3` elements — one ARGB color for each point on the triangle.)
- The worker isolate sends a `_BufferAllocationRequest` message to the main isolate with the sizes it needs.
- `IsolateRenderer` allocates the memory using `malloc.allocate()` and creates two sets of buffers, #1 and #2. It saves these buffers into a field (`IsolateRenderer._renderBuffers`) so that they aren't freed prematurely. It then sends the pointers back to the worker isolate as a `_UseTheseSharedBuffers` message.
- The worker isolate creates its own `TypedData` objects using the pointers it received.
- Now we have shared mutable memory. It's important that we avoid concurrent modification (for example, main isolate sending the vertex buffer to the raster thread _while_ it's being worked on by the worker thread). That's why we have two buffers, #1 and #2.
- The worker isolate sends an `_IsolateIsReady` message to the main isolate.
- `IsolateRenderer` receives this message and completes its initialization.
- From now on, the `Retro3D` widget listens to changes to a `ChangeNotifier` called `SceneViewConfig`, and every time there's any change (e.g., moved camera, changed zoom), it calls a method on `IsolateRenderer` called `requestNextFrame()`.
- `requestNextFrame()` uses a `CancellableOperation` to debounce the calls, so that we don't accidentally ask for five consecutive renders in quick succession (just because some other part of the code changed 5 different things about the `SceneViewConfig`, one after the other).
- `requestNextFrame()` sends a `RenderConfig` message to the worker isolate. The `RenderConfig` object includes things like the camera position, zoom, but also the current viewport size and the `RenderConfig.id` (which exists mostly for debugging — to link requests to later renders).
- The worker isolate receives the `RenderConfig` message.
- It switches to the next buffer (if it was on #1 before, it goes to #2, and vice versa). Thanks to the fact that the rendering is all synchronous, and messages in isolates are processed in order, we know that double buffering (i.e. two buffers) is enough. One buffer is always "done" and the other one is being worked on.
- The worker isolate does the rendering and fills the shared memory buffers with its output.
- When done, the worker isolate sends back a `_RenderReady` message. This message only contains the _index_ of the used buffer (#1 or #2), which is a single integer. So there's no copying of large amount of data, nor any kind of re-allocation. The message also contains some additional data, such as the current polygon count (some polygons might be hidden and therefore not present in the render mesh) and the projection matrix (so that the main thread can compute where to put labels on the render).
- `IsolateRenderer` receives the `_RenderReady` message and transforms it into a `RenderResult` which contains all the data needed for a `Canvas.drawVertices()` call. So, the index of the buffer received from the worker isolate is used to find the actual `TypedData` objects.
- The `RenderResult` is assigned as the new value of a `ValueNotifier`.
- This value notifier is used as a [`repaint` listenable](https://api.flutter.dev/flutter/rendering/CustomPainter/CustomPainter.html) for the `CustomPainter` that actually paints the 3D render on the screen.
- Now we have a loop — any change to `SceneViewConfig` leads to a `requestNextFrame()` call, which in turn sends a `RenderConfig` to the worker isolate, which renders it into one of the shared buffers, then notifies the main isolate, which repaints using the new data.

The result is noticeable, even when running on a very powerful device. On my M4 MacBook Pro, when showing three 3D renders at once, average time taken by a frame on the main thread goes from 3.7 ms to 2.9 ms. That's 20% improvement on a thread that currently does a _lot_ of other things (from physics simulation through marching squares all the way to AI).

![[Screenshot 2025-11-21 at 12.47.04.png]]

Basically, the main thread's cost of displaying all these 3D models went from 20% of its overall CPU time to close to zero.

## The future of mutable shared state in Dart

The Dart team is experimenting with a more direct support for shared mutable memory. [The proposal](https://github.com/dart-lang/language/blob/main/working/333%20-%20shared%20memory%20multithreading/proposal.md) is written by the aforementioned Slava Egorov (the Dart Tech Lead), and discusses things that go beyond simple arrays. For my current use cases, that would probably be overkill, but I'm _very_ happy that the Dart team thinks about supporting advanced (and scary and unsafe) programming. It's the only way Dart can truly become a powerhouse general-purpose programming language. Give people sane, safe tools to work with, but also allow them to bring out a chainsaw if they must.

## Was AI useful here?

It's late 2025, and so I feel the need to address the obvious question of "was any of this code written by an A.I."? I initially hoped so, because it seemed like a good fit. The code is already there, just put it into an isolate and come up with a message passing scheme.

But the reality was quite dismal. Even when I asked it to simply implement some standard `Isolate` boilerplate based off the shared memory example I've already written, it introduced a bug. After that, I got so nervous (the bug was not easy to spot) that I just implemented the whole thing myself. It took me a day, and some of it was spent chasing my own bugs (freeing memory twice, a classic) but most of it was iteratively crafting the code to my liking.

As a rule, I'm trying to force myself to use A.I.: to get out of my comfort zone, and to reap the benefits of this new technology. But increasingly, I fear that my opinion on LLMs is starting to set, and I see them not as independent coding agents I can trust, but more like fast code generators. There's a huge gap between what current LLMs can dependably do, and the <abbr title="Chat Oriented Programming">CHOP</abbr> vision of "I'll be a tech lead and the AIs will be my team". Maybe this works in some scenarios, but I just haven't been able to make it work.

Where current AI _does_ help is, in my opinion:

- write easily definable functions or methods (these _can_ be advanced, but only if the problem at hand is common enough in the training data), or tests
- "fill in the gap" kind of work (e.g. look at this one class and create the other classes that are obviously related)
- kick-start — I need to do something but I'd normally postpone doing it because I can't decide where to start. Instead of postponing, just ask the AI for the first step and it will make the initial decisions and the boring boilerplate work for you.
- cookie-cutter programming in languages you're not an expert in (e.g. modify my website to have automatic syntax highlighting on `<code>` blocks)

This is already _huge_ help, don't get me wrong. It's just that I currently don't see an easy path from here to "AI agent can do expert level programming on my behalf".

## Future work

I'm obviously not done with the game or its optimization. Choosing Flutter & Dart to implement a simulation-heavy real-time game has its upsides (like ease of development; portability) but also its downsides (something like C++ still slays in terms of performance, especially compared to GC'd languages like Dart; Unity & Godot come with so many more bells and whistles). I chose the trade-off knowingly: it makes perfect sense for me (a Flutter expert who actually _enjoys_ building games solo from a text editor) and for the project at hand (a game full of complex interlocking systems and experimental UI). I'm far from suggesting that it makes sense for anyone else.

So this post isn't some kind of a "here's how you do it" explainer. It's more of a "look at this obscure problem I had" kind of article.

If you _do_ find any of the above useful or at least entertaining, I'm happy.

**P.S.:** The multi-threaded renderer update is now up on Steam if you want to [playtest it](https://store.steampowered.com/app/2538440/GIANT_ROBOT_GAME/).
