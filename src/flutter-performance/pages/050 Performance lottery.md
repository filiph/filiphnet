---
title: "Chapter 5: Performance lottery"
description: The unpredictability of app performance.
created: 2025-03-03T08:00:00.000Z
publish: true
---

==WARNING:== This chapter is unfinished.

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

Ok, now I think you're ready for the explanation _for this particular instance of performance lottery._ Turns out that ... %% governors %%

==TODO CONTINUE HERE==

%%
TODO: what performance lottery is, what is meant in most instances (cache misses etc.), lead into the following -> scientific method
%%