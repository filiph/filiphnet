---
title: "Chapter 6: Environment"
description: No man is an island and no program runs alone.
created: 2025-03-13T08:00:00.000Z
publish: true
---

==WARNING:== This chapter is a stub.

Your code doesn't run alone, like some ethereal _idea_ in a perfectly uneventful void.

Instead, it runs in an onion.

%% comics - he _really_ is losing his mind, isn't he? %%

Fancy performance engineers generally call this "the environment". I call it an onion.

{ DIAGRAM of the onion }

The onion has layers, and each of them affects your code's performance. Let's start from the inside-most layer.

## Flutter

Much of your Flutter code is programmed in a declarative style, and it's on the framework to figure out how to make things work. This in itself is a bit of a layered onion — from C++ code of the Flutter engine all the way up to common Flutter widgets such as `ListView` — but you get it as an atomic package. When you upgrade Flutter, the new version contains a specific version of Dart, a specific Flutter engine, and so on. It's rare for people to be running, say, Flutter 3.29.0 with anything else than framework revision 35c388afb5, engine revision f73bfc4522, and Dart 3.7.0.

The version of the Flutter SDK can obviously have a large effect on the performance of your code. It's common for Flutter to get performance improvements even in minor version bumps. It's also very much possible to encounter a performance regression from version to version.

When evaluating performance, always be aware which version of the Flutter SDK your app is written in. You can find the version by running `flutter --version`. You can also run `flutter --version --machine` to get machine-readable JSON output like this:

```json
{
  "frameworkVersion": "3.29.0",
  "channel": "stable",
  "repositoryUrl": "https://github.com/flutter/flutter.git",
  "frameworkRevision": "35c388afb57ef061d06a39b537336c87e0e3d1b1",
  "frameworkCommitDate": "2025-02-10 12:48:41 -0800",
  "engineRevision": "f73bfc4522dd0bc87bbcdb4bb3088082755c5e87",
  "dartSdkVersion": "3.7.0",
  "devToolsVersion": "2.42.2",
  "flutterVersion": "3.29.0",
  "flutterRoot": "/path/to/flutter"
}
```

If you need to access this information from within a running app, use `FlutterVersion`.

```dart
import 'package:flutter/services.dart' show FlutterVersion;
var version = FlutterVersion.version;
```

## Dart runtime

When you run `dart compile exe` — either directly or through `flutter build` — your Dart code gets compiled into machine instructions. 

So instead of

```dart
var x = z + 1;
```

you get something like

```asm
mov rdi, 0x1
add rax, rdi
```

except in binary, so it's something like

```
01001000100000111100011100000001010010001000100111111000
```

in the actual `.exe` file.

%% The above was done using https://dart.godbolt.org/, then https://defuse.ca/online-x86-assembler.htm, then https://www.rapidtables.com/convert/number/hex-to-binary.html?x=4883C7014889F8 %%

But that's not all that goes into that file. The compiler must also include the *Dart runtime*. That's all the things that your program does that you don't need to worry about. For example:

- **Memory management.** When you create a new `List` in Dart, you don't need to worry about allocating memory for it, nor do you have to remember to free the memory once the list is no longer needed. But your code wouldn't work without this, so it's included in the `.exe` as part of the runtime. This includes the garbage collector, which will be a recurring character in this book.
- **Exception handling.** When you decide to throw an exception in your Dart code, you don't need to worry about things like stopping execution mid-function, creating the `StackTrace` object, or finding whoever's responsible of catching it. But again, your code wouldn't work without this, so it's included in the `.exe` as part of the Dart runtime.
- **I/O.** When you read from the file system with something like `file.readAsString()`, you don't need to worry about interfacing with the underlying system. Same goes for any other input or output. This, too, goes into your binary as part of the Dart runtime.

The binary code you ship is deeply intertwined with the Dart runtime. Some of the most basic operations — things that you never ever think about while writing Dart, such as passing objects to functions — are performed by the runtime.

So, as you can imagine, the Dart runtime has a major effect on the performance of your code. 

You can find you installed Dart's version by running `dart --version`. The version is also printed with `flutter --version`.

The runtime will be different for different operating systems and architectures. So, the runtime for `linux_arm64` will be different from the one for `windows_x64` even if they are the same version number. But we'll get back to this further along our path through the onion.

If you need to find out the version of the runtime from within a running Dart program, you can use the following:

```dart
import 'dart:io' show Platform;
var version = Platform.version;
```

This assumes you're _not_ running the program in the browser. Then again, if you're running Dart in the browser, chances are you're running a Flutter app, and you can use the aforementioned `FlutterVersion` class and its `FlutterVersion.dartVersion` member.

The browser is a whole separate layer, of course. When compiling for the Web, your Dart code _and_ the Dart runtime is either compiled into JavaScript or into Web Assembly. The browser then executes that JavaScript or Web Assembly. Suffice to say, the browser and its version matters. Plus, unlike the runtime that is compiled with your code, the browser environment can (and will) change "under your feet." Browser vendors (Google, Microsoft, Mozilla, Apple) constantly work on their technology. This means that the same _build_ of your app (the same compiled blob of JavaScript or Web Assembly) can run at different speeds today than they will do tomorrow.

