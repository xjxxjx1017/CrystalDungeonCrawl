require 'code/class'
require 'libs/beGUI/beGUI'
require 'libs/beGUI/customizedTheme'
require 'code/util'
require 'code/keycode'
require 'map_generator'
require 'profile'

COLOR_TINT = Color.new( 0, 172, 186)
COLOR_TINT_50 = Color.new( 0, 172, 186, 128)
COLOR_DARK_BLUE = Color.new( 5, 26, 36)
COLOR_RED = Color.new( 255, 15, 0)
COLOR_ORANGE = Color.new( 243, 129, 4)
COLOR_ORANGE_50 = Color.new( 243, 129, 4, 128)
COLOR_PURPLE = Color.new( 148, 157, 224)
COLOR_WHITE = Color.new( 255, 255, 255)
COLOR_GREY = Color.new( 40, 40, 40)
COLOR_YELLOW_TRANS = Color.new( 255, 255, 0, 160 )

local texUI_backdrop_sample = Resources.load('res/UI_backdrop_sample.png')
local texUI_bank7_ui = Resources.load('res/bank7_ui.png')
local texUI_bank7 = Resources.load('res/bank7.png')
local texUI_tile_ui = Resources.load('res/tile_ui.png')
local texUI_numbers = Resources.load('res/numbers.png')
local texUI_crystal_coin = Resources.load('res/crystal_coin.png')

P = beGUI.percent -- Alias of percent.

-- adjust = {150, 200, 200, 50, 0, 0, 50, -25 }

UI_DebugConsole = class({
    widget = nil,
    container = nil,

    ctor = function(self)
    end,

    setup = function(self, container)
        self.container = container
        if DEBUG_ADJUST_PARAMS then
            for i = 1,#adjust do
                local xx = math.floor( i / 10 )
                local yy = i % 10
                container:addChild(
                    beGUI.InputBox.new('', 'Adjust'..i..": "..adjust[i])
                        :put(margin + 7 * 32 + ( 7 * 32 ) * xx, lineHeight * ( 0 + yy ) + margin * ( 0 + yy ) )          -- X: 0, Y: 0.
                        :resize(P(20), lineHeight) -- W: 100%, H: 23.
                        :on('changed', function (sender, value)
                            adjust[i] = value
                            print('adjust value '..i.. ': '.. value)
                        end)
                )
            end
        end
        if DEBUG_CONSOLE then
            self.widget = container:addChild( beGUI.InputBox.new('', 'console')
                :setId('debug_console')
                :put(margin + 7 * 32, lineHeight * ( 2 + 0 ) + margin * ( 3 + 1 ) )          -- X: 0, Y: 0.
                :resize(P(20), lineHeight) -- W: 100%, H: 23.
                :on('changed', function (sender, value)
                    print('adjust value '.. value)
                    local args = mysplit( value )
                    if args[1] == 'kill' and #args >= 3 then
                        for k,v in ipairs( game:getBoard( args[2], args[3] ) ) do
                            if v.cfg.can_player_attack then v:killThis( game.player ) end
                        end
                    end
                end))
        end
    end,
})

UI_Pool = class({
    pool = {},

	ctor = function(self)
	end,
	
    getRes = function( self, res, playSprFrame )
        if self.pool[res] == nil then
            self.pool[res] = Resources.load( res )
            if playSprFrame ~= nil and self.pool[res] ~= nil then
                self.pool[res]:play( playSprFrame, false, true, true )
            end
        end
        return self.pool[res]
    end,
})
ui_pool = UI_Pool.new()


