g_savedata = {}
g_savedata.teams = {red={},blue={},sp={}}
g_savedata.spawns = {red={},blue={}}
game_started = false
tick_counter = 0
g_savedata.redvehicle = nil
g_savedata.bluevehicle = nil
function onTick(game_ticks)
    if game_started then
        tick_counter = tick_counter + 1
        if tick_counter >= 1800 then --1800
            game_started = false
            tick_counter = 0


            for _, user_peer_id in ipairs(g_savedata.teams.red) do
                home(user_peer_id)
            end
            for _, user_peer_id in ipairs(g_savedata.teams.blue) do
                home(user_peer_id)
            end

            server.announce("[Server]", "Game started!")
        end
    end
end

function onCreate()
    server.announce("[Server]", "Event script loaded!")
    server.announce("[Server]", "Use ?help for a list of commands.")
    clearPopups(-1)
    drawPopups()
end

function onPlayerJoin(steam_id, name, peer_id, admin, auth)
	server.announce("[Server]", name .. " joined the game")
end

function onPlayerLeave(steam_id, name, peer_id, admin, auth)
    for _, value in ipairs(g_savedata.teams.red) do
        if value == peer_id then
            table.remove(g_savedata.teams.red, _)
            server.announce("[Server]", name .. "[" .. peer_id .. "]" .. " left the red team")
            return
        end
    end
    for _, value in ipairs(g_savedata.teams.blue) do
        if value == peer_id then
            table.remove(g_savedata.teams.blue, _)
            server.announce("[Server]", name .. "[" .. peer_id .. "]" .. " left the blue team")
            return
        end
    end
    for _, value in ipairs(g_savedata.teams.sp) do
        if value == peer_id then
            table.remove(g_savedata.teams.sp, _)
            server.announce("[Server]", name .. "[" .. peer_id .. "]" .. " left the spectator team")
            return
        end
    end
    server.announce("[Server]", name .. " left the game")
end

function onCustomCommand(full_message, user_peer_id, is_admin, is_auth, command, one, two, three, four, five)
    if command == "?help" then
        local help_message = [[
Available commands:
?join <red/blue/spectator/s> - Join a team (red, blue, or spectator).
?leave - Leave your current team.
?teams - Show the list of players in each team.
?setspawn <red/blue> - Set the spawn point for a team (admin only).
?reset - Reset all team spawn points (admin only).
?home - Teleport to your team's spawn point.
?start - Start the game (spawns vehicles and starts the timer).
?help - Show this help message.
        ]]
        server.announce("[Server]", help_message, user_peer_id)
    end

	if (command == "?join") and one then
		local team = string.lower(one)
        for _, value in ipairs(g_savedata.teams.red) do
            if value == user_peer_id then
                server.announce("[Server]", "You are already in a team!", user_peer_id)
                return
            end
        end
        for _, value in ipairs(g_savedata.teams.blue) do
            if value == user_peer_id then
                server.announce("[Server]", "You are already in a team!", user_peer_id)
                return
            end
        end
        for _, value in ipairs(g_savedata.teams.sp) do
            if value == user_peer_id then
                server.announce("[Server]", "You are already in a team!", user_peer_id)
                return
            end
        end
        name = getUserbyId(user_peer_id).name
        if team == "red" then 
            table.insert(g_savedata.teams.red, user_peer_id)    
            drawPopups()
            server.announce("[Server]", name .. "[" .. user_peer_id .. "]" .. " joined the red team!")
        elseif team == "blue" then
            table.insert(g_savedata.teams.blue, user_peer_id)
            drawPopups()
            server.announce("[Server]", name .. "[" .. user_peer_id .. "]" .." joined the blue team!")
        elseif team == "spectator" or team == "s" then
            table.insert(g_savedata.teams.sp, user_peer_id)
            drawPopups()
            server.announce("[Server]", name .. "[" .. user_peer_id .. "]" .." joined as a spectator!")
        else
            server.announce("[Server]", "Invalid team name!", user_peer_id)
        end
	end
    if (command == "?leave") then
        clearPopups(user_peer_id)
        for _, value in ipairs(g_savedata.teams.red) do
            if value == user_peer_id then
                table.remove(g_savedata.teams.red, _)
                server.announce("[Server]", "You left the red team!")
                drawPopups()
                return
            end
        end
        for _, value in ipairs(g_savedata.teams.blue) do
            if value == user_peer_id then
                table.remove(g_savedata.teams.blue, _)
                server.announce("[Server]", "You left the blue team!")
                drawPopups()
                return
            end
        end
        for _, value in ipairs(g_savedata.teams.sp) do
            if value == user_peer_id then
                table.remove(g_savedata.teams.sp, _)
                server.announce("[Server]", "You left the spectator team!")
                drawPopups()
                return
            end
        end
        server.announce("[Server]", "You are not in a team!")
        drawPopups()
    end
    if (command == "?teams") then
        local red = "Red team: "
        local blue = "Blue team: "
        for _, value in ipairs(g_savedata.teams.red) do
            red = red .. getUserbyId(value).name .. "[" .. value .. "]" .. ", "
        end
        for _, value in ipairs(g_savedata.teams.blue) do
            blue = blue .. getUserbyId(value).name .. "[" .. value .. "]" .. ", "
        end
        server.announce("[Server]", red)
        server.announce("[Server]", blue)
    end
    if command == "?setspawn" and is_admin then
        local spawnCoords = server.getPlayerPos(user_peer_id)
        if string.lower(one) == "red" then
            g_savedata.spawns.red = spawnCoords

            local x,y,z  = matrix.position(spawnCoords)
            server.announce("[Server]", "Red spawn set to: " .. x .. ", " .. y .. ", " .. z, user_peer_id)
        elseif string.lower(one) == "blue" then
            g_savedata.spawns.blue = spawnCoords

            local x,y,z  = matrix.position(spawnCoords)
            server.announce("[Server]", "Blue spawn set to: " .. x .. ", " .. y .. ", " .. z, user_peer_id)
        else
            server.announce("[Server]", "Invalid team name!", user_peer_id)
        end
    end
    if command == "?reset" and is_admin then
            g_savedata.spawns.red = nil
            g_savedata.spawns.blue = nil
            server.announce("[Server]", "All spawn points have been reset!", user_peer_id)
    end
    if command == "?home" then
        home(user_peer_id)
        
    end
    if command == "?start" then
        if g_savedata.spawns.red and g_savedata.spawns.blue then
            g_savedata.bluevehicle = server.spawnVehicle(g_savedata.spawns.blue, "blue")
            g_savedata.redvehicle = server.spawnVehicle(g_savedata.spawns.red, "red")
            
            server.announce("[Server]", "Vehicles spawning...")
            drawMapObjects()
            game_started = true
            tick_counter = 0
        else
            server.announce("[Server]", "spawns are not set for both teams!", user_peer_id)
        end
    end
