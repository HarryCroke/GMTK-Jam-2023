pico-8 cartridge // http://www.pico-8.com
version 41
__lua__
function _init()
    init_intro()
    --init_game()
    --init_menu()
    first_menu=true
    
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
        --hour_length = 1,
        ufo_count = 0,
        ufo_total = -1,
        ufo_perhour = 1,
        ufo_prev_dir = 1,
        goal = 0
    }

    map_start = 0
    map_end = 512
    new_night()
    strikes = 1
    
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
        gas = 104,
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

    if btn(2) and (player.gas > 0) and not (player.can_eat)
    or btn(5) and (player.gas > 0) and not (player.can_eat) then
        player.sucking = true
        player.moving = false
        player.walk_dx = 0
        if(player.flip) then
            shootRay(player.x+2, "suck")
        else
            shootRay(player.x+5, "suck")
        end
        
        player.gas -= 1
    elseif btn(3) and (player.can_eat) and (player.gas<104)
    or btn(4) and (player.can_eat) and (player.gas<104) then
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
    --if btnp(5) and (player.gas>=20) then
     --   if(player.flip) then
      --      player.extra_dx+=player.boost_dx
       -- else
        --    player.extra_dx-=player.boost_dx
        --end
        --player.gas -= 20
    --end

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
            sfx(2)

        end
    elseif(player.sucking) then
        player.spr = 3
    elseif (player.eating) then
        player.anim_tick +=1
        if(player.anim_tick>(player.anim_max*2.5)) then
            if(player.spr == 4) then
                player.spr = 1
            else 
                player.spr = 4
            end
            player.anim_tick = 0
            sfx(3)

        end
    elseif(player.dx != 0) then
        player.spr=2
    else 
        player.spr = 1
        player.anim_tick = player.anim_max*2.5
    --player.spr = 1
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
        bottom_y = 120,
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
            sfx(7)
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
            if(night.count == 1) then
                spawn_ufo(128, 16, -1, -2, 16)
                night.ufo_prev_dir = -1
            elseif(night.ufo_prev_dir == 1)then
                spawn_ufo(map_end, 16, -1, -2, 16)
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
    if(night.hour > 7) then
        strikes-=1
        if(strikes >= 0) then 
            init_transition(false)
        else 
            init_end()
        end 
        
        
    end

    if(player.score >= night.goal)then
        init_transition(true)
    end
end

function new_night()
    ufos = {}
    night.count +=1
    night.hour = 0
    night.tick = 0
    night.ufo_total += 2
    night.ufo_count = night.ufo_total
    night.goal = night.count
    player.score = 0
    if (night.count>6) then
        night.ufo_perhour = 2
    else 
        night.ufo_perhour = 1
    end
    ufo_wave()
    init_player()

end

-- UI
function draw_ui()
    camera(0,0)
    -- clock
    print("night " .. night.count , 8, 0, 7)
    print("0" .. night.hour .. ":00", 108, 0, 7)
    
    --print("Gas: " .. player.gas, 8, 32, 7)
    
    spr(39, 104,120)
    print(player.score .. "/" .. night.goal, 114, 120, 7)


    -- gas bar
    rectfill(3, 121, 3+(player.gas/2), 126, 12)
    spr(36,2,120)
    spr(37,10,120)
    spr(37,18,120)
    spr(37,26,120)
    spr(37,34,120)
    spr(37,42,120)
    spr(38,50,120)
end

-- GAME UPDATE AND DRAW
function update_game()
    update_player()
    update_ufos()
    update_night()
end

function draw_game()
    cls()
    camera(player.cam_x, 120)
    map(0,0)
    camera(player.cam_x, 0)

    pal(8, 8+128, 1)
    spr(player.spr, player.x, player.y, 1, 1, player.flip)
    map(0,0)
    for ray in all(rays) do 
        line(ray.x, ray.top_y, ray.x, 103, 11)
    end
    draw_ufos()
    --print(debug, 8, 40, 7)

    draw_ui()
end

-- NIGHT TRANSITIONS
function init_transition(night_success)
    scene = "transition"
    success = night_success
    trans_tick = 0
    if(success) then 
        sfx(-1)
        sfx(4)
    else 
        sfx(-1)
        sfx(5)
    end
end

function update_transition()
    trans_tick += 1
    if(trans_tick > 30) and btnp(4) or (trans_tick > 30) and btnp(5) then 
        scene=("game")
        new_night()
    end
