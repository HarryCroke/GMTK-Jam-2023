pico-8 cartridge // http://www.pico-8.com
version 41
__lua__
function _init()
    --init_intro()
    init_game()
    
end

function init_game()
    scene = "game"
    init_player()
    rays = {}
    ufos = {}
    night =
    {
        count = 0,
        hour = 0,
        tick = 0,
        hour_length = 300,
        ufo_count = 0,
        ufo_total = -1,
        ufo_perhour = 1,
        ufo_prev_dir = 1,
        goal = 0
    }

    new_night()
    map_start = 0
    map_end = 512
    
    --spawn_ufo(128, 16, -1, -4, 16)
    --spawn_ufo(0, 16, 1, 4, 16)
end

-- PLAYER SETUP
function init_player()
    player =
    {
        x = 128,
        y= 104,
        spr = 1,
        flip = false,
        max_dx = 1,
        dx = 0,
        walk_dx = 0,
        extra_dx = 0,
        acc_x = 0.25,
        deacc_x = 0.5,
        boost_dx = 7,
        moving = false,
        sucking = false,
        anim_max = 4,
        anim_tick = 0,
        friction = 0.05,
        suck_power = 1,
        cam_x = 0,
        score = 0,
        gas = 100,
        can_eat = false,
        eating = false

    }
end

-- UPDATE PLAYER
function update_player()
    -- player movement input
    if (btn(1)) then
        player.walk_dx+=player.acc_x
        player.moving = true
    elseif (btn(0)) then
        player.walk_dx-=player.acc_x
        player.moving = true
    else
        player.moving = false
    end

    -- player flip and friction
    if(player.walk_dx > player.friction) then
        player.flip = true
        player.walk_dx-=player.friction
    elseif(player.walk_dx < -player.friction) then
        player.flip = false
        player.walk_dx+=player.friction
    else 
        player.moving=false
        player.walk_dx = 0
    end
    -- clamp player speed
    if(player.walk_dx > player.max_dx) then
        player.walk_dx = player.max_dx
    elseif(player.walk_dx < -player.max_dx) then
        player.walk_dx = -player.max_dx
    end

    if btn(4) and (player.gas > 0) and not (player.can_eat) then
        player.sucking = true
        player.moving = false
        player.walk_dx = 0
        if(player.flip) then
            shootRay(player.x+6, "suck")
        else
            shootRay(player.x+1, "suck")
        end
        
        player.gas -= 1
    elseif btn(4) and (player.can_eat) and (player.gas<100) then
        player.moving = false
        player.eating= true
        player.sucking = false
        player.gas+=1
        player.walk_dx = 0
    else
        player.sucking = false
        player.eating = false
    end

    -- boost
    if btnp(5) and (player.gas>=20) then
        if(player.flip) then
            player.extra_dx+=player.boost_dx
        else
            player.extra_dx-=player.boost_dx
        end
        player.gas -= 25
    end

    -- Camera
    player.cam_x = player.x-56,0
    if(player.cam_x <0) then 
        player.cam_x = 0
    elseif (player.cam_x > map_end-128) then
        player.cam_x = map_end-128
    end
    camera(player.cam_x)

    if (player.extra_dx <= player.deacc_x) and (player.extra_dx > 0)
    or (player.extra_dx >= -player.deacc_x) and (player.extra_dx < 0)then
        player.extra_dx = 0
    elseif (player.extra_dx > 0) then
        player.extra_dx -= player.deacc_x
    elseif (player.extra_dx < 0)then
        player.extra_dx += player.deacc_x
    
    end

    -- player speed/pos cals
    player.dx = player.walk_dx + player.extra_dx
    player.x += player.dx

    -- Clamp player pos
    if(player.x<-8) then
        player.x = map_end
    elseif(player.x>map_end) then
        player.x = -8
    end

    check_grass_collision()
    animate_player()
end

function animate_player()
    if(player.moving) then
        player.anim_tick +=1
        if(player.anim_tick>player.anim_max) then
            if(player.spr == 1) then
                player.spr = 2
            else 
                player.spr = 1
            end
            player.anim_tick = 0

        end
    elseif(player.dx != 0) then
        player.spr=2
    else 
        player.spr = 1
    end

    if(player.sucking) then
        player.spr = 3
    elseif (player.eating) then
        player.spr = 4
    end
end

function check_grass_collision()
    if (fget(mget(player.x/8, 13)) == 1) or (fget(mget((player.x+8)/8, 13)) == 1) then
        player.can_eat = true
    else 
        player.can_eat = false
    end
    
end

-- SUCKING

function shootRay(ray_x, ray_type)
    ray =
    {
        x = ray_x,
        top_y = 0,
        bottom_y = 128,
        type = ray_type 
    }
    add(rays, ray)
end

-- UFOS
function spawn_ufo(ufo_x, ufo_y, ufo_dir, ufo_dx, ufo_spr)
    ufo = {
        x = ufo_x,
        y = ufo_y,
        dir = ufo_dir,
        dx = ufo_dx,
        max_dx = ufo_dx,
        spr = ufo_spr
    }
    add(ufos, ufo)
