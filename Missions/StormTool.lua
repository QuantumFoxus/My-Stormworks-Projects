version = "01.02.2024"
-- g_savedata table that persists between game sessions
g_savedata={{},{{}},{{}}, false, 1} -- [1] - vehicles, spawned by command; [2] - all vehicles; [3] - players; [4] - off; [5] - tickrate
tickrate = 10
WhiteList = -- list for admins
{
 76561198198224295,
 76561198157163891,
 76561199026787846,
 76561198864097981,
}

BlackList = -- automate kick users from this list
{
	--76561198836002144
}

AuthBlackList = -- does not authorize users from this list
{
	--76561198836002144
}

AutoAuth = true
	
respawn_trigger = false
lastmoveid = -1
dist_to_players = {}
dist_easy = {}

glob_look_id = -1
vec_dist = 10
off = false

i = 0

function onTick(game_ticks)
local p_pos
local d_dist
if g_savedata[4] == false then
	for key, o in pairs(g_savedata[3]) do
		local look_id
		if o.peer_id ~= nil and o.ui == true or o.move == true and o.peer_id ~= nil then
			p_pos = server.getPlayerPos(o.peer_id)
			--server.setPopupScreen(0, 0, "Vehicle", true,"peer_id: " .. o.peer_id .." key: ".. key .. " move:" .. tostring(o.move), 0.85, 0)
			
			--if o.move == true then
			check_dist_player(o.peer_id)
			--sortt(dist_to_players[o.peer_id+1])
			local look_d
			if dist_to_players[o.peer_id+1][1] ~= nil and o.veh_id ~= nil then
				if dist_to_players[o.peer_id+1][2] ~= o.veh_id then 
						look_id = dist_to_players[o.peer_id+1][2]
						look_d = dist_to_players[o.peer_id+1][1]
					else
						look_id = dist_to_players[o.peer_id+1][2]
						look_d = dist_to_players[o.peer_id+1][1]
				end
				if look_d < 10 then
				
					local obj=getbyid(look_id)
					local pos=server.getVehiclePos(obj.vehicle_id)
					d_dist = matrix.distance(pos, p_pos)
					if o.move == nil then o.move = false end
					glob_look_id = obj.vehicle_id
					if o.ui then
						server.setPopupScreen(o.peer_id, 100, "Vehicle", o.ui,"id: " .. look_id .. "\nuser: " .. obj.peer_id .. "\ndist: " .. string.format("%.0f", d_dist) .. "\nMove_now: " .. tostring(o.is_move_now) .. "\nTicks delay: " .. game_ticks, 0.85, 0)
					end
				else
					glob_look_id = -1
					server.setPopupScreen(o.peer_id, 100, "Vehicle", o.ui,"", 0.85, 0)
					--server.removePopup(o.peer_id, 100)
				end
			end
			if o.timer == nil then
				o.timer = 0 
			end
			if o.timer < g_savedata[5] and o.move ~= nil and o.move == true and o.veh_id ~= nil then
				o.timer = o.timer + 1	
			elseif o.move ~= nil and o.move == true and o.veh_id ~= nil then
				o.timer = 0
				if o.is_move_now == nil then
					o.is_move_now = false
				end
				local x,y,z = matrix.position(p_pos)
				local out_matrix = matrix.translation(x,y-400,z)
				server.moveVehicle(o.veh_id, out_matrix)
				server.setVehicleBattery(o.veh_id, battery, 1)
				server.setVehicleKeypad(o.veh_id, "key", 101 + o.peer_id, 101 + o.peer_id)
				local DATA = server.getVehicleButton(o.veh_id, "phys_gun")
				if DATA ~= nil then
					o.is_move_now = DATA["on"]
				end
				if o.is_move_now == true and o.move_dist == nil and look_id ~= nil then 
					o.move_dist = d_dist
					o.move_id = look_id
				elseif o.is_move_now == false then
					o.move_dist = nil
				end
				
				if o.is_move_now and o.move_dist ~= nil and o.move_id ~= nil then
					local xl,yl,zl = server.getPlayerLookDirection(o.peer_id)
					local veh_p = server.getVehiclePos(o.move_id)
					local xv,yv,zv = matrix.position(veh_p)
					x = lerp(xv, x + xl * o.move_dist,  1)   
					y = lerp(yv, y + yl * o.move_dist,  1)  
					z = lerp(zv, z + zl * o.move_dist,  1)  
					local res_pos = matrix.translation(x,y,z)
					server.setVehicleInvulnerable(o.move_id, true)
					lastmoveid = o.move_id
					server.moveVehicle(o.move_id, res_pos)
				else
					server.setVehicleInvulnerable(lastmoveid, false)
				end
			end
		end
	
	end
