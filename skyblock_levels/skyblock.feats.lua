--[[

Skyblock for Minetest

Copyright (c) 2015 cornernote, Brett O'Donnell <cornernote@gmail.com>
Source Code: https://github.com/cornernote/minetest-skyblock
License: GPLv3

]]--

-- expose api
skyblock.feats = {}

-- file to save players feat
local filepath = minetest.get_worldpath()..'/players/'


-- local variable to save players feats
local players_feat = {}

-- get players current level
function skyblock.feats.get_level(player_name)
	skyblock.log('skyblock.feats.get_level('..player_name..')')
	return skyblock.feats.get(0, player_name, 'level')
end

-- reset
function skyblock.feats.reset(player_name)
	skyblock.log('skyblock.feats.reset('..player_name..')')
	players_feat[player_name] = {}
	skyblock.feats.save(players_feat[player_name], player_name)
	skyblock.feats.update(player_name)
end

-- update feats
function skyblock.feats.update(player_name)
	skyblock.log('skyblock.feats.update('..player_name..')')
	local level = skyblock.feats.get_level(player_name)
	local pos = skyblock.get_spawn(player_name)
	if not pos or not skyblock.levels[level] then return end
	local info = skyblock.levels[level].get_info(player_name)

	-- next level
	if info.count==info.total then
		skyblock.levels[level+1].make_start_blocks(info.player_name)
		skyblock.feats.add(0,info.player_name,'level')
		info = skyblock.levels[level+1].get_info(info.player_name)
	end
	
	-- update formspecs
	minetest.get_player_by_name(player_name):set_inventory_formspec(info.formspec)
	local meta = minetest.env:get_meta(pos)
	meta:set_string('formspec', info.formspec_quest)
	meta:set_string('infotext', info.infotext)
end

-- get feat
function skyblock.feats.get(level,player_name,feat)
	--skyblock.log('skyblock.feats.get('..level..','..player_name..','..feat..')')
	if players_feat[player_name] == nil then
		players_feat[player_name] = skyblock.feats.load(player_name) or {}
	end
	if players_feat[player_name][level] == nil then
		players_feat[player_name][level] = {}
	end
	if players_feat[player_name][level][feat] == nil then
		players_feat[player_name][level][feat] = 0
		if feat=='level' then
			players_feat[player_name][level][feat] = 1
		end
	end
	return players_feat[player_name][level][feat]
end

-- add feat
function skyblock.feats.add(level,player_name,feat)
	skyblock.log('skyblock.feats.add('..level..','..player_name..','..feat..')')
	local player_feat = skyblock.feats.get(level,player_name,feat)
	players_feat[player_name][level][feat] = player_feat + 1
	if level==0 or feat=='level' then
		skyblock.feats.save(players_feat[player_name], player_name)
		return
	end
	local rewarded = skyblock.levels[level].reward_feat(player_name,feat)
	
	-- update
	if rewarded then
		--minetest.chat_send_player(player_name, 'You earned the feat "'..feat..'"')
		minetest.chat_send_all(player_name..' completed the quest "'..feat..'" on level '..level)
		minetest.log('action', player_name..' completed the quest "'..feat..'" on level '..level)
	end
	
	skyblock.feats.save(players_feat[player_name], player_name)
	skyblock.feats.update(player_name)
end

-- give reward
function skyblock.feats.give_reward(level,player_name,item_name)
	skyblock.log('skyblock.feats.give_reward('..level..','..player_name..','..item_name..')')
	local player = minetest.get_player_by_name(player_name)
	player:get_inventory():add_item('rewards', item_name)
	--player:set_inventory_formspec(skyblock.levels.get_formspec(player_name))
end

-- track eating
function skyblock.feats.on_item_eat(hp_change, replace_with_item, itemstack, user, pointed_thing)
	if not user then return end
	local player_name = user:get_player_name()
	local level = skyblock.feats.get_level(player_name)
	if( skyblock.levels[level].on_item_eat ) then
		skyblock.levels[level].on_item_eat(player_name, itemstack)
	end
end
minetest.register_on_item_eat(skyblock.feats.on_item_eat)

-- track node digging
function skyblock.feats.on_dignode(pos, oldnode, digger)
	if not digger then return end -- needed to prevent server crash when player leaves
	local player_name = digger:get_player_name()
	local level = skyblock.feats.get_level(player_name)
	skyblock.levels[level].on_dignode(pos, oldnode, digger)
end
minetest.register_on_dignode(skyblock.feats.on_dignode)

-- track node placing
function skyblock.feats.on_placenode(pos, newnode, placer, oldnode)
	if not placer then return end -- needed to prevent server crash when player leaves
	local player_name = placer:get_player_name()
	local level = skyblock.feats.get_level(player_name)
	skyblock.levels[level].on_placenode(pos, newnode, placer, oldnode)
end
minetest.register_on_placenode(skyblock.feats.on_placenode)

-- track on_place of items with their own on_place
local function on_place(v, is_craftitem)
	local entity = minetest.registered_items[ v ];
	if entity and entity.on_place then
		local old_on_place = entity.on_place;
		function entity.on_place(itemstack, placer, pointed_thing)
			local old_count = itemstack:get_count();
			local res = old_on_place( itemstack, placer, pointed_thing );
			if( itemstack and itemstack:get_count() == old_count-1 ) then
				skyblock.feats.on_placenode(pointed_thing, {name=v,param2=0}, placer, nil);
			end
			return res;
		end
		if( is_craftitem == 1 ) then
			minetest.register_craftitem(":"..v, entity);
		else
			minetest.register_node(":"..v, entity);
		end
	end
