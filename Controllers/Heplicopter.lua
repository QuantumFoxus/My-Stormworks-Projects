ign = input.getNumber
igb = input.getBool
osn = output.setNumber

altLast = 0
altitudeTar = 0
function onTick()

    active = igb(1)
    rollT = ign(1)
    pitchT = ign(2)
    yawT = ign(3)
    UpDownT = ign(4)

    tiltf = ign(30) * 4
    tiltr = ign(31) * 4
    altitude = ign(32)

    if UpDownT > 0.1 and active then
        altitudeTar = altitudeTar + 0.1
    elseif UpDownT < -0.1 and active and altitudeTar > 0.2 then
        altitudeTar = altitudeTar - 0.1
    end
    resPitch = pitchT * 0.5 - tiltf
    resRoll = rollT * 0.5 - tiltr
    resYaw = yawT

    if active then
        collective = clamp(collective + clamp(altitudeTar - altitude,-1,1) / 10, -1, 1)
    else
        collective = 0
    end
    LFRoll = resRoll + resYaw
    RFRoll = resRoll + resYaw
    LBRoll = resRoll - resYaw
    RBRoll = resRoll - resYaw
    LFPitch = resPitch + resYaw
    RFPitch = resPitch - resYaw
    LBPitch = resPitch + resYaw
    RBPitch = resPitch - resYaw

    LFRoll, RFRoll, LBRoll, RBRoll, LFPitch, RFPitch, LBPitch, RBPitch =
    balance(LFRoll, RFRoll, LBRoll, RBRoll, LFPitch, RFPitch, LBPitch, RBPitch)
    osn(1,collective)
    osn(2,LFRoll)
    osn(3,LFPitch)
    osn(4,RFRoll)
    osn(5,RFPitch)
    osn(6,LBRoll)
    osn(7,LBPitch)
    osn(8,RBRoll)
    osn(9,RBPitch)
end

function balance(...)
    max = 0
    for i = 1, select("#", ...) do
        local v = select(i, ...)
        if v > max then
            max = v
        end
    end
    if math.abs(max) < 1 then
        return ...
    end
    for i = 1, #... do
        local v = select(i, ...)
        if v > 0 then
            v = v / max
        elseif v < 0 then
            v = -v / max
        end
       return v
    end
end

function clamp(value, min, max)
    return math.max(min, math.min(max, value))
end