sin,cos,atan,rad=math.sin,math.cos,math.atan,math.rad
s=screen
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
function toworld(v,i,j,k)
return add(add(multf(i,v.x),multf(j,v.y)),multf(k,v.z))
end
function mag(v)
return math.sqrt(v.x^2+v.y^2+v.z^2)
end
function dot(a,b)
return a.x*b.x+a.y*b.y+a.z*b.z
end
function crs(a,b)
return {x=a.y*b.z-a.z*b.y,y=a.z*b.x-a.x*b.z,z=a.x*b.y-a.y*b.x}
end
function norm(v)
return multf(v,1/mag(v))
end
function proj(a,b)
return multf(norm(b), dot(a,norm(b)))
end
function vec(x,y,z)
return {x=x or 0,y=y or 0,z=z or 0}
end
function add(a,b)
return vec(a.x+b.x,a.y+b.y,a.z+b.z)
end
function mult(a,b)
return vec(a.x*b.x,a.y*b.y,a.z*b.z)
end
function multf(a,n)
return vec(a.x*n,a.y*n,a.z*n)
end
function invert(a)
return multf(a,-1)
end
function subt(a,b)
return add(a,invert(b))
end
function atan2(y,x)
if x>0 then
return atan(y/x)
elseif x<0 and y>=0 then
return atan(y/x)+math.pi
elseif x<0 and y<0 then
return atan(y/x)-math.pi
elseif x==0 and y>0 then
return math.pi/2
elseif x==0 and y<0 then
return -math.pi/2
else--x==0 and y==0
return 0--nil,
end
end

function rotate3(v, pitch, yaw, roll)
    local cp, sp = cos(pitch), sin(pitch)
    local cy, sy = cos(yaw),   sin(yaw)
    local cr, sr = cos(roll),  sin(roll)

    local x1 = v.x
    local y1 = v.y * cp - v.z * sp
    local z1 = v.y * sp + v.z * cp

    local x2 = x1 * cy - y1 * sy
    local y2 = x1 * sy + y1 * cy
    local z2 = z1

    return {
        x = x2 * cr - z2 * sr,
        y = y2,
        z = x2 * sr + z2 * cr
    }
end

w=200
h=100
MAX_H_FOV=rad(40)
MAX_V_FOV=rad(60)
MIN_DISTANCE=1
MAX_DISTANCE=8000
TIMETODELETE=5
MAX_ERR_TARGET = 30
pi2=math.pi*2
trgs={}
time=0

radar_err={0,0.5,0.5}

local radar_pos={0,0,0}
local radar_rot={0,0,0}--pitch,yaw,roll()
local camera_rot={0,0}--pitch,yaw()

horizont = {{x=0,y=0,z=1}}
for i = -180,180,10 do
    local vec = rotate3(horizont[1], 0, 0, math.rad(i))
    table.insert(horizont,vec)
end
table.insert(horizont,rotate3(horizont[1], 0, math.pi/8, 0))
table.insert(horizont,rotate3(horizont[1], 0, -math.pi/8, 0))
table.remove(horizont,1)

hor2= {}
function onTick()
--
radar_pos={
input.getNumber(24),--X
input.getNumber(25),--Y
input.getNumber(26)--Z
}
local rx,ry,rz=ijkfromeuler(input.getNumber(27),input.getNumber(28),input.getNumber(29))
radar_rot={
rx,ry,rz
}
local rx_ny,ry_ny,rz_ny=ijkfromeuler(input.getNumber(27),0,input.getNumber(29))
radar_rot_ny={
rx_ny,ry_ny,rz_ny
}
camera_rot={
input.getNumber(8)*pi2,--x
input.getNumber(4)*pi2--y
}

for i=1,#horizont,1 do
    hor2[i]=rotate3(horizont[i],camera_rot[1],0,camera_rot[2])
    hor2[i]=toworld(hor2[i],radar_rot[1],radar_rot[2],radar_rot[3])
end

time=time+1
-- targets={}
for i = 0,5,1 do
if input.getBool(i + 1) then
local distance = input.getNumber(i * 4 + 1)
local azimuth = input.getNumber(i * 4 + 2) * pi2
local elevation = input.getNumber(i * 4 + 3) * pi2


