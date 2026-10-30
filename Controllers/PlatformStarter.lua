started = false
finished = false
xs, ys, zs = 0, 0, 0
time = 0
brakes = 0
function onTick()
    linear = input.getNumber(2)
    angular = input.getNumber(1)
    x = input.getNumber(5)
    y = input.getNumber(6)
    z = input.getNumber(7)
    is_manual = input.getBool(1)
    if started == false and x ~= 0 and y ~= 0 and z ~= 0 then
        xs = x
        ys = y
        zs = z
        started = true
    end
    timeToStart = property.getNumber("Auto Start Time")
    startDist = property.getNumber("Auto Start Distance")
    isAutoStart = property.getBool("Auto Start")

    if isAutoStart and time > timeToStart * 60 and not finished then
        dst = startDist - math.sqrt((x - xs) ^ 2 + (y - ys) ^ 2 + (z - zs) ^ 2)
        linear = (dst * 0.01)
        angular = 0
        brakes = 1 - linear * 3 and dst < 5 or 0
        if dst < 0.1 then
            finished = true
            breaks = 1
        end
    end
    if finished then
        brakes = is_manual and 0 or 1
    end
    time = time + 1
    output.setNumber(1, angular)
    output.setNumber(2, -angular)
    output.setNumber(3, linear)
    output.setNumber(4, brakes)
end