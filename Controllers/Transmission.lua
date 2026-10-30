params = {inp = {}}
pi2 = math.pi * 2
ign = input.getNumber
osn = output.setNumber
slip = 1.11
bias = 0.56
function onTick()
	params.speed = ign(1)
	params.inp.pedal = ign(2)
	params.inp.steer = ign(3)
	params.yawRate = - ign(4)
	params.lateralAccel = - ign(5)
	
	params.wheelRadius = property.getNumber("Wheel Diameter") / 2
    params.wheelAngVel = {
        ign(6) * pi2,  -- Front Left
        ign(7) * pi2,  -- Front Right
        ign(8) * pi2,  -- Rear Left
        ign(9) * pi2   -- Rear Right
    }
    params.wheelbase = property.getNumber("Wheelbase Length")
    params.trackWidth = property.getNumber("Wheelbase Width")


    out = VehicleControl.update(params)
    osn(1, out.pedal)
    osn(2, out.steerL)
    osn(3, out.steerR)
    osn(4, out.clutch[1]) -- Front Left clutch
    osn(5, out.clutch[2]) -- Front Right clutch
    osn(6, out.clutch[3]) -- Rear Left clutch
    osn(7, out.clutch[4]) -- Rear Right clutch
    osn(8, out.brake[1])  -- Front Left brake
    osn(9, out.brake[2])  -- Front Right brake
    osn(10, out.brake[3]) -- Rear Left brake
    osn(11, out.brake[4]) -- Rear Right brake
end

