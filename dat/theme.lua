-- Demonstration theme pack (see heroes/docs/seam.md). Keys are ORIGINAL names.
nh.rename_monster("gnome lord", "street thug")  -- named by dat/minefill.lua
nh.rename_monster("straw golem", "recon drone")
nh.rename_monster("newt", "gutter rat")
nh.rename_object("dagger", "stun baton")
nh.rename_object("long sword", "plasma blade")  -- named by dat/tower3.lua
nh.rename_object("healing", "med-spray", "!")   -- the potion, not the spell
nh.monster_flags("newt", { nocorpse = true })
nh.kill_verb("defeat", "defeated")
nh.role("Valkyrie", {
  name = "Thunder warrior",
  ranks = { "Rookie" },
  sidekick = "straw golem",                     -- a golem never eats
})
nh.hero("Valkyrie", {
  kit = { { "war hammer", spe = 2 }, "dagger", { "small shield", spe = 3 },
          { "potion of healing", n = 2 }, "food ration" },
  intrinsics = { "regeneration" },
  spells = { "force bolt" },
})
