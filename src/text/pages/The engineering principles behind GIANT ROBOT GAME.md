---
description: How this weird game is being built.
social_image: http://filiph.net/text/imgs/slice1@10x%202.png
created: 2023-08-15T08:00:00.000Z
publish: true
---

I thought I'd share some of the approaches that I use when developing [_GIANT ROBOT GAME_](https://giantrobotgame.com/). This post will be about code organization, classes, NPC AI, and so on. I thought some folks might find it interesting.

![[steam-gif-2-1.gif]]

For those who don't know, _GIANT ROBOT GAME_ is a game of vehicular combat, presented in sci-fi UI aesthetics. Focus is on depth (i.e. variety of options at any given time)
and moddability. It is a spiritual descendant (though not a narrative successor) to my award winning game, _Knights of San Francisco_. It is currently in development for PC/Mac/Linux.

## High-level approach

The game is not a roguelike (at least not in the strict sense) but the focus on depth and variety of options naturally leads to engineering approaches you'll find in most roguelike codebases. That is to say, nothing is special. Everything is built from parts. The player character is just another entity in the simulated world.

Everything in the game is an `Entity`: from pieces of debris to projectiles to factories.
Bare entities can't do anything except react to physics, catch on fire, and so on.

The only class that extends `Entity` is called `ComplexEntity`. Complex entities
have things like AI, faction allegiance, status reporting, and — most importantly —
parts.

Parts are what defines the capabilities of each entity. You can put legs
on a factory and it will have locomotion capability. You can put a warhead
on a fuel tank and you have a ... slightly more explosive fuel tank.
There are parts for repairing, for deploying, for shooting, for swiveling. 
Most of these parts depend on energy for operation, which means 
you have to include an `EnergyPart`. You get the point. 

This way, we can mix and match capabilities, sometimes with hilarious results.
The philosophy is more of a playground than of a realistic simulation.
As long as something is fun, I don't much care if it's weird or unrealistic.

## Radical effects

This level of _qualitative_ combination is what first brought me to the idea of making my next game about giant battle robots. Robots are great in that it's easy to replace parts and have a slightly different robot. This is hard to do with humans.

![[steam-gif-3-1.gif]]

My motto for _Knights of San Francisco_ was "radical powers, radical effects and simulationism". This applies for _GIANT ROBOT GAME_ as well.

- **Radical powers** — I'm not so much interested in the stereotypical incremental approach, where the player's character gets, say, `+2` on damage as they level up. I'm not saying it won't be in the game, but I focus on things that have radical, narrative effects. For example, the player gets a smoke grenade launcher. Suddenly, there's a way for them to radically modify the visibility on the battlefield. To me, this is more interesting than a damage modifier, and leads to more strategic gameplay.
- **Radical effects** — The events perceived by the player shouldn't be incremental ("wow, I made 200 damage!") but narrative ("I started a wildfire!" or "that fuel tank exploded and pushed me off the cliff!").
- **Simulationism** — My philosophy is to create a simulated world that could go on without the players. This means that I sometimes can't control how difficult or smooth the experience will be. There may be times when it's either too easy or too hard. To me, this is okay. I prefer games where the player is just a part of the world. The world doesn't revolve around the player. It could exist and evolve without them. This can obviously lead to sub-par experiences for the player.


## Pragmatism

For one of my past games, I used Goal Oriented Action Planning (GOAP) as the basis for the game agents’ AI. If you don't know GOAP — it's beautiful. It boils down to an A* search through a possibility space towards a desirable goal.

My reason for using GOAP was so that the actors in the game could _surprise_ the player (and me) with novel approaches to problems. To an extent, this worked. But in reality, this advantage of GOAP didn't materialize nearly often enough. And if it did, the player didn't notice. It didn't make the NPCs _seem_ more intelligent, nor more fun to interact with. It didn't make the game any more fun.

In the end, for my first commercial game (_Knights of San Francisco_), I removed GOAP and went with the much simpler mini-max approach. This new AI was less elegant, at least in my mind. But it was good enough, and much more malleable and easier to reason about.

