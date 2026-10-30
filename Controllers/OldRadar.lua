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
    return {x=dot(v,i),y=dot(v,j),z=dot(v,k)}
end
function toworld(v,i,j,k)
    return add(add(multf(i,v.x),multf(j,v.y)),multf(k,v.z))
end
function mag(v)
    return math.sqrt((v.x or 0)^2+(v.y or 0)^2+(v.z or 0)^2)
end
function dot(a,b)
    return (a.x or 0)*(b.x or 0)+(a.y or 0)*(b.y or 0)+(a.z or 0)*(b.z or 0)
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

function onTick()
    rr_pos = vec(
        ign(1),
        ign(2),
        ign(3)
    )
    local rx, ry, rz = ijkfromeuler(ign(4), ign(5), ign(6))
    rrRot = {
        rx, ry, rz
    }

    trg = vec(ign(31) * pi2, ign(30) * pi2)
    if ign(32) ~= 0 then
        dst = ign(32)
        local x = dst * cos(trg.y) * sin(trg.x)
        local z = dst * cos(trg.y) * cos(trg.x)
        local y = dst * sin(trg.y)
        local glob_pos = toworld({x=x,y=y,z=z}, rrRot[1], rrRot[2], rrRot[3])
        world_pos = add(glob_pos, rr_pos)
    end
    if(world_pos ~= nil) then
        osn(1, world_pos.x)
        osn(2, world_pos.y)
        osn(3, world_pos.z)
    end
end
