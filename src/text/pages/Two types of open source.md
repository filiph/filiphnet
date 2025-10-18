---
title: "The two types of open source"
description: Let's stop pretending that "without warranty" means "without expectation".
created: 2025-05-27T09:00:00.000Z
date: May 2025
social_image: https://filiph.net/text/imgs/two-types-of-open-source.png
publish: true
---

The software world tends to view open source as some kind of a boolean flag. A library either is open source or it isn't. Is that piece of code open source? Yes? Ok.

![[two-types-of-open-source.png]]

But I think we can all agree there's a world of difference between something like the Android SDK (Apache 2.0) and a random stranger's npm package that happens to sport the same LICENSE file. There's a difference between Microsoft's VS Code and my software experiments on GitHub (all with MIT license). Ghost is a different "kind" of open source than Pico CMS, despite both having the same license and both having commercial offerings.

I think most people will agree that the pairs I mention above are of different types. But it's been hard for me to come up with the right taxonomy.

You can't say "professional versus amateur". If "professional" means "I get paid for it", then many tiny open source projects end up in the same bag as the ones with a huge corporation behind it (because the solo developer gets a few bucks in sponsorship). If you define "professional" as "made by someone who was professionally trained", then obviously almost all side projects are "professional". I could go on, but let's just agree that "amateur vs professional" is an even more blurred dichotomy in software development than elsewhere.

We also can't simply say "commercial versus non-commercial". Some projects backed by huge companies are ostensibly non-commercial (nobody is being charged for using them, and the company has no revenue tied directly to the project) while some solo dev projects have commercial sides to them.

We can't even draw the line by size of the team or company behind the project. Big tech companies are happy to let their employees publish open source software, so it's not hard to find projects that are officially "owned" by Google yet are on the opposite side of the spectrum from something like Android SDK. In fact, I just remembered about Scuttlebutt, a short-lived 20% project I worked on with Martin Omander when I was at Google. Despite being a Google project (and still accessible on code.google.com), I don't think anyone would ever mistake Scuttlebutt for something akin to Android or Flutter.

## High-expectation versus low-expectation

So, I propose a new terminology: high-expectation versus low-expectation open source.

Let's take Go, the programming language, as an example of a high-expectation open source project. Go is MIT licensed, which means that it literally says, in ALL CAPS, that the software is "provided 'as is', without warranty of any kind, express or implied". Legally speaking, this says: "don't expect anything". Legally, Google is within its rights to just drop Go tomorrow, shut down Go's website, and cease publishing any updates.

The same, of course, goes for TypeScript (MIT), Dart (MIT), or Swift (Apache 2.0).

But I think we all agree that the _expectation_ is different. Google, Microsoft and Apple really, _really_ shouldn't just drop these projects, even though they legally can, because the software development world sees a kind of implicit promise: "This is a big deal for us, we're investing in this, we're actively promoting this on our events. You, external developers, should use this."

In contrast, there are thousands, maybe millions of open source side projects by solo developers. These side projects _carry the exact same software license_, yet most sane people will not have the same expectation of someone's npm package as they have of Apple's Swift.

## Why is this important?

I don't think anything I say above will surprise anyone. But few people explicitly look at open source software as high- or low-expectation. And sometimes, this taxonomy would really help.

Every once in a while, some poor soul's side project becomes very popular. And suddenly they find themselves maintaining a piece of crucial infrastructure for, seemingly, the rest of the world. For free, in perpetuity.

