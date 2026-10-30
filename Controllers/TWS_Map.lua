sin,cos,atan,rad=math.sin,math.cos,math.atan,math.rad
s=screen
ign = input.getNumber
osn = output.setNumber
pi = math.pi
pi2 = pi * 2

function ijkfromeuler(ex,ey,ez)
local cx,sx,cy,sy,cz,sz=cos(ex),sin(ex),cos(ey),sin(ey),cos(ez),sin(ez)
local i,j,k=
{x=cy*cz,y=cy*sz,z=-sy},
{x=sx*sy*cz-cx*sz,y=sx*sy*sz+cx*cz,z=sx*cy},
{x=cx*sy*cz+sx*sz,y=cx*sy*sz-sx*cz,z=cx*cy}
return i,j,k
end

function tolocal(v,i,j,k)
return {x= dot(v,i),y= dot(v,j),z= dot(v,k)}
end

function mag(v)
return math.sqrt((v.x or 0)^2 + (v.y or 0)^2 + (v.z or 0)^2)
end

function dot(a,b)
return (a.x or 0)*(b.x or 0) + (a.y or 0)*(b.y or 0) + (a.z or 0)*(b.z or 0)
end

function vec(x,y,z)
return {x=x or 0,y=y or 0,z=z or 0}
end

function add(a,b)
return vec((a.x or 0)+(b.x or 0),(a.y or 0)+(b.y or 0),(a.z or 0)+(b.z or 0))
end

function multf(a,n)
return vec((a.x or 0)*n,(a.y or 0)*n,(a.z or 0)*n)
end

function invert(a)
return multf(a,-1)
end

function subt(a,b)
return add(a,invert(b))
end

function atan2(y,x)
if x>0 then return atan(y/x)
elseif x<0 and y>=0 then return atan(y/x)+pi
elseif x<0 and y<0 then return atan(y/x)-pi
elseif x==0 and y>0 then return pi/2
elseif x==0 and y<0 then return -pi/2
else return 0 end
end

function pToS(world_pos,self_pos,rot,w,h,camera_rot,no_limit)
local local_pos=subt(world_pos, self_pos)
local_pos=tolocal(local_pos,rot.x,rot.y,rot.z)
local azimuth=atan2(local_pos.x,local_pos.z)-camera_rot.x
local elevation=atan2(local_pos.y,math.sqrt(local_pos.x^2+local_pos.z^2))-camera_rot.y
local x=w/2+(azimuth/MAX_H_FOV)*w/2
local y=h/2-(elevation/MAX_V_FOV)*h/2
if not no_limit and (x<-w*0.5 or x>w*1.5 or y<-h*0.5 or y>h*1.5) then
return nil,nil
end
return x,y
end

trgs = {}
buttons = {}
compass = 0
time = 0
mzoom=9
zoom = 9
XmapPr = 0
YmapPr = 0
Xmap = 0
Ymap = 0
init = true
locktouch = false
bools = {}

function Init()
XmapPr = ign(30)
YmapPr = ign(31)
Xmap = XmapPr
Ymap = YmapPr
end

function floatToBits(float)
local bytes = string.pack(">f", float)
local bits = 0
for i = 1, #bytes do
local byte = bytes:byte(i)
bits = bits * 256 + byte
end
return bits
end
function boolsFromNumber(number)
local bitsNumber = floatToBits(number)
local signals = {}
for i = 0, 31 do
signals[i+1] = (bitsNumber & (1 << i)) ~= 0
end
return signals
end

function onTick()
bools = boolsFromNumber(ign(32))
if init then
Init()
init = false
end
compass = ign(31) * pi2
rr_pos = vec(
ign(26),
ign(27),
ign(28)
)
touchx = ign(29)
touchy = ign(30)
isTouch = bools[1]
for i=0,4 do
if ign(i*4+1) then
trgs[ign(i*4+1)] = {
x=ign(i*4+2),
y=ign(i*4+3),
z=ign(i*4+4)
}
end
end
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
end
if checkButton("DEL") and not DELl then
end
DELl = checkButton("DEL")
end

cnstS = 0.14
function onDraw()
local w,h=s.getWidth(),s.getHeight()
local size = 10/zoom
-- for i, tar in ipairs(targets) do
--     local px, pz = (tar and tar.x) or 0, (tar and tar.z) or 0
--     local sX, sY = map.mapToScreen((radar_pos and radar_pos.x) or 0, (radar_pos and radar_pos.z) or 0, mzoom, w, h, px, pz)
--     if selectedTar and selectedTar == i then
--         s.drawCircle(sX,sY,size)
--     end
--     s.setColor(255,0,0)
--     s.drawText(sX-1,sY-2,i)
-- end
if not clickedonbuttons(touchx, touchy) and (isTouch or isTouch2) and not locktouch then
XmapPr = Xmap
YmapPr = Ymap
Xmap, Ymap = map.screenToMap(Xmap, Ymap, zoom, w, h, touchx, touchy)
time = 0
end
locktouch = isTouch
if checkButton("LOCK") then
Xmap = rr_pos.x
Ymap = rr_pos.z
time = 60
end
screen.drawMap(lerp(XmapPr, Xmap, time / 60), lerp(YmapPr, Ymap, time / 60), zoom)
local xscreenlast, yscreenlast = map.mapToScreen(lerp(XmapPr, Xmap, time / 60), lerp(YmapPr, Ymap, time / 60), zoom,
w, h, rr_pos.x, rr_pos.z)
screen.sc(0, 0, 100)
drawPlane(xscreenlast, yscreenlast, -compass, 10)
screen.sc(0, 100, 0)
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

function drawPlane(x, y, angle, size)
local halfSize = size / 2
local quarterSize = size / 4
local points = {
{x = 0, y = -halfSize},
{x = -quarterSize, y = 0},
{x = -quarterSize, y = quarterSize},
{x = quarterSize, y = quarterSize},
{x = quarterSize, y = 0},
{x = 0, y = -halfSize/2},
}

for i = 1, #points do
local rx, ry = rotatecoords(points[i].x, points[i].y, angle)
rx = rx + x
ry = ry + y
local nextIndex = (i % #points) + 1
local rxnext, rynext = rotatecoords(points[nextIndex].x, points[nextIndex].y, angle)
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