UI_ShowNumber = function( sprX, sprY, n, zoom, color )
    if color == nil then
        color = Color.new(255, 255, 255)
    end
	if n == nil then return end
    if type(obj) == 'table' then Debug.trace() end
    if n > 100 then
        tex( texUI_numbers, sprX - 5 * zoom, sprY, 5 * zoom, 7 * zoom, math.floor( n / 100 ) * 5, 0, 5, 7, 0, Vec2.new(0.5, 0.5), false, false, color )
        tex( texUI_numbers, sprX, sprY, 5 * zoom, 7 * zoom, math.floor( ( n % 100 )/10) * 5, 0, 5, 7, 0, Vec2.new(0.5, 0.5), false, false, color )
        tex( texUI_numbers, sprX + 5 * zoom, sprY, 5 * zoom, 7 * zoom, math.floor( n % 10 ) * 5, 0, 5, 7, 0, Vec2.new(0.5, 0.5), false, false, color )
    elseif n >= 10 then
        tex( texUI_numbers, sprX, sprY, 5 * zoom, 7 * zoom, math.floor(n/10) * 5, 0, 5, 7, 0, Vec2.new(0.5, 0.5), false, false, color )
        tex( texUI_numbers, sprX + 5 * zoom, sprY, 5 * zoom, 7 * zoom, math.floor( n % 10 ) * 5, 0, 5, 7, 0, Vec2.new(0.5, 0.5), false, false, color )
    else
        tex( texUI_numbers, sprX + 3 * zoom, sprY, 5 * zoom, 7 * zoom, math.floor( n % 10 ) * 5, 0, 5, 7, 0, Vec2.new(0.5, 0.5), false, false, color )
    end
end

UI_Equipment_Render = function( x, y, w, h, cfg, res, iconResIndex, number, barResX, barResY, barValue, barMax, callback )
    local adjust = {32, 26, 7, 8, -46, 
        8, 4, 0, 2.5, -18, 
        -20, 73, -6, -6}
    x = x + adjust[7]
    y = y + adjust[8]
    -- show equipment icon
    spr( res, x, y, w, h )
    -- show the right down corner icon
    if number > 0 then
        tex( texUI_tile_ui, x + adjust[1], y + adjust[2], 64, 64, 32 * iconResIndex, 0, 32, 32 )
        UI_ShowNumber( x + 64 + adjust[3], y + 64 + adjust[4], number, 2 )
    end
    if barMax > 0 then
        -- show number
        UI_ShowNumber( x + adjust[11], y + adjust[12], barMax, 2 )
        UI_ShowNumber( x + adjust[11], y + adjust[12] + adjust[10], barValue, 2 )
        -- show the bar
        local p = barValue / barMax
        tex( texUI_bank7_ui, x + adjust[5], y + adjust[6] + 32 * (1 - p) * adjust[9], 32, 32 * adjust[9] * p, 
            32 * barResX, barResY * 32 + 32 * (1 - p) * 3, 32, 32 * 3 * p )
    end

    -- mouse hover event
    UI_Clickable( Rect.new( x, y, x + w, y + h ), Rect.new( x, y + h + adjust[13], x + w + adjust[14], y + 3 + h + adjust[13] ), 
    function()
        -- print('itemdetails', '', cfg.id)
        ui_itemDetail.curDetail = cfg
    end, callback )
end

UI_Buy_Render = function( x, y, iconResIndexX, iconResIndexY, priceResIndexX, priceResIndexY, cost, canAfford, canPayPartial )
    local adjust = {14, 24 , 16}
    local color = nil
    if not canAfford then
        if canPayPartial then
            color = Color.new( 255, 125, 0 )
        else
            color = Color.new( 255, 0, 0 )
        end
    end
    local coinColor = Equipment_GetCrystalColor( cost )
    -- show crystal
    tex( texUI_crystal_coin, x + adjust[1], y + 2, 32, 32, 0, 0, 0, 0, 0, Vec2.new(0.5, 0.5), false, false, coinColor )
    -- show icon
    tex( texUI_bank7_ui, x, y, 32, 32, iconResIndexX * 32 , iconResIndexY * 32, 32, 32 )
    -- show number
    UI_ShowNumber( x + adjust[2], y + adjust[3], Crystals_sum(cost), 2, color )
end

UI_Icon_Render = function( x, y, iconResIndexX, iconResIndexY, w, h )
    -- show icon
    tex( texUI_bank7_ui, x, y, 32 * w, 32 * h, iconResIndexX * 32 , iconResIndexY * 32, 32 * w, 32 * h )
