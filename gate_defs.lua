local function swap_gate_node(pos,name,dir)
	local node = core.get_node(pos)
	local meta = core.get_meta(pos)
	local meta0 = meta:to_table()
	node.name = name
	node.param2=dir
	core.set_node(pos,node)
	meta:from_table(meta0)
end

local function addGateNode(gateNodes, pos)
	gateNodes[#gateNodes+1] = vector.new(pos)
end

local function placeGate(player,pos)
	local dir = minetest.dir_to_facedir(player:get_look_dir())
	local pos1 = vector.new(pos)
	local gateNodes = {}
	addGateNode(gateNodes, pos1)
	pos1.y=pos1.y+1
	addGateNode(gateNodes, pos1)
	for i=1,2 do
		if core.get_node(gateNodes[i]).name ~= "air" then
			print("not enough space")
			return false
		end
	end
	core.set_node(pos, {name="gateway_light:gatenode_off", param2=dir})
	local player_name = player:get_player_name()
	local meta = core.get_meta(pos)
	meta:set_string("infotext", "Gateway\rOwned by: "..player_name)
	meta:set_int("gateActive", 0)
	meta:set_string("owner", player_name)
	meta:set_string("dont_destroy", "false")
	gateway_light.registerGate(player_name, pos, dir)
	return true
end

local function removeGate(pos)
	local meta = core.get_meta(pos)
	if meta:get_string("dont_destroy") == "true" then
		-- when swapping it
		return
	end
	gateway_light.unregisterGate(meta:get_string("owner"), pos)
end

function gateway_light.activateGate(pos)
	local node = core.get_node(pos)
	local dir=node.param2
	local meta = core.get_meta(pos)
	meta:set_int("gateActive",1)
	meta:set_string("dont_destroy","true")
	minetest.sound_play("gateOpen", {pos = pos, max_hear_distance = 72,})
    local color = ""
    if meta:get_string("_color") then
        local stored_color = meta:get_string("_color")
        if stored_color == "blue" or stored_color == "red" or stored_color == "green" or stored_color == "violet" or stored_color == "orange" or stored_color == "yellow" or stored_color == "pink" or stored_color == "cyan" then
            color = "_" .. stored_color
        end
    end
	swap_gate_node(pos,"gateway_light:gatenode_on" .. color,dir)
	meta:set_string("dont_destroy","false")
end

function gateway_light.deactivateGate(pos)
	local node = core.get_node(pos)
	local dir=node.param2
	local meta = core.get_meta(pos)
	meta:set_int("gateActive",0)
	meta:set_string("dont_destroy","true")
	minetest.sound_play("gateClose", {pos = pos, gain = 1.0,loop = false, max_hear_distance = 72,})
	swap_gate_node(pos,"gateway_light:gatenode_off",dir)
	meta:set_string("dont_destroy","false")
end

local function gateCanDig(pos, player)
	local meta = core.get_meta(pos)
	return meta:get_string("dont_destroy") ~= "true"
		and player:get_player_name() == meta:get_string("owner")
end

local sg_collision_box = {
	type = "fixed",
	fixed={{-0.5,-0.5,-0.5,0.5,-0.42,0.5},},
}

local sg_selection_box = {
	type = "fixed",
	fixed={{-0.5,-0.5,-0.5,0.5,1.5,0.5},},
}

function gateway_light.node_abm(pos, node, active_object_count, active_object_count_wider)
    if pos then
	    --local owner
	    for _,object in pairs(core.get_objects_inside_radius(pos, 1)) do
		    if object:is_player() then
			    local player_name = object:get_player_name()
			    local gate = gateway_light.findGate(pos)
			    if not gate then
				    print("Gate is not registered!")
				    return
			    end
			    --owner = owner or core.get_meta(pos):get_string("owner")
			    if gate.type == "private"
			    and player_name ~= core.get_meta(pos):get_string("owner") then
				    return
			    end
			    local pos1 = vector.new(gate.destination)
			    if not gateway_light.findGate(pos1) then
				    gate.destination = nil
				    gateway_light.deactivateGate(pos)
				    gateway_light.save_data(core.get_meta(pos):get_string("owner"))
				    return
			    end
			    local dir1 = gate.destination_dir
			    local dest_angle
				if dir1 == 0 then
					pos1.z = pos1.z-2
					dest_angle = 180
				elseif dir1 == 1 then
					pos1.x = pos1.x-2
					dest_angle = 90
				elseif dir1 == 2 then
					pos1.z=pos1.z+2
					dest_angle = 0
				elseif dir1 == 3 then
					pos1.x = pos1.x+2
					dest_angle = -90
				end
			    object:moveto(pos1,false)
			    object:set_look_yaw(math.rad(dest_angle))
			    core.sound_play("enterEventHorizon", {pos = pos, max_hear_distance = 72})
		    end
	    end
    end
end

local sg_groups = {snappy=2,choppy=2,oddly_breakable_by_hand=2,not_in_creative_inventory=1}
local sg_groups1 = {snappy=2,choppy=2,oddly_breakable_by_hand=2}

local node_config = {
	tiles = {
		{name = "gateway_metal.png"},
		{
		name = "puddle_animated2.png",
		animation = {
			type = "vertical_frames",
			aspect_w = 16,
			aspect_h = 16,
			length = 2.0,
			},
		},
		{
		name = "gateway_particle_anim.png",
		animation = {
			type = "vertical_frames",
			aspect_w = 16,
			aspect_h = 16,
			length = 1.5,
			},
        },
		{
		name = "gateway_portal.png",
		animation = {
			type = "vertical_frames",
			aspect_w = 16,
			aspect_h = 16,
			length = 1.5,
			},
		},
	},
	alpha = 192,
	drawtype = "mesh",
	mesh = "gateway.b3d",
	visual_scale = 1.0,
	groups = sg_groups,
	drop="gateway_light:gatenode_off",
	paramtype2 = "facedir",
	paramtype = "light",
	light_source = 10,
	selection_box = sg_selection_box,
	collision_box = sg_collision_box,
	can_dig = gateCanDig,
	on_destruct = removeGate,
	on_rightclick=gateway_light.gateFormspecHandler,
}

minetest.register_node("gateway_light:gatenode_on",node_config)

local blue_portal = node_config
blue_portal.tiles[4].name="gateway_portal.png^[multiply:#0063b0"
minetest.register_node("gateway_light:gatenode_on_blue",blue_portal)

local green_portal = node_config
green_portal.tiles[4].name="gateway_portal.png^[multiply:#4ee34c"
minetest.register_node("gateway_light:gatenode_on_green",green_portal)

local red_portal = node_config
red_portal.tiles[4].name="gateway_portal.png^[multiply:#dc1818"
minetest.register_node("gateway_light:gatenode_on_red",red_portal)

local violet_portal = node_config
violet_portal.tiles[4].name="gateway_portal.png^[multiply:#a437ff"
minetest.register_node("gateway_light:gatenode_on_violet",violet_portal)

local cyan_portal = node_config
cyan_portal.tiles[4].name="gateway_portal.png^[multiply:#07B6BC"
minetest.register_node("gateway_light:gatenode_on_cyan",cyan_portal)

local orange_portal = node_config
orange_portal.tiles[4].name="gateway_portal.png^[multiply:#ff8b0e"
minetest.register_node("gateway_light:gatenode_on_orange",orange_portal)

local yellow_portal = node_config
yellow_portal.tiles[4].name="gateway_portal.png^[multiply:#ffe400"
minetest.register_node("gateway_light:gatenode_on_yellow",yellow_portal)

local pink_portal = node_config
pink_portal.tiles[4].name="gateway_portal.png^[multiply:#ff62c6"
minetest.register_node("gateway_light:gatenode_on_pink",pink_portal)

minetest.register_node("gateway_light:gatenode_off",{
	description = "Light Gateway",
	inventory_image = "stargate.png",
	wield_image = "stargate.png",
	tiles = {"gateway_metal.png",
        {
		name = "puddle_animated2.png",
		animation = {
			type = "vertical_frames",
			aspect_w = 16,
			aspect_h = 16,
			length = 2.0,
			},
		},
        "null.png"
	},
	groups = sg_groups1,
	paramtype2 = "facedir",
	paramtype = "light",
	drawtype = "mesh",
	mesh = "gateway.b3d",
	visual_scale = 1.0,
	light_source = 10,
	selection_box = sg_selection_box,
	collision_box = sg_collision_box,
	can_dig = gateCanDig,
    _color = "",
	on_destruct = removeGate,
	on_place = function(itemstack, placer, pointed_thing)
		local pos = pointed_thing.above
		if placeGate(placer,pos)==true then
			itemstack:take_item(1)
			return itemstack
		else
			return
		end
	end,
	on_rightclick=gateway_light.gateFormspecHandler,
    on_punch = function(pos, node, puncher, pointed_thing)
	    local player_name = puncher:get_player_name()
        local meta = core.get_meta(pos)
	    if player_name ~= meta:get_string("owner") then
		    return
	    end

        local itmstck=puncher:get_wielded_item()
        local item_name = ""
        if itmstck then item_name = itmstck:get_name() end

        -- deal with painting or destroying
	    if itmstck then
		    local _,indx = item_name:find('dye:')
		    if indx then
                --lets paint!!!!
                meta:set_string("_color", item_name:sub(indx+1));
            end
        end
    end,
})

minetest.register_abm({
	nodenames = {"gateway_light:gatenode_on", "gateway_light:gatenode_on_blue",
        "gateway_light:gatenode_on_green", "gateway_light:gatenode_on_red",
        "gateway_light:gatenode_on_violet", "gateway_light:gatenode_on_cyan",
        "gateway_light:gatenode_on_orange", "gateway_light:gatenode_on_yellow",
        "gateway_light:gatenode_on_pink",
    },
	interval = 1,
	chance = 1,
	action = gateway_light.node_abm
})
