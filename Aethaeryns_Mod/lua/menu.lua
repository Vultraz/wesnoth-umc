#define MOD_MENU
<<
mod_menu = {}
mod_menu.lich_image = "portraits/undead/transparent/ancient-lich.png"

local function get_roles()
   local roles = {}
   for i, v in ipairs(SUMMON_ROLES) do
      roles[i] = SUMMON_ROLES[i]
   end
   table.insert(roles, "None")
   return roles
end

local function get_sides_with_all()
   local sides = {"All"}
   for i, v in ipairs(SIDES) do
      sides[i + 1] = SIDES[i]
   end
   return sides
end

local function submenu_inventory_quantity(item, container)
   local title = "Change Inventory"
   local description = string.format("How much of %s do you want to give?", item)
   local label = "Item Quantity:"
   local count = menu_text_input(mod_menu.lich_image, title, description, label)
   if count and count > 0 then
      mod_inventory.add(item, count, container)
   end
end

function mod_menu.toggle(menu_item)
   if mod_menu_items[menu_item].status then
      mod_menu_items[menu_item].status = false
      fire.clear_menu_item(mod_menu_items[menu_item].id)
   else
      mod_menu_items[menu_item].status = true
      fire.set_menu_item(mod_menu_items[menu_item])
   end
end

function mod_menu.select_leader()
   local leader = wesnoth.get_units { side = wesnoth.current.side, canrecruit = true }[1]
   if leader.type == "Peasant" then
      local title = "Leader Selection"
      local description = "Select a leader type."
      local leader_category = menu(LEADER_ROLES, mod_menu.lich_image, title, description, menu_simple_list)
      if leader_category then
         local levels = {}
         for key, value in pairs(regular[leader_category]) do
            if tonumber(string.sub(key, 7)) <= change_unit.max_level then
               table.insert(levels, key)
            end
         end
         table.sort(levels)
         local description = "Select a level."
         local level = menu(levels, mod_menu.lich_image, title, description, menu_simple_list)
         if level then
            local description = "Select a unit."
            local choice = menu(regular[leader_category][level], mod_menu.lich_image, title, description, menu_unit_list, nil, "summoner")
            if choice then
               change_unit.transform(leader.x, leader.y, choice)
            end
         end
      end
   end
end

function mod_menu.summon(summoner_type)
   local e = wesnoth.current.event_context
   local title = string.format("Summon %s", summoner_type)
   local description = "Select a unit level."
   local image = PORTRAIT[summoner_type]
   local levels = {}
   for key, value in pairs(regular[summoner_type]) do
      table.insert(levels, key)
   end
   table.sort(levels)
   local level = menu(levels, image, title, description, menu_simple_list)
   if level then
      local description = "Select a unit to summon."
      local choice = menu(regular[summoner_type][level], image, title, description, menu_unit_list_with_cost, nil, "unit")
      if choice then
         local spawn_success = spawn_unit.reg_spawner(e.x1, e.y1, choice, summoner_type, wesnoth.current.side)
         if not spawn_success then
            gui2_error("Insufficient hitpoints on the attempted summoner.")
         end
      end
   end
end

function mod_menu.summon_summoner()
   local e = wesnoth.current.event_context
   local title = "Summon Summoner"
   local description = "Select a summoner type."
   local summoner_type = menu(SUMMON_ROLES, mod_menu.lich_image, title, description, menu_simple_list)
   if summoner_type then
      local description = "Select a unit to summon."
      local summoner = menu(summoners[summoner_type], mod_menu.lich_image, title, description, menu_unit_list, nil, "summoner")
      if summoner then
         spawn_unit.boss_spawner(e.x1, e.y1, summoner, summoner_type, wesnoth.current.side)
      end
   end
end

