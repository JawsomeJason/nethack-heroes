# Rules for coding agents

## What this repository is

This is a public fork of NetHack 5.0, in C.
It becomes an original superhero roguelike.
The game ships as a theme pack (Lua and text data) on top of an almost untouched C engine.
Downstream theme packs can narrow it further.

## Read first

Before any design work, read `heroes/docs/vision.md` and every file in `heroes/docs/adr/`.
Record each new decision as an ADR in `heroes/docs/adr/`.
Copy the section layout of an existing ADR and add it to the index in `heroes/docs/adr/README.md`.

## Naming rule

Use only original, generic names. This applies to every file, commit message, branch name and PR text.
Never write the name of an existing comic, film or game franchise, publisher, character, team or place.
Never write a term that belongs to one.
If a name might belong to one, pick a different name.
History is never rewritten, so a leaked name stays forever.

Never name or describe a downstream theme pack.
Write "a downstream theme pack".
Downstream packs live elsewhere and this repository never names them.
The public origin name is "Gifted".

## Engine budget

Keep engine changes under 300 added lines of C in at most 6 upstream files.
If a change needs more, write an ADR first.

## Where files go

* Fork-specific docs and code go in `heroes/`.
* New fork-specific data files go in `dat/`.

## Licence duty

NetHack is under the NGPL.
Each modified upstream file must carry a prominent notice that it was changed, with the date.

## Checks and CI

Checks run locally through git hooks.
Do not add GitHub Actions workflows.
Do not create a `.github` folder.

## Build

```
cd sys/unix && sh setup.sh hints/linux.501 && cd ../..
make -j8 all
make install
```

`make install` overwrites the playground, including `sysconf`.
Wizard mode needs `WIZARDS=*` in `playground/sysconf`.
