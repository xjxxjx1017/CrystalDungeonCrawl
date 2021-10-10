require 'code/class'
require 'code/co'
require 'code/util'

MapTile_WH = 16
totalH = 768
totalW = 1366
tileSize = 32

tileCountNoCamera= 24
margin = 8 
lineHeight = 30
mapPaddingW = 70
mapPaddingH = tileSize * 0
mapOffsetXNoCamera = totalW / 2 - tileSize * tileCountNoCamera / 2
mapOffsetYNoCamera = mapPaddingH
btnWUnit = 80
roomCount = 3

MapCfg = class({
    mapOffsetX = 0,
    background = '',
    -- map position offsets
    mox = 0,
    moy = 0,
    moxNoCamera = mapOffsetXNoCamera,
    moyNoCamera = mapOffsetYNoCamera,
    id = '',

    ctor = function( self )
    end,

    reset = function( self, id, mapTile_WH )
        self.id = id
        MapTile_WH = mapTile_WH
        self.mapOffsetX = totalW / 2 - tileSize * MapTile_WH / 2
        self.mox = mapCfg.mapOffsetX
        self.moy = mapPaddingH
        if MapTile_WH == 24 then
            self.background = 'level/background002.map'
        elseif MapTile_WH == 16 then
            self.background = 'level/background001.map'
        end
    end,
})
mapCfg = MapCfg.new()

--[[
    4x4房间联通打墙，封闭，与等级算法。
    房间的属性有，方向（左右上。不能同时出现两个上。如果是左右，则上为封闭。如果为上，则上为打通。），是否联通（联通算法没有踩到的格子为秘密房间）
    把秘密房间，封闭或打通，加boss，加玩家应用到整个地图。
]]
MapOverlayDefault = {
    id = -1,
    isPassage = false, isSecretRoom = false,
    isLeftThrough = false, isRightThrough = false, isUpThrough = false, isDownThrough = false, isUpBlock = false, isDownBlock = false,
    isBoss = false, isPlayer = false, rfloor = -1, level = -1,
    openPos = {}, closePos = {}
}

