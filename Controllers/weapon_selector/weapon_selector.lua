ign=input.getNumber
osn=output.setNumber
igb=input.getBool
osb=output.setBool
launch_types = {"AAM ","TRPD","AGM ","BOMB"}
not_launch_types = {"GUN "}
selected_type = 1
selected_pylons = {}
is_ini = true
fire = false
function onTick()
	ini()
	check_pylons()
	buttons()
	
	for i = 1,32 do
		osb(i,false)
	end
	
	
	if selected_type > #getkeys(weapons) then
		selected_type = 1
	end
	
	local is_launch = true
	for key,val in pairs(not_launch_types) do
		if getkeys(weapons)[selected_type] == val then
			is_launch = false
		end
	end
	selected_pylons = {}
    osn(32,#getkeys(weapons))
    osn(30,selected_type)
	if #getkeys(weapons) > 0 then
		if is_launch then
            osn(31,1)
		    if #getkeys(weapons[getkeys(weapons)[selected_type]])%2 == 0 then
		        table.insert(selected_pylons, weapons[getkeys(weapons)[selected_type]][1].pylon)
		    else
		        table.insert(selected_pylons, weapons[getkeys(weapons)[selected_type]][#weapons[getkeys(weapons)[selected_type]]].pylon)
		    end
		    osb(selected_pylons[1],fire)
		    osb(32,true) -- launch flag
		else
            osn(31,0)
			for key,val in pairs(weapons[getkeys(weapons)[selected_type]]) do
				table.insert(selected_pylons, val.pylon)
				osb(val.pylon,igb(3))
			end
            osb(32,false) -- launch flag
		end
	end
end
function onDraw()
	w,h=screen.getWidth(),screen.getHeight()
	i=0
	for key, val in pairs(weapons) do
    local statustoscreen = ""
    local is_launchs = true
        for key2,val2 in pairs(not_launch_types) do
            if key == val2 then
                is_launchs = false
            end
        end
        if is_launchs==false then
            local ammo = 0
            for key2, val2 in pairs(val) do
                ammo = ammo + val2.status
            end
            statustoscreen = ammo
        end
        --val[1].status ~= 0 and math.floor(val[1].status) or ""
		if key == getkeys(weapons)[selected_type] then
			screen.drawText(1,i*7+2,key.." "..#val.." "..statustoscreen.. " <")
		else
			screen.drawText(1,i*7+2,key.." "..#val.." "..statustoscreen)
		end
	i=i+1
	end
    for i = 1,#getkeys(weapons) do
    	screen.drawText(1,h*0.6,#getkeys(weapons))
	end
end

function ini()
	if is_ini then
		types = concatArray(launch_types,not_launch_types)
	end
end

btns={}
function buttons()
	if igb(2) and igb(2)~= btns[2] then
        if selected_type+1<=#getkeys(weapons) then
            selected_type = selected_type + 1
        else
            selected_type = 1
        end
	end
	btns[2] = igb(2)
	if igb(1) and igb(1)~= btns[1] then
        if selected_type-1>0 then
            selected_type = selected_type - 1
        else
            selected_type = #getkeys(weapons)
        end
	end
	btns[1] = igb(1)
	
	fire = igb(3) and igb(3)~= btns[3]
	btns[3]=igb(3)
end

function check_pylons()
	weapons = {}
    -- weapons = {
    --     AAM = {{pylon=1,status=1},{pylon=2,status=1},{pylon=3,status=1}},
    --     TRPD = {{pylon=4,status=1},{pylon=5,status=1},{pylon=6,status=1}}
    -- }
    for i = 1, 23, 2 do
    	if ign(i) > 0 and ign(i) <= #types then
        	local wtype = types[ign(i)]
	        local status = ign(i+1)
	        if weapons[wtype] ~= nil then
	        	table.insert(weapons[wtype],{pylon = (i-1)/2+1, status = status})
	        else
	        	weapons[wtype] = {{pylon = (i-1)/2+1, status = status}}
	        end
        end
    end
end

function getkeys(arr)
	if arr == nil then return {} end
	keys={}
	for key,_ in pairs(arr) do
	 table.insert(keys,key)
	end
	return keys
end

function concatArray(a, b)
  local result = {table.unpack(a)}
  table.move(b, 1, #b, #result + 1, result)
  return result
end