---
title: "Chapter 1: Intro"
description: Book introduction.
created: 2025-03-03T08:00:00.000Z
publish: true
---

## Performance or Die

 Have you noticed how every teacher thinks that *their* field is the most important in the world? Math teachers think math is the most important because it's the purest description of reality or whatever. Language teachers think that language is the most important because that's how we communicate and think. Biology teachers think that biology is the most important because _biology is life_, and what's more important than life?

This continues in Computer Science departments, doesn't it. Whatever the professor teaches — algorithms, data structures, linear algebra, complexity theory — that's what they think is the most important. 

%% (comic: Haha yeah, he's right.) %%

They are, of course, all wrong. The most important field of all is performance.

%% (comic: lowered eyelids) %%

Let me give you an example. Imagine an app that checks all the boxes. It addresses an existing problem and it solves it well. It's well designed and follows all the usability and accessibility best practices. It looks beautiful and is available on all the important platforms. The developers forgot only one thing: performance. It's infuriatingly slow. It takes ages to open. It gobbles memory so much that mobile operating systems need to evict other apps, making multitasking hard to impossible. Its animations jank on most devices, and users sometimes don't know whether or not they clicked a button because the response speed is so slow. Arghh!

Do you think such an app will be successful? I think not.

%% (comic: he has a point. B: don't encourage him) %%

I have seen a few apps that fit the description, and helped at least a couple of them from their performance hole. I have good reasons to believe that performance is, in fact, crucial. It might not be the be-all and end-all of software development, but it's definitely a multiplier.

Bad performance can erase all your other advantages. Good performance can _enable_ something completely new. Something that wasn't possible otherwise.

### The future

For decades, a valid strategy for making code run faster was to simply wait. I'm not kidding. Computers got faster every year, so if you were working on something in 1995 and you knew it wouldn't ship before late 1996, you could bet that your performance problems would just go away. Your company could just buy a significantly faster server when it became available next year. Consumers would upgrade to faster computers sooner or later. Moore's law was at play.

This golden age has ended. The usual wells of faster hardware have dried up. 

![[Screenshot 2025-01-13 at 09.29.48.png]]

First, there are the limits to miniaturization. Transistors are now at a scale at which physics are starting to say no. The current CPU manufacturing processes are at a few nanometers but silicon atomic size is about 0.2nm. Quantum tunneling becomes a problem. Current designs are almost at the theoretical limit of power density (~100 W/cm²). Manufacturing costs are increasing exponentially. %% TODO: check if this is correct %%

Second, there's the "memory wall". Even if you make the CPU faster at processing data, it still needs to first _access_ the data to process, and that has its own physical limitations.

Don't worry, this is not the end of invention. Computers _will_ get faster. There's always something cooking: quantum computing, High Bandwidth Memory (HBM), die stacking, you name it. There will probably be breakthroughs in the future. It's just that you can't count on them as easily as you could count on Moore's law in the past.

In other words, if you write slow code today, you can expect it to be about as slow 5 years from now. Maybe even ten, twenty years from now. This hadn't been the case in all of computer history.

### Career

If making performant software doesn't motivate you enough, think about something even more important: you. I mean, your bank account.

You may have heard the term "marketable skills". It's the skills you have that people are willing to pay for. The rule is that if you have a skill that people are willing to pay for, *and* it's rare for people to have that skill, then you are getting paid handsomely.

Here's a table:

| Skill | Marketable? | Rare? | => Carrer |
| --- | --- | --- | --- |
| Breathing | No | No | No |
| Burping alphabet | No | Yes | No |
| Mediocre writing | Yes | No | Meh |
| Optimizing code | Yes | Yes | \$\$\$\$\$ |

This book teaches Flutter performance which — at least in the medium term — is a skill both marketable and rare. If you're the person in your team who others turn to when dealing with performance issues, that's a good position to be in. If you're interviewing for a new job and you can tell people you singlehandedly removed jank from a critical app in your previous job, that's a gem in your resumé.

But what about outside of Flutter, you ask? The thing is, most of the skills in this book are applicable outside of Dart and Flutter. The book is called "Flutter Performance" and it's full of practical tips but what I'm really after is teaching the more fundamental skills, the scientific method, and humbleness before truth.