Generate_MapOverlay = function()
    --[[
        房间layout的定义
        room = {
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
    local rooms = {}
    for ii = 1,roomCount do    -- x
		local row = {}
    	for jj = 1,roomCount do        -- y
            table.insert( row, merge( MapOverlayDefault, {
                id = (jj-1) * roomCount + ii,
                level = roomCount + 1 - jj,
                rfloor = roomCount + 1 - jj
            } ))
        end
		table.insert( rooms, row )
    end
    -- setup boss and player room
    local stR = Vec2.new( math.random(1,roomCount), roomCount )
    local edR = Vec2.new( -1, 1 )
    local curFloor = roomCount
    local curX = stR.x
    local curDir = 1
    if stR.x == roomCount or math.random() > 0.5 then curDir = -1 end
    if stR.x == 1 then curDir = 1 end
    while curFloor > 0 do
        local curRoom = rooms[curX][curFloor]
        local isDrop = curRoom.isDownThrough == false and math.random() > 0.67 and not( curX == stR.x and curFloor == stR.y )
        local nextRoomP = Vec2.new( curDir + curX, curFloor )
        if nextRoomP.x < 1 or nextRoomP.x > roomCount then isDrop = true end
        if isDrop then
            nextRoomP = Vec2.new( curX, curFloor - 1 )
        end
        if nextRoomP.y == 0 then
            -- function end here. boss is here. 
            edR.x = curX
            rooms[stR.x][stR.y].isPlayer = true
            rooms[edR.x][edR.y].isBoss = true
            curFloor = 0
        else
            local nextRoom = rooms[nextRoomP.x][nextRoomP.y]
            curRoom.isPassage = true
            nextRoom.isPassage = true
            if isDrop then
                curRoom.isUpThrough = true
                nextRoom.isDownThrough = true
                if nextRoomP.x == 1 or nextRoomP.x == roomCount or math.random() > 0.5 then
                    curDir = curDir * -1
                end
            elseif curDir < 0 then
                curRoom.isLeftThrough = true
                nextRoom.isRightThrough = true
                curRoom.isUpBlock = true
                nextRoom.isDownBlock = true
            elseif curDir > 0 then
                curRoom.isLeftThrough = true
                nextRoom.isRightThrough = true
                curRoom.isUpBlock = true
                nextRoom.isDownBlock = true
            end
            curX, curFloor = nextRoomP.x, nextRoomP.y
        end
    end
    for jj = 1,roomCount do        -- y
        -- choose only one room in a level to be a secret room
        local allPossibleSecret = {}
        for ii = 1,roomCount do    -- x
            local r = rooms[ii][jj]
            if r.isPassage == false then 
                table.insert( allPossibleSecret, r )
            end
        end
		if #allPossibleSecret > 0 then
	        allPossibleSecret = shuffle( allPossibleSecret )
	        allPossibleSecret[1].isSecretRoom = true
	        allPossibleSecret[1].level = allPossibleSecret[1].level + 2
		end
    end
    for ii = 1,roomCount do
        local p = ''
        for jj = 1,roomCount do   
			local curR = rooms[jj][ii]
			if curR.isBoss then p = p .. ' B'
			elseif curR.isPlayer then p = p.. ' P'
            elseif curR.isPassage then p = p .. ' .'
            elseif curR.isSecretRoom then p = p .. ' #'
			else p = p .. ' X' end
        end
        print( p )
    end
	return rooms
end

MapModule = class({
    countH = 0,
    countW = 0,
    data = {},
    key = 0,

    ctor = function( self, data, key )
        self.data = data
        self.countW = #data
        self.countH = #data[1]
        self.key = key
    end
})

MapGenerator2 = class({
    weightSum = {},
    levels = {},
    feature_overlay = nil,

    ctor = function( self )
    end,

    reset = function( self )
        self:loadDesigns()
    end,

    -- 加载LDTK产生的地图配置
    -- 生成大小不一的房间模块
    loadDesigns = function( self )
        self.weightSum = {}
        self.levels = {}
        -- 加载地图文件
        local j = loadJson('level_modules/level_module8x8.ldtk')
        local gridSize = j.defaultGridSize
        for k,level in ipairs( j.levels ) do
            -- 只读取地图层级的信息，只是为了生成关卡，以及决定在哪个房间生成什么样的关卡。
            -- 更深层级的信息之后在读入
            local curLevel = {
                name = level.fieldInstances[3].__value,
                weight = level.fieldInstances[6].__value,
                units = level.layerInstances[1].entityInstances,
                tiles = level.layerInstances[2].gridTiles,
                w = level.layerInstances[1].__cWid,
                h = level.layerInstances[1].__cHei,
            }
            -- is player
            local key = ''
            if level.fieldInstances[5].__value then
                if level.fieldInstances[8].__value then
                    key = 'tutorial_player'
                else
                    key = 'player'
                end
            -- is boss
            elseif level.fieldInstances[4].__value then
                key = 'boss'
            -- is secret or passage
            elseif level.fieldInstances[7].__value then
                key = 'test'
            else
                key = '8x8'
            end
            if self.weightSum[key] == nil then self.weightSum[key] = 0 end
            self.weightSum[key] = self.weightSum[key] + curLevel.weight
            if self.levels[key] == nil then self.levels[key] = {} end
            table.insert( self.levels[key], curLevel )
        end
    end,

    generateMap = function( self )
        if mainLoop.stategamemode == 'test' then
            return {
                w = 16,
                h = 16,
                rooms = {{
                    level = selectRandomObjByWeight( self.levels['test'], 'weight' ),
                    rotate = 0,
                    flipX = false,
                    flipY = false,
                    layout = nil,
                    x = 0,
                    y = 0
                }}
            }
        elseif mainLoop.stategamemode == 'gen1' then
            for ii = 1,2 do
                for jj = 1,2 do
                    local curRoom = {
                        level = nil,
                        rotate = 0,
                        flipX = false,
                        flipY = false,
                        layout = nil,
                        x = 0,
                        y = 0
                    }
                    local r = overlay[ii][jj]
                    if r.isBoss then
                        curRoom.level = selectRandomObjByWeight( self.levels['boss'], 'weight' )
                        -- curRoom.rotate = 3
                    elseif r.isPlayer then
                        curRoom.level = selectRandomObjByWeight( self.levels['player'], 'weight' )
                        -- curRoom.rotate = 3
                    else
                        curRoom.level = selectRandomObjByWeight( self.levels['8x8'], 'weight' )
                        curRoom.rotate = math.random(0,3)
                        curRoom.flipX = math.random(0,1) > 0.5
                        curRoom.flipY = math.random(0,1) > 0.5 
                    end
                    curRoom.layout = r
                    curRoom.x = (ii-1) * 8
                    curRoom.y = (jj-1) * 8
                    table.insert( allRooms, curRoom )
                end
            end
            return {
                w = 16,
                h = 16,
                rooms = allRooms
            }
        elseif mainLoop.stategamemode == 'gen2' then
            -- 给每个房间生成一个模块，记录模块的位置，以及旋转、XY反转状况
            -- 生成整个地图世界base的room layout，哪里是passage，哪里是secret room，哪里是boss room
            -- 所有的地块都叠加在一起
            local overlay = Generate_MapOverlay()
            local allRooms = {}
            for ii = 1,roomCount do
                for jj = 1,roomCount do
                    local curRoom = {
                        level = nil,
                        rotate = 0,
                        flipX = false,
                        flipY = false,
                        layout = nil,
                        x = 0,
                        y = 0,
                    }
                    local r = overlay[ii][jj]
                    if r.isBoss then
                        curRoom.level = selectRandomObjByWeight( self.levels['boss'], 'weight' )
                    elseif r.isPlayer then
                        if profileManager.cfg.profile.round > 1 and not profileManager.cfg.profile.playedTutorial then
                            curRoom.level = selectRandomObjByWeight( self.levels['tutorial_player'], 'weight' )
                            profileManager.cfg.profile.playedTutorial = true
                        else
                            curRoom.level = selectRandomObjByWeight( self.levels['player'], 'weight' )
                        end
                    else
                        curRoom.level = selectRandomObjByWeight( self.levels['8x8'], 'weight' )
                        curRoom.rotate = math.random(0,3)
                        curRoom.flipX = math.random(0,1) > 0.5
                        curRoom.flipY = math.random(0,1) > 0.5 
                    end
                    curRoom.layout = r
                    curRoom.x = (ii-1) * 8
                    curRoom.y = (jj-1) * 8
                    table.insert( allRooms, curRoom )
                end
            end
            return {
                w = 32,
                h = 32,
                rooms = allRooms
            }
        end
    end
})
mapGenerator2 = MapGenerator2.new({})