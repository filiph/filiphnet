---
title: "Chapter 4: Amdahl's law"
description: An explanation of Amdahl's law.
created: 2025-03-03T08:00:00.000Z
publish: true
---

## The parable of the islander

Imagine you're an islander and every week, you make a journey to a city inland. You don't want to waste time, so you decide to make that journey as short as possible.

{ MAP }

Half of your journey is on water, half on land. If you can only improve one of the legs of your journey, you should focus on where you can make the most impact. For example, upgrading from a very slow rowing boat to a motorboat that's 8x faster will have a larger effect than upgrading from a bicycle to a motorbike that's only 2x faster.

But the math gets a bit more interesting when the journey isn't half water, half land. What if you travel 1 mile on water and then 99 miles on land?

{ MAP }

Now, almost any improvement in land transportation will overshadow improvements in water transportation. You could buy the fastest speedboat in the world and gun it from your island to the coast at 300 mph — and yet this would hardly move the needle. Because you'd still spend the vast majority of your journey on land.

If you can only improve one of the legs of your journey, in this new scenario, you should focus on land transportation. Anyone with common sense can see this.

Yet we have trouble translating this simple concept to a more abstract field, such as software optimization.

## Amdahl's law

%% https://en.wikipedia.org/wiki/Amdahl%27s_law %%

Amdahl's rule is probably the most important thing you'll learn in this book. If you know it and live by it, you're fine. If you don't know it or ignore it, you'll waste hours and hours of your own time.

Gene Amdahl, in 1967:

> The overall performance improvement gained by optimizing a single part of a system is limited by the fraction of time that the improved part is actually used.

Arguably, that's a bit dry. Here's my paraphrasing:

> If you optimize something that doesn't happen all that often, you're wasting your time.

Now, when I say it like that, it seems obvious. But experience suggests that even very smart people _repeatedly_ fall into this trap.

## Math problem

Here's a little math problem for you. Try to first answer it without actually doing the math — just guess.

You're optimizing an app. By profiling, you find out that 5% of all frame build times are spent inside function `computeFoo()`. You optimize this function, making it 20% faster. What is the effect on overall build times? How much faster are they running now? In other words, what was the overall speedup?

This is not a trick question.

