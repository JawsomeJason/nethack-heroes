# 0002 Ship the game as a theme pack

## Status

Accepted, 2026-11-11

## Context

The fork must stay mergeable with upstream.
Downstream theme packs must be able to rename and narrow the game without forking the engine.

## Decision

The game is a theme pack over the engine.
The public superhero game is pack one.
A downstream theme pack is a second pack on the same seam.
Engine changes have a budget of under 300 added lines of C in at most 6 upstream files.

## Consequences

* The public game can only use what the seam offers, so a downstream pack works the same way.
* Every new hook widens the fork and counts against the budget.
* Old names stop parsing after a rename, so each rename keeps the old name as an alias.
* The same word in two object classes needs a class filter.
* Strings in C that mention monster or object names outside the tables are not covered by the seam.

## Evidence

Tested: a 28-line prototype renamed monsters, objects and unidentified appearances from a Lua file at startup.
The new names showed in combat, inventory, wishes and genocide.
The names survived save and restore.
Untested: aliases, class filters and the in-game encyclopedia, which is keyed by old names.
