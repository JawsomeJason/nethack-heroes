-- foundry.lua: boss floor of the first mission, a casting works.
des.level_init({ style = "solidfill", fg = " " })
des.level_flags("mazelevel", "noflip")

local W, H = 79, 21
local XO = -1  -- after des.map{x=2}, level-call x = map column - 1
local g = {}
for y = 0, H - 1 do g[y] = {} for x = 0, W - 1 do g[y][x] = " " end end
local function fill(x1, y1, x2, y2, c) for y = y1, y2 do for x = x1, x2 do g[y][x] = c end end end
local function box(x1, y1, x2, y2)
   fill(x1, y1, x2, y2, ".")
   for x = x1, x2 do g[y1][x] = "-"; g[y2][x] = "-" end
   for y = y1 + 1, y2 - 1 do g[y][x1] = "|"; g[y][x2] = "|" end
end

box(2, 1, 76, 19)            -- works floor
box(58, 5, 76, 15)           -- boss office
g[10][58] = "."              -- its door
fill(14, 2, 18, 4, "L")      -- two melting vats
fill(36, 16, 40, 18, "L")
fill(26, 6, 26, 14, "F")     -- machine cages, a broken line
g[10][26] = "."; g[11][26] = "."
fill(44, 4, 44, 12, "F")
g[8][44] = "."; g[9][44] = "."
fill(60, 6, 60, 9, "F")      -- grille inside the office
fill(60, 11, 60, 14, "F")

local rows = {}
for y = 0, H - 1 do rows[#rows + 1] = table.concat(g[y]) end
des.map({ x = 2, y = 0, map = table.concat(rows, "\n"), lit = true })
des.wallify()
local function X(x) return x + XO end

des.door({ x = X(58), y = 10, state = "closed" })
des.stair("up", X(4), 10)

-- the boss and the reward
des.monster({ id = "ogre", coord = { X(70), 10 }, name = "Foundry Boss", waiting = 1,
              inventory = function() des.object("skeleton key") end })
des.object({ id = "chest", coord = { X(75), 10 }, locked = 1, contents = function()
   des.object("bag of holding")
   des.object("magic lamp")
   des.object("potion of healing"); des.object("potion of healing"); des.object("potion of healing")
end })

-- guards and workers
for _, p in ipairs({ { 64, 7 }, { 64, 13 }, { 55, 10 } }) do
   des.monster({ id = "hill orc", coord = { X(p[1]), p[2] } })
end
des.monster({ id = "hill orc", coord = { X(34), 4 } })
des.monster({ id = "large kobold", coord = { X(20), 14 } })
des.monster({ id = "large kobold", coord = { X(46), 16 } })
des.monster({ id = "jackal", coord = { X(30), 8 } })
des.monster({ id = "jackal", coord = { X(30), 12 } })

-- crates
for _, p in ipairs({ { 8, 3 }, { 9, 3 }, { 8, 17 }, { 20, 17 }, { 50, 3 }, { 52, 17 }, { 66, 6 }, { 66, 14 } }) do
   des.object({ id = "large box", coord = { X(p[1]), p[2] } })
end
for _ = 1, 4 do des.object() end
des.trap("rust", X(40), 8)
