pid_pitch = {
    p = 10,
    i = 0.2,
    d = 5,
    max = 1,
    min = -1,
    i_l = 0,
    prev_err = 0
}

function PID(setpoint, process, pid)
    local err = setpoint - process
    local p = err * pid.p
    pid.i_l = clamp(pid.i_l + err * pid.i, pid.min, pid.max)
    local d = (err - pid.prev_err) * pid.d
    pid.prev_err = err
    return clamp(p + pid.i_l + d, pid.min, pid.max)
end

function clamp(Value, Min, Max)
    if Value > Max then
        return Max
    elseif Value < Min then
        return Min
    end
    return Value
end

prev_tilt = 0

function onTick()
    local tilt = -(input.getNumber(2) - input.getNumber(1) * 0.1)
    local stabpos = input.getNumber(3)
    local length = property.getNumber("Stab line lenght") / 2
    local dt = 1/60

    local angspd = (tilt - prev_tilt) / dt
    prev_tilt = tilt

    --  
    local correction = PID(0, tilt + angspd * 0.2, pid_pitch)
    local x_target = clamp(correction * length, -length, length)
 
    local threshold = 0.05  --  sens
    local error = x_target - stabpos

    local move_left = false
    local move_right = false

    if error > threshold then
        move_right = true
    elseif error < -threshold then
        move_left = true
    end

    -- 
    output.setBool(1, move_left)
    output.setBool(2, move_right)
end
