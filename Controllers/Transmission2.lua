ign = input.getNumber
osn = output.setNumber
igb = input.getBool
WheelsDiameter = 3
maxSlipThreshold = 0.1
targetAngularVel = 0.2
clutchToBrakeRatio = 2
lfClutch = 1
rfClutch = 1
lbClutch = 1
rbClutch = 1
lfBrake = 0
rfBrake = 0
lbBrake = 0
rbBrake = 0
function onTick()
    
    WheelsDiameter = property.getNumber("Wheels diameter (meters)")
    ad = ign(20)
    ws = ign(21)
    rps = ign(22)
    speed = math.abs(ign(9))
    angularVel = ign(11)
    turnOff = igb(1)
    speedFactor = 1 / (1 + speed * 0.03)
    if turnOff then
        speedFactor = 1
    end
    dstBtwWheels = property.getNumber("Distance BTW Wheels (meters)")
    dstBtwAxles = property.getNumber("Distance BTW axes (meters)")
    espPower = property.getNumber("ESP Power")
    leftSteer, rightSteer = ackermannSteering(ad, dstBtwWheels, dstBtwAxles, speedFactor)

    slip = getWheelsSlip(speed, rps, WheelsDiameter)
    adSpeedFixed = ad * speedFactor

    throttle = tcs(slip, maxSlipThreshold, ws, turnOff)
    -- ESP correction
    local esp_lf, esp_rf, esp_lb, esp_rb = esp(angularVel, adSpeedFixed, turnOff)
    if ws < 0 then
        throttle = 0
        esp_lf = esp_lf - ws
        esp_rf = esp_rf - ws
        esp_lb = esp_lb - ws
        esp_rb = esp_rb - ws
    end
    
    -- ABS
    lfBrake, rfBrake, lbBrake, rbBrake = abs(slip, esp_lf, esp_rf, esp_lb, esp_rb, maxSlipThreshold)
    lfClutch, rfClutch, lbClutch, rbClutch = 1 - lfBrake * clutchToBrakeRatio, 1 - rfBrake * clutchToBrakeRatio, 1 - lbBrake * clutchToBrakeRatio, 1 - rbBrake * clutchToBrakeRatio
    osn(2, -leftSteer)
    osn(3, rightSteer)
    osn(4, throttle)
    osn(5, lfBrake)
    osn(6, lfClutch)
    osn(7, rfBrake)
    osn(8, rfClutch)
    osn(9, lbBrake)
    osn(10, lbClutch)
    osn(11, rbBrake)
    osn(12, rbClutch)

end

function getWheelsSlip(speed, rps, WheelsDiameter)
    if rps == 0 then
        return 0
    end
    wheelCircumference = WheelsDiameter * math.pi
    wheelSpeed = rps * wheelCircumference
    slip = math.abs(wheelSpeed - speed) / math.max(math.abs(wheelSpeed), speed)
    return slip
end

function ackermannSteering(ad, dstBtwWheels, dstBtwAxles, speedF)
    local maxAngle = math.rad(60)
    if math.abs(ad) < 0.05 then
        left = 0
        right = 0
    else
        turningRadius = dstBtwAxles / math.tan(math.abs(ad))
        if ad > 0 then
            left = math.atan(dstBtwWheels / (turningRadius + (dstBtwWheels / 2)))
            right = math.atan(dstBtwWheels / (turningRadius - (dstBtwWheels / 2)))
        else
            left = -math.atan(dstBtwWheels / (turningRadius - (dstBtwWheels / 2)))
            right = -math.atan(dstBtwWheels / (turningRadius + (dstBtwWheels / 2)))
        end
        left = left * speedF
        right = right * speedF
        -- left = math.max(-maxAngle, math.min(maxAngle, left))
        -- right = math.max(-maxAngle, math.min(maxAngle, right))
        -- left = left / maxAngle
        -- right = right / maxAngle
    end
    return left, right
end


