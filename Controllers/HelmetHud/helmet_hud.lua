w = 200
h = 100
MAX_H_FOV = math.rad(40)
MAX_V_FOV = math.rad(60)
MIN_DISTANCE = 1
MAX_DISTANCE = 2000
TIMETODELETE = 3
pi2 = math.pi*2
trgs = {}
time = 0

radar_err = {0,0.5,0.5}

local radar_pos = {0, 0, 0}
local radar_rot = {0, 0, 0}  -- pitch, yaw, roll ()
local camera_rot = {0, 0}     -- pitch, yaw ( )

function rotmat2d(x,y,r)
	return x*math.cos(r)-y*math.sin(r), x*math.sin(r)+y*math.cos(r)
end

function rotationMatrix(pitch, yaw, roll)
    local cp = math.cos(pitch)
    local sp = math.sin(pitch)
    local cy = math.cos(yaw)
    local sy = math.sin(yaw)
    local cr = math.cos(roll)
    local sr = math.sin(roll)
    
    return {
        {cy*cr + sy*sp*sr,  sr*cp,  -sy*cr + cy*sp*sr},
        {-cy*sr + sy*sp*cr, cr*cp,   sy*sr + cy*sp*cr},
        {sy*cp,            -sp,      cy*cp}
    }
end

function multiplyMatrices(a, b)
    return {
        {
            a[1][1]*b[1][1] + a[1][2]*b[2][1] + a[1][3]*b[3][1],
            a[1][1]*b[1][2] + a[1][2]*b[2][2] + a[1][3]*b[3][2],
            a[1][1]*b[1][3] + a[1][2]*b[2][3] + a[1][3]*b[3][3]
        },
        {
            a[2][1]*b[1][1] + a[2][2]*b[2][1] + a[2][3]*b[3][1],
            a[2][1]*b[1][2] + a[2][2]*b[2][2] + a[2][3]*b[3][2],
            a[2][1]*b[1][3] + a[2][2]*b[2][3] + a[2][3]*b[3][3]
        },
        {
            a[3][1]*b[1][1] + a[3][2]*b[2][1] + a[3][3]*b[3][1],
            a[3][1]*b[1][2] + a[3][2]*b[2][2] + a[3][3]*b[3][2],
            a[3][1]*b[1][3] + a[3][2]*b[2][3] + a[3][3]*b[3][3]
        }
    }
end

function onTick()
    --   
    radar_pos = {
        input.getNumber(24),  -- X
        input.getNumber(25),  -- Y
        input.getNumber(26)   -- Z
    }
    
    radar_rot = {
        input.getNumber(27),  -- pitch
        input.getNumber(28),  -- yaw
        input.getNumber(29)   -- roll
    }
    
    camera_rot = {
        input.getNumber(8) * pi2,  -- pitch ( )
        input.getNumber(4) * pi2  -- yaw ( )
    }
    
    time = time + 1
    trgs = {}
    
    --   
    local R_radar = rotationMatrix(
        radar_rot[1],
        radar_rot[2],
        radar_rot[3]
    )
    
    --    ( )
    local R_camera = rotationMatrix(
        camera_rot[1],
        camera_rot[2],
        0  -- roll    
    )
    
    --   
    -- local R_total = multiplyMatrices(R_radar, R_camera)
    local R_total = R_radar
    
    --  
    for i = 0, 5 do
        if input.getBool(i+1) then
            local distance = input.getNumber(i*4+1)
            local azimuth = input.getNumber(i*4+2)*pi2
            local elevation = input.getNumber(i*4+3)*pi2
            
            --     
            local x = distance * math.cos(elevation) * math.sin(azimuth) + radar_err[1]
            local z = distance * math.cos(elevation) * math.cos(azimuth) + radar_err[2]
            local y = distance * math.sin(elevation) + radar_err[3]
            y, z = rotmat2d(y, z, radar_rot[1])
			z, x = rotmat2d(z, x, radar_rot[2])
			x, y = rotmat2d(x, y, radar_rot[3])
            --   
            
            --    
            local world_pos = {
            	x + radar_pos[1], y + radar_pos[2], z + radar_pos[3]
                -- radar_pos[1] + x*R_radar[1][1] + y*R_radar[1][2] + z*R_radar[1][3],
                -- radar_pos[3] + x*R_radar[2][1] + y*R_radar[2][2] + z*R_radar[2][3],
                -- radar_pos[2] + x*R_radar[3][1] + y*R_radar[3][2] + z*R_radar[3][3]
            }
            
            table.insert(trgs, {
                world_pos = world_pos,
                time = time
            })
        end
    end
    MAX_H_FOV = math.rad(property.getNumber("MAX_HORIZONTAL_FOV"))
    MAX_V_FOV = math.rad(property.getNumber("MAX_VERTICAL_FOV"))
    