end

function home(user_peer_id)
    local team = nil
        for _, value in ipairs(g_savedata.teams.red) do
            if value == user_peer_id then
                team = "red"
                break
            end
        end
        if not team then
            for _, value in ipairs(g_savedata.teams.blue) do
                if value == user_peer_id then
                    team = "blue"
                    break
                end
            end
        end
        if team then
            local v = team == "blue" and g_savedata.bluevehicle or team == "red" and g_savedata.redvehicle or nil
            if v then
                local pos = server.getVehiclePos(v, 0, 0, 0)
                local x,y,z = matrix.position(pos)
                y= y + 2
                pos = matrix.translation(x,y,z)
                server.setPlayerPos(user_peer_id, pos)
                server.announce("[Server]", "You have been teleported home!", user_peer_id)
                return
            end
        else
            server.announce("[Server]", "No vehicles found for your team!", user_peer_id)
        end
end

function clearPopups(user_peer_id)
    server.removePopup(user_peer_id, 1)
    server.removePopup(user_peer_id, 2)
    server.removePopup(user_peer_id, 3)
    server.removeMapObject(user_peer_id, 4)
    server.removeMapObject(user_peer_id, 5)
    server.removeMapObject(user_peer_id, 6)
    server.removeMapObject(user_peer_id, 7)
end
function drawPopups()
    redteam = "RED\n"
    blueteam = "BLUE\n"
    specteam = "SPECTATORS\n"
    for _, value in ipairs(g_savedata.teams.red) do
        redteam = redteam .. server.getPlayerName(value) .. "[" .. math.floor(value) .. "]" .. "\n"
    end
    for _, value in ipairs(g_savedata.teams.blue) do
        blueteam = blueteam .. server.getPlayerName(value) .. "[" .. math.floor(value) .. "]" .. "\n"
    end
    for _, value in ipairs(g_savedata.teams.sp) do
        specteam = specteam .. server.getPlayerName(value) .. "[" .. math.floor(value) .. "]" .. "\n"
    end
    server.setPopupScreen(-1, 1, "RED", true, redteam, -0.9, 0.9)
    server.setPopupScreen(-1, 2, "BLUE", true, blueteam, 0.9, 0.9)
    server.setPopupScreen(-1, 3, "SPECTATOR", true, specteam, 0, 0.9)
    drawMapObjects()
end
function drawMapObjects()
    if g_savedata.redvehicle and g_savedata.bluevehicle then
        local red_pos = server.getVehiclePos(g_savedata.redvehicle, 0, 0, 0)
        local blue_pos = server.getVehiclePos(g_savedata.bluevehicle, 0, 0, 0)
        local xr,yr,zr = matrix.position(red_pos)
        local xb,yb,zb = matrix.position(blue_pos)
        server.removeMapObject(-1, 4)
        server.removeMapObject(-1, 5)
        server.removeMapObject(-1, 6)
        server.removeMapObject(-1, 7)
        for _, user_peer_id in ipairs(g_savedata.teams.red) do
            server.addMapObject(user_peer_id, 4, 1, 19, 0, 0, 0, 0, g_savedata.redvehicle, nil, "Carrier", 0, "",0,255,0,255)
        end
        for _, user_peer_id in ipairs(g_savedata.teams.blue) do
            server.addMapObject(user_peer_id, 5, 1, 19, 0, 0, 0, 0, g_savedata.bluevehicle, nil, "Carrier", 0, "",0,255,0,255)
        end
        for _, user_peer_id in ipairs(g_savedata.teams.sp) do
            server.addMapObject(user_peer_id, 6, 1, 19, 0, 0, 0, 0, g_savedata.redvehicle, nil, "RED Carrier", 0, "",255,0,0,255)
            server.addMapObject(user_peer_id, 7, 1, 19, 0, 0, 0, 0, g_savedata.bluevehicle, nil, "BLUE Carrier", 0, "",0,0,255,255)
        end
    end
end
function getUserbyId(id)
    players = server.getPlayers()
    for _, value in ipairs(players) do
        if value.id == id then
            return value
        end
    end
end