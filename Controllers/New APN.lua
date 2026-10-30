sin,cos,atan,rad=math.sin,math.cos,math.atan,math.rad
s=screen
DT = 1/60

function ijkfromeuler(ex,ey,ez)
local cx,sx,cy,sy,cz,sz=cos(ex),sin(ex),cos(ey),sin(ey),cos(ez),sin(ez)
local i,j,k=
{x=cy*cz,y=cy*sz,z=-sy},
{x=sx*sy*cz-cx*sz,y=sx*sy*sz+cx*cz,z=sx*cy},
{x=cx*sy*cz+sx*sz,y=cx*sy*sz-sx*cz,z=cx*cy}
return i,j,k
end

function tolocal(v,i,j,k)
return {x=dot(v,i),y=dot(v,j),z=dot(v,k)}
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
local m=mag(v)
if m==0 then
return vec()
end
return multf(v,1/m)
end

function proj(a,b)
return multf(norm(b),dot(a,norm(b)))
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
else
return 0
end
end

function lerp(a,b,t)
return a+(b-a)*t
end

function clamp(value,min,max)
return math.max(min,math.min(max,value))
end

function sign(x)
if x>0 then return 1 elseif x<0 then return -1 else return 0 end
end

function smooth(a, prev, k)
return prev + (a - prev) * k
end

target_pos={x=0,y=0,z=0}
start_pos=vec()
climbed=false
started=false
sbt=vec()
outmult=property.getNumber("mult")

prev_target_pos=nil
prev_rocket_pos=nil
target_vel=vec()
rocket_vel=vec()

prev_los = nil
prev_los_rate = vec()

prev_az = 0
prev_el = 0

N = property.getNumber("N")
HYBRID = property.getNumber("Hybrid")
if HYBRID == 0 then
HYBRID = 0.75
end

DELAY = property.getNumber("Delay")
if DELAY == 0 then
DELAY = 1
end

SMOOTH = property.getNumber("Smooth")
if SMOOTH == 0 then
SMOOTH = 0.2
end

LOS_SMOOTH = property.getNumber("LOS Smooth")
if LOS_SMOOTH == 0 then
LOS_SMOOTH = 0.2
end

NEAR_DIST = 50
NEAR_GAIN = 5
distToBlowUp = 5
schange = -1

function hybrid_guidance()
local future_target = add(target_pos, multf(target_vel, DELAY * DT))
local future_rocket = add(rocket_pos, multf(rocket_vel, DELAY * DT))

local r = subt(future_target, future_rocket)
local v = subt(target_vel, rocket_vel)

local dist = mag(r)
if dist < distToBlowUp and dist ~= 0 then
output.setBool(2,true)
end
local gain = 1 + (1 - clamp(dist / NEAR_DIST, 0, 1)) * (NEAR_GAIN - 1)
local speed = math.max(mag(rocket_vel), 0.1)

if dist < 0.001 then
return 0,0
end

local los = norm(r)
local t_go = (dist / speed) - (DELAY * DT)
if t_go < 0 then t_go = 0 end

local zem = add(r, multf(v, t_go))
local zem_dir = norm(zem)

local los_rate = vec()
if prev_los ~= nil then
local raw_rate = multf(subt(los, prev_los), 1 / DT)
los_rate = add(prev_los_rate, multf(subt(raw_rate, prev_los_rate), LOS_SMOOTH))
prev_los_rate = {x=los_rate.x,y=los_rate.y,z=los_rate.z}
else
prev_los_rate = vec()
end
prev_los = {x=los.x,y=los.y,z=los.z}

local relative_vel = subt(target_vel, rocket_vel)
local closing_velocity = math.max(0, -dot(relative_vel, los))

local lateral = crs(crs(los, los_rate), los)
local pn_dir = norm(add(los, multf(lateral, clamp((N * closing_velocity) / speed, -2, 2))))

local aim_dir = norm(add(multf(zem_dir, HYBRID), multf(pn_dir, 1 - HYBRID)))

local local_dir = tolocal(aim_dir, rocket_rotate.x, rocket_rotate.y, rocket_rotate.z)

local azimuth = atan2(local_dir.x, local_dir.z) * gain
local elevation = atan2(local_dir.y, math.sqrt(local_dir.x^2 + local_dir.z^2)) * gain

return azimuth, elevation
end

function onTick()
output.setBool(1,(input.getBool(1) and not started) or mag(sbt)<property.getNumber("Distance Radar") and mag(sbt)>0 and started)

rocket_pos={
x=input.getNumber(1),
y=input.getNumber(2),
z=input.getNumber(3)
}

local ex,ey,ez=input.getNumber(4),input.getNumber(5),input.getNumber(6)
local i,j,k=ijkfromeuler(ex,ey,ez)
rocket_rotate={x=i,y=j,z=k}

if prev_rocket_pos~=nil then
rocket_vel = multf(subt(rocket_pos, prev_rocket_pos), 60)
end
prev_rocket_pos={x=rocket_pos.x,y=rocket_pos.y,z=rocket_pos.z}

local tp={
x=input.getNumber(29),
y=input.getNumber(30),
z=input.getNumber(31)
}

if tp.x~=0 or tp.y~=0 or tp.z~=0 then
target_pos=tp
end

if prev_target_pos~=nil then
target_vel = multf(subt(target_pos, prev_target_pos), 60)
end
prev_target_pos={x=target_pos.x,y=target_pos.y,z=target_pos.z}

local azimuth,elevation=hybrid_guidance()

azimuth = smooth(azimuth, prev_az, SMOOTH)
elevation = smooth(elevation, prev_el, SMOOTH)
prev_az = azimuth
prev_el = elevation

if started==true then
output.setNumber(1,clamp(azimuth,-2,2)*outmult)
output.setNumber(2,clamp(elevation,-2,2)*outmult)
else
output.setNumber(1,0)
output.setNumber(2,0)
end

if input.getNumber(32)>0 then
started=true
end

output.setNumber(3,azimuth)
output.setNumber(4,elevation)
output.setNumber(5,0)
end