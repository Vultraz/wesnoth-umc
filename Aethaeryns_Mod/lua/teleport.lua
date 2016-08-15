#define MOD_LUA_TELEPORT
<<
local RUNE_ON = "scenery/rune2-glow.png"
local RUNE_OFF = "scenery/rune2.png"

local function add_teleporter_to_list(x, y, is_active, name)
   return "Stub"
end

local function bad_terrain(x, y)
   local terrain = wesnoth.get_terrain(x, y)
   if string.sub(terrain, 0, 1) == "X"
      or string.sub(terrain, 0, 1) == "Q"
      or string.sub(terrain, -2, -1) == "Xm"
      or terrain == "Mv"
   then
      return true
   else
      return false
   end
end

local function occupied_hex(x, y)
   if wesnoth.get_unit(x, y) then
      return true
   else
      return false
   end
end

-- The first empty, non-impassable/unwalkable hex in the radius is
-- the destination.
local function teleport_destination(x, y)
   local candidate_hexes = wesnoth.get_locations { x = x, y = y, radius = 1 }
   -- check the center first
   if not bad_terrain(x, y) and not occupied_hex(x, y) then
      return {x, y}
   end
   -- check the radius (it wastefully checks the center twice)
   for i, hex in ipairs(candidate_hexes) do
      if not bad_terrain(hex[1], hex[2]) and not occupied_hex(hex[1], hex[2]) then
         return hex
      end
   end
   -- The teleportation is blocked if there is no valid destination.
   return false
end

function teleport_unit(x, y, unit, side)
   local destination = teleport_destination(x, y)
   if destination then
      wesnoth.sides[side].gold = wesnoth.sides[side].gold - 20
      fire.teleport_tile(unit.x, unit.y, destination[1], destination[2])
   else
      gui2_error("Teleportation blocked.")
   end
end

function add_teleporter(x, y, is_active, name)
   fire.label(x, y, name)
   if is_active then
      w_items.place_image(x, y, RUNE_ON)
   else
      w_items.place_image(x, y, RUNE_OFF)
   end
   add_teleporter_to_list(x, y, is_active, name)
end

function starter_teleporters()
   add_teleporter(138,   5, false, "Intercontinental Teleporter")
   add_teleporter( 49,  27, true,  "Sellyn Teleporter")
   add_teleporter( 92,  89, true,  "Labaenry Teleporter")
   add_teleporter( 62,  98, true,  "Academy Teleporter")
   add_teleporter( 98, 119, true,  "South Labaenry Teleporter")
   add_teleporter( 47, 158, true,  "Blynaerth Teleporter")
   add_teleporter(172,  53, true,  "Rheon Teleporter")
   add_teleporter(204,  31, true,  "Garn Teleporter")
   add_teleporter(267,  25, true,  "Duldrasiath Teleporter")
   add_teleporter(210,  55, true,  "Deranion Teleporter")
   add_teleporter(147,  86, true,  "Elabril Teleporter")
   add_teleporter(202,  72, true,  "Monastery Teleporter")
   add_teleporter(141, 122, false, "Vargork Teleporter")
   add_teleporter(238,  64, false, "Teleporter") -- desert
   add_teleporter(300,  79, false, "Temple Teleporter")
   add_teleporter(310, 144, false, "Teleporter") -- drake
   add_teleporter(214, 116, false, "Teleporter") -- middle elf town
   add_teleporter(246, 159, false, "Blinadoc Teleporter")
   add_teleporter(214, 171, false, "Vanathion Teleporter")
end
>>
#enddef