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

MAX_TRGS = 30
timer = 0
MAX_H_FOV = rad(property.getNumber("MAX_HORIZONTAL_FOV")) or rad(40)
MAX_V_FOV   = rad(property.getNumber("MAX_VERTICAL_FOV"))   or rad(28)
MAX_DISTANCE = property.getNumber("MAX DISTANCE") or 100000
MAX_DIST_ERR = property.getNumber("Radar MAX distance error") or 300
TIME_TO_DEL = property.getNumber("Time to delete") or 600
ONLINE_MODE = property.getBool("Online targets update")
ABG_A = 0.9
MIN_DT_FOR_GAMMA = 5
trgs = {}
selTar = nil
outI = 0
function abg_update(trg, meas_pos, dt)
if dt <= 3 and dt ~= -1 then return end
if dt == -1 then dt = 1 end
local a = ABG_A
local alpha = a
local beta  = 2 * (1 - a)
local gamma = (1 - a) * (1 - a)
if dt < MIN_DT_FOR_GAMMA then
gamma = 0
end
local x_pred = add(
add(trg.pos, multf(trg.vel, dt)),
multf(trg.acc, 0.5 * dt * dt)
)
local v_pred = add(trg.vel, multf(trg.acc, dt))
local a_pred = trg.acc

local r = subt(meas_pos, x_pred)

trg.pos = add(x_pred, multf(r, alpha))
trg.vel = add(v_pred, multf(r, beta / dt))
trg.acc = add(a_pred, multf(r, gamma / (dt * dt)))
end

function online_upd(trg)
local v = add(trg.vel,trg.acc)
if mag(v) < 0.5 then return end
trg.vel = v
trg.pos = add(trg.pos,trg.vel)
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
bools = {}
function onTick()
bnum = ign(21)
bools = boolsFromNumber(bnum)
rr_pos=vec(ign(1),ign(2),ign(3))
local rx,ry,rz=ijkfromeuler(ign(4),ign(5),ign(6))
rrRot=vec(rx,ry,rz)
camRot=vec(ign(7)*pi2, ign(8)*pi2,0)

if ONLINE_MODE then
for _, trg in ipairs(trgs) do
online_upd(trg)
end
end

for i = 9, 18, 3 do
if math.abs(ign(i))>0.001 or math.abs(ign(i+1))>0.001 or math.abs(ign(i+2))>0.001 then
local meas = vec(ign(i),ign(i+1),ign(i+2))
local found = false

for _, trg in ipairs(trgs) do
local dt = timer - trg.time
local pred = trg.pos
if dt > 3 then
pred = add(
add(trg.pos, multf(trg.vel, dt)),
multf(trg.acc, 0.5 * dt * dt)
)
end
local mgnV = mag(trg.vel)
local dst_check = (trg.vel ~= nil and mgnV > 0.5) and (MAX_DIST_ERR * 2 * mgnV) or MAX_DIST_ERR
if mag(subt(meas, pred)) < dst_check then
abg_update(trg, meas, dt)
trg.time = timer
trg.radar = (i-9)/3
found = true
break
end
end

if not found then
for idx = 1, MAX_TRGS do
if trgs[idx] == nil then
trgs[idx] = {
    pos = meas,
    vel = vec(),
    acc = vec(),
    time = timer,
    radar = (i-9)/3
}
break
end
end
end
end
end

for i=#trgs,1,-1 do
if trgs[i] and timer > trgs[i].time + TIME_TO_DEL*60 then
trgs[i]=nil
end
end
if selTar ~= nil and trgs[selTar] ~= nil then
local tp = trgs[selTar].pos
osn(21,tp.x)
osn(22,tp.y)
osn(23,tp.z)
osn(24,selTar)
end

for i = 0,4 do
local trg = trgs[outI+i]
if trg ~= nil then
osn(1+i*4,outI+i)
osn(2+i*4,trg.pos.x)
osn(3+i*4,trg.pos.y)
osn(4+i*4,trg.pos.z)
end
end
outI = outI+5 > MAX_TRGS and 1 or outI+5
timer = timer+1
osn(25,rr_pos.x)
osn(26,rr_pos.y)
osn(27,rr_pos.z)
end

function onDraw()
w, h = s.getWidth(), s.getHeight()
s.sc(0, 0, 255)
s.drawRect(0,0,w-1,h-1)
if w == 256 then
local selFlag = bools[1]
for i = 1, MAX_TRGS do
local t = trgs[i]
if t ~= nil and rr_pos~= nil then
s.sc(200, 200, 0)
local vel_mag = mag(t.vel or vec())
local acc_mag = mag(t.acc or vec())
if selTar and selTar == i then
s.sc(255,0,0)
end
s.drawText(5,i*8, "target " .. i .. ": " .. "Vel vec: " .. (math.floor(vel_mag*100)/100) .. " acc: " .. (math.floor(acc_mag*1000)/1000))

local x,y=pToS(t.pos or vec(),rr_pos,rrRot,w,h,camRot)
if x ~=nil and y~=nil then
local distance=mag(subt(t.pos or vec(),rr_pos))
local size=math.max(1,10*(1-distance/MAX_DISTANCE)) * 0.6
if mag(vec(w/2-x,h/2-y,0)) < size * 1.5 and bools[1] then
selTar = i
selFlag = false
end
local x1,y1=x-size,y-size
local x2,y2=x+size,y+size
s.sc(255,0,0)
if selTar and selTar == i then
s.drawCircle(x,y,size+3)
end
s.drawRect(x1,y1,size*2,size*2)
local x3 = x-(#tostring(i))*4
s.drawText(x3+3,y-2,i)
x3 = x-(#tostring(math.floor(distance)))*2
s.drawText(x3+1,y+size+8,math.floor(distance))
end
end
end
if selFlag then selTar = nil end
else
-- for debug on monitors
end
end
