sin,cos,tan,atan,rad,pi=math.sin,math.cos,math.tan,math.atan,math.rad,math.pi
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

function rad2Turns(rad)
    return rad / (2 * math.pi)
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


function clamp(s,t,u) return s<t and t or (s>u and u or s) end

fov = pi/4
trg = {}
function onTick()
    selfPos = vec(ign(1), ign(2), ign(3))
    local ex,ey,ez=ign(4),ign(5),ign(6)
    local i,j,k=ijkfromeuler(ex,ey,ez)
    selfRotation=vec(i,j,k)
    local centerPos = vec(ign(7), ign(8), ign(9))
    radarYaw, radarPitch = getAnglesOnTarget(centerPos, selfPos, selfRotation)
    radarPitch = (math.abs(radarYaw) < math.pi/2) and radarPitch or -radarPitch
    cameraYaw, cameraPitch = radarYaw, radarPitch
    radarYaw, radarPitch = clamp(radarYaw, -pi, pi), clamp(radarPitch, -pi/2, pi/2)
    cameraFov = rad((1-ign(14))*127)
    
    trg.azimuth, trg.elevation = radarYaw+ign(10), radarPitch-ign(11)
    trg.distance, trg.strength = ign(12), ign(13)
    local targetPoslocal = vec(
    trg.distance * sin(trg.azimuth),
    trg.distance * cos(trg.azimuth) * sin(trg.elevation),
    trg.distance * cos(trg.azimuth) * cos(trg.elevation)
)
    targetPosWorld = toworld(targetPoslocal, selfRotation.x, selfRotation.y, selfRotation.z)
    
    osn(30, rad2Turns(radarYaw))
    osn(31, -rad2Turns(radarPitch))
    osn(32, rad2Turns(fov))
end

function onDraw()
    local w,h = s.getWidth(), s.getHeight()
    local tanV = tan(cameraFov/2)
    local tanH = tanV * (w/h)

    local relYaw   = radarYaw   - cameraYaw
    local relPitch = radarPitch - cameraPitch

    if math.abs(relYaw) < pi/2 or math.abs(relPitch) < pi/2 then
        local cx = w/2 + (tan(relYaw)/tanH) * (w/2)
        local cy = h/2 - (tan(relPitch)/tanV) * (h/2)
    
        local k = tan(fov/2) / tanV
        local rw,rh = h*k, h*k
    
        s.sc(255,0,0)
        s.drawRect(cx-rw/2, cy-rh/2, rw, rh)
    end
    local trgYaw, trgPitch = getAnglesOnTarget(targetPosWorld, selfPos, selfRotation)
    local trgRelYaw   = trgYaw   - cameraYaw
    local trgRelPitch = trgPitch - cameraPitch
    if math.abs(trgRelYaw) < pi/2 or math.abs(trgRelPitch) < pi/2 then
        local cx = w/2 + (tan(trgRelYaw)/tanH) * (w/2)
        local cy = h/2 - (tan(trgRelPitch)/tanV) * (h/2)
    
        local k = 3 / tanV
        local rw,rh = k, k
    
        s.sc(0,255,0)
        s.drawRect(cx-rw/2, cy-rh/2, rw, rh)
    end
end