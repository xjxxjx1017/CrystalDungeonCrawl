require 'code/class'
require 'code/co'
require 'code/util'
require 'code/keycode'
require 'code/tweenmanager'
require 'units/player'
require 'units/unit_factory'
require 'units/unit_master'
require 'units/effect'
require 'equipments/equipment_def'
require 'equipments/equipment'

Game = class({
    curUnitList = {},
    curEffectList = {},
    curStaticUnitList = {},
    curLightSourceList = {},
    curCrystalCollectorList = {},
    
    coreLoop = nil,
    yard = nil,
    yardOriginal = nil,
    yard_ai = nil,
    player = nil,
	goal = nil,

    hint = nil,
    whitestar = nil,
    blind = nil,

    disableRange = 7,
    invisibleRange = 16,

    turn = 1,

    board = {},

    currency = copy( CRYSTALS ),
    weapon = Equipment.new( EQUIPMENT_DEFAULT ),
    shield = Equipment.new( EQUIPMENT_DEFAULT ),
    badge = nil,
    craftedEquipments = {},

    history = copy( Profile_HistoryDefault ),

    uiDirty = false,
    gamemode = 'test', -- 'test', 'gen1', 'gen2'
    lastgamemode = nil,
    gameFinished = false,

    ctor = function( self )
    end,

    lose = function (self, killedBy)
        if self.gameFinished then return end
        self.gameFinished = true
        
        -- save a failed game
        self.history.isWin = false
        self.history.killedBy = killedBy
        self.history.dateTimeTo = DateTime.ticks()
        profileManager.cfg.profile.crystals = copy( game.currency )
        profileManager:addNewHistory( copy( self.history ) )
        profileManager:saveAll()

        mainLoop:changeState( 'modehistory' )
    end,

    win = function(self)
        if self.gameFinished then return end
        self.gameFinished = true
        
        -- save a succesfful play through
        self.history.isWin = true
        self.history.dateTimeTo = DateTime.ticks()
        profileManager.cfg.profile.crystals = copy( game.currency )
        profileManager:addNewHistory( copy( self.history ) )
        profileManager:saveAll()
        
        mainLoop:changeState( 'modehistory' )
    end,

    loadStage = function(self)
        local map = mapGenerator2:generateMap( true )

        -- re-initialize the game board
        self.board = init2dArray( map.w, map.h )

        self:generateUnitByMapData( map )
        self:sortByLevel()
		if self.player ~= nil then
        	self.player:changeState()
		end
    end,

    sortByLevel = function(self)
        local sortByLayer = function(a, b)
            return a.cfg.layer < b.cfg.layer
        end
        print( '--------------------- before sort ---------------------' )
        if DEBUG_RENDER_ORDER then for k,v in ipairs( self.curUnitList ) do v:info( '#render#' ) end end
        self.curUnitList = sort( self.curUnitList, sortByLayer )
        print( '--------------------- after sort ---------------------' )
        if DEBUG_RENDER_ORDER then for k,v in ipairs( self.curUnitList ) do v:info( '#render#' ) end end
    end,

    generateUnitByMapData = function( self, map )
        --[[ 当前map的定义
        map = {
            w = 16,
            h = 16,
            rooms = {
                {
                    level = nil,        -- 见下面level的定义
                    rotate = 0,
                    flipX = false,
                    flipY = false,
                    layout = nil,       -- 可能为nil
                    x = 0,
                    y = 0
                }
            }
        }
        房间level的定义
        level = {
            name = nil,
            weight = 0,
            units = { {RAW} },
            tiles = { {RAW} },
            w = 0,
            h = 0,
        }
        房间layout的定义
        layout = {
            id = 0,
            level = 1 ~ 9,
            rfloor = 1 ~ 4,
            isDownThrough = false,
            isUpThrough = false,
            isLeftThrough = false,
            isRightThrough = false,
            isUpBlock = false,
            isDownBlock = false,
            isPassage = false,
            isSecretRoom = false,
            isPlayer = false,
            isBoss = false,
        }
        ]]

        local tileSize = 16
        local createConfigDefault = { id = -1, x = -1, y = -1, count = 1, level = 1, unitDef = nil, sealId = -1, special = false }
        local expectedLevelList = {1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,2,2,2,2,2,2,2,2,3,3,3,3,4,4,5}
        
        local gridLayerUnits = init2dArray( map.w, map.h )
        local gridLayerTiles = init2dArray( map.w, map.h )

        --[[
        基本的配置文件结构，用于传递给Unit_Factory跟·UnitMaster，从而制造单位
        createConfig = {
            name = nil,     -- units are only represented by names
            id = -1,        -- tiles are only represented by ids
            x = 0,
            y = 0,
            cfg = {},
            level = 0,
        }
        ]]

        -- 遍历所有的room，应用rotate和flip，assign给每个格子上的tiles和units图层
        local applyRoomCfgToCreateCfg = function( createCfg, v )
            -- 然后应用flip，rotate等要素
            if v.flipX then createCfg.y = v.level.h - 1 - createCfg.y end
            if v.flipY then createCfg.x = v.level.w - 1 - createCfg.x end
            for iii = 1,v.rotate do 
                createCfg.x, createCfg.y = v.level.w - 1 - createCfg.y, createCfg.x 
            end
        end
        -- 这个运算会有机会对现有的单位和背景Tile做覆盖操作，从而实现更复杂的地图配置
        for k,v in ipairs(map.rooms) do
            local layout = v.layout
            local noneBlockingTiles = {}
            for kk,tile in ipairs( v.level.tiles ) do
                local createCfg = {
                    id = tile.t,
                    name = nil,
                    x = tile.px[1] / tileSize,
                    y = tile.px[2] / tileSize,
                    cfg = {},
                    level = 1
                }
                applyRoomCfgToCreateCfg( createCfg, v )
                local tileDef = UnitFactory_DefByIdMap[ createCfg.id ]
				if tileDef.cfg == nil then print( 'Unit def not found', '', 'id'..createCfg.id ) end
                if tileDef.cfg.blocking == false or tileDef.cfg.blocking == nil then
                    -- 如果tile是可通过的则储存，以备之后计算
                    table.insert( noneBlockingTiles, { x = createCfg.x, y = createCfg.y } )
                    -- 地图通路逻辑，只是遮挡2个tile，没有移出遮挡
                    -- 如果地图出入口match，则不覆盖地图出入口
                    if layout ~= nil and layout.isUpBlock and (( createCfg.x == 4 and createCfg.y == 0 ) or ( createCfg.x == 3 and createCfg.y == 0 ) ) then
                        createCfg.name = 'MOUNTAIN'
                    elseif layout ~= nil and layout.isDownBlock and (( createCfg.x == 4 and createCfg.y == 7 ) or ( createCfg.x == 3 and createCfg.y == 7 ) ) then
                        createCfg.name = 'MOUNTAIN' 
                    end
                end
                -- 最后存入gridLayer
                gridLayerTiles[ createCfg.x + 1 + v.x ][ createCfg.y + 1 + v.y ] = createCfg

            end
            for kk,entity in ipairs( v.level.units ) do
                -- 先根据单个模块的配置，设好最初的属性
                local createCfg = {
                    id = -1,
                    name = entity.__identifier,
                    x = entity.__grid[1],
                    y = entity.__grid[2],
                    cfg = {},
                    level = 0,
                }
                for kkk,field in ipairs( entity.fieldInstances ) do
                    if field.__type == "Point" then
                        createCfg.cfg[field.__identifier] = { x = field.__value.cx, y = field.__value.cy }
                    end
                end
                if layout ~= nil then createCfg.level = layout.level end
                applyRoomCfgToCreateCfg( createCfg, v )
                -- 在空余tile列表中移出当前tile
                noneBlockingTiles = filter( noneBlockingTiles, function(t) return t.x ~= createCfg.x or t.y ~= createCfg.y end )
                -- 最后存入gridLayer
                gridLayerUnits[ createCfg.x + 1 + v.x ][ createCfg.y + 1 + v.y ] = createCfg
            end
            noneBlockingTiles = shuffle( noneBlockingTiles )
            local addUnitInThisRoom = function( name )
                if #noneBlockingTiles > 0 then
                    local x = noneBlockingTiles[1].x
                    local y = noneBlockingTiles[1].y
                    -- 在空余tile处加一个罐子
                    local createCfg = {
                        id = -1,
                        name = name,
                        x = x,
                        y = y,
                        cfg = {},
                        level = 1
                    }
                    if layout ~= nil then createCfg.level = layout.level end
                    -- 在空余tile列表中移出当前tile
                    noneBlockingTiles = filter( noneBlockingTiles, function(t) return t.x ~= createCfg.x or t.y ~= createCfg.y end )
                    -- 存入gridLayer
                    gridLayerTiles[ createCfg.x + 1 + v.x ][ createCfg.y + 1 + v.y ] = createCfg
                end
            end
            -- 如果是secret的房间，则在可以移动的tile上放上壶
            if layout ~= nil and layout.isSecretRoom then
                addUnitInThisRoom( 'SMOKING_POT1' )
            end
            -- 任意房间都会被放上一个蓝色的回复道具 (BLUE_COIN)
            if layout ~= nil and layout.isPlayer == false then
                addUnitInThisRoom( 'BLUE_COIN' )
            end
        end

        -- 如果是SEAL，则直接用随机单位名字直接替换SEAL的名字
        local SealList = {}
        SealList['SEAL_STRONG'] = { 'ROCK_MAN' }
        SealList['SEAL_ORE'] = { 'CRYSTAL_ORE' }
        SealList['SEAL_GANG'] = { 'WOLF_GANG', 'DOG_GANG' }
        SealList['SEAL_TRAP'] = { 'DIG_MOUSE', 'SHY_GRASS', 'SHADOW' }
        SealList['SEAL_NORMAL'] = { 'FISH', 'SHEEP', 'CABAGE', 'BAT', 'SLIME' }
        SealList['SEAL_PICKUP'] = { 'CRYSTAL1', 'CRYSTAL2', 'CRYSTAL3', 'CRYSTAL5' }
        SealList['SEAL_BOSS'] = { 'SLIMEKING' }
		local createUnitByNameOrId = function( tCfg, x, y )
            --[[
            基本的配置文件结构，用于传递给Unit_Factory跟·UnitMaster，从而制造单位
            createConfig = {
                name = nil,     -- units are only represented by names
                id = -1,        -- tiles are only represented by ids
                x = 0,
                y = 0,
                cfg = {},
                level = 0,
            }
            ]]
			if tCfg == nil or tCfg.id == nil then return end
            if SealList[tCfg.name] ~= nil then tCfg.name = SealList[tCfg.name][ math.random( 1,#SealList[tCfg.name] ) ] end
            local id = tCfg.id
            if tCfg.name ~= nil then 
				if UnitDef[tCfg.name] == nil then warn( 'Unit name not found:', '', 'name'..tCfg.name ) end
				id = UnitDef[tCfg.name].id 
			end
            -- 附加等级直接从等级表里随机选取
            -- UnitFactory_CreateUnit( id, x, y, true, 1, tCfg.level + expectedLevelList[math.random(1,#expectedLevelList)] - 1, nil )
            UnitFactory_CreateUnit( id, x, y, true, 1, tCfg.level, nil )
		end
        for i = 1, map.w do
            for j = 1, map.h do
                -- 单位则直接是单位
                local tCfg = gridLayerTiles[i][j]
                createUnitByNameOrId( tCfg, i-1, j-1 )
                local tCfg = gridLayerUnits[i][j]
                createUnitByNameOrId( tCfg, i-1, j-1 )
            end
        end
    end,

    clear = function( self )
        self.curUnitList = {}
        self.curEffectList = {}
        self.curStaticUnitList = {}
        self.curLightSourceList = {}
        self.curCrystalCollectorList = {}
        self.board = {}
        self.badge = nil
        self.gameFinished = false
    end,

    setup = function ( self )
        self.hint = Resources.load('spr/star.spr')
        self.hint:play('idle', false, true, true)
        self.whitestar = Resources.load('spr/whitestar.spr')
        self.whitestar:play('idle', false, true, true)
        self.blind = Resources.load('spr/blind.spr')
        self.blind:play('idle', false, true, true)
        -- initialize profiles
        game.currency = copy( profileManager.cfg.profile.crystals )
        -- initialize equipments
        game:upgradeEquipment( FindEquipmentById('剑1'), true )
        game:upgradeEquipment( FindEquipmentById('护盾1'), true  )
    end,

    reset = function( self )
        -- reset equipments
        self.craftedEquipments = {}
        game:upgradeEquipment( FindEquipmentById(self.weapon.cfg.baseweapon), true )
        game:upgradeEquipment( FindEquipmentById('护盾1'), true  )
        self.weapon.cfg.energy = self.weapon.cfg.energy_max
        -- clear the existing stage
        self:clear()
        -- setup profile and history
        profileManager.cfg.profile.round = profileManager.cfg.profile.round + 1
        profileManager.cfg.profile.crystals = copy( game.currency )
        profileManager:saveAll()
        self.history = merge( copy( Profile_HistoryDefault ), {
            dateCreated = profileManager.cfg.profile.dateCreated,
            dateTimeFrom = DateTime.ticks(), 
            dateTimeTo = nil, 
            round = profileManager.cfg.profile.round,
            killedBy = nil, 
            crystal_gain = copy( CRYSTALS ), 
            steps = 0, 
            monster_kill = {}, 
            equipments = {}, 
            mode = gamemode
        } )
        -- load a new stage
        self:loadStage()
    end,

    gameLoop = function(self, delta)
        -- update unit animations and check whether all their turn has finished
        local turnFinished = true
        local hasNextAction = false
		if self.player ~= nil then
	        self.player:update( delta )
	        turnFinished = turnFinished and self.player:getTurnFinished()
		end
        for k, v in ipairs(self.curUnitList) do
            local xx, yy = v:getLogicPos()
            if self:isPlayerInRange( xx, yy, self.disableRange ) then
                v:update( delta )
                turnFinished = turnFinished and v:getTurnFinished()
            end
        end
        if not( turnFinished ) or not( tweenManager:getAllFinished() ) then
            -- if one of the unit hasn't finished, then let them let them keep going
        else
			if self.player ~= nil then
	            -- otherwise, try start a player action first
	            hasNextAction = self.player:nextAction()
	            if not ( hasNextAction ) then
	                -- if the player has no action to perform, then all other units will stand by wait for the player
	            else
                    if DEBUG_RENDER_ORDER then for k,v in ipairs( game.curUnitList ) do v:info( '#render#' ) end end
                    print( '--------------------- turn ' .. self.turn .. ' ---------------------' )
                    self.turn = self.turn + 1
	                -- otherwise, if the player moved, all other units will try to act, if they have any intent to do so
	                for k,v in ipairs( self.curUnitList ) do
	                    if v.nextAction ~= nil then
                            local xx, yy = v:getLogicPos()
                            if self:isPlayerInRange( xx, yy, self.disableRange ) then
                                v:nextAction()
                            end
	                    end
	                end
	            end
			end
        end
    end,

    update = function (self, delta)

        if DEBUG_KEYS then
            --[[
                R： 重新生成本关卡
                I：上一关卡
                O：下一关卡
                E： 装备至该关卡标准
            ]]
            if keyp(KeyCode.A) then
                local xx, yy = mouse(1)
                print( '', '', xx, yy )
            end
            if keyp(KeyCode.R) then
                print('', '重新生成地图，等级'..self.currentMapIndex)
                self:reset()
            end
            if keyp(KeyCode.O) then
                self.currentMapIndex = self.currentMapIndex + 1
                if self.currentMapIndex > #Chapters then
                    self.currentMapIndex = #Chapters
                end
                print('', '切换地图等级，等级'..self.currentMapIndex)
            end
            if keyp(KeyCode.I) then
                self.currentMapIndex = self.currentMapIndex - 1
                if self.currentMapIndex < 1 then
                    self.currentMapIndex = 1
                end
                print('', '切换地图等级，等级'..self.currentMapIndex)
            end
            if keyp(KeyCode.E) then
                game:upgradeEquipment( FindEquipmentById('护盾10'), true  )
                game:upgradeEquipment( FindEquipmentById('弓箭10'), true  )
                --[[
                    local weapon, shield = Analysis_Level_Equipments( self.currentMapIndex )
                    self:upgradeEquipment( FindEquipmentById(weapon), true )
                    self:upgradeEquipment( FindEquipmentById(shield), true )
                    game.player:changeState()
                    print('', '切换玩家装备到预期，等级'..self.currentMapIndex)
                ]]
            end
            if keyp(KeyCode.D) then
                -- firing a dropping crystal
                local xx, yy = mouse(1)
                Projectile_DropCrystals( xx, yy, { crystal1 = 10 } )
            end
            if keyp(KeyCode.P) then
                ui:openPopup( 'popuptest', {'popuptest', 'popuptest', 'popuptest'}, 'test', function() print('popup onConfirm') end )
            end
            if keyp(KeyCode.Num1) then
                -- firing a dropping crystal
                local xx, yy = mouse(1)
                Projectile_DropCrystals( xx, yy, { crystal1 = 10 } )
            end
            if keyp(KeyCode.Num2) then
                -- firing a dropping crystal
                local xx, yy = mouse(1)
                Projectile_DropCrystals( xx, yy, { crystal2 = 10 } )
            end
            if keyp(KeyCode.Num3) then
                -- firing a dropping crystal
                local xx, yy = mouse(1)
                Projectile_DropCrystals( xx, yy, { crystal3 = 10 } )
            end
            if keyp(KeyCode.Num4) then
                -- firing a dropping crystal
                local xx, yy = mouse(1)
                Projectile_DropCrystals( xx, yy, { crystal4 = 10 } )
            end
            if keyp(KeyCode.S) and key(KeyCode.LCtrl) then
                profileManager:saveAll()
            elseif keyp(KeyCode.S) then
                game.weapon.cfg.sight = game.weapon.cfg.sight + 10
            end
            if keyp(KeyCode.L) and key(KeyCode.LCtrl) then
                profileManager:loadAll()
            end
            if keyp(KeyCode.K) then
                game:lose('console')
            end
            local cameraSpeed = 250
            if key(KeyCode.G) then
                mainCamera:moveCameraPos( 0, 1 * delta * cameraSpeed )
            end
            if key(KeyCode.T) then
                mainCamera:moveCameraPos( 0, -1 * delta * cameraSpeed )
            end
            if key(KeyCode.H) then
                mainCamera:moveCameraPos( 1 * delta * cameraSpeed, 0 )
            end
            if key(KeyCode.F) then
                mainCamera:moveCameraPos( -1 * delta * cameraSpeed, 0 )
            end
            if keyp(KeyCode.M) then
                self.currency.crystal1 = self.currency.crystal1 + 50
                self.currency.crystal2 = self.currency.crystal2 + 30
                self.currency.crystal3 = self.currency.crystal3 + 20
                self.currency.crystal4 = self.currency.crystal4 + 10
                self.currency.crystal_white = self.currency.crystal_white + 10
                game.player:changeState()
            end
        end

        tweenManager:update(delta)

        self:gameLoop(delta)

        local newlySeenGrid = {}
        

        local doRenderLogic = function( list, isUpdate )
            for k, v in ipairs(list) do
                local vx, vy = v:getLogicPos()
                if self:isInCamera( v ) then
                    if self.player ~= nil then
                        if isUpdate then
                            v:update(delta)
                        end
                        if self.player:isInSight( vx, vy ) then
                            local id = ''..vx..' '..vy
                            if v.cfg.seen == false and not exists( newlySeenGrid, id ) and v.cfg.is_terrain then
                                table.insert( newlySeenGrid, id )
                            end
                            v.cfg.seen = true
                            v:render( delta )
                        elseif v.cfg.is_terrain and v.cfg.seen then
                            v:render( delta )
                            spr( self.blind, vx * 32 + mapCfg.mox, vy * 32 + mapCfg.moy, 32, 32)
                        elseif v.cfg.is_terrain then
                            spr( self.whitestar, vx * 32 + mapCfg.mox, vy * 32 + mapCfg.moy, 32, 32)
                        end
                    else 
                        if isUpdate then
                            v:update(delta)
                        end
                        v:render(delta)
                    end
                end
            end
        end

        -- render logic
        doRenderLogic( self.curStaticUnitList, false )
        doRenderLogic( self.curUnitList, true )

		if self.player ~= nil then
        	self.player:render( delta )
            local px, py = self.player:getRenderPos()
            self.weapon:render( px, py, 32 * 0.5, 32 * 0, 0.5, math.pi * 0)
		end

        if game.shield.cfg.energy_power < game.shield.cfg.energy_power_max then
            for k, v in ipairs( newlySeenGrid ) do
                local pos = mysplit( v )
                local posX, posY = mapCfg.mox + 32 * pos[1] + math.random(0, 16), mapCfg.moy + 32 * pos[2] + math.random(0, 16)
                local amount = math.ceil( game.shield.cfg.energy_power_max / 10 )
                Projectile_DropShield( posX, posY, 1, amount )
            end
        end

        tweenManager:render()

        for k, v in ipairs(self.curEffectList) do
            v:render( delta )
        end

        if self.uiDirty then
            mainLoop:updateCraftPanel(false)
            self.uiDirty = false
        end
    end,

    upgradeEquipment = function ( self, equipDef, isFree )
        print('打造 ' .. equipDef.desc) 
        isFree = isFree == true or false
        local n = Equipment.new( equipDef )
        local lastEquipment = ''
        if isFree == false then
            if not( Equipment_canAfford( n.cfg ) ) then return end
            Equipment_cost( equipDef )
        end
        self:unlockEquipment( n.cfg.id )
        if equipDef.etype == 'weapon' then
            self.weapon:info( 'upgradeEquipment:Old' )
            local used = self.weapon.cfg.energy_max - self.weapon.cfg.energy
            self.weapon = n
            self.weapon.cfg.energy = self.weapon.cfg.energy_max - used
			-- below code can fix ui problem and create game hacks
			-- if self.weapon.cfg.energy < 0 then self.weapon.cfg.energy = 0 end
            self.weapon:info( 'upgradeEquipment:NewAdjusted' )
        elseif equipDef.etype == 'shield' then
            self.shield:info( 'upgradeEquipment:Old' )
            local used = self.shield.cfg.energy_power_max - self.shield.cfg.energy_power
            self.shield = n
            self.shield.cfg.energy_power = self.shield.cfg.energy_power_max - used
            self.shield:info( 'upgradeEquipment:NewAdjusted' )
        elseif equipDef.etype == 'badge' then
            local used = 0
            if self.badge ~= nil then 
            	self.badge:info( 'upgradeEquipment:Old' )
				used = self.badge.cfg.energy_max - self.badge.cfg.energy 
			end
            self.badge = n
            self.badge.cfg.energy = self.badge.cfg.energy_max - used
            self.badge:info( 'upgradeEquipment:NewAdjusted' )
        end
    end,

    unlockEquipment = function( self, id )
        if not exists( self.craftedEquipments, id ) then
            table.insert( self.craftedEquipments, id )
        end
    end,

    filterEquipmentByCrafted = function( self )
        return FilterEquipmentByCrafted( self.craftedEquipments )
    end,

    searchAdjustMap = function ( self, m, id, x, y )
        local r = {}
        for i = 1, 8 do
            local xx = x + adjust8X[i]
            local yy = y + adjust8Y[i]
            local vv = mget(m, xx, yy)
            if id == vv then
                table.insert( r, { x = xx, y = yy } )
            end
        end
        return r
    end,

    getEmptySpaceInRange = function ( self, x, y, rangemin, rangemax )
        local result = {}
        for i = -rangemax,rangemax do
            for j = -rangemax,rangemax do
                if (x+i)*(x+i) + (y+j)*(y+j) <= rangemin * rangemin then
				else 
	                if self:getBlocked( x + i, y + j ) == nil and self:isPlayer( x + i, y + j ) == false then
	                    table.insert( result, {x = x+i, y = y+j } )
	                end
				end
            end
        end
        return result
    end,
        
    getBlocked = function ( self, x, y )
        for k, v in ipairs(game:getBoard(x, y)) do
            if v.isShow == true and v.cfg.blocking == true then
                return v
            end
        end
        return nil
    end,

    getFirstBlocked = function( self, x, y, lst )
        for kk,vv in ipairs( lst ) do
            local blockedBy = self:getBlocked( x + vv.x, y + vv.y )
            if blockedBy ~= nil then 
				return blockedBy, vv.x, vv.y
			end
        end
        return nil, x, y
    end,

    convertPosToFacingDirection = function( self, facingDirection, posInUpDirection )
        local upDir = { x = 0, y = 1 }
        if facingDirection.x == 1 and facingDirection.y == 0 then
            return { x = posInUpDirection.y, y = -posInUpDirection.x }
		end
        if facingDirection.x == 0 and facingDirection.y == -1 then
            return { x = -posInUpDirection.x, y = -posInUpDirection.y }
		end
        if facingDirection.x == -1 and facingDirection.y == 0 then
            return { x = -posInUpDirection.y, y = posInUpDirection.x }
		end
        if facingDirection.x == 0 and facingDirection.y == 1 then
            return { x = posInUpDirection.x, y = posInUpDirection.y }
		end
        return { x = 0, y = 0 }
    end,

    searchPlayer = function ( self, lst, x, y )
        local a = filter( lst, function(l) return self:isPlayer( l.x + x, l.y + y ) end )
        if #a > 0 then 
            return a[1] 
        else 
            return nil 
        end
    end,

    getUnitAtPos = function( self, x, y )
        return self:getBoard(x, y)
    end,

    getUnitsInRange = function(self, x, y, range )
        local rlt = {}
        for i = x - range, x + range do
            for j= y - range, y + range do
                for k, v in ipairs(game:getBoard(i, j)) do
                    local vx, vy = v:getLogicPos()
                    if (vx-x)*(vx-x)+(vy-y)*(vy-y) <= range * range then
                        table.insert( rlt, v )
                    end
                end
            end
        end
        return rlt
    end,

    isPlayerInRange = function(self, x, y, range )
        local vx, vy = self.player:getLogicPos()
        return (vx-x)*(vx-x)+(vy-y)*(vy-y) <= range * range
    end,

    isInCamera = function(self, v)
        local rx, ry = v:getRealPos()
        local cx, cy = mainCamera:getCameraPos()
        return rx >= cx - 32 and rx <= cx + 960 + 32 and ry >= cy - 32 and ry <= cy + 640 + 32
    end,
    
    isPlayer = function ( self, x, y )
        local px, py = self.player:getLogicPos()
        return px == x and py == y
    end,
        
    removeUnit = function ( self, vv )
        if vv.cfg.is_static then
            remove( self.curStaticUnitList, vv )
        else
            remove( self.curUnitList, vv )
        end
        if vv.cfg.light_range > 0 then
            remove( self.curLightSourceList, vv )
        end
        if vv.cfg.crystal_collector then
            remove( self.curCrystalCollectorList, vv )
        end
        self:removeFromBoardByXY( vv )
    end,

    addUnit = function( self, u )
        if u.cfg.is_static then
            table.insert( self.curStaticUnitList, u )
        else
            table.insert( self.curUnitList, u )
        end
        if u.cfg.light_range > 0 then
            table.insert( self.curLightSourceList, u )
        end
        if u.cfg.crystal_collector then
            table.insert( self.curCrystalCollectorList, u )
        end
		if u.cfg.is_boss == false then
	        self:addToBoardByXY(u)
		end
    end,

    findNearestPot = function( self, x, y )
        local minLength = 9999999
        local minUnit = nil
        for k,v in ipairs( self.curCrystalCollectorList ) do
            local xx, yy = v:getLogicPos()
            local l = (x-xx)*(x-xx) + (y-yy)*(y-yy)
            if minLength > l then
                minLength = l
                minUnit = v
            end
        end
        return minUnit
    end,

    removeFromBoardByXY = function( self, u )
        local x,y = u:getLogicPos()
        if x < 0 or x > MapTile_WH or y < 0 or y > MapTile_WH then error( 'board position not found '..'x'..x..' y'..y..' ' .. Debug.trace() ) end
        remove( self:getBoard(x, y), u )
    end,

    addToBoardByXY = function( self, u )
        local x,y = u:getLogicPos()
        if x < 0 or x > MapTile_WH or y < 0 or y > MapTile_WH then error( 'board position not found '..'x'..x..' y'..y..' ' .. Debug.trace() ) end
        table.insert( self:getBoard(x, y), u )
    end,

    existsOnBoardByXY = function( self, u )
        if self.board == nil or #self.board == 0 then return false end
        local x,y = u:getLogicPos()
        return exists( self:getBoard(x, y), u )
    end,

    getBoard = function( self, x, y )
        local xx, yy = x+1, y+1
        if xx < 1 or xx > MapTile_WH or yy < 1 or yy > MapTile_WH then 
			return {} 
		end
		if self.board == nil or self.board[xx] == nil or self.board[xx][yy] == nil then
            return self:getBoard( math.floor( x ), math.floor( y ) )
		end
        return self.board[xx][yy]
    end,

    getBoardTileFamily = function( self, x, y )
        local grid = self:getBoard( x, y )
        if grid ~= nil then
            for k,v in ipairs( grid ) do
                if v.cfg.tile_family ~= nil then
                    return v.cfg.tile_family
                end
            end
        end
        return nil
    end,

    canCreateUnit = function( self, x, y )
        local isEmpty = true
        local px, py = -1, -1
        if game.player ~= nil then px, py = game.player:getLogicPos() end
        for kk,vv in ipairs( game:getBoard(x, y) ) do
            if vv.cfg.blocking == true or vv.cfg.is_tile == false or ( x == px and y == py ) then isEmpty = false end
        end
        return isEmpty
    end,
    
    chargeWeapon = function (self)
        local dx = self.weapon.cfg.energy_max - self.weapon.cfg.energy
        local primary = Crystals_getPrimary( self.weapon.cfg.recharge_cost )
        
        if self.currency[primary] < dx then
            dx = self.currency[primary]
        end
        self.weapon.cfg.energy = self.weapon.cfg.energy + dx
        self.currency[primary] = self.currency[primary] - dx
        self.player:changeState()
    end,
    
    createEffect = function ( self, img, state, x, y, dx, dy, wM, hM, callback )
        local e = nil
        local removeEffect = function ()
            table.remove( self.curEffectList, tablefind( self.curEffectList, e ) )
            if callback ~= nil then
                callback()
            end
        end
        e = EffectAtt.new( img, state, x, y, dx, dy, wM, hM, removeEffect )
        table.insert( self.curEffectList, e )
    end,

    curAtt = function (self, blocker)
        local att_total = -1
        if blocker.cfg.is_terrain then
            att_total = self.weapon.cfg.att_terrain
        elseif self.weapon.cfg.energy > 0 then
            att_total = self.weapon.cfg.att
        else
            att_total = self.weapon.cfg.att
        end
        return att_total
    end,
})

game = Game.new()