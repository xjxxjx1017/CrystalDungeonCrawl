require 'code/class'
require 'code/keycode'
require 'code/util'
require 'units/object'
local Tween = require 'code/tween' -- See https://github.com/kikito/tween.lua.

--[[

单位的抽象化UnitMaster
    单位的真正不同 - 图片，AI，生成逻辑 (先不考虑boss, 不考虑地形)
    * 怪物Factory。初始化怪物，应该用一系列参数就行，可以仅凭参数初始化出任意怪物。
    * 多个AI函数，放在AI文件里，传参数的时候，传进去。
    * 生成函数( 中心点，生成范围，生成数量，掉落数量，怪物等级 )
    * alert属性，警戒范围
    * trample属性
    * stun的被动属性, 自生AI也会触发stun
    * 追踪玩家，保持当前移动方向，直到无法移动
    * hide xxx回合的属性，切换入地与升上来状态。hide状态被踩，会解除并会攻击正上方。
    * 生成单位在xxx，跟踪生成单位的总数。被生成的单位会记录其parent
    * 单位的唯一ID序列
    * 预定模式的移动路径，当前的step

走上去会被给予定身的效果的地形（water）。玩家到达地形上之后，增加stun
可以破坏的地形（tree）

]]

Unit_Info = function( surfix, id, details, cfg )
    if DEBUG_UNIT == false and DEBUG_RENDER_ORDER == false then return end
    if DEBUG_RENDER_ORDER == true and details ~= '#render#' then return end
    print( surfix, ' ', id or 'N', details or '---', 'hp'..cfg.hp, 'att'..cfg.att, 'att_trample'..cfg.att_trample )
end

