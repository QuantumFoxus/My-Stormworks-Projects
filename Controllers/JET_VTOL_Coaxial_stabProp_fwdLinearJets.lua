sin,cos,atan,rad=math.sin,math.cos,math.atan,math.rad
ign=input.getNumber
osn=output.setNumber
s=screen
pi2=math.pi*2
pi=math.pi
function ijkfromeuler(ex,ey,ez)
local cx,sx,cy,sy,cz,sz=cos(ex),sin(ex),cos(ey),sin(ey),cos(ez),sin(ez)
local i,j,k={x=cy*cz,y=cy*sz,z=-sy},{x=sx*sy*cz-cx*sz,y=sx*sy*sz+cx*cz,z=sx*cy},{x=cx*sy*cz+sx*sz,y=cx*sy*sz-sx*cz,z=cx*cy}
return i,j,k
end

function tolocal(v,i,j,k)
return{x=dot(v,i),y=dot(v,j),z=dot(v,k)}
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
return{x=a.y*b.z-a.z*b.y,y=a.z*b.x-a.x*b.z,z=a.x*b.y-a.y*b.x}
end

function vec(x,y,z)
return{x=x or 0,y=y or 0,z=z or 0}
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
if m==0 then return vec()end
return multf(v,1/m)
end

function atan2(y,x)
if x>0 then return atan(y/x)
elseif x<0 and y>=0 then return atan(y/x)+math.pi
elseif x<0 and y<0 then return atan(y/x)-math.pi
elseif x==0 and y>0 then return math.pi/2
elseif x==0 and y<0 then return -math.pi/2
else return 0 end
end

function lerp(a,b,t)
return a+(b-a)*t
end

function clamp(value,min,max)
return math.max(min,math.min(max,value))
end

function project(a,b)
return multf(b,dot(a,b)/dot(b,b))
end

function reject(a,b)
return subt(a,project(a,b))
end

function reflect(a,b)
return subt(a,multf(project(a,b),2))
end

function rotate3(point,pitch,yaw,roll)
local cos_pitch,sin_pitch=math.cos(pitch),math.sin(pitch)
local x1=point.x
local y1=point.y*cos_pitch-point.z*sin_pitch
local z1=point.y*sin_pitch+point.z*cos_pitch
local cos_yaw,sin_yaw=math.cos(yaw),math.sin(yaw)
local x2=x1*cos_yaw+z1*sin_yaw
local y2=y1
local z2=-x1*sin_yaw+z1*cos_yaw
local cos_roll,sin_roll=math.cos(roll),math.sin(roll)
local x3=x2*cos_roll-y2*sin_roll
local y3=x2*sin_roll+y2*cos_roll
local z3=z2
return{x=x3,y=y3,z=z3}
end

function sign(x)
if x>0 then return 1 elseif x<0 then return -1 else return 0 end
end


function PID(setpoint,process,pid)
local err=setpoint-process
local p=err*pid.p
pid.i_l=clamp((pid.i_l or 0)+err*pid.i,pid.min,pid.max)
local d=(err-(pid.prev_err or 0))*pid.d
pid.prev_err=err
return clamp(p+pid.i_l+d,pid.min,pid.max)
end

out={fwd=0,pitch=0,roll=0,yaw=0,up=0,boost=0}
pid_roll={p=3,i=0,d=60,max=1,min=-1}
pid_pitch={p=2,i=0.002,d=120,max=1,min=-1}
pid_yaw={p=0.7,i=0.0005,d=100,max=0.4,min=-0.4}
pid_vertSpd={p=1,i=0.001,d=30,max=1,min=0}
pid_vert={p=2.1,i=0.001,d=300,max=1,min=-1}
pid_vertLinear={p=1,i=0,d=30,max=1,min=-1}
pid_linear={p=1,i=0,d=5,max=1,min=-1}
lastPos=vec()
inited=false
setAlt=0
boostTimer = 0
function onTick()
pos=vec(ign(21),ign(22),ign(23))
spd=subt(pos,lastPos)
lastPos=pos
local ex,ey,ez=ign(24),ign(25),ign(26)
local i,j,k=ijkfromeuler(ex,ey,ez)
local cabineUpVec=toworld(vec(0,1,0),i,j,k)
local cabineFwdVec=toworld(vec(0,0,1),i,j,k)
local worldUp=vec(0,1,0)
localSpd = tolocal(spd, i, j, k)
if not inited and(ex~=0 or ey~=0 or ez~=0) then
dirVec=cabineFwdVec
setAlt = pos.y
inited=true
end
dirVec=dirVec or cabineFwdVec
local trgFwd=ign(2)
if trgFwd>0.9 then
    if boostTimer<20000 then
        boostTimer=boostTimer+1
    end
