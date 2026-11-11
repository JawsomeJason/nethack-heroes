-- hq.lua: the headquarters, level 1 of the main dungeon.
des.level_init({ style = "solidfill", fg = " " })
des.level_flags("mazelevel", "noflip")

local W, H = 79, 21
local XO = -1  -- after des.map{x=2}, level-call x = map column - 1
local g = {}
for y = 0, H - 1 do g[y] = {} for x = 0, W - 1 do g[y][x] = " " end end

local function box(x1, y1, x2, y2)
   for y = y1, y2 do for x = x1, x2 do
      local edge = x == x1 or x == x2 or y == y1 or y == y2
      g[y][x] = edge and ((y == y1 or y == y2) and "-" or "|") or "."
   end end
end
local function door(x, y) g[y][x] = "." end -- real doors are added after the map

-- three upper rooms share the top wall row of the hall
box(2, 1, 22, 9)    -- briefing room
box(24, 1, 44, 9)   -- supply room
box(46, 1, 66, 9)   -- infirmary
box(2, 9, 66, 18)   -- main hall
box(66, 9, 76, 18)  -- launch bay
local doors = { { 12, 9 }, { 34, 9 }, { 56, 9 }, { 66, 13 } }
for _, d in ipairs(doors) do door(d[1], d[2]) end
g[4][56] = "{"      -- infirmary fountain

local rows = {}
for y = 0, H - 1 do rows[#rows + 1] = table.concat(g[y]) end
des.map({ x = 2, y = 0, map = table.concat(rows, "\n"), lit = true })
des.wallify()

local function X(x) return x + XO end
for _, d in ipairs(doors) do des.door({ x = X(d[1]), y = d[2], state = "nodoor" }) end

-- The engine always puts the dungeon exit stair on level 1 (a branch) and starts a new game on it.
-- It is the briefing room entrance, and climbing it asks the engine's "no return" confirmation.
des.levregion({ region = { 10, 7, 10, 7 }, region_islev = 1, type = "branch" })
des.stair("down", X(62), 16)
des.levregion({ region = { 73, 13, 73, 13 }, region_islev = 1, type = "portal", name = "cityfill" })

-- briefing room
des.monster({ id = "watchman", name = "Mentor", peaceful = 1, coord = { X(12), 4 }, waiting = 1 })
des.object({ id = "scroll of magic mapping", coord = { X(8), 3 } })
-- supply room
for i = 0, 2 do des.object({ id = "potion of healing", coord = { X(28 + i), 3 } }) end
des.object({ id = "scroll of magic mapping", coord = { X(34), 3 } })
des.object({ id = "scroll of magic mapping", coord = { X(35), 3 } })
des.object({ id = "sack", coord = { X(40), 3 } })
des.object({ id = "lock pick", coord = { X(41), 3 } })
des.object({ id = "cloak of protection", coord = { X(42), 3 } })
-- infirmary
des.object({ id = "stethoscope", coord = { X(50), 3 } })
des.object({ id = "potion of extra healing", coord = { X(51), 3 } })

-- the portal is a hidden trap, so signs in the launch bay doorway and in front of it mark it
des.engraving({ coord = { X(67), 13 }, type = "burn", text = "LAUNCH BAY. MISSION GATE AHEAD." })
des.engraving({ coord = { 70, 13 }, type = "burn", text = "MISSION GATE" })
