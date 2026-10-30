sin,cos,atan,rad,deg,pi2=math.sin,math.cos,math.atan,math.rad,math.deg,math.pi*2
s=screen
ign,osn=input.getNumber,output.setNumber
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

w=200
h=100
trgs={}

radar_err={0,0.25,1}

rocket_pos=vec(0,0,0)
rocket_rotate=vec(0,0,0)--pitch,yaw,roll()
last_rpos=vec(0,0,0)
az=0
el=0
last_tar_pos=vec(0,0,0)
v1 = 0.05
v2 = 0.95
F={}
to_out={0,0}
for z=1,25 do
F[z] = {0, 0, 1, 0, 0, 0}
end
function filter()
	for i=1,25,1 do
		F[i][1] = F[i][3] + v1
		F[i][2] = F[i][1]/(F[i][1] + v2)
		F[i][3] = (1 - F[i][2])*F[i][1]
		F[i][5] = F[i][4]
		F[i][4] = F[i][6]
        if i>23 then
            F[i][6] = F[i][2]*(to_out[i-23] - F[i][5]) + F[i][4]
            osn(i-23,F[i][6])
        else
            F[i][6] = F[i][2]*(ign(i) - F[i][5]) + F[i][4]

        end
	end
end

function onTick()
    --
    filter()
    omult=ign(31)
    navc=property.getNumber("NAVC")
    last_rpos=rocket_pos
    rocket_pos=vec(ign(24),ign(25),ign(26))

    local rx, ry, rz=ijkfromeuler(ign(27), ign(28), ign(29))
    rocket_rotate=vec(rx, ry, rz)
    -- for i=0, 5, 1 do
        if input.getBool(1) and ign(1) > 0 then
        -- if math.abs(ign(1))>0.01 then
            local distance=F[1][6]
            local azimuth=F[2][6] * pi2
            local elevation=F[3][6] * pi2
            local x=distance * cos(elevation) * sin(azimuth)+radar_err[1]
            local z=distance * cos(elevation) * cos(azimuth)+radar_err[3]
            local y=distance * sin(elevation)+radar_err[2]
            local glob_pos=toworld({ x=math.floor(x), y=math.floor(y), z=math.floor(z) }, rocket_rotate.x, rocket_rotate.y, rocket_rotate.z)
            -- print(glob_pos)
            local world_pos=vec(
                glob_pos.x+rocket_pos.x, glob_pos.y+rocket_pos.y, glob_pos.z+rocket_pos.z)
            if trgs[1]~=nil and trgs[1].world_pos~=nil then
                trgs[1].world_pos=world_pos
            else
                trgs[1]={
                    world_pos=world_pos
                }
            end
        else
            -- targets[1]=nil
        end
    -- end

    -- for i=5,0,-1 do
    i=1
        if trgs[i] ~=nil and mag(trgs[i].world_pos)>1 then
            local tar_spd=subt(trgs[i].world_pos,last_tar_pos)
            local r_spd=mag(subt(rocket_pos,last_rpos))
            if r_spd <=1 then
            	r_spd=5
            end
            --local interc,cntt=targets[i].world_pos, 5
            local interc,cntt=InterceptPN(trgs[i].world_pos,tar_spd,rocket_pos,r_spd)
            --local interc,cntt=ComputeZEM3D(targets[i].world_pos, tar_spd, radar_pos, r_spd, 0.1)
		
            local dx=interc.x - rocket_pos.x
            local dy=interc.y - rocket_pos.y
            local dz=interc.z - rocket_pos.z
            local local_pos=tolocal(vec(dx,dy,dz),rocket_rotate.x,rocket_rotate.y,rocket_rotate.z)
            az=atan2(local_pos.x,local_pos.z)
            el=atan2(local_pos.y,math.sqrt(local_pos.x^2+local_pos.z^2))
            osn(3,trgs[i].world_pos.x)
            osn(4,trgs[i].world_pos.y)
            osn(5,trgs[i].world_pos.z)
            last_tar_pos=vec(trgs[i].world_pos.x,trgs[i].world_pos.y,trgs[i].world_pos.z)
            -- break
        else
        end
            to_out[1] = math.abs(clamp(az,-1,1))^0.3*sign(az)*omult
            to_out[2] = math.abs(clamp(el,-1,1))^0.3*sign(el)*omult
    -- end
