# 0005 Headquarters and missions

## Status

Accepted, 2026-11-11

## Context

The game needs short runs and a home base.
The stock dungeon is a long campaign and replacing it is a large job.

## Decision

Level 1 is the headquarters.
Portals lead to short mission dungeons.
The stock dungeon stays below the headquarters as the long campaign, with its endgame unchanged for now.

## Consequences

* One stair branch per level is an engine limit in `src/mklev.c` (`place_branch`), so extra missions use portals.
* An `unconnected` dungeon has a difficulty equal to its own floor number.
* Missions name their own enemies to tune difficulty, or a small C change is needed.
* `MAXDUNGEON` is 16 and stock uses 9, so about 7 missions fit before a constant is raised.
* The game assumes dungeon 0 is the main one and finds about 25 landmark levels by name.

## Evidence

Tested: a hub level with three portals to three `unconnected` dungeons works.
Tested: a 133-line Lua file generates a connected city-block level every time (10 of 10).
Tested: a dungeon can be entered from its top floor going up.
Untested: the headquarters as a special level on level 1 of the main dungeon.