end
for _,v in ipairs({"doors:door_wood","doors:door_glass","doors:door_steel","doors:door_obsidian_glass"}) do
	on_place(v,1);
end
for _,v in ipairs({"default:cactus", "farming:seed_wheat", "farming:seed_cotton"}) do
	on_place(v,0);
end

-- track bucket feats
function skyblock.feats.bucket_on_use(itemstack, user, pointed_thing)
	if not user then return end -- needed to prevent server crash when player leaves
	local player_name = user:get_player_name()
	local level = skyblock.feats.get_level(player_name)
	skyblock.levels[level].bucket_on_use(player_name, pointed_thing)
end

-- track bucket_water feats
function skyblock.feats.bucket_water_on_use(itemstack, user, pointed_thing)
	if not user then return end -- needed to prevent server crash when player leaves
	local player_name = user:get_player_name()
	local level = skyblock.feats.get_level(player_name)
	skyblock.levels[level].bucket_water_on_use(player_name, pointed_thing)
end

-- track bucket_lava feats
function skyblock.feats.bucket_lava_on_use(itemstack, user, pointed_thing)
	if not user then return end -- needed to prevent server crash when player leaves
	local player_name = user:get_player_name()
	local level = skyblock.feats.get_level(player_name)
	skyblock.levels[level].bucket_lava_on_use(player_name, pointed_thing)
end

-- bucket_empty
local function bucket_on_use(itemstack, user, pointed_thing)
	-- Must be pointing to node
	if pointed_thing.type ~= 'node' then
		return
	end
	-- Check if pointing to a liquid source
	local n = minetest.env:get_node(pointed_thing.under)
	liquiddef = bucket.liquids[n.name]
	if liquiddef ~= nil and liquiddef.source == n.name and liquiddef.itemname ~= nil then
		
		-- begin track bucket feats
		skyblock.feats.bucket_on_use(itemstack, user, pointed_thing)
		-- end track bucket feats
	
		minetest.env:add_node(pointed_thing.under, {name='air'})
		return {name=liquiddef.itemname}
	end
end
minetest.override_item('bucket:bucket_empty', {
	on_place = bucket_on_use,
	on_use = bucket_on_use,
})

-- bucket_water
local function bucket_water_on_use(itemstack, user, pointed_thing)
	-- Must be pointing to node
	if pointed_thing.type ~= 'node' then
		return
	end
	-- Check if pointing to a liquid
	local n = minetest.env:get_node(pointed_thing.under)
	if bucket.liquids[n.name] == nil then
		-- Not a liquid

		-- begin anti-grief change
		local player_name = user:get_player_name()
		local spawn = skyblock.get_spawn(player_name)
		local range = skyblock.start_gap/3 -- how far from spawn you can use water
		local pos = pointed_thing.under
		if spawn==nil or (pos.x-spawn.x > range or pos.x-spawn.x < range*-1) or (pos.y-spawn.y > range/2 or pos.y-spawn.y < range*-1/2) or (pos.z-spawn.z > range or pos.z-spawn.z < range*-1) then
			minetest.chat_send_player(player_name, 'Cannot use bucket so far from your home.')
			return
		end
		-- end anti-grief change

		minetest.env:add_node(pointed_thing.above, {name='default:water_source'})
	elseif n.name ~= 'default:water_source' then
		-- It's a liquid
		minetest.env:add_node(pointed_thing.under, {name='default:water_source'})
	end

	-- begin track bucket feats
	skyblock.feats.bucket_water_on_use(itemstack, user, pointed_thing)
	-- end track bucket feats

	return {name='bucket:bucket_empty'}
end
minetest.override_item('bucket:bucket_water', {
	on_place = bucket_water_on_use,
	on_use = bucket_water_on_use,
})

-- bucket_lava
local function bucket_lava_on_use(itemstack, user, pointed_thing)
	-- Must be pointing to node
	if pointed_thing.type ~= 'node' then
		return
	end
	-- Check if pointing to a liquid
	local n = minetest.env:get_node(pointed_thing.under)
	if bucket.liquids[n.name] == nil then
		-- Not a liquid

		-- begin anti-grief change
		local player_name = user:get_player_name()
		local spawn = skyblock.get_spawn(player_name)
		local range = skyblock.start_gap/3 -- how far from spawn you can use lava
		local pos = pointed_thing.under
		if spawn==nil or (pos.x-spawn.x > range or pos.x-spawn.x < range*-1) or (pos.z-spawn.z > range or pos.z-spawn.z < range*-1) then
			--if (pos.y-spawn.y > range/2 or pos.y-spawn.y < range*-1/2) then
				minetest.chat_send_player(player_name, 'Cannot use bucket so far from your home.')
				return
			--end
		end
		-- end anti-grief change

		minetest.env:add_node(pointed_thing.above, {name='default:lava_source'})
	elseif n.name ~= 'default:lava_source' then
		-- It's a liquid
		minetest.env:add_node(pointed_thing.under, {name='default:lava_source'})
	end

	-- begin track bucket feats
	skyblock.feats.bucket_lava_on_use(itemstack, user, pointed_thing)
	-- end track bucket feats

	return {name='bucket:bucket_empty'}
end
minetest.override_item('bucket:bucket_lava', {
	on_place = bucket_lava_on_use,
	on_use = bucket_lava_on_use,
})

-- save data
function skyblock.feats.save(data,player_name)
	local file,err = io.open(filepath..player_name..'.feats', 'wb')
	if err then return nil end
	file:write(minetest.serialize(data))
	file:close()
end

-- load data
function skyblock.feats.load(player_name)
	local file,err = io.open(filepath..player_name..'.feats', 'r')
	if err then return nil end
	local data = file:read('*all')
	file:close()
	return minetest.deserialize(data)
end
