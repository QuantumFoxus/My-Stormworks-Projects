sin,cos,atan,rad=math.sin,math.cos,math.atan,math.rad
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

function mag(v)
return math.sqrt(v.x^2+v.y^2+v.z^2)
end

function dot(a,b)
return a.x*b.x+a.y*b.y+a.z*b.z
end

function vec(x,y,z)
return {x=x or 0,y=y or 0,z=z or 0}
end

function add(a,b)
return vec(a.x+b.x,a.y+b.y,a.z+b.z)
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

function norm(v)
local m=mag(v)
if m==0 then return vec() end
return multf(v,1/m)
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

target_pos=vec()
raw_target_pos=vec()
rocket_pos=vec()
rocket_vel=vec()
target_vel=vec()

prev_target_pos=nil
prev_rocket_pos=nil

outmult=property.getNumber("mult")
started=false

TARGET_SMOOTH = property.getNumber("Target Smooth")
if TARGET_SMOOTH == 0 then
TARGET_SMOOTH = 0.25
end

function update_target_filter(tp)
if raw_target_pos.x == 0 and raw_target_pos.y == 0 and raw_target_pos.z == 0 then
raw_target_pos = {x=tp.x,y=tp.y,z=tp.z}
target_pos = {x=tp.x,y=tp.y,z=tp.z}
return
end

raw_target_pos = {x=tp.x,y=tp.y,z=tp.z}
target_pos = {
x=lerp(target_pos.x, raw_target_pos.x, TARGET_SMOOTH),
y=lerp(target_pos.y, raw_target_pos.y, TARGET_SMOOTH),
z=lerp(target_pos.z, raw_target_pos.z, TARGET_SMOOTH)
}
end

function lead_guidance()
local r = subt(target_pos, rocket_pos)
local dist = mag(r)
if dist < 0.001 then
return 0,0
end

local speed = math.max(mag(rocket_vel), 0.1)
local t_lead = dist / speed
if t_lead > 3 then
t_lead = 3
end

local lead_pos = add(target_pos, multf(target_vel, t_lead))
local delta = subt(lead_pos, rocket_pos)

local aim_dir = norm(delta)

local front_dist = input.getNumber(32)
if front_dist > 0 and front_dist < SAFE_DIST then
local k = 1 - clamp(front_dist / SAFE_DIST, 0, 1)

local up = vec(0,1,0)
aim_dir = norm(add(aim_dir, multf(up, k * PULL_UP)))
end

local local_dir = tolocal(aim_dir, rocket_rotate.x, rocket_rotate.y, rocket_rotate.z)

local azimuth = atan2(local_dir.x, local_dir.z)
local elevation = atan2(local_dir.y, math.sqrt(local_dir.x^2 + local_dir.z^2))

return azimuth, elevation
end

SAFE_DIST = 100
PULL_UP = 1

function onTick()
rocket_pos={
x=input.getNumber(1),
y=input.getNumber(2),
z=input.getNumber(3)
}

local ex,ey,ez=input.getNumber(4),input.getNumber(5),input.getNumber(6)
local i,j,k=ijkfromeuler(ex,ey,ez)
rocket_rotate={x=i,y=j,z=k}

if prev_rocket_pos then
rocket_vel=multf(subt(rocket_pos,prev_rocket_pos),60)
end
prev_rocket_pos={x=rocket_pos.x,y=rocket_pos.y,z=rocket_pos.z}

local tp={
x=input.getNumber(28),
y=input.getNumber(29),
z=input.getNumber(30)
}

if tp.x~=0 or tp.y~=0 or tp.z~=0 then
update_target_filter(tp)
end

if prev_target_pos then
target_vel=multf(subt(target_pos,prev_target_pos),60)
end
prev_target_pos={x=target_pos.x,y=target_pos.y,z=target_pos.z}

local azimuth,elevation=lead_guidance()

if started and (tp.x ~= 0 or tp.y ~= 0 or tp.z ~= 0) then
output.setNumber(1,azimuth*outmult)
output.setNumber(2,elevation*outmult)
else
output.setNumber(1,0)
output.setNumber(2,0)
end

if input.getNumber(31)>0 then
started=true
end

output.setNumber(3,azimuth)
output.setNumber(4,elevation)
end