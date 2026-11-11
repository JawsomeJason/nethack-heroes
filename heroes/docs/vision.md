# Vision

## The vision in one paragraph

You play one hero with a fixed power identity and a named weakness.
You work out of a headquarters, take missions into a city that is different every run, and the city remembers how you treat it.
Underneath, it is NetHack 5.0 with its tables almost untouched.
The superhero game is a theme pack.
A downstream theme pack is a second pack on the same seam.

## More than a rename

Three things make this more than a rename.

* **Identity that does not converge.** Late NetHack heroes end up with the same kit and every resistance. A hero here keeps one power set and one weakness from turn 1 to the end.
* **Stakes outside yourself.** NetHack runs on greed. Here civilians are on the map, and how you treat them changes who helps and who hunts you.
* **A nemesis who returns.** NetHack already has one. The Wizard returns from death and harasses you for the rest of the game. Renamed, he is a recurring villain.

Growth works through the existing powers-by-level tables.
The quest artifact can serve as signature gear later.
Danger-triggered power surges can wait.

## Origins

Five origins sit on the five race slots.
They are named by where the power comes from.

| Origin | Source of power | How it plays | Proposed slot |
|---|---|---|---|
| Human | None. Skill and gear | Best skills and standing. Tools and armour | human |
| Gifted | Born with it | Innate powers. The public fears you | orc |
| Altered | An accident or experiment | Strong body and a hard weakness | gnome |
| Attuned | Magic, by study, object or pact | Widest range of powers. They can fail | elf |
| Offworlder | From another world or realm | Strong body. One material weakness | dwarf |

The slot mapping is untested.
The orc slot is proposed for Gifted because human monsters are already hostile to it.
Being feared is a Gifted trait only.
See `heroes/docs/adr/0004-five-origins-on-race-slots.md`.

## World

Level 1 is the headquarters.
Portals lead to short mission dungeons.
The stock dungeon stays below the headquarters as the long campaign.
Its endgame is unchanged for now.

* Missions are short and unlock in threat tiers.
* The headquarters can later grow into a district map with more portals.
* The existing puzzle branch can serve as the training room with new text.
* The end goal stays the Amulet chain, framed as the source of all powers.

Limits found:

* One stair branch per level is an engine limit in `src/mklev.c` (`place_branch`).
* An `unconnected` dungeon has a difficulty equal to its own floor number.
* `MAXDUNGEON` is 16 and stock uses 9.
* The game assumes dungeon 0 is the main one and finds about 25 landmark levels by name.

See `heroes/docs/adr/0005-headquarters-and-missions.md`.

## What changes underneath

| Treatment | Systems |
|---|---|
| Keep as is | Combat, items and identification, shops, pet behaviour, level generation, bones, prayer rules |
| New text only | Monster and item names, prayer as a call for backup, gods as patrons, the Wizard as nemesis, the town watch as police, alignment as public standing, quest dialogue |
| Small C change | Signature powers never fade (about 1 line). "Defeat" instead of "kill" (about 2 strings). Human enemies leave no corpse (a flag per monster). Standing bias by origin (about 1 line). Hero presets (one Lua binding) |
| Fits badly | Eating corpses for powers, altar sacrifice, genocide, the "You murderer!" penalty, Elbereth. They stay in for now. Most early enemies are machines to soften the clash |

Line counts in the C row are estimates.

## The pack seam

The public game is itself a pack.
If it is built only through the seam, a downstream pack works the same way and the C fork stays small.

| Layer | Holds | Lives in |
|---|---|---|
| Engine | Upstream NetHack plus the seam hooks | This repository, C |
| Public pack | Generic names, hero presets, levels, missions, flavour text, symbols | This repository, Lua and text |
| Downstream pack | Overrides of the same files, an options file that narrows heroes and origins, tiles | Outside this repository |

Data today: levels, the dungeon graph, quest dialogue, rumours, encyclopedia text, map symbols, and which roles and races are offered.
Data after the seam: names, kit, powers, weakness, sidekick, patron names, which monsters can appear, and standing bias.

Engine budget: under 300 added lines of C in at most 6 upstream files.
Each modified upstream file carries a prominent notice that it was changed, with the date.
See `heroes/docs/adr/0002-ship-the-game-as-a-theme-pack.md`.

Loose ends found by the rename prototype:

* Old names stop parsing, so each rename keeps the old name as an alias.
* The same word in two object classes needs a class filter.
* About 275 C strings mention monster names and about 458 mention object names outside the tables.
* The in-game encyclopedia is keyed by old names.

## Roster

Heroes are data presets on the 13 existing role slots.
A preset sets name, kit, starting powers, weakness, sidekick and casting numbers.
All names are working names.

