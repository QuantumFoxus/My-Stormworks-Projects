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
function lerp(a, b, t)
    return a + (b - a) * t
end
function clamp(value, min, max)
    return math.max(min, math.min(max, value))
end
function sign(x)
    if x > 0 then return 1 elseif x < 0 then return -1 else return 0 end
end
target_pos = { x = 0, y = 0, z = 0 }
start_pos = vec()
climbed = false
started = false
sbt = vec()
defAlt = property.getNumber("Default altitude")
dirfly = property.getNumber("Altitude to direct flight")
ticks = 0
function onTick()
    if started and ticks < 1000 then
        ticks = ticks + 1
    end
    radar_work = (input.getBool(1) and not started) or mag(sbt) < property.getNumber("Distance Radar") and mag(sbt) > 0 and started
    output.setBool(1, radar_work)
    output.setBool(2, (input.getNumber(28) ~= 0 or input.getNumber(29) ~= 0) and radar_work)
    if not climbed then
        start_pos = {
            x = input.getNumber(1),
            y = defAlt,
            z = input.getNumber(3)
        }
    end
    rocket_pos = {
        x = input.getNumber(1),
        y = input.getNumber(2),
        z = input.getNumber(3)
    }
    local ex, ey, ez = input.getNumber(4), input.getNumber(5), input.getNumber(6)
    local i, j, k = ijkfromeuler(ex, ey, ez)
    rocket_rotate = { x = i, y = j, z = k }
    if input.getNumber(30)~=0 or input.getNumber(31)~=0 or input.getNumber(32)~=0 then
        target_pos = {
            x = input.getNumber(30),
            y = input.getNumber(31),
            z = input.getNumber(32)
        }
    end
    sbt = subt(target_pos, rocket_pos)
    hor_dst = math.sqrt(sbt.x^2 + sbt.z^2)
	if target_pos.y > dirfly then
		defAlt = target_pos.y
	end
    target_pos_bal={
        x = target_pos.x,
        y = lerp(defAlt,target_pos.y,1-(clamp(hor_dst-100,0,defAlt)/defAlt)^0.4),
        z = target_pos.z
    }
    local azimuth, elevation = 0,0
    if rocket_pos.y >= start_pos.y then
        climbed = true
    end
    if climbed then
        azimuth, elevation = getAngle(target_pos_bal)
    else
        azimuth, elevation = getAngle(start_pos)
    end
    if started == true and input.getNumber(28) == 0 and input.getNumber(29) == 0 and ticks >= 60 then
        output.setNumber(1, azimuth * 1)
        output.setNumber(2, elevation * 1)
    else
        output.setNumber(1, 0)
        output.setNumber(2, 0)
    end
    if input.getBool(1) then
        started = true
    end


	output.setNumber(3, defAlt)
	output.setNumber(4, target_pos.y)
	output.setNumber(5, dirfly)
end

function getAngle(world_pos)
    local delta = subt(world_pos, rocket_pos)
    
    local local_pos = tolocal(delta, rocket_rotate.x, rocket_rotate.y, rocket_rotate.z)
    
    local azimuth = atan2(local_pos.x, local_pos.z)
    local elevation = atan2(local_pos.y, math.sqrt(local_pos.x^2 + local_pos.z^2))
    
    if math.abs(elevation) > math.pi / 2 then
        --azimuth = azimuth + math.pi
        --elevation = -elevation
    end
    
    return azimuth, elevation
end