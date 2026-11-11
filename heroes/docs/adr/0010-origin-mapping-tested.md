# 0010 Origin mapping tested

## Status

Accepted, 2026-11-11. Refines 0004.

## Context

ADR 0004 put five origins on the race slots without testing them.
The wave-1 heroes need an origin they can pick. Only the Gifted should be feared.

## Decision

Keep the slots from 0004. Fix three gaps with new `nh.race` lists (`aligns`, `friends`, `foes`) in `src/theme.c`, not upstream C:

* The orc slot allows only chaotic, so the lawful Feral fighter could not be Gifted. Gifted now allows all three alignments.
* Orc monsters are always peaceful to the orc slot. Gifted has no friends, so the orc-slot criminals stay hostile.
* Human monsters are always hostile to the gnome slot too. Altered has no foes, so being feared stays a Gifted trait.

Wave-1 origins: Thunder warrior takes Human or Offworlder. Arcanist takes Human, Attuned or Gifted. Feral fighter takes Human or Gifted.
The menu picks an origin by its first letter, and Altered and Attuned share A, so no wave-1 hero offers Altered.

## Consequences

* A future hero that offers both Altered and Attuned needs a new origin name or a menu change.

## Evidence

Tested in `heroes/test/smoke.sh` on 2026-11-11:

* Each wave-1 hero's origin menu offers the origin above, and the hero plays into the mission and reaches its boss floor.
* A Gifted Feral fighter: 4 human monsters made in wizard mode, none peaceful. A renamed orc monster, not peaceful.
* A Human Feral fighter: of 4 human monsters made, at least one is peaceful.

Untested: the Altered and Attuned peace rules in play, and the Gifted Arcanist.
