-- theme.lua: the public superhero pack, first playable slice.
-- The API is in heroes/docs/seam.md. Every key is an ORIGINAL NetHack name.

-- monsters: early enemies are machines and street criminals
local function mon(keys, new, criminal)
   for _, k in ipairs(keys) do nh.rename_monster(k, new) end
   if criminal then nh.monster_flags(keys[1], { nocorpse = true }) end
end
local machines = {
   { { "newt" }, "mini drone" },
   { { "sewer rat" }, "scuttle bot" },
   { { "giant rat" }, "sewer crawler" },
   { { "jackal" }, "patrol drone" },
   { { "fox" }, "guard drone" },
   { { "coyote" }, "scrap hound" },
   { { "grid bug" }, "circuit bug" },
   { { "giant bat" }, "hover drone" },
   { { "gas spore" }, "floating mine" },
   { { "giant ant" }, "crawler drone" },
   { { "killer bee" }, "stinger drone" },
   { { "soldier ant" }, "assault drone" },
   { { "straw golem" }, "recon drone" },  -- sidekicks: golems never eat
   { { "paper golem" }, "paper familiar" },
   { { "rope golem" }, "tracker bot" },
}
local criminals = {
   { { "hobbit" }, "pickpocket" },
   { { "goblin" }, "lookout" },
   { { "hobgoblin" }, "goon" },
   { { "kobold" }, "mugger" },
   { { "large kobold" }, "gang tough" },
   { { "kobold lord", "kobold lady", "kobold leader" }, "gang lieutenant" },
   { { "kobold shaman" }, "hex dealer" },
   { { "hill orc" }, "enforcer" },
   { { "orc shaman" }, "gang chemist" },
   { { "orc-captain" }, "crew boss" },
   { { "gnome" }, "tunnel rat" },
   { { "gnome lord", "gnome lady", "gnome leader" }, "street thug" }, -- named by dat/minefill.lua
   { { "dwarf" }, "smuggler" },
   { { "ogre" }, "brute" },
   { { "ogre lord", "ogre lady", "ogre leader" }, "brute boss" },
   { { "ogre king", "ogre queen", "ogre tyrant" }, "crime lord" },
   { { "watchman" }, "beat cop" },          -- the police: peaceful, but human
   { { "watch captain" }, "precinct captain" },
}
for _, m in ipairs(machines) do mon(m[1], m[2], false) end
for _, m in ipairs(criminals) do mon(m[1], m[2], true) end
nh.kill_verb("defeat", "defeated")

-- objects the headquarters, the mission and the kits use
nh.rename_object("dagger", "stun baton")
nh.rename_object("long sword", "plasma blade")  -- named by dat/tower3.lua
nh.rename_object("healing", "med-spray", "!")   -- the potion, not the spell
nh.rename_object("extra healing", "trauma spray", "!")
nh.rename_object("full healing", "revival spray", "!")
nh.rename_object("magic mapping", "city map", "?")
nh.rename_object("chest", "strongbox")
nh.rename_object("large box", "crate")
nh.rename_object("sack", "duffel bag")
nh.rename_object("lock pick", "bypass tool")
nh.rename_object("skeleton key", "master keycard")
nh.rename_object("stethoscope", "med scanner")
nh.rename_object("cloak of protection", "armored coat")

-- origins on the race slots (ADR 0004, tested in ADR 0010)
nh.race("human", { noun = "Human", adj = "Human", coll = "humanity" })
nh.race("orc", { noun = "Gifted", adj = "Gifted", coll = "the Gifted",
                 individual = "Gifted", friends = {},   -- orc monsters are not kin
                 aligns = { "lawful", "neutral", "chaotic" } })
nh.race("gnome", { noun = "Altered", adj = "Altered", coll = "the Altered",
                   individual = "Altered", foes = {} }) -- only the Gifted are feared
nh.race("elf", { noun = "Attuned", adj = "Attuned", coll = "the Attuned",
                 individual = "Attuned" })
nh.race("dwarf", { noun = "Offworlder", adj = "Offworld", coll = "the Offworlders",
                   individual = "Offworlder" })

-- wave-1 heroes; the other ten role slots allow no origin, so the menu hides them
for _, r in ipairs({ "Archeologist", "Barbarian", "Caveman", "Healer", "Knight",
                     "Monk", "Priest", "Rogue", "Ranger", "Tourist" }) do
   nh.role(r, { races = {} })
end

nh.role("Valkyrie", {
   name = "Thunder warrior",
   ranks = { "Spark Novice", "Cloud Runner", "Rain Caller", "Gale Rider",
             "Thunder Caller", "Lightning Hand", "Sky Warden", "Thunder Marshal",
             "Sky Sovereign" },
   lgod = "the Thunder Court", ngod = "the Open Sky", cgod = "the Wild Wind",
   races = { "human", "dwarf" },
   sidekick = "straw golem",
})
nh.hero("Valkyrie", {
   kit = { { "war hammer", spe = 2 }, "dagger", { "small shield", spe = 3 },
           { "potion of healing", n = 2 }, "food ration" },
   intrinsics = { "shock resistance" },
   spells = { "force bolt" },
})

-- three origins: Altered and Attuned share the menu letter A
nh.role("Wizard", {
   name = "Arcanist",
   ranks = { "Apprentice", "Initiate", "Adept", "Scholar", "Spellwright",
             "Warder", "Ward Master", "High Arcanist", "Archmage" },
   lgod = "the First Ward", ngod = "the Open Book", cgod = "the Deep Dark",
   races = { "human", "elf", "orc" },
   sidekick = "paper golem",
})
nh.hero("Wizard", {
   kit = { { "quarterstaff", spe = 1 }, "cloak of magic resistance",
           "wand of striking", "spellbook of force bolt",
           { "potion of healing", n = 2 } },
   spells = { "force bolt", "protection" },
})

-- no weapon: the slot fights bare-handed with martial arts
nh.role("Samurai", {
   name = "Feral fighter",
   ranks = { "Stray", "Street Scrapper", "Pack Runner", "Scent Tracker",
             "Brawler", "Night Hunter", "Pack Leader", "Pack Alpha", "Apex Hunter" },
   lgod = "the Pack", ngod = "the Old Forest", cgod = "the Red Moon",
   races = { "human", "orc" },
   sidekick = "rope golem",
})
nh.hero("Samurai", {
   kit = { "leather jacket", { "potion of healing", n = 2 },
           { "cram ration", n = 3 } },  -- the slot shows a food ration by another name
   intrinsics = { "regeneration" },
})
