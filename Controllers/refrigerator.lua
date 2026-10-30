ign = input.getNumber
osn = output.setNumber
igb = input.getBool
osb = output.setBool

volumeSystem = 1
volumeRoom = 8
i = 0
doorOpen = false
OpenTime = 90
CloseTime = 150
lastIgb1 = false
function onTick()
    if lastIgb1 ~= igb(1) and igb(1) == true then
        i = 1
        doorOpen = not doorOpen
    end
    lastIgb1 = igb(1)
    if i < 1000 and i ~= 0 then
        i = i + 1
    end
    local emStop = igb(2) or doorOpen
    local tempS = ign(1)
    local tempRoom = ign(2)
    local tempTrg = ign(3)
    local err = tempTrg - (tempRoom * volumeRoom + tempS * volumeSystem) / (volumeSystem + volumeRoom)
    local cooling = err < 0.5
    local heating = err > 0.5
    local hatch = false
    if doorOpen then
        hatch = false
    end
    if not doorOpen and i > CloseTime then
        hatch = true
    end
    osb(1, hatch)
    osb(2, cooling)
    osb(3, heating)
    osn(1, math.floor(tempS*10)/10)
    osn(2, math.floor(tempRoom*10)/10)
    osn(3, (doorOpen and i > OpenTime) and -1 or 0)
end