end

UI_Clickable = function( clickArea, highlightArea, onHover, onClick, priority )
    if priority == nil then priority = MOUSE_PRIORITY_UI end
    local xx, yy, tb1 = mouseManager:getMouse( priority )
    if xx > clickArea.x0 and xx < clickArea.x1 and yy > clickArea.y0 and yy < clickArea.y1 then
        if onHover ~= nil then
            onHover()
        end
        blend( Canvas.BlendModeAdd )
        rect(highlightArea.x0, highlightArea.y0, highlightArea.x1, highlightArea.y1, true, COLOR_YELLOW_TRANS)
        if mouseClick(tb1) and onClick ~= nil then
            onClick()
        end
        blend()
    end
end

UI_Choices_Default = {
    text = 'Choice Text',
    callback = nil,
}
UI_Choices = function( choices )
    local adjust = {150, 200, 200, 50, 0, 0, 50, -25 }
    rect( 0, 0, totalW, totalH, true, Color.new(0, 0, 0, 180 ) )
    UI_Title( -2, game.choicesTitle )
    for k,v in ipairs( choices ) do
        UI_MenuButton( k - 2, v.text, v.callback, MOUSE_PRIORITY_POPUP )
    end
end

UI_ItemDetail = class({
    curDetail = nil,
    container = nil,

    ctor = function(self)
    end,

    setup = function(self, container)
        self.container = container
        container:addChild(
            beGUI.MultilineLabel.new( '' )
                :setId('item_details')
                :put( margin + mapCfg.moxNoCamera, margin + mapCfg.moyNoCamera)
                :resize( tileSize * tileCountNoCamera - margin * 2, tileSize * tileCountNoCamera - margin * 2 )
        )
    end,

    render = function(self)
		if self.container == nil then return end
        local details = self.container:find('item_details')
        if self.curDetail == nil then 
            details:setVisible( false ) 
			return
        end
        printOnce( '###', '', self.curDetail.id, mapCfg.moxNoCamera, mapCfg.moyNoCamera, mapCfg.moxNoCamera + tileSize * 16 , mapCfg.moyNoCamera + tileSize * 16 )
        rect(mapCfg.moxNoCamera, mapCfg.moyNoCamera, mapCfg.moxNoCamera + tileSize * 16 , mapCfg.moyNoCamera + tileSize * 16, true, COLOR_GREY)
        local d = FindEquipmentById( self.curDetail.id )
        details:setValue( Equipment_GetDetailDescription(d) ):setVisible( true )
    end,
})
ui_itemDetail = UI_ItemDetail.new()

