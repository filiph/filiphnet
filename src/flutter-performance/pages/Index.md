---
title: "Flutter Performance Book"
description: Filip’s book-in-writing on Flutter & Dart performance.
created: 2025-03-03T08:00:00.000Z
publish: true
---

Hi, I'm Filip. I worked on the Dart and Flutter teams at Google between 2016 and 2021, and I've been involved in Flutter performance, specifically, for over 7 years now. I've helped a few Flutter startups from performance-related trouble, and I've done more than my share of education and outreach.

![[Screenshot 2025-03-03 at 10.47.48 1.png]]

You may recognize my face from the official Flutter YouTube channel. Some of the veterans of Flutter development might remember my Flutter performance talk at Flutter Europe 2020 or maybe they've read my old Medium.com articles on performance testing and raster thread optimization.

<!-- Flutter Europe 2020](https://www.youtube.com/watch?v=SQcmrl_NkqY) -->

Here, I plan to put together a more coherent story of how to build performant Flutter apps and games. While most developers are probably fine knowing a few tips and tricks here and there — and can still deliver performant apps — I believe there's a need for a subset of Flutter developers who become performance experts. Every organization using Flutter would benefit from a [Winston Wolfe](https://en.wikipedia.org/wiki/Pulp_Fiction#Cast) that knows what to do when things get slow or inefficient.

![[pulp-fiction.gif]]

That could be you. Performance optimization is a vast and complicated topic but it's learnable and — dare I say — fun.

## Chapters

I'm writing the book in the open so that I can get feedback ([email me](mailto:filip.hracek@gmail.com), [message me](https://mastodon.social/@filiph), or [discuss](https://forum.itsallwidgets.com/t/flutter-performance-book/2777)). Here's a very rough outline. Chapters that are drafted already are linked.

1. [Intro](/flutter-performance/010-intro.html)
2. [Performance, speed, efficiency](/flutter-performance/020-performance-speed-efficiency.html) (unfinished)
3. [Is Dart fast enough?](/flutter-performance/030-is-dart-fast-enough.html)
4. [Amdahl's law](/flutter-performance/040-amdahl's-law.html) (math formulas in LaTeX don't render yet)
5. Performance lottery
6. Statistics for performance engineers %% Scientific method %%
7. Performance profiling vs analysis vs benchmarking vs testing %% Performance Profiling/Analysis (what's wrong), Benchmarking (which is better), Testing (are things ok?) %%
8. Benchmarking (tight loop/hot path, DoNotOptimizeAway) %% remember: it's tooling from the days of batch programs -- it may not be important %%
9. CPU Profiling (`time -v`, flame chart, `perf`, `simpleperf`)
10. Timeline %% Frame Pipeline (frame budget, ui vs raster thread), `dart:developer`, maximize minimal frame rate (not average framerate) %%
11. Raster thread optimization %% (oversized images, RepaintBoundary?, debugDisableOpacityLayers, debugPaintLayerBordersEnabled, checkerboardRasterCacheImages, ) %%
12. Memory (caching, memory pressure, memory leaks, GC, GC jank, WeakReference)
13. Data structures (TypedData, Buffers, "Efficiency with Algorithms, Performance with Data Structures")
14. FFI
15. Parallelism & Concurrency (Futures, async/await, isolates, "Dart is not multithreaded", `pragma("vm:shared")`)
16. Pragmas
17. Inlining
18. Understanding Dart Kernel Representation
19. SIMD / vectorization
20. Continuous performance testing
21. Sleights of hand (perceived performance magic tricks)
22. A bag of tricks


%%	1. JSON parsing
	1. SnapshotWidget
	2. Thunks (e.g. logging takes function, not a computed value)
	3. "stub"
18. Continuous performance testing
	5. browserstack - a farm of actual devices
19. --
20. Pragmas
21. Inlining
22. Understanding Dart Kernel Representation
23. SIMD / vectorization %%

No guarantees the book will ever be finished but if you want to be notified, subscribe to [my mailing list](https://filiph.net/await).


