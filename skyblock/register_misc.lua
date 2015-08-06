--[[

Skyblock for Minetest

Copyright (c) 2015 cornernote, Brett O'Donnell <cornernote@gmail.com>
Source Code: https://github.com/cornernote/minetest-skyblock
License: GPLv3

]]--

-- set mapgen to singlenode
minetest.register_on_mapgen_init(function(mgparams)
	minetest.set_mapgen_params({mgname='singlenode', water_level=-32000})
end)

-- new player
minetest.register_on_newplayer(function(player)
	-- spawn player
	skyblock.spawn_player(player)
end)

-- respawn player
minetest.register_on_respawnplayer(function(player)
	-- unset old spawn position
	if skyblock.dig_new_spawn then
		local player_name = player:get_player_name()
		local spawn = skyblock.get_spawn(player_name)
		skyblock.set_spawn(player_name, nil)
		skyblock.set_spawn(player_name..'_DEAD', spawn)
	end
	-- spawn player
	skyblock.spawn_player(player)
	return true
end)

-- localization
local y_bottom, c_acid

-- register map generation
minetest.register_on_generated(function(minp, maxp, seed)
	if not y_bottom then
		y_bottom = skyblock.world_bottom
		c_acid = minetest.get_content_id("skyblock:acid")
	end

	-- do not handle mapchunks which are too heigh or too low
	if minp.y > y_bottom then
		return
	end

	local vm, emin, emax = minetest.get_mapgen_object("voxelmanip")
	local data = vm:get_data()
	local area = VoxelArea:new{MinEdge=emin, MaxEdge=emax}

	-- avoid that liquids flown down spread
	if maxp.y >= y_bottom then
		for z = minp.z,maxp.z do
			for x = minp.x,maxp.x do
				if (z+x)%2 == 0 then
					data[area:index(x,y_bottom,z)] = c_acid
				end
			end
		end
		maxp.y = y_bottom-1
	end

	-- the atmosphere is bad for Sam
	for p_pos in area:iterp(minp, maxp) do
		data[p_pos] = c_acid
	end

	-- add starting blocks
	--[[
	local start_pos_list = skyblock.get_start_positions_in_mapchunk(minp, maxp)
	for _,pos in ipairs(start_pos_list) do
		skyblock.make_spawn_blocks_on_generated(pos, data, area)
	end
	]]--

	-- store the voxelmanip data
	vm:set_data(data)
	vm:calc_lighting(emin,emax)
	vm:write_to_map(data)
	vm:update_liquids()
end)


-- no placing low nodes
minetest.register_on_placenode(function(pos)
	if pos.y < y_bottom then
		minetest.remove_node(pos)
		return true -- give back item
	end
end)
