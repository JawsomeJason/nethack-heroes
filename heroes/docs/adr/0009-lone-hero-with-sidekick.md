# 0009 Lone hero with a sidekick

## Status

Accepted, 2026-11-11

## Context

NetHack controls one character.
Controlling a full team fights the engine.

## Decision

The player has one hero plus one AI sidekick.
The sidekick uses the pet slot and never starves.
There is no party control.

## Consequences

* The sidekick follows pet rules for movement and fighting.
* A pet that neither eats meat nor plants never starves or turns on you.
* The preset names the sidekick.
* Balance needs care because early floors get easier.

## Evidence

Untested: all of it. No prototype was built for this decision.
The no-starve behaviour is expected from the pet food rules and was not run.
