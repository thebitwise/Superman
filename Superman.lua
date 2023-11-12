--$$\        $$$$$$\  $$\   $$\  $$$$$$\  $$$$$$$$\ 
--$$ |      $$  __$$\ $$$\  $$ |$$  __$$\ $$  _____|
--$$ |      $$ /  $$ |$$$$\ $$ |$$ /  \__|$$ |      
--$$ |      $$$$$$$$ |$$ $$\$$ |$$ |      $$$$$\    
--$$ |      $$  __$$ |$$ \$$$$ |$$ |      $$  __|   
--$$ |      $$ |  $$ |$$ |\$$$ |$$ |  $$\ $$ |      
--$$$$$$$$\ $$ |  $$ |$$ | \$$ |\$$$$$$  |$$$$$$$$\ 
--\________|\__|  \__|\__|  \__| \______/ \________|
-- coded by Lance/stonerchrist on Discord
util.require_natives("2944b", "g")
pluto_use "0.5.0"
function play_anim(ped, dict, name, duration)
    while not HAS_ANIM_DICT_LOADED(dict) do
        REQUEST_ANIM_DICT(dict)
        util.yield()
    end
    TASK_PLAY_ANIM(ped, dict, name, 1.0, 1.0, duration, 3, 0.5, false, false, false)
end

local SUPPORT_ENT_HASH = util.joaat('IG_RoosterMcCraw')
local support_ent = 0
local superman = false
local SPEED = 600.0
local GRAVITY = 9.8
local WHITE = {r=1, b=1, g=1, a=0.5}

local ROOT = menu.my_root()
local cur_pitch = 0
local cur_yaw = GET_ENTITY_HEADING(players.user_ped())
local camera = 0

local function world_to_screen_coords(v1)
    local ptr_x, ptr_y = memory.alloc(4), memory.alloc(4) 
    GET_SCREEN_COORD_FROM_WORLD_COORD(v1.x, v1.y, v1.z, ptr_x, ptr_y) 
    return v3.new({x = memory.read_float(ptr_x), y = memory.read_float(ptr_y), z = 0.0})
end

util.create_tick_handler(function()
    local ped = players.user_ped()
    local rotate_lr = -GET_CONTROL_NORMAL(1, 1)
    local rotate_ud =  -GET_CONTROL_NORMAL(2, 2)
    local lateral = GET_CONTROL_NORMAL(30, 30)
    if math.abs(cur_pitch) >= 120 then 
        rotate_lr = -rotate_lr
    end

    local c = players.get_position(players.user())

    cur_pitch += rotate_ud * 2
    cur_yaw += rotate_lr * 2

    local jump = IS_CONTROL_PRESSED(55, 55)
    local shift = IS_CONTROL_PRESSED(21, 21)

    if math.abs(cur_pitch) >= 360 then 
        cur_pitch = 0
    end

    if math.abs(cur_yaw) >= 360 then 
        cur_yaw = 0
    end


    if superman then 
        if support_ent ~= 0 and DOES_ENTITY_EXIST(support_ent) then 
            local rot = GET_ENTITY_ROTATION(support_ent, 1)
            SET_ENTITY_ROTATION(support_ent, cur_pitch, 0.0, cur_yaw, 1, true)
            SET_ENTITY_MAX_SPEED(support_ent, SPEED)
            local forward_control = IS_CONTROL_PRESSED(32, 32)
            local backward_control = IS_CONTROL_PRESSED(33, 33) 
            local vel = GET_ENTITY_SPEED_VECTOR(support_ent, true)

            local side_speed = vel.x
            if math.abs(side_speed) > 5 then 
                APPLY_FORCE_TO_ENTITY_CENTER_OF_MASS(support_ent, 0, -side_speed, 0, 0, true, true, true, true)
            end

            if forward_control then
                APPLY_FORCE_TO_ENTITY_CENTER_OF_MASS(support_ent, 0, 0, SPEED, 0, true, true, true, true)
            end

            if backward_control then
                APPLY_FORCE_TO_ENTITY_CENTER_OF_MASS(support_ent, 0, 0, -SPEED, 0, true, true, true, true)
            end

            if jump then 
                APPLY_FORCE_TO_ENTITY_CENTER_OF_MASS(support_ent, 0, 0, 0, SPEED / 2, true, true, true, true)
            end

            if shift then 
                APPLY_FORCE_TO_ENTITY_CENTER_OF_MASS(support_ent, 0, 0, 0, -SPEED / 2, true, true, true, true)
            end

            if lateral then 
                APPLY_FORCE_TO_ENTITY_CENTER_OF_MASS(support_ent, 0, lateral*SPEED, 0, 0.0, true, true, true, true)
            end

            HARD_ATTACH_CAM_TO_ENTITY(camera, players.user_ped(), 0.0, 0.0, 0.0, 0.0, -5.0, .0, true)
        else
            util.request_model(SUPPORT_ENT_HASH, 2000)
            support_ent = entities.create_object(SUPPORT_ENT_HASH, c, GET_ENTITY_HEADING(ped))
            SET_ENTITY_ROTATION(support_ent, -90, 90, 90, 0)
            ATTACH_ENTITY_TO_ENTITY(ped, support_ent, 90, 0, 0, 0, 0, 0, 0, true, false, false, true, 0, true, 0)
        end
    end
end)


ROOT:toggle('Superman fly', {}, '', function(on)
    local ped = players.user_ped()
    local c = players.get_position(players.user())
    superman = on 
    if not on then
        CLEAR_PED_TASKS_IMMEDIATELY(ped) 
        if support_ent ~= 0 then 
            entities.delete(support_ent)
        end
        if camera ~= 0 then 
            RENDER_SCRIPT_CAMS(false, false, 0, true, true, 0)
            DESTROY_CAM(camera, false) 
            camera = 0
        end
        FREEZE_ENTITY_POSITION(ped, false)
    else 
        FREEZE_ENTITY_POSITION(ped, true)
        CLEAR_PED_TASKS_IMMEDIATELY(ped)
        camera = CREATE_CAM_WITH_PARAMS('DEFAULT_SCRIPTED_CAMERA', c.x, c.y, c.z, 0.0, 0.0, 0.0, 120, true, 0)
        --ATTACH_CAM_TO_ENTITY(camera, players.user_ped(), 0.0, 0.0, 0.0, true)
        RENDER_SCRIPT_CAMS(true, false, 0, true, true, 0)
        play_anim(ped, 'skydive@freefall', 'free_forward', -1)
    end
end)

ROOT:slider('Speed', {}, '', 1, 1000, 600, 1, function(val)
    SPEED = val
end)

util.on_stop(function()
    if support_ent ~= 0 then 
        entities.delete(support_ent)
    end
    if camera ~= 0 then 
        DESTROY_CAM(camera, false) 
    end
    FREEZE_ENTITY_POSITION(players.user_ped(), false)
end)

menu.my_root():hyperlink('Join Discord', 'https://discord.gg/zZ2eEjj88v', '')
