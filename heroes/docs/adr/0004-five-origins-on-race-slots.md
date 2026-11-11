# 0004 Five origins on race slots

## Status

Accepted, 2026-11-11

## Context

A hero needs a source of power that shapes how the public treats them.
`NUM_RACES` is 5 and cannot grow cheaply.

## Decision

Five origins on the five race slots, named by where the power comes from.

| Origin | Source of power | Proposed slot |
|---|---|---|
| Human | None. Skill and gear | human |
| Gifted | Born with it | orc |
| Altered | An accident or experiment | gnome |
| Attuned | Magic, by study, object or pact | elf |
| Offworlder | From another world or realm | dwarf |

The earlier "tech" and "trained" origins merge into Human.
The orc slot is proposed for Gifted because human monsters are already hostile to it.
That gives "the public fears the Gifted" with no new code.
Being feared is a Gifted trait only.

## Consequences
* Origin and role stay separate choices, as in stock NetHack.
## Evidence

Untested: the slot mapping and the hostility of human monsters toward the orc slot here.
Tested: hiding races from an options file works today.
