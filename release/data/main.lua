require 'game'
require 'ui_elements'
require 'map_generator'
require 'background'
require 'units/projectile'
require 'camera'
require 'profile'

-- resources
lanapixel = Font.new('fonts/LanaPixel.ttf', 26)   -- 中文像素字体，13 的倍数效果较好。
local texUI_backdrop = Resources.load('res/UI_backdrop.png')
local texUI_portrate = Resources.load('res/fire profiel-export.png')

DEBUG = false -- full player vision, better weapon, more crystals
DEBUG_MORE_CRYSTAL = false
DEBUG_POSITION = false
DEBUG_MAP = false
DEBUG_WEAPON = false
DEBUG_UNIT = false
DEBUG_RENDER_ORDER = false
DEBUG_FAST_MODE = false
DEBUG_FRAME = false
DEBUG_FRAME_RATE = false
DEBUG_HIDE_TERRAIN = false
DEBUG_UI_LAYOUT = false
DEBUG_ANALYSIS_LEVEL = false
DEBUG_ANALYSIS_ALL = false
DEBUG_TILE = false 	-- 打印tile的role
DEBUG_LEVEL = false -- 打印单位的等级情况
DEBUG_CONSOLE = false -- input some common through the UI ( e.g. to kill an unit )
DEBUG_UNIT_GENERATE = false -- debug the unit generation logic, including level balance
DEBUG_KEYS = true -- enable cheat keys
DEBUG_ADJUST_PARAMS = false -- use UI to adjust particle systems
TEST_MAP = 'level/test2.map'

tileH = 32
tileW = 32

theme = customizedTheme.default()

SceneGameMode = class({

	setupAgain = function( self, gamemode )
		Debug.setTimeout( 180 )
		
        game:loadStage()
	end,
})