[![[dependency_2x.png]]](https://xkcd.com/2347/)

And god forbid they stumble. They make a change that's unpopular, or stop maintaining for a month. Suddenly, a torrent of abuse descends on them because there are all these people who _expected_ the solo developer's side project to have the same level of support as Sentry does.

These angry developers are clearly in the wrong. They should have read the LICENSE file, right? The LICENSE file clearly states that the software is provided "as is". No warranties!

But substitute the side project with something on the other side of the expectation spectrum, and things get more complicated. If Microsoft drops TypeScript tomorrow, and stop providing patches even for the most critical security bugs, should the software world really just shrug and say, 

> "Well, look at the license, they didn't guarantee anything!"

I think not. No matter what the license tells you, there are varying degrees of expectations attached to different open source projects, and we should all accept this and be aware of it.

## Make your expectations conscious

If you see someone's side project has Apache 2.0 license, obviously don't assume their support will be equivalent to that of Android SDK. Expect that project to die, sooner or later, _OR_ offer to contribute to it.

Conversely, if you're using some big tech company's big open source project, and they pull the rug from under you, don't just shrug and point to the LICENSE file. Did the company expend effort to make you use the tech? Did they make it seem like a Big Thing™? Legally, you're still screwed, because of that LICENSE file. But that doesn't mean you can't feel let down. You can and probably _should_ make it clear to the company and everyone else that you consider this behavior unfair. (Obviously, always be civil. There are people on the other side of the wire.) You can partake in the usual acts of feedback towards a powerful organization: all the way from word-of-mouth through blogposts to public boycott drives.

## Set expectations as an author

This thing goes both ways, of course. If you're working on an open source project, chances are you want it to be popular. So you put effort into marketing it: you make the README very attractive, you add a website, record videos, write blogposts. You make it 1.0 ASAP. You create high expectations.

But then life happens (as it inevitably does) and you find yourself maintaining a huge project for a lot of people. And these people have high expectations.

Let's be clear: you don't deserve abuse. Never. But let's also acknowledge that your users have a right to feel frustrated, despite the "as is" wording in your LICENSE file. By your marketing, you led them to believe your project is more dependable than it actually is.

This is why I recommend forcing yourself to keep expectations low. Be very candid with your prospective users. Tell them you're working alone, or in a small group. Tell them this is a side project. Tell them it's non-commercial, and that you don't plan (or even see a way) to make money from this in the future.

Always remember that projects seem much easier at the start, and they're also much more exciting to work on. People underestimate the work required, and overestimate their passion for the project 5 years into the future.

[There's a badge](https://unmaintained.tech/) that I've been slowly adding to my GitHub projects: 
![[Screenshot 2025-05-27 at 12.36.27.png]] 

I put this in the README even in some of the projects I currently do maintain (for myself). Even if they're alive and well today, I don't want to lead people into having unrealistically high expectations. (Obviously, even I have projects that I consider maintained and safe to be depended upon by others. But most of my projects aren't that.)

%% **UPDATE:** Miroslav Kravec over at Mastodon suggests an alternative wording to the badge above: "Serves Author's Needs".  %%

## The economics of high expectations

Normalize getting paid for open source work.

Right now, that only really happens in big and/or very successful companies. Look at people who receive sponsorships on GitHub: they get peanuts for their work. Recently, I found someone with tons of high-quality open source projects. They had sponsorships set up, and didn't shy away from asking for them. I later found out they're making something like $500 a month. If they were working full time on this (and I think they could), that's $3 per hour. That's below minimum wage in, say, Ecuador, and waaaay below what that person can make as an software engineer employee, let alone an entrepreneur. (And make no mistake, starting and maintaining a number of successful open source projects requires much of the same skill set as running a small company.) 

It's true that, in the short term, money doesn't matter. Pure excitement and sense of meaning will beat any kind of compensation package. But as weeks become months and months become years, that relationship reverses. And we're talking about software libraries here, not about art — which means that dependability, longevity of support, and all the other boring stuff, is more important than almost anything else.

## IANAL

Look, I am not a lawyer. I want to make it clear that none of this article goes against the spirit of open source licenses. The LICENSE files clearly state that open source projects are provided without warranty. You have no _legal_ recourse if some big company drops one of their high-expectation open source projects.

I'm merely saying that project authors, be they big companies or solo devs, _have a choice of how to present their project._ And I think we can all agree that if someone practically begs developers to use their open source project, and knowingly sets high expectations, they can expect negative feedback when they don't deliver - regardless of what's stated in the LICENSE file.