end

function ComputeZEM3D(tar, tarVel, rPos, rVel, maxAngle)
    local iMax=1
    local iErr=10000
    local cnt=0
    local cntMax=10
    local interP=tar
    local time=0
    maxAngle=maxAngle or math.rad(45)  --   45 
    
    --    3D

    local function clampDirection(toTarget, currentDir, maxAngle)
        local dirTarget=norm(toTarget)
        local dirCurrent=norm(currentDir)
        local cosTheta=dot(dirTarget, dirCurrent)
        
        if cosTheta > math.cos(maxAngle) then
            return currentDir
        end
        
        --   
        local axis=crs(dirTarget, dirCurrent)
        if mag(axis) < 1e-6 then
            return dirTarget * mag(currentDir)
        end
        axis=norm(axis)
        
        --      
        local newDir={
            x=dirTarget.x * math.cos(maxAngle),
            y=dirTarget.y * math.cos(maxAngle),
            z=dirTarget.z * math.cos(maxAngle)
        }
        local tangent=crs(axis, dirTarget)
        newDir.x=newDir.x+tangent.x * math.sin(maxAngle)
        newDir.y=newDir.y+tangent.y * math.sin(maxAngle)
        newDir.z=newDir.z+tangent.z * math.sin(maxAngle)
        
        return multf(norm(newDir),mag(currentDir))
    end

    while cnt < cntMax and iErr > iMax do
        local dx=interP.x-rPos.x
        local dy=interP.y-rPos.y
        local dz=interP.z-rPos.z
        local dst=math.sqrt(dx*dx+dy*dy+dz*dz)
        
        --      
        local time=dst/rVel
        
        --    
        local newTar=vec(
            tar.x+tarVel.x * time * navc,
            tar.y+tarVel.y * time * navc,
            tar.z+tarVel.z * time * navc
        )
        
        --    
        local toTarget=vec(tar.x-rPos.x, tar.y-rPos.y, tar.z-rPos.z)
        local toInter=vec(interP.x-rPos.x, interP.y-rPos.y, interP.z-rPos.z)
        local correctedDir=clampDirection(toTarget, toInter, maxAngle)
        interP=vec(
            rPos.x+correctedDir.x,
            rPos.y+correctedDir.y,
            rPos.z+correctedDir.z
        )
        
        --  
        iErr=math.sqrt((newTar.x-interP.x)^2+(newTar.y-interP.y)^2+(newTar.z-interP.z)^2)
        interP=newTar
        cnt=cnt+1
    end
    
    --   
    local dir=norm(vec(interP.x-rPos.x, interP.y-rPos.y, interP.z-rPos.z))
    local rocketFuture=vec(
        rPos.x+dir.x * rVel * time,
        rPos.y+dir.y * rVel * time,
        rPos.z+dir.z * rVel * time
    )
    
    --   ZEM
    return vec(
        interP.x-rocketFuture.x,
        interP.y-rocketFuture.y,
        interP.z-rocketFuture.z
    )
end

function InterceptPN(tar, tarVel, rPos, rVel)

	local iMax=3
	local iErr=1000
	local cnt=0
	local cntMax=1
	local interP=tar
	while cnt < cntMax and iErr > iMax do
		local dst=mag(subt(interP,rPos))
		local time=dst/rVel
		local newresP=vec(tar.x+tarVel.x * time * navc, tar.y+tarVel.y * time * navc, tar.z+tarVel.z * time * navc)
		iErr=mag(subt(newresP, interP))
		interP=newresP
		cnt=cnt+1
		-- print(iErr)
	end

	return interP,time
end

function clamp(v,minv,maxv)
	return v > maxv and maxv or v < minv and minv or v	
end

function sign(a)
    return a>0 and 1 or a<0 and -1 or 0
    
end