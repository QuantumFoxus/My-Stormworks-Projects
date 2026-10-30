sin,cos,atan,rad,deg=math.sin,math.cos,math.atan,math.rad,math.deg
local pi=math.pi
local pi2=pi*2
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
return multf(v,1/mag(v))
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
function euler_from_ijk(i,j,k)
local roll=atan2(j.z,i.z)
local pitch=atan2(-k.z,math.sqrt(k.x^2+k.y^2))
local yaw=atan2(k.y,k.x)
return roll,pitch,yaw
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
return {x=x3,y=y3,z=z3}
end

horizont={}
hor2={}
widthAgle=rad(property.getNumber("widthAgle")) or rad(40)
heightAgle=rad(property.getNumber("heightAgle")) or rad(180)
heightStep=rad(property.getNumber("heightStep")) or rad(10)
sideLineHeight=rad(property.getNumber("sideLineHeight")) or rad(2)
sideTextAngle=rad(property.getNumber("sideTextAngle")) or rad(3)
dirArrLen=property.getNumber("Direction Arrow Lenght") or 20
function onTick()
if not horizont.points then
horizont=create_horizont(widthAgle,heightAgle,heightStep,sideLineHeight,sideTextAngle)
end
plane_pos={
input.getNumber(24),
input.getNumber(25),
input.getNumber(26)
}
local rx,ry,rz=ijkfromeuler(input.getNumber(27),input.getNumber(28),input.getNumber(29))
plane_rot={
x=rx,y=ry,z=rz
}
camRot={
    x=input.getNumber(4)*pi2,
    y=input.getNumber(8)*pi2
  }
  local cli=rotate3(vec(1,0,0),-camRot.y,camRot.x,0)
  local clj=rotate3(vec(0,1,0),-camRot.y,camRot.x,0)
  local clk=rotate3(vec(0,0,1),-camRot.y,camRot.x,0)
  camera_i=toworld(cli,plane_rot.x,plane_rot.y,plane_rot.z)
  camera_j=toworld(clj,plane_rot.x,plane_rot.y,plane_rot.z)
  camera_k=toworld(clk,plane_rot.x,plane_rot.y,plane_rot.z)

  camera_azimuth=atan2(camera_k.x,camera_k.z)
  for i=1,#horizont.points,1 do
    hor2[i]=rotate3(horizont.points[i],0,camera_azimuth,0)
  end
end

MAX_H_FOV=rad(property.getNumber("MAX_HORIZONTAL_FOV")) or rad(40)
MAX_V_FOV=rad(property.getNumber("MAX_VERTICAL_FOV")) or rad(28)
function eToS(world_pos,w,h,no_limit)
  local no_limit=no_limit or false
  local local_pos=tolocal(world_pos,camera_i,camera_j,camera_k) -- без rot и camera_rot!
  local azimuth=atan2(local_pos.x,local_pos.z)
  local elevation=atan2(local_pos.y,math.sqrt(local_pos.x^2+local_pos.z^2))
  local x=w/2+(azimuth/MAX_H_FOV)*w/2
  local y=h/2-(elevation/MAX_V_FOV)*h/2
  if(x<-w*0.5 or x>w*1.5 or y<-h*0.5 or y>h*1.5)and not no_limit then
    return nil,nil
  end
  return x,y
end

