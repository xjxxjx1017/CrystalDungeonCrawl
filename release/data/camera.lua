require 'code/class'
require 'code/util'
require 'code/keycode'

ONE_SCREEN_GRID_COUNT = 24

MainCamera = class({
    cameraLimitX = nil,
    cameraLimitY = nil,
    lastX = 0,
    lastY = 0,

    ctor = function(self)
    end,

    reset = function(self)
        local adjust = { ( MapTile_WH - ONE_SCREEN_GRID_COUNT ) * 32 * - 0.5, 0, 
            ( MapTile_WH - ONE_SCREEN_GRID_COUNT ) * 32 * 0.5, ( MapTile_WH - ONE_SCREEN_GRID_COUNT ) * 32 }
        local canvasWidth, canvasHeight = Canvas.main:size()        
        self.cameraLimitMin = Vec2.new( adjust[1], adjust[2] )
        self.cameraLimitMax = Vec2.new( adjust[3], adjust[4] )
    end,

    getCameraPos = function( self )
        if self.lastX < self.cameraLimitMin.x then self.lastX = self.cameraLimitMin.x end
        if self.lastX > self.cameraLimitMax.x then self.lastX = self.cameraLimitMax.x end
        if self.lastY < self.cameraLimitMin.y then self.lastY = self.cameraLimitMin.y end
        if self.lastY > self.cameraLimitMax.y then self.lastY = self.cameraLimitMax.y end
        return self.lastX, self.lastY
    end,

    setCameraPos = function( self, x, y )
        self.lastX, self.lastY = x, y
    end,

    moveCameraPos = function( self, dx, dy )
        self.lastX, self.lastY = self.lastX + dx, self.lastY + dy
    end,

    gridToUIPos = function( self, x, y )
        local cx, cy = self:getCameraPos()
        return x - cx, y - cy
    end,

    uiToGridPos = function( self, x, y )
        local cx, cy = self:getCameraPos()
        -- printOnce('CameraPos', '', cx, cy )
        return x + cx, y + cy
    end,

    update = function(self, delta)
        -- get camera in the canvas limit
        if self.lastX < self.cameraLimitMin.x then self.lastX = self.cameraLimitMin.x end
        if self.lastX > self.cameraLimitMax.x then self.lastX = self.cameraLimitMax.x end
        if self.lastY < self.cameraLimitMin.y then self.lastY = self.cameraLimitMin.y end
        if self.lastY > self.cameraLimitMax.y then self.lastY = self.cameraLimitMax.y end
        local x, y = self:getCameraPos()
		-- printOnce('', 'Camera', x, y)
        camera(x, y)
    end,

})
mainCamera = MainCamera.new()