[Akin](https://spacecraft.ssl.umd.edu/akins_laws.html)'s Law of Spacecraft Design #36:

> "Any run-of-the-mill engineer can design something which is elegant. A good engineer designs systems to be efficient. A great engineer designs them to be effective."

"Effective" here translates to "provides customer value". In game development terms, that's mostly how _fun_ the game is to play. I'm often surprised how common it is to sink time and talent into stuff that ultimately has no bearing on actual gameplay, or _how the player perceives it_.

Game developers, but especially solo devs with a programming background, are especially prone to this "elegancy" pitfall. I know because I've definitely fallen for it several times.

This is because writing the code for a game is, in itself, a sort of a puzzle game. Sometimes the engineering is _more_ interesting than the actual game. And I want to avoid that scenario at all cost.

I try to remember that some of the most important and interesting games were built with tools and code that any "serious" developer would scoff at. *Spelunky* and *Undertale* were built in *GameMaker Studio*. The original code for *Minecraft*, the best-selling videogame in history, was, reportedly, a terrible mess. Everyone loves to [laugh at the code comments](https://www.youtube.com/watch?v=k238XpMMn38) in the source code for *Team Fortress 2* — a game with a Metacritic score of 92/100.

![[Screenshot 2023-08-15 at 15.12.38.png]]

I'm, of course, not advocating for a complete lack of software engineering standards. All I'm saying is that, in game development more than anywhere else, nobody cares about how elegant your code is unless they get the value out of it.

And, besides that, I'd say a lot of the "elegancy" pitfall in game development is really just us nerds getting enamored with a cool algorithmic approach. I fell in love with the idea of ECS (Entity-Component-System), then I realized it's not really needed — nor desirable! — for my use case. I do have entities and, to an extent, the idea of  components and systems, but the implementation is _miles_ away from anything that could be considered ECS. I built a pretty feature-rich implementation of Behavior Trees (for AI), then I realized it's just making things more complicated and messy ([link](https://takinginitiative.files.wordpress.com/2020/01/behaviortrees_breaking-the-cycle-of-misuse.pdf?force_download=true) to PDF) — despite its claims of elegancy and its popularity among AAA studios.

These are the things that I have learned to respect:

- YAGNI (with [exceptions](https://lukeplant.me.uk/blog/posts/yagni-exceptions/)).
- Architect for change.
- Fail fast.
- Readability over writability.
- Avoid the second system effect — the urge to throw it all away and start from scratch. Understanding complex (and inevitably flawed) existing code takes time and seems unproductive. But it's still _more_ productive than the seemingly thrilling alternative of rewriting from scratch.

If you need more depth to the ideas above, I recommend Paul Boyd's [The Cargo Cult of Good Code](https://pboyd.io/posts/cargo-cult-of-good-code/), Chris Keihl's [Software development topics I've changed my mind on](https://chriskiehl.com/article/thoughts-after-6-years),  tef's [Write code that's easy to delete](https://programmingisterrible.com/post/173883533613/code-to-debug), Tess Snider's [tidbits for programmers](https://twitter.com/Malkyne/status/1484314926269140993), John Salvatier's [Reality has a surprising amount of detail](http://johnsalvatier.org/blog/2017/reality-has-a-surprising-amount-of-detail), André Staltz's [don't rewrite everything](https://twitter.com/andrestaltz/status/1508454285432000526), Joel Spolsky's [Things You Should Never Do](https://www.joelonsoftware.com/2000/04/06/things-you-should-never-do-part-i/), Lidwell's book [Universal Principles of Design](https://www.google.com/search?client=firefox-b-d&q=universal+principles+of+design) (I have the pocket edition on my table), much of the rest of [Akin's laws](https://spacecraft.ssl.umd.edu/akins_laws.html).


## Game engine

The game aesthetics are rooted in sci-fi movie interfaces. Think of a movie such as Star Wars or Oblivion, and the UIs the characters use in those movies. High contrast, simple, functional. I have studied these interfaces for years. (I even gave a [talk](https://slideslive.com/39000557/futuristic-ui-how-to-make-users-feel-like-they-re-in-a-scifi-movie) about Futuristic UI earlier this year.)

![[webexpo-slide(1).2023-08-15 14_53_07.gif]]

This means I'm focusing less on realism and more on symbolism. Think of a military Heads-Up Display (HUD), with its limited colors, high contrast, simple shapes and lines. That's what I'm going for.

For that reason, I felt that going with a traditional game engine (such as Unity or Unreal or Godot) would be counter productive. I was considering it but then I reverted back to Flutter (a portable UI framework) and Flame (a simple "game engine" built on top of Flutter). So far, it's been mostly a positive experience. I do know that I'm missing out on some things that are "included in the box" for something like Unity. But the ease of UI and vector graphics development makes it up for me.

![[slice1@10x 2.png]]

For the game, I wanted to have a 1970's style 3D renderer. I ended up building it myself, and it was not only an interesting-yet-achievable problem, but it also allowed me a lot more flexibility than I would have with a 3D engine made for modern 3D games. More on that in a future article.


## Code structure

Code is organized in a roughly feature-first manner.

```
lib
├── audio
├── campaign        <-- Meta game
├── editor          <-- Game creation tools
├── experimental    <-- What it says
├── game            <-- The game itself (play session)
│   ├── ai
│   ├── camera
│   ├── combat
│   ├── deployment
│   ├── dialogue
│   ├── energy
│   ├── entity      <-- The "game object"
│   ├── faction
│   ├── levels      <-- Level loading
│   ├── locomotion
│   ├── map
│   ├── movement
│   ├── physics
│   ├── player
│   ├── repair
│   ├── scripting   <-- Machinery for game scripting
│   ├── sensors
│   ├── status      <-- Temporary buffs, reporting
│   ├── storage     <-- Entities carrying other entities
│   ├── swivel      <-- The part that lets turrets swivel
│   ├── systems     <-- Remnants of ECS
│   ├── ui          <-- How to show stuff to player
│   └── util
├── retro3d         <-- The retro 3D renderer
└── style           <-- Palette, typography
```


## Conclusion

That's it for now. Excuse me while I go implement wind.
