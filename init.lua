local last_positions = {}

local function restore_player_position(a_name)
	if a_name then
		local temp_position = last_positions[a_name]
		if temp_position then
			local temp_player = core.get_player_by_name(a_name)
			temp_player:setpos(temp_position)
			temp_player:setacceleration({x=0, y=0, z=0})
			last_positions[a_name] = nil
		end
	end
end

core.register_on_punchnode(function(a_position, a_node, a_puncher, a_pointed_thing)
	if a_puncher then
		local temp_player_name = a_puncher:get_player_name()
		if temp_player_name then
			if core.is_protected(a_position, temp_player_name) then
				if last_positions[temp_player_name]==nil then
					last_positions[temp_player_name] = a_puncher:getpos()
				end
			else
				last_positions[temp_player_name] = nil
			end
		end
	end
end)

local next = next

core.register_globalstep(function(a_delta_time)
	if next(last_positions)~=nil then
		local temp_players = core.get_connected_players()
		for _, temp_player in ipairs(temp_players) do
			local temp_player_name = temp_player:get_player_name()
			if not temp_player:get_player_control().LMB then
				last_positions[temp_player_name] = nil
			end
		end
	end
end)

local is_protected = function()
	local temp_is_protected = core.is_protected

	core.is_protected = function(a_position, a_digger_name, a_only_owner)
		local result = temp_is_protected(a_position, a_digger_name, a_only_owner)
		if result and a_digger_name then
			restore_player_position(a_digger_name)
		end
		return result
	end

	print("[MOD] repel setup!")
end

local setup = true

--wait until other mods are loaded to ensure override works with other protection mods!
if core.register_on_mods_loaded then
	core.register_on_mods_loaded(is_protected)
else -- for pre Minetest 5, setup on first join player
	core.register_on_prejoinplayer(function()
		if setup then
			setup = nil
			is_protected()
		end
	end)
end