end

end

function onPlayerJoin(steam_id, name, peer_id, admin, auth)
	
	for u = 1, #WhiteList, 1 do 
		if steam_id == WhiteList[u] then 
			server.announce("[ST]","Welcome, [admin] ".. name )
			server.addAdmin(peer_id)
			record_player(steam_id, name, peer_id, true, true)
			return
		end
	end
	for u = 1, #BlackList, 1 do 
		if steam_id == BlackList[u] then 
			server.announce("[ST]",name .. "tried to join server, but was banned...")
			server.banPlayer(peer_id)
			return
		end
	end
	
	if AutoAuth then 
		for u = 1, #AuthBlackList, 1 do 
			if steam_id == AuthBlackList[u] then 
				server.announce("[ST]","Hello, ".. name .. ", you don't have rights to authorize (~_~)" )
				record_player(steam_id, name, peer_id, false, false)
				return
			end
		end
		server.announce("[ST]","Hello, ".. name )
		server.addAuth(peer_id)
		record_player(steam_id, name, peer_id, false, true)
	end
	
end

function onPlayerLeave(steam_id, name, peer_id, admin, auth)
	server.announce("[ST]", name .. " left this party")
	for key,o in pairs(g_savedata[3]) do
		if o.peer_id == peer_id then
		o=nil
		return
		end
	end
end

