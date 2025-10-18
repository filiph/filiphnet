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
2. [Performance, speed, efficiency](/flutter-performance/020-performance-speed-efficiency.html)
3. [Is Dart fast enough?](/flutter-performance/030-is-dart-fast-enough.html)
4. [Amdahl's law](/flutter-performance/040-amdahl's-law.html)
5. [Performance lottery](/flutter-performance/050-performance-lottery.html)
6. [Environment](/flutter-performance/060-environment.html)
7. Performance profiling vs analysis vs benchmarking vs testing %% input (things are slow), profiling (where are things slow?), analysis (why?), optimization (let's make it better), benchmarking (is it better now?), monitoring (does it stay better?), testing (will it stay better?) plus engineering (holistic approach, all of the above, continuously) %%
8. Benchmarking - Easy mode %% What is benchmarking for? tight loop/hot path. Remember: it's tooling from the days of batch programs -- it may not be important; code locality is high, though — 80% of total execution is covered by 50 to 150 functions (JSMeter 2009). Easy mode: C++, batch, min(values). Only if you don't allocate, or don't care.  ; maybe look at claim from https://medium.com/@chetan.akarte/what-is-symbol-in-dart-4483b2f7f5d6 - Symbols faster? actually no. despite that, LLMs recommend it https://kagi.com/assistant/92a6d6ff-fcef-41d4-b0e5-21a16ef7a661, run longer work rather than repeat something short. If it's really short, it probably doesn't matter. If it happens in a tight loop, measure the thing that runs the loop.%%
9. Statistics for performance engineers %% It's almost always distributions, not single numbers. Normal distributions. %%
10. Benchmarking - Normal mode %% Gather all samples. Find statistic (`t_stats`). Always read raw data. Always visualize. Use `benchmarkWidgets()`. %%
11. Data visualizations for performance engineers %% always visualize. rug chart, histograms, violin plots etc. %%
12. Benchmarking - Hard mode %% life is multimodal. In Dart, some of these "lesser" modes are important (it's where GC happens). But there's also noise! Also, how do you compare multimodal distributions? Pareto front / domination. ; multimodality doesn't matter for things that take a short time even at their worst. Just use mean for that. %%
13. Benchmarking - Nightmare mode %% DoNotOptimize away, read CPU instructions %%
14. CPU Profiling (`time -v`, flame chart, `perf`, `simpleperf`)
15. Timeline %% Frame Pipeline (frame budget, ui vs raster thread), `dart:developer`, maximize minimal frame rate (not average framerate) %%
16. Raster thread optimization %% (oversized images, RepaintBoundary?, debugDisableOpacityLayers, debugPaintLayerBordersEnabled, checkerboardRasterCacheImages, ) %%
17. Memory (caching, memory pressure, memory leaks, GC, GC jank, WeakReference)
18. Data structures (TypedData, Buffers, "Efficiency with Algorithms, Performance with Data Structures")
19. FFI
20. Parallelism & Concurrency (Futures, async/await, isolates, "Dart is not multithreaded", `pragma("vm:shared")`)
21. Pragmas
22. Inlining
23. Understanding Dart Kernel Representation
24. SIMD / vectorization
25. Interop with the platform (the other side of method channels, FFI) %% out of scope, but mention e.g. Xcode’s Organizer %%
26. Continuous performance testing %% stress testing, browserstack - a farm of actual devices %%
27. Sleights of hand (perceived performance magic tricks)
28. A bag of tricks


%%
bag of tricks

1. JSON parsing
2. SnapshotWidget
3. Thunks (e.g. logging takes function, not a computed value)
4. `late final` (like a thunk)
5. "stub"
6. emojis are slow on iOS because they're SVGs https://forum.itsallwidgets.com/t/flutter-performance-book/2777/9
7. consider using `SchedulerBinding.scheduleTask` with low priority for initializing stuff

%%

No guarantees the book will ever be finished but if you want to be notified, subscribe to [my mailing list](https://filiph.net/await).


