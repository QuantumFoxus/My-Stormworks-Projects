sin,cos,atan,rad,deg=math.sin,math.cos,math.atan,math.rad,math.deg
local pi,pi2=math.pi,math.pi*2
s=screen
function ijkfromeuler(ex,ey,ez)
local cx,sx,cy,sy,cz,sz=cos(ex),sin(ex),cos(ey),sin(ey),cos(ez),sin(ez)
return {x=cy*cz,y=cy*sz,z=-sy},{x=sx*sy*cz-cx*sz,y=sx*sy*sz+cx*cz,z=sx*cy},{x=cx*sy*cz+sx*sz,y=cx*sy*sz-sx*cz,z=cx*cy}
end
function tolocal(v,i,j,k) return {x=dot(v,i),y=dot(v,j),z=dot(v,k)} end
function toworld(v,i,j,k) return add(add(multf(i,v.x),multf(j,v.y)),multf(k,v.z)) end
function mag(v) return math.sqrt(v.x^2+v.y^2+v.z^2) end
function dot(a,b) return a.x*b.x+a.y*b.y+a.z*b.z end
function norm(v) local m=mag(v) return m==0 and vec() or multf(v,1/m) end
function vec(x,y,z) return {x=x or 0,y=y or 0,z=z or 0} end
function add(a,b) return vec(a.x+b.x,a.y+b.y,a.z+b.z) end
function multf(a,n) return vec(a.x*n,a.y*n,a.z*n) end
function invert(a) return multf(a,-1) end
function subt(a,b) return add(a,invert(b)) end
function atan2(y,x)
if x>0 then return atan(y/x)
elseif x<0 and y>=0 then return atan(y/x)+pi
elseif x<0 and y<0 then return atan(y/x)-pi
elseif x==0 and y>0 then return pi/2
elseif x==0 and y<0 then return -pi/2
else return 0 end
end

trgs,visible_targets,prevBeams={}, {}, {}
hits,misses,sendIndex={}, {}, 1
max_dist=property.getNumber("Single radar MAX distance error")
if max_dist==0 then max_dist=40 end
local tmp=property.getNumber("Sweep speed")
sweep_speed=tmp==0 and 1 or tmp
inited,ini_i,sweep,const_rotation=false,0,0,0
offset=vec(-6.5,0,-2.25)

function onTick()
const_rotation=input.getNumber(25)/180*pi
if not inited then ini_i=ini_i+1 end
if not inited and ini_i>4 then sweep=const_rotation/pi2 inited=true end
sweep=sweep+sweep_speed
if sweep>=1 then sweep=sweep-2 end
output.setNumber(1,sweep)
for i=1,6 do
visible_targets[i]=false
if trgs[i] then misses[i]=(misses[i] or 0)+1 end
end

local curBeams={}
for b=1,6 do
local bi=(b-1)*4+1
curBeams[b]={d=input.getNumber(bi),az=input.getNumber(bi+1)*pi2,el=input.getNumber(bi+2)*pi2}
end

rr_pos=vec(input.getNumber(26),input.getNumber(27),input.getNumber(28))
local rx,ry,rz=ijkfromeuler(input.getNumber(29),input.getNumber(30),input.getNumber(31))

for b=1,6 do
local beam=prevBeams[b]
if beam and beam.d>1 then
local x=beam.d*cos(beam.el)*sin(beam.az)
local z=beam.d*cos(beam.el)*cos(beam.az)
local y=beam.d*sin(beam.el)
local vecV=toworld(add(vec(x,y,z),offset),rx,ry,rz)
vecV=add(vecV,rr_pos)

local is_duplicate=false
local nearest,nearest_dist=nil,max_dist
for j=1,6 do
if trgs[j]~=nil then
local dist=mag(subt(trgs[j],vecV))
if dist<nearest_dist then nearest,nearest_dist=j,dist end
end
end
if nearest then
is_duplicate=true
trgs[nearest]=add(multf(trgs[nearest],.65),multf(vecV,.35))
hits[nearest]=math.min((hits[nearest] or 1)+1,3)
misses[nearest]=0
visible_targets[nearest]=true
end
if not is_duplicate then
for j=1,6 do
if trgs[j]==nil then
trgs[j]=vecV hits[j]=1 misses[j]=0 visible_targets[j]=true break
end
end
end
end
end
prevBeams=curBeams

local sendVec,slot_to_clear=nil,nil
for i=1,6 do
local j=(sendIndex+i-2)%6+1
if visible_targets[j] and trgs[j] and hits[j]>=2 then sendVec,slot_to_clear=trgs[j],j break end
end
if sendVec==nil then for i=1,6 do
local j=(sendIndex+i-2)%6+1
if trgs[j] and hits[j]>=2 then sendVec,slot_to_clear=trgs[j],j break end
end end
sendIndex=sendIndex%6+1

if sendVec~=nil then
output.setNumber(3,sendVec.x) output.setNumber(4,sendVec.y) output.setNumber(5,sendVec.z)
else
output.setNumber(3,0) output.setNumber(4,0) output.setNumber(5,0)
end
for i=1,6 do
if trgs[i] and misses[i]>8 then trgs[i]=nil hits[i]=nil misses[i]=nil end
end
end

function onDraw()
w,h=s.getWidth(),s.getHeight()
local vo=(const_rotation/(0.5*pi))*(h/4)
for i=1,6 do
if trgs[i]~=nil then
local status=visible_targets[i] and "V" or "M"
s.drawText(5,vo+i*8,string.format("%d:%s(%.0f,%.0f,%.0f)",i,status,trgs[i].x,trgs[i].y,trgs[i].z))
end
end
end