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
function clamp(value, min, max)
    return value < min and min or (value > max and max or value)
end
function sign(value)
    return value > 0 and 1 or (value < 0 and -1 or 0)
end
function normalizeAngle(angle)
    return (angle + math.pi) % (2 * math.pi) - math.pi
end

restrictedzones = {
    {90, 180, -90, 90},
    {-180, -90, -90, 90},
}

reload_timer = 0

function onTick()
    max_ammo = property.getNumber("Max ammo")

    rocket_pos = {
        x = input.getNumber(1), -- X
        y = input.getNumber(2), -- Y
        z = input.getNumber(3)  -- Z
    }
    local rx, ry, rz = ijkfromeuler(input.getNumber(4), input.getNumber(5), input.getNumber(6))
    rocket_rotate = {
        x = rx,
        y = ry,
        z = rz
    }
    target = {
        x = input.getNumber(7), -- X
        y = input.getNumber(8), -- Y
        z = input.getNumber(9)  -- Z
    }
    ammo_count = input.getNumber(10)
    turret_ring = math.abs(input.getNumber(11)) * math.pi * 2
    turret_ring = normalizeAngle(turret_ring)   
    fire = input.getBool(1)
    local azimuth, elevation = getAngle(target)
    elevation = clamp(elevation, -0.03, 1)
    azimuth = clamp(math.abs(azimuth) ^ 0.7 * sign(azimuth), -1, 1)
    if ammo_count == 0 then
        reloading = true
    end
    if ammo_count >= max_ammo then
        if reloading then
            reload_timer = 60
        end
        reloading = false
    end

    if reload_timer > 0 then
        reload_timer = reload_timer - 1
        fire = false
    end

    if reloading then
        fire = false
        elevation = 0
        azimuth = -turret_ring
    end

    fire = fire and not isInRestrictedZone(turret_ring, elevation, restrictedzones)
    output.setBool(1, fire)
    output.setBool(2, reloading)
    output.setNumber(1, azimuth) -- yaw
    output.setNumber(2, elevation / math.pi * 2) -- pitch
end

function getAngle(world_pos)
    local delta = subt(world_pos, rocket_pos)
    
    local local_pos = tolocal(delta, rocket_rotate.x, rocket_rotate.y, rocket_rotate.z)
    
    local azimuth = atan2(local_pos.x, local_pos.z)
    local elevation = atan2(local_pos.y, math.sqrt(local_pos.x^2 + local_pos.z^2))
    
    if math.abs(elevation) > math.pi / 2 then
        azimuth = azimuth + math.pi
        elevation = -elevation
    end
    
    return azimuth, elevation
end

function isInRestrictedZone(turret_ring, elevation, restricted_zones)
    local horizontal_angle = turret_ring * 180 / math.pi
    local vertical_angle = elevation * 180 / math.pi

    -- horizontal_angle = (horizontal_angle % 360 + 360) % 360

    for _, zone in ipairs(restricted_zones) do
        local h_start, h_end, v_start, v_end = zone[1], zone[2], zone[3], zone[4]

        if horizontal_angle >= h_start and horizontal_angle <= h_end and
           vertical_angle >= v_start and vertical_angle <= v_end then
            return true
        end
    end

    return false
end