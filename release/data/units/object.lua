require 'code/class'
require 'code/keycode'
require 'code/util'
require 'libs/beTilesetLoader'
local Tween = require 'code/tween' -- See https://github.com/kikito/tween.lua.

local txtBank7 = Resources.load('res/bank7.png')
local txtNumber = Resources.load('res/numbers.png')
local sprUnitBase = Resources.load('spr_ui/tile_unit_base.spr')
local sprNumber = Resources.load('spr_ui/numbers.spr')

SpritePool = class({
    pool = {},

	ctor = function(self)
	end,
	
    getRes = function( self, res, playSprFrame )
        if self.pool[res] == nil then
            self.pool[res] = Resources.load( res )
            if playSprFrame ~= nil and self.pool[res] ~= nil then
                self.pool[res]:play( playSprFrame )
            end
        end
        return self.pool[res]
    end,
})
sprPool = SpritePool.new()

ResPool = class({
	pool = {},

	ctor = function(self)
	end,

	getRes = function( self, res, tile_family )
		if self.pool[res] == nil then
			if tile_family ~= nil then
				self.pool[res] = beTilesetLoader_readTileFamily( 'res', tile_family )
			else
				self.pool[res] = Resources.load( res )
			end
		end
		return self.pool[res]
	end,
})
resPool = ResPool.new()


