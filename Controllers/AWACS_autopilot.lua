sin,cos,atan,rad=math.sin,math.cos,math.atan,math.rad
s=screen
ign = input.getNumber
igb = input.getBool
osn = output.setNumber
osb = output.setBool
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

function getAnglesOnTarget(world_pos, self_pos, self_rotation)
local delta = subt(world_pos, self_pos)
local local_pos = tolocal(delta, self_rotation.x, self_rotation.y, self_rotation.z)
local azimuth = atan2(local_pos.x, local_pos.z)
local elevation = atan2(local_pos.y, math.sqrt(local_pos.x^2 + local_pos.z^2))
if math.abs(elevation) > math.pi / 2 then
    azimuth = azimuth + math.pi
    elevation = -elevation
end
return azimuth, elevation
end



angle_step = rad(property.getNumber("Angle step") or 15)

function onTick()
    plane_pos=vec(
    ign(5),
    ign(6),
    ign(7))

    local trgCenter = vec(ign(13),ign(14),ign(15))

    local ex,ey,ez=ign(8),ign(9),ign(10)
    local i,j,k=ijkfromeuler(ex,ey,ez)
    plane_rotation=vec(i,j,k)

    local setAlt = ign(11) ~= 0 and ign(11) or 1000
    local setDist = ign(12) ~= 0 and ign(12) or 2500
    local is_counterclockwise = igb(1)

    local diff = subt(plane_pos, trgCenter)
    local curAngle = atan2(diff.x,diff.z)
    local angle_stepF = is_counterclockwise and -angle_step or angle_step
    local trgAngle = curAngle + angle_stepF
    local trgPoint = vec(trgCenter.x + sin(trgAngle) * setDist, trgCenter.y + setAlt, trgCenter.z + cos(trgAngle) * setDist)
    local azimuth, elevation = getAnglesOnTarget(trgPoint, plane_pos, plane_rotation)
    local diff2 = subt(trgCenter, trgPoint)
    local roll_cmd = -atan2(diff2.y, math.sqrt(diff2.x^2 + diff2.z^2))
    roll_cmd = is_counterclockwise and -roll_cmd or roll_cmd
    osn(1,roll_cmd)
    osn(2,-elevation)
    osn(3,azimuth)

    osn(11,diff.x)
    osn(12,diff.y)
    osn(13,diff.z)
    osn(14, math.deg(roll_cmd))

end
