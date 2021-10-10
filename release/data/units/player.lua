require 'code/class'
require 'code/keycode'
require 'code/util'
require 'units/object'
local Tween = require 'code/tween' -- See https://github.com/kikito/tween.lua.

local NO_ACTION = { event = '', dir = Vec2.new(0,0) }

Player = class({
	
	levelUpCrystalMark = { 5, 10, 20, 40, 100, 200, 500, 1000, 99999 },
    level = 0,
	stun = 0,
	pickup_range = 16 * 1.8,
    curMovingPath = {},
	curMovingPathIdx = 0, -- indicate which step it is a the moment. If player is not on the same grid as expect, it auto move will be terminated.
	leaveBattleCount = 0,
	usingItem = nil,
	playingItem = nil,
	playingItemStep = 1,
	playingItemDir = nil,
	lastAction = copy( NO_ACTION ),
	runeStepCount = 1,

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

	setCurrentMovingPath = function( self, path )
		if path == nil then self.curMovingPath = nil end
		local px, py = self:getLogicPos()
		local pv = Vec2.new( px, py )
		self.curMovingPath = concat( {pv}, path )
		self.curMovingPathIdx = 1
	end,

	nextAction = function( self )
		local px, py = self:getLogicPos()
		local changed = false
		local gx, gy = game.goal:getLogicPos()
		local wCfg = game:getWeapon().cfg
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
				game:setWeapon( 'force_att', 0 )
			else
				game:setWeapon( 'force_att', wCfg.force_att - 1 )
			end
		end

		if forceAttTarget ~= nil then
			self.curDir = forceAttTarget;
		else
			-- feature: force move check
			if wCfg.force_move > 0 then
				-- feature: if force move
				game:setWeapon( 'force_move', wCfg.force_move - 1 )
				local m = wCfg.cur_force_move
				self.curDir = m;
			else
				local triggerForceMove = function( dir )
					if wCfg.force_move_max > 0 then
						game:setWeapon( 'force_move', wCfg.force_move_max )
						game:setWeapon( 'cur_force_move', { x = dir.x, y = dir.y } )
					end
				end
				-- check keys, and whether a move action is possible
				for k, m in ipairs( self.playerMoves ) do
					-- check movement trigger by keyboard
					if key( m.k ) then
						-- feature: force move triggered
						triggerForceMove( m )
						self.curDir = m;
					end
				end
				-- check movement trigger by mouse
				local xx, yy, click = mouseManager:getMouse( MOUSE_PRIORITY_GAME )
				if click then
					local mouseDir = mouseManager:getMousePlayerDir()
					if mouseDir ~= nil then
						triggerForceMove( mouseDir )
						self.curDir = mouseDir
					end
				end
			end
		end
		
		if self.curDir ~= nil then

			if self.usingItem ~= nil then
				-- use the item
				print('使用物品: '..self.usingItem.cfg.id)
				remove( game.inventory, self.usingItem )
				self.playingItem = self.usingItem
				self.usingItem = nil
				self.playingItemStep = 1
				self.playingItemDir = copy( self.curDir )
				self:playItemStep()
				return true
			end
			
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
					game:setWeapon( 'force_att', wCfg.force_att_max )
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
					local energyRate = 1
					if energyRate <= TANDAO_LIMIT_1 then
						if math.random() < 0.25 then attackFailed = true print('attact failed - 1') end
					elseif energyRate <= TANDAO_LIMIT_2 then
						if math.random() < 0.5 then attackFailed = true rint('attact failed - 2') end
					end
					-- check red barrier
					if blk.cfg.red_barrier > 0 and game.currency.crystal4 < blk.cfg.red_barrier then
						attackFailed = true
					else
						game.currency.crystal4 = game.currency.crystal4 - blk.cfg.red_barrier
						attackFailed = false
						blk:removeRedBarrier()
					end
					-- perform attack action
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
				game:setWeapon( 'force_move', 0 ) -- only foce move after attack
				if newX > MapTile_WH-1 or newX < 0 or newY > MapTile_WH-1 or newY < 0 then return false end
				self:actionMove( newX, newY )
				return true
			end
		else
			if self.playingItem ~= nil then
				local isUsed = self:playItemStep()
				if isUsed then return true end
			end
		end
		return false
	end,

	playItemStep = function(self)
		-- each step can have multiple counts ( or small steps to finish the step ), so we need to count the script index
		local scriptIndex = getIndexByStep( self.playingItem.cfg.script, 'count', self.playingItemStep )
		print( 'Player script..'..'id'..self.playingItem.cfg.id..' step'..self.playingItemStep..' idx'..scriptIndex )
		-- check if there's no further script to run
		if scriptIndex > #self.playingItem.cfg.script or scriptIndex == 0 then
			self.playingItem = nil
			self.playingItemDir = nil
			self.playingItemStep = -1
			return false
		end
		-- run the script
		local item = self.playingItem
		local step = self.playingItem.cfg.script[scriptIndex]
		local ai = step.action
		ai( self, self.playingItemDir, item, step )
		-- add 1 to step count
		self.playingItemStep = self.playingItemStep + 1
		return true
	end,

	checkRuneStep = function( self, event, xOriginal, yOriginal )
		local px, py = self:getLogicPos()
		local dir = Vec2.new( px - xOriginal, py - yOriginal )
		if dir:__len() > 0 then dir = dir.normalized end
		-- calculate the angle
		local angle = -1
		local lastDir = self.lastAction.dir
		if dir:__eq( lastDir ) then angle = 0
		elseif dir.x == lastDir.x * -1 or dir.y == lastDir.y * -1 then angle = 180 
		elseif dir.x == 0 and dir.y == 0 then angle = -1
		else angle = 90 end
		self.lastAction = { event = event, dir = dir }
		for k,v in ipairs( game.rune ) do
			local patternIndex = getIndexByStep( v.cfg.pattern, 'count', v.cfg.step )
			print( 'Player rune..'..'id'..v.cfg.id..' step'..v.cfg.step..' idx'..patternIndex..' angle'..angle..'event'..self.lastAction.event )
			if patternIndex == 0 or patternIndex > #v.cfg.pattern then
				v.cfg.step = 1
			else
				-- check whether progressing steps
				local curP = v.cfg.pattern[ patternIndex ]
				if self.lastAction.event == curP.event and ( angle == curP.angle or curP.angle < 0 or angle < 0 ) then
					v.cfg.step = v.cfg.step + 1
					-- check action trigger
					local patternIndex = getIndexByStep( v.cfg.pattern, 'count', v.cfg.step )
					curP = v.cfg.pattern[ patternIndex ]
					if curP.action ~= nil then
						curP.action( self, Vec2.new(0,0), v, curP )
						v.cfg.step = 1
					end
				else
					v.cfg.step = 1
				end
			end
		end
	end,
	
	actionMove = function ( self, x, y )

		self.leaveBattleCount = self.leaveBattleCount + 1
		self:actionRecover()

		game.history.steps = game.history.steps + 1
		local xx, yy = self:getLogicPos()
        -- game:createEffect( 'res/smoke_anime/', '', xx, yy, 0, 16, 94/32, 43/32 )
		self:animeMove( x, y, function() 
			self:checkRuneStep( 'move', xx, yy )
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

		self.leaveBattleCount = 0
		if game.weaponTemp ~= nil then
			if game.weaponTemp.cfg.energy > 0 then
				game.weaponTemp.cfg.energy = game.weaponTemp.cfg.energy - 1
			end
		else
			local shield = game.shield
			local weapon = game:getWeapon()
			-- if weapon has hp cost
			if weapon.cfg.hp_cost > 0 then
				game.shield.cfg.energy_power = shield.cfg.energy_power - weapon.cfg.hp_cost
				if game.shield.cfg.energy_power < 0 then game.shield.cfg.energy_power = 0 end
			end
			-- if weapon has exp cost
			if weapon.cfg.att_cost.crystal_exp > 0 then
				game.currency.crystal_exp = game.currency.crystal_exp - weapon.cfg.att_cost.crystal_exp
				if game.currency.crystal_exp < 0 then game.currency.crystal_exp = 0 end
			end
		end
		local px, py = self:getLogicPos()
		-- show slash effect
		-- tweenManager:addSpriteAnimeSequence( SpriteAnimeSequence.new( img, { 
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
				self:checkRuneStep( 'attack', px, py )
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

		if game.weaponTemp ~= nil and game.weaponTemp.cfg.energy == 0 then
			game.weaponTemp = nil
		end
	end,
	
	actionSkipTurn = function(self)
		local px, py = self:getLogicPos()
		self:animeMove( px, py , nil )
		for k,v in ipairs( game.rune ) do
			v.cfg.step = 1
		end
		self.lastAction = copy( NO_ACTION )
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

	actionRecover = function( self )
		if self.leaveBattleCount > 3 then
			if game.currency.crystal1 > 0 and game.shield.cfg.energy_power < game.shield.cfg.energy_power_max then
				game.currency.crystal1 = game.currency.crystal1 - 1
				game.shield.cfg.energy_power = game.shield.cfg.energy_power + 1
			end
		end
	end,

	actionUseItem = function( self, item )
		self.usingItem = item
	end,

	attacked = function( self, attacker, att, att_effect_stun )
		self.leaveBattleCount = 0
		print('player-attacked-' .. game.shield.cfg.energy_power .. '-' .. att)
		-- check extra hp
		if self.cfg.extra_hp then 
			if att >= self.cfg.extra_hp then
				att = att - self.cfg.extra_hp
				self.cfg.extra_hp = 0
			else
				self.cfg.extra_hp = self.cfg.extra_hp - att
			end
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
		if att > 0 and game.shield.cfg.energy_power == 0 then
			-- check hard def
			if self.cfg.hard_def > 0 then
				self.cfg.hard_def = self.cfg.hard_def - 1
				game.shield.cfg.energy_power = 1
			else
				-- game over
				game:lose( attacker )
			end
		end
		if att_effect_stun > 0 then self.stun = self.stun + 1 end
		self:changeState()
	end,

    healed = function( self, source, amount )
		print( 'player healed'..amount )
		game.shield.cfg.energy_power = game.shield.cfg.energy_power + amount
		local x, y = self:getLogicPos()
		self:animeAttack( 'att_effect', 'heal', x, y, 0, 0, 1, 1 )   
		if game.shield.cfg.energy_power > game.shield.cfg.energy_power_max then
			game.shield.cfg.energy_power = game.shield.cfg.energy_power_max
		end
    end,
	
	changeState = function( self )
		if game.shield.cfg.energy_power > 0 and game:getWeapon().cfg.energy > 0 then
			self.spr_:play('idle', false, true, true)
		elseif game.shield.cfg.energy_power > 0 then
			self.spr_:play('idle', false, true, true)
		elseif game:getWeapon().cfg.energy > 0 then
			self.spr_:play('idle', false, true, true)
		else
			self.spr_:play('idle', false, true, true)
		end
		self:checkLevelUp()
		game.uiDirty = true
	end,

	checkLevelUp = function( self )
		local resetChoicesAndLevelUp = function()
			mouseManager:removeMouseBlocker( MOUSE_PRIORITY_POPUP - 1 )
			game.choices = {}
			self.level = self.level + 1
			self:checkLevelUp()
		end
		local resetChoices = function()
			mouseManager:removeMouseBlocker( MOUSE_PRIORITY_POPUP - 1 )
			game.choices = {}
			self:checkLevelUp()
		end
		if self.level < 1 then
			mouseManager:setMouseBlocker( MOUSE_PRIORITY_POPUP - 1 )
			game.choicesTitle = '请选择 - 本命武器'
			game.choices = {
				{ text = "火焰之剑", callback = function() 
					game:upgradeEquipment( FindEquipmentById('火焰之剑'), true, true )
					resetChoicesAndLevelUp()
				end },
				{ text = "火焰之矛", callback = function() 
					game:upgradeEquipment( FindEquipmentById('火焰之矛'), true, true )
					resetChoicesAndLevelUp()
				end },
				{ text = "火焰弓", callback = function() 
					game:upgradeEquipment( FindEquipmentById('火焰弓'), true, true )
					resetChoicesAndLevelUp()
				end },
				{ text = "火焰斧", callback = function() 
					game:upgradeEquipment( FindEquipmentById('火焰斧'), true, true )
					resetChoicesAndLevelUp()
				end },
			}
		elseif self.level > 0 and #game.rune == 0 then
			mouseManager:setMouseBlocker( MOUSE_PRIORITY_POPUP - 1 )
			game.choicesTitle = '请选择 - 刻印 (可以触发效果的舞蹈方式)'
			game.choices = {
				{ text = "春风的刻印 - 来回走动能得到加持", callback = function() 
					game:upgradeEquipment( RUNE_HEAL, true, true )
					resetChoices()
				end },
				{ text = "龟壳的刻印 - 攻击后撤退能得到加持", callback = function() 
					game:upgradeEquipment( RUNE_GUARD, true, true )
					resetChoices()
				end },
				{ text = "冲锋的刻印 - 努力冲锋，能加持下一次的攻击", callback = function() 
					game:upgradeEquipment( RUNE_CHARGE, true, true )
					resetChoices()
				end },
			}
		else
			local currency = game.currency.crystal_exp
			local markCurrency = self.levelUpCrystalMark[ self.level ]
			local shouldLevelUp = currency > markCurrency
			if shouldLevelUp then
				mouseManager:setMouseBlocker( MOUSE_PRIORITY_POPUP - 1 )
				game.choicesTitle = '升级了！请选择升级奖励'
				game.choices = {
					{ text = "所有武器的攻击力+1，耐久度消耗+1", callback = function() 
						game:upgradeEquipment( FindEquipmentById(game.shield.cfg.level_up[1]), true, true )
						game.weaponEnhance.cfg.att = game.weaponEnhance.cfg.att + 1
						game.weaponEnhance.cfg.energy_max = game.weaponEnhance.cfg.energy_max + 1
						resetChoicesAndLevelUp()
					end },
					{ text = "所有武器的耐久度上限+2", callback = function() 
						game:upgradeEquipment( FindEquipmentById(game.shield.cfg.level_up[1]), true, true )
						game.weaponEnhance.cfg.energy_max = game.weaponEnhance.cfg.energy_max + 2
						resetChoicesAndLevelUp()
					end },
					{ text = "本命武器的攻击力+2，能量消耗+2", callback = function() 
						game:upgradeEquipment( FindEquipmentById(game.shield.cfg.level_up[1]), true, true )
						game.weaponMain.cfg.att = game.weaponMain.cfg.att + 2
						if game.weaponMain.cfg.hp_cost > 0 then game.weaponMain.cfg.hp_cost = game.weaponMain.cfg.hp_cost + 2 end
						if game.weaponMain.cfg.att_cost.crystal_exp > 0 then game.weaponMain.cfg.att_cost.crystal_exp = game.weaponMain.cfg.att_cost.crystal_exp + 2 end
						resetChoicesAndLevelUp()
					end },
					{ text = "额外增加护盾，并增加红水晶、蓝水晶各10个", callback = function() 
						game:upgradeEquipment( FindEquipmentById(game.shield.cfg.level_up[1]), true, true )
						game:upgradeEquipment( FindEquipmentById(game.shield.cfg.level_up[1]), true, true )
						game.currency.crystal1 = game.currency.crystal1 + 10
						game.currency.crystal4 = game.currency.crystal4 + 10
						resetChoicesAndLevelUp()
					end },
				}
			end
		end
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
        return ( px - x ) * ( px - x ) + ( py - y ) * ( py - y ) <= game:getWeapon().cfg.sight * game:getWeapon().cfg.sight
    end,
	
}, Object)