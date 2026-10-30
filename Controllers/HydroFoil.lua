pid_f = { p = 0.5, i = 0.1, d = 3, max = 0.5, min = -0.5, i_l = 0, prev_err = 0}
pid_b = { p = 0.75, i = 0.1, d = 3, max = 0.5, min = -0.5, i_l = 0, prev_err = 0}
pid_stab = { p = 6, i = 0.01, d = 5, max = 0.5, min = -0.5, i_l = 0, prev_err = 0}

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
function onTick()
    tarDepth = -input.getNumber(1)
    tiltFront = input.getNumber(2) * 8
    tiltRight = input.getNumber(3) * 4
    altFront = input.getNumber(4)
    altBack = input.getNumber(5)
    lspd = input.getNumber(6)
    tarRoll = input.getNumber(7) * 0.1
    
    if math.abs(tarDepth) > 0 and math.abs(lspd) > 1 then
        resFront = PID(tarDepth, altFront, pid_f)
        resBack = PID(tarDepth, altBack, pid_b)
        resRoll = -PID(tarRoll, tiltRight, pid_stab)
    else
        resFront = 0
        resBack = 0
        resRoll = 0
        pid_f.i_l = 0
        pid_b.i_l = 0
        pid_stab.i_l = 0
    end
    resFront = resFront - tiltFront
    resBack = resBack + tiltFront
    resRoll = resRoll
    if lspd < 0 then 
        resFront = -resFront
        resBack = -resBack
        resRoll = -resRoll
    end
    output.setNumber(1, resFront)
    output.setNumber(2, resBack)
    output.setNumber(3, resRoll)
end