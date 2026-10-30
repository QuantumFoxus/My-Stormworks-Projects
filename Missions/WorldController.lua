g_savedata = {}
g_savedata.vehiclesID = {}
g_savedata.playersUI = {}
users_look = {}
distToUI = 300
fovToUI = 10
respawn_trigger = false
autoAuth = true
last = -1
script = true
function onTick(game_ticks)
    if not script then
        return
    end
    for index, user_id in pairs(g_savedata.playersUI) do
        local user_pos = server.getPlayerPos(user_id)
        local x_user, y_user, z_user = matrix.position(user_pos)
        local x_look, y_look, z_look = server.getPlayerLookDirection(user_id)
        for index2, group_id in pairs(g_savedata.vehiclesID) do
            local veh_pos = server.getVehiclePos(index2, 0, 0, 0)
            local x_veh, y_veh, z_veh = matrix.position(veh_pos)
            dist = matrix.distance(user_pos, veh_pos)
            if dist < distToUI then
                -- Calculate the vector from the player to the vehicle
                local dx = x_veh - x_user
                local dy = y_veh - y_user
                local dz = z_veh - z_user
                local mag_look = math.sqrt(x_look^2 + y_look^2 + z_look^2)
                local mag_to_vehicle = math.sqrt(dx^2 + dy^2 + dz^2)
                local dot_product = (x_look * dx + y_look * dy + z_look * dz)
                local angle = math.acos(dot_product / (mag_look * mag_to_vehicle)) * (180 / math.pi)
                
                if angle <= fovToUI then
                    local VEHICLE_DATA, is_success = server.getVehicleData(index2)
                    if is_success then
                        users_look[user_id] = index2
                        server.setPopupScreen(user_id, user_id, "", true, "Vehicle Name: " .. VEHICLE_DATA.name .. "\n" .. "Vehicle ID: " .. index2, 0.85, 0.7)
                        return
                    end
                end
            end
        end
        users_look[user_id] = nil
        server.setPopupScreen(user_id, user_id, "", false, "", 0.85, 0.7)
    end
end

function onPlayerJoin(steam_id, name, peer_id, admin, auth)
	server.announce("[Server]", name .. " joined the game")
    if autoAuth == true then
        server.addAuth(peer_id)
    end
end

function onPlayerLeave(steam_id, name, peer_id, admin, auth)
    for index, value in ipairs(g_savedata.playersUI) do
        if value == peer_id then
            table.remove(g_savedata.playersUI, index)
        end
    end
	server.announce("[Server]", name .. " left the game")
end

