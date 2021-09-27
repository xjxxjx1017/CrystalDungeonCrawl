require 'code/class'
require 'code/keycode'
require 'code/util'
require 'units/object'
local Tween = require 'code/tween' -- See https://github.com/kikito/tween.lua.

function AI_Loop( self )
	local think = function ( )
        local sx, sy = self:getLogicPos()
        local curStep = -1
        for i = 1, 8 do
            local xx = self.cfg.aiX + adjust8[i].x
            local yy = self.cfg.aiY + adjust8[i].y
            if sx == xx and sy == yy then
                curStep = i
                break
            end
        end
        local nextStep = curStep + self.cfg.aiStepDir
        if nextStep >= 9 then nextStep = 1 end
        if nextStep <= 0 then nextStep = 8 end
        local newX = self.cfg.aiX + adjust8[nextStep].x
        local newY = self.cfg.aiY + adjust8[nextStep].y
        return newX, newY
	end

    self:info('ai_loop')
    local x, y = think()
    self:info( 'x'..x..'y'..y )
    if game:getBlocked( x, y ) == nil and not( game:isPlayer( x, y ) ) then
        self:info( 'actionMove' )
        self:actionMove( x, y )
    elseif game:isPlayer( x, y ) then
        self:info( 'actionAttack' )
        self:actionAttack( x, y )
    else
        self.cfg.aiStepDir = 0 - self.cfg.aiStepDir
	end
end

function AI_Wonder( self )
	think = function ()
        local sx, sy = self:getLogicPos()
        local newX, newY = sx + self.cfg.aiPath[self.cfg.aiStep].x, sy + self.cfg.aiPath[self.cfg.aiStep].y
        if newX > MapTile_WH-1 or newX < 0 or newY > MapTile_WH-1 or newY < 0 then return sx, sy end
        self.cfg.aiStep = self.cfg.aiStep + 1
        if self.cfg.aiStep > #self.cfg.aiPath then self.cfg.aiStep = 1 end
		print(self.id .. '-think' .. '-' .. newX .. '-' .. newY)
        return newX, newY
	end

    if self.cfg.angry > 0 then
        self:info('ai_chasing')
        AI_CHASE_AND_ATTACK(self)
        return
    end

    self:info('ai_wonder')
    local x, y = think()
    self:info( 'x'..x..'y'..y )
    if game:getBlocked( x, y ) == nil and not( game:isPlayer( x, y ) ) then
        self:info( 'actionMove' )
        self:actionMove( x, y )
    elseif game:isPlayer( x, y ) then
        self:info( 'actionAttack' )
        self:actionAttack( x, y )
    end
end

function AI_Charge( self )
	think = function ()
        -- if it's already moving
        if self.cfg.curDx == 0 and self.cfg.curDy == 0 then
            self.cfg.curDx, self.cfg.curDy = self:getPlayerDir()
        end
        return self.cfg.curDx, self.cfg.curDy
	end
    local x, y = self:getLogicPos()
    local dx, dy = think()
    self:info( 'dx'..dx..'dy'..dy )
    self:info( 'actionMove' )
    self:actionMove( x + dx, y + dy )
end

function AI_Passive_ConterAttack( self )
    if self.cfg.angry <= 0 then return end
    self:info( 'AI_Passive_ConterAttack' )
    local foundPlayer = game:searchPlayer( adjust4, self:getLogicPos() )
    if foundPlayer ~= nil then
        self:info( 'actionAttack' )
        self:actionAttack( game.player:getLogicPos() )
    end
end

function AI_UnhideAttack( self )
    if self.cfg.hide > 0 and self.cfg.att > 0 then
        self:info( 'AI_UnhideAttack' )
        local foundPlayer = game:searchPlayer( adjust4, self:getLogicPos() )
        if foundPlayer ~= nil then
            self:info( 'actionAttack' )
            self:actionShow()
            self:actionAttack( game.player:getLogicPos() )
        end
    end
end

function AI_StepOnShow( self )
    if self.cfg.hide > 0 and self.cfg.att > 0 then
        self:info( 'AI_StepOnShow' )
        local x, y = self:getLogicPos()
        local p = game:isPlayer( x, y )
        if p then 
            self:info( 'actionAttack' )
            self:actionShow()
            self:actionAttack( x, y )
        end
    end
end

function AI_MONTHER( self )
    if self.cfg.born == 0 and #self.cfg.child < self.cfg.max_child then
        self:info( 'AI_MONTHER' )
        local x, y = self:getLogicPos()
        local availPos = {}
        for i = 1, 8 do
            local xx = x + adjust8[i].x
            local yy = y + adjust8[i].y
            if game:getBlocked( xx, yy ) == nil and game:isPlayer( xx, yy ) == false then
                table.insert( availPos, {x = xx, y = yy } )
            end
        end
        if #availPos > 0 then
            availPos = shuffle( availPos )
            UnitFactory_CreateUnit( self.cfg.child_id, availPos[1].x, availPos[1].y, true, 1, self.cfg.curLevel, self )
            game:sortByLevel()
        end
    end
end

function AI_GANG_TRACKER(self)
    if self.cfg.alarmed == true then
        self:info( 'AI_GANG_TRACKER' )
        local x, y = self:getLogicPos()
        local units = game:getUnitsInRange( x, y, self.cfg.alarm_ally_range )
        for k,v in ipairs( units ) do
            v.cfg.alarmed = true
        end
        AI_CHASE_AND_ATTACK(self)
    end
end

function AI_CHASE_AND_ATTACK(self)
    local x, y = self:getLogicPos()
    local xx, yy = self:getPlayerDir()
    x, y = x + xx, y + yy
    print('debug', '', x, y, xx, yy)
    if game:getBlocked( x, y ) == nil and not( game:isPlayer( x, y ) ) then
        self:info( 'actionMove' )
        self:actionMove( x, y )
    elseif game:isPlayer( x, y ) then
        self:info( 'actionAttack' )
        self:actionAttack( x, y )
    end
end

function AI_BLINK_ASSASIN(self)
    if self.cfg.alarmed == true then
        local px, py = game.player:getLogicPos()
        local x, y = self:getLogicPos()
        local foundPlayer = game:searchPlayer( adjust4, x, y )
        if foundPlayer ~= nil then
            self:info( 'actionAttack' )
            self:actionAttack( game.player:getLogicPos() )
            return
        end
        local inMaxRange = game:isPlayerInRange( x, y, self.cfg.blink_range_max )
        local inMinRange = game:isPlayerInRange( x, y, self.cfg.blink_range_min )
        local inCloseRange = game:isPlayerInRange( x, y, 2 )
        if self.cfg.angry > 0 then
            if inMaxRange and not( inMinRange ) then
                local empty = game:getEmptySpaceInRange( px, py, 1, 1)
                if #empty > 0 then
                    local l = shuffle(empty)[1]
                    self:actionMove( l.x, l.y )
                end
                return
            end
        elseif inMinRange and not( inCloseRange ) then
            local empty = game:getEmptySpaceInRange( px, py, 1, 1)
            if #empty > 0 then
                local l = shuffle(empty)[1]
                self:actionMove( l.x, l.y )
            end
            return
        elseif inCloseRange then
            local empty = game:getEmptySpaceInRange( px, py, self.cfg.blink_range_min, self.cfg.blink_range_max)
            if #empty > 0 then
                local l = shuffle(empty)[1]
                self:actionMove( l.x, l.y )
            end
            return
        end
    end
end