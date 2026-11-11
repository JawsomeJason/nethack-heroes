# 0001 Build on NetHack 5 in C

## Status

Accepted, 2026-11-11

## Context

The game needs a deep, proven roguelike core.
Several bases were possible.

## Decision

Base the game on NetHack 5.0 in C.
Browser play comes later through the existing WebAssembly build in `sys/libnh` and `win/shim`.
Rejected for now:

* A JavaScript rewrite of NetHack.
* Other roguelike engines with data-driven mods.
* A new game from scratch.

## Consequences

* The engine stays close to upstream, so upstream merges stay cheap.
* Game logic is C and Lua, not JavaScript.
* The web UI is a later front end over the WebAssembly build.
* The rejected options can be reopened with a new ADR.

## Evidence

Tested: the build runs in about 15 seconds and Lua is vendored in `nhlua/lua`.
Untested: the WebAssembly build for this fork.
Untested: a JavaScript rewrite of NetHack, which was not evaluated.
