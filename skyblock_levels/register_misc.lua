--[[

Skyblock for Minetest

Copyright (c) 2015 cornernote, Brett O'Donnell <cornernote@gmail.com>
Source Code: https://github.com/cornernote/minetest-skyblock
License: GPLv3

]]--


-- new player
minetest.register_on_newplayer(function(player)
	local player_name = player:get_player_name()
	-- add rewards to player inventory
	player:get_inventory():set_size('rewards', 4)
	-- update feats
	skyblock.feats.update(player_name)
	-- init level1
	skyblock.levels[1].init(player_name)
end)

-- join player
minetest.register_on_joinplayer(function(player)
	-- set inventory formspec
	player:set_inventory_formspec(skyblock.levels.get_formspec(player:get_player_name()))
end)

-- die player
minetest.register_on_dieplayer(function(player)
	local player_name = player:get_player_name()
	-- empty inventory
	skyblock.levels.empty_inventory(player)
	-- reset feats
	skyblock.feats.reset(player_name)
	-- init level1
	skyblock.levels[1].init(player_name)
end)

-- unified inventory skyblock button
if unified_inventory then
	unified_inventory.register_button('skyblock', {
		type = 'image',
		image = 'ui_skyblock_icon.png',
		tooltip = 'Skyblock Quests',
		action = function(player)
			skyblock.feats.update(player:get_player_name())
		end,	
	})
end