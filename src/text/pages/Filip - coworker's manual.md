---
title: "Filip H. — Coworker's Manual"
description: How to deal with Filip.
created: 2023-08-07T08:00:00.000Z
publish: true
---

If you've been sent this link, you're probably about to work with Filip. Don't panic. Despite the length, nothing here should be too surprising. It's just to set expectations, sync terminology, and make things clear.

<!--
## General philosophy of work

I think you'll agree that the things we'll collaborate on are going to be pretty interesting. That doesn't mean they won't at times be frustrating, difficult and grinding — but they are the kinds of problems that most developers find at least a little bit self-motivating. This is by design. I am at the privileged position to choose the problems I work on, and so I work on stuff that's fascinating & meaningful to me (and nerds like me).

This is key. I really hope we'll be working on stuff that is inherently motivating. If you ever find yourself _not_ feeling motivated by the stuff we work on, please tell me loud and clear.
-->

## Development philosophy

1. I am a pragmatist. I try to follow best practices and find elegant solutions — but I have no problem murdering them when they get in the way.
2. [Akin](https://spacecraft.ssl.umd.edu/akins_laws.html)'s Law of Spacecraft Design #36: "Any run-of-the-mill engineer can design something which is elegant. A good engineer designs systems to be efficient. A great engineer designs them to be effective."
	- "Effective" here translates to "provides customer value". In gamedev terms, that's mostly how _fun_ the game is to play. I'm often surprised how common it is to sink time and talent into stuff that ultimately has no bearing on actual gameplay.
3. I try to be acutely aware of trade-offs. Not just space/time, but also [flexibility/usability](https://en.wikipedia.org/wiki/Flexibility%E2%80%93usability_tradeoff) and others.
4. In readability vs writability/elegance, I prefer readability. A few months from now, you won't care how easy something was to write or how smart you felt writing it — you'll care about whether it's clear and easy to follow.
5. As for the question "functional or imperative paradigm?", my answer is: "yes". (They both have advantages and *can* work well in tandem.
7. YAGNI (with [exceptions](https://lukeplant.me.uk/blog/posts/yagni-exceptions/)).
8. Avoid the second system effect — the urge to throw it all away and start from scratch. Understanding complex (and inevitably flawed) existing code takes time and seems unproductive. But it's still _more_ productive than the seemingly thrilling alternative of rewriting from scratch.
9. Avoid premature optimization.
10. [Prevent bit rot](https://software.rajivprab.com/2020/04/25/preventing-software-rot/). For example, don't introduce new dependencies unless you absolutely need to.
11. Fail fast (e.g. put your assumptions into `assert`s).
12. Manually formatting your code is a waste of everyone's time. Use automated tools.
13. Be aware of the different [refactorings](https://refactoring.com/catalog/) and use them, especially when they make the code *simpler*.
14. Follow good API design. For example, if calling some method is expensive (i.e. takes a long time to execute), it should _look_ expensive. In Dart, that's the difference between something like `int get count` (cheap-looking) and `int computeCount()` (expensive-looking).
15. Be your own Product Manager (software engineers are sometimes forced to, and often _used_ to, outsourcing the unpleasant decisions to a PM, then bitching about it). 
16. Know that finishing is [a skill](https://www.tumblr.com/makegames/1136623767/finishing-a-game).
17. Embrace [the power of boring](https://selfimproving.dev/the-power-of-boring.html).

If you need more depth to the ideas above, I recommend Paul Boyd's [The Cargo Cult of Good Code](https://pboyd.io/posts/cargo-cult-of-good-code/), Chris Keihl's [Software development topics I've changed my mind on](https://chriskiehl.com/article/thoughts-after-6-years),  tef's [Write code that's easy to delete](https://programmingisterrible.com/post/173883533613/code-to-debug), Tess Snider's [tidbits for programmers](https://twitter.com/Malkyne/status/1484314926269140993), John Salvatier's [Reality has a surprising amount of detail](http://johnsalvatier.org/blog/2017/reality-has-a-surprising-amount-of-detail), André Staltz's [don't rewrite everything](https://twitter.com/andrestaltz/status/1508454285432000526), Joel Spolsky's [Things You Should Never Do](https://www.joelonsoftware.com/2000/04/06/things-you-should-never-do-part-i/), Lidwell's book [Universal Principles of Design](https://www.google.com/search?client=firefox-b-d&q=universal+principles+of+design) (I have the pocket edition on my table), much of the rest of [Akin's laws](https://spacecraft.ssl.umd.edu/akins_laws.html).


## Mode of work

1. I avoid IM (instant messaging) when I can. I think IM is almost always better for the one asking than for the one being asked. That said, I have to admit it's *sometimes* good to be in IM communication. Possibly at set times or in predetermined bursts. We'll figure it out. I just want to prepare you for my tendency to use asynchronous communication (such as email) — i.e. communication where the recipient can choose _when_ to receive.
2. For productivity _and_ personal health reasons, I utilize what is sometimes called the "lion approach" to work pacing. I am productive in bursts, with periods of relatively low productivity in between. Sometimes, migraine forces me to only do the most basic stuff for 1-3 days in a row. Other times, I get a ton of things done in a single, long, inspired day. I realize this is not ideal, because it's not very predictable, but that's how things are with me.
3. In communication, more frequent is generally better. Don't be afraid to send an email even if all you want to say is "I tried to fix A today - but no luck so far." It can seem extraneous but I think it's better than no communication at all. Reading an "FYI" email can be finished in seconds.
4. When video calling, I find it very important that both parties have good and reliable internet connection. It is often the difference between a productive chat and an awkward catastrophe. To me, it's generally better to wait until both parties can have good reception than to try to force a video call despite bad connection.
5. It’s not enough to be correct. You must also be helpful. (Example: When I say "this UI is shit", I may be correct. But I'm not helpful. On the other hand, if I say "we could improve this by X and Y, and here's how we'll get the time & resources to do that", then I'm helpful.)



## Conclusion

I wanted this as a document so that you can _call me out_ on these things. It's a bit harder to break my own rules and ideals when they're written down and a single click away. 

If you have things that you'd like to clear out with me, the way I do above, please do! This is intended as a conversation starter (not ender).

See you soon!


