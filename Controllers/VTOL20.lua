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
function toworld(v,i,j,k)
return add(add(multf(i,v.x),multf(j,v.y)),multf(k,v.z))
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
function euler2quat(e)
local cx,cy,cz,sx,sy,sz=math.cos(e.x/2),math.cos(e.y/2),math.cos(e.z/2),math.sin(e.x/2),math.sin(e.y/2),math.sin(e.z/2)
return {w=cx*cy*cz + sx*sy*sz, x=sx*cy*cz - cx*sy*sz, y=cx*sy*cz + sx*cy*sz, z=cx*cy*sz - sx*sy*cz}
end
function qmul(a,b) return {w=a.w*b.w-a.x*b.x-a.y*b.y-a.z*b.z,
x=a.w*b.x+a.x*b.w+a.y*b.z-a.z*b.y,
y=a.w*b.y-a.x*b.z+a.y*b.w+a.z*b.x,
z=a.w*b.z+a.x*b.y-a.y*b.x+a.z*b.w} end
function qinv(q) return {w=q.w,x=-q.x,y=-q.y,z=-q.z} end
function quat2euler(q)
local x=atan2(2*(q.w*q.x+q.y*q.z),1-2*(q.x^2+q.y^2))
local y=math.asin(math.max(-1,math.min(1,2*(q.w*q.y-q.z*q.x))))
local z=atan2(2*(q.w*q.z+q.x*q.y),1-2*(q.y^2+q.z^2))
return {x=x,y=y,z=z}
end
function eulertolocal(trg,cur)
return quat2euler(qmul(euler2quat(trg),qinv(euler2quat(cur))))
end
function eulertoworld(err,cur)
return quat2euler(qmul(euler2quat(cur),euler2quat(err)))
end
function getAngle(trg, pos, ijk)
local vc = subt(trg, pos)
local local_pos = tolocal(vc, ijk.x, ijk.y, ijk.z)
local azimuth = atan2(local_pos.x, local_pos.z)
local elevation = atan2(local_pos.y, math.sqrt(local_pos.x^2 + local_pos.z^2))
if math.abs(elevation) > math.pi / 2 then
azimuth = azimuth + math.pi
elevation = -elevation
end
return azimuth, elevation
end
function pToS(world_pos,self_pos,rot,w,h,camera_rot,no_limit)
local local_pos=tolocal(subt(world_pos,self_pos),rot.x,rot.y,rot.z)
local yaw,pitch=camera_rot.x,camera_rot.y
local cy,sy,cx,sx=cos(yaw),sin(yaw),cos(pitch),sin(pitch)
local x1=cy*local_pos.x-sy*local_pos.z
local z1=sy*local_pos.x+cy*local_pos.z
local y2=cx*local_pos.y-sx*z1
local z2=sx*local_pos.y+cx*z1
local azimuth=atan2(x1,z2)
local elevation=atan2(y2,math.sqrt(x1*x1+z2*z2))
local x=w/2+(azimuth/MAX_H_FOV)*(w/2)
local y=h/2-(elevation/MAX_V_FOV)*(h/2)
if not no_limit and (x<-w*0.5 or x>w*1.5 or y<-h*0.5 or y>h*1.5) then return nil,nil end
return x,y
end
function s6x20(A, b)
local M, y, x, i, j, k, s, p
M = {}
for i = 1, 6 do
M[i] = {}
for j = 1, 6 do
s = 0
for k = 1, 20 do s = s + A[(i - 1) * 20 + k] * A[(j - 1) * 20 + k] end
M[i][j] = s
end
M[i][7] = b[i]
end
for i = 1, 6 do
p = i
for j = i + 1, 6 do if math.abs(M[j][i]) > math.abs(M[p][i]) then p = j end end
M[i], M[p] = M[p], M[i]
s = M[i][i]
for j = i, 7 do M[i][j] = M[i][j] / s end
for j = 1, 6 do
if j ~= i then
s = M[j][i]
for k = i, 7 do M[j][k] = M[j][k] - s * M[i][k] end
end
end
end
y = {}
for i = 1, 6 do y[i] = M[i][7] end
x = {}
for k = 1, 20 do
s = 0
for i = 1, 6 do s = s + A[(i - 1) * 20 + k] * y[i] end
x[k] = s
end
return x
end
function cross(a,b)
return vec(
a.y*b.z-a.z*b.y,
a.z*b.x-a.x*b.z,
a.x*b.y-a.y*b.x)
end

function buildA()
A={}
for m=1,20 do
local d=motors[m].dir
local r=motors[m].pos
local t=cross(r,d)
-- Fx Fy Fz
A[0*20+m]=d.x
A[1*20+m]=d.y
A[2*20+m]=d.z
-- Mx My Mz
A[3*20+m]=t.x
A[4*20+m]=t.y
A[5*20+m]=t.z
end
return A
end

