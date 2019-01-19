-- title:  Witchem up
-- author: @tinchetsu, @RushJet1
-- desc:   #CGAJAM game
-- script: lua
-- input:  gamepad

--colors
c0=0	--mask color
c1=8
c2=6
c3=11
c4=14
tt=0
tx=false
halfway=false
halfway2=false
tick=0
level=1
max_level=2
lives=3
max_health=3
invul=false
cam={x=0,y=0,sx=-0.5,sy=0}
exp_wait=0	--to avoid sound glitches

pl_state=1	--0:intro, 1:play, 2:dead, 3:win
win=false	--TODO, implement win screen
play_intro=true;

p_bullets={}	--player bullets
e_bullets={}	--enemy bullets
enemies={}	--active enemies
exps={}		--explosions
maps={}	--active maps
stars={}

--spawn data
sMap={}	--map list
spawns={} --enemy spawn list

--player
pl={
	x=0,y=10,speed=2,
	rx=0,ry=0,rw=8,rh=6,--for bullet collision
	l=lives,--lives
	h=max_health,--hearts
	sh_t=0,bomb_t=0,ht=0,
	introt=0,
	walk=false,
	walks=265,
	--mx=0,my=0,mw=14,mh=16,--for map collision
	hurt=function(m,dmg)
		if dmg>0 then
			sfx(61,49,-1,sfxch)
			m.ht=100
			if not invul then
				m.h=m.h-dmg
			end
			if m.h <=0 then
				player_die()
			end
		end
	end
}

--player death anim data
pl_dead={
	x=0,y=0,s=269,t=0,
	bx=0,by=0,ba=1,binc=0 --broom
}

pi=math.pi
pi2=math.pi*2
pow=math.pow
sin=math.sin
cos=math.cos
atan2=math.atan2
floor=math.floor
sqrt = math.sqrt
rand=math.random

-- ease functions
function inQuad(t, b, c, d)
  t = t / d
  return c * pow(t, 2) + b
end

local function outQuad(t, b, c, d)
  t = t / d
  return -c * t * (t - 2) + b
end

local function outBack(t, b, c, d, s)
  if not s then s = 1.70158 end
  t = t / d - 1
  return c * (t * t * ((s + 1) * t + s) + 1) + b
end

local function inOutQuad(t, b, c, d)
  t = t / d * 2
  if t < 1 then
    return c / 2 * pow(t, 2) + b
  else
    return -c / 2 * ((t - 1) * (t - 3) - 1) + b
  end
end

function reset_all()
	p_bullets={}
	e_bullets={}
	enemies={}
	exps={}
	maps={}
	stars={}
	spawns={}
	pl.x=0
	pl.y=0
	pl.h=max_health
	tick=0
	cam.x=0
	cam.y=0
	pl_state=1
	pl.introt=0
	pl.sh_t=0
	pl.ht=0
	music()
end

--change palette
function pal(c0,c1)
	if c0==nil and c1==nil then
		for i=0,15 do poke4(0x3ff0*2+i,i) end
	else
		poke4(0x3ff0*2+c0,c1)
	end
end

--sprite flags
FLAGS={}
function fset(i,f) FLAGS[i]=f end
function fget(i,f) 
	local val = FLAGS[i] or 0
	return val&f~=0
end

--obj collision
function obj_hit(a,b)
	return a.rx<b.rx+b.rw and b.rx<a.rx+a.rw and
		a.ry<b.ry+b.rh and b.ry<a.ry+a.rh 
end

fset(1,1)
fset(2,1)
fset(3,1)
fset(17,1)
fset(18,1)
fset(19,1)
fset(33,1)
fset(34,1)
fset(35,1)
fset(49,1)
fset(50,1)
fset(51,1)
fset(65,1)
fset(66,1)
fset(67,1)
fset(81,1)
fset(82,1)
fset(83,1)
fset(84,1)
fset(97,1)
fset(98,1)
fset(99,1)
fset(100,1)
fset(101,1)
fset(102,1)
fset(113,1)
fset(114,1)
fset(115,1)
fset(116,1)
fset(117,1)
fset(118,1)
fset(129,1)
fset(130,1)
fset(131,1)
fset(132,1)
fset(133,1)
fset(145,1)
fset(146,1)
fset(147,1)
fset(148,1)
fset(149,1)
fset(161,1)
fset(162,1)
fset(163,1)
fset(164,1)



--
moon=nil



-----------------
-- Maps
-----------------
function update_maps()
end
	
function draw_maps()
	sx= cam.x*0.01
	for _,v in pairs(stars) do
		if v.x+sx<0 then
			v.x=v.x+240
		end
		pix(v.x+sx,v.y,c4)
	end
	--moon
	if moon then
		spr(moon.s,moon.x+cam.x*0.015,moon.y+cam.y*0.015,c0,2,0,0,2,2)
	end
	--spr(272,150+cam.x*0.015,10+cam.y*0.2,c0,2,0,0,2,2)
	for k,v in pairs(maps)do
		map(v[1],v[2],v[3]-v[1]+1,v[4]-v[2]+1,v[5]+cam.x,v[6]+cam.y,0,2)
	end
end


-----------------
-- explosions
-----------------
exp_def={
[1]={
init=function(m)
	sfx(62,25,-1,sfxch)
end,
u=function(m)
	local s=m.t*0.3
	m.t=m.t+1
	m.a=sin(s)*6
	if s>pi then
		m.run=false
	end
end,
d=function(m)
	circ(m.x,m.y,m.a+1,c2)
	circ(m.x,m.y,m.a,c4)
end
},

[2]={dur=0,   --particles used in the intro	
init=function(m)
	m.a=0.5*rand()
	m.dur=100+rand()*5
end,
u=function(m)
	m.t=m.t+1
	m.x=m.x-rand()*2
	m.y=m.y+m.a
	if m.t>m.dur then
		m.run=false;
	end
end,
d=function(m)
	if m.t%3==0 then
		rect(m.x,m.y,2,2,c2)
	else
		rect(m.x,m.y,2,2,c4)
	end
end

},

[3]={
init=function(m)
	--sfx(62,25,-1,sfxch)
end,
u=function(m)
	local s=m.t*0.3
	m.t=m.t+1
	m.a=sin(s)*10
	if s>pi then
		m.run=false
	end
end,
d=function(m)
	circ(m.x,m.y,m.a+1,c4)
	circ(m.x,m.y,m.a,c3)
end
},

}

function new_exp(type,x,y,delay)
	local def=exp_def[type]
	local e={x=x,y=y,a=0,d=delay,t=0,run=true}
	for k,v in pairs(def) do
		e[k]=v
	end
	e:init()
	exp_wait=10
	table.insert(exps,e)
end

function update_explosions()
	for k,v in pairs(exps) do
		v:u()
		if not v.run then
			table.remove(exps,k)
		end
	end
	if exp_wait>0 then exp_wait=exp_wait-1 end
end

function draw_explosions()
	for _,v in pairs(exps) do
		v:d()
	end
end

-----------------
-- Enemy bullets
-----------------
function bullet_dir(x1,y1,x2,y2,speed)
	local a=atan2(y2-y1,x2-x1)
	return speed*cos(a), speed*sin(a)
end

bul_def={
[1]={rx=0,ry=0,rw=6,rh=6,t=0,dmg=1,
init=function()
end,
u=function(m)
	m.x=m.x+m.dx
	m.y=m.y+m.dy
	m.rx=m.x-2
	m.ry=m.y-2
	m.t=m.t+1
end,
d=function(m)
	if m.t%6==0 then
		pal(c2,c4)
		pal(c4,c2)
	end
	circ(m.x,m.y,2,c2)
	circ(m.x,m.y,1,c4)
	pal()
end,
}

}

function new_bullet(type,x,y,dx,dy)
	local def=bul_def[type]
	local b={x=x,y=y,dx=dx,dy=dy,run=true}
	for k,v in pairs(def) do
		b[k]=v
	end
	b:init()
	table.insert(e_bullets,b)
end

function update_en_bullets()
	for k,v in pairs(e_bullets) do
		v:u()
		if v.x<-16 or v.x>256 or v.y<-16 or v.y>152 then
			v.run=false
		end
		if not v.run then
			table.remove(e_bullets,k)
		end
	end
end

function draw_en_bullets()
	for _,v in pairs(e_bullets) do
		v:d()
	end
end

-----------------
-- Enemies
-----------------
--common updates
function en_up(e,rx,ry)
	e.t=e.t+1
	e.rx=e.x+e.a+rx
	e.ry=e.y+e.b+ry
end

function en_anim(e)
	e.a_id=e.a_id+1
	if e.a_id > #e.anim then
		e.a_id=1
	end
	e.s= e.anim[e.a_id]
end



--moon boss stuff

function move_rocks(b)
	local x,y = b:pos()
	x=x+16 y=y+16
	for i=1, #b.rocks do
		b.rocks[i].x = x+cos(b.rock_rot+i*pi2/8)*40
		b.rocks[i].y = y+sin(b.rock_rot+i*pi2/8)*40
	end
end

function move_green(b)
	local x,y = b:pos()
	x=x+16 y=y+16
	for i=1, #b.rocks do
		if i%2==0 then
			b.rocks[i].x = x+cos(b.rock_rot+i*pi2/16)*80
			b.rocks[i].y = y+sin(b.rock_rot+i*pi2/16)*80
		else
			b.rocks[i].x = x-cos(b.rock_rot+i*pi2/16)*40
			b.rocks[i].y = y-sin(b.rock_rot+i*pi2/16)*40
		end
	end
end

function create_moon_rocks(b)
	local x,y = b:pos()
	x=x+16 y=y+20

	for a=0, 8 do
		local nx=cos(a*pi2/8)*40
		local ny=sin(a*pi2/8)*30
		new_exp(3, x+nx,y+ny+2)
		table.insert(b.rocks,new_enemy(6,x+nx, y+ny,b))
	end
	
end

function create_green_fire(b)
	local x,y = b:pos()
	x=x+16 y=y+20

	for a=0, 16 do
		local nx=cos(a*pi2/16)*40
		local ny=sin(a*pi2/16)*30
		new_exp(3, x+nx,y+ny+2)
		table.insert(b.rocks,new_enemy(8,x+nx, y+ny,b))
	end
	
end

function boss1_sht1(b,sht)
	local x,y = b:pos()
	x=x+16 y=y+20
	local a=atan2(pl.y-y,pl.x-x)
	if sht%2==0 then
		a=a+0.2
	end

	--print(floor(x).." "..floor(y),0,80)
	new_bullet(1,x,y, cos(a)*1.25, sin(a)*1.25)
	new_bullet(1,x,y, cos(a+0.37)*1, sin(a+0.37)*1)
	new_bullet(1,x,y, cos(a-0.37)*1, sin(a-0.37)*1)
end


