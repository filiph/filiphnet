---
title: "Chapter 5: Performance lottery"
description: The unpredictability of app performance.
created: 2025-03-03T08:00:00.000Z
publish: true
---

Let me tell you a true story. In early 2019, we were building a demo game for that year's Google I/O developer conference. In terms of programming, it was mostly Luigi Rosso (of Rive fame) and me, and at one point I decided to have a look at the game's performance. Not that we saw any major issues: I just wanted to make sure that I'm not unwittingly releasing a piece of "evidence" that "Flutter is slow". 

%% https://github.com/2d-inc/developer_quest  https://github.com/2d-inc/developer_quest/graphs/contributors  %%

I wrote a benchmark and ran it on my testing Android device. I saw some high frame build times, so I made an obvious performance optimization, and ran the benchmark again.

To my surprise, the optimization made the app _slower_. Build times were longer and framerate was lower. A complete disaster.

I though I was going crazy (a common symptom of dealing with performance lottery, by the way). I was inexperienced, so I worked under the assumption that my optimization _must_ be flawed somehow. Unfortunately, I don't remember what that optimization was, exactly, but you'll have to trust me it was something really obvious.

Anyway, I sunk several hours into this. At some point, I was so frustrated that I put a `print()` statement into a function in order to confirm that the function is actually being called every frame. %% Remember: this was a game, and games often have update functions that run on each frame. %% The print statement worked, and I saw a bunch of output in the console scroll by. (Back then, Android `logcat`'s "Fold similar content" feature didn't exist yet, so duplicate log messages weren't collapsed into a single one. I really _did_ see the messages scroll by, at a rate of about 60 lines per second.)

And then I noticed that this change, *the addition of a completely useless `print()` statement,* made build times significantly *shorter*. There was suddenly no jank.

![[ab9ce9447edbe163a066d0eff0318459.jpg]]

WAT?

Now, listen. Even this bizarre incident has a perfectly reasonable explanation. Of course that adding a print statement doesn't actually improve performance. But, before I get to the explanation, I want to emphasize how completely random this seemed to be at the time. I want to marinate you a bit longer in this state of confusion so that you deeply understand the true meaning of "performance lottery." A _single line_ that should have had a _detrimental_ effect to performance, if any, actually _improved_ performance in _all_ the ways I measured. Imagine yourself looking at this kind of result, and being able to reproduce it again and again.

Madness. Absolute madness.

Ok, now I think you're ready for the explanation _for this particular instance of performance lottery._ Turns out that modern mobile operating systems have something called a governor. This is a power management component that adjusts CPU clock speed (i.e. frequency) according to some predetermined rules. 

So if the governor believes that the smartphone is more or less idle, it will lower the processor frequency. Then, when you touch the screen, for example, the governor will immediately set the CPU clock speed to maximum. (This happens instantaneously, so the user has no idea their phone just got significantly faster. There's no perceptible "warm-up" period.)

The idea of governors is fantastic for us as everyday users. Governors let us use our hardware to its fullest when needed, but they also save battery and decrease device heat.

The same idea, unfortunately, is also absolute poison for as as performance engineers.

You may have already guessed what happened with my unexpected `print()` speedup. Before I added the print statement, the governor evaluated the game as something that doesn't really need high performance. It was doing just fine on a lower clock speed, so why waste battery?

Then, I introduced the `print()` statement. I know that a single print statement doesn't look like much but remember that, on an Android device (at least at that time), each of those print calls meant that:

1. Dart needed to allocate memory for the new `String` (it was not a constant literal but something dynamic, such as `"iteration $i"`)
2. Dart needed to send the `String` to the Android OS logging subsystem
3. Android OS had to receive the String and put it into its log ring buffer (`logcat`)
4. Android OS then had to _send_ the log message via USB Debugging connection to my workstation (which was running the performance test in profile mode)

That's not a _lot_ of work, but it was enough to push the game — in the eyes of the governor — to the "needs more CPU clock speed" category. Rather than letting the app jank, the governor decided to switch the device to high-performance mode. Again, this is a good choice from the user's perspective.

But it's also why a less efficient, more wasteful game was running significantly faster. Performance was improved by _adding completely unnecessary work._

Now, once I found out about governors, I sighed a deep sigh of relief ("I'm not going crazy yet") and started working on eliminating the influence of governors on performance testing. You can read more on that in the _Hardware_ chapter.

%% comic: what do you think would happen if he never found out about governors? -- I don't know. He'd probably get even crazier about performance. -- How so? -- I don't know. He'd write a book? -- He's already doing that. -- Yeah, ok, but he'd, like, add little drawings into it and stuff. -- Drawings? You mean like little cartoons? -- Yeah. -- Yeah, that would be pretty crazy. %%

Here, I'd like to return to the topic at hand: performance lottery. It's when you make a change to your code, and the observed performance effect is seemingly disconnected from that change.

Here are a few additional examples:

- You refactor a method and, by doing so, make it a few operations shorter. Suddenly, the shorter method fits into some compiler heuristic, and the compiler now optimizes it much better. This leads to faster code although your original change wasn't a performance optimization at all.
- You come up with a performance optimization for a tight loop. The effect of _your_ change is only 1% speedup but, incidentally, you also made an array in your code a tiny bit smaller (maybe from 17 elements to 16) and now things fit into the CPU's L1 cache. When you run your benchmark, you get an amazing 20% speedup, and you start to think of yourself as a performance guru. (Until you try that same optimization elsewhere — with big fanfare — and only see the meager 1% speedup because you don't win the performance lottery that time. So now you think of yourself as a performance clown.)
- You notice that a microbenchmark consistently runs slower on your colleague's workstation, even though the two machines are identical. After a long and arduous investigation, you realize that the culprit is _the username_. Your colleague's username is longer than yours. That means she runs the benchmark from a directory with a longer overall length (e.g. `/home/mylongusername/...`). The current working directory is in your environment variables, which are in memory, and so a different username length moves the program stack. This leads to a different memory layout, which can lead to a cache set conflict, which can have a significant impact on performance.[^mytkowicz] %% https://youtu.be/r-TLSBdHe1A?si=gHxDLwLwPoq1VrVZ&t=822, also https://users.cs.northwestern.edu/~robby/courses/322-2013-spring/mytkowicz-wrong-data.pdf %%
- You follow the common wisdom that inlining functions makes code run faster because it avoids the overhead of a function call (if you don't know what inlining is yet, don't worry, we'll get to that). So you inline as much of your code as possible. Unfortunately, you're building for a system with an infamously low memory throughput — so your inlining actually makes everything _slower_ without you realizing it. This is because the inlining makes the compiled machine code larger, and the device spends more time accessing it, which more than offsets any advantage of inlining. This one happened to Nintendo with their Super Mario 64 game on N64. When a modder named Kaze Emanuar "un-optimized" the game in 2024 (28 years after release!), he got significantly better performance. %% https://www.youtube.com/watch?v=Ca1hHC2EctY %%

[^mytkowicz]: I won't go into details of this one since it's so low-level and mostly relevant to C and C++ programmers. But if you're interested, I encourage you to watch Emery Berger's Strange Loop talk "Performance Matters" or read the paper by Mytkowicz et al. titled "Producing Wrong Data Without Doing Anything Obviously Wrong!" from 2009.

It's important to understand that, despite the name, performance lottery _isn't_ random chance. The processor doesn't throw dice to decide whether it will work fast or slow today. Every instance of performance lottery can be explained by some deterministic cause. Sometimes you find the cause, sometimes you don't — but it's always there.

In practice, though, it _is_ a lottery. Modern computing is so incredibly complicated and layered that any code change can have unintended knock on effects. Somewhere in the black box that is hardware architecture (branch prediction, pipelining, CPU cache hierarchy, ...) and software environment (governors, memory layout, compiler heuristics), something lurks that will make your code run either faster or slower. Sometimes, you'll figure it out. But often, you simply won't know why it happened, or even _that_ it happened.

Unless you want to spend the rest of your life trying to understand the entirety of the modern software and hardware stack, you better make peace with the fact that performance lottery is real.
