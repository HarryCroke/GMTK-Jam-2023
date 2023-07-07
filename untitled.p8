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

    --spawn_ufo(0, 16, -1, 4, 16)
    spawn_ufo(128, 16, -1, -4, 16)
    spawn_ufo(0, 16, 1, 4, 16)
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
        acc_x = 0.25,
        moving = false,
        sucking = false,
        anim_max = 4,
        anim_tick = 0,
        friction = 0.05,
        suck_power = 3,
        cam_x = 0,
        score = 0

    }
end

-- UPDATE PLAYER
function update_player()
    -- player movement input
    if (btn(1)) then
        player.dx+=player.acc_x
        player.moving = true
    elseif (btn(0)) then
        player.dx-=player.acc_x
        player.moving = true
    else
        player.moving = false
    end

    -- player flip and friction
    if(player.dx > player.friction) then
        player.flip = true
        player.dx-=player.friction
    elseif(player.dx < -player.friction) then
        player.flip = false
        player.dx+=player.friction
    else 
        player.moving=false
        player.dx = 0
    end
    -- clamp player speed
    if(player.dx > player.max_dx) then
        player.dx = player.max_dx
    elseif(player.dx < -player.max_dx) then
        player.dx = -player.max_dx
    end

    if btn(5) then
        player.sucking = true
        player.moving = false
        player.dx = 0
        shootRay(player.x+4, "suck")
    else
        player.sucking = false
    end

    -- Camera
    player.cam_x = player.x-56,0
    if(player.cam_x <0) then 
        player.cam_x = 0
    elseif (player.cam_x > 248-120) then
        player.cam_x = 248-120
    end
    camera(player.cam_x)
    player.x += player.dx

    -- Clamp player pos
    if(player.x<-8) then
        player.x = 256
    elseif(player.x>256) then
        player.x = -8
    end

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
        ufo.x+=ufo.dx
        ufo.dx = ufo.max_dx
        for ray in all(rays) do
            if(ray.x < (ufo.x+8)) and (ray.x > ufo.x) then
                ufo.dx = 0.1 * ufo.dir
                ufo.y += player.suck_power
            end
        end

        if(ufo.y >= player.y) then
            del(ufos, ufo)
            player.score += 1
        end


    end
end

function draw_ufos()
    for ufo in all(ufos) do
        spr(ufo.spr, ufo.x, ufo.y)
    end
end

-- GAME UPDATE AND DRAW
function update_game()
    update_player()
    update_ufos()

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
    print("score: " .. player.score, 8, 8, 7)
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
000770000878000608780006f1f70006000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000770004f4761164f476116f1f76116000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700fff76666fff76666fff76666000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000666ff600666ff600666ff6000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000006060060606006000606006000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
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
00000000002042000024020000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
40404040000042000024000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000042000024000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
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
0021000000000000000000000000000000000000000000000000000000002200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
2020202020202020202020202020202020202020202020202020202020202020000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