MainLoop = class({
	state = 'mainmenu',
	stategamemode = 'test',
	mainMenuRoot = nil,
	debugConsoleRoot = nil,
    ui3Root = nil,
	tilesMask = nil,

	setup = function(self)
		-- initialize game basics
		cls(Color.new(0,0,0))
		math.randomseed(DateTime.ticks())
		Canvas.main:resize(1366, 768)
        theme = customizedTheme.default()
		font(lanapixel)

		-- initialize UI
		self.mainMenuRoot = beGUI.Widget.new():put(0,0):resize(P(100), P(100))
		self.debugConsoleRoot = beGUI.Widget.new():put(0,0):resize(P(100), P(100))
        self.ui3Root = beGUI.Widget.new():put(0,0):resize(P(100), P(100))
		UI_DebugConsole.new():setup( self.debugConsoleRoot )
		ui_itemDetail:setup( self.ui3Root )

		-- preparing game content
		profileManager:loadAll()
		game:setup()
		mouseManager:setup()

		-- initialize main menu
		self:changeState( 'mainmenu')

		sync()
	end,

	changeState = function( self, newState, gamemode )
		self.state = newState
		self.stategamemode = gamemode

		if newState == 'mainmenu' then
		elseif newState == 'modehistory' then
			ui_historyList:reset()
		elseif newState == 'game' then
			Debug.setTimeout( 180 )

			if gamemode == 'test' then
				mapCfg:reset( gamemode, 16 )
				self.tilesMask = Resources.load( 'spr/background_mask.spr' )
				self.tilesMask:play('idle', false, true, true)
			elseif gamemode == 'gen2' then
				mapCfg:reset( 'gen2', 24 )
				self.tilesMask = Resources.load( 'spr/background_mask.spr' )
				self.tilesMask:play('idle', false, true, true)
			end

			bg:reset()
			mouseManager:reset()
			mapGenerator2:reset()
			game:reset()
		
			-- setup camera limits
			mainCamera:reset()
			local canvasWidth, canvasHeight = Canvas.main:size()
			local px, py = game.player:getRealPos()
			mainCamera:setCameraPos( mapCfg.mox + px - canvasWidth * 0.5, mapCfg.moy + py - canvasHeight * 0.5 )

			Debug.setTimeout( 60 )
		end
	end,

	update = function( self, delta )

		if self.state == 'game' then  
			if DEBUG_FRAME_RATE and delta > 0.1 then
				warn('frame rate very low: '.. delta)
			end
			mainCamera:update(delta)
			game:update(delta)
			bg:update(delta)
			camera()
			-- render in game UI
			local adjust = { 48, 160, 288, 50, 31, 78, 389 }
			ui_itemDetail.curDetail = nil
			-- if self.tilesMask ~= nil then
			-- 	spr( self.tilesMask, 0, 0, 960, 640 )
			-- end
			-- tex( texUI_backdrop, 0, 0 )
			UI_RenderCrystals( 16, 590, game.currency )
			-- render current equipments on the left hand 
			UI_Equipment_Render( adjust[1], adjust[2], 96, 96, game.shield.cfg, ui_pool:getRes( game.shield.cfg.img, 'idle' ), 3, 0, 1, 0, game.shield.cfg.energy_power, game.shield.cfg.energy_power_max )
			if game.weaponTemp == nil then
				UI_Equipment_Render( adjust[1], adjust[3], 96, 96, 
					game:getWeapon().cfg, ui_pool:getRes( game:getWeapon().cfg.img, 'idle' ), 4, 
					game:getWeapon().cfg.att, 0, 0, 0, 0 )
			else
				UI_Equipment_Render( adjust[1], adjust[3], 96, 96, 
					game:getWeapon().cfg, ui_pool:getRes( game:getWeapon().cfg.img, 'idle' ), 4, 
					game:getWeapon().cfg.att, 0, 0, game:getWeapon().cfg.energy, game:getWeapon().cfg.energy_max )
				UI_Equipment_Render( adjust[1] + 96 + 32, adjust[3] + 64, 32, 32, 
					game.weaponMain.cfg, ui_pool:getRes( game.weaponMain.cfg.img, 'idle' ), 4, 
					0, 0, 0, 0, 0 )
			end
			if game.badge ~= nil then
				UI_Equipment_Render( adjust[1], adjust[3] + 160, 96, 96, game.badge.cfg, ui_pool:getRes( game.badge.cfg.img, 'idle' ), 99, game.badge.cfg.level, 0, 0, game.badge.cfg.energy, game.badge.cfg.energy_max )
			end
			for k,v in ipairs( game.rune ) do
				UI_Equipment_Render( adjust[1] + k * 32, adjust[3] + 160 + 96, 32, 32, 
					v.cfg, ui_pool:getRes( v.cfg.img, 'idle' ), 99, 0, 0, 0, 0, 0, function()
						game.player:actionUseItem( v )
					end )
			end
			for k,v in ipairs( game.inventory ) do
				UI_Equipment_Render( adjust[1] + k * 32, adjust[3] + 160 + 96 + 32, 32, 32, 
					v.cfg, ui_pool:getRes( v.cfg.img, 'idle' ), 99, 0, 0, 0, 0, 0, function()
						game.player:actionUseItem( v )
					end )
			end
			tex( texUI_portrate, adjust[4], adjust[5], 96, 96 )
			if ( game.player.cfg.extra_hp > 0 ) then text( 'HP+'..game.player.cfg.extra_hp, adjust[4] - 64, adjust[5] ) end
			if ( game.player.cfg.extra_att > 0 ) then text( 'Att+'..game.player.cfg.extra_att, adjust[4] - 32, adjust[5] ) end
			if ( game.player.cfg.hard_def > 0 ) then text( 'Death Prevent'..game.player.cfg.hard_def, adjust[4], adjust[5] ) end
			-- render item details, if mouse is hovering any
			ui_itemDetail:render()
			self.ui3Root:update(theme, delta)
			-- render projectiles
			mainCamera:update(delta)
			projectileManager:update(delta)
			projectileManager:render()
			camera()
		end

		if #game.choices > 0 then
			UI_Choices( game.choices )
		end

		local adjust = { 16, 590 }
		if self.state == 'mainmenu' then
            UI_Title( -2, '水晶锻造者 - 烈火的冒险迷宫' )
            UI_MenuButton( 0, '开始新游戏', function() 
				self:changeState( 'modeselect' )
            end )
            UI_MenuButton( 1, '选项', function() 
                print('选项')
				self:changeState( 'modeoption' )
            end )
            UI_MenuButton( 2, '退出', function() 
                print('退出')
                exit() 
            end )
            UI_RenderCrystals( adjust[1], adjust[2], profileManager.cfg.profile.crystals )
		elseif self.state == 'modehistory' then
            UI_Title( -4, '履历浏览' )
            UI_MenuButton( 6, '返回', function() 
                print('返回')
				self:changeState( 'modeselect' )
            end )
            ui_historyList:render()
		elseif self.state == 'modeoption' then
            UI_Title( -2, '选项' )
            UI_MenuButton( 0, '清空记录', function() 
                print('清空记录')
                profileManager:clearAll()
                profileManager:saveAll()
				game.currency = copy( profileManager.cfg.profile.crystals )
            end )
            UI_MenuButton( 1, '返回', function() 
                print('返回')
				self:changeState( 'mainmenu' )
            end )
		elseif self.state == 'modeselect' then  
            UI_Title( -2, '模式选择 (加载需要2分钟，请耐心等待）' )
            UI_MenuButton( 0, '履历浏览', function() 
                print('履历浏览')
				self:changeState( 'modehistory' )
            end )
            UI_MenuButton( 1, '第二代 - 标准模式 (推荐)', function() 
                print('第二个模式 - 标准模式')
				self:changeState( 'game', 'gen2' )
            end )
            UI_MenuButton( 2, '测试模式', function() 
                print('第零个模式 - 测试模式')
				self:changeState( 'game', 'test' )
            end )
            UI_MenuButton( 3, '返回', function() 
				self:changeState( 'mainmenu' )
            end )
            UI_RenderCrystals( adjust[1], adjust[2], profileManager.cfg.profile.crystals )
		end

        self.mainMenuRoot:update(theme, delta)
        self.debugConsoleRoot:update(theme, delta)
	end,
	
	updateCraftPanel = function(self, isForce)
        ui_itemList:update()
	end,
})
mainLoop = MainLoop.new()

function setup()
	mainLoop:setup()
end

function update(delta)
	mainLoop:update( delta )
end