--[[
	Object is a class that handles basic grid based objects ( more likely to be units ). 
	It has two pairs of position values, one for rendering and the other for logic.
	It can play out the animation of attack and move
	It handles the tweens of attack and move, can check whether the unit's turn is finished.
	It also holds the units config
]]
Object = class({
	x1 = 0, -- anime posX
	y1 = 0, -- anime posY
	x2 = 0, -- logic posX
	y2 = 0, -- logic posY
	spr_ = nil,
	sprLevel = nil,
	tw = nil,
	actions = {},
	id = '',
	cfg = nil,
	isShow = true,
	xOffset = 0,
	yOffset = 0,
	
	ctor = function ( self, id, x, y, cfg, xOffset, yOffset )
		self.id = id .. '.' .. x .. '.' .. y
		self.cfg = cfg or Unitcfg.new()
		self:setAllpos( x, y )
		self.xOffset = xOffset
		self.yOffset = yOffset
		if self.cfg.img ~= nil and self.cfg.tile_family == nil then
			local imgSrc = self.cfg.img
			if self.cfg.pickup_equipment == nil then
				imgSrc = 'spr/' .. self.cfg.img ..  '.spr'
			end
			-- self.spr_ = sprPool:getRes( imgSrc, 'idle' )
			self.spr_ = Resources.load(imgSrc)
			if self.spr_ == nil then
			a = 0
			end
			self.spr_:play('idle', false, true, true)
		end
		-- if self.cfg.curLevel > 0 or self.cfg.curLevel < 11 then
		-- 	self.sprLevel = Resources.load('spr_ui/numbers')
		-- 	self.sprLevel:play(''.. (self.cfg.curLevel%10))
		-- end
	end,

	update = function( self, delta )
		if self.tw ~= nil then
			self.tw:update(delta)
		end
		for k,v in ipairs( self.actions ) do
			v:update(delta)
		end
		for k = #self.actions, 1, -1 do
			local vv = self.actions[k]
			if vv.finished == true then
				table.remove( self.actions, k )
			end
		end
	end,

	animeAttack = function( self, effect, effectType, x, y, dx, dy, wM, hM, onComplete )
		print("", "animeAttack "..self.id, "x"..x, "y"..y )
		tweenManager:addDelay( 0.5, true, onComplete )
        game:createEffect( effect, effectType, x, y, dx, dy, wM, hM )
	end,
	
	animeMove = function ( self, x, y, onComplete )
		print("", "animeMove "..self.id, "2"..x, "y2"..y )
		local exist = self.cfg.isGridBase and game:existsOnBoardByXY( self )
		if exist then game:removeFromBoardByXY( self ) end
		self.x2, self.y2 = x, y
		if exist then game:addToBoardByXY( self ) end
		if self == game.player then
			tweenManager:addTween( Tween.new( 0.3, self, { x1 = x, y1 = y }, 'linear' ), true, onComplete )
		else
			tweenManager:addTween( Tween.new( 0.5, self, { x1 = x, y1 = y }, 'inOutCubic' ), true, onComplete )
		end
	end,
	
	render = function( self, delta )
		local UnitPicOffsetBack = 20
		local UnitAllOffset = -20
		local sprX, sprY = self.x1 * tileW + self.xOffset, self.y1 * tileW + self.yOffset
		if self.cfg.is_tile == false then sprY = sprY + UnitAllOffset end
		if self.isShow == false then return end
		if self.cfg.tile_family == nil then
			if self.spr_ ~= nil then
				local sX, sY = sprX, sprY
				if self.cfg.is_tile == false then sY = sY + UnitPicOffsetBack end
				spr(self.spr_, sX, sY, tileW * self.cfg.width, tileW * self.cfg.height)
			end
		else
			local x,y = self:getLogicPos()
			local tileres = resPool:getRes(self.cfg.img, self.cfg.img)
			local adjust8 = { {x = -1, y = -1}, {x = 0, y = -1}, {x = 1, y = -1}, {x = 1, y = 0}, {x = 1, y = 1}, {x = 0, y = 1}, {x = -1, y = 1}, {x = -1, y = 0} }
			local list = {}
			for ii = 1,8 do
				local dd = adjust8[ii]
				local tf = game:getBoardTileFamily( x + dd.x, y + dd.y )
				list[ii] = tf
			end
			local id = beTilesetLoader_getTileId( tileres, self.cfg.tile_family, list )
			local wCount = 8
			local xx, yy = id % wCount * 32, math.floor( id / wCount ) * 32
			tex( tileres.tex, sprX, sprY, 32, 32, xx, yy, 32, 32 )
			if DEBUG_TILE then
				UI_ShowNumber( sprX + 13, sprY + 13, role, 1 )
			end
		end
		if self.cfg.pickup_equipment then
			-- UI_ShowNumber( sprX + 20, sprY + 23, self.cfg.level, 1 )
			-- local eq = FindEquipmentById( self.cfg.pickup_equipment )
			-- text( eq.desc, sprX + 4, sprY + 16 )
		elseif self.cfg.crystal_collector then
			local color = self:getLevelColor()
			tex( txtBank7, sprX, sprY, 32, 32, 32 * 15, 0, 32, 32 )
			UI_ShowNumber( sprX + 3, sprY + 23, Crystals_sum( self.cfg.crystal_collected ), 1 )
			UI_ShowNumber( sprX + 20, sprY + 23, self.hp, 1, color )
		elseif self.cfg.is_boss or self.cfg.owner ~= nil then
		elseif self == game.player then
			-- tex( txtBank7, sprX, sprY, 32, 32, 32 * 13, 0, 32, 32 )
			-- local color = COLOR_WHITE
			-- UI_ShowNumber( sprX + 3, sprY + 23, game:getWeapon().cfg.att, 1, color )
			-- local color = COLOR_WHITE
			-- UI_ShowNumber( sprX + 20, sprY + 23, game.shield.cfg.energy_power, 1, color )
		elseif self.cfg ~= nil and self.cfg.att ~= nil and self.cfg.is_terrain ~= nil and self.cfg.att > 0 and self.cfg.is_terrain == false then
			local color = self:getLevelColor()
			tex( txtBank7, sprX, sprY, 32, 32, 32 * 14, 0, 32, 32 )
			UI_ShowNumber( sprX + 3, sprY + 23, self.cfg.att, 1, color )
			if self.cfg.can_player_attack then
				UI_ShowNumber( sprX + 20, sprY + 23, self.cfg.hp, 1, color )
			end
			if DEBUG_LEVEL and self.cfg.can_player_attack and self.cfg.curLevel > 0 then
				UI_ShowNumber( sprX + 13, sprY + 13, self.cfg.curLevel, 1, color )
			end
		elseif self.cfg ~= nil and self.cfg.is_terrain == false and self.cfg.is_pickup == false and self.cfg.can_player_attack then
			tex( txtBank7, sprX, sprY, 32, 32, 32 * 15, 0, 32, 32 )
			UI_ShowNumber( sprX + 20, sprY + 23, self.cfg.hp, 1 )
		end
		if self.cfg.red_barrier > 0 then
			circ( sprX + 16, sprY + 32, 16, false, Color.new(255, 0, 0) )
			UI_ShowNumber( sprX + 20, sprY + 23, self.cfg.red_barrier, 1, COLOR_RED )
		end
		if DEBUG_TILE then
			UI_ShowNumber( sprX + 3, sprY + 23, self.x1, 1, COLOR_RED )
			UI_ShowNumber( sprX + 20, sprY + 23, self.y1, 1, COLOR_RED )
		end
		if DEBUG_POSITION then
			rect(
				sprX, sprY, 
				sprX + tileW * self.cfg.width, sprY + tileW * self.cfg.height, 
				false,
				Color.new(255, 0, 0)
			)
			local px, py = self:getLogicPos()
			UI_ShowNumber( sprX + 3, sprY + 23, px, 1, color )
			UI_ShowNumber( sprX + 20, sprY + 23, py, 1, color )
		end
	end,

	getLevelColor = function(self)
		local level = 0
		if self == game.player then
			return Color.new( 255, 255, 255 )
		elseif self.cfg ~= nil and self.cfg.curLevel ~= nil then
			if self.cfg.is_boss then
				return Color.new( 255, 0, 0 )
			else
				level = self.cfg.curLevel
				if self.cfg.curLevel >= game.player.level + 4 then
					return Color.new( 255, 0, 0 )
				elseif self.cfg.curLevel >= game.player.level + 2 then
					return Color.new( 255, 100, 0 )
				elseif self.cfg.curLevel >= game.player.level then
					return Color.new( 255, 255, 0 )
				else
					return Color.new( 0, 255, 0 )
				end
			end
		end
	end,

	getTurnFinished = function(self)
		if DEBUG_FAST_MODE then return true end
		for k,v in ipairs( self.actions ) do
			if v.finished == false then 
				return false 
			end
		end
		return true
	end,

	setAllpos = function( self, x, y )
		self.x1 = x
		self.y1 = y
		local exist = self.cfg.isGridBase and game:existsOnBoardByXY( self )
		if exist then game:removeFromBoardByXY( self ) end
        self.x2 = x
		self.y2 = y
		if exist then game:addToBoardByXY( self ) end
	end,
	
	getRealPos = function(self)
		-- reutnr the position on screen
		return self.x1 * tileW + self.xOffset, self.y1 * tileW + self.yOffset
	end,

	getRenderPos = function(self)
		return self.x1, self.y1
	end,

	getDisplayPos = function(self)
		-- return the position where the sprite should start render
		return self.x2, self.y2
	end,

	getLogicPos = function(self)
		return self.x2, self.y2
	end,
})
