sin,cos,atan,rad=math.sin,math.cos,math.atan,math.rad
s=screen sc=s.setColor ign=input.getNumber osn=output.setNumber
pi=math.pi pi2=pi*2
function ijkfromeuler(ex,ey,ez)
local cx,sx,cy,sy,cz,sz=cos(ex),sin(ex),cos(ey),sin(ey),cos(ez),sin(ez)
return {x=cy*cz,y=cy*sz,z=-sy},{x=sx*sy*cz-cx*sz,y=sx*sy*sz+cx*cz,z=sx*cy},{x=cx*sy*cz+sx*sz,y=cx*sy*sz-sx*cz,z=cx*cy}
end
function tolocal(v,i,j,k) return {x=dot(v,i),y=dot(v,j),z=dot(v,k)} end
function mag(v) return math.sqrt((v.x or 0)^2+(v.y or 0)^2+(v.z or 0)^2) end
function dot(a,b) return (a.x or 0)*(b.x or 0)+(a.y or 0)*(b.y or 0)+(a.z or 0)*(b.z or 0) end
function vec(x,y,z) return {x=x or 0,y=y or 0,z=z or 0} end
function add(a,b) return vec((a.x or 0)+(b.x or 0),(a.y or 0)+(b.y or 0),(a.z or 0)+(b.z or 0)) end
function multf(a,n) return vec((a.x or 0)*n,(a.y or 0)*n,(a.z or 0)*n) end
function subt(a,b) return vec(a.x-b.x,a.y-b.y,a.z-b.z) end
function toworld(v,i,j,k) return add(add(multf(i,v.x),multf(j,v.y)),multf(k,v.z)) end
function rotate3(p,pitch,yaw,roll)
local cp,sp=cos(pitch),sin(pitch)
local x1,y1,z1=p.x,p.y*cp-p.z*sp,p.y*sp+p.z*cp
local cy,sy=cos(yaw),sin(yaw)
local x2,z2=x1*cy+z1*sy,-x1*sy+z1*cy
local cr,sr=cos(roll),sin(roll)
return vec(x2*cr-y1*sr,x2*sr+y1*cr,z2)
end
function atan2(y,x)
if x>0 then return atan(y/x)elseif x<0 then return atan(y/x)+(y>=0 and pi or -pi)elseif y>0 then return pi/2 elseif y<0 then return -pi/2 end return 0
end
function pn(n,d) local v=property.getNumber(n) return v==0 and d or v end
MAX_TRGS=30 timer=0
MAX_H_FOV=rad(pn("MAX_HORIZONTAL_FOV",40))
MAX_V_FOV=rad(pn("MAX_VERTICAL_FOV",28))
MAX_D=pn("MAX DISTANCE",100000)
MAX_DIST_ERR=pn("Radar MAX distance error",300)
TTL=pn("Time to delete",600)
ONLINE_MODE=property.getBool("Online targets update")
ABG_A=0.9 trgs={} selTar=0 outI=1

function abg_update(trg,meas_pos,dt)
if dt<=3 and dt~=-1 then return false end
if dt==-1 then dt=1 end
local a=ABG_A
local alpha,beta,gamma=a,2*(1-a),(1-a)*(1-a)
if dt<5 then gamma=0 end
local x_pred=add(add(trg.pos,multf(trg.vel,dt)),multf(trg.acc,0.5*dt*dt))
local v_pred=add(trg.vel,multf(trg.acc,dt))
local r=subt(meas_pos,x_pred)
trg.pos=add(x_pred,multf(r,alpha))
trg.vel=add(v_pred,multf(r,beta/dt))
trg.acc=add(trg.acc,multf(r,gamma/(dt*dt)))
return true
end
function pToS(world_pos,w,h)
local local_pos=tolocal(subt(world_pos,rr_pos),cam_i,cam_j,cam_k)
local azimuth=atan2(local_pos.x,local_pos.z)
local elevation=atan2(local_pos.y,math.sqrt(local_pos.x^2+local_pos.z^2))
local x=w/2+(azimuth/MAX_H_FOV)*w/2
local y=h/2-(elevation/MAX_V_FOV)*h/2
if x<-w*.5 or x>w*1.5 or y<-h*.5 or y>h*1.5 then return end
return x,y
end
function bits(n)
local bytes=string.pack(">f",n) local bitsNumber=0
for i=1,#bytes do bitsNumber=bitsNumber*256+bytes:byte(i) end
local s={} for i=0,31 do s[i+1]=(bitsNumber&(1<<i))~=0 end
return s
end
bools={} prsdNw=false

