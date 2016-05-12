#define MOD_LUA_SPAWN_UNITS
<<
-- Spawns all the preset units so the huge maps can get populated.
local function spawn_human_farmer(coord)
   spawn_unit.spawn_unit(coord[1], coord[2], "Peasant", 6)
end

function spawn_default_starting_units()
   if wesnoth.get_variable("aeth_scenario_name") == "Big Woods" then
      -- human farmers
      local coords = {
         {70, 129},
         {65, 128},
         {58, 125},
         {61, 122},
         {69, 123},
         {73, 124},
         {82, 117},
         {75, 114},
         {71, 116},
         {62, 114},
         {64, 111},
         {61, 109},
         {66, 106},
         {77, 107},
         {83, 111},
         {56, 103},
         {59, 99},
         {57, 96},
         {49, 85},
         {55, 83},
         {51, 81},
         {56, 77},
         {59, 80},
         {63, 75},
         {56, 69},
         {70, 73},
         {72, 78},
         {78, 75},
         {79, 67},
         {86, 66},
         {86, 71},
         {88, 74},
         {93, 67},
         {92, 73},
         {87, 82},
         {91, 83},
         {89, 86},
         {98, 88},
         {104, 89},
         {102, 92},
         {100, 62},
         {104, 62},
         {110, 64},
         {112, 67},
         {108, 74},
         {139, 52},
         {141, 52},
         {141, 48},
         {150, 49},
         {152, 55},
         {155, 55},
         {151, 46},
         {153, 44},
         {158, 46},
         {162, 44},
         {166, 36},
         {178, 37},
         {171, 70},
         {170, 68},
         {173, 63},
         {178, 63},
         {189, 25},
         {195, 25},
         {196, 29},
         {196, 20},
      }
      for i, coord in ipairs(coords) do
         spawn_human_farmer(coord)
      end
   -- else
   --    debugOut(wesnoth.get_variable("aeth_scenario_name"))
   end
end
>>
#enddef