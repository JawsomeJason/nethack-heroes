# 0008 Terminal first

## Status

Accepted, 2026-11-11

## Context

The slice must prove the game is fun before any visual work.
Tiles and a web UI are large efforts of their own.

## Decision

Terminal play comes first.
Tiles and a web UI come later.
Browser play will use the existing WebAssembly build in `sys/libnh` and `win/shim`.

## Consequences

* The slice uses map symbols and text only.
* Symbols are set in data files, not in C.
* Tile work waits until the slice is fun.
* A downstream pack may add tiles on its own.

## Evidence

Tested: the unix terminal build runs and a generated city level renders in a terminal.
Untested: the WebAssembly build in this fork.
Untested: tiles.