function onCustomCommand(full_message, user_peer_id, is_admin, is_auth, command, one, two, three, four, five)
	com_low = string.lower(command)
	if one~=nil then
		one = string.lower(one)
	else
		one = 0
	end
	if two~=nil then
		two = string.lower(two)
	else
		two = 0
	end
	if three~=nil then
		three = string.lower(three)
	else
		three = 0
	end
	if four~=nil then
		four = string.lower(four)
	else
		four = 0
	end
	if five~=nil then
		five = string.lower(five)
	else
		five = 0
	end
	
	
	if com_low == "?hello" then
		server.announce("[ST]", "world")
		return
	end
	
	if com_low == "?help" then
		server.announce("[ST]", "HELP: version "..version .. ";\n[] - parameter\n {} - not necessary\n'' - fixed parameter", user_peer_id)
		server.announce("[ST]", "Command list:", user_peer_id)
		server.announce("[ST]", "?help - this page", user_peer_id)
		server.announce("[ST]", "?hello - World", user_peer_id)
		server.announce("[ST]", "?heal [id] - restore player HP", user_peer_id)
		server.announce("[ST]", "?revive [id] - revive player", user_peer_id)
		server.announce("[ST]", "?kill [id] - kill player", user_peer_id)
		server.announce("[ST]", "?spawn [name] - (?s) spawn vehicle by name from host saves", user_peer_id)
		server.announce("[ST]", "?clear [ 'all' | 'l' | 'last' | id ] - (?c) remove all vehicles or last spawned vehicle or vehicle by id", user_peer_id)
		server.announce("[ST]", "?teleport [ 'p' | 'player' ] [id] [id_target] - (?t) teleport one player to other player", user_peer_id)
		server.announce("[ST]", "?teleport [ 'c' | 'coordinate' ] [id] [x] [y] [z] - (?t) teleport player to coordinate", user_peer_id)
		server.announce("[ST]", "?move - change vehicle move mode for user (use a radio on last slot to move vehicles)", user_peer_id)
		server.announce("[ST]", "?respawn [id] - reload vehicle (you can use ?r and look on vehicle)", user_peer_id)
		server.announce("[ST]", "?flag [name] [state] - switch game setting flag on server", user_peer_id)
		server.announce("[ST]", "?ui - change ui mode for user", user_peer_id)
		server.announce("[ST]", "?script - switch script", user_peer_id)
		return
	end
	
	if (com_low == "?s" or com_low == "?spawn") and is_admin then
		local user_pos = server.getPlayerPos(user_peer_id)
		local xl, yl, zl = server.getPlayerLookDirection(user_peer_id)
		local posl = matrix.rotationToFaceXZ(xl, zl)
		local x,y,z = matrix.position(user_pos)
		local yt=y+7
		local xt=x
		local zt=z+20
		local xt,zt = rotate(xt , zt, x, z, math.deg(math.atan(xl,zl)))
		local pos_temp = matrix.translation(xt,yt,zt)
		local result_pos = matrix.multiply(pos_temp, posl)
		local rotate_matrix = matrix.rotationX(-math.rad(yl*90))
		local result_maxtrix = matrix.multiply(result_pos, rotate_matrix)
		g_savedata[1][#g_savedata[1]+1], is_suc = server.spawnVehicle(result_maxtrix, one)
		server.announce("[ST]","vehicle spawned, user: "..user_peer_id.." id: "..g_savedata[1][#g_savedata[1]].." name: ".. one)
		return
	end
	
	if (com_low == "?c" or com_low == "?clear") and is_admin then
		if one == "l" or one == "last" then
			for iii = 0, #g_savedata[1]-1, 1 do
				local VEHICLE_DATA, is_ss = server.getVehicleData(g_savedata[1][#g_savedata[1] - iii])
				--server.despawnVehicle(g_savedata[1][#g_savedata[1]], true)
				if is_ss == true then
					server.despawnVehicleGroup(VEHICLE_DATA["group_id"], true)
					server.announce("[ST]","last vehicle deleted, user: "..user_peer_id.." id: "..g_savedata[1][#g_savedata[1]])
					break
				end
			end
			g_savedata[1][#g_savedata[1]]=nil
			
		elseif one == "a" or one == "all" then
			for key,value in pairs(g_savedata[1]) do
				local VEHICLE_DATA2, is_ss2 = server.getVehicleData(value)
				--server.despawnVehicle(value, true)
				if is_ss2 == true then
					server.despawnVehicleGroup(VEHICLE_DATA2["group_id"], true)
				end
				
			end
			server.announce("[ST]","all vehicles deleted, user: "..user_peer_id)
		else
			if one == 0 and glob_look_id > 0 then
				one = glob_look_id
			end
			local VEHICLE_DATA2, is_success = server.getVehicleData(one)
			server.despawnVehicleGroup(VEHICLE_DATA2["group_id"], true)
			--local is_success = server.despawnVehicle(one, true)
			if is_success then 
			for key,value in pairs(g_savedata[1]) do
				if value==one then g_savedata[1][key]=nil end
			end
			server.announce("[ST]","vehicle deleted, user: " .. user_peer_id .. " id: " .. one)
			else
			server.announce("[ST]","vehicle NOT deleted, WRONG ID: " .. one)
			end
			
		end
		return
	end
	
	if (com_low == "?u" or com_low == "?unstack") and is_admin then
		if one == 0 then 
			one = glob_look_id
		end
		local res_mat = server.getVehiclePos(one)
		local x,y,z = matrix.position(res_mat)
		local yt = y + 10
		local xt = x
		local zt = z
		local res_pos = matrix.translation(xt,yt,zt)
		server.setVehicleInvulnerable(one, true)
		server.moveVehicle(one, res_pos)
		server.announce("[ST]","vehicle moved up", user_peer_id)
		server.setVehicleInvulnerable(one, false)
		return
	end

	if com_low == "?heal" and is_admin then
		if one~=nil then
			user_peer_id=tonumber(one)
		end
		local object_id, is_success = server.getPlayerCharacterID(user_peer_id)
		server.setCharacterData(object_id, 100, false, false)
		server.announce("[ST]", "Healed: " .. one, user_peer_id)
		return
		
	end
	
	if com_low == "?revive" and is_admin then
		if one~=nil then
			user_peer_id=tonumber(one)
		end
		local object_id, is_success = server.getPlayerCharacterID(user_peer_id)
		server.reviveCharacter(object_id)
		server.setCharacterData(object_id, 100, false, false)
		server.announce("[ST]", "Revived: " .. one, user_peer_id)
		return
		
	end
	
	if com_low == "?kill" and is_admin then
		if one~=nil then
			user_peer_id=tonumber(one)
		end
		local object_id, is_success = server.getPlayerCharacterID(user_peer_id)
		server.killCharacter(object_id)
		server.announce("[ST]", "Killed: " .. one, user_peer_id)
		return
		
	end
	
	if ( com_low == "?tp" or com_low == "?teleport" ) and is_admin then
		if one == "p" or one == "player" then
			if three~=nil then
				local user_pos = server.getPlayerPos(three)
				local is_success = server.setPlayerPos(two, user_pos)
				server.announce("[ST]", "Teleported: " .. two .. " to " .. three)
				return
			else
				local user_pos=server.getPlayerPos(two)
				local is_success = server.setPlayerPos(user_peer_id, user_pos)
				server.announce("[ST]", "Teleported: " .. user_peer_id .. " to " .. two)
				return
			end
		end
		if one == "c" or one == "coordinate" then
			local user_pos = matrix.translation(three,four,five)
			local is_success = server.setPlayerPos(two, user_pos)
				server.announce("[ST]", "Teleported: " .. two .. " to coordinates: " .. three .. "; " .. four .. "; " .. five)
		end
	end
	
	if com_low == "?move" and is_admin then
		for key, o in pairs(g_savedata[3]) do
			if o.peer_id == user_peer_id then
				if o.move == false and one == 0 or one == on then
					o.move = true
					local object_id, is_success = server.getPlayerCharacterID(user_peer_id)
					server.setCharacterItem(object_id, 9, 19, false, 101 + user_peer_id, 100)
					local transform_matrix = server.getPlayerPos(user_peer_id)
					local x,y,z = matrix.position(transform_matrix)
					local pf = matrix.translation(x,y+10,z)
					local addon_index = server.getAddonIndex()
					local veh_id = server.spawnAddonVehicle(pf, addon_index, 4)
					o.veh_id = veh_id
					server.announce("[ST]", "Enable move mode for " .. user_peer_id, user_peer_id)
					--phys_gun
				elseif o.move == true and one == 0 or one == off then
					o.move = false
					local object_id, is_success = server.getPlayerCharacterID(user_peer_id)
					server.setCharacterItem(object_id, 9, 0, false, 0, 0)
					if o.veh_id ~= nil then 
						server.despawnVehicle(o.veh_id, true)
					end
					server.announce("[ST]", "Disable move mode for " .. user_peer_id, user_peer_id)
				end
				break
			end
			
		end
		
	end
	
	if com_low == "?ui" then
		if one == "true" or one == "on" then
			for key, o in pairs(g_savedata[3]) do
				o.ui = true
				server.announce("[ST]", "ui on",user_peer_id)
				return
			end
		elseif one == "false" or one == "off" then
			for key, o in pairs(g_savedata[3]) do
				o.ui = false
				server.announce("[ST]", "ui off",user_peer_id)
				return
			end
		elseif one == 0 then 
			for key, o in pairs(g_savedata[3]) do
				if o.ui == false then
					o.ui = true
					server.announce("[ST]", "ui on",user_peer_id)
					return
				else
					o.ui = false
					server.announce("[ST]", "ui off",user_peer_id)
					return
				end
			end
		end
	end
	
	if com_low == "?reg" and is_admin then
		for key, o in pairs(g_savedata[3]) do
			if one == o.peer_id then
				return
			end
		end
		local name = server.getPlayerName(one)
		record_player(-1, name, tonumber(one), two, three)
		
	end
	
	if com_low == "?cs" and is_admin then
		if one == 0 then
			for key, o in pairs(g_savedata[3]) do
				server.removePopup(o.peer_id, 100)
			end
			server.announce("[ST]", "cleared UI ", user_peer_id)
		
		else
			for key, o in pairs(g_savedata[3]) do
				server.removePopup(o.peer_id, one)
			end
			server.announce("[ST]", "cleared UI: ".. one, user_peer_id)
		end
	end
	
	if com_low == "?script" and is_admin then
		if g_savedata[4] == true then g_savedata[4] = false server.announce("[ST]", "Enabled onTick", user_peer_id)
		else g_savedata[4] = true server.announce("[ST]", "Disabled onTick", user_peer_id) end
	end

	if com_low == "?tickrate" and is_admin then
		if tonumber(one) > -1 then
			g_savedata[5] = tonumber(one)
			server.announce("[ST]", "Tickrate set to " .. one, user_peer_id)
		else
			server.announce("[ST]", "Wrong number for tickrate: " .. one, user_peer_id)
		end
	end
	
	if com_low == "?respawn" and is_admin or com_low == "?r" and is_admin then
		if one == 0 and glob_look_id > 0 then
			one = glob_look_id
		end
		local is_s = server.resetVehicleState(one)
		if is_s then
			server.announce("[ST]", "Respawned: " .. one, user_peer_id)
		else
			server.announce("[ST]", "Wrong id: " .. one, user_peer_id)
		end
	end
	
	if com_low == "?flag" and is_admin then
	local twof
	if two == "true" then 
		twof = true
	elseif two == "false" then
		twof = false
	else 
		server.announce("[ST]", "Wrong state: ".. two)
		return
	end
	server.setGameSetting(one, twof)
	server.announce("[ST]", "Flag ".. one .." changed to " .. two)
	end 
	
end



function onCreate(is_world_create)
	server.announce("[ST]", "StormTool loaded, version: "..version)
	if is_world_create == true then 
	server.setGameSetting("infinite_batteries", true)
	server.setGameSetting("override_weather", true)
	end
	server.setGameSetting("settings_menu", true)
	server.setWeather(0, 0, 0)
	local PLAYER_LIST = server.getPlayers()
	for key, o in pairs(PLAYER_LIST) do
		record_player(o.steam_id, o.name, o.id, o.admin, o.auth)
	end
	
end

function onPlayerDie(steam_id, name, peer_id, is_admin, is_auth)
	if peer_id == 0 and server.getGameSettings().respawning == false then
		server.setGameSetting("respawning", true)
		respawn_trigger=true
	end
end

function onPlayerRespawn(peer_id)
	if peer_id == 0 and respawn_trigger then
		server.setGameSetting("respawning", false)
		respawn_trigger=false
	end
end

function onVehicleSpawn(vehicle_id, peer_id, x, y, z, group_cost, group_id)
	local itt = 1
	if g_savedata[2][1].vehicle_id ~= nil then 
		itt = #g_savedata[2]+1
	end
	g_savedata[2][#g_savedata[2]+1] = {}
	g_savedata[2][#g_savedata[2]].vehicle_id = vehicle_id
	g_savedata[2][#g_savedata[2]].peer_id = peer_id
	g_savedata[2][#g_savedata[2]].pos = matrix.translation(x,y,z)
	g_savedata[2][#g_savedata[2]].group_cost = group_cost
	g_savedata[2][#g_savedata[2]].group_id = group_id
end

function onVehicleDespawn(vehicle_id, peer_id)
	for key,o in pairs(g_savedata[2]) do
		if o.vehicle_id == vehicle_id then 
			o=nil
		end
	end
end

function record_player(steam_id, name, peer_id, admin, auth)
	for key,o in pairs(g_savedata[3]) do
		if o.peer_id == peer_id then 
		return
		end
	end
	local n=1
	if g_savedata[3][1].peer_id ~= nil then
	n=#g_savedata[3]+1
	end
	
	g_savedata[3][n] = {}
	g_savedata[3][n].steam_id = steam_id
	g_savedata[3][n].name = name
	g_savedata[3][n].peer_id = peer_id
	g_savedata[3][n].admin = admin
	g_savedata[3][n].auth = auth
	g_savedata[3][n].move = false
	if g_savedata[3][n].ui == nil then
		g_savedata[3][n].ui = true
	end
	--server.announce("[ST]", "registered " .. peer_id)
end

function check_dist_player(id)
	local player_pos, is_succs = server.getPlayerPos(id)
	dist_to_players[id+1] = {}
	dist_easy[id+1] = {}
	
	if is_succs then
		local x,y,z = matrix.position(player_pos)
			local xl, yl, zl = server.getPlayerLookDirection(id)
			xl=xl*vec_dist+x
			yl=yl*vec_dist+y
			zl=zl*vec_dist+z
		dist_to_players[id+1] = {1000,-1}
		for key,o in pairs(g_savedata[2]) do
			--o.dist = matrix.distance(player_pos, o)
			local v_pos, is_suc = server.getVehiclePos(o.vehicle_id)
			if is_suc then
				local xv,yv,zv = matrix.position(v_pos)
					-- dist_to_players[id+1] = {} 
					local tt = distancePointToLine(xv, yv, zv, x, y, z, xl, yl, zl)
					if tt < dist_to_players[id+1][1] then 
						dist_to_players[id+1] = {tt, o.vehicle_id}
					end
				--matrix.distance(player_pos, o)
			else
					-- dist_to_players[id+1] = {} 
				--dist_to_players[id+1][key] = {10000,-1}
			end
		end
	end
end

function rotate(x , y, x_c, y_c, angle)
        local xt = x - x_c
        local yt = y - y_c
        local r = math.rad(angle)
        local cs=math.cos(r)
        local sn=math.sin(r)
        return xt * cs + yt * sn + x_c, yt * cs - xt * sn + y_c
end

function height_to_vec(x0, y0, vx1, vy1, vx2, vy2)
	local vec = math.abs( (vy2 - vy1) * x0 - (vx2 - vx1) * y0 + vx2 * vy1 - vy2 * vx1)
	local scalar = math.sqrt( (vy2 - vy1) ^ 2 + (vx2 - vx1) ^ 2 )
	return vec/scalar
end

function sortt(array)
	table.sort( array, function( a, b ) return a[1] < b[1] end )
end

function distancePointToLine(x, y, z, x1, y1, z1, x2, y2, z2)
    local AB = {x2 - x1, y2 - y1, z2 - z1}
    local AP = {x - x1, y - y1, z - z1}
	local BP = {x - x2, y - y2, z - z2}
    
    local lengthAB = math.sqrt(AB[1] * AB[1] + AB[2] * AB[2] + AB[3] * AB[3])
	local lengthAP = math.sqrt(AP[1] * AP[1] + AP[2] * AP[2] + AP[3] * AP[3])
	local lengthBP = math.sqrt(BP[1] * BP[1] + BP[2] * BP[2] + BP[3] * BP[3])
    if lengthAP < lengthBP and lengthBP > vec_dist then return 1000 end
    local dotProduct = (AP[1] * AB[1] + AP[2] * AB[2] + AP[3] * AB[3]) / lengthAB
    
    local projection = {x1 + dotProduct * AB[1] / lengthAB, y1 + dotProduct * AB[2] / lengthAB, z1 + dotProduct * AB[3] / lengthAB}
    
    local distance = math.sqrt((x - projection[1])^2 + (y - projection[2])^2 + (z - projection[3])^2)
 
    return distance
end

function getbyid(id)
	for key,o in pairs(g_savedata[2]) do
		if o.vehicle_id == id then 
			return o
		end
	end
end

function lerp(a, b, t)
  return a + (b-a) * t
end