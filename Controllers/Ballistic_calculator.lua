-- ==============================================================
-- Turret ballistics controller
-- Analytic (closed-form) linear-drag solver  no per-tick simulation
-- ==============================================================

local sin,cos,atan,pi,acos = math.sin,math.cos,math.atan,math.pi,math.acos

function ijkfromeuler(a,b,c)
	local d,e,f,g,h,i=cos(a),sin(a),cos(b),sin(b),cos(c),sin(c)
	local j={x=f*h,y=f*i,z=-g}
	local k={x=e*g*h-d*i,y=e*g*i+d*h,z=e*f}
	local l={x=d*g*h+e*i,y=d*g*i-e*h,z=d*f}
	return j,k,l
end

function dot(m,n) return m.x*n.x+m.y*n.y+m.z*n.z end
function vec(o,p,q) return {x=o or 0,y=p or 0,z=q or 0} end
function multf(m,r) return {x=m.x*r,y=m.y*r,z=m.z*r} end
function add(m,n) return {x=m.x+n.x,y=m.y+n.y,z=m.z+n.z} end
function invert(m) return multf(m,-1) end
function subt(m,n) return add(m,invert(n)) end
function mag(s) return math.sqrt(s.x*s.x+s.y*s.y+s.z*s.z) end
function tolocal(s,j,k,l) return {x=dot(s,j),y=dot(s,k),z=dot(s,l)} end

function atan2(p,o)
	if o>0 then return atan(p/o) end
	if o<0 and p>=0 then return atan(p/o)+pi end
	if o<0 and p<0 then return atan(p/o)-pi end
	if o==0 and p>0 then return pi/2 end
	if o==0 and p<0 then return -pi/2 end
	return 0
end

function normalizeAngle(m) return (m+pi)%(2*pi)-pi end
function clamp(s,t,u) return s<t and t or (s>u and u or s) end

function vecFromAngs(az, elev)
	local ca, sa = cos(az), sin(az)
	local ce, se = cos(elev), sin(elev)
	return {x = ce*sa, y = se, z = ce*ca}
end

function getAngle(world_pos, rocket_pos, tur_rotate)
	rocket_pos = rocket_pos or vec()
	tur_rotate = tur_rotate or vec()
	local delta = subt(world_pos, rocket_pos)
	local local_pos = tolocal(delta, tur_rotate.x, tur_rotate.y, tur_rotate.z)
	local azimuth = atan2(local_pos.x, local_pos.z)
	local elevation = atan2(local_pos.y, math.sqrt(local_pos.x^2 + local_pos.z^2))

	return azimuth, elevation
end

WEAPONS = {
	{v=800,  drag=0.0,    lt=120},
	{v=1000, drag=0.02,   lt=150},
	{v=1000, drag=0.01,   lt=300},
	{v=900,  drag=0.005,  lt=600},
	{v=800,  drag=0.002,  lt=1500},
	{v=700,  drag=0.001,  lt=2400},
	{v=600,  drag=0.0005, lt=2400},
}