pidPitch={p=0.8,i=0.01,d=30,max=1,min=-1,i_l=0,prev_err=0}
pidYaw=  {p=0.8,i=0.01,d=30,max=1,min=-1,i_l=0,prev_err=0}
pidRoll= {p=0.8,i=0.01,d=30,max=1,min=-1,i_l=0,prev_err=0}
pidMoveX={p=0.02,i=0,d=1.4,max=1,min=-1,i_l=0,prev_err=0}
pidMoveY={p=0.02,i=0,d=1.4,max=1,min=-1,i_l=0,prev_err=0}
pidMoveZ={p=0.02,i=0,d=1.4,max=1,min=-1,i_l=0,prev_err=0}
function PID(setpoint,process,pid)
local err = setpoint - process
local p = err * pid.p
pid.i_l = clamp(pid.i_l + err * pid.i, pid.min*0.3, pid.max*0.3)
local d = (err - pid.prev_err) * pid.d
pid.prev_err = err
return clamp(p+pid.i_l+d,pid.min,pid.max)
end
function clamp(Value,Min,Max)
if Value>Max then
Value=Max
elseif Value<=Min then
Value=Min
end
return Value
end
function balance(a)
local m=0 for i=1,#a do m=math.max(m,math.abs(a[i])) end
if m>1 then for i=1,#a do a[i]=a[i]/m end end
return a
end

MAX_H_FOV = rad(40)
MAX_V_FOV   = rad(28)
motors = {
{pos=vec(-0.75,1,2.5),   dir=vec(0,1,0)},  --UP_FORWARD_LEFT
{pos=vec(0.75,1,2.5),    dir=vec(0,1,0)},  --UP_FORWARD_RIGHT
{pos=vec(-0.75,1,-2.5),  dir=vec(0,1,0)},  --UP_BACK_LEFT
{pos=vec(0.75,1,-2.5),   dir=vec(0,1,0)},  --UP_BACK_RIGHT
{pos=vec(-0.75,-1,2.5),  dir=vec(0,-1,0)}, --DOWN_FORWARD_LEFT
{pos=vec(0.75,-1,2.5),   dir=vec(0,-1,0)}, --DOWN_FORWARD_RIGHT
{pos=vec(-0.75,-1,-2.5), dir=vec(0,-1,0)}, --DOWN_BACK_LEFT
{pos=vec(0.75,-1,-2.5),  dir=vec(0,-1,0)}, --DOWN_BACK_RIGHT
{pos=vec(1,0,2.5),       dir=vec(1,0,0)},  --RIGHT_FORWARD
{pos=vec(1,0.75,0),      dir=vec(1,0,0)},  --RIGHT_UP
{pos=vec(1,0,-2.5),      dir=vec(1,0,0)},  --RIGHT_BACK
{pos=vec(1,-0.75,0),     dir=vec(1,0,0)},  --RIGHT_DOWN
{pos=vec(-1,0,2.5),      dir=vec(-1,0,0)}, --LEFT_FORWARD
{pos=vec(-1,0.75,0),     dir=vec(-1,0,0)}, --LEFT_UP
{pos=vec(-1,0,-2.5),     dir=vec(-1,0,0)}, --LEFT_BACK
{pos=vec(-1,-0.75,-0),   dir=vec(-1,0,0)}, --LEFT_DOWN
{pos=vec(-0.75,0,3.25),  dir=vec(0,0,1)},  --FORWARD_LEFT
{pos=vec(0.75,0,3.25),   dir=vec(0,0,1)},  --FORWARD_RIGHT
{pos=vec(-0.75,0,-3.25), dir=vec(0,0,-1)}, --BACK_LEFT
{pos=vec(0.75,0,-3.25),  dir=vec(0,0,-1)}, --BACK_RIGHT
}
inited = false
CAM_ROT = vec()
function onTick()
if not inited then
A = buildA()
inited = true
end
CAM_ROT=vec(ign(20)*pi2,ign(21)*pi2,0)
self_pos=vec(ign(1),ign(2),ign(3))
local sx,sy,sz=ijkfromeuler(ign(4),ign(5),ign(6))
tar_pos=vec(ign(14),ign(15),ign(16))

local errW = subt(tar_pos, self_pos)
local errL = tolocal(vec(-PID(0,errW.x,pidMoveX), -PID(0,errW.y,pidMoveY), -PID(0,errW.z,pidMoveZ)), sx, sy, sz)
local kF = 0.01
local Fx,Fy,Fz = errL.x, errL.y, errL.z
local lCurRotation = eulertolocal(vec(ign(17),ign(18),ign(19)),vec(ign(4),ign(5),ign(6)))
osn(21,lCurRotation.x)
osn(22,lCurRotation.y)
osn(23,lCurRotation.z)
local Mx,My,Mz = -PID(0,lCurRotation.x,pidPitch),-PID(0,lCurRotation.y,pidYaw),-PID(0,lCurRotation.z,pidRoll)

b = {Fx,Fy,Fz,Mx,My,Mz}
T = balance(s6x20(A,b))
local power = 7
for i=1,20 do
osn(i,0.32+clamp(T[i],0,1)*power)
end
end

cam_pos = vec(0,2.5,-3.125)
i,j,k = ijkfromeuler(0,0,0)
ijk = vec(i,j,k)
T = {}
function onDraw()
w,h = s.getWidth(), s.getHeight()
for ii, m in ipairs(motors) do
local xs,ys = pToS(m.pos,cam_pos,ijk,w,h,CAM_ROT)
if xs ~= nil and ys ~= nil and T[ii] ~= nil then
local color = multf(m.dir,200)
local distance = mag(subt(m.pos, cam_pos))
local radius = 30 / (distance + 1)
local xs2,ys2 = pToS(add(m.pos,multf(m.dir,T[ii]*3)),cam_pos,ijk,w,h,CAM_ROT)
if xs2 ~= nil and ys2 ~= nil then
s.sc(math.abs(color.x),math.abs(color.y),math.abs(color.z))
s.drawCircle(xs,ys,radius)
s.drawLine(xs,ys,xs2,ys2)
end
end
end
end