function mod_menu.interact()
   local e = wesnoth.current.event_context
   local title = "Interactions"
   local image = mod_menu.lich_image -- todo: definitely not appropriate here
   local interaction_hexes = wesnoth.get_locations { x = e.x1, y = e.y1, radius = 1 }
   local unit_list = {}
   local current_side = wesnoth.current.side
   for i, hex in ipairs(interaction_hexes) do
      local unit = wesnoth.get_unit(hex[1], hex[2])
      if unit ~= nil and unit.side == current_side then
         table.insert(unit_list, unit)
      end
   end
   local unit = unit_list[1]
   if unit_list[2] ~= nil then
      local description = "Which unit is doing the interaction?"
      local selected_unit = menu(unit_list, image, title, description, menu_unit_name_and_location, nil)
      if selected_unit then
         unit = selected_unit
      else
         return
      end
   end
   local description = "How do you want to interact?"
   local option = menu(find_interactions(e.x1, e.y1), image, title, description, menu_picture_list, 1)
   if option then
      if option == "Visit Shop" then
         local description = "What item do you want to purchase from the shop?"
         local inventory = show_current_inventory(containers[e.x1][e.y1]["shop"])
         local item = menu(inventory, "", title, description, menu_picture_list, 1, "item_stats")
         if item then
            mod_inventory.shop_buy(unit, e.x1, e.y1, item, wesnoth.current.side)
         end
      elseif option == "Collect Gold" then
         wesnoth.sides[wesnoth.current.side]["gold"] = wesnoth.sides[wesnoth.current.side]["gold"] + containers[e.x1][e.y1]["gold"]
         game_object.clear(e.x1, e.y1)
      elseif option == "Remove from Chest" then
         local description = "What item do you want to remove from the chest?"
         local inventory = show_current_inventory(containers[e.x1][e.y1]["chest"])
         local item = menu(inventory, "", title, description, menu_picture_list, 1, "item_stats")
         if item then
            mod_inventory.chest_remove(unit, e.x1, e.y1, item)
         end
      elseif option == "Add to Chest" then
         local description = "What item do you want to put in the chest?"
         local inventory = show_current_inventory(wesnoth.get_unit(e.x1, e.y1).variables)
         local item = menu(inventory, "", title, description, menu_picture_list, 1, "item_stats")
         if item then
            mod_inventory.chest_add(unit, e.x1, e.y1, item)
         end
      end
   end
end

function mod_menu.unit_commands()
   local e = wesnoth.current.event_context
   local title = "Unit Commands"
   local description = "What do you want to do with this unit?"
   local image = mod_menu.lich_image -- todo: definitely not appropriate here
   local options = {
      {"Use Item", "icons/potion_red_small.png"},
      {"Upgrades", "attacks/woodensword.png"},
      {"Speak", "icons/letter_and_ale.png"}}
   local option = menu(options, image, title, description, menu_picture_list, 1)
   if option == "Use Item" then
      local description = "Which item do you want to use?"
      local inventory = show_current_inventory(wesnoth.get_unit(e.x1, e.y1).variables)
      local item = menu(inventory, "", title, description, menu_picture_list, 1, "item_stats")
      if item then
         mod_inventory.use(e.x1, e.y1, item)
      end
   elseif option == "Upgrades" then
      submenu_upgrade_unit()
   elseif option == "Speak" then
      fire.custom_message()
   end
end

function mod_menu.unit_editor()
   local e = wesnoth.current.event_context
   local title = "Change Unit"
   local description = "What stat do you want to modify?"
   local options = {"Side", "Inventory", "Transform", "Role", "Stats"}
   local choice = menu(options, mod_menu.lich_image, title, description, menu_simple_list)
   if choice then
      if choice == "Transform" then
         local description = "What unit do you want it to transform to?"
         local label = "Unit Type:"
         local new_unit = menu_text_input(mod_menu.lich_image, title, description, label)
         if new_unit then
            change_unit.transform(e.x1, e.y1, new_unit)
         end
      elseif choice == "Role" then
         local role = menu(get_roles(), mod_menu.lich_image, title, "Select a new (summoning) role for this unit.", menu_simple_list)
         if role then
            change_unit.role(e.x1, e.y1, role)
         end
      elseif choice == "Inventory" then
         local description = "Which item do you want to add?"
         local item = menu(show_all_inventory(), "", title, description, menu_picture_list, 1, "item_stats")
         if item then
            submenu_inventory_quantity(item, wesnoth.get_unit(e.x1, e.y1).variables)
         end
      elseif choice == "Side" then
         local side = menu(SIDES, mod_menu.lich_image, title, "Select a target side.", menu_simple_list)
         if side then
            change_unit.side(e.x1, e.y1, side)
         end
      elseif choice == "Stats" then
         local stats = {"Hitpoints", "Max Hitpoints", "Max Moves",
                        "Experience", "Max Experience", "Gender",
                        "Leader"}
         local stat = menu(stats, mod_menu.lich_image, title, "Which stat do you want to change?", menu_simple_list)
         if stat then
            stat = string.gsub(string.lower(stat), " ", "_")
            if stat ~= "gender" and stat ~= "leader" then
               local description = string.format("What should the new value of %s be?", stat)
               local label = "New Value:"
               local new_value
               new_value = menu_text_input(mod_menu.lich_image, title, description, label)
               if new_value then
                  change_unit[stat](e.x1, e.y1, new_value)
               end
            else
               change_unit[stat](e.x1, e.y1)
            end
         end
      end
   end
