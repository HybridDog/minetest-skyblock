--[[

Skyblock for Minetest

Copyright (c) 2015 cornernote, Brett O'Donnell <cornernote@gmail.com>
Source Code: https://github.com/cornernote/minetest-skyblock
License: GPLv3

]]--


-- override skyblock.make_spawn_blocks
skyblock.make_spawn_blocks = function(spawn,player_name)
	skyblock.levels[1].make_start_blocks(player_name)
end

-- new player
minetest.register_on_newplayer(function(player)
	-- add rewards to player inventory
	player:get_inventory():set_size('rewards', 4)

	-- update feats
	skyblock.feats.update(player:get_player_name())
end)

-- join player
minetest.register_on_joinplayer(function(player)
	-- set inventory formspec
	player:set_inventory_formspec(skyblock.levels.get_formspec(player:get_player_name()))
end)

-- die player
minetest.register_on_dieplayer(function(player)
	-- empty inventory
	skyblock.levels.empty_inventory(player)
	-- reset feats
	skyblock.feats.reset(player:get_player_name())
end)

-- unified inventory skyblock button
unified_inventory.register_button("skyblock", {
	type = "image",
	image = "skyblock_quest.png",
	tooltip = "Skyblock Missions",
	action = function(player)
		skyblock.feats.update(player:get_player_name())
	end,	
})
