
require 'code/class'
require 'code/keycode'
require 'code/util'
require 'units/object'
require 'libs/beFrames/beFrames'

EffectId = 0
EffectAtt = class({
	x = 0,
	y = 0,
	wM = 1,
	hM = 1,
	dx = 0,
	dy = 0,
	spr_ = nil,
	_spriteUpdater = nil,
	
	ctor = function ( self, img, state, x, y, dx, dy, wM, hM, callback )
		self.x = x
		self.y = y
		self.wM = wM
		self.hM = hM
		self.dx = dx
		self.dy = dy
        
		local imgSrc = 'spr/' .. img ..  '.spr'
		self.spr_ = Resources.load(imgSrc)
		self:play( state, true, false, 
            function ()
				-- Resources.unload(self.spr_)
				self.spr_ = nil
                callback()
			end
		)
	end,
	
	render = function( self, delta )
		local w = tileW
		local h = tileH
		local ww = w * self.wM
		local hh = h * self.hM
		if self._spriteUpdater then
			self._spriteUpdater(delta)
		end
		if self.spr_ ~= nil then
			spr(self.spr_, self.x * tileW + mapCfg.mox + tileW / 2 - ww / 2 + self.dx, self.y * tileH + mapCfg.moy + tileH / 2 - hh / 2 + self.dy, ww, hh)
		end
		if DEBUG then
			rect(
				self.x * tileW + mapCfg.mox + tileW / 2 - ww / 2 + self.dx, self.y * tileH + mapCfg.moy + tileH / 2 - hh / 2 + self.dy, 
				self.x * tileW + mapCfg.mox + ww, self.y * tileH + mapCfg.moy + hh, 
				false,
				Color.new(255, 0, 0)
			)
		end
	end,

	play = function (self, motion, reset, loop, played)
		if reset == nil then reset = true end
		if loop == nil then loop = true end

		local success, duration = self.spr_:play(motion, reset, loop)
		if success and played then
			local ticks = 0
			self._spriteUpdater = function (delta)
				ticks = ticks + delta
				if ticks >= duration then
					ticks = ticks - duration
					played()
					if not loop then
						self._spriteUpdater = nil
					end
				end
			end
		end

		return success, duration
	end,
})