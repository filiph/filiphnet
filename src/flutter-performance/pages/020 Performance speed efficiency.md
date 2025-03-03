---
title: "Chapter 2: Performance, speed, efficiency"
description: What's the difference?
created: 2025-03-03T08:00:00.000Z
publish: true
---

==WARNING:== This chapter is unfinished.

I'm intentionally calling this book "Flutter Performance" even though the term is vague. That's because, if you care about optimizing apps or games, you're not looking at one neat metric. You have to have a more complex view.

That said, we can build such a view from smaller parts.

### Efficiency

Efficiency is the easiest term to define and measure. Given a problem, the more efficient program simply *does less work*.

Let's say you want to find the highest number in a list of numbers. That's the problem. In practical terms, efficiency is how many CPU instructions you need to execute to get the highest number. The fewer instructions you execute, the more efficient your program.

%%
```c
double findMax(double* array, int length) {
    int i;
    double current;
    double max = 0;

    for (i = 0; i < length; i++) {
        current = array[i];
        if (current > max) {
            max = current;
        }
    }
    return max;
}
```
https://godbolt.org/
https://gcc.gnu.org/onlinedocs/gcc/Optimize-Options.html
%%

Here's an example of ARM64 assembly code for finding a maximum value in an array:

```asm
findMax:
        sub     sp, sp, #48
        str     x0, [sp, 8]
        str     w1, [sp, 4]
        str     xzr, [sp, 32]
        str     wzr, [sp, 44]
        b       .L2
.L5:
        ldrsw   x0, [sp, 44]
        lsl     x0, x0, 3
        ldr     x1, [sp, 8]
        add     x0, x1, x0
        ldr     d31, [x0]
        str     d31, [sp, 24]
        ldr     d30, [sp, 24]
        ldr     d31, [sp, 32]
        fcmpe   d30, d31
        bgt     .L7
        b       .L3
.L7:
        ldr     d31, [sp, 24]
        str     d31, [sp, 32]
.L3:
        ldr     w0, [sp, 44]
        add     w0, w0, 1
        str     w0, [sp, 44]
.L2:
        ldr     w1, [sp, 44]
        ldr     w0, [sp, 4]
        cmp     w1, w0
        blt     .L5
        ldr     d31, [sp, 32]
        fmov    d0, d31
        add     sp, sp, 48
        ret
```

And here's the same program, but compiled in a higher optimization level. The listing above was compiled with the `-O0` flag (default mode). The listing below was compiled with the `-O3` flag (a lot more optimizations enabled).

```asm
findMax:
        movi    d0, #0
        cmp     w1, 0
        ble     .L1
        add     x1, x0, w1, uxtw 3
.L3:
        ldr     d31, [x0], 8
        fcmpe   d31, d0
        fcsel   d0, d31, d0, gt
        cmp     x1, x0
        bne     .L3
.L1:
        ret
```

Even if you've never seen assembly, you can probably tell that the second listing does less work. There are simply fewer instructions. The unoptimized version does a lot of loading (`ldr`) and storing (`str`) into memory, and lacks the obvious optimization of skipping the whole function if the list is empty (`cmp w1, 0` — is the length zero? `ble .L1` — if so, jump to the end of the function). 

More efficient code does less work, and therefore draws less energy and improves battery life. 

It also generally finishes faster. But not always.

### Speed

A program can do less work but still be slower.

One obvious way this happens is when using parallelism. A Dart program can spawn a separate isolate and outsource half of its work to it. By doing so, it will be finished almost twice as fast, but it will also have to spend CPU cycles on managing the extra isolate do it'll do slightly more work. Slightly lower efficiency, more complex code, but also much faster execution.

Another reason why efficiency and speed sometime don't go hand in hand is the fact that not all CPU operations take the same amount of time. A CPU loads a number from memory address `x0` to register `d31`. (That's `ldr d31, [x0]` in ARM assembly.) This operation can take something like 1 nanosecond if the address `x0` happens to be in Level 1 (L1) cache that sits right next to the CPU. But the same load instruction will take 70-100 nanoseconds if `x0` is currently not in one of the L1-L3 caches and must be obtained from RAM. (This is why data locality %% TODO is this the word? %% matters and why we'll be coming back to this.) So, once again, you can do fewer instructions and therefore have higher efficiency but still be slower. 

%% https://en.wikipedia.org/wiki/CPU_cache %%

![[Screenshot 2025-01-13 at 15.27.53.png]]
  
### Jank // Smoothness

Now, this is where we might stop if we were building mainframe programs. In the old days — like, way before my time even — the most important programs were batch jobs. Think about something like cracking a military code, where you feed a program with the encoded message and some parameters, and you let it run for minutes or even hours. Same with weather forecast or a ballistic research computer, which runs a physics simulation for a long time before spitting out a result.

These programs needed efficiency and speed, of course, especially since hardware was so slow and expensive back then. What they didn't need was nice user experience.

If you were running a weather forecast simulation in the 1960s, you didn't care how usable or unusable the computer got while it was processing — because the simulation was probably the only program running. You just patiently waited.

Today, though, most computing is different. You expect your pocket computer to update a multi-megapixel screen at least 60 times per second while it's also decoding an animated gif meme on the background. Most computation comes in very short bursts between frames, not in multi-minute batches.

Our tools and our thinking sometime haven't caught up to this new reality. So many people on the internet stress over the wrong kind of performance. They write and publish benchmarks as if we were all still living in the mainframe days.

Tight loops that run for

==TODO: finish chapter==

%% ==XXX START HERE==

TODO: This is also when all our tools were built — so we make benchmarks and use perf tools.

TODO: We're not building batch programs, Perception


### Memory consumption

TODO: Take too much memory, and you degrade the system's performance or even kill your own app.
TODO: Also, more memory means more GC pauses.


### Performance

TODO: the most fluffy but also the goal
 %%