function onTick()
bools=bits(ign(21))
clkPos=vec(ign(22),ign(23))
clck=bools[4] or bools[5]
rr_pos=vec(ign(1),ign(2),ign(3))
local rx,ry,rz=ijkfromeuler(ign(4),ign(5),ign(6))
rrRot=vec(rx,ry,rz)
camRot=vec(ign(7)*pi2+pi/2,ign(8)*pi2,0)
local cli,clj,clk=rotate3(vec(1,0,0),-camRot.y,camRot.x,0),rotate3(vec(0,1,0),-camRot.y,camRot.x,0),rotate3(vec(0,0,1),-camRot.y,camRot.x,0)
cam_i,cam_j,cam_k=toworld(cli,rrRot.x,rrRot.y,rrRot.z),toworld(clj,rrRot.x,rrRot.y,rrRot.z),toworld(clk,rrRot.x,rrRot.y,rrRot.z)

if ONLINE_MODE then
for i=1,MAX_TRGS do local t=trgs[i] if t then local v=add(t.vel,t.acc) if mag(v)>=.5 then t.vel=v t.pos=add(t.pos,v) end end end
end

for i=9,18,3 do
if math.abs(ign(i))>0.001 or math.abs(ign(i+1))>0.001 or math.abs(ign(i+2))>0.001 then
local meas=vec(ign(i),ign(i+1),ign(i+2))
local best,bestDist=nil,MAX_DIST_ERR
for j=1,MAX_TRGS do
local trg=trgs[j]
if trg then
local dt=timer-trg.time
local pred=trg.pos
if ONLINE_MODE and dt>3 then pred=add(add(trg.pos,multf(trg.vel,dt)),multf(trg.acc,0.5*dt*dt)) end
local mgnV=mag(trg.vel)
local dst_check=ONLINE_MODE and mgnV>0.5 and MAX_DIST_ERR*2*mgnV or MAX_DIST_ERR
local dist=mag(subt(meas,pred))
if dist<dst_check and dist<bestDist then best,bestDist=j,dist end
end end
if best then
local trg=trgs[best]
if abg_update(trg,meas,timer-trg.time) then trg.time=timer end
trg.radar=(i-9)/3
else
for idx=1,MAX_TRGS do
if trgs[idx]==nil then trgs[idx]={pos=meas,vel=vec(),acc=vec(),time=timer,radar=(i-9)/3} break end
end end
end end

for a=1,MAX_TRGS-1 do if trgs[a] then for b=a+1,MAX_TRGS do
if trgs[b] and mag(subt(trgs[a].pos,trgs[b].pos))<MAX_DIST_ERR then
if trgs[b].time>trgs[a].time then trgs[a]=trgs[b] end
trgs[b]=nil if selTar==b then selTar=a end
end end end end

if bools[1] and not prsdNw and selTar<MAX_TRGS then selTar=selTar+1 end
if bools[2] and not prsdNw and selTar>1 then selTar=selTar-1 end
selTar=bools[3] and 0 or selTar
prsdNw=bools[1] or bools[2] or bools[3]

for i=MAX_TRGS,1,-1 do if trgs[i] and timer>trgs[i].time+TTL*60 then trgs[i]=nil end end

if selTar>0 and trgs[selTar] then
local tp=trgs[selTar].pos
osn(21,tp.x) osn(22,tp.y) osn(23,tp.z) osn(24,selTar)
else osn(24,0) end

for i=0,4 do local trg=trgs[outI+i]
if trg then osn(1+i*4,outI+i) osn(2+i*4,trg.pos.x) osn(3+i*4,trg.pos.y) osn(4+i*4,trg.pos.z) end end
osn(32,selTar)
outI=outI+5>MAX_TRGS and 1 or outI+5
timer=timer+1
if mvTimer>0 and mvTimer<timeMvMap then local q=mvTimer/timeMvMap mapX=OmapX+(NmapX-OmapX)*q mapY=OmapY+(NmapY-OmapY)*q mvTimer=mvTimer+1 end
end