end

function draw_transition()
    pal(8, 8, 1)
    cls()
    camera(0,0)
    print("-debrief-", hcenter("-debrief-"), 8, 7)
    if(success == true) then
        print("success!", hcenter("success!"), 16, 11)
        print(player.score .. "/" .. night.goal .. " ufos abducted", hcenter(player.score .. "/" .. night.goal .. " ufos abducted"), 24, 7)
    else 
        print("failure!", hcenter("failure!"), 16, 8)
        print(player.score .. "/" .. night.goal .. " ufos abducted", hcenter(player.score .. "/" .. night.goal .. " ufos abducted"), 24, 7)
    end 

    print("-night " .. night.count+1 .. " breif-", hcenter("-night " .. night.count+1 .. " breif-"), 40, 7)
    print("abduct " .. night.goal+1 .. " ufos before 8AM", hcenter("abduct " .. night.goal+1 .. " ufos before 8AM"), 48, 7)
    print("❎ to continue", hcenter("❎ to continue"), 80, 7)

    if(strikes == 0) then 
        print("you cannot fail again!", hcenter("you cannot fail again!"), 56, 8)
    end 

end

-- GAME OVER
function init_end()
    scene = "end"
    sfx(-1)
    sfx(6)
end_tick = 0
end

function update_end()
    end_tick+=1
    if(end_tick > 240) and btnp(4) or (end_tick > 200) and btnp(5) then
        init_menu()
    end
end 

function draw_end()
    cls()
    pal(12,8,1)
    camera(0,0)
    map(24,15)
    spr(28, 56, 96)
    spr(44, 72, 96)
    spr(5, 116, 104)
    print("it's over...", hcenter("it's over..."), 55, 8)
    print("it's over...", hcenter("it's over..."), 54, 12)
    if(end_tick > 200) then 
        print("❎ to try again", hcenter("❎❎ to try again"), 69, 5)
        print("❎ to try again", hcenter("❎❎ to try again"), 68, 7)
        
    end 
end

-- MAIN MENU    
function init_menu()
    scene = "menu"
    menu_tick = 0
    if(first_menu == false) then
        music(4)
    end
end

function update_menu()
    menu_tick += 1
    if(menu_tick>40) then 
        menu_tick=0
    end 
    if btnp(5) then
        music(-1) 
        init_game()
        first_menu=false
    end
end

function draw_menu()
    cls()
    pal()
    
    print("ufo abduction", hcenter("ufo abduction"), 35, 5)
    print("ufo abduction", hcenter("ufo abduction"), 34, 7)
    zspr(81, 2, 2, 48, 40, 2)
    -- Box outlines
    camera(0,0)
    map(64,0)
    
    if(menu_tick<20) then 
        print("❎ to start", hcenter("❎❎ to start"), 97, 14)
        print("❎ to start", hcenter("❎❎ to start"), 96, 7)
    else 
        print("❎ to start", hcenter("❎❎ to start"), 97, 13)
        print("❎ to start", hcenter("❎❎ to start"), 96, 6)
    end
    

    print("⬆️/❎ - tractor beam", hcenter("⬆️⬆️/🅾️🅾️ - tractor beam"), 113, 2)
    print("⬆️/❎ - tractor beam", hcenter("⬆️⬆️/🅾️🅾️ - tractor beam"), 112, 7)

    print("⬇️/🅾️ - eat grass", hcenter("⬆️⬆️/🅾️🅾️ - eat grass"), 121, 2)
    print("⬇️/🅾️ - eat grass", hcenter("⬆️⬆️/🅾️🅾️ - eat grass"), 120, 7)
    


    zspr(64, 4, 1, 32, 16, 2)
end

-- INTRO
function init_intro()
    logos = {}
    logo_count=0
    intro_tick=0
    logo_tint=2
    logo_colour=14
    scene='intro'
    --sfx(1)
    music(2)
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
        --sfx(-1)
        sfx(0)
        elseif intro_tick==75 then
            init_menu()
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
    elseif (scene == "transition") then 
        update_transition()
    elseif (scene == "end") then 
        update_end()
    elseif (scene == "menu") then 
        update_menu()
    end
    
end