integral = 0
previous_error = 0
Kp = 0.5
Ki = 0.05
Kd = 0.4
function tcs(slip, threshold, ws, turnOff)
    if slip < threshold or turnOff then
        integral = 0
        previous_error = 0
        return ws
    end
    error = slip
    integral = integral + error
    integral = clamp(integral, -10, 10)
    derivative = error - previous_error
    output = clamp(Kp * error + Ki * integral + Kd * derivative, 0, 0.7)
    previous_error = error
    return ws - output
end


esp_integral = 0
esp_prev_error = 0
esp_Kp = 1
esp_Ki = 0.001
esp_Kd = 0.0001
function esp(angVel, adF, turnOff)
    if turnOff or math.abs(angVel) < math.abs(targetAngularVel * adF) and not isOppositeSigns(angVel, targetAngularVel * adF) then
        esp_integral = 0
        esp_prev_error = 0
        return 0, 0, 0, 0
    end
    local error = angVel - targetAngularVel * adF
    esp_integral = esp_integral + error
    esp_integral = clamp(esp_integral, -10, 10)
    local derivative = error - esp_prev_error
    local pid_output = esp_Kp * error + esp_Ki * esp_integral + esp_Kd * derivative
    esp_prev_error = error
    local correction = math.abs(clamp(pid_output * espPower, -0.3, 0.3))
    if error > 0.01 then
        -- Oversteer, brake outer wheels
        return correction * 0.5, 0, correction, 0
    elseif error < -0.01 then
        -- Understeer, brake inner wheels
        return 0, correction * 0.5, 0, correction
    else
        return 0, 0, 0, 0
    end
end

function isOppositeSigns(a, b)
    return (a < 0 and b >= 0) or (a >= 0 and b < 0)
end

function abs(slip, lfBrake, rfBrake, lbBrake, rbBrake, threshold)
    if slip < threshold or ws >= 0 or turnOff then
        return lfBrake, rfBrake, lbBrake, rbBrake  -- no adjustment needed
    end
    -- Reduce brakes proportionally to prevent locking
    local reduction_factor = math.min(slip * 2, 1)
    lfBrake = lfBrake * (1 - reduction_factor)
    rfBrake = rfBrake * (1 - reduction_factor)
    lbBrake = lbBrake * (1 - reduction_factor)
    rbBrake = rbBrake * (1 - reduction_factor)
    return lfBrake, rfBrake, lbBrake, rbBrake
end


function clamp(value, min, max)
    if value < min then
        return min
    elseif value > max then
        return max
    else
        return value
    end
end

function onDraw()
    w,h = screen.getWidth(), screen.getHeight()
    screen.sc(255,255,255)
    screen.drawText(5,5,"Wheels speed: " ..math.floor(WheelsDiameter * math.pi * rps *100)/100 .. " m/s")
    screen.drawText(5,20,"Vehicle Speed: "..math.floor(speed*100)/100 .. " m/s")
    screen.drawText(5,35,"Wheel Slip: "..math.floor(getWheelsSlip(speed, rps, WheelsDiameter)*100)/100)
    screen.drawText(5,65,"Wheel RPS: "..math.floor(rps*100)/100)
    screen.drawText(5,80,"Vehicle Angular Velocity: "..math.floor(angularVel*100)/100 .. " rad/s")
    screen.drawText(5,95,"ESP Brake LF: "..math.floor(lfBrake*100)/100 .. " RF: "..math.floor(rfBrake*100)/100 .. " LB: "..math.floor(lbBrake*100)/100 .. " RB: "..math.floor(rbBrake*100)/100)
    screen.drawText(5,105,"Throttle Output: "..math.floor(throttle*100)/100)
    screen.drawText(5,120,"Steering left: "..math.floor(-leftSteer*100)/100 .. " right: "..math.floor(rightSteer*100)/100)
    screen.drawText(5,135,"AD: " ..math.floor(ad*100)/100 .. " adSpeedFixed: "..math.floor(adSpeedFixed*100)/100)
    screen.drawText(5,150,"Speed Factor: "..math.floor(speedFactor*100)/100)
end