%% possibly talk about  https://filiph.net/raytracer/ - Dart used to be faster, now it's slower - but what if we recompile it? %%

## Operating System

Let's get back to your compiled `.exe` with all its machine instructions. Not even this can run by itself. It needs an operating system to talk to. The OS provides access to files, the network, and important services such as the time. It also allocates memory, provides processing threads, starts processes, and more. Any of these things can be more efficient, or less efficient, depending on the OS and its version.

So, once again, you should remember to capture this context when analyzing performance. To get the information about the exact version of the operating system, use the `Platform` class:

```dart
import 'dart:io' show Platform;
var osName = Platform.operatingSystem;
var osVersion = Platform.operatingSystemVersion;
```

But the real issue with operating systems isn't that their performance changes slightly between versions. It's that they constantly and actively affect performance in real time.

We talked about governors in the previous chapter about _Performance lottery_. In short, operating systems change processing speed depending on various heuristics. If the OS governor thinks that the current load isn't urgent, it lowers the clock speed of a processor or even puts some CPUs to sleep. This can happen really quickly: one millisecond, the device is firing on all cylinders, and the next one, it's in battery saving mode. Then a fraction of a second later, the user touches the screen, and the governor switches everything back on.

Governors are a pain when it comes to benchmarking but they're obviously a good thing from the more general perspective of app performance. Yes, we want our apps to be snappy, but not at the cost of draining all of the user's battery, or keeping their cooling fans on at all times. Once again, it's a tradeoff.

We'll talk about how to disable governors in a later chapter. For now, let's just acknowledge that these heuristics, which are included in all our operating systems (from desktop to laptops to mobile phones), have an effect on the performance of our programs.

## Hardware

We live in a world of thousands of devices from hundreds of manufacturers, all of them with slightly different performance characteristics. A 13-inch 2020 MacBook Pro M1 is different from a custom-build Intel x64 PC is different from Samsung A25 6GB is different from Samsung A25 _8GB_ is different from iPhone 16e is different from iPhone 16 Pro Max 256GB is different from Raspberry Pi 4B.

The great thing is that Flutter can target each of these devices and a thousand more.

The absolutely terrifying thing is that Flutter can target each of these devices and a thousand more.

%% COMIC: ahh, the classic joke where he says the same thing twice. This guy's good. ; Did he pay you to say that? ; No, he *drew* me to say that. ; beat ; Fair enough. %%

Well, it's only terrifying if you expect your app's performance to be precisely the same on your user's devices as it is on yours. Once you let go of this silly notion, you're good.

In practical terms, it's important to test your app on a wide variety of devices. Don't do the Silicon Valley thing where people only ever see their app running on the latest flagship phone connected to spotless 5G. Ideally, you should have your app on your daily-driver phone — so that the app needs to co-exist with a myriad other apps and services — and that phone should be on the _lower_ end of your target audience's device spectrum.

If you're really into shiny new iPhones but you're shipping apps that will be used by hundreds of millions of users in emerging markets (or just ordinary users in the US), I have bad news for you. You have two options:

1. Downgrade the phone you carry around in your pocket
2. Lose touch with what your app trully feels like to use by the vast majority of your users

%% COMIC: let's lose touch together %%

If you're benchmarking, select a single device and use that. Comparing two benchmark results from two different devices is useless.

## Room

When I was employed at Google on the Flutter team, my family and I lived in Mountain View, California. We rented an apartment under the roof and so, during the summer, it got really hot. (We didn't have air conditioning. We're one of those weird types who avoid air conditioning unless it's unbearably hot. And in Silicon Valley, it's almost never unbearably hot.)

Then the pandemic came, and we had to work from home. I took the bedroom.

I had an Intel MacBook Pro back then, and I remember when the first really hot day came...

%% temperature, vibration %%

## Controlling the onion

%% at least do this: plugged in, no major other app open (minecraft), no work being done %%

%% we want the environment to have as few effects as possible. This generally means as few _detrimental_ effects as possible. Yes, you could argue we should measure "real life" performance, so why should we remove things that are "real life" from the equation? Because they're noise. total_time = our_program + runtime overhead + system overhead + hardware potentially slowing down due to governors, termal throttling etc. That's why C++ benchmark sometimes take the minimum time. In our world, we can't, because our programs almost certainly create some of the runtime overhead (GC).   %%

%% ideally do this: running on the target device, benchmark on a specialized device that's really close to target %%

## Raspberry Pi

%% my approach: raspberry pi %%
%% use RPi ideally https://github.com/ardera/flutter-pi %%

%% ./flutter-pi/build/flutter-pi --orientation portrait_up --videomode 1920x1080 --dimensions "168,78" --release raspi_bench_test   // This tries to emulate Samsung Galaxy A05s, a budget phone for $126. %%

%% shut down daemons and set governor to performance https://kagi.com/assistant/116e11a9-4560-4242-b9e5-3629afa01ca1 %%

%% https://github.com/ardera/flutter-pi/issues/469#issuecomment-2736811090 - use raspberry pi for testing %%