function _draw()
    if(scene=="intro")  then
        draw_intro()
    elseif (scene=="game") then
        draw_game()
    elseif (scene == "transition") then
        draw_transition()
    elseif (scene == "end") then 
        draw_end()
    elseif (scene == "menu") then 
        draw_menu()
    end
    
end

-- UTILITY FUNCTIONS

function hcenter(s)
    -- screen center minus the
    -- string length times the 
    -- pixels in a char's width,
    -- cut in half
    return 64-#s*2
end

function zspr(n,w,h,dx,dy,dz)
    sx = 8 * (n % 16)
    sy = 8 * flr(n / 16)
    sw = 8 * w
    sh = 8 * h
    dw = sw * dz
    dh = sh * dz
    sspr(sx,sy,sw,sh, dx,dy,dw,dh)
  
  end
__gfx__
00000000000000000000000000000800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000005550000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700700070007000700070007900000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000087800060878000608785556000000060000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000770004f4761164f4761164f479916700071167000700600000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700fff76666fff76666fff97966087866660575611600000000000000000000000030303030000000000000000000000000000000000000000000000000
0000000000666ff600666ff600667ff64f476ff64f4766660000000000000000000000003b3b3b3b303030300000000000000000000000000000000000000000
00000000006060060606006000600006f1f76006fff76ff60000000000000000000000003b3b3b3b3b3b3b3b3030303040404040000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000666600000000000000c0c00066000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000068282600000007766000c9cc682000000000000000000000000
000b300000000000000000000000000000000000000000000000000000000000000000000000628282860000076666600c999cc2000000000000000000000000
00b33300000000000000000000000000000000000000000000000000000000000000000000068282828260007666666600c9a9c2000000000000000000000000
6666dddd00000000000000000000000000000000000000000000000000000000000000000006826666826000666666660c9aa9c6000000000000000000000000
0dddddd000000000000000000000000000000000000000000000000000000000000000000062861111628600628282860c9a9611000000000000000000000000
00dddd00000000000000000000000000000000000000000000000000000000000000000000628611116286006282828600698611000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000006828266668282606666666606828266000000000000000000000000
b3b3b3b300000000000000000000000000000000000000000000000000bbbb00000000000682828282828260628282860000000c000000000000000000000000
333333330040000000000400000000000111111111111111111111100bbbbbb00000000066666666666666666282828600776cc0000000000000000000000000
34343434044000000000044000000000110000001000000010000011b71bb17b000000000282828282828280666666660766c99c000000000000000000000000
40404040244444200244444200000000110000001000000010000011b11bb11b04400440028282828282828062828286766c9a9c000000000000000000000000
040404040240220000220420000000001100000010000000100000110bbbbbb002400240028666666666628062828286666c9a9c000000000000000000000000
00000000002042000024020030c0303011000000100000001000001100b11b00424242420286424664246280666666666282c9c6000000000000000000000000
4040404000004200002400003bcb3b3b011111111111111111111110000bb0002242224202862426624262806282828662828286000000000000000000000000
0000000000004200002400003bcb3b3b000000000000000000000000000000000240024002864246642462806282828666666666000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
e777777e777777777777777777777777077777777777777077777777000000000000000000000000000000000000000000000000000000000000000000000000
7e1111e11111111111111111111111177cccccccccccccc7cccccccc000000000000000000000000000000000000000000000000000000000000000000000000
71e11e111117777117777117111117177c1111111111111711111111777777770000000000000000000000000000000000000000000000000000000000000000
711ee1177171111171111717111117177c1111111111111711111111777777770000000000000000000000000000000000000000000000000000000000000000
711ee1177171111171111717117117177c1111111111111711111111000000007777777700000000000000000000000000000000000000000000000000000000
71e11e111117777117777111771771177c1111111111111711111111000000007777777700000000000000000000000000000000000000000000000000000000
7e1111e11111111111111111111111177c1111111111111711111111000000000000000000000000000000000000000000000000000000000000000000000000
e777777e7777777777777777777777777c1111111111111711111111000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000007c1111111111111711111111000000000000000000000000000000000000000000000000000000000000000000000000
000000000111000000006660000000007c1111111111111711111111000000000000000000000000000000000000000000000000000000000000000000000000
000000001111177777766666000000007c1111111111111711111111000000000000000000000000000000000000000000000000000000000000000000000000
000000000111477777746660000000007c1111111111111711111111000000000000000000000000000000000000000000000000000000000000000000000000
000000000007747777411000000000007c1111111111111711111111000000000000000000000000000000000000000000000000000000000000000000000000
0000000000778f4774f81700000000007c1111111111111711111111000000000000000000000000000000000000000000000000000000000000000000000000
0000000000778f7771f81100000000007c1111111111111711111111000000000000000000000000000000000000000000000000000000000000000000000000
000000000077887771881100000000007c1111111111111711111111000000000000000000000000000000000000000000000000000000000000000000000000
00000000007777ffff11110000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000077ffffffff110000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000007f44ffff44f70000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000fff44ffff44fff000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000ffffffffffffff000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000ffffffffffff0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000ffffffffff00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000ffffff0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__gff__
0000000000000000000101010100000000000000000000000000000000000000000000010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__map__
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000048484848484848484848484848484848000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000047474747474747474747474747474747000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000044464646464646464645000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000004456565656565656565656450000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0021000000000000000909000000000000000000000909090028282828282800000028282828000909090900000000000000000000000909090000000000220000005456565656565656565656550000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
2020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202000005456565656565656565656550000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000005456565656565656565656550000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000005456565656565656565656550000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
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
00000000000000000000000000000000000000000000000000000000000000191a1b00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00210000000000000000000000000000000000000000000000282828282828292a2b28282828000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
2020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__sfx__
000a0000241752410518175241750c105001050010500105001050010500105001050010500105001050010500105001050010500105001050010500105001050010500105001050010500105001050010500105
013200000001200012000120001200012000120001200012000120001200012000120001200012000120001200012000120001200012000120001200012000120001200012000120001200012000120001200012
910600000342500405004050040500405004050040500405004050040500405004050040500405004050040500405004050040500405004050040500405004050040500405004050040500405004050040500405
000600000114100101001010010100101001010010100101001010010100101001010010100101001010010100101001010010100101001010010100101001010010100101001010010100101001010010100101
111100000e1020e1521315215152141021d1521a102221522110224102001020010200102281022a1023010200102001020010200102001020010200102001020010200102001020010200102001020010200102
591100000e10215152111520e15214102071521a102001520015200152001520015500102281022a1023010200102001020010200102001020010200102001020010200102001020010200102001020010200102
682000000e202212521d2521a25214202132521a20200252002520025200252002520025200252002520025200252002520025200252002420023200222002150020200202002020020200202002020020200202
100b00000e5521355215552145021d5001a500225002150224502005020050200502285022a502305020050200502005020050200502005020050200502005020050200502005020050200502005020050200500
191900000e7520e7220e7120e7120e7120e7120e7120e71200700007000070000700007000070000700007000e7520e7220e7120e7120e7120e7120e7120e7120070000700007000070000700007000070000700
191900000c7520c7220c7120c7120c7120c7120c7120c71215752157221571215712157121571215712157120e7520e7220e7120e7120e7120e7120e7120e7120070000700007000070000700007000070000700
1919000010752107221071210712107121071210712107120c7520c7220c7120c7120c7120c7120c7120c7120e7520e7220e7120e7120e7120e7120e7120e7121575215722157121571215712157121571215712
0d0c00000e5620e5620e5620e562005000050000500005000e5620e5620e5620e562005000050000500005000c5620c5620c5620c562155621556215562155620e5620e5620e5620e56200500005000050000500
0d0c00000e5620e5620e5620e562005000050000500005000e5620e5620e5620e56200500005000050000500105621056210562105620c5620c5620c5620c5620e5620e5620e5620e56215562155621556215562
010c00000212502125021250212502125021250212502125021250212502125021250212502125021250212500125001250012500125001250012500125001250212502125021250212502125021250212502125
010c0000005730057313503135030c65500503005030e6000c6550050300503005030050314503145030e600005730057314503145030c65515503155030e6000c6551550315503155030057300500005000e600
0d0c00000e5620e5620e5620e562005000050000500005000e5620e5620e5620e5620050000500005000050010562105621056210562115621156211562115621356213562135621356211562115621156211562
__music__
01 08424344
00 09424344
01 08424344
00 0a424344
01 0b424344
00 0c424344
00 0b0d0e44
00 0c0d0e44
00 0b0d0e44
00 0c0d0e44
00 0b0d0e44
00 0f0d0e44
00 0c0d0e44
00 0f0d0e44
00 410d4344
02 410d0e44