function solve_with_drag(tbl,x0,y0,z0,xt,yt,zt,g,opts)
	opts=opts or {}
	local tol=opts.tol or 1e-4
	local maxiter=opts.maxiter or 25
	local scan_steps=opts.scan_steps or 60
	local accept_tol=opts.accept_tol or 0.1 -- max allowed height error (m) to trust a found root

	local v0=tbl.v or 0
	local drag_frac=tbl.drag or 0        -- fractional velocity loss PER TICK, as the game applies it
	local k=drag_frac*60                 -- coefficient used in the closed-form algebra below
	local ln1mD=(drag_frac>1e-9) and math.log(1-drag_frac) or 0  -- exact per-tick decay rate
	local max_time=(tbl.lt or 3600)/60  -- projectile lifetime, seconds

	local dx,dy,dz=xt-x0,yt-y0,zt-z0
	local R=math.sqrt(dx*dx+dy*dy)*0.984
	local az=atan2(dy,dx)
	local res={azimuth=az,elevations={},times={},msg=""}

	if v0<=0 then res.msg="bad muzzle velocity"; return res end

	if R<1e-6 then
		-- straight up/down shot
		if math.abs(dz)<1e-9 then res.msg="target==start"; return res end
		local a,b,c=0.5*g,-v0,dz
		local D=b*b-4*a*c; if D<0 then D=0 end
		local t1=(-b+math.sqrt(D))/(2*a)
		local t2=(-b-math.sqrt(D))/(2*a)
		if dz>0 then table.insert(res.elevations,pi/2) else table.insert(res.elevations,-pi/2) end
		if t1>0 and t1<=max_time then table.insert(res.times,t1) end
		if t2>0 and t2<=max_time then table.insert(res.times,t2) end
		res.msg=(dz>0) and "vertical up" or "vertical down"
		return res
	end

	local function height_at_range(theta)
		local vx0,vz0=v0*cos(theta),v0*sin(theta)
		if vx0<=1e-9 then return nil end
		local t,z
		if drag_frac>1e-9 then
			local ratio=R*k/vx0
			if ratio>=1 then return nil end

			t=math.log(1-ratio)/(60*ln1mD)
			if t>max_time then return nil end
			local r=1-drag_frac
			z=(ratio)/k*(vz0+g*r/k)-(g*r/k)*t
		else
			t=R/vx0
			if t>max_time then return nil end
			z=vz0*t-0.5*g*t*t
		end
		return z-dz,t
	end

	-- Upper bound on launch angle: past this, drag caps the range below R.
	local theta_limit=pi/2-1e-6
	if k>1e-9 then
		local c=clamp(R*k/v0,-1,1)
		theta_limit=math.min(theta_limit, acos(c)-1e-6)
	end
	if theta_limit<=1e-6 then res.msg="out of range"; return res end

	local roots={}
	local last_th,last_val=1e-6, height_at_range(1e-6)
	for i=1,scan_steps do
		local th=1e-6+(theta_limit-1e-6)*(i/scan_steps)
		local val=height_at_range(th)
		if last_val and val and last_val*val<=0 then
			local lo,hi,vlo,vhi=last_th,th,last_val,val
			local theta=nil
			for it=1,maxiter do
				local mid=(lo+hi)/2
				local vm=height_at_range(mid)
				if vm then
					if math.abs(vm)<tol then theta=mid; break end
					if vlo*vm<=0 then hi,vhi=mid,vm else lo,vlo=mid,vm end
				else
					hi=mid
				end
			end
			if not theta then theta=(lo+hi)/2 end
			local check=height_at_range(theta)
			if check and math.abs(check)<accept_tol then
				local dup=false
				for _,r in ipairs(roots) do if math.abs(r-theta)<1e-6 then dup=true; break end end
				if not dup then table.insert(roots,theta) end
			end
		end
		last_th,last_val=th,val
	end

	if #roots==0 then res.msg="no solutions (with drag)"; return res end
	table.sort(roots) -- roots[1] = flat/direct arc, roots[2] (if present) = lobbed/mortar arc
	for _,th in ipairs(roots) do
		local _,t=height_at_range(th)
		table.insert(res.elevations,th)
		table.insert(res.times,t)
	end
	res.msg=(#res.elevations==1) and "one solution" or "two solutions"
	return res
end

timer = 0

function onTick()
	tur_pos={x=input.getNumber(1),y=input.getNumber(2),z=input.getNumber(3)}
	local rx=input.getNumber(4); local ry=input.getNumber(5); local rz=input.getNumber(6)
	local i,j,k=ijkfromeuler(rx,ry,rz)
	local tur_rot={x=i,y=j,z=k}
	trg={x=input.getNumber(7),y=input.getNumber(8),z=input.getNumber(9)}
	turret_ring=normalizeAngle(math.abs(input.getNumber(11))*pi*2)
	local fire=input.getBool(1)

	res=solve_with_drag(WEAPONS[property.getNumber("Gun type") or 5],tur_pos.z,tur_pos.x,tur_pos.y,trg.z,trg.x,trg.y,30,nil)

	want_high_arc = input.getBool(2)
	local chosen_elev
	if want_high_arc and res.elevations[2] then
		chosen_elev = res.elevations[2]
	else
		chosen_elev = res.elevations[1]
	end
	trgv = vecFromAngs(res.azimuth or 0, chosen_elev or 0)

	local az, elev = getAngle(trgv,nil,tur_rot)
	elev = clamp(elev,-0.1,math.rad(89.9))

	if math.abs(trg.x)<0.1 and math.abs(trg.y)<0.1 and math.abs(trg.z)<0.1 then
		az, elev = 0, 0
	end

	if input.getBool(1) then
		timer = (res.times[want_high_arc and 2 or 1] or 0) * 60
	end
	if timer > 0 then
		timer = timer - 1
	else
		timer = 0
	end

	
	if mag(trg) > 0.1 then
		output.setNumber(1,az*2)
		output.setNumber(2,(elev or 0)/pi*2)
	else
		output.setNumber(1,-turret_ring/5)
		output.setNumber(2,0)
	end
	output.setNumber(3,drop or 0)
end

function onDraw()
	screen.drawText(0,20,res.msg)
	screen.drawText(0,40,res.times[want_high_arc and 2 or 1] or 0)
	screen.drawText(0,60,"time to target: " .. math.floor(timer / 6) / 10)
end