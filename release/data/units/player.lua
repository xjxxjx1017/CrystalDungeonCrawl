require 'code/class'
require 'code/keycode'
require 'code/util'
require 'units/object'
local Tween = require 'code/tween' -- See https://github.com/kikito/tween.lua.


Player = class({
    level = 20,
	stun = 0,
	pickup_range = 16 * 1.8,

	playerMoves = { 
		{ x = -1, y = 0, k = KeyCode.Left },
		{ x = 1, y = 0, k = KeyCode.Right },
		{ x = 0, y = -1, k = KeyCode.Up },
		{ x = 0, y = 1, k = KeyCode.Down }
	},
	nextActionList = {},
	curDir = nil,

	ctor = function ( self, x, y )
        Object.ctor(self, 'player', x, y, merge( Config_Base, {img = 'player2'} ), mapCfg.mox, mapCfg.moy )
	end,

	nextAction = function( self )
		local px, py = self:getLogicPos()
		local changed = false
		local gx, gy = game.goal:getLogicPos()
		local wCfg = game.weapon.cfg
		self.curDir = nil
        if px == gx and py == gy then
            game:win()
			return false
        end
		if self.stun > 0 then
			self.stun = self.stun - 1
			self:actionSkipTurn()
			return true
		end

		--feature: force attack check
		local forceAttTarget = nil
		if wCfg.force_att > 0 then
			for k,v in ipairs( adjust4 ) do
				for kk, vv in ipairs( game:getBoard( px + v.x, py + v.y ) ) do
					if forceAttTarget == nil and vv.cfg.is_terrain == false and vv.cfg.can_player_attack then
						forceAttTarget = v
					end
				end
			end
			if forceAttTarget == nil then 
				wCfg.force_att = 0
			else
				wCfg.force_att = wCfg.force_att - 1
			end
		end

		if forceAttTarget ~= nil then
			self.curDir = forceAttTarget;
		else
			-- feature: force move check
			if wCfg.force_move > 0 then
				-- feature: if force move
				wCfg.force_move = wCfg.force_move - 1
				local m = wCfg.cur_force_move
				self.curDir = m;
			else
				-- check keys, and whether a move action is possible
				for k, m in ipairs( self.playerMoves ) do
					if key( m.k ) then
						-- feature: force move triggered
						if wCfg.force_move_max > 0 then
							wCfg.force_move = wCfg.force_move_max
							wCfg.cur_force_move = { x = m.x, y = m.y }
						end
						self.curDir = m;
					end
				end
			end
		end

		if self.curDir ~= nil then
			
			-- range attack check
			local dirRange = {}
			for k, v in ipairs( wCfg.range) do
				table.insert( dirRange, game:convertPosToFacingDirection( self.curDir, v ) )
			end
			local blocker, dx, dy = game:getFirstBlocked( px, py, dirRange )
			local newX, newY = px + self.curDir.x, py + self.curDir.y
			local blockerMeele = game:getBlocked(newX, newY)
			local isRange = dx*dx+dy*dy > 1+1
			local allInRange = transform( dirRange, function(r) return game:getBlocked( px + r.x, py + r.y ) end )
			local allUnitsInRange = filter( allInRange, function(r) return r ~= nil and blocker.cfg.can_player_attack and blocker.cfg.is_terrain == false end )

			-- attack range, range aoe or meele target
			local toAttack = {}
			if wCfg.is_aoe == true and #allUnitsInRange > 0 then
				toAttack = allUnitsInRange
			elseif wCfg.is_aoe == false and #allUnitsInRange > 0 then
				toAttack = { allUnitsInRange[1] }
			elseif blockerMeele ~= nil and blockerMeele.cfg.can_player_attack then
				toAttack = { blockerMeele }
			end

			if #toAttack > 0 then
				if wCfg.att_self_stun > 0 then
					self.stun = self.stun + wCfg.att_self_stun
				end
				if wCfg.force_att_max > 0 and wCfg.force_att == 0 and forceAttTarget == nil then
					wCfg.force_att = wCfg.force_att_max
				end
				forEach( toAttack, function( blk )
					local bx, by = blk:getLogicPos()
					-- if a range weapon is going on a meele attack, the blocker will conter attack first
					local dirWeakRange = {}
					for k, v in ipairs( wCfg.range_weak) do
						table.insert( dirWeakRange, game:convertPosToFacingDirection( self.curDir, v ) )
					end
					local wk = filter( dirWeakRange, function(r) return bx == px + r.x and by == py + r.y end )
					if #wk > 0 then
						blk:actionAttack( px, py )
					end
					-- player attack
					local a = game:curAtt( blk )
					-- 弹刀
					local attackFailed = false
					local energyRate = game.weapon.cfg.energy / game.weapon.cfg.energy_max
					if energyRate <= TANDAO_LIMIT_1 then
						if math.random() < 0.25 then attackFailed = true print('attact failed - 1') end
					elseif energyRate <= TANDAO_LIMIT_2 then
						if math.random() < 0.5 then attackFailed = true rint('attact failed - 2') end
					end
					if attackFailed and not blk.cfg.no_shield_block then
						self:actionAttack( bx, by, self.curDir.x, self.curDir.y, false )
					else
						self:actionAttack( bx, by, self.curDir.x, self.curDir.y, true )
						blk:attacked( a, 0, self )
					end
				end)
				return true
			else
				-- move player
				wCfg.force_move = 0 -- only foce move after attack
				if newX > MapTile_WH-1 or newX < 0 or newY > MapTile_WH-1 or newY < 0 then return false end
				self:actionMove( newX, newY )
				return true
			end
		end
		return false
	end,
	
	actionMove = function ( self, x, y )
		game.history.steps = game.history.steps + 1
		local xx, yy = self:getLogicPos()
        -- game:createEffect( 'res/smoke_anime/', '', xx, yy, 0, 16, 94/32, 43/32 )
		self:animeMove( x, y, function() 
			self:actionStepOnSomething()
			self:actionPickup() 
		end )
		self:moveCamera( x, y )
	end,

	moveCamera = function( self, x, y )
        local canvasWidth, canvasHeight = Canvas.main:size()
        local xx, yy = mapCfg.mox + x * 32 - canvasWidth * 0.5, mapCfg.moy + y * 32 - canvasHeight * 0.5
		tweenManager:addTween( Tween.new( 0.3, mainCamera, { lastX = xx, lastY = yy }, 'linear' ), true, nil )
	end,

	actionAttack = function( self, x, y, dirX, dirY, isSuccess )
		if game.weapon.cfg.energy > 0 then
			game.weapon.cfg.energy = game.weapon.cfg.energy - 1
		end
		local px, py = self:getLogicPos()
		-- show slash effect
		-- tweenManager:addSpriteAnimeSequence( SpriteAnimeSequence.new( game.weapon.cfg.img, { 
		-- 	{ target = { x = mapCfg.mox + px * 32 + dirX * 16, y = mapCfg.moy + py * 32 + dirY * 16, w = 32, h = 32, rotAngle = math.pi * 0 } }, 
		-- 	{ duration = 1, easing = 'outQuad', target = { x = mapCfg.mox + px * 32 + dirX * 16, y = mapCfg.moy + py * 32 + dirY * 16, w = 32, h = 32, rotAngle = math.pi * -1 } } 
		-- } ) )
		tweenManager:addTweenSequence( TweenSequence.new( self, { 
			{ target = {} }, 
			{ duration = 0.15, easing = 'inExpo', target = { x1 = px + dirX * 0.5, y1 = py + dirY * 0.5 } } , 
			{ duration = 0.65, easing = 'outExpo', target = { x1 = px, y1 = py } } 
		} ), false )
		if isSuccess then
			self:animeAttack( 'fire_blast', 'idle', x, y, 0, -32 * 1, 54/32 * 1, 90/32 * 1, function() 
				self:changeState()
			end )
		else
			-- play a small fire blast animation
			self:animeAttack( 'fire_blast', 'idle', x, y, 0, -32 * 0.25, 54/32 * 0.25, 90/32 * 0.25, function() 
				self:changeState()
			end )
			-- play shield animation
			game:createEffect( 'shield_def', 'idle', x, y, 0, 0, 33/32, 33/32 )
		end

		if game.weapon.cfg.energy == 0 then
			-- remove all crafted record of the same category as the broken weapon
			local currentGroup = game.weapon.cfg.baseweapon
			for k,v in ipairs(EquipmentDefList) do
				if currentGroup == v.baseweapon and exists( game.craftedEquipments, v.id ) then 
					remove( game.craftedEquipments, v.id )
				end
			end
			game:upgradeEquipment( FindEquipmentById('白板武器'), true )
		end
	end,
	
	actionSkipTurn = function(self)
		local px, py = self:getLogicPos()
		self:animeMove( px, py , nil )
	end,
	
	actionPickup = function( self )
		local ulist = game:getUnitAtPos( self:getLogicPos() )
        for k, v in ipairs(ulist) do
            if v.cfg.is_pickup then
				v:pickup()
				self:changeState()
            end
        end
		local px, py = self:getRealPos()
		for k,v in ipairs( projectileManager.projectiles ) do
			if (v.x - px)^2 + (v.y - py)^2 < self.pickup_range ^ 2 then
				local adjust = {400, 2, 40, 32}
				v:setMagnet( Vec2.new( 8 + 40, 640 - 8 - 15), adjust[1] )
				v:setAccept( Vec2.new( 8 + 40, 640 - 8 - 15), adjust[4], adjust[2], function( p )
					for k,v in pairs(CRYSTALS) do
						game.currency[k] = game.currency[k] + p.crystals[k]
						game.history.crystal_gain[k] = game.history.crystal_gain[k] + p.crystals[k]
					end
					self:changeState()
				end )
				v:setVelocity( Vec2.new(math.random() - 0.5, -math.random()).normalized:__mul( adjust[3] ) )
				v:setGravity( nil, 0, 0 )
				v.isActive = true
			end
		end
	end,

	actionStepOnSomething = function( self )
		local ulist = game:getUnitAtPos( self:getLogicPos() )
        for k, v in ipairs(ulist) do
			v:steppedOn( self:getLogicPos() )
        end
	end,

	attacked = function( self, attacker, att, att_effect_stun )
		print('player-attacked-' .. game.shield.cfg.energy_power .. '-' .. att)
		if att > 0 and game.shield.cfg.energy_power == 0 then
			-- game over
			game:lose( attacker )
		end
		if game.shield.cfg.energy_power > 0 then
			-- play shield animation
			local x, y = self:getLogicPos()
			game:createEffect( 'shield_def', 'idle', x, y, 0, 0, 33/32, 33/32 )
		end
		game.shield.cfg.energy_power = game.shield.cfg.energy_power - att
		if game.shield.cfg.energy_power < 0 then
			game.shield.cfg.energy_power = 0
		end
		if att_effect_stun > 0 then self.stun = self.stun + 1 end
		self:changeState()
	end,
	
	changeState = function( self )
		if game.shield.cfg.energy_power > 0 and game.weapon.cfg.energy > 0 then
			self.spr_:play('idle', false, true, true)
		elseif game.shield.cfg.energy_power > 0 then
			self.spr_:play('idle', false, true, true)
		elseif game.weapon.cfg.energy > 0 then
			self.spr_:play('idle', false, true, true)
		else
			self.spr_:play('idle', false, true, true)
		end
		game.uiDirty = true
	end,

    isInSight = function( self, x, y )
		-- check all light sources
		for k,v in ipairs( game.curLightSourceList ) do
			local xx, yy = v:getLogicPos()
			if v.cfg.light_range > 0 and ( xx - x ) * ( xx - x ) + ( yy - y ) * ( yy - y ) <= v.cfg.light_range ^ 2 then
				return true
			end
		end
		local px, py = self:getLogicPos()
        return ( px - x ) * ( px - x ) + ( py - y ) * ( py - y ) <= game.weapon.cfg.sight * game.weapon.cfg.sight
    end,
	
}, Object)