| Working name | Origin | Role slot | Built from | Known gap |
|---|---|---|---|---|
| Thunder warrior | Offworlder | Valkyrie | The slot's gods and quest are already Norse. Starts with the existing lightning hammer artifact | None |
| Arcanist | Attuned | Wizard | Spellbooks and a starting cloak | None |
| Feral fighter | Gifted | Samurai | Fast melee plus regeneration | None |
| Weather witch | Gifted | Priest | Lightning and cold powers, flying | None |
| Blaster | Gifted | Ranger | A force bolt power that never fades | The preset must tune the slot's casting numbers. Unverified |
| Armoured inventor | Human | Archeologist | Heavy armour, flying, charged devices | None |
| Acrobat | Altered | Monk | Unarmed fighting, speed, the warning intrinsic | No climbing or swinging power exists in the engine. Left out at first |
| Behemoth | Altered | Barbarian | Top strength, regeneration | Always transformed at first. A two-form version could reuse the lycanthropy rules later |

Waves:

1. Thunder warrior, arcanist, feral fighter.
2. Weather witch, blaster, armoured inventor.
3. Acrobat, behemoth.

Rule of thumb for future heroes:

* A power that exists as an intrinsic, a spell or an item is one line in a preset.
* A power that exists only for monsters is a small C change.
* A power nothing in NetHack does is left out or told through text.

Wave 1 ships in `dat/theme.lua`.

## Companion and tone

The hero is alone with one AI sidekick.
The sidekick uses the pet slot and never starves.
There is no party control.
Enemies are "defeated" and human enemies leave no corpse.

## First playable slice

1. Seam v1: renames with alias and class filter, hero presets, permanent signature power, "defeat" wording, standing bias.
2. The headquarters with one portal.
3. One three-floor mission: two generated city floors and one hand-made boss floor.
4. About 30 renamed enemies, mostly machines.
5. Wave 1 heroes.
6. A sidekick.
7. A scripted smoke test.

The rewritten quest is dropped from the slice because the quest opens at experience level 14.

Targets:

* Fun inside the first 20 minutes.
* Under 300 added lines of C in at most 6 upstream files.
* A trial merge of upstream each session with no conflicts.
* A smoke test that boots each hero, enters the portal, reaches floor 3, saves and restores, and checks for "impossible" and "panic".

## Risks

| Risk | Response |
|---|---|
| Name leak. History is never rewritten | Naming rule in `CLAUDE.md`. Local git hooks. This repository never names a downstream pack |
| Seam creep. Every hook widens the fork | Hold the engine budget. Trial-merge upstream each session |
| Balance. Permanent powers and a sidekick make early floors easier | Missions name their own enemies, so tuning stays in Lua |
| Content against code. The slice is about a third code and two thirds writing and level design | Expect a full conversion to take months, mostly text |
| Base choice. A JavaScript rewrite of NetHack exists and was not evaluated | Stay on NetHack 5.0 in C. Reopen with a new ADR if needed |
| Theme clash. Stock rules fit badly | Leave them for now and revisit after the slice is fun |

## Tested and untested

Tests ran on 2026-11-11 in scratch copies.

| Claim | Status | Detail |
|---|---|---|
| Renaming from a Lua file at startup | Tested | A 28-line prototype renamed monsters, objects and unidentified appearances. Names survived save and restore |
| Aliases, class filters, encyclopedia | Untested | Needed for a full rename |
| Lua generates a city level | Tested | 133 lines of Lua gave a connected level 10 of 10 times |
| Hub with portals to missions | Tested | One hub level, three portals, three `unconnected` dungeons |
| Entering a dungeon from its top floor going up | Tested | Works |
| One stair branch per level | Tested | Engine limit in `place_branch` |
| Hiding roles and races from options | Tested | Works today |
| Build | Tested | About 15 seconds with `make -j8 all` |
| Headquarters as a special level on level 1 | Tested | New games start there |
| Hero preset binding | Tested | Three wave-1 presets boot and play the mission in the smoke test |
| Origin to race slot mapping | Tested | Three gaps fixed through the seam. See ADR 0010 |
| Blaster casting numbers | Untested | Unverified |
| Sidekick never starves | Untested | Expected from pet food rules |
| "Defeat" wording and no human corpse | Tested | A defeated large criminal leaves no corpse |
| WebAssembly browser build | Untested | Later work |
| Git hooks for the naming rule | Untested | Not written yet |

## Build

```
cd sys/unix && sh setup.sh hints/linux.501 && cd ../..
make -j8 all
make install
```

`make install` overwrites the playground, including `sysconf`.
Wizard mode needs `WIZARDS=*` in `playground/sysconf`.

## Decisions

The decisions behind this page are in `heroes/docs/adr/README.md`.