local x = distance * cos(elevation) * sin(azimuth) + radar_err[1]
local z = distance * cos(elevation) * cos(azimuth) + radar_err[3]
local y = distance * sin(elevation) + radar_err[2]
local glob_pos = toworld({ x = x, y = y, z = z }, radar_rot[1], radar_rot[2], radar_rot[3])
local world_pos = vec(
glob_pos.x + radar_pos[1], glob_pos.y + radar_pos[2], glob_pos.z + radar_pos[3])
local rewrite = false
for j = 1,#trgs,1 do
if trgs[j] ~= nil and mag(subt(trgs[j].world_pos, world_pos)) < MAX_ERR_TARGET then
trgs[j].world_pos = world_pos
trgs[j].time = time
rewrite = true
break
end
end
if rewrite == false then
local added = false
for j=1,#trgs,1 do
if trgs[j]==nil then
trgs[j]={
world_pos = world_pos,
time = time,
detect = true,
id = j
}
added = true
break
end
end
if added==false then
trgs[#trgs+1]={
world_pos = world_pos,
time = time,
detect = true,
id = #trgs+1
}
end
end
end
end
for i = #trgs, 1, -1 do
if trgs[i] ~= nil and time > trgs[i].time + TIMETODELETE * 60 then
trgs[i]=nil
elseif trgs[i] ~= nil then
trgs[i].detect = false
end
end
MAX_H_FOV = rad(property.getNumber("MAX_HORIZONTAL_FOV"))
MAX_V_FOV = rad(property.getNumber("MAX_VERTICAL_FOV"))
TIMETODELETE = property.getNumber("TIMETODELETE")
MAX_ERR_TARGET = property.getNumber("MAX_ERR_TARGET")
end

function projectToScreen(world_pos,tmpp)
local dx=world_pos.x-radar_pos[1]
local dy=world_pos.y-radar_pos[2]
local dz=world_pos.z-radar_pos[3]
local local_pos=tolocal ({x=dx,y=dy,z=dz},radar_rot[1],radar_rot[2],radar_rot[3])
local azimuth=atan2(local_pos.x,local_pos.z)-camera_rot[2]--x,z
local elevation=atan2(local_pos.y,math.sqrt(local_pos.x^2+local_pos.z^2))-camera_rot[1]--y,x,z

local x=w/2+(azimuth/(MAX_H_FOV))*w/2
local y=h/2-(elevation/(MAX_V_FOV))*h/2

return x,y
end

function pToS(world_pos)
local dx=world_pos.x
local dy=world_pos.y
local dz=world_pos.z
local local_pos=tolocal({x=dx,y=dy,z=dz},radar_rot[1],radar_rot[2],radar_rot[3])
local azimuth=atan2(local_pos.x,local_pos.z)--x,z
local elevation=atan2(local_pos.y,math.sqrt(local_pos.x^2+local_pos.z^2))--y,x,z

local x=w/2+(azimuth/(MAX_H_FOV))*w/2
local y=h/2-(elevation/(MAX_V_FOV))*h/2

return x,y
end

function onDraw()
w=s.getWidth()
h=s.getHeight()
s.sc(255,255,255)
s.drawRect(0,0,w-1,h-1)

for i=1,#hor2-2,1 do
    local x,y = pToS(hor2[i])
    s.drawCircle(x,y,2)
end
local xtmp,ytmp=pToS(hor2[1])
local xend,yend=pToS(hor2[#hor2])
s.drawLine(xtmp,ytmp,xend,yend)

for tmpp,target in ipairs(trgs) do
local x,y=projectToScreen(target.world_pos,tmpp)
local distance=math.sqrt(
(target.world_pos.x-radar_pos[1])^2+
(target.world_pos.y-radar_pos[2])^2+
(target.world_pos.z-radar_pos[3])^2)

local size=math.max(1,10*(1-distance/MAX_DISTANCE))
local x1,y1=x-math.max(1,size),y-math.max(1,size)
local x2,y2=x+math.max(1,size),y+math.max(1,size)
if target.detect then
s.sc(0,255,0)
else
    s.sc(255,0,0)
end
s.drawLine(x1,y,x,y1)
s.drawLine(x,y1,x2,y)
s.drawLine(x2,y,x,y2)
s.drawLine(x,y2,x1,y)
s.drawText(x-1,y-2,target.id)
s.drawText(x-1,y+size*1.2,math.floor(distance))
-- s.drawLine(x1,y,x2,y)
-- s.drawLine(x,y1,x,y2)
end
end