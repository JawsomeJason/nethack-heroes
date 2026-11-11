# 0003 Heroes are presets on role slots

## Status

Accepted, 2026-11-11

## Context

`NUM_ROLES` is 13 and `NUM_RACES` is 5.
Both are compile-time sizes that ripple into the monster table, tiles and saves.
Adding roles would be a large engine change.

## Decision

Heroes are data presets on the 13 existing role slots, not new roles.
A preset sets name, kit, starting powers, weakness, sidekick and casting numbers.
The working roster has eight presets in three waves, and all names are working names.
The full table is in `heroes/docs/vision.md`.
A power that exists as an intrinsic, a spell or an item is one line in a preset.
A power that exists only for monsters is a small C change.
A power nothing in NetHack does is left out or told through text.

## Consequences

* No new roles and no change to the monster table, tiles or saves.
* Five role slots stay unused or hidden by options.
* The blaster must tune the slot's casting numbers.
* The acrobat has no climbing or swinging power at first.
* The behemoth is always transformed at first. A two-form version could reuse the lycanthropy rules later.

## Evidence

Tested: hiding roles and races works today from an options file.
Untested: the preset binding, which is not built yet.
Untested: the blaster's casting numbers.
