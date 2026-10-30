sin,cos,atan,rad,deg,pi2=math.sin,math.cos,math.atan,math.rad,math.deg,math.pi*2
s=screen
ign,osn=input.getNumber,output.setNumber
MAX_H_FOV=rad(40)
MAX_V_FOV=rad(28)
function vec(x,y,z)
    return {x=x or 0,y=y or 0,z=z or 0}
end
function mag(v)
return math.sqrt(v.x^2+v.y^2+v.z^2)
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

las={}
tar={}
ang=vec(0,0,0)
itt=1
max_itt=90
max_dist=50
max_count=max_itt*0.7
trg=vec(0,0,0)
function onTick()
    camRot={
        ign(31)*pi2,--x
        ign(32)*pi2--y
        }
    ang=vec(ign(1)*pi2,ign(2)*pi2)
    for i=3,9 do
        las[i] = ign(i)
    end
    for index, value in pairs(las) do
        local x = value * cos(ang.y) * sin(ang.x)
        local z = value * cos(ang.y) * cos(ang.x)
        local y = value * sin(ang.y)
        local pos= vec(x,y,z)
        tar[itt]={pos=pos,mag=mag(pos)}
        itt = itt >= max_itt and 1 or itt+1
    end
	for index,value in pairs(tar) do
        detect_count = 0
		for index2,value2 in pairs(tar) do
			if math.abs(value.mag - value2.mag) > max_dist then
				detect_count = detect_count+1
			end
		end
        if detect_count > max_count then
            trg=value.pos
            break
        end
	end
    -- print("----------")
    -- print(trg)
end

function onDraw()
    w=s.getWidth()
    h=s.getHeight()
    local azimuth=atan2(trg.x,trg.z) - camRot[1]
    local elevation=atan2(trg.y,math.sqrt(trg.x^2+trg.z^2)) - camRot[2]

    local x=w/2+(azimuth/(MAX_H_FOV))*w/2
    local y=h/2-(elevation/(MAX_V_FOV))*h/2
    s.drawCircle(x,y,3)
end
