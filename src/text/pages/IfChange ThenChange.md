---
title: "IfChange ThenChange"
description: "I miss Google's LINT.IfChange."
created: 2025-11-14T09:00:00.000Z
date: November 2025
publish: true
---

There's this simple lint that's used internally at Google that will seem inelegant to purists but is actually really useful in practice. And I often wish it was open source so I could use it in my projects now that I've been outside Google for 4 years.

I'm talking about `LINT.IfChange`. It works like this:

- You have ==two source files that need to be kept in sync.== For example, an enum declaration in C, and a corresponding enum declaration in Dart. (More examples below.)
- You wrap the enum in its C file in code comments that looks something like this:
    - `// LINT.IfChange`
    - ... the code fragment ...
    - `// LINT.ThenChange(path/to/other/file.dart)`
- You do the same in the Dart file.
- When a <abbr title="Change List">CL</abbr>/commit makes any change to one code fragment *without also changing the other*, a pre-commit hook produces a lint warning.

That's it.

Now, in the ideal world, we wouldn't need this lint at all, right?

- Whenever a developer makes a change to one file, they should read all the associated comments, and there they will probably find something like "This should be kept in sync with XYZ." If they neglect to do it, then the code reviewer will surely correct that mistake! But let's be real: almost nobody reads the whole file that's being changed.
- A statically typed codebase should catch these types of "forgotten manual sync" errors during writing. For example, a Dart switch statement will refuse to compile if you don't address every possible option. So if an enum value is added in one place, all the affected switch statements will be marked. But not all codebases are statically typed, not all language features can check exhaustiveness and not all correctness can be automatically dis-proven. Plus, almost every codebase mixes more than one language (programming, markup, etc.).
- A properly tested codebase should catch these bugs as soon as the unit tests run. But not all of these errors are simple to test, and some of them are nigh *impossible* to test without full, continuous integration testing — which, in turn, can be flaky, prohibitively hard to set up, and expensive to run.
- In the modern world of A.I., an error like this should not be able to slip past automated LLM code review. But, well — try it. Unless it's a trivial example, chances are pretty high that the A.I. will miss it. (And even if it doesn't, the feedback comes a lot later than with a simple git hook that executes in a tiny fraction of a second on your workstation.)

So, in the real world, `LINT.IfChange` is really helpful. You can search GitHub for "ThenChange" and you'll find many examples (all of them in open source Google libraries, as far as I can tell). 

## Examples