end

function mod_menu.terrain_editor()
   local e = wesnoth.current.event_context
   terrain.change_hexes = wesnoth.get_locations { x = e.x1, y = e.y1, radius = terrain.radius }
   local title = "Terrain Editor"
   local description = "Which terrain would you like to switch to?"
   local options = {
      "Repeat last terrain",
      "Set an overlay",
      "Change radius",
      "Water",
      "Flat",
      "Desert",
      "Fall",
      "Frozen",
      "Rough",
      "Cave",
      "Obstacle",
      "Castle",
      "Special"}
   local name = menu(options, mod_menu.lich_image, title, description, menu_simple_list)
   if name then
      if name == "Repeat last terrain" then
         terrain.set_terrain(terrain.last_terrain)
      elseif name == "Change radius" then
         local new_radius = menu(terrain.possible_radius, mod_menu.lich_image, title, "What do you want to set the terrain radius as?", menu_simple_list)
         if new_radius then
            terrain.radius = new_radius
         end
      elseif name == "Set an overlay" then
         local options_overlay = {
            "Repeat last overlay",
            "Water",
            "Desert",
            "Embellishments",
            "Forest",
            "Frozen",
            "Rough",
            "Cave",
            "Obstacle",
            "Village",
            "Bridge",
            "Special",
            "Remove overlay"}
         local overlay_name = menu(options_overlay, mod_menu.lich_image, title, "Which terrain would you like to switch to?", menu_simple_list)
         if overlay_name then
            if overlay_name == "Repeat last overlay" then
               terrain.set_overlay(terrain.last_overlay)
            elseif overlay_name == "Remove overlay" then
               terrain.remove_overlay()
            else
               local terrain_choice = menu(terrain.overlays[overlay_name], mod_menu.lich_image, title, "Which terrain overlay would you like to place?", menu_terrain_list)
               if terrain_choice then
                  terrain.set_overlay(terrain_choice)
               end
            end
         end
      else
         local terrain_choice = menu(terrain.terrain[name], mod_menu.lich_image, title, "Which terrain would you like to place?", menu_terrain_list)
         if terrain_choice then
            terrain.set_terrain(terrain_choice)
         end
      end
   end
end

function mod_menu.place_object()
   local e = wesnoth.current.event_context
   local title = "Place Object"
   local description = "What do you want to do with this unit?"
   local options = {
      {"Place Shop", "scenery/tent-shop-weapons.png"},
      {"Place Chest", "items/chest-plain-closed.png"},
      {"Place Pack", "items/leather-pack.png"},
      {"Place Gold Pile", "items/gold-coins-large.png"},
      {"Clear Hex", "terrain/grass/green-symbol.png"}}
   local option = menu(options, mod_menu.lich_image, title, description, menu_picture_list, 1)
   if option then
      if option == "Place Shop" then
         game_object.simple_place(e.x1, e.y1, "shop", "scenery/tent-shop-weapons.png", true)
      elseif option == "Place Chest" then
         game_object.simple_place(e.x1, e.y1, "chest", "items/chest-plain-closed.png", true) -- items/chest-plain-open.png
      elseif option == "Place Pack" then
         game_object.simple_place(e.x1, e.y1, "pack", "items/leather-pack.png", true)
      elseif option == "Place Gold Pile" then
         local description = "How much gold do you want to place in the pile?"
         local label = "Gold:"
         local gold = menu_text_input(mod_menu.lich_image, title, description, label)
         if gold and type(gold) == "number" and gold > 0 then
            game_object.gold_place(e.x1, e.y1, gold)
         end
      elseif option == "Clear Hex" then
         game_object.clear(e.x1, e.y1)
      end
   end
end