(Here's you chance to guess. What follows is the solution.)

The formula for overall speedup is:

$$
S_{\text{overall}}={\frac {1}{(1-t_{\text{opt}})+{\frac {t_{\text{opt}}}{S_{\text{opt}}}}}}
$$

where

- $S_{\text{overall}}$ (overall speedup) is the improvement ratio of the optimized code versus the unoptimized code. For example, a value of $2$ means that the overall performance has improved 2x (i.e. we've halved the execution time).
- $t_{\text{opt}}$ (time optimized)  is the fraction of execution time spent in the  function we're trying to optimize. For example, a value of $0.1$ means that we're optimizing a function that takes 10% of the overall execution time.
- Therefore, the term $(1-t_{\text{opt}})$ is the fraction of execution time spent _outside_ the function we're trying to optimize. In other words, it's the rest of the execution time.
- $S_{\text{opt}}$ (speedup optimized)  is the ratio by which we're able to improve the function. For example, if this is $1.01$, then we're making the function 1% faster.

In code, the above equality could be written as:

```dart
var speedupOverall =
        1.0 / ((1 - timeOptimized) + timeOptimized / speedupOptimized);
```

%% ![[Screenshot 2025-01-14 at 20.13.19 1.png]] %%

Assigning values from above, we get:

$$
S_{\text{overall}}={\frac {1}{(1-0.05)+{\frac {0.05}{1.20}}}}={\frac {1}{0.95 + 0.0416}} = 1.008403361345
$$

Yep. That's less than 1% overall speedup. And remember that we sped `computeFoo()` up by 20% (which is amazing in most scenarios) and that the function constitutes a whopping 5% of all execution time (which is a lot for a single function).

Many talented engineers are seduced by much less. You see people stressing over code that constitutes less than 0.01% of execution time. Even if they can make such code _100x faster_ (they can't), the overall speedup will be 1.0001. That's just 0.01%. 

In reality, they make the code, say, 30% faster, which gives them an overall improvement of 0.002%. They're almost certainly wasting their time.

%% 1/((1-0.0001) + (0.0001/100))  = 1.00009900980197 %%
%% 1/((1-0.0001) + (0.0001/1.3)) = 1.00002307745563 %%

Now, don't get me wrong: every improvement is an improvement, and sometimes you have no choice but to optimize by tiny fractions here and there.

It's just really, _really_ important to always have Amdahl's law in mind. Whenever you optimize, or even just start thinking about optimizing, have a rough idea of the value of $t_{\text{opt}}$. Are you optimizing something that takes 50% of the overall execution time? 10%? 1%? Less?

## Microbenchmarks suck

Amdahl's law is (one) reason you should ignore most microbenchmarks you find on the internet.

Microbenchmarks make for great online content. You can write an article or make a video about whether records are faster than classes, and people will like and share this stuff like it's the most important discovery that year. There might be a few cool heads who try to calm everyone down but it's hard to fight "OMG 50% FASTER!!!1" with long articles about boring topics such as Amdahl's law.

This is best explained by an example. Let's make a sensationalist performance "discovery".

Hypothesis: when returning structured data from a function, it matters whether we use a class or if we use a record.

Step 1 is to come up with the structured data. Remember, we're after a sensationalist "discovery" so it doesn't actually matter what the data looks like. This isn't tied to any real-life app we're trying to optimize. This is just a microbenchmark in a vacuum. So we can come up with something like this:

```dart
final class MyClass {
  final double real;
  final int integer;
  final String string;

  const MyClass(
      {required this.real, required this.integer, required this.string});
}

// versus

typedef MyRecord = ({double real, int integer, String string});
```

Now we build a benchmark that measures how quickly Dart can fill a large list of `MyClass` / `MyRecord` instances. For the sake of brevity, I'll skip how to do this properly for now — there's a whole section about building benchmarks later on in this book. Assume we did everything right and the benchmark actually measures what we want to measure. We get output like this:

```console
Baseline(RunTime): 3.375638812180594 us.
MyClass(RunTime): 5.149719312850859 us.
MyRecord(RunTime): 8.551375932340253 us.
```

And there you go, we can write our article: "Dart records are 66% slower than classes" or whatever. If we look at the overhead over baseline (again, wait for the appropriate chapter to learn more about benchmarking), we could even say that "Records are 3x slower than classes!"

%% (8.551375932340253 - 3.375638812180594) / (5.149719312850859 - 3.375638812180594) = 2.9174195411 %%

Cue everyone rewriting every record into a class.

But, since this is a chapter about Amdahl's law, you probably know what's next.

First of all, this benchmark is completely arbitrary so we _can't_ have an idea of what $t_{\text{opt}}$ is. (Remember, $t_{\text{opt}}$ is the *ratio* of the optimized time versus the overall execution time. Since there's no app, there _is_ no overall execution time.) 

But we could at least look at the time scales involved. Instead of saying "3x faster", let's have a look at the measured time.

The measured overhead of `MyClass` is 1.774 µs, and for `MyRecord` it's 5.176 µs. That makes `MyRecord` 3.4 µs slower. Oh, but wait, did I mention the times are for _1000 iterations._ 

So we're talking about _3.4 nanoseconds_ difference per operation.

%% 5.149719312850859 - 3.375638812180594 = 1.7740805007 %%
%% 8.551375932340253 - 3.375638812180594 = 5.1757371202 %%
%% 5.1757371202 - 1.7740805007 = 3.4016566195  %%

Now, remember, a single CPU cycle is about %% a 3GHz processor %% 0.3 nanoseconds. So something that makes a 3.4 nanoseconds difference is not going to be a problem unless your app does basically *nothing else.* You don't need to worry about it. If you see such a microbenchmark on the internet, feel free to ignore it.

%% ==TODO== maybe try this in a larger app (change class to record and measure some actual metric) %%

## The root of all evil

The legendary computer scientist, Donald Knuth, wrote this about performance optimization in 1974:

> Programmers waste enormous amounts of time thinking about, or worrying about, the speed of noncritical parts of their programs, and these attempts at efficiency actually have a strong negative impact when debugging and maintenance are considered. We should forget about small efficiencies, say about 97% of the time: premature optimization is the root of all evil. Yet we should not pass up our opportunities in that critical 3%.

You might have heard someone repeat the phrase "premature optimization is the root of all evil". It's basically a software engineering adage at this point. Yet, I don't think many people know the full context of that sentence. By chiding developers for wasting enormous amounts of time worrying about "noncritical parts of their programs", Donald Knuth indirectly talks about Amdahl's law. Those "noncritical parts" are the functions with relatively negligible $t_{\text{opt}}$. Forget about small inefficiencies there. Instead, find the critical parts of your program (read: find the functions with large $t_{\text{opt}}$) and spend your time optimizing *those*.

We'll talk more about how to figure out which part of your code to optimize. For now, just remember Amdahl's law. Let it become your second nature to always ask: "But how often does this code actually run?" What's the $t_{\text{opt}}$?