UnitMaster = class({

	ctor = function ( self, typename, cfg, x, y, level, cfgOverwrite )
        -- print('', 'UnitMaster-creating name: '..typename )
        local c = merge( Config_Base, copy(cfg) )
		if cfgOverwrite ~= nil then
        	c = merge( c, cfgOverwrite )
		end

        -- overwrite unit properties according to unit level
        if c.level ~= nil and #c.level > 0 then
            c.curLevel = level
            c = merge( c, c.level[c.curLevel] )
        else
            c.curLevel = -3
        end
        -- assign maxHp value, if not assigned already
        if c.hp > 0 and c.maxHp == 0 then
            c.maxHp = c.hp
        end

        -- generate a random weapon
        if c.pickup_equipment_random then
            c.pickup_equipment = AllPickupEquipmentIds[ math.random(1, #AllPickupEquipmentIds) ]
            local equip = FindEquipmentById( c.pickup_equipment )
            c.img = equip.img
        end
        -- generate a random script
        if c.pickup_script_random then
            c.pickup_equipment = AllScriptEquipmentIds[ math.random(1, #AllScriptEquipmentIds) ]
            local equip = FindEquipmentById( c.pickup_equipment )
            c.img = equip.img
            c.level = equip.level
        end

        -- initialize parts if there's any
        local initedParts = {}
        local px, py = x, y
        for k,v in ipairs( c.parts ) do
            local p = UnitMaster.new( 'parts.' .. typename, copy(v), x + v.x, y + v.y, level )
            p.cfg.owner = self
            table.insert( initedParts, p )
        end
        c.parts = initedParts
        if #initedParts > 0 then px, py = c.parts[1]:getLogicPos() end

		c.att_trample = c.att_trample_max
		if #c.aiPath > 0 then 
			c.aiStep = math.random(1, #c.aiPath);
		end

        -- initialize this unit
        Object.ctor(self, typename, px, py, c, mapCfg.mox, mapCfg.moy )
        game:addUnit( self )
        -- add to its parent, if any
        if cfg.parent ~= nil then
            self.cfg.parent = cfg.parent -- to restore the real parent from deep copy.
            table.insert( self.cfg.parent.cfg.child, self )
        end
	end,

    actionMove = function( self, x, y )
        local sx, sy = self:getLogicPos()
        local dx, dy = x - sx, y - sy
        if self:isOutOfMap( dx, dy ) then
            self:trampleUsed(999)
            return
        end
        for k,v in pairs( self.cfg.parts ) do
            local sx, sy = v:getLogicPos()
            if v:isOutOfMap( dx, dy ) then
                self:trampleUsed(999)
                return
            end
        end
        local dsx, dsy = self:getDisplayPos()
        local tx, ty = dsx + dx, dsy + dy
        if game.player ~= nil then
            self:reduceAngry()
			if ( game.player:isInSight( tx, ty ) or game.player:isInSight( dsx, dsy ) ) and self.cfg.ai ~= AI_BLINK_ASSASIN then
                -- play move animation if player can see this
                -- game:createEffect( 'res/smoke_anime/', '', sx, sy, 1, 1 )
	            self:animeMove(tx, ty )
	            self:info( 'actionTrample' )
	            self:actionTrample( tx, ty )
	        else
                -- otherwise move instantly
	            self:setAllpos( tx, ty )
	        end
		end
        -- move all its parts instantly
        for k,v in pairs( self.cfg.parts ) do
            local ppx, ppy = v:getLogicPos()
            tx, ty = ppx + dx, ppy + dy
            v:setAllpos( tx, ty )
            v:info( 'actionTrample' )
            v:actionTrample( tx, ty )
        end
    end,

    actionAttack = function ( self, x, y )
        if game.player == nil then return end
        if self.cfg.att > 0 or self.cfg.att_effect_stun > 0 then
            self:reduceAngry()
            if self.cfg.is_stationary == false then 
                local xx, yy = self:getRenderPos()
                local dir = Vec2.new( x, y ):__sub( Vec2.new( xx, yy ) ).normalized
                tweenManager:addTweenSequence( TweenSequence.new( self, { 
                    { target = {} }, 
                    { duration = 0.3, easing = 'inExpo', target = { x1 = xx + dir.x * 0.5, y1 = yy + dir.y * 0.5 } } , 
                    { duration = 0.5, easing = 'outExpo', target = { x1 = xx, y1 = yy } } 
                } ), true )
            end
            self:animeAttack( 'att_effect', self.cfg.att_img, x, y, 0, 0, 1, 1, function() 
                game.player:attacked( self.cfg.id, self:getAtt( game.player ), self.cfg.att_effect_stun )
                if self.cfg.att_self_damage > 0 then
                    self:selfDamaged( self.cfg.att_self_damage )
                end
            end )
        end
    end,

    actionHeal = function( self )
		local x, y = self:getLogicPos()
        if game.player:isInSight( x, y ) then
            self:animeAttack( 'att_effect', 'casting', x, y, 0, 0, 1, 1 )    
        end
    end,

    reduceAngry = function( self )
        self.cfg.angry = self.cfg.angry - 1
        if self.cfg.angry < 0 then self.cfg.angry = 0 end
    end,

    actionTrample = function ( self, x, y )
        if game.player == nil then return end
        -- if it is not a parts owner
        if #self.cfg.parts == 0 and self:getAttTrampleMax() > 0 then
            -- trample attack
            if game:isPlayer( x, y ) then
                self:animeAttack( 'att_effect', self.cfg.att_img, x, y, 0, 0, 1, 1, nil )    
                self:trampleUsed( 1 )
                game.player:attacked( self.cfg.id, self:getAtt( game.player ), self.cfg.att_effect_stun )
            end
            -- check all the units, to see whether any gets trampled
            for k,v in ipairs(game:getBoard(x, y)) do
                if v.cfg.can_trample and v.cfg.hp > 0 then
                    self:trampleUsed( 1 )
                    -- v:attacked( self:getAtt( v ), self.cfg.att_effect_stun, self )
                    v:killThis()
                end
            end
        end
    end,

    actionHide = function( self )
        self.cfg.hide = self.cfg.hide_max
        self.cfg.show = 0
		local x, y = self:getLogicPos()
        if game.player:isInSight( x, y ) then
            self:animeAttack( 'att_effect', 'blunt', x, y, 0, 0, 1, 1, function() self.isShow = false end )    
        else
            self.isShow = false
        end
    end,

    actionShow = function( self )
        self.cfg.show = self.cfg.show_max
        self.cfg.hide = 0
		local x, y = self:getLogicPos()
        if game.player:isInSight( x, y ) then
            self:animeAttack( 'att_effect', 'blunt', x, y, 0, 0, 1, 1, function() self.isShow = true end )    
        else
            self.isShow = true
        end
        if self.cfg.walked_on_damage then
            local x, y = self:getLogicPos()
            local p = game:isPlayer( x, y )
            if p then 
                self:info( 'actionShow - actionAttack' )
                self:actionAttack( x, y )
            end
        end
    end,

    nextAction = function(self)
        if self.cfg.ai ~= nil or self.cfg.is_terrain == false then
            self:actionStatusUpdate()
        end
        if self.cfg.ai ~= nil then
            if not(self.cfg.alarmed) and self.cfg.aiLazy then return end
            if self.cfg.stun > 0 then return end
            print(self.id .. '-ai')
            self.cfg.ai( self )
        end
    end,

    actionStatusUpdate = function( self, x, y )
        -- update alarmed
        if game.player ~= nil and self.cfg.alarmed == false then
            local plx, ply = game.player:getLogicPos()
            local inSight = self:isInSight( plx, ply )
            if inSight then 
                self.cfg.alarmed = true
                self:info( 'alarmed' )
            end
        end
        -- update stun
        if self.cfg.stun > 0 then
            self.cfg.stun = self.cfg.stun - 1
            self.cfg.curDx, self.cfg.curDy = 0, 0
            self:info( 'stun' )
        end
        if self.cfg.stepLoop > 0 then
            self.cfg.curStep = self.cfg.curStep + 1
            if self.cfg.curStep >= self.cfg.stepLoop then
                self.cfg.curStep = 1
            end
            self:info( 'step '..self.cfg.curStep )
        end
        -- update trample and stun
        if self.cfg.att_trample <= 0 and self.cfg.stun == 0 then
            self.cfg.stun = self.cfg.att_trample_stun
            self.cfg.att_trample = self.cfg.att_trample_max
            self.cfg.curDx, self.cfg.curDy = 0, 0
            self:info( 'trample->stun' )
        end
        if self.cfg.hide > 0 then
            self.cfg.hide = self.cfg.hide - 1
            if self.cfg.hide == 0 then
                self:actionShow()
            end
        elseif self.cfg.show > 0 then
            self.cfg.show = self.cfg.show - 1
            if self.cfg.show == 0 then
                self:actionHide()
            end
		end
        if self.cfg.born > 0 then
            self.cfg.born = self.cfg.born - 1
        elseif self.cfg.born == 0 and self.cfg.born_interval > 0 then
            self.cfg.born = self.cfg.born_interval
        end
    end,

    info = function( self, details )
        Unit_Info( 'INFO', self.id .. ' x' .. self.x2 .. 'y' .. self.y2, details, self.cfg )
    end,

    trampleUsed = function ( self, amount )
        self:info( 'trampleUsed'..amount )
        if self.cfg.owner == nil then
            if self.cfg.att_trample > 0 then
                self.cfg.att_trample = self.cfg.att_trample - amount
            end
        else
            -- if this is a part of a larger unit, the unit is attacked
            self.cfg.owner:trampleUsed( amount )
        end
    end,

    attacked = function ( self, att, att_effect_stun, attacker )
        self:info( 'attacked att'..att .. 'att_effect_stun'..att_effect_stun )
        self.cfg.alarmed = true
        if self.cfg.owner == nil then
            if self.cfg.hp ~= nil and self.cfg.hp > 0 then
                self:info( 'attacked'..att )
                self.cfg.hp = self.cfg.hp - att
                self.cfg.angry = self.cfg.angry + 1
                self.cfg.stun = self.cfg.stun + att_effect_stun
                if self.cfg.hp <= 0 then
                    table.insert( game.history.monster_kill, self.cfg.id )
                    self:killThis( attacker )
                end
            end
        else
            -- if this is a part of a larger unit, the unit is attacked
            self.cfg.owner:attacked( att, att_effect_stun )
        end
    end,

    healed = function( self, source, amount )
        if self.cfg.owner == nil then
			if self.cfg.hp == nil then
			a = 0
			end
            if self.cfg.hp > 0 and self.cfg.hp < self.cfg.maxHp then
                self:info( 'healed'..amount )
                self.cfg.hp = self.cfg.hp + amount
                local x, y = self:getLogicPos()
                if game.player:isInSight( x, y ) then
                    self:animeAttack( 'att_effect', 'heal', x, y, 0, 0, 1, 1 )    
                end
                if self.cfg.hp >= self.cfg.maxHp then
                    self.cfg.hp = self.cfg.maxHp
                end
            end
        else
            -- if this is a part of a larger unit, the unit is attacked
            self.cfg.owner:healed( source, amount )
        end
    end,

    selfDamaged = function ( self, att )
        self:info( 'selfDamaged att'..att )
        if self.cfg.owner == nil then
            if self.cfg.hp > 0 then
                self:info( 'selfDamaged'..att )
                self.cfg.hp = self.cfg.hp - att
                if self.cfg.hp <= 0 then
                    self:killThis()
                end
            end
        else
            -- if this is a part of a larger unit, the unit is attacked
            self.cfg.owner:selfDamaged( att )
        end
    end,

    steppedOn = function (self, x, y )
        self:info( 'steppedOn x'..x .. 'y'..y )
        if self.cfg.walked_on_damage and self.isShow then
            self:actionAttack( x, y )
        end
    end,
	
	getAttTrampleMax = function(self)
		local att_trample_max = self.cfg.att_trample_max
		if self.cfg.owner ~= nil then 
			att_trample_max = self.cfg.owner.cfg.att_trample_max 
		end
		return att_trample_max
	end,

    getAtt = function( self, target )
        if target.is_terrain then
            return self.cfg.att_terrain
        else
            return self.cfg.att
        end
    end,

    removeRedBarrier = function( self )
        self:info( 'redBarrierRemoved' )
        self.cfg.red_barrier = 0
        -- remove attackable status for pickup items
        if self.cfg.is_pickup then 
            self.cfg.can_player_attack = false 
            self.cfg.blocking = false
            self.cfg.hp = 0 
        end
    end,

    killThis = function( self, attacker )
        self:info( 'killThis' )
        self:drop()
        local vx, vy = self:getLogicPos()
        if self.cfg.die_summon then
            UnitFactory_CreateUnit( UnitDef[self.cfg.summon_monster_white].id, vx, vy, false, self.cfg.summon_count, self.cfg.summon_level, nil, { angry = 3, crystal_white = true } )
        end
        if #self.cfg.parts == 0 and self.cfg.is_terrain then
            UnitFactory_CreateUnit( UnitDef.DESERTED.id, vx, vy, true, 1, 1 )
        end
        if attacker == game.player then
            UnitFactory_CreateUnit( UnitDef.FIRE_REMAIN.id, vx, vy, true, 1, 1 )
        end
        for k,v in pairs( self.cfg.parts ) do
            local vvx, vvy = v:getLogicPos()
            game:removeUnit( v )
            if attacker == game.player then
                UnitFactory_CreateUnit( UnitDef.FIRE_REMAIN.id, vvx, vvy, true, 1, 1 )
            end
        end
        game:removeUnit( self )
        if self.cfg.parent ~= nil then
            remove( self.cfg.parent.cfg.child, self )
        end
        if self.cfg.is_drop_badge and game.badge == nil then
            -- 掉落空白badge
            -- UnitFactory_CreateUnit( UnitDef.BADGE.id, vx, vy, true, 1, 1 )
        end
        game:sortByLevel()
    end,

    drop = function(self)
        for k,v in pairs( self.cfg.parts ) do
            v:drop()
        end
        if self.cfg.dropImg ~= nil then
            -- firing a dropping crystal
            local xx, yy = self:getRenderPos()
            -- get random color key sequence
            local allKeys = shuffle( CRYSTALS_COMMON )
            if self.cfg.crystal > 0 then
                local ck = {}
                if self.cfg.crystal_drop_only ~= nil then
                    ck[self.cfg.crystal_drop_only] = self.cfg.crystal
                elseif self.cfg.crystal_white == false then
                    ck['crystal1'] = math.ceil( self.cfg.crystal * 0.5 )
                    if game.weaponTemp == nil then
                        ck['crystal_exp'] = self.cfg.crystal - ck['crystal1']
                    else
                        ck['crystal4'] = self.cfg.crystal - ck['crystal1']
                    end
                    local diff = self.cfg.curLevel - game.player.level
                    if diff > 0 then
                        ck['crystal_white'] = diff
                    end
                else
                    ck['crystal_white'] = self.cfg.crystal
                end
                game:dropCrystal( xx, yy, ck )
            end
        end
        if self.cfg.crystal_collector and Crystals_sum( self.cfg.crystal_collected ) then
            local xx, yy = self:getRenderPos()
            Projectile_DropCrystals( mapCfg.mox + 32 * xx + 16, mapCfg.moy + 32 * yy + 16, self.cfg.crystal_collected )
        end
    end,

    pickup = function(self)
        if self.cfg.is_pickup then
            self:info( 'pickup' )
            if self.cfg.pickup_equipment ~= nil then
                game:upgradeEquipment( FindEquipmentById( self.cfg.pickup_equipment ), true, false )
            end
            game:removeUnit( self )
        end
    end,

    getPlayerDir = function(self)
        if game.player == nil then return 0, 0 end
        -- check where's the player's relative position
        local plx, ply = game.player:getLogicPos()
        local avrX, avrY = self:getLogicPos()
        local ddx, ddy = plx - avrX, ply - avrY
        if math.abs(ddx) - math.abs(ddy) > 0 or ( math.random() > 0.5 and math.abs(ddx) == math.abs(ddy) ) then
            return ddx / math.abs(ddx), 0
        else
            return 0, ddy / math.abs(ddy)
        end
    end,

    getAIPointDir = function( self )
        if self.cfg.aiX == nil or self.cfg.aiY == nil then return self:getPlayerDir() end
        local plx, ply = self.cfg.aiX, self.cfg.aiY
        local avrX, avrY = self:getLogicPos()
        local ddx, ddy = plx - avrX, ply - avrY
        if math.abs(ddx) - math.abs(ddy) > 0 or ( math.random() > 0.5 and math.abs(ddx) == math.abs(ddy) ) then
            return ddx / math.abs(ddx), 0
        else
            return 0, ddy / math.abs(ddy)
        end
    end,

    getLogicPos = function(self)
        if #self.cfg.parts == 0 then
            return self.x2, self.y2
        end
        local avrX, avrY = 0, 0
        for k,v in ipairs( self.cfg.parts ) do
            local px, py = v:getLogicPos()
            avrX, avrY = avrX + px / #self.cfg.parts, avrY + py / #self.cfg.parts
        end
        return avrX, avrY
    end,

	getDisplayPos = function(self)
        if #self.cfg.parts == 0 then
            return self.x2, self.y2
        end
        return self.cfg.parts[1].x2, self.cfg.parts[1].y2
	end,

    isOutOfMap = function( self, dx, dy )
        -- check if it's going to the edge of the world
        local minX, maxX, minY, maxY = 99, -1, 99, -1
        local mapMin, mapMax = 0, MapTile_WH-1
        for k,v in ipairs( self.cfg.parts ) do
            local px, py = v:getLogicPos()
            if px + dx > maxX then maxX = px + dx end
            if py + dy > maxY then maxY = py + dy end
            if px + dx < minX then minX = px + dx end
            if py + dy < minY then minY = py + dy end
        end
        local px, py = self:getLogicPos()
        if px + dx > maxX then maxX = px + dx end
        if py + dy > maxY then maxY = py + dy end
        if px + dx < minX then minX = px + dx end
        if py + dy < minY then minY = py + dy end
        return maxX > mapMax or maxY > mapMax or minX < mapMin or minY < mapMin
    end,

    isInSight = function( self, x, y )
        if self.cfg.alarm_range <= 0 then return false end
        local result = false 
        for k,v in ipairs( self.cfg.parts ) do
            local px, py = v:getLogicPos()
            result = result or ( px - x )*( px - x ) + ( py - y ) * ( py - y ) <= self.cfg.alarm_range * self.cfg.alarm_range
        end
        local px, py = self:getLogicPos()
        result = result or ( px - x )*( px - x ) + ( py - y ) * ( py - y ) <= self.cfg.alarm_range * self.cfg.alarm_range
        return result
    end,

}, Object)