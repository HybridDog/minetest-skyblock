--[[

Skyblock for Minetest

Copyright (c) 2015 cornernote, Brett O'Donnell <cornernote@gmail.com>
Source Code: https://github.com/cornernote/minetest-skyblock
License: GPLv3

]]--


-- quest
minetest.register_node("skyblock:quest", {
	description = "Skyblock",
	tiles = {"skyblock_quest.png"},
	is_ground_content = false,
	paramtype = "light",
	light_propagates = true,
	sunlight_propagates = true,
	light_source = 15,
	diggable = false,
	drop = "",
	on_construct = function(pos)
		-- do not remove, needed to init the node
	end,
})

--
minetest.register_node("skyblock:acid", {
	description = "acid gas",
	tiles = {"skyblock_acid.png"},
	drawtype = "glasslike",
	post_effect_color = {a=255, r=72, g=49, b=37},
	is_ground_content = false,
	paramtype = "light",
	use_texture_alpha = true,
	walkable = false,
	diggable = false,
	drop = "",
	pointable = false,
	damage_per_second = 325,
	after_destruct = function(pos)
		local nd = minetest.get_node(pos).name
		if nd ~= "air" then
			minetest.log("error", "[skyblock] "..nd.." tried to replace an acid at "..minetest.pos_to_string(pos))
		end
		minetest.set_node(pos, {name="skyblock:acid"})
	end
})
