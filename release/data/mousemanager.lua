require 'code/class'
require 'code/co'
require 'code/util'
require 'code/keycode'

-- these number indicates minimum priority of each category
MOUSE_PRIORITY_DEBUG = 2000
MOUSE_PRIORITY_SYSTEM = 1000
MOUSE_PRIORITY_POPUP = 200
MOUSE_PRIORITY_UI = 100
MOUSE_PRIORITY_GAME = 50

MouseManager = class({
    mouseGridHintRes = nil,
    mousePlayerMoveArrowRes = nil,
    mouseBlockers = {},

    setup = function(self)
        self.mouseGridHintRes = sprPool:getRes( 'spr_ui/mouse_grid.spr', 'idle' )
        self.mousePlayerMoveArrowRes = sprPool:getRes( 'spr_ui/move_hint_arrow.spr', 'idle' )
    end,

    reset = function(self)
        self.mouseBlockers = {}
    end,

    setMouseBlocker = function( self, blockMaxPriority )
        if indexOf( self.mouseBlockers, blockMaxPriority ) < 1 then
            table.insert( self.mouseBlockers, blockMaxPriority )
        end
    end,

    removeMouseBlocker = function( self, blockMaxPriority )
        remove( self.mouseBlockers, blockMaxPriority )
    end,

    getMouse = function( self, priority )
        local mx, my, mb, b2, b3, wheel = mouse(1)
        for k,v in ipairs( self.mouseBlockers ) do
            if v >= priority then
                mb = false
                mx = -1
                my = -1
                b2 = false
                b3 = false
                wheel = 0
            end
        end
        return mx, my, mb, b2, b3, wheel
    end,
    
    getMouseGrid = function( self )
        local mx, my, mb = mouseManager:getMouse( MOUSE_PRIORITY_GAME )
        -- printOnce('mouse_grid', '', 'mx'..mx, 'my'..my, 'mxmin'.. mapCfg.moxNoCamera, 'mymin'..mapCfg.moyNoCamera, 'mxmax'..mapCfg.moxNoCamera + 32 * MapTile_WH, 'mymax'..mapCfg.moyNoCamera + 32 * MapTile_WH )
        if mx > mapCfg.moxNoCamera and my > mapCfg.moyNoCamera and mx < mapCfg.moxNoCamera + 32 * MapTile_WH and my < mapCfg.moyNoCamera + 32 * MapTile_WH then
            mx, my = mainCamera:uiToGridPos( mx, my )
            mx = mx - mapCfg.mox
            my = my - mapCfg.moy
            local mGridX = mx - mx % 32
            local mGridY = my - my % 32
            local gX = mGridX / 32
            local gY = mGridY / 32
            return gX, gY
        end
        return -1, -1
    end,
    
    getMousePlayerDir = function( self )
        local mx, my = self:getMouseGrid()
        local px, py = game.player:getLogicPos()
        local dx, dy = mx - px, my - py
        if (px ~= mx or py ~= my) and (mx >= 0 and my >= 0) then
            if math.abs(dx) >= math.abs(dy) then
                -- show movement hints on X axis
                local rotate = 0
                if dx < 0 then rotate = math.pi end
                local dd = dx / math.abs( dx )
                return Vec2.new( dd, 0 )
            else
                -- show movement hints on Y axis
                local rotate = math.pi * 0.5
                if dy < 0 then rotate = math.pi * 1.5 end
                local dd = dy / math.abs( dy )
                return Vec2.new( 0, dd )
            end
        end
        return nil
    end,
    
    update = function( self, delta )
        mainCamera:update(delta)
        local mx, my = self:getMouseGrid()
        local mmx, mmy, mb = mouseManager:getMouse( MOUSE_PRIORITY_GAME )
        local renderOnGrid = function ( res )
            if mx >= 0 and my >= 0 then
                -- render grid mouse over hint
                local cx, cy = mapCfg.mox + mx * 32, mapCfg.moy + my * 32
                -- printOnce( 'RenderGrid', '', mx, my, cx, cy, mapCfg.mox, mapCfg.moy, mapCfg.moxNoCamera, mapCfg.moyNoCamera )
                spr( res, cx, cy, 32, 32 )
            end
        end
        renderOnGrid( self.mouseGridHintRes )
        if game.waitForAction then
            -- render player move direction arrow
            local dir = self:getMousePlayerDir()
            if dir ~= nil then
                local rotate = 0
                if dir.x ~= 0 then
                    -- show movement hints on X axis
                    rotate = 0
                    if dir.x < 0 then rotate = math.pi end
                else
                    -- show movement hints on Y axis
                    rotate = math.pi * 0.5
                    if dir.y < 0 then rotate = math.pi * 1.5 end
                end
                local px, py = game.player:getLogicPos()
                local cx, cy = mapCfg.mox + (px+dir.x) * 32, mapCfg.moy + (py+dir.y) * 32
                spr( self.mousePlayerMoveArrowRes, cx, cy, 32, 32, rotate )
                if game.player.usingItem ~= nil then
                    renderOnGrid( self.mouseGridHintRes )
                end
            end
        end
        camera()
        if game.waitForAction then
            if game.player.usingItem ~= nil then
                local it = game.player.usingItem
                spr( ui_pool:getRes( it.cfg.img, 'idle' ), mmx - 16, mmy - 16, 32, 32 )
            end
        end
    end
})

mouseManager = MouseManager.new()