function onCustomCommand(full_message, user_peer_id, is_admin, is_auth, command, one, two, three, four, five)
    local commandl
    local onel
    local twol
    local threel
    local fourl
    local fivel
    if command ~= nil then
        commandl = string.lower(command)
    end
    if one ~= nil then
        onel = string.lower(one)
    end
    if two ~= nil then
        twol = string.lower(two)
    end
    if three ~= nil then
        threel = string.lower(three)
    end
    if four ~= nil then
        fourl = string.lower(four)
    end
    if five ~= nil then
        fivel = string.lower(five)
    end
    
	if commandl == "?hello" then
		server.announce("[Server]", "world", user_peer_id)
	end
    if commandl == "?ui" then
        local flag = false
        for index, value in ipairs(g_savedata.playersUI) do
            if value == user_peer_id then
                flag = true
            end
        end
        if not flag then
            table.insert(g_savedata.playersUI, user_peer_id)
            server.announce("[Server]", "UI activated", user_peer_id)
            return
        else
            for index, value in ipairs(g_savedata.playersUI) do
                if value == user_peer_id then
                    table.remove(g_savedata.playersUI, index)
                    server.removePopup(user_peer_id, user_peer_id)
                    server.announce("[Server]", "UI deactivated", user_peer_id)
                    return
                end
            end
        end
    end
    if commandl == "?r" then
        if  not is_admin then
            server.announce("[Server]", "You are not an admin", user_peer_id)
            return
        end
        if onel == nil and users_look[user_peer_id] ~= nil then
            local vehicle_id = users_look[user_peer_id]
            local is_success = server.resetVehicleState(vehicle_id)
            if is_success then
                server.announce("[Server]", "Vehicle reset successfully", user_peer_id)
            else
                server.announce("[Server]", "Failed to reset vehicle", user_peer_id)
            end
        else 
            local vehicle_id = tonumber(onel)
            if vehicle_id == nil then
                server.announce("[Server]", "Invalid vehicle ID", user_peer_id)
                return
            end
            local is_success = server.resetVehicleState(vehicle_id)
            if is_success then
                server.announce("[Server]", "Vehicle reset successfully", user_peer_id)
            else
                server.announce("[Server]", "Failed to reset vehicle", user_peer_id)
            end
        end
    end
    if commandl == "?c" then 
        if  not is_admin then
            server.announce("[Server]", "You are not an admin", user_peer_id)
            return
        end
        if onel == nil and users_look[user_peer_id] ~= nil then
            local vehicle_id = users_look[user_peer_id]
            local is_success = server.despawnVehicle(vehicle_id, true)
            if is_success then
                g_savedata.vehiclesID[vehicle_id] = nil
                server.announce("[Server]", "Vehicle deleted", user_peer_id)
            else
                server.announce("[Server]", "Failed to clear vehicle", user_peer_id)
            end
        elseif onel == "l" and last ~= -1 then
            local is_success = server.despawnVehicle(last, true)
            if is_success then
                g_savedata.vehiclesID[last] = nil
                server.announce("[Server]", "Vehicle deleted", user_peer_id)
            else
                server.announce("[Server]", "Failed to clear vehicle", user_peer_id)
            end
        else 
            local vehicle_id = tonumber(onel)
            if vehicle_id == nil then
                server.announce("[Server]", "Invalid vehicle ID", user_peer_id)
                return
            end
            local is_success = server.despawnVehicle(vehicle_id, true)
            
            if is_success then
                g_savedata.vehiclesID[vehicle_id] = nil
                server.announce("[Server]", "Vehicle deleted", user_peer_id)
            else
                server.announce("[Server]", "Failed to delete vehicle", user_peer_id)
            end
        end
    end
    if commandl == "?s" then
        if not is_admin then
            server.announce("[Server]", "You are not an admin", user_peer_id)
            return
        end
        local veh_name = one
        if twol ~= nil then
            veh_name = veh_name .. " " .. two
        end
        if threel ~= nil then
            veh_name = veh_name .. " " .. three
        end
        if fourl ~= nil then
            veh_name = veh_name .. " " .. four
        end
        if fivel ~= nil then
            veh_name = veh_name .. " " .. five
        end
        local user_pos = server.getPlayerPos(user_peer_id)
		local xl, yl, zl = server.getPlayerLookDirection(user_peer_id)
		local posl = matrix.rotationToFaceXZ(xl, zl)
		local x,y,z = matrix.position(user_pos)
		local yt=y+7
		local xt=x
		local zt=z+20
		xt,zt = rotate(xt , zt, x, z, math.deg(math.atan(xl,zl)))
		local pos_temp = matrix.translation(xt,yt,zt)
		local result_pos = matrix.multiply(pos_temp, posl)
		local rotate_matrix = matrix.rotationX(-math.rad(yl*90))
		local result_maxtrix = matrix.multiply(result_pos, rotate_matrix)
		local vid, is_suc = server.spawnVehicle(result_maxtrix, veh_name)
        if is_suc then
            last = vid
            g_savedata.vehiclesID[vid] = -1
            server.announce("[Server]", "Vehicle spawned successfully, id:".. vid, user_peer_id)
        else
            server.announce("[Server]", "Failed to spawn vehicle", user_peer_id)
        end
    end
    if commandl == "?u" then
        if not is_admin then
            server.announce("[Server]", "You are not an admin", user_peer_id)
            return
        end
        if onel == nil and users_look[user_peer_id] ~= nil then
            local vehicle_id = users_look[user_peer_id]
            local pos = server.getVehiclePos(vehicle_id, 0, 0, 0)
            local x, y, z = matrix.position(pos)
            y = y + 5
            local pos_temp = matrix.translation(x, y, z)
            server.setVehiclePos(vehicle_id, pos_temp)
            server.announce("[Server]", "Vehicle unstacked, id: " .. vehicle_id, user_peer_id)
        else
            local vehicle_id = tonumber(onel)
            if vehicle_id == nil then
                server.announce("[Server]", "Invalid vehicle ID", user_peer_id)
                return
            end
            local pos = server.getVehiclePos(vehicle_id, 0, 0, 0)
            local x, y, z = matrix.position(pos)
            y = y + 5
            local pos_temp = matrix.translation(x, y, z)
            server.setVehiclePos(vehicle_id, pos_temp)
            server.announce("[Server]", "Vehicle unstacked, id: " .. vehicle_id, user_peer_id)
        end   
    end
    if commandl == "?a" then
        if not is_admin then
            server.announce("[Server]", "You are not an admin", user_peer_id)
            return
        end
        autoAuth = not autoAuth
        if autoAuth then
            server.announce("[Server]", "Auto auth enabled", user_peer_id)
        else
            server.announce("[Server]", "Auto auth disabled", user_peer_id)
        end
    end
    if commandl == "?kick" then
        if not is_admin then
            server.announce("[Server]", "You are not an admin", user_peer_id)
            return
        end
        if onel == nil then
            server.announce("[Server]", "Invalid player ID: ".. onel, user_peer_id)
            return
        end
        server.kickPlayer(onel)
    end
    if commandl == "?script" then
        if not is_admin then
            server.announce("[Server]", "You are not an admin", user_peer_id)
            return
        end
        script = not script
        if script == false then
            server.announce("[Server]", "Script disabled", user_peer_id)
        elseif script == true then
            server.announce("[Server]", "Script enabled", user_peer_id)
        end
    end
    if commandl == "?help" then
        local help_message = [[
Available commands:
?hello - Responds with "world".
?ui - Toggles the UI for the player.
?r [vehicle_id] - Resets the state of a vehicle (admin only).
?c [vehicle_id] - Deletes a vehicle (admin only).
?s [vehicle_name] - Spawns a vehicle with the given name (admin only).
?a - Toggles auto-authentication for players (admin only).
?help - Displays this help message.
]]
        server.announce("[Server]", help_message, user_peer_id)
    end
end

function onGroupSpawn(group_id, peer_id, x, y, z, group_cost)
    for index, value in pairs(server.getVehicleGroup(group_id)) do
        g_savedata.vehiclesID[value] = group_id
    end
end

function onVehicleDespawn(vehicle_id, peer_id)
    g_savedata.vehiclesID[vehicle_id] = nil
end

function onCreate()
    server.announce("[Server]", "WorldController script loaded")
    server.setGameSetting("settings_menu", true)
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

function rotate(x , y, x_c, y_c, angle)
    local xt = x - x_c
    local yt = y - y_c
    local r = math.rad(angle)
    local cs=math.cos(r)
    local sn=math.sin(r)
    return xt * cs + yt * sn + x_c, yt * cs - xt * sn + y_c
end