UI_ItemList = class({
    page  = 1,
    totalPage = 1,
    pageItemMax = 11,
    lastItemList = {},

    ctor = function(self)
    end,

    render = function(self)
        local itemlist = self.lastItemList
        for i,ee in ipairs( itemlist ) do
            if i < ( self.page * self.pageItemMax + 1 ) and i > (self.page-1) * self.pageItemMax then
                local ii = i % self.pageItemMax
                local iconResIndex, number, barResX, barResY, barValue, barMax = 4, ee.cfg.att, 0, 0, ee.cfg.energy, ee.cfg.energy_max
                if ee.cfg.energy_power_max > 0 then
                    iconResIndex, number, barResX, barResY, barValue, barMax = 3, ee.cfg.energy_power_max, 1, 0, ee.cfg.energy_power, ee.cfg.energy_power_max
                end
                local canAfford = Equipment_canAfford( ee.cfg )
                printOnce('', '', row, ee.cfg.id, res, iconResIndex, number, barResX, barResY, barValue, barMax, 
                    isEquipped, isSwitchable, isUpgrade, isNew, isLocked, canAfford)
                -- row, res, iconResIndex, number, barResX, barResY, barValue, barMax, isEquipped, isSwitchable, isUpgrade, isNew, isLocked
                self:_render( ii-1, ee.cfg, ui_pool:getRes( ee.cfg.img, 'idle' ), iconResIndex, number, barResX, barResY, barValue, barMax, ee.isEquipped, ee.isSwitchable, ee.isUpgrade, ee.isNew, ee.isLocked, canAfford )
            end
        end
    end,

    _render = function( self, row, cfg, res, iconResIndex, number, barResX, barResY, barValue, barMax, 
        isEquipped, isSwitchable, isUpgrade, isNew, isLocked, canAfford )
    
        local adjust = {44, 0, 52, 12, -4, 4, -30, 
            0, 0.8, -155, 80, 41, 52, 136, 
            40, 32}

        local x = totalW + adjust[10]
        local y = adjust[11] + row * adjust[12]
        
        x = x + adjust[7]
        y = y + adjust[8]
        -- show equipment icon
        spr( res, x, y, 32, 32 )
        if not isLocked then
            if canAfford then
                text( cfg.desc, x + adjust[1], y + adjust[2] )
            else
                text( cfg.desc, x + adjust[1], y + adjust[2], Color.new( 125, 125, 125 ) )
            end
            -- show equipped or change
            if isEquipped then
                UI_Icon_Render( x + adjust[14], y, 3, 0, 1, 1 )
            elseif isSwitchable then
                UI_Icon_Render( x + adjust[14], y, 4, 0, 1, 1 )
            end
            -- show upgrade or craft
            if isUpgrade then
                UI_Buy_Render( x + adjust[14], y, 5, 0, 7, 0, cfg.cost, canAfford, false )
            elseif isNew then
                UI_Buy_Render( x + adjust[14], y, 6, 0, 7, 0, cfg.cost, canAfford, false )
            end
        else
            text( "? ? ?", x + adjust[1], y + adjust[2], Color.new( 125, 125, 125 ) )
            -- show lock
            UI_Icon_Render( x + adjust[14], y, 8, 2, 1, 1 )
        end

        -- mouse hover event
        if not isLocked then
            UI_Clickable( Rect.new( x, y, x + adjust[14] + adjust[15], y + adjust[12] ), Rect.new( x, y + adjust[16] - row, x + adjust[14] + adjust[15], y + 3 + adjust[16] ),
            function()
                -- print('itemdetails', '', cfg.id)
                ui_itemDetail.curDetail = cfg
            end,
            function()
                if (( isNew or isUpgrade ) and canAfford) or isSwitchable  then
                    game:upgradeEquipment( cfg, isSwitchable, false, true )
                    game.player:changeState()
                    self:update()
                    game.player.stun = game.player.stun + 3
                end
            end )
        end

    end,
    
    _updateResult = { cfg = nil, isEquipped = false, isSwitchable = false, isUpgrade = false, isNew = false, isLocked = false },
    update = function( self )
        local fullList = {}
        local fullIds = {}
        local equipped = { game.weaponMain.cfg.id, game.shield.cfg.id }
        if game.badge ~= nil then table.insert( equipped, game.badge.cfg.id ) end
        local crafted, craftedLevelUp, levelUpMissed = game:filterEquipmentByCrafted()
    
        for k,n in ipairs( levelUpMissed ) do
            table.insert( fullIds, n )
        end

        for k,n in ipairs( crafted ) do
            if not exists( equipped, n ) then
                local ee = merge( EquipmentDefault, copy( FindEquipmentById( n ) ) );
                local isLevelUped = false
                for klevelup, nlevelup in ipairs( ee.level_up ) do
                    if exists( crafted, nlevelup ) then
                        isLevelUped = true
                    end
                end
                if isLevelUped == false then
                    table.insert( fullList, { cfg = ee, isEquipped = false, isSwitchable = true, isUpgrade = false, isNew = false, isLocked = false } )
                end
                table.insert( fullIds, n )
            end
        end
    
        for k,n in ipairs( craftedLevelUp ) do
            local ee = merge( EquipmentDefault, copy( FindEquipmentById( n ) ) );
            table.insert( fullList, { cfg = ee, isEquipped = false, isSwitchable = false, isUpgrade = true, isNew = false, isLocked = false } )
            table.insert( fullIds, n )
        end

        local lockedList = {}
        -- find all the next next level up categories
        for k,n in ipairs( craftedLevelUp ) do
            local ee = merge( EquipmentDefault, copy( FindEquipmentById( n ) ) );
            for knn, nnn in ipairs( ee.level_up ) do
                if exists( AllLevelUpCategories, nnn ) then
                    local eee = merge( EquipmentDefault, copy( FindEquipmentById( nnn ) ) );
                    table.insert( lockedList, { cfg = eee, isEquipped = false, isSwitchable = false, isUpgrade = false, isNew = false, isLocked = true } )
                end
            end
        end

        local newCategoryList = {}
        -- show all the missing base categories
        for k,n in ipairs( AllBaseCategories ) do
            local ee = merge( EquipmentDefault, copy( FindEquipmentById( n ) ) );
            if not exists( crafted, n ) then
                table.insert( newCategoryList, { cfg = ee, isEquipped = false, isSwitchable = false, isUpgrade = false, isNew = true, isLocked = false } )
            end
        end
        game.history.equipments = {}
        for k,v in ipairs( fullList ) do
            if v.cfg.isEquipped == true or v.cfg.isSwitchable then
                table.insert( game.history.equipments, v.cfg.id )
            end
        end
        fullList = concat( fullList, newCategoryList )
        fullList = concat( fullList, lockedList )
        self.lastItemList = fullList
    end,
})
ui_itemList = UI_ItemList.new()

