
--[[
    Projectile class is a class that enable game objects that are not bind to the game's grid systems.
    For example: 
        dropping crystals
        collecting crystals
        arrows ( can dodge )
        boss's fireball from the sky
]]

ProjectileManager = class({

    projectiles = {},

    update = function(self, delta)
        for k, v in ipairs( self.projectiles ) do
            v:update( delta )
        end
    end,

    render = function(self)
        for k, v in ipairs( self.projectiles ) do
            v:render()
        end
    end,

})
projectileManager = ProjectileManager.new()

Projectile = class({
    x = 0,
    y = 0,
    w = 0, 
    h = 0,
    angle = 0,

    -- basic physics
    v = Vec2.new( 0, 0 ),
    friction = 1,
    -- assuming mass is always 1

    -- making projectiles constantly moving to it and then bounce
    gravity = nil,
    groundY = 0,
    bounce = 0,

    -- making projectiles constantly moving to it
    magnetPoint = nil,
    magnetForce = 0,

    -- accept point，距离accept point越近，速度越低，在accept point范围内会有一个速度限制
    acceptPoint = nil,
    acceptSpeedLimit = 0,
    acceptRange = 0,
    acceptCallback = nil,

    res = nil,
	isActive = true,
    isVisible = true,

    crystals = copy( CRYSTALS ),
    shield = 0,

    color = nil,

    ctor = function( self, res, x, y, w, h )
        self.res, self.x, self.y, self.w, self.h = res, x, y, w, h
        table.insert( projectileManager.projectiles, self )
    end,

    killThis = function(self)
        self.isActive = false
        self.isVisible = false
        remove( projectileManager.projectiles, self )
        if self.acceptCallback ~= nil then
            self.acceptCallback( self )
        end
    end,

    update = function(self, delta)
		if self.isActive == false then return end
        local cx, cy = mainCamera:getCameraPos()
        -- move
        self.x = self.x + self.v.x * delta
        self.y = self.y + self.v.y * delta
        -- apply friction
		if self.v.length > 0 then
        	self.v = self.v:__add( self.v.normalized:__mul( self.friction * -1 * delta ) )
		end
        -- apply magnet force
        if self.magnetPoint ~= nil then
            local magnetPoint = self.magnetPoint:__add( Vec2.new( cx, cy ) )
            local force = magnetPoint:__sub( Vec2.new( self.x, self.y ) ).normalized:__mul( self.magnetForce )
            self.v = self.v:__add( force:__mul( delta ) )
        end
        -- ground check
        if self.gravity ~= nil then
            if self.y > self.groundY then
                self.v = self.v:__mul( self.bounce * -1 )
                self.y = self.groundY
            else
                -- apply gravity force
                self.v = self.v:__add( self.gravity:__mul( delta ) )
            end
        end
        -- check accept and apply accept speed restains
        if self.acceptPoint ~= nil then
            local acceptPoint = self.acceptPoint:__add( Vec2.new( cx, cy ) )
            local distance = Vec2.new( self.x, self.y ):__sub( acceptPoint ).length
            if self.acceptSpeedLimit > 0 then
                local speedLimit = self.acceptSpeedLimit * distance
                if speedLimit < 20 then speedLimit = 20 end
                if self.v.length > speedLimit then
                    self.v = self.v.normalized:__mul( speedLimit )
                end
            end
            if DEBUG_ADJUST_PARAMS then
                print( distance, self.acceptRange, self.v.length ) 
            end
            if distance < self.acceptRange then
                self:killThis()
            end
        elseif self.v.length < 10 and math.abs( self.y - self.groundY ) < 3 then 
            -- is active?
            self.isActive = false 
        end
    end,

    render = function(self)
        if self.isVisible == false then return end
        if self.color == nil then
            tex( self.res, self.x, self.y, self.w, self.h, 0, 0, self.angle )
        else
            tex( self.res, self.x, self.y, self.w, self.h, 0, 0, 0, 0, self.angle, Vec2.new(0.5, 0.5), false, false, self.color )
        end
    end,

    setVelocity = function( self, v )
        self.v = v
    end,

    setFriction = function( self, f )
        self.friction = f
    end,

    setCrystal = function( self, crystals )
        self.crystals = merge( self.crystals, copy( crystals ) )
    end,

    setShield = function( self, shield )
        self.shield = shield
    end,

    setGravity = function( self, gravity, groundY, bounce )
        self.gravity = gravity
        self.groundY = groundY
        self.bounce = bounce
    end,

    setColor = function( self, color )
        self.color = color
    end,

    -- always take on screen position, as it needs to target UI position and handles camera
    setMagnet = function( self, point, force )
        self.magnetForce = force
        self.magnetPoint = point
    end,

    -- always take on screen position, as it needs to target UI position and handles camera
    setAccept = function( self, acceptPoint, acceptRange, acceptSpeedLimit, acceptCallback )
        self.acceptPoint, self.acceptRange, self.acceptSpeedLimit, self.acceptCallback = acceptPoint, acceptRange, acceptSpeedLimit, acceptCallback
    end,
})

