# Theme pack seam

The seam lets a Lua theme pack rename and reshape the game without changing C.
The code is in `src/theme.c` and `include/theme.h`.

## Loading

The engine loads two optional files, once per process, before the role menu shows.

1. `theme.lua`, the public pack. It ships in the data archive (`nhdat`).
2. `pack.lua`, a downstream theme pack. It is a loose file in the install folder.

Both run in one safe Lua sandbox. Later calls override earlier ones.
If `theme.lua` has an error, `pack.lua` is not loaded.
With both files absent, the game is stock NetHack.

Every key is the original NetHack name: monster names, object names, appearances, role names and race nouns.
A downstream pack never depends on the public pack's names.

Nothing from a pack is written to the save file.
Names are applied again in each process, so a restored game shows the names of the packs installed now.

## Name lookup

After a rename, both the original and the themed name resolve in these places:

* Monsters: wizard-mode creation, wishes for figurines and corpses, `des.monster` in level files, and every other caller of `name_to_mon()`.
* Objects: wishes and wizard-mode wishes.
* Objects in level files: `des.object` and `obj.new`. Lua wrappers translate an original name to the themed name.

Other places that match a name as text do not see the original name.
Examples are option values such as `role:Valkyrie`, and the in-game encyclopedia, which is keyed by original names.

## nh.rename_monster(original, new)

Renames every gender form whose original text is `original`.
To set a gendered form, key on that form, such as `"dwarf lady"`.
Returns the number of names changed. 0 means no match.

```lua
nh.rename_monster("gnome lord", "street thug")
nh.rename_monster("dwarf lady", "street boss")
```

## nh.rename_object(original, new [, class])

Renames the object type whose original name is `original`.
`class` is an object class symbol such as `"!"` or `"+"`.
Use it when one name exists in two classes.
Without `class`, every matching type is renamed.
Returns the number of names changed.

```lua
nh.rename_object("healing", "med-spray", "!") -- the potion, not the spell
```

## nh.rename_appearance(original, new [, class])

Renames an unidentified appearance, such as `"ruby"` or `"cloth"`.
Matching and return value are as for `nh.rename_object`.
The appearance shuffle is not changed.

```lua
nh.rename_appearance("ruby", "red gel", "!")
```

## nh.theme_object(original [, class])

Returns the current name for an original object name or appearance, or nil if it is not renamed.
An original object name is never read as an appearance, so `"ruby"` stays the gem after `nh.rename_appearance("ruby", ...)`.
A `"potion of "` style prefix narrows the class and is kept in the result.
The level file wrappers use it. A pack does not normally call it.

```lua
nh.theme_object("potion of healing") -- "potion of med-spray"
```

## nh.role(original, fields)

Changes a role slot. `original` is the stock male role name, such as `"Valkyrie"`.
All fields are optional. A field that is absent keeps its current value.

| Field | Value |
|---|---|
| `name` | Role name. A string, or `{ m = "...", f = "..." }` |
| `ranks` | List of up to 9 rank titles, lowest first. Each is a string or `{ m, f }`. A nil entry keeps that rank |
| `lgod`, `ngod`, `cgod` | Lawful, neutral and chaotic patron names |
| `races` | List of original race nouns the role allows. Replaces the list |
| `sidekick` | Monster name of the starting pet. A pet that is neither a meat eater nor a plant eater never starves |
| `spelbase`, `spelheal`, `spelshld`, `spelarmr`, `spelstat`, `spelspec`, `spelsbon` | Casting numbers, as in `struct Role` |

```lua
nh.role("Valkyrie", {
  name = "Thunder warrior",
  ranks = { "Rookie", { m = "Patrolman", f = "Patrolwoman" } },
  lgod = "the Founder", races = { "human", "dwarf" },
  sidekick = "straw golem", spelbase = 5,
})
```

## nh.race(original, fields)

Changes a race slot. `original` is the stock race noun, such as `"orc"`.
Fields are `noun`, `adj` (adjective), `coll` (collective) and `individual` (a string or `{ m, f }`).

```lua
nh.race("orc", { noun = "Gifted", adj = "Gifted", coll = "the Gifted" })
```

## nh.hero(original_role, fields)

Sets a hero preset for a role. It applies when a new game starts with that role.
All fields are optional.

* `kit` is a list of up to 16 items. It replaces the stock kit.
  Each item is an original object name, or `{ "name", spe = 2, n = 3 }`.
  A `"potion of "` style prefix picks the class.
  Items are uncursed and fully identified.
  Weapons and armour default to +0. Armour is worn and the first weapon is wielded, as with stock kits.
  The stock spells are removed with the stock kit.
  Under `pauper` no kit is given. Under `nudist` the kit has no armour.
  The explore-mode wand of wishing and the wizard-mode kit are kept.
  A kit weapon outside the role's skills unlocks that skill at Basic.
* `intrinsics` is a list of up to 12 property names.
  The names are the engine's property names, as `#wizintrinsic` lists them.
  `"regeneration"`, `"telepathy"` and `"speed"` are also accepted.
  The intrinsics are granted again every turn, so they cannot be lost.
* `spells` is a list of up to 12 original spell names. They are learned at start and never fade.
  A spell whose spellbook is in the kit is learned from the book.

```lua
nh.hero("Valkyrie", {
  kit = { { "war hammer", spe = 2 }, { "potion of healing", n = 2 } },
  intrinsics = { "regeneration", "telepathy", "poison resistance" },
  spells = { "force bolt" },
})
```

## nh.monster_flags(original, flags)

Sets flags on a monster type. The only flag is `nocorpse`.
Returns the number of names matched.

```lua
nh.monster_flags("watchman", { nocorpse = true })
```

## nh.kill_verb(verb, past)

Replaces "kill" in "You kill the newt!" and "killed" in "The newt is killed!".
Both forms are required.
The wording for monsters that are not alive ("destroy") does not change.

```lua
nh.kill_verb("defeat", "defeated")
```

## Testing

`heroes/test/smoke.sh` builds, installs and plays the demonstration pack `dat/theme.lua` in tmux.
It prints one PASS or FAIL line per check.
Untested: race renames, gendered names, `nh.rename_appearance`, the "killed" form, and kits that hold charged items.
