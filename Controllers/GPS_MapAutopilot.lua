w,h = 64,64
osn = output.setNumber
ign = input.getNumber
buttons = {}
isTouchlast = false
isTouch2last = false
pi2 = math.pi * 2
zoom = 1
time = 0
XmapPr = 0
YmapPr = 0
Xmap = 0
Ymap = 0
locktouch = false
init = true
GPS = {}
DELl = false
dstToNext = 20
angletrg=0
function Init()
    XmapPr = ign(30)
    YmapPr = ign(31)
    Xmap = XmapPr
    Ymap = YmapPr
end

function onTick()
    if init then
        Init()
        init = false
    end
    touchx = ign(3)
    touchy = ign(4)
    touchx2 = ign(5)
    touchy2 = ign(6)
    isTouch = input.getBool(1)
    isTouch2 = input.getBool(2)
    heading = ign(28)
    throttle = ign(29)
    gpsX = ign(30)
    gpsY = ign(31)
    compass = ign(32) * pi2
    updateButtons()
    if time < 60 then
        time = time + 5
    end
    if checkButton("-") and zoom < 30 then
        zoom = zoom + 0.1
    end
    if checkButton("+") and zoom >= 0.5 then
        zoom = zoom - 0.1
    end
    if checkButton("R") then
        zoom = 1
    end
    if checkButton("CLR") then
        GPS = {}
    end
    if checkButton("DEL") and not DELl then
        table.remove(GPS, #GPS)
    end
    DELl = checkButton("DEL")
    if checkButton("AUTO") then
        if #GPS > 0 then
            local dst = math.sqrt((gpsX - GPS[1].x) ^ 2 + (gpsY - GPS[1].y) ^ 2)
            local x, y = GPS[1].x, GPS[1].y
            local dx = x - gpsX
            local dy = y - gpsY
            angletrg = atan2(dy, dx) - math.pi / 2
            local angleDiff = compass - angletrg
            if math.abs(angleDiff) > math.pi then
                angleDiff = angleDiff - pi2 * sign(angleDiff)
            end
            osn(1, clamp(angleDiff,-0.5,0.5))
            if #GPS == 1 then
                throttletar = clamp(dst / (dstToNext*2), 0, 1)
            else
                throttletar = 1
            end
            osn(2, throttletar)
            if dst < dstToNext and #GPS == 1 then
                table.remove(GPS, 1)
            elseif dst < dstToNext * 2 then
                table.remove(GPS, 1)
            end
        else
            buttons["AUTO"].state = false
            osn(1, heading)
            osn(2, throttle)
        end
    else
        osn(1, heading)
        osn(2, throttle)
    end
end

cnstS = 0.14

function onDraw()
    w = screen.getWidth()
    h = screen.getHeight()
    if not clickedonbuttons(touchx, touchy) and (isTouch or isTouch2) and not locktouch then
        XmapPr = Xmap
        YmapPr = Ymap
        Xmap, Ymap = map.screenToMap(Xmap, Ymap, zoom, w, h, touchx, touchy)
        time = 0
        if checkButton("SET") then
            table.insert(GPS, { x = Xmap, y = Ymap })
        end
    end
    locktouch = isTouch
    if checkButton("LOCK") then
        Xmap = gpsX
        Ymap = gpsY
        time = 60
    end
    screen.drawMap(lerp(XmapPr, Xmap, time / 60), lerp(YmapPr, Ymap, time / 60), zoom)
    local xscreenlast, yscreenlast = map.mapToScreen(lerp(XmapPr, Xmap, time / 60), lerp(YmapPr, Ymap, time / 60), zoom,
    w, h, gpsX, gpsY)
    screen.sc(0, 0, 100)
    drawShip(xscreenlast, yscreenlast, -compass, 10)
    screen.sc(0, 100, 0)
    for i = 1, #GPS do
        local xscreen, yscreen = map.mapToScreen(lerp(XmapPr, Xmap, time / 60), lerp(YmapPr, Ymap, time / 60), zoom, w, h,
            GPS[i].x, GPS[i].y)
        screen.drawCircle(xscreen, yscreen, 3)
        screen.drawLine(xscreen, yscreen, xscreenlast, yscreenlast)
        xscreenlast, yscreenlast = xscreen, yscreen
    end
    drawButton(w - h * cnstS*3, 0, h * cnstS*3, h * cnstS, "LOCK", { 0, 0, 100 }, true, true)
    drawButton(w - h * cnstS*3, h * cnstS, h * cnstS, h * cnstS, "+", { 0, 100, 0 }, false, false)
    drawButton(w - h * cnstS*2, h * cnstS, h * cnstS, h * cnstS, "-", { 100, 0, 0 }, false, false)
    drawButton(w - h * cnstS, h * cnstS, h * cnstS, h * cnstS, "R", { 0, 0, 100 }, false, false)
    drawButton(w - h * cnstS*3, h * cnstS * 2, h * cnstS * 3, h * cnstS, "SET", { 50, 50, 50 }, true, false)
    drawButton(w - h * cnstS*3, h * cnstS*3, h * cnstS*3, h * cnstS, "CLR", { 50, 50, 50 }, false, false)
    drawButton(w - h * cnstS*3, h * cnstS*4, h * cnstS*3, h * cnstS, "DEL", { 50, 50, 50 }, false, false)
    drawButton(w - h * cnstS*3, h * cnstS*5, h * cnstS*3, h * cnstS, "AUTO", { 50, 0, 0 }, true, false)
end

function drawButton(x, y, w, h, text, color, istoggle, state)
    if buttons[text] == nil then
        buttons[text] = {}
    end
    buttons[text].istoggle = istoggle
    buttons[text].x = x
    buttons[text].y = y
    buttons[text].w = w
    buttons[text].h = h
    if buttons[text].state == nil then
        buttons[text].state = state
    end
    if buttons[text].state == false then
        screen.sc(0, 0, 0)
    else
        screen.sc(255, 0, 0)
    end
    screen.drawRectF(x, y, w, h)
    screen.sc(color[1], color[2], color[3])
    screen.drawRectF(x + 1, y + 1, w - 2, h - 2)
    screen.sc(255, 255, 255)
    screen.drawText(x + 3, y + 2, text)
end

function updateButtons()
    local check = isTouch and isTouchlast == false or isTouch2 and isTouch2last == false
    isTouchlast = isTouch
    isTouch2last = isTouch2
    for k, v in pairs(buttons) do
        local inrange = touchx >= v.x and touchx <= v.x + v.w and touchy >= v.y and touchy <= v.y + v.h
        if v.istoggle then
            if check and touchx >= v.x and inrange then
                buttons[k].state = not buttons[k].state
            end
        else
            buttons[k].state = (isTouch or isTouch2) and inrange
        end
    end
end

function checkButton(name)
    if buttons[name] == nil then
        return false
    end
    return buttons[name].state
end

function clickedonbuttons(x, y)
    for k, v in pairs(buttons) do
        if x >= v.x and x <= v.x + v.w and y >= v.y and y <= v.y + v.h then
            return true
        end
    end
    return false
end

function lerp(a, b, t)
    return a + (b - a) * t
end

function clamp(value, min, max)
    if value < min then
        return min
    elseif value > max then
        return max
    end
    return value
end

function atan2(y, x)
    if x > 0 then
        return math.atan(y / x)
    elseif y >= 0 and x < 0 then
        return math.atan(y / x) + math.pi
    elseif y < 0 and x < 0 then
        return math.atan(y / x) - math.pi
    elseif y > 0 and x == 0 then
        return math.pi / 2
    elseif y < 0 and x == 0 then
        return -math.pi / 2
    end
end

function sign(x)
    if x > 0 then
        return 1
    elseif x < 0 then
        return -1
    else
        return 0
    end
end

function drawShip(x, y, angle, size)
    local halfSize = size / 2
    local quarterSize = size / 4
    local points = {
        {x = 0, y = 0 - halfSize}, --f
        {x = - quarterSize, y = 0}, --l
        {x = - quarterSize, y = quarterSize}, --cl
        {x = - quarterSize, y = halfSize}, --bl
        {x = quarterSize, y = halfSize}, --br
        {x = quarterSize, y = quarterSize}, --cr
        {x = quarterSize, y = 0}, --r
    }
    for i = 1, #points do
        local rx, ry = rotatecoords(points[i].x, points[i].y, angle)
        rx = rx + x
        ry = ry + y
        local nextIndex = (i % #points) + 1
        local rxnext , rynext = rotatecoords(points[nextIndex].x, points[nextIndex].y, angle)
        rxnext = rxnext + x
        rynext = rynext + y
        screen.drawLine(rx, ry, rxnext, rynext)
    end

end

function rotatecoords(x, y, angle)
    local cosA = math.cos(angle)
    local sinA = math.sin(angle)
    return x * cosA - y * sinA, x * sinA + y * cosA
end