UI_Popup = class({
    ispopup = false,
    popup = nil,

    ctor = function(self)
    end,


    setup = function(self)
        self.popup = beGUI.Widget.new():put(0, 0):resize(P(100), P(100))
    end,


    render = function(self, delta)
        if self.ispopup then
			rect(0, 0, totalW, totalH, true, Color.new(40, 40, 40, 180))
            font(theme['font'].resource)
            self.popup:update(theme, delta)
            font(lanapixel)
        end
    end,

    open = function(self, title, messages, button, onConfirm)
        self.ispopup = true
        local onClick = function()
            print('Popup: remove')
            self.popup:clearChildren()
            self.ispopup = false
            onConfirm()
        end

        local box = beGUI.Widget.new()
            :setId('popupcontainer')
            :put(0, 0)     -- X: 27%, Y: 15.
            :resize(totalW - 30, totalH - 30) -- W: 45%, H: 290.
        for k,v in ipairs( messages ) do
            local font = 'font_white'
            if k == #messages then
                font = 'font_alert'
            end
            box:addChild( beGUI.Label.new(v, 'center', false, font)
                :put(0, totalH / 2 - lineHeight - #messages * lineHeight / 2 + k * lineHeight)
                :resize(totalW, lineHeight)
            )
        end
        box:addChild(
            beGUI.Button.new(button)
                :setId('popup_exit')
                :anchor(0, 0)      -- X: left, Y: bottom.
                :put((totalW - btnWUnit) / 2, totalH / 2 - lineHeight - #messages * lineHeight / 2 + #messages * lineHeight + lineHeight * 2)    -- X: -50%, Y: 0.
                :resize(btnWUnit, lineHeight) -- W: 48%, H: 23.
                :on('clicked', function (sender)
                    onClick()
                end)
        )
        self.popup:addChild( box )
    end,
})
ui_popup = UI_Popup.new()

UI_RenderCrystals = function( x, y, currency )
    local adjust = { x, y, 16, 16, 42 }
    local x, y = adjust[1], adjust[2]
    n = 0
    for k,v in pairs(CRYSTALS) do
        if k ~= 'crystal_main' then
            local crystal = currency[k]
            local cs = {}
            cs[k] = crystal
            local color = Equipment_GetCrystalColor( cs )
            tex( texUI_crystal_coin, x + n * adjust[5], y, 32, 32, 0, 0, 0, 0, 0, Vec2.new(0.5, 0.5), false, false, color )
            -- show number
            UI_ShowNumber( x + adjust[3] + n * adjust[5], y + adjust[4], crystal, 2, color )
            n = n + 1
        end
    end
end

UI_MenuButton = function( row, txt, onClick, priority)
    local adjust = {192, 32, 32, 192, 32 + 3, 325, 250, 50 }
    local x, y = adjust[6], adjust[7]
    text( txt, x, y + row * adjust[8] )
    UI_Clickable( Rect.new( x, y + row * adjust[8], x + adjust[1], y + row * adjust[8] + adjust[2] ), Rect.new( x, y + row * adjust[8] + adjust[3], x + adjust[4], y + row * adjust[8] + adjust[5] ), 
        nil, onClick, priority )
end

UI_Title = function( row, txt )
    local adjust = {192, 32, 32, 192, 32 + 3, 325, 250, 50 }
    local x, y = adjust[6], adjust[7]
    text( txt, x, y + adjust[8] * row, COLOR_RED )
end

Render_History = function( row, history )
    local adjust = { 160, 150, 120, 30, 450, 170, -30 }
    -- dateCreated = nil, dateTimeFrom = nil, dateTimeTo = nil, round = nil,  killedBy = nil, crystal_gain = copy( CRYSTALS ), steps = 0, monster_kill = {}, equipments = {}, mode = nil, isWin = false
    local lineHeight = adjust[4]
    local timeTo, timeFrom = 0, 0
    if history.dateTimeTo ~= nil then timeTo = history.dateTimeTo end
    if history.dateTimeFrom ~= nil then timeFrom = history.dateTimeFrom end
    -- '模式: '..history.mode .. '   ' ..'步数: '..history.steps .. '   '..(timeTo - timeFrom)
    text( '' .. history.round  .. '回', adjust[1], adjust[2] + adjust[3] * row )
    if history.isWin then
        text( ''..'胜利', adjust[1] + adjust[5], adjust[2] + adjust[3] * row, Color.new( 0, 255, 80 ) )
    else
        local s = ''..'失败'
        if history.killedBy ~= nil then 
            s = s .. '   '..'被谁击败: ' .. history.killedBy
        end
        text( s, adjust[1] + adjust[5], adjust[2] + adjust[3] * row, Color.new( 255, 80, 0 ) )
    end
    UI_RenderCrystals( adjust[1] + adjust[6], adjust[2] + adjust[3] * row + lineHeight + adjust[7], history.crystal_gain )
    text( '装备: '..#history.equipments, adjust[1], adjust[2] + adjust[3] * row + lineHeight )
    text( '杀死: '..#history.monster_kill, adjust[1], adjust[2] + adjust[3] * row + lineHeight * 2 )
end

UI_HistoryList = class({
    page  = 1,
    totalPage = 1,
    pageItemMax = 3,
    historyList = {},

    reset = function(self)
        self.historyList = {}
        sortByCurrency = function( a, b )
            return Crystals_sum( a.crystal_gain ) > Crystals_sum( b.crystal_gain )
        end
        self.historyList = sort( profileManager.cfg.history, sortByCurrency )
        self.totalPage = math.ceil( #self.historyList / self.pageItemMax )
    end,

    render = function(self)
        for i, hh in ipairs( self.historyList ) do
            if i < ( self.page * self.pageItemMax + 1 ) and i > (self.page-1) * self.pageItemMax then
                local ii = ( i - 1 ) % self.pageItemMax
                Render_History( ii, hh )
            end
        end
        local x, y, b1, b2, b3, wheel = mouseManager:getMouse( MOUSE_PRIORITY_SYSTEM )
        if keyp( KeyCode.Down ) or wheel < 0 then self.page = self.page + 1 end
        if keyp( KeyCode.Up ) or wheel > 0 then self.page = self.page - 1 end
        if self.page > self.totalPage then self.page = self.totalPage end
        if self.page < 1 then self.page = 1 end
        UI_Title( 5, ''..self.page..'/'..self.totalPage )
    end
})
ui_historyList = UI_HistoryList.new()
