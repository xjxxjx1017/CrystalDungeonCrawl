require 'code/class'
local Tween = require 'code/tween' -- See https://github.com/kikito/tween.lua.

function Equipment_canAfford( equipDef )
    Equipment_info( 'Equipment_canAfford:', equipDef )
    return Crystals_canAfford( equipDef.cost )
end

function Equipment_cost( equipDef )
    Equipment_info( 'Equipment_cost:', equipDef )
    for k,v in pairs(CRYSTALS) do
        game.currency[k] = game.currency[k] - (equipDef.cost[k] or 0)
    end
end

function Equipment_info( surfix, equipDef )
    if DEBUG_WEAPON == false then return end
    local cost = ''
    print( surfix, ' ', equipDef.desc or 'N', ' Lv.' .. (#equipDef.level_up or 'N'), (equipDef.energy or 'N') .. '/' .. (equipDef.energy_max or 'N'), (equipDef.energy_power or 'N') .. '/' .. (equipDef.energy_power_max or 'N'),
        cost )
end

function Equipment_GetDetailDescription( equipDef )
    local result = '[col=0x00ff00ff]'..equipDef.id..'[/col]\n\n'
    if equipDef.etype == 'shield' then
        result = result 
            .. '[col=0x00AABCff]最大能量: \t\t'.. equipDef.energy_power_max..'[/col]\n\n'

            .. '[col=0xffffffff]' .. equipDef.descDetails..'[/col]\n\n'

            .. '[col=0xaaaaaaff]可用升级: \t\t'.. #equipDef.level_up..'[/col]\n\n'
    elseif equipDef.etype == 'weapon' then
        result = result
            .. '[col=0xff9900ff]攻击力: \t\t'.. equipDef.att..'[/col]\n\n'

            .. '[col=0xffff00ff]最大充能: \t\t'.. equipDef.energy_max..'[/col]\n'
            .. '[col=0xffff00ff]单位充能消耗: \t\t'.. Crystals_sum( equipDef.recharge_cost ) ..'[/col]\n\n'

            .. '[col=0xffffffff]' .. equipDef.descDetails..'[/col]\n\n'

            .. '[col=0xaaaaaaff]可用后续升级: \t\t'.. #equipDef.level_up..'[/col]\n\n'
    elseif equipDef.etype == 'badge' then
        result = result
            .. '[col=0xffff00ff]最大充能: \t\t'.. equipDef.energy_max..'[/col]\n'
            .. '[col=0xffff00ff]单位充能消耗: \t\t'.. Crystals_sum( equipDef.recharge_cost ) ..'[/col]\n\n'

            .. '[col=0xffffffff]' .. equipDef.descDetails..'[/col]\n\n'

            .. '[col=0xaaaaaaff]可用后续升级: \t\t'.. #equipDef.level_up..'[/col]\n\n'

    end
	return result
end

Equipment_GetLevelUpDisplay = function(level_up)
    return #level_up
end

Equipment = class({
    cfg = nil,
    spr = nil,

    ctor = function( self, equipDef )
        self.cfg = merge( EquipmentDefault, copy( equipDef ) )
        self.spr = sprPool:getRes( self.cfg.img, 'idle' )
        Equipment_info( 'created', self.cfg )
    end,
	
	info = function(self, surfix )
        Equipment_info( surfix, self.cfg )
	end,

    -- render equipment at the player's location
    render = function(self, x, y, dx, dy, zoom, angle )
        -- rotCenter = Vec2.new(0, 0)
		if self.spr ~= nil then
			-- spr(self.spr, mapCfg.mox + x * 32 + dx, mapCfg.moy + y * 32 + dy, 32 * zoom, 32 * zoom, angle)
        else
            debugtest('weapon not found')
        end
    end,
})