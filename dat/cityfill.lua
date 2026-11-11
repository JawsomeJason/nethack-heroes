-- cityfill.lua: procedurally generated city-street filler level, pure Lua.
des.level_init({ style = "solidfill", fg = " " })
des.level_flags("mazelevel", "noflip")

local VERBOSE = false -- true prints the connectivity result on every generation
local W, H = 79, 21
local XO = -1  -- empirical: after des.map{x=2}, x coords are map col - 1 (y needs no shift)
local g, street = {}, {}          -- g[y][x] = map char; street[y][x] = bool
for y = 0, H - 1 do
   g[y], street[y] = {}, {}
   for x = 0, W - 1 do g[y][x] = (x > 0 and y > 0 and x < W - 1 and y < H - 1) and "." or " " end
end

-- split lo..hi into alternating street/block segments {from, to, kind}
local function cuts(lo, hi, bmin, bmax)
   local segs, pos = {}, lo
   while true do
      local s = math.random(2, 3)
      if hi - pos + 1 - s < bmin + 2 then
         segs[#segs + 1] = { pos, hi, "s" }
         return segs
      end
      segs[#segs + 1] = { pos, pos + s - 1, "s" }
      pos = pos + s
      local b = math.random(bmin, math.min(bmax, hi - pos - 1))
      segs[#segs + 1] = { pos, pos + b - 1, "b" }
      pos = pos + b
   end
end

local function fill(x1, y1, x2, y2, c)
   for y = y1, y2 do for x = x1, x2 do g[y][x] = c end end
end

local doors, rooms, pts = {}, {}, {}

local function building(x1, y1, x2, y2, skip) -- skip: side shared with a neighbour
   fill(x1, y1, x2, y2, " ")                  -- stone; wallify() outlines it
   if math.random(100) <= 50 then              -- solid building: wall ring with barred windows
      for x = x1, x2 do for _, y in ipairs({ y1, y2 }) do
         g[y][x] = (x > x1 and x < x2 and x % 3 == 0) and "F" or "-"
      end end
      for y = y1 + 1, y2 - 1 do for _, x in ipairs({ x1, x2 }) do
         g[y][x] = (y % 3 == 0) and "F" or "|"
      end end
      return
   end
   fill(x1 + 1, y1 + 1, x2 - 1, y2 - 1, ".")
   local dx = math.random(x1 + 1, x2 - 1)
   local dy = math.random(y1 + 1, y2 - 1)
   local side = math.random(4)
   while side == skip do side = math.random(4) end
   local p = ({ { dx, y1 }, { dx, y2 }, { x1, dy }, { x2, dy } })[side]
   local shop = math.random(100) <= 25
   doors[#doors + 1] = { p[1], p[2], shop }
   rooms[#rooms + 1] = { x1 + 1, y1 + 1, x2 - 1, y2 - 1, shop }
end

local function park(x1, y1, x2, y2)
   for y = y1 + 1, y2 - 1 do for x = x1 + 1, x2 - 1 do
      if math.random(100) <= 18 then g[y][x] = "T" end
   end end
   local cx, cy = (x1 + x2) // 2, (y1 + y2) // 2
   if math.random(2) == 1 then g[cy][cx] = "{"
   else fill(cx, cy, cx + 1, cy, "P") end
end

local xs, ys = cuts(1, W - 2, 5, 14), cuts(1, H - 2, 4, 6)
for _, sy in ipairs(ys) do
   for _, sx in ipairs(xs) do
      if sy[3] == "s" or sx[3] == "s" then
         for y = sy[1], sy[2] do for x = sx[1], sx[2] do street[y][x] = true end end
      else
         local x1, y1, x2, y2 = sx[1], sy[1], sx[2], sy[2]
         if math.random(100) <= 12 then park(x1, y1, x2, y2)
         elseif x2 - x1 >= 11 and math.random(2) == 1 then
            local m = math.random(x1 + 5, x2 - 5)
            building(x1, y1, m, y2, 4); building(m + 1, y1, x2, y2, 3)
         else building(x1, y1, x2, y2) end
      end
   end
end

-- stairs go on street cells, far apart; streets form one connected grid
local list = {}
for y = 1, H - 2 do for x = 1, W - 2 do
   if street[y][x] then list[#list + 1] = { x, y } end
end end
local up = list[math.random(#list)]
local dn = up
for _ = 1, 50 do
   dn = list[math.random(#list)]
   if math.abs(dn[1] - up[1]) + math.abs(dn[2] - up[2]) >= 30 then break end
end

local rows = {}
for y = 0, H - 1 do rows[#rows + 1] = table.concat(g[y]) end
des.map({ x = 2, y = 0, map = table.concat(rows, "\n"), lit = true })
des.wallify()

for _, d in ipairs(doors) do
   des.door({ x = d[1] + XO, y = d[2], state = d[3] and "closed" or "random" })
end
for _, r in ipairs(rooms) do
   des.region({ region = { r[1] + XO, r[2], r[3] + XO, r[4] },
                lit = math.random(100) <= 60 and 1 or 0,
                type = r[5] and "shop" or "ordinary", filled = 1 })
   pts[#pts + 1] = { XO + r[1] + math.random(0, r[3] - r[1]), r[2] + math.random(0, r[4] - r[2]) }
end
des.stair("up", up[1] + XO, up[2])
if nh.level_difficulty() == 1 then -- floor 1 of the mission: portal back to the headquarters
   local pp = up
   for _, c in ipairs(list) do
      if math.abs(c[1] - up[1]) + math.abs(c[2] - up[2]) == 3 then pp = c break end
   end
   des.levregion({ region = { pp[1] + 1, pp[2], pp[1] + 1, pp[2] }, region_islev = 1, type = "portal", name = "hq" })
end
des.stair("down", dn[1] + XO, dn[2])

for _ = 1, math.random(8, 12) do des.object() end

-- enemies are named here so difficulty is tuned in this file, not by the generator
local roster = {
   { "sewer rat", "jackal", "hobbit", "grid bug", "kobold", "newt" },
   { "giant rat", "jackal", "large kobold", "hobbit", "hill orc", "giant bat", "jackal" },
}
local depth = math.min(nh.level_difficulty(), #roster)
local foes = roster[depth]
for _ = 1, 3 + depth * 2 do
   local c = list[math.random(#list)]
   des.monster({ id = foes[math.random(#foes)], coord = { c[1] + XO, c[2] } })
end
for _, p in ipairs(pts) do
   if math.random(100) <= 30 then des.monster({ id = foes[math.random(#foes)], coord = p }) end
   if math.random(100) <= 50 then des.object({ coord = p }) end
end
for _ = 1, 3 do des.trap() end

-- in-game verification: flood-fill the real map from the up stairs
do
   local seen, q, reached, nd = {}, { { up[1] + XO, up[2] } }, false, 0
   seen[up[2] * 100 + up[1] + XO + 1] = true
   while #q > 0 do
      local c = table.remove(q)
      if c[1] == dn[1] + XO and c[2] == dn[2] then reached = true end
      for _, o in ipairs({ { 1, 0 }, { -1, 0 }, { 0, 1 }, { 0, -1 } }) do
         local x, y = c[1] + o[1], c[2] + o[2]
         local k = y * 100 + x + 1
         if x >= 0 and x <= 77 and y >= 0 and y <= 20 and not seen[k] then
            local t = nh.getmap(x, y).typ_name
            if t == "room" or t == "door" or t == "stairs" then
               seen[k] = true; q[#q + 1] = { x, y }
               if t == "door" then nd = nd + 1 end
            end
         end
      end
   end
   if VERBOSE or not reached then
      nh.pline("CITYCHECK " .. (reached and "connected" or "DISCONNECTED") .. " doors reached " .. nd .. "/" .. #doors)
   end
end