[TensorFlow uses it](https://github.com/tensorflow/tfx/blob/e537507b0c00d45493c50cecd39888092f1b3d79/tfx/workspace.bzl#L83) to make sure dependency versions in the Bazel build file are the same as the ones in the Python file.

```bzl
# Fetch MLMD repo from GitHub.
tfx_github_archive(
    name = "com_github_google_ml_metadata",
    repo = "google/ml-metadata",
    # LINT.IfChange
    tag = "v1.16.0",
    # LINT.ThenChange(//tfx/dependencies.py)
)
```

[Chromium uses it](https://github.com/win32ss/supermium/blob/69eb6c5ae33c9dc065409c1d7c5ab055fbab77db/base/features.cc#L72) to make sure their constants in C++ are the same as the ones in Java.

```c
// LINT.IfChange
#define LOW_MEMORY_DEVICE_THRESHOLD_MB 1024
// LINT.ThenChange(//base/android/java/src/org/chromium/base/SysUtils.java)
```

[The Language Interpretability Tool](https://github.com/PAIR-code/lit/blob/3debb609cf1b9e8775471c262026e0a1a1f87a28/lit_nlp/app.py#L71) uses it to make sure their Python backend code stays in sync with their TypeScript front-end code.

```python
# LINT.IfChange
class ComponentInfo(TypedDict):
  configSpec: types.Spec  # Named for JSON struct
  metaSpec: types.Spec    # Named for JSON struct
  description: str
# LINT.ThenChange(./client/lib/types.ts)
```

You get the picture.

## Sometimes better then static types

I love `LINT.IfChange` so much that I would even argue that it should be sometimes used _instead of_ static typing.

Here's an example.

Let's say you have a special mode in your app that lets you bring up debugging information. For example, in GIANT ROBOT GAME, when I press `Ctrl-Shift-D`, I get a debugging overlay, and when I press `Ctrl-D` over an entity, I get lots of information about that entity. YouTube has "Stats for Nerds" (try right clicking a video on desktop). A social media app might have something similar for posts.

Now, it's easy to forget to add things to these debugging overlays. I, for one, forget all the time. Entities in my game get new capabilities and new data — and then I don't add them to the debugging modal. Only when I later need to debug something and I bring up the modal, I realize my error. (Too late if it's in production.)

This could be addressed in a type-safe way. Every type of entity must publish some kind of list of `DiagnosticableAspect` objects that the debugging modal simply displays.

```dart
import 'package:my_app/src/debugging/diagnosticable.dart';

class TroutMissile implements Diagnosticable {
  Vector2 velocity;
  Vector2 acceleration;

  @override
  List<DiagnosticableAspect> get debuggingAspects => [...];
  
  // ...
}
```

But this has problems.

1. You're adding a dependency, which you sometimes want to avoid.
2. Not all debugging information is just a simple text string. Sometimes, you want to show an image, a graph, or an icon. Other times you want the user to be able to play an associated sound file. So now your `DiagnosticableAspect` needs to be able to have all that capability, duplicating functionality of your UI framework in the process. Also, your simple object now needs to provide all that info about images and graphs and sound files via the `DiagnosticableAspect`, increasing complexity.
3. Sometimes, you want to show the debugging info in something other than a linear list. Maybe the image goes to the top right corner? Maybe some numbers can be shown next to each other in a row? You either have to support it all via `Diagnosticable`, or you're out of luck.
4. You _still_ can easily forget to update that `debuggingAspects` field. There's no lint warning.

Compare this with the `LINT.IfChange` approach:

```dart
class TroutMissile implements Diagnosticable {
  // LINT.IfChange
  Vector2 velocity;
  Vector2 acceleration;
  // LINT.ThenChange(//src/debugging/modal.dart)
  
  // ...
}

```

The linked Dart file can be completely separate, can import whatever it wants (including Flutter, for example), and can make all the UI decisions it wants. And. you get a lint warning.

Yep, this example is contrived — but you get the picture.

## Why doesn't this exist outside Google?

I'm sure there are similar cross-language lints out there, I'm just not aware of them being used. I think it's a shame.

I realize the lint's approach may seem dirty. It's literally just a comment with a "special" meaning. There's no cleverness here. You're throwing static analysis out of the window for what? For searching a string in the codebase?

Look — I'm as much fond of elegant solutions as the next person, but I _also_ like stupidly simple, _practical_ solutions. And I like this one.

I advocate for creating a new open source tool that has the exact [same syntax](https://www.chromium.org/chromium-os/developer-library/guides/development/keep-files-in-sync/) as Google's `LINT.IfChange`. Google is unlikely to release that code to open source because I think `LINT.IfChange` is too intricately part of the company's source control infrastructure. Also, it's not like people outside Google are clamoring for tiny lint tools to be released.

A naive implementation of `LINT.IfChange` shouldn't take more than a couple of hours, especially if you already have a library that can talk to git ([example](https://pub.dev/packages/git)). But the devil's in the details. Since the library needs to work across programming languages, you might have to be able to find out what is a comment in what file. Or maybe you just search for "LINT.IfChange" and "LINT.ThenChange(...)" since those strings are quite unique — and keep your fingers crossed that those don't mean something else? What happens when the linked file doesn't exist? What if it's being renamed in this commit? Do you want to only support paths in `ThenChange` or also (the less used) labels? Should the tool be compiled to a binary (probably yes) and if so, how do you distribute it?

You get the picture. 

Then add to it the terrifying possibility that the lint tool *actually becomes widely popular.* Now you have the responsibility (though only felt, not contractual) to keep this tool maintained and running for years. Inevitably, there will be bugs and feature requests. 

- The tool won't work on _&lt;insert random obscure encoding&gt;_ files — fix it.
- The tool reports false positives when run on documentation files that mention it — fix it.
- The tool takes seconds to run for a 1 MLOC monorepo on a potato — fix it.
- The tool should work across repositories — implement it or say no.
- The tool should work in Mercurial and Perforce — implement it or say no.

Once again, you get the picture.

I really wanted to work on this myself but, given my schedule for the coming many months, I shouldn't take on more work. But, if you — despite all those caveats I've outlined above — are in a mood for a side project, I'll be among your first users.