clckd=false mapX,mapY=0,0 mzoom=9 mvTimer,timeMvMap=0,30
menu,menuX,track,move,center=0,999,false,false,false
function inb(x,y,w,h) return clkPos.x>=x and clkPos.x<=x+w and clkPos.y>=y and clkPos.y<=y+h end
function button(x,a,t) sc(a and 0 or 60,a and 180 or 60,a and 0 or 60) s.drawRectF(bx+x,by,11,9) sc(255,255,255) s.drawText(bx+x+3,by+2,t) end

function onDraw()
w,h=s.getWidth(),s.getHeight()
if w==256 then
for i=1,MAX_TRGS do
local t=trgs[i]
if t and rr_pos then
sc(100,100,100)
if selTar>0 and selTar==i then sc(255,0,0) end
s.drawText(5,i*8,"T "..i..": "..math.floor(mag(subt(rr_pos,t.pos))).." M | R-r: "..t.radar)
local x,y=pToS(t.pos,w,h)
if x and y then
local distance=mag(subt(t.pos,rr_pos))
local size=math.max(5,10*(1-distance/MAX_D))*0.6
sc(100,100,100)
if selTar>0 and selTar==i then sc(255,0,0) s.drawCircle(x,y,size+3) end
s.drawRect(x-size,y-size,size*2,size*2)
s.drawText(x-(#tostring(i))*4+3,y-2,i)
s.drawText(x-(#tostring(math.floor(distance)))*2+1,y+size+8,math.floor(distance))
end end end
else
if mapX==0 and mapY==0 and rr_pos then mapX,mapY=rr_pos.x,rr_pos.z end
if rr_pos then
if move and lastRX then mapX=mapX+rr_pos.x-lastRX mapY=mapY+rr_pos.z-lastRZ end
lastRX,lastRZ=rr_pos.x,rr_pos.z
if track then mapX,mapY=rr_pos.x,rr_pos.z end end
mw,mh=68,12 bx=(w-mw)/2
menuX=menuX+(h-menu*mh-menuX)*.35
by=menuX<h-2 and menuX or h-8
open=menuX<h-2
plus=clck and open and inb(bx+8,by,12,9)
minus=clck and open and inb(bx+20,by,12,9)
if plus then mzoom=math.max(1,mzoom-.1)
elseif minus then mzoom=math.min(30,mzoom+.1)
elseif clck and not clckd and open and inb(bx+32,by,12,9) then track=not track
elseif clck and not clckd and open and inb(bx+44,by,12,9) then move=not move
elseif clck and not clckd and open and inb(bx+56,by,12,9) then center=not center
elseif clck and not clckd and inb(bx,by,8,8) then menu=1-menu
elseif clck and not clckd and not inb(bx,by,open and mw or 8,open and mh or 8) then
OmapX,OmapY=mapX,mapY
NmapX,NmapY=map.screenToMap(mapX,mapY,mzoom,w,h,clkPos.x,clkPos.y)
mvTimer=1 end
if center and trgs[selTar] then mapX,mapY=trgs[selTar].pos.x,trgs[selTar].pos.z end
if rr_pos then s.drawMap(mapX,mapY,mzoom) end
clckd=clck
if rr_pos then local x,y=map.mapToScreen(mapX,mapY,mzoom,w,h,rr_pos.x,rr_pos.z) sc(0,0,255) s.drawCircle(x,y,3) end
for i=1,MAX_TRGS do local tar=trgs[i] if tar then
local sX,sY=map.mapToScreen(mapX,mapY,mzoom,w,h,tar.pos.x,tar.pos.z)
if selTar>0 and selTar==i then sc(255,0,0) s.drawCircle(sX,sY,5) end
sc(0,0,0,255) s.drawText(sX-1,sY-2,i) end end
sc(0,0,0,220) s.drawRectF(bx,by,open and mw or 8,open and mh or 8)
sc(255,255,255) s.drawText(bx+3,by+2,menu and "^" or "v")
if open then button(8,plus,"+") button(20,minus,"-") button(32,track,"T") button(44,move,"M") button(56,center,"C") end
end
end