tex_Crystals = Resources.load('res/collect_crystal3.png')
tex_Shield = Resources.load('res/collect_shield.png')

ParamsSet1 = {-100, 200, 2, 0.3, 16, -8, -16, -16, 16}
Projectile_DropCrystals = function( xx, yy, crystals )
    local adjust = ParamsSet1
	local total = 0
    for k,v in pairs( CRYSTALS ) do
        if crystals[k] ~= nil then
            local count = crystals[k]
            if count > 0 then
                local cs = {}
                cs[k] = 1
                local color = Equipment_GetCrystalColor( cs )
                for i = 1,count do
                    tweenManager:addDelay( 0.1 * total, false, function()
                        local proj = Projectile.new( tex_Crystals, xx + adjust[7], yy + adjust[8], 32, 32 )
                        proj:setVelocity( Vec2.new( math.random( 1, adjust[5] ) - adjust[5]/2, adjust[1] ) )
                        proj:setGravity( Vec2.new( 0, adjust[2] ), yy + adjust[6] + math.random( 1, adjust[9] ) - adjust[9]/2, adjust[4] )
                        proj:setFriction( adjust[3] )
                        proj:setCrystal( cs )
                        proj:setColor( color )
                    end)
					total = total + 1
                end
            end
        end
    end
end

ParamsSet3 = {400, 2, 1, 16, -16, -16}
Projectile_PotCollectCrystals = function( xx, yy, crystals, nearestPot )
    local adjust = ParamsSet3
	local total = 0
    local axx, ayy = mapCfg.mox + 32 * xx + 16, mapCfg.moy + 32 * yy + 1
    for k,v in pairs( CRYSTALS ) do
        if crystals[k] ~= nil then
            local count = crystals[k]
            if count > 0 then
                local cs = {}
                cs[k] = 1
                local color = Equipment_GetCrystalColor( cs )
                for i = 1,count do
                    local px, py = nearestPot:getLogicPos()
                    local nxx, nyy = mainCamera:gridToUIPos( mapCfg.mox + 32 * px + 0, mapCfg.moy + 32 * py + 0 )
                    tweenManager:addDelay( 0.1 * total, false, function()
                        local proj = Projectile.new( tex_Crystals, axx + adjust[5], ayy + adjust[6], 32, 32 )
                        proj:setCrystal( cs )
                        proj:setColor( color )
                        proj:setFriction( adjust[3] )
                        proj:setMagnet( Vec2.new( nxx, nyy ), adjust[1] )
                        proj:setAccept( Vec2.new( nxx, nyy ), adjust[4], adjust[2], function( p )
                            nearestPot.cfg.crystal_collected[k] = nearestPot.cfg.crystal_collected[k] + 1
                        end )
						-- local cx, cy = mainCamera:getCameraPos()
						-- print( '#', '', xx, yy, px, py, axx, ayy, nxx, nyy, mapCfg.mox + 32 * px + 16, mapCfg.moy + 32 * py + 1, cx, cy )
                    end)
					total = total + 1
                end
            end
        end
    end
end

ParamsSet2 = {400, 2, 2, 32, -16, -16}
Projectile_DropShield = function( xx, yy, count, shield )
    local adjust = ParamsSet2
    -- apply effect immidiately
    game.shield.cfg.energy_power = game.shield.cfg.energy_power + count
    if game.shield.cfg.energy_power > game.shield.cfg.energy_power_max then
        game.shield.cfg.energy_power = game.shield.cfg.energy_power_max
    end
    -- animation
    for i = 1,count do
        tweenManager:addDelay( 0.1 * i, false, function()
            local proj = Projectile.new( tex_Shield, xx + adjust[5], yy + adjust[6], 16, 16 )
            proj:setShield( shield )
            proj:setFriction( adjust[3] )
            proj:setMagnet( Vec2.new( 8 + 40 + 16, 16 + 168 ), adjust[1] )
            proj:setAccept( Vec2.new( 8 + 40 + 16, 16 + 168 ), adjust[4], adjust[2], function( p )
                -- game.shield.cfg.energy_power = game.shield.cfg.energy_power + p.shield
                -- if game.shield.cfg.energy_power > game.shield.cfg.energy_power_max then
                --     game.shield.cfg.energy_power = game.shield.cfg.energy_power_max
                -- end
            end )
        end)
    end
end