function onDraw()
local w=s.getWidth()
local h=s.getHeight()
s.sc(0,255,0)
s.drawLine(0,h*0.05,0,0)
s.drawLine(w-1,h*0.05,w-1,0)
s.drawLine(0,h*0.95,0,h-1)
s.drawLine(w-1,h*0.95,w-1,h-1)
s.drawLine(w*0.05,0,0,0)
s.drawLine(w*0.05,h-1,0,h-1)
s.drawLine(w*0.95,0,w-1,0)
s.drawLine(w*0.95,h-1,w-1,h-1)
s.sc(255,255,0)
local camVec_local=vec(0,0,1)
local camVec_global=toworld(camVec_local,plane_rot.x,plane_rot.y,plane_rot.z)
local x_cam_local,y_cam_local=eToS(camVec_global,w,h,true)
s.drawCircle(x_cam_local,y_cam_local,3)
if x_cam_local and(x_cam_local>w or x_cam_local<0 or y_cam_local>h or y_cam_local<0)then
local vecDir=norm(vec(x_cam_local-w/2,h/2-y_cam_local,0))
vecDir=multf(vecDir,dirArrLen)
s.drawLine(w/2,h/2,w/2+vecDir.x,h/2-vecDir.y)
local angle=atan2(-vecDir.y,-vecDir.x)
s.drawLine(w/2+vecDir.x,h/2-vecDir.y,w/2+vecDir.x+5*cos(angle+pi/6),h/2-vecDir.y-5*sin(angle+pi/6))
s.drawLine(w/2+vecDir.x,h/2-vecDir.y,w/2+vecDir.x+5*cos(angle-pi/6),h/2-vecDir.y-5*sin(angle-pi/6))
end
for i=1,#hor2,horizont.line_len do
local x1,y1=eToS(hor2[i],w,h)
local x2,y2=eToS(hor2[i+1],w,h)
local x3,y3=eToS(hor2[i+2],w,h)
local x4,y4=eToS(hor2[i+3],w,h)
local x_text_left,y_text_left=eToS(hor2[i+4],w,h)
local x_text_right,y_text_right=eToS(hor2[i+5],w,h)
x_text_left=x_text_left and x_text_left-5 or nil
if i==1 then
s.sc(255,255,0)
elseif(i-1)/horizont.line_len%2==0 then
s.sc(0,255,0)
else
s.sc(255,0,0)
end
if x1 and x2 and x3 and x4 then
s.drawLine(x1,y1,x2,y2)
s.drawLine(x2,y2,x3,y3)
s.drawLine(x3,y3,x4,y4)
local angle=horizont.angles[(i-1)/horizont.line_len+1]*(180/pi)+0.5
s.drawText(x_text_left,y_text_left,-math.floor(angle))
s.drawText(x_text_right,y_text_right,-math.floor(angle))
end
end
end

function create_horizont(widthAgle,heightAgle,heightStep,sideLineHeight,sideTextAngle)
hor={}
hor.line_len=6
null_vec={x=0,y=0,z=1}
hor.points={}
hor.widthAgle=widthAgle or rad(40)
hor.heightAgle=heightAgle or rad(180)
hor.heightStep=heightStep or rad(10)
hor.sideLineHeight=sideLineHeight or rad(2)
hor.sideTextAngle=sideTextAngle or rad(3)
hor.angles={}
for i=0,hor.heightAgle/2*100,hor.heightStep*100 do
for j,angle in ipairs({i/100,-i/100})do
if angle==0 or i==0 then angle=0 end
if j==2 and angle==0 then break end
local sideagle=angle>0 and -hor.sideLineHeight or angle<0 and hor.sideLineHeight or 0
local sidesideangle=angle==0 and hor.sideLineHeight*2 or 0
table.insert(hor.points,rotate3(null_vec,angle+sideagle,-hor.widthAgle/2-sidesideangle,0))
table.insert(hor.points,rotate3(null_vec,angle,-hor.widthAgle/2-sidesideangle,0))
table.insert(hor.points,rotate3(null_vec,angle,hor.widthAgle/2+sidesideangle,0))
table.insert(hor.points,rotate3(null_vec,angle+sideagle,hor.widthAgle/2+sidesideangle,0))
table.insert(hor.points,rotate3(null_vec,angle,-hor.widthAgle/2-sidesideangle-hor.sideTextAngle,0))
table.insert(hor.points,rotate3(null_vec,angle,hor.widthAgle/2+sidesideangle+hor.sideTextAngle,0))
table.insert(hor.angles,angle)
end
end
return hor
end