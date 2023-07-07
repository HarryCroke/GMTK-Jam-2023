pico-8 cartridge // http://www.pico-8.com
version 41
__lua__
function _init()
    init_intro()
end

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
    update_intro()
end

function _draw()
    draw_intro()
end
__gfx__
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