end

function update_ufos()
    for ufo in all(ufos) do 
        
        ufo.dx = ufo.max_dx

        for ray in all(rays) do
            if(ray.x < (ufo.x+8)) and (ray.x > ufo.x) then
                ufo.dx = 0.1 * ufo.dir
                ufo.y += player.suck_power
            end
        end

        if(ufo.x > player.cam_x-8) and (ufo.x + 8 > player.cam_x+128) or (ufo.x<0) or (ufo.x > map_end) then
            ufo.x+=ufo.dx/4
        else 
            ufo.x+=ufo.dx
        end

        if(ufo.y >= player.y) then
            del(ufos, ufo)
            player.score += 1
        end

        if (ufo.x < -8) then
            ufo.x = map_end
        elseif (ufo.x > map_end) then
            ufo.x = -8
        end


    end
end

function draw_ufos()
    for ufo in all(ufos) do
        spr(ufo.spr, ufo.x, ufo.y)
    end
end

function ufo_wave()
    i = night.ufo_perhour
    while (i>0) do 
        if(night.ufo_count > 0) then
            if(night.ufo_prev_dir == 1)then
                spawn_ufo(128, 16, -1, -2, 16)
                night.ufo_prev_dir = -1
            else 
                spawn_ufo(0, 16, 1, 2, 16)
                night.ufo_prev_dir = 1
            end
            night.ufo_count -=1
        end
        i-=1
    end
end

-- NIGHT
function update_night()
    night.tick+=1
    if(night.tick>night.hour_length) then
        night.hour+=1
        night.tick=0
        ufo_wave()

    end
    if(night.hour > 6) then
        new_night()
    end

    if(player.score == night.goal)then
        new_night()
    end
end

function new_night()
    night.count +=1
    night.hour = 0
    night.tick = 0
    night.ufo_total += 2
    night.ufo_count = night.ufo_total
    night.goal = night.ufo_total
    player.score = 0
    if (night.count>6) then
        night.ufo_perhour = 2
    else 
        night.ufo_perhour = 1
    end
    ufo_wave()
    init_player()

end


-- GAME UPDATE AND DRAW
function update_game()
    update_player()
    update_ufos()
    update_night()
end

function draw_game()
    cls()
    spr(player.spr, player.x, player.y, 1, 1, player.flip)
    map(0,0)
    for ray in all(rays) do 
        line(ray.x, ray.top_y, ray.x, ray.bottom_y, 8)
    end
    draw_ufos()

    camera(0,0)
    print("night: " .. night.count , 8, 8, 7)
    print("time: 0" .. night.hour .. ":00", 8, 16, 7)
    print("score: " .. player.score .. "/" .. night.goal, 8, 24, 7)
    print("Gas: " .. player.gas, 8, 32, 7)
    --print(debug, 8, 40, 7)
end

-- INTRO MANAGEMENT
function init_intro()
    logos = {}
    logo_count=0
    intro_tick=0
    logo_tint=2
    logo_colour=14
    scene='intro'
end

--draw and update intro
function update_intro()
    intro_tick+=1
    if logo_count<15 then
        if intro_tick==5 then
        logo={
        speed=7,
        y=128,
        colour=logo_tint
        }
        add(logos,logo)
        intro_tick=0
        logo_count+=1
        if logo_count%2==0 then
        logo_tint=2
        else
        logo_tint=14
        end
        end
    else
        if intro_tick==30 then
        logo_colour=7
        sfx(-1)
        sfx(41)
        elseif intro_tick==75 then
        --init_menu()
        end
    end
    for logo in all(logos) do
        logo.y-=logo.speed
        logo.speed/=1.1
        if logo.y<=56 then
        del(logos,logo)
        end
    end
end

function draw_intro()
    cls()
    for logo in all(logos) do
        print('\130 harfrog \130',39,logo.y,logo.colour)
    end
    print('\130 harfrog \130',39,56,logo_colour)
end

function _update()
    if (scene=="intro")then
        update_intro()
    elseif (scene == "game") then
        rays = {} -- clear rays each frame
        update_game()
    end
    
end

function _draw()
    if(scene=="intro")  then
        draw_intro()
    elseif (scene=="game") then
        draw_game()
    end
    
end
__gfx__
00000000000000000000000070007000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000008780000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0070070070007000700070004f470000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000770000878000608780006f1f70006000000060000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000770004f4761164f476116f1f76116700071160000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700fff76666fff76666fff76666087866660000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000666ff600666ff600666ff64f476ff60000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000006060060606006000606006777760060000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000b3000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00b33300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
6666dddd000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0dddddd0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00dddd00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
b3b3b3b3000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
33333333004000000000040000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
34343434044000000000044000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
40404040244444200244444200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
04040404024022000022042000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000002042000024020030303030000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
4040404000004200002400003b3b3b3b000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000004200002400003b3b3b3b000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__gff__
0000000000000000000000000000000000000000000000000000000000000000000000010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__map__
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0021000000000000002323000000000000000000002323230000000000002200002100000000002323232300000000000000000000002323230000000000220000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
2020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