function onDraw()
    w,h = screen.getWidth(), screen.getHeight()
    screen.sc(255,255,255)
    screen.drawLine(w*0.2,h*0.2,w*0.8,h*0.2) -- hor up
    screen.drawLine(w*0.2,h*0.8,w*0.8,h*0.8) -- hor down
    screen.drawLine(w*0.5,h*0.2,w*0.5,h*0.8) -- vert
    
	screen.drawText(w*0.05,h*0.4,"SLIP\n"..math.floor(slip*100)/100)
    screen.drawText(w*0.65,h*0.4,"BIAS\n"..math.floor(bias*100)/100)
    screen.drawRectF(w*0.45,h*0.3,w*0.1,h*0.4)
    screen.sc(255,0,0)
    
    screen.drawRectF(w*0.3-1,h*0.17-1,w*0.1+2,h*0.06+2)
    screen.drawRectF(w*0.3-1,h*0.83+1,w*0.1+2,-h*0.06-2)
    screen.drawRectF(w*0.7+1,h*0.17-1,-w*0.1-2,h*0.06+2)
    screen.drawRectF(w*0.7+1,h*0.83+1,-w*0.1-2,-h*0.06-2)
    wheels = {	{{w*0.1,h*0.1},{w*0.2,h*0.1},{w*0.2,h*0.3},{w*0.1,h*0.3}},
				{{w*0.9,h*0.1},{w*0.8,h*0.1},{w*0.8,h*0.3},{w*0.9,h*0.3}},
				{{w*0.1,h*0.7},{w*0.2,h*0.7},{w*0.2,h*0.9},{w*0.1,h*0.9}},
				{{w*0.9,h*0.7},{w*0.8,h*0.7},{w*0.8,h*0.9},{w*0.9,h*0.9}}
    	
    }
	for j=1,#wheels,1 do
		for i=1,#wheels[j],1 do --LF wheel
			local x1 = wheels[j][i][1]
			local y1 = wheels[j][i][2]
			local x2 = wheels[j][(i)%#wheels[j]+1][1]
			local y2 = wheels[j][(i)%#wheels[j]+1][2]
			xc, yc = j==1 and w*0.2 or w*0.8, h*0.2
			angle = j==1 and j<3 and out.steerL*30 or j<3 and out.steerR*30 or 0
			x1, y1 = rotatecoords(x1, y1, angle, xc, yc)
			x2, y2 = rotatecoords(x2, y2, angle, xc, yc)
			screen.drawLine(x1,y1,x2,y2)
		end
	end
	screen.sc(0,0,0)
    screen.drawRectF(w*0.3,h*0.17,w*0.1,h*0.06)
    screen.drawRectF(w*0.3,h*0.83,w*0.1,-h*0.06)
    screen.drawRectF(w*0.7,h*0.17,-w*0.1,h*0.06)
    screen.drawRectF(w*0.7,h*0.83,-w*0.1,-h*0.06)
	screen.drawRectF(w*0.45+1,h*0.3+1,w*0.1-2,h*0.4-2)
	
	screen.sc(255,0,0)
	screen.drawLine(w*0.45+1,h*0.5,w*0.55-1,h*0.5)
end

function rotatecoords(x, y, angle, xc, yc)
	angle = angle * math.pi / 180
    local cosA = math.cos(angle)
    local sinA = math.sin(angle)
    x, y = x - xc, y - yc
    return x * cosA - y * sinA + xc, x * sinA + y * cosA + yc
end

-- Vehicle Dynamics Control Module
-- Implements ABS, ESP, TCS, Torque Split, and Ackermann Steering in Lua

-- Input axes:
-- params.speed               : vehicle forward speed (m/s)
-- params.wheelRadius         : nominal wheel radius (m)
-- params.wheelAngVel         : table of angular velocities for each wheel (rad/s), order: {FL, FR, RL, RR}
-- params.wheelbase           : distance front-to-rear axle (m)
-- params.trackWidth         : distance left-to-right wheels (m)
-- params.inp.pedal          : combined pedal axis [-1..1], negative = brake, positive = throttle
-- params.inp.steer          : steering command axis [-1..1]
--
-- Optional axes for ESP:
-- params.yawRate             : yaw rate (rad/s)
-- params.lateralAccel        : lateral acceleration (m/s^2)

VehicleControl = {}

-- ABS: limit wheel slip during braking
function VehicleControl.ABS(speed, wheelRadius, wheelAngVel)
    if speed <= 0 then return false end
    local slipThreshold = 0.2
    local wheelSpeed = wheelAngVel * wheelRadius
    slip = (speed - wheelSpeed) / speed
    return slip > slipThreshold
end

-- TCS: traction control during acceleration
function VehicleControl.TCS(speed, wheelRadius, wheelAngVel)
    if speed <= 0 then return false end
    local slipThreshold = -0.2
    local wheelSpeed = wheelAngVel * wheelRadius
    slip = (speed - wheelSpeed) / speed
    return slip < slipThreshold
end

-- ESP: stability control (simplified yaw moment correction)
function VehicleControl.ESP(params)
    local desiredYawRate = params.inp.steer * params.speed / params.wheelbase
    local yawError = desiredYawRate - params.yawRate
    local Kp = 0.5
    local brakeCommands = {0,0,0,0}
    local corrective = Kp * yawError
    if corrective > 0 then
        -- understeer: brake rear wheels
        brakeCommands[3] = corrective
        brakeCommands[4] = corrective
    else
        -- oversteer: brake front wheels
        brakeCommands[1] = -corrective
        brakeCommands[2] = -corrective
    end
    return brakeCommands
end

-- Torque split front/rear
function VehicleControl.torqueSplit(params)
    local frontBias = 0.6
    local pedal = params.inp.pedal
    local throttleInput = math.max(pedal, 0)
    local torqueFront = throttleInput * frontBias
    local torqueRear = throttleInput * (1 - frontBias)
    return {torqueFront, torqueFront, torqueRear, torqueRear}
end

-- Ackermann steering angles for left/right
function VehicleControl.ackermann(params)
    local steer = params.inp.steer
    local maxAngle = math.rad(30)
    local angle = steer * maxAngle
    if math.abs(angle) < 1e-3 then
        return 0, 0
    end
    local L = params.wheelbase
    local W = params.trackWidth
    local R = L / math.tan(angle)
    local leftAngle, rightAngle
    if steer > 0 then
        leftAngle  = math.atan(L / (R - W/2))
        rightAngle = math.atan(L / (R + W/2))
    else
        leftAngle  = math.atan(L / (R + W/2))
        rightAngle = math.atan(L / (R - W/2))
    end
    return leftAngle / maxAngle, rightAngle / maxAngle
end

-- Main update: computes control outputs
function VehicleControl.update(params)
    local pedal = params.inp.pedal
    local brakeInput = math.max(-pedal, 0)
    local throttleInput = math.max(pedal, 0)

    local brakeOut = {0,0,0,0}
    local clutchOut = {1,1,1,1}

    -- ABS & TCS per wheel
    for i=1,4 do
        if VehicleControl.ABS(params.speed, params.wheelRadius, params.wheelAngVel[i]) then
            brakeOut[i] = math.max(brakeOut[i], brakeInput)
        end
        if VehicleControl.TCS(params.speed, params.wheelRadius, params.wheelAngVel[i]) then
            clutchOut[i] = 0
        end
    end

    -- ESP correction
    if params.yawRate and params.lateralAccel then
        local espBrakes = VehicleControl.ESP(params)
        for i=1,4 do
            brakeOut[i] = math.max(brakeOut[i], espBrakes[i])
        end
    end

    -- Torque distribution
    local torqueCmds = VehicleControl.torqueSplit(params)
    for i=1,4 do
        if clutchOut[i] == 1 then
            clutchOut[i] = torqueCmds[i]
        end
    end

    -- Steering
    local steerL, steerR = VehicleControl.ackermann(params)

    return {
        clutch = clutchOut,
        brake = brakeOut,
        pedal = pedal,
        steerL = steerL,
        steerR = steerR
    }
end