else
    boostTimer=0
end
if boostTimer>300 then
    if out.boost <1 then
        out.boost = out.boost + 0.01
    end
else
    out.boost = 0
end
local trgYaw=ign(1)
local trgUp=ign(4)
if math.abs(trgUp)>0.02 then setAlt=setAlt+trgUp*0.75 end
local levelAxis=crs(cabineUpVec,worldUp)
local levelLocal=tolocal(levelAxis,i,j,k)
local trgAlt=0
out.up=PID(setAlt,pos.y,pid_vert)
if trgFwd>0.9 then trgAlt=PID(setAlt,pos.y,pid_vertLinear)*0.1
elseif trgFwd<-0.9 then trgAlt=-PID(setAlt,pos.y,pid_vertLinear)*0.1 end
out.up=PID(out.up,spd.y,pid_vertSpd)
out.pitch=-PID(trgAlt,levelLocal.x,pid_pitch)
local pitchComp=math.cos(out.pitch)
out.up=out.up/math.max(pitchComp,0.2)
local rollErr = levelLocal.z + localSpd.x * 0.5
out.roll = PID(0, rollErr, pid_roll)
dirVec=rotate3(dirVec,0,trgYaw*0.02,0)
local yawAxis=crs(cabineFwdVec,dirVec)
local yawLocal=tolocal(yawAxis,i,j,k)
out.yaw=-PID(0,yawLocal.y,pid_yaw)
out.fwd=math.abs(trgFwd)>0.02 and trgFwd or -PID(0,-localSpd.z,pid_linear)
pivL=clamp(-out.fwd-out.yaw*math.cos(clamp(-out.fwd,-1,1)*pi/2),-1,1)
if pivL>0 then pivL=pivL*0.8 end
pivR=clamp(-out.fwd+out.yaw*math.cos(clamp(-out.fwd,-1,1)*pi/2),-1,1)
if pivR>0 then pivR=pivR*0.8 end
sL=1-(out.up*math.cos(pivL*pi/2)-out.fwd*math.sin(pivL*pi/2)+out.roll*math.cos(pivL*pi/2)-out.yaw*math.sin(pivL*pi/2))
sR=1-(out.up*math.cos(pivR*pi/2)-out.fwd*math.sin(pivR*pi/2)-out.roll*math.cos(pivR*pi/2)+out.yaw*math.sin(pivR*pi/2))
osn(1,pivL)
osn(2,pivR)
osn(3,sL)
osn(4,sR)
osn(5,1-out.boost)
osn(6,1-out.boost)
osn(7,clamp(out.pitch,-1,1))
osn(8,-out.roll)
osn(9,clamp(out.yaw,-1,1))
if localSpd.z<-0.01 then
    out.roll=-out.roll
end
osn(10,(- out.roll)*20)
osn(11,( out.roll)*20)
end

function onDraw()
    local w, h = s.getWidth, s.getHeight()
    s.drawText(0,10,"localSpd: "..string.format("%.2f",localSpd.x)..","..string.format("%.2f",localSpd.y)..","..string.format("%.2f",localSpd.z))
    s.drawText(0,20,"SetAlt: "..string.format("%.2f",setAlt))
    s.drawText(0,30,"Alt: "..string.format("%.2f",pos.y))
    s.drawText(0,40,"Vspd: "..string.format("%.2f",spd.y))
end