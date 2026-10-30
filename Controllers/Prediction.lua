ign = input.getNumber
osn = output.setNumber
igb = input.getBool
osb = output.setBool
sin, cos, atan, pi = math.sin, math.cos, math.atan, math.pi

function dot(m,n) return m.x*n.x+m.y*n.y+m.z*n.z end
function vec(o,p,q) return {x=o or 0,y=p or 0,z=q or 0} end
function multf(m,r) return {x=m.x*r,y=m.y*r,z=m.z*r} end
function add(m,n) return {x=m.x+n.x,y=m.y+n.y,z=m.z+n.z} end
function invert(m) return multf(m,-1) end
function subt(m,n) return add(m,invert(n)) end
function mag(s) return math.sqrt(s.x*s.x+s.y*s.y+s.z*s.z) end

function atan2(p,o)
	if o>0 then return atan(p/o) end
	if o<0 and p>=0 then return atan(p/o)+pi end
	if o<0 and p<0 then return atan(p/o)-pi end
	if o==0 and p>0 then return pi/2 end
	if o==0 and p<0 then return -pi/2 end
	return 0
end

function wrapAngle(a)
	while a > pi do a = a - 2*pi end
	while a <= -pi do a = a + 2*pi end
	return a
end

function vecAngles(v)
	local horMag = math.sqrt(v.x*v.x + v.y*v.y)
	local yaw = atan2(v.y, v.x)
	local pitch = atan2(v.z, horMag)
	return yaw, pitch
end

function vecFromAngles(yaw, pitch, magnitude)
	local horMag = magnitude * cos(pitch)
	return vec(horMag*cos(yaw), horMag*sin(yaw), magnitude*sin(pitch))
end

p1 = vec(60,-30,0)
p2 = vec(80,0,0)
p3 = vec(70,30,0)
pp = vec()

function onTick()
	pp = getPrevention(p1, p2, p3, 1)
end

function onDraw()
	local w,h = screen.getWidth(), screen.getHeight()
	screen.sc(255,0,0)
	screen.drawCircle(w/2 + p1.x, h/2 + p1.y, 2)
	screen.sc(0,255,0)
	screen.drawCircle(w/2 + p2.x, h/2 + p2.y, 2)
	screen.sc(0,0,255)
	screen.drawCircle(w/2 + p3.x, h/2 + p3.y, 2)
	screen.sc(0,255,255)
	screen.drawCircle(w/2 + pp.x, h/2 + pp.y, 2)
end

function getPrevention(p1, p2, p3, ticks)
	local v1 = subt(p2, p1)
	local v2 = subt(p3, p2)

	local mag1, mag2 = mag(v1), mag(v2)
	if mag1 < 1e-6 then mag1 = 1e-6 end

	local yaw1, pitch1 = vecAngles(v1)
	local yaw2, pitch2 = vecAngles(v2)

	local deltaYaw = wrapAngle(yaw2 - yaw1)
	local deltaPitch = pitch2 - pitch1
	local ratio = mag2 / mag1

	local predicted = p3
	local curYaw, curPitch = yaw2, pitch2

	local accel = mag2 - mag1
		
	for n = 1, ticks do
		curYaw = curYaw + deltaYaw
		curPitch = curPitch + deltaPitch
		
		local curMag = mag2 + accel * n
		
		predicted = add(predicted, vecFromAngles(curYaw, curPitch, curMag))
	end

	return predicted
end