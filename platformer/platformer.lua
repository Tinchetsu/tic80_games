-- title:  Platformer
-- author: @tinchetsu
-- desc:   WIP platoformer
-- script: lua

function Player(x,y)
	local player={
		x=x,
		y=y,
		w=7,
		h=7,
		dx=0,
		dy=0,
		sp=1,
		s=256,
		st=0 -- 0:ground, 1:jump
	}
	function player:update()
		local p=self
		-- testing how to handle inputs
		p.dx=btn(2) and -p.sp or btn(3) and p.sp or 0
		p.dy=p.dy+0.1
		if p.dy>4 then p.dy=4 end
		--check state
		if isSolid(p.x,p.y+p.h+1)or isSolid(p.x+p.w,p.y+p.h+1)then
			p.st=0
		else
			p.st=1
		end
		if btn(5) and p.st==0 then
			p.st=1
			p.dy=-2.4
		end	
		checkMapCol2(p)
	end
	function player:draw()
		local p=self
		spr(p.s,p.x,p.y,0)
		--draw bbox points
		pix(p.x,p.y,15)
		pix(p.x+p.w,p.y,15)
		pix(p.x+p.w,p.y+p.h,15)
		pix(p.x,p.y+p.h,15)
	end

	return player
end


function isSolid(x,y)
	return mget(x/8,y/8)~=0
end


function checkMapCol2(e)
	-- check x collisions
	local s=mget((e.x+e.dx)/8,e.y/8)
	if e.dx>0then
		if isSolid(e.x+e.w+e.dx,e.y)or isSolid(e.x+e.w+e.dx,e.y+e.h)then
			e.x=((e.x+e.w)//8)*8+7-e.w
		else
			e.x=e.x+e.dx
		end
	elseif e.dx<0then
		if isSolid(e.x+e.dx,e.y)or isSolid(e.x+e.dx,e.y+e.h)then
			e.x=((e.x//8))*8
		else 
			e.x=e.x+e.dx
		end
	end
	-- check y collisions
	s=mget(e.x/8,(e.y+e.dy)/8)
	if e.dy>0then
		if isSolid(e.x,e.y+e.h+e.dy) or isSolid(e.x+e.w,e.y+e.h+e.dy)then
			e.y=((e.y+e.h)//8)*8+7-e.h
			e.dy=0
		else 
			e.y=e.y+e.dy
		end
	elseif e.dy<0then
		if isSolid(e.x,e.y+e.dy) or isSolid(e.x+e.w,e.y+e.dy)then
			e.y=((e.y//8))*8
			e.dy=0
		else 
			e.y=e.y+e.dy
		end
	end
end

function checkMapCol(e)
	-- check h collisions
	local s=mget((e.x+e.dx)/8,e.y/8)
	if e.dx>0then
		if s==0then e.x=e.x+e.dx else e.x=((e.x//8))*8+7 end
	elseif e.dx<0then
		if s==0then e.x=e.x+e.dx else e.x=((e.x//8))*8 end
	end
	-- check h collisions
	s=mget(e.x/8,(e.y+e.dy)/8)
	if e.dy>0then
		if s==0then
			e.y=e.y+e.dy
		else 
			e.y=(e.y//8)*8+7
			e.dy=0
		end
	elseif e.dy<0then
		if s==0then
			e.y=e.y+e.dy
		else 
			e.dy=0
			e.y=(e.y//8)*8
		end
	end
end

pl=Player(100,10)

function TIC()	
	cls(0)
	map(0,0,30,17,0,0,0)
	pl:update()
	pl:draw()
	current=tstamp()
  	print('Timestamp: '..current,10,10,15)
end

-- <TILES>
-- 001:0bbbbbbbbb555555b5544444b5444494b5444444b5449444b5444444b5444494
-- 002:bbbbbbbb55555555444444444444449449449444444444944494444444449444
-- 003:bbbbbbb0555555bb4444455b4949445b4444445b4444945b4494445b4444445b
-- 004:0bbbbbbbbb555555b5544444b5494444b5444494b5549444bb5555550bbbbbbb
-- 005:bbbbbbbb555555554494444444444494449494449444449455555555bbbbbbbb
-- 006:bbbbbbb0555555bb4444455b4944945b4444445b9449455b555555bbbbbbbbb0
-- 007:0bbbbbb0bb5555bbb554455bb544445bb544445bb549445bb544445bb544495b
-- 008:b544445bb544445bb544945bb544445bb549445bb544445bb544945bb594445b
-- 009:b544495bb594445bb544445bb549445bb544445bb554955bbb5555bb0bbbbbb0
-- 017:b5444444b5449444b5444494b5444444b5449444b5444444b5944494b5444444
-- 018:4444444444444944449444949444444444494444494444944444444444449444
-- 019:4444445b9444445b4444945b4944445b4444445b4444445b4494445b4444945b
-- 033:b5444444b5494449b5444444b5444944b5444444b5544494bb5555550bbbbbbb
-- 034:44494444444449444944444444444444444944944444444455555555bbbbbbbb
-- 035:4444945b4444445b4494445b4444445b4494445b9444455b555555bbbbbbbbb0
-- </TILES>

-- <SPRITES>
-- 000:7777777777777777777777777777777777777777777777777777777777777777
-- 001:0022220000242400202222022222222200022000002222000020020000200200
-- 016:0022200002222220255555005549490005444400002220000022000003003000
-- 017:000ee00000eeeee00eeeee000e424200004444000022620000c22c0000011000
-- </SPRITES>

-- <MAP>
-- 003:700000000000000000000000000000000000000000000000000000000070000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 004:800000000000000000000000000000000000000000000000000000000080000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 005:800000000000000000000000000000000000000000000000000000000080000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 006:800000000000000000000000000000000000000000000000000000000080000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 007:800000000000000000000000000000000000000000000000000000000080000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 008:800000000000000000000000000000000000000000000000000000000080000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 009:800000000000000000000040505050600000000000000000000000000080000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 010:800000000000000000000000000000000000000000000000007000000080000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 011:800000000000000000000000000000000000000000000000008000000080000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 012:800000000000001020202020300000000000000000000000008000000080000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 013:800000000000001222222222320000212121000000000000009000000080000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 014:800000000000000000000000000000000000000000000040505050600080000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 015:900000000000000000000000000000000000000000000000000000000090000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 016:102020202030202020202020202020202020202020304050505050505060000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- </MAP>

-- <WAVES>
-- 000:00000000ffffffff00000000ffffffff
-- 001:0123456789abcdeffedcba9876543210
-- 002:0123456789abcdef0123456789abcdef
-- </WAVES>

-- <SFX>
-- 000:000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000304000000000
-- </SFX>

-- <PALETTE>
-- 000:0000007e25531d2b535f574fab5236008751ff004d83769cff77a8ffa300c2c3c700e756ffccaa29adfffff024fff1e8
-- </PALETTE>

-- <PALETTE1>
-- 000:0000007e25531d2b535f574fab5236008751ff004d83769cff77a8ffa300c2c3c700e756ffccaa29adfffff024ffffff
-- </PALETTE1>