enemy_def={
--bat
[1]={
l=1,s=257,rx=0,ry=0,rw=10,rh=8,a_id=1,
anim={257,258},dmg=1,
hit=function(m,dmg)
	m.l=m.l-dmg
	if m.l<=0 then
		m.run=false
		for i=1,rand(3,6) do
			new_exp(1,m.rx+rand(-4,4),m.ry+rand(-4,4))
		end
	end
end,
u=function(m)
	m.a=m.a-m.arg[3]
	m.b=sin(m.t*m.arg[1])*m.arg[2]
	en_up(m,-4,-2)
	if m.x+m.a<-16 then m.run=false end
	if m.t%10==0 then en_anim(m) end
end,
d=function(m)
	spr(m.s,m.x+m.a-6,m.y+m.b-6,c0,2)
	--rect(me.rx,me.ry,me.rw,me.rh,c4)
end
},

--eye
[2]={
l=5,s=274,rx=0,ry=0,rw=10,rh=8,a_id=1,anim={275,274},
ht=0,sx=0,sy=0,dmg=1,
hit=function(m,dmg)
	m.l=m.l-dmg
	m.ht=5
	if m.l<=0 then
		m.run=false
		for i=1,rand(3,6) do
			new_exp(1,m.rx+rand(-2,2),m.ry+rand(-2,2))
		end
	end
end,
u=function(m)
	if m.t<60 then m.a=outQuad(m.t,m.sx,m.arg[1],60) end
	if m.t==90 then m.sx=m.a end
	if m.t>200 then m.a=inQuad(m.t-200,m.sx,m.sx-200,200) end
	if m.t>400 then run=false end

	m.b=sin(m.t*0.05)*10
	local x=m.x+m.a
	local y=m.y+m.b
	if m.t>60 and m.t<220 and m.t%50==0 then
		local dx,dy=bullet_dir(x,y,pl.x,pl.y,1)
		new_bullet(1,x,y+4,dx,dy)
	end
	en_up(m,-4,-2)
	if m.x+m.a<-16 then m.run=false end
	if m.ht>0 then m.ht=m.ht-1 end
	if m.t%5==0 then en_anim(m) end
end,
d=function(m)
	if(m.ht>0) then
		pal(c2,c4)
		pal(c4,c2)
		pal(c1,c3)
	end
	spr(m.s,m.x+m.a-6,m.y+m.b-6,c0,2)
	pal()
end
},

--bunny
[3]={
l=6,s=259,rx=0,ry=0,rw=10,rh=12,a_id=1,anim={260,261,260,259},
ht=0,sh_t=0,sx=0,sy=0,dmg=1,
hit=function(m,dmg)
	m.l=m.l-dmg
	m.ht=2
	if m.l<=0 then
		m.run=false
		for i=1,rand(3,6) do
			new_exp(1,m.rx+rand(-2,2),m.ry+rand(-2,2))
		end
	end
end,
u=function(m)
	m.a=m.a+cam.sx
	if m.t<m.arg[1] then
		if m.t%8==0 then
			en_anim(m)
		end
		m.a=m.a-0.25
	end
	local x=m.x+m.a
	local y=m.y+m.b
	if m.t>m.arg[1] and m.t<m.arg[2] then
		if m.t%30==0 then
			m.sh_t=10
			local dx,dy=bullet_dir(x-6,y+2,pl.x,pl.y,1)
			new_bullet(1,x-6,y+2,dx,dy)
		end
		if m.sh_t>0 then
			m.s=262
			m.sh_t=m.sh_t-1
		else
			m.s=260
		end
	end

	if m.t>m.arg[2] then
		if m.t%8==0 then
			en_anim(m)
		end
		m.a=m.a-0.25
	end
	en_up(m,-4,-2)
	if m.ht>0 then m.ht=m.ht-1 end
	if m.x+m.a<-16 then m.run=false end

end,
d=function(m)
	if(m.ht>0) then
		pal(c2,c4)
		pal(c4,c2)
		pal(c1,c3)
	end
	spr(m.s,m.x+m.a-6,m.y+m.b-6,c0,2)
	pal()
	--rectb(m.rx,m.ry,m.rw,m.rh,5)
end
},

--Moon enemy
[4]={
l=50,ht=0,yinc=0,
rx=0,ry=0,rw=0,rh=0,dmg=0,moves={{180,30},{160,40},{140,20},{150,60},{190,60},{200,20},{120,40}},
sh_type=1, shooting=false;
sh_time=100, shoots=10, rock_rot=0,
rocks={},
tnext=0,--time for next move
inext=1,--next index in the moves
smove=0,--move start time
from={0,0},
hit=function(m,dmg)
	if m.t>600 and m.l>0 then
		m.ht=2
		m.l=m.l-dmg
		if m.l<=0 then
			m.t=0
			m.tnext=5
			for k,v in pairs(m.rocks) do
				v.parent_run=false
			end
			for k,v in pairs(e_bullets) do
				v.run=false
				new_exp(1,v.x,v.y)
			end
		end
	end
end,
u=function(m)
	if m.l>0 then
		--a=[[
		if m.t==5 then exp_wait=60 sfx(59,0) end
		if m.t==150 then exp_wait=60 sfx(59,0) end
		if m.t==280 then exp_wait=60 sfx(59,0) end
		if m.t>5 and m.t<50 then 
			m.a=rand()*2
			m.b=rand()*2
		end
		if m.t>150 and m.t<200 then
			m.a=rand()*2
			m.b=rand()*2
		end
		if m.t>280 and m.t<330 then
			m.a=rand()*2
			m.b=rand()*2
		end

		if m.t>400 and m.t<550 then
			m.a=inOutQuad(m.t-400,0,m.moves[1][1]-m.x,150)
			m.b=inOutQuad(m.t-400,0,m.moves[1][2]-m.y,150)
		end
		--]]
		if m.t==600 then
			music(1)
			m.rw=24
			m.rh=28
			create_moon_rocks(m)
			m.dmg=1
		end
		--starts enemy main logic
		if m.t>600 then
			--update rock positions
			m.rock_rot=m.rock_rot+0.01
			move_rocks(m)

			m.yinc=sin(m.t*0.02)*5
			if m.tnext<m.t then
				m.tnext=m.t+200+rand()*50
				m.inext = floor(1+rand()*(#m.moves-1))
				m.smove=m.t
				from={m.a, m.b}
			end
			if m.t<m.smove+100 then
				m.a=inOutQuad(m.t-m.smove,from[1],m.moves[m.inext][1]-m.x-from[1],150)
				m.b=inOutQuad(m.t-m.smove,from[2],m.moves[m.inext][2]-m.y-from[2],150)
			end

			m.sh_time=m.sh_time-1
			--shoot patterns
			--shot type 1
			if m.sh_time==0 then
				m.shooting=true
				m.sh_type=1
				m.sh_time = 0
				m.shoots=10
			end

			if m.shooting then
				if m.sh_type==1 then
					if m.t%30==0 then
						if m.shoots>0 then
							boss1_sht1(m, m.shoots)
						else
							m.shooting=false
							m.sh_time = 60
						end
						m.shoots=m.shoots-1
					end
				end
			end

		end
	end
	en_up(m,4,2+m.yinc)
	local x = m.x+m.a
	local y = m.y+m.b+m.yinc
	if m.ht>0 then m.ht=m.ht-1 end

	--death animation
	if m.l<=0 then
		if m.t==m.tnext then
			for i=0,15 do 
				new_exp(1,x+14+rand()*30-15,y+16+rand()*30-15)
			end
			m.tnext=m.t+floor(10+rand()*15)
		end
		m.a=m.a+0.5
		m.b=m.b-0.1
		if m.t>300 then
			m.run=false
			pl.ht=0
			pl.walk=false
			pl.sh_t=0
			pl_state=3

			--kill all shoots

		end
	end
end,
d=function(m)
	if(m.ht>0) then
		pal(c2,c4)
		pal(c4,c2)
		pal(c1,c3)
	end
	spr(272,m.x+m.a,m.y+m.b+m.yinc,c0,2,0,0,2,2)
	if m.l>0 then
		if m.t>600 then
			spr(276,m.x+m.a+6,m.y+m.b+8+m.yinc,c0,2)
			if m.shooting then
				spr(277,m.x+m.a+6,m.y+m.b+8+m.yinc,c0,2)
			end
		end
	else
		spr(283,m.x+m.a+6,m.y+m.b+8+m.yinc,c0,2)
	end
	--rectb(m.rx,m.ry,m.rw,m.rh,5)
	--for k,v in pairs(m.moves) do
	--	rectb(v[1],v[2],4,4,5)
	--end
	pal()
end,
pos=function(m)
	return m.x+m.a, m.y+m.b+m.yinc
end
},
--robot(same as bunny)
[5]={
l=6,s=294,rx=0,ry=0,rw=10,rh=12,a_id=1,anim={294},
ht=0,sh_t=0,sx=0,sy=0,dmg=1,
hit=function(m,dmg)
	m.l=m.l-dmg
	m.ht=2
	if m.l<=0 then
		m.run=false
		for i=1,rand(3,6) do
			new_exp(1,m.rx+rand(-2,2),m.ry+rand(-2,2))
		end
	end
end,
u=function(m)
	m.a=m.a+cam.sx
	if m.t<m.arg[1] then
		if m.t%8==0 then
			en_anim(m)
		end
		m.a=m.a-0.25
	end
	local x=m.x+m.a
	local y=m.y+m.b
	if m.t>m.arg[1] and m.t<m.arg[2] then
		if m.t%30==0 then
			m.sh_t=10
			local dx,dy=bullet_dir(x-6,y+2,pl.x,pl.y,1)
			new_bullet(1,x-6,y+2,dx,dy)
		end
		if m.sh_t>0 then
			m.s=293
			m.sh_t=m.sh_t-1
		else
			m.s=294
		end
	end

	if m.t>m.arg[2] then
		if m.t%8==0 then
			en_anim(m)
		end
		m.a=m.a-0.25
	end
	en_up(m,-4,-2)
	if m.ht>0 then m.ht=m.ht-1 end
	if m.x+m.a<-16 then m.run=false end

end,
d=function(m)
	if(m.ht>0) then
		pal(c2,c4)
		pal(c4,c2)
		pal(c1,c3)
	end
	spr(m.s,m.x+m.a-6,m.y+m.b-6,c0,2)
	pal()
	--rectb(m.rx,m.ry,m.rw,m.rh,5)
end
},

--enemy rock, follows the moon boss
[6]={
l=10,s=294,rx=0,ry=0,rw=10,rh=12,a_id=1,anim={294},
ht=0,sh_t=0,sx=0,sy=0,dmg=1,parent_run=true,
hit=function(m,dmg)
	m.l=m.l-dmg
	m.ht=2
	if m.l<=0 then
		m.run=false
		for i=1,rand(3,6) do
			new_exp(1,m.rx+rand(-2,2),m.ry+rand(-2,2))
		end
	end
end,
u=function(m)
	if not m.parent_run then
		m.l=0
		m:hit(1)
	end
	en_up(m,-4,-2)
	if m.ht>0 then m.ht=m.ht-1 end
	if m.x+m.a<-16 then m.run=false end
end,
d=function(m)
	if(m.ht>0) then
		pal(c2,c4)
		pal(c4,c2)
		pal(c1,c3)
	end
	spr(280,m.x+m.a-6,m.y+m.b-6,0,2)
	pal()
	--rectb(m.rx,m.ry,m.rw,m.rh,5)
end
},
--Green Moon enemy
[7]={
l=50,ht=0,yinc=0,
rx=0,ry=0,rw=0,rh=0,dmg=0,moves={{180,30},{160,40},{140,20},{150,60},{190,60},{200,20},{120,40}},
sh_type=1, shooting=false;
sh_time=100, shoots=10, rock_rot=0,
rocks={},
tnext=0,--time for next move
inext=1,--next index in the moves
smove=0,--move start time
from={0,0},
hit=function(m,dmg)
	if m.t>600 and m.l>0 then
		m.ht=2
		m.l=m.l-dmg
		if m.l<=0 then
			m.t=0
			m.tnext=5
			for k,v in pairs(m.rocks) do
				v.parent_run=false
			end
			for k,v in pairs(e_bullets) do
				v.run=false
				new_exp(1,v.x,v.y)
			end
		end
	end
end,
u=function(m)
	if m.l>0 then
		--a=[[
		if m.t==5 then exp_wait=60 sfx(59,0) end
		if m.t==150 then exp_wait=60 sfx(59,0) end
		if m.t==280 then exp_wait=60 sfx(59,0) end
		if m.t>5 and m.t<50 then 
			m.a=rand()*2
			m.b=rand()*2
		end
		if m.t>150 and m.t<200 then
			m.a=rand()*2
			m.b=rand()*2
		end
		if m.t>280 and m.t<330 then
			m.a=rand()*2
			m.b=rand()*2
		end

		if m.t>400 and m.t<550 then
			m.a=inOutQuad(m.t-400,0,m.moves[1][1]-m.x,150)
			m.b=inOutQuad(m.t-400,0,m.moves[1][2]-m.y,150)
		end
		--]]
		if m.t==600 then
			music(1)
			m.rw=24
			m.rh=28
			create_green_fire(m)
			m.dmg=1
		end
		--starts enemy main logic
		if m.t>600 then
			--update rock positions
			m.rock_rot=m.rock_rot+0.03
			move_green(m)

			m.yinc=sin(m.t*0.02)*5
			if m.tnext<m.t then
				m.tnext=m.t+200+rand()*50
				m.inext = floor(1+rand()*(#m.moves-1))
				m.smove=m.t
				from={m.a, m.b}
			end
			if m.t<m.smove+100 then
				m.a=inOutQuad(m.t-m.smove,from[1],m.moves[m.inext][1]-m.x-from[1],150)
				m.b=inOutQuad(m.t-m.smove,from[2],m.moves[m.inext][2]-m.y-from[2],150)
				m.a=m.a-1
			end

			m.sh_time=m.sh_time-1
			--shoot patterns
			--shot type 1
			if m.sh_time==0 then
				m.shooting=true
				m.sh_type=1
				m.sh_time = 0
				m.shoots=10
			end

			if m.shooting then
				if m.sh_type==1 then
					if m.t%20==0 then
						if m.shoots>0 then
							boss1_sht1(m, m.shoots)
						else
							m.shooting=false
							m.sh_time = 60
						end
						m.shoots=m.shoots-1
					end
				end
			end

		end
	end
	en_up(m,4,2+m.yinc)
	local x = m.x+m.a
	local y = m.y+m.b+m.yinc
	if m.ht>0 then m.ht=m.ht-1 end

	--death animation
	if m.l<=0 then
		if m.t==m.tnext then
			for i=0,15 do 
				new_exp(1,x+14+rand()*30-15,y+16+rand()*30-15)
			end
			m.tnext=m.t+floor(10+rand()*15)
		end
		m.a=m.a+0.5
		m.b=m.b-0.1
		if m.t>300 then
			m.run=false
			pl.ht=0
			pl.walk=false
			pl.sh_t=0
			pl_state=3

			--kill all shoots

		end
	end
end,
d=function(m)
	if(m.ht>0) then
		pal(c2,c4)
		pal(c4,c2)
		pal(c1,c3)
	end
	spr(326,m.x+m.a,m.y+m.b+m.yinc,c0,2,0,0,2,2)
	if m.l>0 then
		if m.t>600 then
			spr(328,m.x+m.a+6,m.y+m.b+8+m.yinc,c0,2)
			if m.shooting then
				spr(344,m.x+m.a+6,m.y+m.b+8+m.yinc,c0,2)
			end
		end
	else
		spr(360,m.x+m.a+6,m.y+m.b+8+m.yinc,c0,2)
	end
	--rectb(m.rx,m.ry,m.rw,m.rh,5)
	--for k,v in pairs(m.moves) do
	--	rectb(v[1],v[2],4,4,5)
	--end
	pal()
end,
pos=function(m)
	return m.x+m.a, m.y+m.b+m.yinc
end
},
--green enemy fireball, follows the moon boss
[8]={
l=10,s=294,rx=0,ry=0,rw=10,rh=12,a_id=1,anim={324,340},
ht=0,sh_t=0,sx=0,sy=0,dmg=1,parent_run=true,
hit=function(m,dmg)
	m.l=m.l-dmg
	m.ht=2
	if m.l<=0 then
		m.run=false
		for i=1,rand(3,60) do
			new_exp(1,m.rx+rand(-2,2),m.ry+rand(-2,2))
		end
	end
end,
u=function(m)
	if not m.parent_run then
		m.l=0
		m:hit(1)
	end
	en_up(m,-4,-2)
	if m.ht>0 then m.ht=m.ht-1 end
	if m.x+m.a<-16 then m.run=false end
end,
d=function(m)
	if(m.ht>0) then
		pal(c2,c4)
		pal(c4,c2)
		pal(c1,c3)
	end
	
	if m.t%10<5 then spr(324,m.x+m.a-6,m.y+m.b-6,0,2)
	else spr(340,m.x+m.a-6,m.y+m.b-6,0,2) end
	
	pal()
	--rectb(m.rx,m.ry,m.rw,m.rh,5)
end
},

}

--add enemy to spawn list
function add_enemy(type,x,y,t,arg)
	spawns[t]={x=x,y=y,type=type,arg=arg}
end

--spàwn groups
function enGroup1(type,x,y,t,arg)
	for i=1,5 do add_enemy(type,x,y,t+i*42,arg)end
end

--spawn enemy
function new_enemy(type,x,y,arg)
	local def=enemy_def[type]
	local e={x=x,y=y,a=0,b=0,t=0,run=true,arg=arg}
	for k,v in pairs(def) do
		e[k]=v
	end
	table.insert(enemies,e)
	return e
end

function update_enemies()
	local s=spawns[tick]
	if s~=nil then
		new_enemy(s.type,s.x,s.y,s.arg)
	end
	for k,v in pairs(enemies) do
		v:u()
		if not v.run then
			table.remove(enemies,k)
		end
	end
end

function draw_enemies()
	for _,v in pairs(enemies) do v:d() end
end

-----------------
-- Player
-----------------
--horrible hack for player-map collisions
function map_col(dx,dy)
	local offx,offy,offw,offh
	local checkR=function(y,v)
		offx=v[5]-v[1]*16
		offy=v[6]-v[2]*16
		local mx=floor((pl.x-cam.x+8+dx-offx)/16)
		local my=floor((pl.y-cam.y+y-offy)/16)
		if mx<v[1] or mx>v[3] or my<v[2] or my>v[4] then return end
		if fget(mget(mx,my),1) then
			dx=0
			pl.x=mx*16-8+cam.x+offx
		end
	end
	local checkL=function(y,v)
		offx=v[5]-v[1]*16
		offy=v[6]-v[2]*16
		local mx=floor((pl.x-cam.x-6+dx-offx)/16)
		local my=floor((pl.y-cam.y+y-offy)/16)
		if mx<v[1] or mx>v[3] or my<v[2] or my>v[4] then return end
		if fget(mget(mx,my),1) then
			dx=0
			pl.x=mx*16+16+6+cam.x+offx
		end
	end
	local checkB=function(x,v)
		offx=v[5]-v[1]*16
		offy=v[6]-v[2]*16
		local mx=floor((pl.x-cam.x+x-offx)/16)
		local my=floor((pl.y-cam.y+10+dy-offy)/16)
		if mx<v[1] or mx>v[3] or my<v[2] or my>v[4] then return end
		
		if fget(mget(mx,my),1) then
			dy=0
			pl.y=my*16-10+cam.y+offy
			if cam.sx~=0 or dx~=0 then
				pl.walk=true
			end
		end
	end
	local checkT=function(x,v)
		offx=v[5]-v[1]*16
		offy=v[6]-v[2]*16
		local mx=floor((pl.x-cam.x+x-offx)/16)
		local my=floor((pl.y-cam.y-7+dy-offy)/16)
		if mx<v[1] or mx>v[3] or my<v[2] or my>v[4] then return end
		if fget(mget(mx,my),1) then
			dy=0
			pl.y=my*16+16+7+cam.y+offy
		end
	end
	for k,v in pairs(maps)do
		checkR( 9,v)
		checkR(-6,v)
		checkL( 9,v)
		checkL(-6,v)
		checkT(-6,v)
		checkT( 7,v)
		checkB(-6,v)
		checkB( 7,v)
	end
	--end
	pl.x=pl.x+dx
	pl.y=pl.y+dy
end


function pl_shot(x,y)
	local s={type=1,dmg=1,x=x,y=y,s=5,t=0,rx=0,ry=0,rw=6,rh=6,run=true}
	if exp_wait<=0 then sfx(63,37,-1,sfxch) end
	table.insert(p_bullets,s)
end

function pl_bomb(x,y)
	local s={type=2,dmg=5,x=x,y=y,sx=1,sy=0,t=0,rx=0,ry=0,rw=6,rh=6,run=true}
	table.insert(p_bullets,s)
end

function update_pl_bullets()
	for k,v in pairs(p_bullets) do
		if v.type==1 then
			v.x=v.x+v.s
			v.rx=v.x-2
			v.ry=v.y-2
		end
		if v.type==2 then
			v.x=v.x+v.sx
			v.y=v.y+v.sy
			v.rx=v.x-2
			v.ry=v.y-2
			v.sx=v.sx-0.025
			v.sy=v.sy+0.06
			if v.sx<0 then v.sx=0 end
			if v.sy>4 then v.sy=4 end
		end

		--ckeck enemy col
		for ek,ev in pairs(enemies) do
			if obj_hit(v,ev) then
				v.run=false
				ev:hit(v.dmg)
				if v.type==2 then
					new_exp(1,v.x,v.y)
				end
			end
		end

		if v.x>250 or v.y>140 then
			v.run=false
		end
		if not v.run then
			table.remove(p_bullets,k)
		end
	end
end

function draw_pl_bullets(x,y)
	for _,v in pairs(p_bullets) do
		if v.type==1 then
			circ(v.x,v.y,2,c2)
			circ(v.x,v.y,1,c4)
		end
		if v.type==2 then
			spr(290,v.x-8,v.y-8,0,2)
		end
	end
end

function update_player()
	local dx,dy=0,0
	pl.walk=false
	if btn(0) then dy=-pl.speed end
	if btn(1) then dy=pl.speed end
	if btn(2) then dx=-pl.speed end
	if btn(3) then dx=pl.speed end

	if pl.x+dx<6 then pl.x=8 pl.dx=0 end
	if pl.x+dx>228 then pl.x=226 pl.dx=0 end
	if pl.y+dy<2 then pl.y=4 end
	if pl.y+dy>128 then pl.y=126 end

	map_col(dx,dy)
	pl.mx=pl.x-6
	pl.my=pl.y-6

	if pl.ht>0 then
		pl.ht=pl.ht-1
	else
		for k,v in pairs(e_bullets) do
			if obj_hit(pl,v) then
				pl:hurt(v.dmg)
				v.run=false
			end
		end
		for k,v in pairs(enemies) do
			if obj_hit(pl,v) then
				pl:hurt(v.dmg)
			end
		end
	end

	if pl.x<0 then
		pl:hurt(1000)
	end

	pl.rx=pl.x-2
	pl.ry=pl.y-2

	if(btn(4))then	
		if pl.sh_t<=1 then
			pl.sh_t=15
			pl_shot(pl.x+16,pl.y+2)
		end
	end
	if(btn(5))then	
		if pl.bomb_t<=1 then
			pl.bomb_t=30
			pl_bomb(pl.x+4,pl.y+6)
		end
	end

	if pl.sh_t>0 then
		pl.sh_t=pl.sh_t-1
	end

	if pl.bomb_t>0 then
		pl.bomb_t=pl.bomb_t-1
	end
end

function draw_player(x,y)
	if pl.ht > 0 then
		if pl.ht%4~=0 then
			return
		end
	end
	rect(x-2,y-10,2,2,c2)
	rect(x-2,y-8,4,2,c2)
	
	rect(x-6,y+6,18,2,c2)
	rect(x-10,y+6,4,2,c4)
	rect(x-12,y+4,6,2,c4)
	rect(x-12,y+8,6,2,c4)
	
	if pl.walk then
		if tick%10==0 then
			if pl.walks==265 then pl.walks=256 else pl.walks=265 end
		end
		spr(pl.walks,x-6,y-6,c0,2)
	else
		spr(256,x-6,y-6,c0,2)
	end
	if pl.sh_t>0 then
		rect(x+6,y+2,8,2,c2)
		rect(x+8,y+2,2,2,c4)
	else
		rect(x+4,y+6,2,2,c4)
	end

	if pl.bomb_t-5>0 then
		rect(x+2,y+4,2,2,c4)
	else
		rect(x,y+6,2,2,c4)
	end
	--rectb(pl.rx,pl.ry,pl.rw,pl.rh,9)
	--rectb(pl.mx,pl.my,pl.mw,pl.mh,5)
end


function hud_text(text,x,y,ca,cb)
	print(text,x+1,y,cb)
	print(text,x-1,y,cb)
	print(text,x,y+1,cb)
	print(text,x,y-1,cb)
	print(text,x,y,ca)
end

function draw_hud()
	--remaining lives
	spr(268,0,0,0,2)
	hud_text("x"..pl.l,16,8,c4,c2)
	for i=1,max_health do
		spr(267,18+i*16,2,0,2)
	end
	for i=1,pl.h do
		spr(266,18+i*16,2,0,2)
	end

end


function update_cam()
	cam.x=cam.x+cam.sx
	cam.y=cam.y+cam.sy
end

---------------------------------
function update_pregame()
	music()
	tick=tick+1
	if pl.l > 0 and not win then
		if tick>150 then
			init_game()
			update=update_game
			draw=draw_game
		end
	else
		if tick>300 then
			m_scr:init()
			update=update_main_screen
			draw=draw_main_screen
			pl.l=3
			win=false
		end
	end
end

function draw_pregame()
	local x,y=100,60
	if pl.l > 0 and not win then
		spr(268,x,y,0,2)
		hud_text("x"..pl.l, x+16, y+8,c4,c2)
	else
		halfway=false
		halfway2=false
		level=1
		if win then
			hud_text("THANK YOU FOR PLAYING ! ! !", 50, 68,c4,c2)
		else
			hud_text("GAME OVER", 90, 68,c4,c2)
		end
	end
end

--intro state animation
function update_player_intro()
	pl.introt=pl.introt+1
	pl.x= outQuad(pl.introt,-50,140,150)
	pl.y= outBack(pl.introt,-20,70,150)
	if pl.introt>150 then
		pl.introt=0
		pl_state=1
	end
	if pl.introt<120 and pl.introt%2==0 then
		new_exp(2,pl.x-6,pl.y+6,1)
	end
end

--when player win, and leaves the level
function update_player_outro()
	pl.introt=pl.introt+1
	pl.x=pl.x+inQuad(pl.introt,0,10,150)
	pl.y=pl.y+inQuad(pl.introt,0,-1,150)

	if pl.introt>150 then
		pl.introt=0
		pl_state=1
		reset_all()
		if level==max_level then
			win=true
			level=1
		end
		level=level+1
		play_intro=true
		update=update_pregame
		draw=draw_pregame
	end
	if pl.introt%2==0 then
		new_exp(2,pl.x-6,pl.y+6,1)
	end
end

------------------------
--player death animation
------------------------
function player_die()
	pl_state=2
	pl_dead.t=0
	pl_dead.x=pl.x
	pl_dead.y=pl.y
	pl_dead.bx=pl.x
	pl_dead.by=pl.y
	pl_dead.binc=0
end

function update_player_death()
	pl_dead.t=pl_dead.t+1
	
	--spawn explosions
	if pl_dead.t==1 then
		for i=0,8 do new_exp(1,pl.x+rand()*26-13,pl.y+rand()*26-13) end
	end 
	if pl_dead.t==5 then
		for i=0,8 do new_exp(1,pl.x+rand()*26-13,pl.y+rand()*26-13) end 
	end

	if pl_dead.binc<45 then
		pl_dead.binc=pl_dead.binc+1
		pl_dead.bx=pl_dead.bx+0.5
		pl_dead.x=pl_dead.x+0.5
	end
	pl_dead.bx=pl_dead.bx+0.5
	pl_dead.by=pl_dead.by+sin(pl_dead.binc*-0.1)*2
	--broom rotation
	if tick%4==0 then
		pl_dead.ba=pl_dead.ba+1
		if pl_dead.ba>8 then
			pl_dead.ba=1
		end
	end

	if tick%6==0 then
		if pl_dead.s==269 then pl_dead.s=270 else pl_dead.s=269 end
	end
	
	pl_dead.x=pl_dead.x+0.2
	pl_dead.y=pl_dead.y+sin(pl_dead.binc*-0.1)*1.5
	--pl.x=pl_dead.x
	--pl.y=pl_dead.y
	if pl_dead.t > 200 then
		pl_dead.t=0
		reset_all()
		pl.l=pl.l-1
		update=update_pregame
		draw= draw_pregame
	end
end

function draw_player_death()
	--broom
	br={{281,0,0},{282,0,0},{281,0,1},{282,1,0},{281,1,0},{282,2,1},{281,0,3},{282,2,0}}
	spr(br[pl_dead.ba][1],pl_dead.bx, pl_dead.by,0,2,br[pl_dead.ba][2],br[pl_dead.ba][3])
	rect(pl_dead.x+4,pl_dead.y-4,2,2,c2)
	rect(pl_dead.x+4,pl_dead.y-2,4,2,c2)
	spr(pl_dead.s, pl_dead.x, pl_dead.y,0,2)
end



-------------
function initMenu()
	
end

function updMenu()
	
end

function drwMenu()

end

-------------
function initLv1()
	sfxch=3
	update_level= update_lv1
	cam.sx=-0.5
	reset_all()
	if halfway == true then
		skip(3000)
	end
	pl.x=80
	pl.y=50
	if play_intro then
		pl.x=0
		pl.y=0
		pl_state=0
		play_intro=false
	end
	
	music(0)
	--stars
	for i=0,50 do
		table.insert(stars,{x=rand(240),y=rand(100)})
	end
	
    moon={s=272,x=150,y=15}
    --maps
    table.insert(maps,{0,0,151,9,160,0})
	table.insert(maps,{0,12,9,16,0,64})

	--enemies
	enGroup1(1,240,46,160,{-0.04,30,1.2})
	enGroup1(1,240,66,350,{0.04,10,1.2})
	enGroup1(1,241,26,650,{0.06,20,1.1})
	enGroup1(1,240,76,670,{-0.06,10,1})
	add_enemy(2,240,60,1050,{rand(-100,-80)})
	add_enemy(2,240,40,1000,{rand(-80,-60)})
	add_enemy(2,240,30,1100,{rand(-60,-40)})
	add_enemy(2,240,30,1150,{rand(-60,-40)})
	add_enemy(3,240,102,550,{rand(60,100), rand(200,350)})
	add_enemy(3,240,102,1000,{rand(60,100), rand(200,350)})
	add_enemy(3,240,70,1330,{rand(60,100), rand(200,350)})
	add_enemy(3,240,102,1580,{rand(60,100), rand(200,350)})
	add_enemy(3,240,118,1810,{rand(60,100), rand(200,350)})
	enGroup1(1,240,56,1970,{-0.1,10,1})
	enGroup1(1,240,60,2000,{-0.05,40,1})
	add_enemy(3,240,118,2220,{rand(60,100), rand(200,350)})
	add_enemy(2,240,60,2450,{rand(-100,-80)})
	add_enemy(2,240,40,2450,{rand(-80,-60)})
	add_enemy(2,240,30,2500,{rand(-60,-40)})
	add_enemy(2,240,30,2550,{rand(-60,-40)})
	add_enemy(3,240,102,2990,{rand(60,100), rand(200,350)})
	add_enemy(3,240,102,3500,{rand(60,100), rand(200,350)})
	
	enGroup1(1,240,66,2600,{-0.1,10,1})
	enGroup1(1,240,40,2800,{-0.05,40,1})
	enGroup1(1,240,76,3000,{-0.1,30,1})
	enGroup1(1,240,60,3200,{-0.05,50,1})

	enGroup1(1,240,56,3500,{-0.1,10,1})
	enGroup1(1,240,60,3700,{-0.05,40,1})

	add_enemy(2,240,80,3750,{rand(-100,-80)})
	add_enemy(2,240,60,3800,{rand(-80,-60)})
	add_enemy(2,240,50,3850,{rand(-60,-40)})
	add_enemy(2,240,50,3900,{rand(-60,-40)})

end

------------------

function initLv2()
	sfxch=1	
	update_level= update_lv2
	cam.sx=-0.5
	reset_all()
	if halfway2 == true then
		skip(2980)
	end
	pl.x=80
	pl.y=50
	if play_intro then
		pl.x=0
		pl.y=0
		pl_state=0
		play_intro=false
	end
	music(2)
	--stars
	for i=0,50 do
		table.insert(stars,{x=rand(240),y=rand(100)})
	end
	moon={s=304,x=150,y=15}
    --maps
    table.insert(maps,{0,17,178,32,160,0})
	table.insert(maps,{0,12,9,16,0,64})
	--table.insert(maps,{0,12,9,16,0,64})
		add_enemy(2,240,60,100,{rand(-100,-80)})
		add_enemy(2,240,80,650,{rand(-100,-80)})
		add_enemy(2,240,40,950,{rand(-100,-80)})
		add_enemy(2,240,54,2250,{rand(-100,-80)})
		add_enemy(2,240,18,2360,{rand(-100,-80)})
		add_enemy(2,240,30,2840,{rand(-100,-80)})
		add_enemy(2,240,60,2870,{rand(-100,-80)})
		add_enemy(2,240,90,2900,{rand(-100,-80)})
		add_enemy(2,240,30,2940,{rand(-100,-80)})
		add_enemy(2,240,90,2970,{rand(-100,-80)})
		add_enemy(2,240,60,3000,{rand(-100,-80)})
		add_enemy(3,240,54,210,{60,555})
		add_enemy(3,240,38,1070,{20,555})
		add_enemy(3,240,102,1780,{rand(60,100), rand(200,350)})
		add_enemy(5,240,22,1400,{0,400})
		add_enemy(5,240,54,2080,{0,400})
		add_enemy(5,240,102,4020,{0,400})
		add_enemy(5,240,38,4120,{0,400})
		add_enemy(5,240,54,4600,{0,400})
		--add_enemy(3,240,118,1810,{rand(60,100), rand(200,350)})
		--add_enemy(3,240,118,1810,{rand(60,100), rand(200,350)})
		--add_enemy(3,240,118,1810,{rand(60,100), rand(200,350)})
		--add_enemy(3,240,118,1810,{rand(60,100), rand(200,350)})
		--add_enemy(3,240,118,1810,{rand(60,100), rand(200,350)})
		--add_enemy(3,240,118,1810,{rand(60,100), rand(200,350)})
		--add_enemy(3,240,118,1810,{rand(60,100), rand(200,350)})
		--add_enemy(3,240,118,1810,{rand(60,100), rand(200,350)})
		enGroup1(1,240,110,200,{-0.04,30,1.2})
		enGroup1(1,240,50,500,{-0.04,30,1.2})
		enGroup1(1,240,60,800,{-0.04,30,1.2})
		enGroup1(1,240,110,1400,{-0.04,30,1.2})
		enGroup1(1,240,95,3300,{-0.04,30,1.2})
		enGroup1(1,240,30,3500,{-0.04,30,1.2})
		enGroup1(1,240,70,3750,{-0.04,50,1.2})
		enGroup1(1,240,60,4000,{-0.04,50,1.2})
end

function update_lv1()
	if tick==4500 then
		cam.sx=0
		music()
	end
	--spawn moon boss
	if tick==4600 then
		new_enemy(4,moon.x+cam.x*0.015, moon.y+cam.y*0.015)
		moon = nil
	end

	if tick>3000 then
		halfway = true
	end
end

function update_lv2()
	if tick==5900 then
		cam.sx=cam.sx/2
		music()
	end
	if tick==6000 then
		cam.sx=0
			new_enemy(7,moon.x+cam.x*0.015, moon.y+cam.y*0.015)
	end
	if tick==3000 then
		halfway2 = true
	end
end
------------------
function skip(t)
	for i=1,t do
		update_cam()
		tick=tick+1
	end
end

function init_game()
	if level==1 then
		initLv1()
	end
	if level==2 then
		initLv2()
	end
end

function print_debug(x,y)
	print(tick,x,y,15)
	print("pl: "..pl.x.." "..pl.y,x,y+8,15)
	print("en: "..#enemies,x+0,y+16,15)
	print("bl: "..#p_bullets,x,y+24,15)
	print("e_bul: "..#e_bullets,x,y+32,15)
end

function update_game()
	update_level()
	update_maps()
	update_en_bullets()
	update_enemies()
	update_pl_bullets()
	if pl_state==0 then
		update_player_intro()
	elseif pl_state==1 then
		update_player()
	elseif pl_state==2 then
		update_player_death()
	elseif pl_state==3 then
		update_player_outro()
	end
	update_explosions()
	update_cam()
	tick=tick+1

	if btn(5) then
		if pl_state~=2 then
			--player_die()
		end
	end
end

function draw_game()
	draw_maps()
	draw_pl_bullets()
	if pl_state~=2 then
		draw_player(pl.x,pl.y)
	end
	draw_enemies()
	draw_explosions()
	draw_en_bullets()
	if pl_state==2 then
		draw_player_death()
	end
	draw_hud()
	--print_debug(0,17)
end


-----------------
--main screen data
m_scr={
	t=0,x=0,y=0,yinc=0,
	h_index=1,hat_anim={480,496},b_index=1,broom_anim={448,449},
	clouds={},press=true,
init=function(m)
	m.clouds={}
	play_intro=true
	for i=0,20 do
		local cloud={}
		for j=0,6 do
			table.insert(cloud, {j*10, rand(0,20), rand(20,30)})
		end
		table.insert(m.clouds, {i*40, rand(110,140), cloud})
	end
	--shuffle table
 	local iters = #m.clouds
    local j
    for i = iters, 2, -1 do
        j = rand(i)
        m.clouds[i], m.clouds[j] = m.clouds[j], m.clouds[i]
    end
	m.t=0
	m.x=240
	m.y=20
	for i=0,50 do
		table.insert(stars,{x=rand(240),y=rand(130)})
	end
end

}

function update_main_screen()
	m_scr.t=m_scr.t+1
	if m_scr.t > 80 and m_scr.t < 180 then
		m_scr.x= 250+outQuad(m_scr.t-80,0,-320,100)
		m_scr.y=20+outQuad(m_scr.t-80,0,40,100)
	end
	if m_scr.t==181 then
		m_scr.x=80
		m_scr.y=200
	end

	if m_scr.t>181 then
		if m_scr.t%6==0 then
			m_scr.b_index=m_scr.b_index+1
			if m_scr.b_index>#m_scr.broom_anim then
				m_scr.b_index=1
			end
		end
		if m_scr.t%4==0 then
			m_scr.h_index=m_scr.h_index+1
			if m_scr.h_index>#m_scr.hat_anim then
				m_scr.h_index=1
			end
		end
		if m_scr.t>200 and m_scr.t<300 then
			m_scr.x=-20+outBack(m_scr.t-200,0,130,100)
			m_scr.y=70+outQuad(m_scr.t-200,0,-20,100)
		end
		if m_scr.t>300 then
			m_scr.yinc=sin(m_scr.t*0.02)*4
		end
	end

	if m_scr.t>300 then
		if btn(4) then
			sfx(48,0,15,1)
			sfx(48,0,15,2)
			sfx(48,0,15,3)
			update= update_pregame
			draw=draw_pregame
		end
	end
end

function draw_main_screen()
	for _,v in pairs(stars) do
		pix(v.x,v.y,c4)
	end

	--moon
	spr(272,30,36,0,2,0,0,2,2)

	for i=1, #m_scr.clouds do
		v=m_scr.clouds[i]
		v[1]=v[1]-0.1-i*0.02
		if(v[1]<-200) then
			v[1]=v[1]+500
		end
		for l,w in pairs(v[3]) do
			circ(v[1]+w[1],v[2]+w[2],w[3]+2,c2)
		end
		for l,w in pairs(v[3]) do
			circ(v[1]+w[1],v[2]+w[2],w[3],c4)
		end
	end

	--title

		if tt==576 then tt=0 tx=true end
		if tt==0 then sfx(50,24,-1,1) end
		if tt==48 then sfx(51,36,-1,1) end
		if tt==96 then sfx(52,24,-1,1) end
		if tt==144 then sfx(50,23,-1,1) end
		if tt==192 then sfx(53,35,-1,1) end
		if tt==288 then sfx(50,22,-1,1) end
		if tt==336 then sfx(51,34,-1,1) end
		if tt==384 then sfx(52,22,-1,1) end
		if tt==432 then sfx(50,21,-1,1) end
		if tt==480 then sfx(53,33,-1,1) end
	
		if tx==true then
			if tt==0 then 
				sfx(54,31,-1,2,13) 
				sfx(31,24,-1,3,8)
			end
			if tt==408 then sfx(55,29,-1,2,13) end
			if tt==288 then sfx(54,29,-1,2,13) end
			if tt==120 then sfx(55,31,-1,2,13) end
			if tt==144 then sfx(31,23,-1,3,8) end
			if tt==288 then sfx(31,22,-1,3,8) end
			if tt==432 then sfx(31,21,-1,3,8) end
		end
	tt =tt+1
	
	if m_scr.t>300 then
		spr(400, 20+0,10 ,0,2,0,0,5,1)
		spr(416, 20+90,10 ,0,2,0,0,3,1)
		spr(419, 20+150,10 ,0,2,0,0,3,1)
		spr(336,6,71,0)
		spr(336,168,71,0)
		hud_text("@tinchetsu",18,72,c4,c1)
		hud_text("@RushJet1",180,72,c4,c1)
		if m_scr.t%40==0 then
			m_scr.press= not m_scr.press
		end
		if m_scr.press then
			hud_text("PRESS Z",100,120,c3,c1)
		end
		
		hud_text("Z=Shoot    X=Bombs",75,129,c3,c1)
	end

	if m_scr.t < 181 then
		spr(432, m_scr.x, m_scr.y,0,2)
	else
		spr(465, m_scr.x, m_scr.y+m_scr.yinc,0,1,0,0,3,3,0)
		spr(450, m_scr.x+8, m_scr.y+m_scr.yinc-8,0)
		spr(m_scr.broom_anim[m_scr.b_index],m_scr.x,m_scr.y+m_scr.yinc-8,0)
		spr(m_scr.hat_anim[m_scr.h_index],m_scr.x-8,m_scr.y+m_scr.yinc+16,0)
	end
end

-------------

m_scr:init()
update= update_main_screen
draw=draw_main_screen

--test levels
--play_intro=false
--init_game()
--update=update_game
--draw=draw_game

function TIC()
	cls(c1)
	update()
	draw()
end

-- <PALETTE>
-- 000:140c1444243430346d4e4a4e854c30346524ff555575716100000079103c8595a155ff55d2aa9955ffffffff55ffffff
-- </PALETTE>

-- <TILES>
-- 001:0bbbbbbbbeeeeeeebe666666be66666ebe6e6666be666666be666e66be666666
-- 002:bbbbbbbbeeeeeeee6666666666e66e666666666666e66666666666666666e666
-- 003:bbbbbbb0eeeeeeeb666666eb6666e6eb666666eb66e666eb666666eb666e66eb
-- 004:000000000b000000b0b000b0000b0b0b0bbbb000b00bbb0000bbb000000bb000
-- 005:00000000000000000000000000000000006bb0000bee6b600b6eeeb0beeeeeeb
-- 006:0000000000000000000000000000000000bbb0000bbbbbb00bbbbbb0bbbbbbbb
-- 007:0000000000000000000000000000b000000bbb0b00bbbbbb0bbbbbbbbbbbbbbb
-- 008:00000000000000000000000000000000b0000000bbbb0000bbbbb000bbbbbb00
-- 009:0000000000000000000bb00000be6b000beeeeb00b6ee6b000bbbb00000bb000
-- 010:06000600060006006e606e606e606e606e606e606e606e606e606e606e606e60
-- 011:0000b0000000b0000000b000000bb000000b0000000b000000bb0000000b0000
-- 012:000b0000000b00000000bb00000000b0000000b000000b0000000b00000000bb
-- 013:000000bb00000b0000000b00000000b0000000b00000bb00000b0000000b0000
-- 016:8888888888888888888888888888888888888888888888888888888888888888
-- 017:be666666be666666be6e66e6be666666be666666be666666be6e6e66be666666
-- 018:6666666e6666666666e66e66666666666e666666666666e66666e6666e666666
-- 019:6666e6eb666666eb6e6e66eb666666eb666666eb6e6666eb6666e6eb666666eb
-- 020:000bbb0000bbb000000bbb0000bbb000000bbb0000bbb000000bbb0000bbb000
-- 027:000b000000bb0000000b0000000bb0000000b0000000bb000000b000000bb000
-- 028:0000b000000b0000000b00000000b000000b00000bb00000b0000000b0000000
-- 029:b0000000b00000000bb00000000b00000000b000000b0000000b00000000b000
-- 033:be666666be666e66be666666be6e6666be66666ebe666666beeeeeee0bbbbbbb
-- 034:6666e6666666666666e666666666666666e66e6666666666eeeeeeeebbbbbbbb
-- 035:666e66eb666666eb66e666eb666666eb6666e6eb666666ebeeeeeeebbbbbbbb0
-- 049:0666666660000000600bbbbb60beeebb60beebbb60bebbbb60bebbbb60bbbbbb
-- 050:6666666600000000bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
-- 051:6666666000000006bbbbb006bbbbbb06bbbbbb06bbbbbb06bbbbbb06bbbbbb06
-- 052:000000060000006e000006e0000060e000060e0000600e000600e0006000e000
-- 053:e60000006600000066e00000660e00006600ee0066000ee066000e0e66000e00
-- 054:00000000000000000000000000000000000000000000000000000000eeeeeeee
-- 055:0000006e0000006600000e660000e06600ee00660ee00066e0e0006600e00066
-- 056:60000000e60000000e6000000e06000000e0600000e00600000e0060000e0006
-- 065:60bbbbbb60bbbbbb60bbbbbb60bbbbbb60bbbbbb60bbbbbb60bbbbbb60bbbbbb
-- 066:bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbebbbbbbeb
-- 067:bbbbbe06bbbbeb06bbbebb06bbebbe06bebbee06ebbeeb06bbeebb06beebbb06
-- 069:66000e00ee660e00ee6e6600006ee6660000e66e000000660000000000000000
-- 070:0bb00bb00bb00bb00bb00bb00bb00bb0666666666ee66ee60ee00ee000000000
-- 071:00e0006600e066ee0066e6ee666ee600e66e0000660000000000000000000000
-- 081:60bbbbbb60bbbbbb60bbbbbb60bbbbbb60bbbbbb600bbbbb6000000006666666
-- 082:bbbbbebbbbbbebbebbbebbeebbebbeebbebbeebbebbeebbb0000000066666666
-- 083:eebbbb06ebbbbb06bbbbbb06bbbbbb06bbbbbb06bbbbb0060000000666666660
-- 084:bbbbbb06bbbbbb06bbbbbb06bbbbbb06bbbbbb06bbbbb0060000000666666660
-- 097:60bbbbbb60bbbbbb60bbbbbb60bbbbbb60bbbbbb60bbbbbb60bbbbbe60bbbbeb
-- 098:bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
-- 099:60bbbbbb60bbbbbb60bbbbbb60bbbbbb60bbbbbb60bbbbbb60bbbbbe60bbbbeb
-- 100:bbbbbebbbbbbebbebbbebbeebbebbeebbebbeebbebbeebbbbbeebbbbbeebbbbb
-- 101:bbbbbbeebbbbbeeebbbbeeebbbbbeebbbbbeebbbbbeebbbbbeebbbbbeebbbbbb
-- 102:bbbbbbbebbbbbbebbbbbbebbbbbbebbbbbbebbbbbbebbbbbbebbbbbbebbbbbbb
-- 113:60bbbebb60bbebbe60bebbee60ebbeeb60bbeebb600eebbb6000000006666666
-- 114:bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb0000000066666666
-- 115:bbbbbb06bbbbbb06bbbbbb06bbbbbb06bbbbbb06bbbbbb06bbbbbb06bbbbbb06
-- 116:eebbbb06ebbbbb06bbbbbb06bbbbbb06bbbbbb06bbbbbb06bbbbbb06bbbbbb06
-- 117:bbbbbbbebbbbbbbbbbbbbebbbbbbebbbbbbbbbbbbbebbbbbbebbbbbbbbbbbbbb
-- 118:bbbbbbbbbbbbbbebbbbbbbbbbbbbbbbbbbbebbbbbbbbbbbb0000000066666666
-- 124:006060600000000660b0b000000b0b0660b0b000000b0b0660b0b000000b0b06
-- 129:0666666060000006600eb00660ebbb0660bbbb06600bb0066000000606666660
-- 130:0666666060000006600eb00660ebbb0660ebbb0660ebbb0660ebbb0660ebbb06
-- 131:0666666660000000600bebeb60bbbbbb60bbbbbb600bbbbb6000000006666666
-- 132:6666666600000000eeeeeeeebbbbbbbbbbbbbbbbbbbbbbbb0000000066666666
-- 133:6666666000000006eeeee006bbbbbe06bbbbbb06bbbbb0060000000666666660
-- 137:0606060660000000000b0b0b60b0b0b0000b0b0b60b0b0b00000000000606060
-- 138:06060606000000000e0e0e0eb0b0b0b00b0b0b0bb0b0b0b00000000060606060
-- 139:06060600000000000e0e0b06b0b0b0000b0b0b06b0b0b0000000000660606060
-- 140:60e0b000000b0b0660e0b000000b0b0660e0b000000b0b0660e0b000000b0b06
-- 145:60bbbe0680bbbe06ebbbbe06bbbbbe06bbbbbe06bbbbbe0600bbbe0660bbbe06
-- 146:60ebbb0660ebbb0660ebbb0660ebbb0660ebbb0660ebbb0660ebbb0660ebbb06
-- 147:0666666660000000600bebeb60ebbbbb60ebbbbb60ebbbbb60ebbb8860ebbb86
-- 148:6666666000000006eeeee006bbbbbb06bbbbbe06bbbbbb0688bbbe0668bbbb06
-- 149:60bbbbbb00ebbbbbeeebbbbbbbbbbbbbbbbbbbbbbbbbbbbb00bbbbbb60bbbbbb
-- 156:60b0b000000b0e0660b0b000000b0e0660b0b000000b0b066000000006060600
-- 161:60ebbb0660ebbb0060ebbbbe60ebbbbb60ebbbbb60ebbbbb60ebbb0860ebbb06
-- 162:60bbbb0660ebbb0660bbbb0660ebbb0660bbbb06600bb0066000000606666660
-- 163:60bbbb8660ebbb8860bbbbbb60ebbbbb60bbbbbb600eeeee6000000006666666
-- 164:68bbbe0688bbbe06bbbbbe06bbbbbe06bbbbbe06bebeb0060000000666666660
-- 165:eebbbbbbebbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
-- </TILES>

-- <SPRITES>
-- 000:00eee000066666606bbbbb00bbe6e6000beeee00006660000066000006006000
-- 001:00000000060006006e666e606e8e8e6006eee600006660000000000000000000
-- 002:0000000000000000066666006e8e8e606eeeee606e666e600600060000000000
-- 003:0ee0e00000e0e0000eeee00006e6e0000eeee0e006666600006e00000e00e000
-- 004:0ee0e00000e0e0000eeee00006e6e0000eeee0e0066666000e66e00000ee0000
-- 005:0ee0e00000e0e0000eeee00006e6e0000eeee0e006666600e0660e000e00e000
-- 006:0ee0e00000e0e0000eeee00006e6e000eeeee0e0066666000066e00000ee0000
-- 007:0eeeee00e6e6eee0eeeeeee0e666eee0eeeeeee00eeeee000606060060060060
-- 008:0eeeee00e6e6eee0eeeeeee0e666eee0ee6eeee00eeeee000606060006000600
-- 009:00eee000066666606bbbbb00bbe6e6000beeee00006660000066000000660000
-- 010:000000000ee0ee00e66e66e0e66666e00e666e0000e6e000000e000000000000
-- 011:000000000ee0ee00e88e88e0e88888e00e888e0000e8e000000e000000000000
-- 012:006000000066000000eee000066666606bbbbb00bbe6e6000beeee0000666000
-- 013:00eee000066666606bbbbb00bbe6e600ebeeee000666600000660e0006006000
-- 014:00eee000066666606bbbbb00bbe6e6000beeee00e6666e000066000000660000
-- 016:00000666000066ee0006eeee006eeeee06eee6ee66eeeeee6eee6e6e6eeeeeee
-- 017:66600000ee660000eee66000eee666006eee6660eeee6666eeeee666e6eee666
-- 018:00000000000000000e6660e006ee6e00068e666006ee66000066600000000000
-- 019:00000000000000000066600006ee6600068e6e6006ee66e00066600000000000
-- 020:ee6ee6eeeee66eee66eeee66e86ee68eeeeeeeeeee6666eee6eeee6eeeeeeeee
-- 021:ee6ee6eeeee66eee66eeee66e86ee68eeeeeeeeeee6666eeee8888eeeee88eee
-- 022:000000000000000000066666006eeeee06eeeeee66eeeeee6eeeeeee6eeeeeee
-- 023:000000000000000066600000eee60000eeee6000eeee6600eeeee600eeeee660
-- 024:00066000006ee60006e6ee606eee6ee66e6eee666eee6e60066ee60000066000
-- 025:000000000000000000000000eee000000ee66666eee000000000000000000000
-- 026:00e00000000e0000e0eee0000eee000000e06000000006000000006000000006
-- 027:eeeeeeeeee6ee6eee6eeee6e68eeee86eeeeeeeeeee88eeeee8888eeeee88eee
-- 032:6e6eeeee6eeeee6e66eeeeee06eee6ee006eeeee0006eeee0000666600000666
-- 033:eee6e666e6ee6666eeee6666eee666606e666600e66660006666000066600000
-- 034:000000000000000000066000006ee60000066000000000000000000000000000
-- 035:000600000060000000666600606e606006666000000060000006000000000000
-- 036:000006006000600006666000006e600000666600006000600600000000000000
-- 037:0066660006e66e6006666660000ee000006666000ee66ee00e6666e00e0660e0
-- 038:000000000066660006e66e6006666660006666000ee66ee00e6666e00e0660e0
-- 048:000006660008888e0e88e88888e8e8e88e888e8888888888888e8e8e8e8888e8
-- 049:66600000ee6600008ee6600088e6660088ee6660888e606688888666888ee666
-- 050:000000000000000000bbb0000beebb000b8ebbb00beebb0000bbb0000e000e00
-- 051:000000000000000000bbb0000beebb000b8ebbb00beebb0000bbb00000e0e000
-- 064:888e88888888e8e86888888806ee8888006eeeee0006e0ee0000066600000666
-- 065:8e86e66688ee66668eee6666ee0666606e606600e66000006666000066600000
-- 066:00e00e00000bb0000e0e0e00000bb00000bbbb0000bbbb0000ebbe00000ee000
-- 067:0000000000000000e0e0bbe00b0bbbbe0bebbbbee000bbe000e0000000000000
-- 068:0bb00bb0b000000bb00bb00b00bbbb0000ebbe00b00ee00bb000000b0bb00bb0
-- 069:0000000000000e000ebb000eebbbbeb0ebbbb0b00ebb0e0e0000000000000000
-- 070:00000eee0000eebb000ebbbb00ebeeee0ebbbbbbeebeeebbebbbbeeeebbbbebe
-- 071:eee00000bbee0000ebbbe000ebbebe00ebbebbe0ebbebbeeeebeeebebbbebbbe
-- 072:bbebbebbebbeebbe6ebbbbe666ebbe66bbbbbbbbbbeeeebbbebbbbebbbbbbbbb
-- 080:00eee0000eeee0000eee8e0066ee8e000eeeeeee0eeeeee000eee00000600600
-- 082:0e0ee0e000b00b000000e0000e0bb0e000bbbb0000bbbb0000ebbe00000ee000
-- 083:00000000e00e00000b00bbe0e0ebbbbee00bbbbe0b00bbe0e00e000000000000
-- 084:000bb0000b0000b0000ee000b0ebbe0bb0bbbb0b000bb0000b0000b0000bb000
-- 085:000000000000e00e0ebb00b0ebbbb00eebbbbe0e0ebb00b00000e00e00000000
-- 086:ebeeeebeebbbbebbeeeeeeeb0ebbbbbb00ebbeee000ebbbb0000eebb00000eee
-- 087:eeeeeebebebbbbbebeeeebeebebbbbe0eebbbe00ebbbe000bbee0000eee00000
-- 088:bbebbebbebbeebbe6ebbbbe666ebbe66bbbbbbbbb86868bbb888888bbb86868b
-- 102:000000e000000e0b0000b0b0000b0b0b00b0b0b00e0b0b0be0b0e0e00b0b0b0b
-- 103:e0e000000b0e0000b0b0e0000b0e0e00e0b0e0e00b0b0e0eb0b0b0e00e0b0e0e
-- 104:bbebbebbbbbeebbbb6ebbe6b66ebbe66bbbbbbbbbbbeebbbbbeeeebbbbbbbbbb
-- 118:e0e0b0b00b0b0b0be0b0b0b00e0b0e0b00e0b0b0000e0b0b0000e0e000000e0e
-- 119:b0b0b0e00e0b0e0eb0b0e0e00b0e0e00e0e0e0000e0e0000e0e000000e000000
-- 144:000000000060006006e666e606e6e6e606eeeee606eeeee606ee6ee600660660
-- 145:0000000000066000006ee6000066660006eee600006ee60006eeee6000666600
-- 146:000000000066000006ee66006eeeee6006ee660006ee6600006eee6000066600
-- 147:00000000000000000066660006eeee606eee66006eee660006eeee6000666600
-- 148:00000000066000006ee660006eeee6006ee66e606ee66e606ee66e6006600600
-- 160:000000000060000006e600006e60000006000000000000000000000000000000
-- 161:00000000066660006eeee6006ee660006eee60006ee660006eeee60006666000
-- 162:0000000000000000066060006ee6e6006eeeee606e6e6e606e6e6e6006060600
-- 163:00000000066006006ee66e606ee66e606ee66e606ee66e6006eee60000666000
-- 164:00000000066660006eeee6006ee66e606ee66e606eeee6006ee6600006600000
-- 165:0066000006ee600006ee600006ee600006ee60000066000006ee600000660000
-- 176:00000000000000000606000006600e0006b66000006600000066000006000000
-- 192:00000000066666606666666600666666000666660006666600006666000006ee
-- 193:06666000006666660006666600066666000066660000666600000666000006ee
-- 194:000000000000000060000000660000006660000066ee0000eeeee000eeeeee00
-- 209:00000eee00000eee000006660000666600066666006666bb0666bbbb6600bbbb
-- 210:ee666666666666666666666666666666bbbbbbbbbeeeeeeeee6eee6ee6e6e6e6
-- 211:00000000666666006660000060000000b0000000b0000000eb000000eb000000
-- 224:0000000000ee0000eeeeeeee00eeeeeeeeeeeeee00eeeeeeeeeeeeee00ee00e0
-- 225:0000bbbb00000bbb000006660000666600066666006666660066666600666666
-- 226:eeeeeeeebe6eeeeeeee66eee66eeeee0666666006666666e666666ee666ee66e
-- 227:eb000000e0000000000000000000000000000000e0006600ee666660e6666600
-- 240:000e0e00ee00e0e00eeeeeeeeeeeeeee0eeeeeee00eeeeee0eeeeeeeee00ee00
-- 241:000666660066666666666666e6606666e0000666e00000600000000000000000
-- 242:66eee66666eee660666666006066600000006000000000000000000000000000
-- 243:6000000000000000000000000000000000000000000000000000000000000000
-- </SPRITES>

-- <MAP>
-- 000:000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000112131000000112131000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001121213100001131000000000000000000000000000000000000000000000000000000000000000000000011212121213100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 001:000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000112131000000112131000000000000000000000000000000000000000000000000000000000000000000000000000000009000000060000000000000001121213100001131000000000000000000000000000000000000000000000000000000000000500000000011212121213100000000000000000000000000000000000000000000400000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 002:000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000122232000000122232000000000000000000000000000000000000000000000000000000000000000000000000000010202020202020203000000000001222223200001232000000000000000000000000000000000000000000000000000000000010203000000011212121213100000000000000000043530000000000738300000000410000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 003:0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000c100000000c100000000000000000000000000000000000000000000000010300000000000000000000000000011212121212121213100000000000000000000000000000000000000000000000000000000000000000000000000000000000011213100000011212121213100000000000010202030546464646464741020203000410040000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 004:00000000000000000000000000000000000000000000000000000000000000000000000000000000000000900000000000000000000000d000000000d0c000000000000040000000000000000000000000000000000011310000000000000000000000000011212121212121213100000000000000000000000000000000000000000000000000000000000000000000000000000000000011213100000011212121213100000000000011212131000000000000001121213100410041004000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 005:00000000000000000000000000000000000000400000000000000000000000000000000000000000000010202020300000000000000000c100000000b100d1000000000041000000000000004000000000000000000011310000000000000000000000000011212121212121213100000000000000000000000000000000000000000000000000000000000000000000000000000000000011213100000012222222223200000000000011212131000000000000001121213100410041004100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 006:000050000090000000000000000000004000004100005000000000000000708000000000600000000000112121213120203000500090d00000000000b090b1000000102020300000000000004100004353636373830011319000000000000050708050006011212121212121213190006000900000000000000000000000000000000000000000000000000000000000000000000000000011213100000000000000000000000000000011212131000000000000001121213100410041004100000000500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 007:202020202020203000000000102020202020202020202020300000001020202020202020202030000000112121213120202020202020300000000060c041b0000000112121310090007080102020203054646474102020203000000000001020202020202020202020202020202020202020203000004353000073830050000000009000000000005000005000007080000000000000000011213100000050007080600090006000500011212131000000000000001121213100410041004100102020202020300000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 008:2121212121212131000000001121212121212121212121213100000011212121212121212121310000001121212131212121212121213100000010202030c0000000112121312020202020112121213100000000112121213100000000001121212121212121212121212121212121212121212120203054646474102020202020202020202020202020202020202020202020202020202011213100001020202020202020202020203011212131000000000000001121213120202020202020202020202020202020202020202020202020202020202020202020202020202020200000000000000000000000000000
-- 012:202030000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 013:212131000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 014:212131202030000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 015:202020202020202020200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 016:212121212121212121210000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 017:00000000000000001030b1c010300000000000001121212131000010300000000000000000041222222221213200b00000b000122121213100000000000000000000000000122222222232000000000000000000000000001222222222222222320000000013331121312626262656370000000000000000000012222222222222222222222222221333222222223848484900000000000029000011293948484848484849000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 018:00004000000000001131c00011310010203000001121212131000012320000400000000000000000d10012320000b19000c000001221213100000000400000000000000000000000b000b10000000000000000009000000000b100b000c00000000000000016341121312626266626370000132323233300001333b100b1b00000c000b0d0b000b1163400b0d000000000290038484849002900d0113a4a0000000000002900000000c700000018000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 019:0000410040000000123200d1113100112131000012222222320000b0b1001020300000000000400000000000000010202030d1000011213100000000410000000000000000400000b100b00010300050000000102020300000b000b10000d100000000000017351121312626572656370000142626563700001545b000b0b01333b0d1b1c1000000173500c1b100000000290000000029002900001121310000000000000000000000c80000000000c700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 020:004041404100000000000000113100111020300000b1b0b1b10000b1b000112131000000001020300000000000102122222130000011213100000000414000004000000000410000b000c00011102020309010112121310000b100b00000c000000000000000c11222322657265724340000142666563700000000b100b1001545b1c0d0001333000000d000c00039490029000000001a484a0000112131d11323233398a8a8a8b800c898a8a8b800c800c70000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 021:004141414100000010202020213100111121310000b0c0b1b00000c00000122232000000001121213000000000113100001131000011213100000000414100404100000000103000b10000d111112121312020302121310040b000c0000000d10000000000d000c1b11567276727253500001457662637000000000000b0000000b000c1001545000000b000000029290029003958002a00000000122232b014262637000000001800c80000001800c900c80000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 022:102020202020300011212121213100111121310000b1b1d1b10000000000000000000000001121212130000000113150601131000011213100000040414100414100000000113100b07080b011112121312121312121310041000000d10000000000000000b1d000b00000000000000000001457262637000000001333b100000000d0b1000000000000b10000002929002a002900000000000000b0d1c0b114262637000000000000c800000098b80000c80000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 023:112121103021310012222222223200111121310000b100b1000000000000000000000000001121212121300010302120202132000012223200000041414100414100000000113100b11030b111112121312121312121310041007080000050000000000000c1b100b10000000000000000001426262434000000001545000000000000000000000000000000000029290000001a48484848580000c0c000b0142626370098a8a8a8a8c818000000000000c80000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 024:203021113121310000c00000c00000121121310000000000000000000000000000000000001121212121213011312222223200000000b1d100001020202020202020300000113100b0113100111121213121213121212120202020202020202020000000d000b000b0001323232323232323142624464700001020202020202020133320202020203848484848484a3a4848484a000000000000000000000014262637000000000000c90098a8c7a8b800c90000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 025:213121113121310000000000000000001121310000000000000000000000000000000000001121212121212111310000000010300000b0000000112121212121212131000011310000113100111121213120202030212121212121212121212121000000c000c000000014262626262626261426465a37000011212121212121211545212121212128384848484848484848484848484848484848484848485926263700000000180000000018c8001800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 026:0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000c8000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- </MAP>

-- <WAVES>
-- 000:00ffffffffffffff00ffffffffffffff
-- 001:ffff000000000000ffff000000000000
-- 002:ffffffff00000000ffffffff00000000
-- 003:0123456789abcdeffedcba9876543210
-- 004:01234567898653effedcba9876543210
-- 006:8899acdeeffeedca8653211001123567
-- 007:aaaabcdeeffeedca8653211001123455
-- 008:cccccddeeffeedca8653211001122333
-- 009:ffffffffffffffff0000000000000000
-- 010:531224579bccda874334567888999a86
-- 011:01234444898653effedcba9876543210
-- 012:01237654898653effedcba9876543210
-- 013:01236547898653effedcba9875783210
-- 015:0080008600e0000d000060000090b000
-- </WAVES>

-- <SFX>
-- 000:0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000003000000000ff
-- 001:010001000100010001000100010001000100010001000100010001000100010001000100010001000100010001000100010001000100010001000100307000000000
-- 002:020002000200020002000200020002000200020002000200020002000200020002000200020002000200020002000200020002000200020002000200204000000000
-- 003:030003000300030003000300030003000300030003000300030003000300030003000300030003000300030003000300030003000300030003000300300000000000
-- 004:040004000400040004000400040004000400f400f400f400f400f400f400f400f400f400f400f400f400f400f400f400f400f400f400f400f400f400507000000000
-- 005:050015003500550075009500a500c500c500d500e500e500e500f500f500f500f500f500f500f500f500f500f500f500f500f500f500f500f500f500004000000000
-- 006:05006500b500d500e500f500f500f500f500f500f500f500f500f500f500f500f500f500f500f500f500f500f500f500f500f500f500f500f500f500005000000000
-- 007:050015001500250025003500450045005500550065006500750075008500850095009500a500a500b500b500c500c500d500d500e500e500f500f500005000000000
-- 008:000000000000000000000000000000000000000000000000000000000000000000010002000300030003000200010000000f000e000d000d000d000e3050000000ff
-- 009:010001010102010301030103010201010100010f010e010d010d010e010f010001010102010301030103010201010100010f010e010d010d010d010e00400000000f
-- 010:020002010202020302030203020202010200020f020e020d020d020e020f020002010202020302030203020202010200020f020e020d020d020d020e00400000000f
-- 011:010001000100010001000100010001000100f100f100f100f100f100f100f100f100f100f100f100f100f100f100f100f100f100f100f100f100f100307000000000
-- 012:010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101305000000000
-- 013:020f020e020e020f020002010202020302030203020202010200020f020e020d020d020e020f0200020002000200020002000200020002000200020000700000004f
-- 014:0802470e75f095f0b5f0c5f0e5f0f5f0f5f0f5f0f5f0f5f0f5f0f5f0f5f0f5f0f5f0f5f0f5f0f5f0f5f0f5f0f5f0f5f0f5f0f5f0f5f0f5f0f5f0f5f0b02000000000
-- 015:097009b008d008ff08ff07fe07fe06fd06fc06fc06fb06fb06fb06fa06fa06fa06f906f906f8f6f8f6f8f6f8f6f8f6f8f6f8f6f8f6f8f6f8f6f8f6f8cb5000000000
-- 016:01000100010001000100011001100110011001100100010001000100010001000100010001000100010001000100010001000100010001000100010008b000000000
-- 017:010001000100012001200120010001000100010001000100010001000100010001000100010001000100010001000100010001000100010001000100308000000600
-- 018:010001000100013001300130010001000100010001000100010001000100010001000100010001000100010001000100010001000100010001000100307000000600
-- 019:010001000100014001400140010001000100010001000100010001000100010001000100010001000100010001000100010001000100010001000100307000000600
-- 020:010001000100015001500150010001000100010001000100010001000100010001000100010001000100010001000100010001000100010001000100304000000600
-- 021:05006500b500d500e5005500a500d500e500f500f500f500f500f500f500f500f500f500f500f500f500f500f500f500f500f500f500f500f500f500005000000000
-- 022:040004000400040004000400040104020403040354025401540f540e540d540d540e540f5401540254035403540354025401540f540e540d540d540e50b0000000ff
-- 023:04000400040004006400f400040004000400040004000400040004000400040004000400040004000400040004000400040004000400040004000400205000060000
-- 024:02202200750085089508b508c508d508d508e508e508f508050022209200a508b508c508d508d508d508e508e508f508f508f508f508f508f508f508902000000000
-- 025:4508750812f132ff95f0b5f7c5f7d5f7d5f7e5f7e5f7f5f7450865081200120fb20ec50d05fd25fd02f175f7a5f7b5f7c5f7d5f7e5f7f508f508f508902000000000
-- 026:65087508850885089508a50802f122ff650775079507c50702200200750895089508c50802000220a210b210c200d200f200f200f500f500f500f500902000000000
-- 027:2508450822f142ff95f7b5f7c5f7d5f7d5f7e5f7e5f7f5f775089508a508c508d508d508d508e508e508e508e508e508f508f508f508f508f508f508902000000000
-- 028:01000100010001300130013041006100710081009100a10001000100010001000100010041006100710081009100a100a100a100a100a100a100a100305000000600
-- 029:01000100010001400140014041006100710081009100a10001000100010001000100010041006100710081009100a100a100a100a100a100a100a100307000000600
-- 030:01000100010001500150015041006100710081009100a10001000100010001000100010041006100710081009100a100a100a100a100a100a100a10030a000000600
-- 031:040004000400040004000400040004000400040004000400040004000400040004000400040004000400040004000400040004000400040004000400309000000000
-- 032:0a000a000a000a000a000a000a000a000a000a000a000a000a000a000a000a000a000a000a000a000a000a000a000a000a000a000a000a000a000a00404000000000
-- 033:0a000a020a040a050a050a050a040a020a000a0e0a0c0a0b0a0b0a0c0a0e0a000a010a020a000a000a000a000a000a000a000a000a000a000a000a0040000000000f
-- 034:0a000a030a050a070a070a070a050a030a0e0a0c0a090a090a090a0b0a0d0a000a010a020a000a000a000a000a000a000a000a000a000a000a000a0040700000000f
-- 035:040004000b000b000c000c000d000d000c000c000b000b000400040004000b000b000c000c000d000d000c000c000b000b000400040004000400040016b00e000000
-- 048:e000f0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000005000110000
-- 050:320042005200520062007200720082009200a200b200b200327042705270527062707270727082709270a270b270b270f200f200f200f200f200f200270000000000
-- 051:42b052705240620062007200720072008200820082008200920092009200a200a200b200b200b200c200c200c200d200d200d200e200e200e200f200370000000400
-- 052:f200f200f200f200f200f200f200f200f200f200f200f200327042705270527062707270727082709270a270b270b270f200f200f200f200f200f200270000000000
-- 053:42a052705230620062007200720072008200820082008200920092009200a200a200b200b200b200c200c200c200d200d200d200e200e200e200f200374000000400
-- 054:f120f120f120f120f120f120f100f100f100f100f100f100515051505150515091509150517051705170517091709170519051905190519091909190257000000000
-- 055:51c051c051c051c091c091c051b051b051b051b051b091b091b091b091b0c1b0c1b0c1b0517051705170517051709170917091709170c170c170f170257000000000
-- 058:000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000004000000000
-- 059:0500050005001500250025002500350035004500450045005500550065006500750085009500a500a500b500c500d500d500e500e500e500e500f500070000000000
-- 060:460065f7a56cd539f500f500f500f500f500f500f500f500f500f500f500f500f500f500f500f500f500f500f500f500f500f500f500f500f500f500c00000000000
-- 061:70020000200df000f000f000f000f000f000f000f000f000f000f000f000f000f000f000f000f000f000f000f000f000f000f000f000f000f000f000c00000000000
-- 062:05002560356045b055a06590753085409540a510a510b550c5b0d560d560e540e510f5b0f590f540f540f520f520f580f5f0f5b0f530f5e0f550f5c020b000000000
-- 063:0ff035ce656cb50affb0ff40ff50ffe0ff70ff80ff90ffa0ffb0ffd0fff0ff50ff00ff00ff60ff00ffb0ff80ff00ff90ffa0ffe0ffb0ffc0ff00ffd0b00000000f00
-- </SFX>

-- <PATTERNS>
-- 000:890028690028890028490028890028690028890028490028890028690028890028490028890028690028890028490028890028690028890028f90026890028690028890028f90026890028690028890028f90026890028690028890028f90026890028690028890028e90026890028690028890028e90026890028690028890028e90026890028690028890028e90026890028690028890028d90026890028690028890028d90026990028890028990028d90026990028890028990028d90026
-- 001:0000000000008d00a86d00a88d00a84d00a88d00a86d00a88d00a84d00a88d00a86d00a88d00a84d00a88d00a86d00a88d00a84d00a88d00a86d00a88d00a8fd00a68d00a86d00a88d00a8fd00a68d00a86d00a88d00a8fd00a68d00a86d00a88d00a8fd00a68d00a86d00a88d00a8ed00a68d00a86d00a88d00a8ed00a68d00a86d00a88d00a8ed00a68d00a86d00a88d00a8ed00a68d00a86d00a88d00a8dd00a68d00a86d00a88d00a8dd00a69d00a88d00a89d00a8dd00a69d00a88d00a8
-- 002:420044420044420044420044420044420044420044420044420044420044420044420044420044420044420044420044820044820044820044820044820044820044820044820044820044820044820044820044820044820044820044820044e20042e20042e20042e20042e20042e20042e20042e20042e20042e20042e20042e20042e20042e20042e20042e20042920044920044920044920044920044920044920044920044920044920044920044920044920044920044920044920044
-- 003:8000f8d5006eb000e6d5006e8000f8d5006eb000e6d5006e8000f8d5006eb000e68000f8f5006e8000f8b000e6f5006e8000f8d5006eb000e6d5006e8000f8d5006eb000e6d5006e8000f8d5006eb000e68000f8d5006e8000f8b000e6d5006e8000f8d5006eb000e6d5006e8000f8d5006eb000e6d5006e8000f8d5006eb000e68000f8d5006e8000f8b000e6d5006e8000f8d5006eb000e6d5006e8000f8d5006eb000e6d5006e8000f8d5006eb000e68000f8d5006e8000f8b000e6d5006e
-- 004:990028890028990028c90026990028890028990028c90026990028890028990028c90026990028890028990028c90026890028690028890028b90026890028690028890028b90026890028690028890028b90026890028690028890028b90026690028490028690028a90026690028490028690028a90026690028490028690028a90026690028490028690028a90026490028f90026490028b90026490028f90026490028b90026f90026d90026f90026b90026f90026d90026f90026690028
-- 005:fd00a66d00a89d00a88d00a89d00a8cd00a69d00a88d00a89d00a8cd00a69d00a88d00a89d00a8cd00a69d00a88d00a89d00a8cd00a68d00a86d00a88d00a8bd00a68d00a86d00a88d00a8bd00a68d00a86d00a88d00a8bd00a68d00a86d00a88d00a8bd00a66d00a84d00a86d00a8ad00a66d00a84d00a86d00a8ad00a66d00a84d00a86d00a8ad00a66d00a84d00a86d00a8ad00a64d00a8fd00a64d00a8bd00a64d00a8fd00a64d00a8bd00a6fd00a6dd00a6fd00a6bd00a6fd00a6dd00a6
-- 006:c30044c30044c30044c30044c30044c30044c30044c30044f30044f30044f30044f30044630046630046630046630046830046830046830046830046630046630046630046630046430046430046430046430046b30044b30044b30044b30044a30044a30044a30044a30044a30044a30044a30044a30044a30044a30044a30044a30044a30044a30044d30044430046f30044b30044b30044b30044b30044b30044b30044b30044b30044b30044b30044b30044b30044b30044b30044b30044
-- 007:8000f8d5005fb000e6d5005f8000f8d5005fb000e6d5005f8000f8d5005fb000e68000f8f5005f8000f8b000e6f5005f8000f8d5005fb000e6d5005f8000f8d5005fb000e6d5005f8000f8d5005fb000e68000f8d5005f8000f8b000e6d5005f8000f8d5005fb000e6d5005f8000f8d5005fb000e6d5005f8000f8d5005fb000e68000f8d5005f8000f8b000e6d5005f8000f8d5005fb000e6d5005f8000f8d5005fb000e6d5005f8000f8d5005fb000e68000f8d5005f8000f8b000e6d5005f
-- 008:c90037000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000b90047000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000990047000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000b90027000000000000000000000000000000000000000000b90037000000000000000000000000000000000000000000
-- 009:000000000000b30016ba00169300168300168a00166300166a00164300164a0016f30014000000fa0014b30014ba0014c30014000000000000000000c30094000000ca0094000000cc0094000000000000000000d30014da0014f30014fa00144300160000004a00166300160000006a00168300160000008a00169300160000009a0016b30016ba0016c30016ca00168300160000008a00166300074300160000000000000000004a00960000004c0096000000000000000000000000000000
-- 010:c30042c30042c10048c30042c10048e10048c30042c10048c30042c30042c10048c30042b10048c10048c30042b10048430044430044b10048430044b10048c10048430044b10048430044430044b10048430044910048710048430044610048e30044e30044610048e30044610048710048e30044610048e30044e30044610048e30044710048e30044610048e30044b30044b30044610048b30044610048710048b30044610048b30044b30044f10046b30044410048b30044610048b30044
-- 011:ca0016000000000000000000ba00160000000000000000008a0016000000000000000000aa00160000000000000000006300836300936300a36300b36300836300936300a36300b36300836300936300a36300b36300836300936300a36300936300836300936300a36300b36300836300936300a36300b36300836300936300a36300b36300836300936300a36300b36300836300936300a36300b36300836300936300a36300b36300836300936300a36300b36300836300936300a36300b3
-- 012:5a00160000000000000000000000000000000000000000005a00180000000000000000005a0018000000000000000000ca0045000000000000000000ca00450000000000000000005a0027000000000000000000aa00270000000000000000009800c74800e74800e79800c74800e74800e79800c74800e78800d74800d75800c78800d74800d75800c78800d7c800e7b800d77800d78800c7b800d77800d78800c7b800d7f800e7c700e7c700d7c700e7c700d7c700e7c700e7c70047cc0047
-- 013:0000000000009300160000009a0016c30014000000ca0014c30016000000ca0016b30016000000ba00169300169a0016b30016000000ba0016000000f30016000000fa00160000004300180000004a0018000000f30016000000fa0016000000d30016000000000000d30096000000da0096000000000000d300b6d300b6d300b6f30016000000fa00164300184a0018f30016000000fa0016d30007b30016000000000000000000b30096000000000000ba0096000000000000bd0096000000
-- 014:c30042c30042c10048c30042c10048e10048c3004241004ac30042c3004271004ac3004291004a71004ac3004261004a43004443004441004a43004441004ae1004843004441004a43004443004441004a43004461004a71004a43004491004ae30044e3004491004ae3004471004a61004ae3004441004ae30044e30044e10048e30044910048e30044b10048e30044e10069000000b30044b30044e10069000000b30044b30044f10069000000b30044b30044f10069000000b30044b30044
-- 015:700808000000000000700818000000000000f00808000000000000f0081800000000000070080a00000000000000000070082a00000000000000000077082a00000000000000000050080a00000070080a57080a50080a77080af0080857080ae00808000000000000000000c00808e70808e00808c70808f00808e70808e00808f70808f00808e7080850080af7080870080a57080a90080a77080a70080a97080a50080a77080a70080a00000000000000000079082a000000000000000000
-- 016:f30832000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000530834000000000000000000000000000000000000000000730834000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 017:490027000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000490027000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000e90035000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000e90035000000000000000000000000000000000000000000f90025000000000000000000000000000000000000000000
-- 018:530075000000000000000000e30075000000000000000000530075000000000000000000a30075000000000000000000530075000000000000000000e30075000000000000000000530075000000000000000000a30075000000000000000000930077930075930075930077930075930075930077930075530077530075530075530077530075530075530077530075830077830075830075830077830075830075830077830075530077530075530075530077530075530075530077530075
-- 019:7300277d0027000000e30045ed0045aa00067a00065a00067a00065a00067a0006aa0006c30045cd0045e30045ed00455300475d0047ca0006e30025ed0025aa0006ca0006ea0006ca0006aa0006ca0006ea00067300277d00279300279d0027a30037ad0037aa0006e30027ed0027ea0006ca0006aa0006ca0006aa0006ca0006ea00069300279d00277300277d00279300279d0027ca00067300277d0027aa00069a0006aa00069a00067a00065a00067a00069a0006aa0006ca0006aa0006
-- 020:000000000000000000000000550028000000000000000000c50026e50026000000000000e500a6000000ea00a6000000ed00a6000000000000000000550028000000000000000000a50026c50026000000000000ca0026000000a50026950026a50026000000000000a500a6000000aa00a6000000ad00a69500260000000000009500a60000009a00a60000009d00a67500260000000000000000007500a60000007a00a60000000000000000000000007d00a6000000000000000000000000
-- 021:8a00160000000000000000007a0016000000000000000000ca0016000000000000000000da00160000000000000000008a00370000000000000000008a0027000000000000000000ca0047000000000000000000da00350000000000000000004800e79800c59800c54800e79800c59800c54800e79800c5c800e58800d58800d5c800e58800d58800d5c800e55800c7f800e5b800d5b800d5f800e5b800d5b800d5f800e58800c75700c75700c75700c75700c75700c75700c75700275c0027
-- 022:730834000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000530834000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000a30834000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000730834000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 023:700808000000000000700818000000000000f00808000000000000f00818000000000000a00808000000000000000000a00818000000000000000000000000000000000000000000900808a80808a00808980808c00808a80808f00808c80808e00808000000e00818000000c00808e80808a00808c80808900808a80808a00808980808c00808a80808a00808c80808900808a80808500808980808900808580808a00808980808700808000000000000000000700818000000000000000000
-- 024:7500287b00285500287b00287500285b00285500287b00287500285b00289500287b0028a500289b0028950028ab00287500289b00285500287b0028e500265b0028550028eb0026c500265b0028a50026cb0026950026ab0026a500269b0026950026ab00265500269b00269500265b0026a500269b0026c50026ab0026a50026cb0026950026ab00265500269b00267500265b00265500267b00267500265b00269500267b0026a500269b0026950026ab00267500269b00265500267b0026
-- 025:8000f8000000d5006eb000e68b005ed5006e8000f80000008000f8000000d5006e000000b000e6000000d5006e0000008000f8000000d5006eb000e68b005ed5006e8000f80000008000f8000000d5006e000000b000e6000000d5006e0000008000f8000000d5006eb000e68b005ed5006e8000f80000008000f8000000d5006e000000b000e6000000d5006e0000008000f8000000d5006eb000e68b005ed5006e8000f80000008000f8000000d5006e000000b000e6b000e6d200f88400f8
-- 026:fa0035aa0045fa0035aa0045fa0035aa0045fa0035aa0045fa0035aa0045fa0035aa0045fa0035aa0045fa0035aa00457a0027fa00357a0027fa00357a0027fa00357a0027fa00357a0027fa00357a0027fa00359a00275a00379a00275a0037aa00377a0027aa00377a0027aa00377a0027aa00377a0027aa00377a0027aa00377a0027aa00377a0027aa00377a0027aa00377a0027aa00377a0027aa00377a0027aa00377a0027ea0047aa0037ea0047aa0037ea0047aa0037ea0047aa0037
-- </PATTERNS>

-- <TRACKS>
-- 000:180301581701182301583701984b02984f02000000000000000000000000000000000000000000000000000000000000000040
-- 001:d85313000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000021
-- 002:086710086715086715596715996715196b16196b14196b15196b15996716196b15196b16196b14000000000000000000000000
-- 003:000000000000000000000008000000000000000000000000000000000000000000000000000000000000000000000000000000
-- </TRACKS>

-- <COVER>
-- 000:ab6000007494648373160f0088003b000041c0414442430343d6e4a4e458c403435642ff55555717160000009701c358591a55ff552daa9955ffffffff55ffffffc2000000000f0088000040ff019c94badb83bedcbbff0682e84696e986aaeac6beeb07c2fc47d6fd87eafec7feff0c0a0784c2a1f88c4a211e85a3d4dc7a47a4daa5fa8dca67b2a8e4c0063077c4e0585c540b54d793b6cd928b98dfe378962740dfb6fd350ce018e0e7e33886f7785197b67717d8379881d748e297483919c728682408687618b7e91a993af999218988b9b8d1e949a760b9ca5ad80b574bfa866a4bc8dbd3e5ab0ac9a928792b6cf8a839ba9c7b91ab298c3b4c88c6fc2d9b8c7d3d3b7cfb04ab4a4a6d67dc4d4e5c4dcd8e5d81151d0dddda6a1fe15f169e8f6f1b0ef32e682d5a266ae0d98ae6fb8752bb7bd05514a73fa1288d721bf93ba830df9f0589011abbc871fffc58c789fe3ac3e0a0fb5b3399de2aeb88cf0f572f8d17d5d2d62294d14d62073063b8a118a1478ebc5213a8d356601e8b094615d99825a234ac2b405c2a00f72848af2bd1ca65b19663dda62fa6148a227896df066b95652abc87e151bf55958b885378e3d1b243f27daa4289eec08487d29d4a03d1a2dbb4bcfa7bb9f837635aa68d51dd8ad07c10e63e1703a5ec143c27b36d7ae08d855a79d1481aa83f0c7d322533a5b7a54fe2bb8adc9cb3ddabc1226d40911ceac5eae2d6cd56628794eccb9b3f7e0d3afd85e2dbab5fbe8d3bb67ce4d7bb77a0ddfbb8f1f4eb348f2f8e3dbaf5f69131176f0f5a9b78b1fbefeebcfede3bf16633fbefb07e147c45fff74f190bc508ffd5130e36ef5281202825c2840638e0e57212388c9d64165872845d8168fc048c28b7c1ae0e162331618834f69d9886bda403e925b9981c598230f7136a80b8b8d2c42188d833c9871ac6b4594284c0c3aa724a85adc68594b30420793e78d4aa88308865649c6139345a854c543f9690986635616abd3813cc733a89c019935a03912f0a6a39c66f5f8159236c943681b04f9e7af9572a0b02e3552d9e8081e72a3b040af14878369905da9630f998e026c402b823a189190964aa7e4a86cf969ac24aa3099a6ab9ad4032b82488adec9a8aa8072a7553e012aa741ba40946c5b21c9296f064e829b678c5afaf920b67cc23ca32ba6da448ffa9bddea8c63b44e3b37ef80bd2b66cc97ca68e32892484bcc17bdd22bfdafaade6a16a31fde929ea0a0de018d6171c669fe2714bec9b288b7fee0a79935e6fb36ca46dcf19be19fd1a3a8c793fe61b9cb33f63cd0b6031b5051bc005a21f03088de6cc184ce17500238074677d4c9cc448cab22c92ff8e132cac6bc827acc247ce449c61331a3bdc1547c523bcb2facd3f3c04bf48c8ec227bc14b0db4f9c117fc43bfcac54cb4f67e902d0e92dc370dc2bdc3574d34387bba2cac95c7068db3f3daba2df5b8d33f5c7d19db6bbd053dcc43fce43bd55bdde105366f9de4bbc5731d3838c18b71a2f31cf27c983cc58b0e2532dd5b1e2339c07b0cd5c5e65cffe2a5e2e655a28978edc97e5e19e2a7016af9eaa36dba7beeafbe0bb6b9aff73b7ce6bfde8b7eeabff05bf771f628fbfe74eeab3ed0ffb657de6eb1cb589c25beca47dc77a34d1fc544f56e2ff9f116db4fecbdb55c3acd759ae638422cbc568f3db7f11e588ef0f3016238c446c7c6c92af0965b954df6f77f3c74682d6f2eb6f0bf6f7acb089110c740cc1dc72645b1006fa664e0c4027fec4350df940b3511cef076ec74dad0e00f28f62aedd583802460220538c78f0a2fac152c616e982833171620d28a3221e5f6432347129ba8493c912d0144d2ce34f07888525fda0e7844cb1ad0b7891c42ac016853042a31348b4462e907a8a341121baa885c9eff5719a5f5472a10f362f903eef4a885cb2a91528a5421d207d86f3436a15580749ed1bc879cba3e409e834493ae17f844112a75ef8954e26f19f8484316d2cf898c21222da868c64e30133194942b1d29f84b4a605d8a9462a62339d9403582749f5464292bf37ac45a81b294a435aa2f591e305e725690bca5e30b08c9cf32d2d69aa47fc720c487c141cf048bb4e56821f897a94e5be588911b98cec6e636304ec894d406a23379a8c67120ef4210e6e63db90e404582eb9dd499553d69d4cb35015124ecd66b3715d72a000aab91fc499a1ae9b8a37a131b907c77af39b9d4017e733f910918a935f99a4e76d170a99a0769dc0a4fc54dd10f9705482625f6097ac67604b1ac0587ec310a080f7a54f899e4d4a0d2c64d94408cea606b19632b4a61d121b2d5abac26eb258943529ad4169f3cd96e4f28ea4a92d0d7af352060537a28999615d19445e5a50b9ab45b3a2558a4318a645f6875504aaa2ba164ba653765c5d92e153ba06d0b2af22000b3
-- </COVER>

