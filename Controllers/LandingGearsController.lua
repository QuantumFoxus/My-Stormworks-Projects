ticks = 60
close = false
ticksNow = 0
actionlast = false
gears = {
    front = {
        gears = {
            time = property.getNumber("Front gear open time") * ticks,
            openState = property.getNumber("FrontGearOpen"),
            closeState = property.getNumber("FrontGearClose")
        },
        cap = {
            time = property.getNumber("Front cap open time") * ticks,
            openState = property.getNumber("FrontCapOpen"),
            closeState = property.getNumber("FrontCapClose"),
            closeAfterGears = property.getBool("Close front cap when gears is opened")
        }
    },
    rear = {
        gears = {
            time = property.getNumber("Rear gear open time") * ticks,
            openState = property.getNumber("RearGearOpen"),
            closeState = property.getNumber("RearGearClose")
        },
        cap = {
            time = property.getNumber("Rear cap open time") * ticks,
            openState = property.getNumber("RearCapOpen"),
            closeState = property.getNumber("RearCapClose"),
            closeAfterGears = property.getBool("Close rear cap when gears is opened")
        }
    }
}
outputG = {
    front = {
        gears = gears.front.gears.openState,
        cap = gears.front.cap.closeAfterGears and gears.front.cap.closeState or gears.front.cap.openState
    },
    rear = {
        gears = gears.rear.gears.openState,
        cap = gears.rear.cap.closeAfterGears and gears.rear.cap.closeState or gears.rear.cap.openState
    },
    unlock = false,
    lastunlock = false,
}

function onTick()
    action = input.getBool(1)
    if action ~= actionlast and action then
        close = not close
        ticksNow = 1
        finished = 0
    end
    actionlast = action
    gearsAction()
    output.setNumber(1,outputG.front.gears)
    output.setNumber(2,outputG.front.cap)
    output.setNumber(3,outputG.rear.gears)
    output.setNumber(4,outputG.rear.cap)
    output.setBool(1,ticksNow > 0)
    if ticksNow ~= 0 then
        ticksNow = ticksNow + 1
    end
end
finished = 0

function gearsAction()
    if ticksNow == 0 then
        return
    end
    for side, _ in pairs(gears) do
        if close then
            if gears[side].cap.closeAfterGears then
                if ticksNow < (gears[side].cap.time + gears[side].gears.time) then
                    outputG[side].cap = gears[side].cap.openState
                end
                if ticksNow > gears[side].cap.time then
                    outputG[side].gears = gears[side].gears.closeState
                end
                if ticksNow > (gears[side].cap.time + gears[side].gears.time) then
                    outputG[side].cap = gears[side].cap.closeState
                end
                if ticksNow > (gears[side].cap.time * 2 + gears[side].gears.time) then
                    outputG[side].cap = gears[side].cap.closeState
                    finished = finished + 1
                end
            else
                outputG[side].gears = gears[side].gears.closeState
                if ticksNow > gears[side].gears.time then
                    outputG[side].cap = gears[side].cap.closeState
                end
                if ticksNow > (gears[side].cap.time + gears[side].gears.time) then
                    outputG[side].cap = gears[side].cap.closeState
                    finished = finished + 1
                end
            end
        else
            if gears[side].cap.closeAfterGears then
                outputG[side].cap = gears[side].cap.openState
                if ticksNow > gears[side].cap.time then
                    outputG[side].gears = gears[side].gears.openState
                end
                if ticksNow > (gears[side].cap.time + gears[side].gears.time) then
                   outputG[side].cap = gears[side].cap.closeState
                end
                if ticksNow > (gears[side].cap.time * 2 + gears[side].gears.time) then
                    finished = finished + 1
                end
            else
                outputG[side].cap = gears[side].cap.openState
                if ticksNow > gears[side].cap.time then
                    outputG[side].gears = gears[side].gears.openState
                end
                if ticksNow > (gears[side].cap.time + gears[side].gears.time) then
                    finished = finished + 1
                end
            end
        end
    end
    if finished == 2 then
        ticksNow = 0
        finished = 0
    end
end