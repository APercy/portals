-- Minetest 0.4.5 : stargate

--data tables definitions
gateway_light={}
gateway_light_network = {}

modpath=minetest.get_modpath("gateway_light")
dofile(modpath.."/gateway_gui.lua")
dofile(modpath.."/gate_defs.lua")
