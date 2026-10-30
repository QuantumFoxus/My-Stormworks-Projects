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
function onTick()
    rocket_pos = {
        x = input.getNumber(1), -- X
        y = input.getNumber(2), -- Y
        z = input.getNumber(3)  -- Z
    }
    local ex, ey, ez = input.getNumber(4), input.getNumber(5), input.getNumber(6)
    local i, j, k = ijkfromeuler(ex, ey, ez)
    rocket_rotate = { x = i, y = j, z = k }

    distance = input.getNumber(32)
    if not distance or distance == 0 then
        distance = 1000
    end
    local res = getCameraTarget(rocket_pos, rocket_rotate, distance)
    output.setNumber(1, res.x)
    output.setNumber(2, res.y)
    output.setNumber(3, res.z)
end

function getCameraTarget(radar_pos, turret_rotate, distance)
    local direction = norm(turret_rotate.z)
    local target_offset = multf(direction, distance)
    local target_pos = add(radar_pos, target_offset)
    return target_pos
end