end

function projectToScreen(world_pos,tmpp)
    --  
    local dx = world_pos[1] - radar_pos[1]
    local dy = world_pos[2] - radar_pos[2]
    local dz = world_pos[3] - radar_pos[3]
    --    

    local R_radar_inv = rotationMatrix(
        -radar_rot[1],
        -radar_rot[2],
        -radar_rot[3]
    )
    
    --    
    local R_camera_inv = rotationMatrix(
        -camera_rot[1],
        -camera_rot[2],
        0
    )
    
    --   
    -- local R_total_inv = multiplyMatrices(R_camera_inv, R_radar_inv)
            dy, dz = rotmat2d(dy, dz, radar_rot[1])
			dz, dx = rotmat2d(dz, dx, radar_rot[2])
			dx, dy = rotmat2d(dx, dy, radar_rot[3])
    --    
    local local_pos = {
    	dx,dy,dz
        -- dx*R_total_inv[3][1] + dy*R_total_inv[3][2] + dz*R_total_inv[3][3],
        -- dx*R_total_inv[2][1] + dy*R_total_inv[2][2] + dz*R_total_inv[2][3],
        -- dx*R_total_inv[1][1] + dy*R_total_inv[1][2] + dz*R_total_inv[1][3]
    }
    screen.drawText(2,h*0.3*tmpp,"x: "..local_pos[1])
    screen.drawText(2,h*0.3*tmpp+h*0.1,"y: "..local_pos[2])
    screen.drawText(2,h*0.3*tmpp+h*0.2,"z: "..local_pos[3])
    --  
    local azimuth = atan2(local_pos[1], local_pos[3])  -- y, x
    local elevation = atan2(local_pos[2], math.sqrt(local_pos[1]^2 + local_pos[3]^2))
    screen.drawText(2+w*0.5,h*0.3*tmpp,"azimuth: "..azimuth)
    screen.drawText(2+w*0.5,h*0.3*tmpp+h*0.1,"elevation: "..elevation)
    --   
    local x = w/2 + (azimuth / (MAX_H_FOV)) * w/2
    local y = h/2 - (elevation / (MAX_V_FOV)) * h/2
    
    return x, y
end

function onDraw()
    w = screen.getWidth()
    h = screen.getHeight()
    screen.drawRect(0,0,w-1,h-1)
    
    for tmpp, target in ipairs(trgs) do
        local x, y = projectToScreen(target.world_pos,tmpp)
        local distance = math.sqrt(
            (target.world_pos[1]-radar_pos[1])^2 +
            (target.world_pos[2]-radar_pos[3])^2 +
            (target.world_pos[3]-radar_pos[2])^2
        )

        local size = math.max(1, 15 * (1 - distance/MAX_DISTANCE))
        screen.drawCircle(x, y, size)
        screen.drawLine(x, y-math.max(1, size)/2, x, y+math.max(1, size)/2)
        screen.drawLine(x-math.max(1, size)/2, y, x+math.max(1, size)/2, y)
    end
end

function math.clamp(v, min, max)
    return math.max(min, math.min(max, v))
end
function atan2(y, x)
    if x > 0 then
        return math.atan(y / x)
    elseif x < 0 and y >= 0 then
        return math.atan(y / x) + math.pi
    elseif x < 0 and y < 0 then
        return math.atan(y / x) - math.pi
    elseif x == 0 and y > 0 then
        return math.pi / 2
    elseif x == 0 and y < 0 then
        return -math.pi / 2
    else -- x == 0 and y == 0
        return 0 --    nil   ,    
    end
end