function mod_menu.settings()
   local e = wesnoth.current.event_context
   local title = "Settings"
   local description = "What action do you want to do?"
   local options = {"Modify Container",
                    "Modify Side",
                    "New Scenario",
                    "Toggle Summon Summoners",
                    "Toggle Unit Editor",
                    "Toggle Terrain Editor",
                    "Toggle Place Object"}
   local option = menu(options, mod_menu.lich_image, title, description, menu_simple_list)
   if option then
      if option == "Modify Container" then
         local description = "Which container do you want to modify?"
         local interaction = menu(find_interactions_to_modify(e.x1, e.y1), mod_menu.lich_image, title, description, menu_picture_list, 1)
         if interaction then
            if interaction == "Modify Shop" then
               local description = "Which item do you want to add?"
               local item = menu(show_all_inventory(), "", title, description, menu_picture_list, 1, "item_stats")
               if item then
                  submenu_inventory_quantity(item, containers[e.x1][e.y1]["shop"])
               end
            elseif interaction == "Modify Chest" then
               local description = "Which item do you want to add?"
               local item = menu(show_all_inventory(), "", title, description, menu_picture_list, 1, "item_stats")
               if item then
                  submenu_inventory_quantity(item, containers[e.x1][e.y1]["chest"])
               end
            end
         end
      elseif option == "Modify Side" then
         local description = "Which side do you want to modify?"
         local side = menu(get_sides_with_all(), mod_menu.lich_image, title, description, menu_simple_list)
         if side then
            local description = "Which variable do you want to change?"
            local stats = {"gold", "village_gold", "base_income", "team_name", "objectives"}
            if side == "All" then
               stat = menu(stats, mod_menu.lich_image, title, description, menu_simple_list)
               if stat then
                  if stat ~= "objectives" then
                     local title = string.format("Choose a new value for %s", stat)
                     local label = "New value:"
                     local new_value = menu_text_input(mod_menu.lich_image, title, description, label)
                     if new_value then
                        for i, side in ipairs(wesnoth.sides) do
                           side[stat] = new_value
                           if stat == "team_name" then
                              side.user_team_name = side.team_name
                           end
                        end
                     end
                  end
               end
            else
               local side_stats = {}
               for i, stat in ipairs(stats) do
                  side_stats[i] = {stat, wesnoth.sides[side][stat]}
               end
               stat = menu(side_stats, mod_menu.lich_image, title, description, menu_almost_simple_list, 1, "team_stats")
               if stat then
                  if stat ~= "objectives" then
                     local title = string.format("The old value of %s is: %s ", stat, wesnoth.sides[side][stat])
                     local label = "New value:"
                     local new_value = menu_text_input(mod_menu.lich_image, title, description, label)
                     if new_value then
                        wesnoth.sides[side][stat] = new_value
                        if stat == "team_name" then
                           wesnoth.sides[side].user_team_name = wesnoth.sides[side].team_name
                        end
                     end
                  end
               end
            end
         end
      elseif option == "New Scenario" then
         local description = "Which scenario do you want to start?"
         local scenarios = {"Introduction",
                            "Introduction (Underground)",
                            "Battle",
                            "Cavern",
                            "Classic",
                            "Hide and Seek",
                            "Open Dungeon",
                            "Woods"}
         local scenario_ids = {
            ["Introduction"] = "intro",
            ["Introduction (Underground)"] = "intro2",
            ["Battle"] = "battle",
            ["Cavern"] = "cavern",
            ["Classic"] = "classic",
            ["Hide and Seek"] = "hide_and_seek",
            ["Open Dungeon"] = "open_dungeon",
            ["Woods"] = "woods"}
         local scenario = menu(scenarios, mod_menu.lich_image, title, description, menu_simple_list)
         if scenario then
            fire.end_scenario(scenario_ids[scenario])
         end
      elseif option == "Toggle Summon Summoners" then
         mod_menu.toggle("summon_summoner")
      elseif option == "Toggle Unit Editor" then
         mod_menu.toggle("unit_editor")
      elseif option == "Toggle Terrain Editor" then
         mod_menu.toggle("terrain_editor")
      elseif option == "Toggle Place Object" then
         mod_menu.toggle("place_object")
      end
   end
end

local function menu_item_summon(unit_role)
   local menu_item = {
      id = "MOD_001_"..unit_role,
      text = "Summon "..unit_role,
      image = "terrain/symbols/terrain_group_custom3_30.png",
      filter = aeth_mod_filter.summon(unit_role),
      command = string.format("mod_menu.summon('%s')", unit_role)}
   return menu_item
end

function set_all_menu_items()
   -- Generates a quick yes/no table for summoners.
   for key, unit_list in pairs(summoners) do
      for i, unit in pairs(unit_list) do
         is_summoner[unit] = true
      end
   end
   -- Generates the toggleable, general menu items.
   for key, menu_item in pairs(mod_menu_items) do
      if menu_item.status then
         fire.set_menu_item(menu_item)
      end
   end
   -- Generates the menu items for each summoner type.
   for summoner_type, v in pairs(summoners) do
      fire.set_menu_item(menu_item_summon(summoner_type))
   end
end
>>
#enddef