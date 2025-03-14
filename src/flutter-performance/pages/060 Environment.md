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

## Runtime

==TODO: CONTINUE==

%% incl. the moving target of web: https://filiph.net/raytracer/ %%

## Operating System

%% governors also turn or when you touch the screen; %%

## Hardware

## Room

%% temperature, vibration %%

## Controlling the onion

%% at least do this: plugged in, no major other app open (minecraft), no work being done %%

%% ideally do this: running on the target device, benchmark on a specialized device that's really close to target %%

## Raspberry Pi

%% my approach: raspberry pi %%
%% use RPi ideally https://github.com/ardera/flutter-pi %%

%% ./flutter-pi/build/flutter-pi --orientation portrait_up --videomode 1920x1080 --dimensions "168,78" --release raspi_bench_test   // This tries to emulate Samsung Galaxy A05s, a budget phone for $126. %%