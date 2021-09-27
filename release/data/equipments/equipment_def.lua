
require 'code/class'

TANDAO_LIMIT_1 = 0.5
TANDAO_LIMIT_2 = 0.2

CRYSTALS = { crystal1 = 0, crystal2 = 0, crystal3 = 0, crystal4 = 0, crystal_main = 0, crystal_white = 0 }
CRYSTALS_COMMON = { 'crystal1', 'crystal2', 'crystal3', 'crystal4' }

Crystals_multiply = function( crystal, multi )
    local result = {}
	local crystal = merge( copy(CRYSTALS), crystal )
    for k,v in pairs( CRYSTALS ) do
        result[k] = crystal[k] * multi
    end
    return result
end

Crystals_add = function( c1, c2 )
	local crystal = merge( copy(CRYSTALS), c1 )
    for k,v in pairs( CRYSTALS ) do
        if c2 ~= nil and c2[k] ~= nil then
            crystal[k] = crystal[k] + c2[k]
        end
    end
    return crystal
end

Crystals_canAfford = function ( cost )
	local crystal = merge( copy(CRYSTALS), cost )
    if crystal.crystal_main > 0 then
        return Crystals_canAfford( Crystals_primaryFromAny( cost ) )
    end
    for k,v in pairs(CRYSTALS) do
        if cost[k] ~= nil and cost[k]  > game.currency[k] then return false end
    end
    return true
end

Crystals_primaryFromAny = function( cost )
    if cost.crystal_main <= 0 then return cost end
	local crystal = merge( copy(CRYSTALS), cost )
    local k = Crystals_getPrimary( game.weapon.cfg.recharge_cost )
    local amount = crystal.crystal_main
    local ck = {}
    ck[k] = amount
    return ck
end

Crystals_sum = function ( cost )
	local crystal = merge( copy(CRYSTALS), cost )
    local sum = 0
    for k,v in pairs(CRYSTALS) do
        if cost[k] ~= nil then 
            sum = sum + cost[k]
        end
    end
    return sum
end

Crystals_getPrimary = function ( cost )
	local crystal = merge( copy(CRYSTALS), cost )
    if crystal.crystal_main > 0 then
        return Crystals_getPrimary( game.weapon.cfg.recharge_cost )
    end
    for k,v in pairs(CRYSTALS) do
        if cost[k] ~= nil and cost[k]  > 0 then return k end
    end
    return 'crystal1'
end

Equipment_GetCrystalColor = function( cost )
    local full_cost = merge( copy(CRYSTALS), cost )
    if full_cost.crystal_main > 0 then
        full_cost[ Crystals_getPrimary( game.weapon.cfg.recharge_cost ) ] = 100
    end
    if full_cost.crystal_white > 0 then
        return Color.new( 255, 255, 255, 255 )
    end
    if full_cost.crystal4  > 0 then
        return Color.new( 255, 0, 0, 255 )
    elseif full_cost.crystal3  > 0 then
        return Color.new( 241, 227, 0, 255 )
    elseif full_cost.crystal2  > 0 then
        return Color.new( 69, 228, 171, 255 )
    elseif full_cost.crystal1  > 0 then
        return Color.new( 0, 167, 181, 255 )
    end
end

EquipmentDefList = {}

EquipmentDefault = {
    -- 费用属性
    cost = copy( CRYSTALS ),
    -- 通用属性
    id = '没', img = 'spr_weapon/question.spr', desc = '没', btn = '没', descDetails='没描述', level_up = {},
    -- 武器属性
    att = 0, min_att = 0, att_terrain = 0, att_self_stun = 0, is_aoe = false, energy_max = 0, energy = 0, recharge_cost = copy( CRYSTALS ), range = { { x = 0, y = 1 } }, range_weak = {},
	sight = 2.5,
    -- 防具属性
    energy_power = 0, energy_power_max = 0, charge_buff = nil, ai = nil,
    -- force move属性
    force_move = 0, force_move_max = 0, cur_force_move = nil, force_att = 0, force_att_max = 0
}

local wn = 50
local wnb = 5

Equipment_getUpgradeCost = function( level )
    return 4 + level 
end

EQUIPMENT_DEFAULT = { 
    id = '无', desc = '装备：无', cost = {}, att = 0, att_terrain = 1, energy_max = 0, energy = 0, min_att = 0, energy_power = 0, energy_power_max = 0, level_up = {}, level = 0
}
table.insert( EquipmentDefList, EQUIPMENT_DEFAULT )

EQUIPMENT_WHITE_SHIELD = {
    id = '白板盾', 
    descDetails = '< 变换 >\n是很多物质的基础。', category = '白板护盾', etype = 'shield', desc = '白石', cost = { crystal_white = 5 }, energy_power = 10, energy_power_max = 10, level_up = { '护盾1' }
}
table.insert( EquipmentDefList, EQUIPMENT_WHITE_SHIELD )

EQUIPMENT_WHITE_SWORD = {
    id = '白板武器', 
    descDetails = '< 变换 >\n是很多物质的基础。', category = '白板武器', etype = 'weapon', desc = '白石', cost = { crystal_white = 5 }, att = 1, energy_max = wn, energy = wn, recharge_cost = { crystal_white = 1 }, 
    range = { { x = 0, y = 1 } }, level_up = { '剑1', '冲刺矛1', '劈山斧1', '弓箭1' }, level  = 0, att_self_stun = 1,
}
table.insert( EquipmentDefList, EQUIPMENT_WHITE_SWORD )

EQUIPMENT_WHITE_BADGE = {
    id = '白板徽章', 
    descDetails = '< 变换 >\n是很多物质的基础。', category = '白板徽章', etype = 'badge', desc = '白石徽章', cost = { crystal_white = 5 }, energy_max = wnb, energy = wnb, recharge_cost = { crystal_main = 3 }, level_up = { '护盾徽章1' }, level = 0
}
table.insert( EquipmentDefList, EQUIPMENT_WHITE_BADGE )

EQUIPMENT_BADGE_SHIELD = {
    id = '护盾徽章1', 
    descDetails = '< 护盾 >\n回复护盾', category = '护盾徽章', etype = 'badge', desc = '护盾徽章', cost = { crystal_white = 20 }, energy_max = wnb, energy = wnb, recharge_cost = { crystal_main = 3 }, level_up = { }, level = 1
}
table.insert( EquipmentDefList, EQUIPMENT_BADGE_SHIELD )

-- 普通的护盾-等级1
EQUIPMENT_SHIELD1 = { 
    id = '护盾1', img = 'spr_weapon/shield.spr', category = '护盾', etype = 'shield', desc = '护盾1', cost = { crystal_white = 1 }, btn = '打造', energy_power = 5, energy_power_max = 5,
    descDetails='< 小秘密 >\n就算护盾为1，它也能完全抵挡一次攻击。', 
    level_up =  {'护盾2'}
} 
table.insert( EquipmentDefList, EQUIPMENT_SHIELD1 )

-- 护盾系列
for i = 2, 5, 1 do
    local equipDef = merge( copy( EQUIPMENT_SHIELD1 ), {
        id = '护盾'..i, img = 'spr_weapon/shield.spr', desc = '护盾'..i, cost = { crystal_main = math.floor(5 * 1.4^i) }, btn = '增强', energy_power = 4 + i, energy_power_max = 4 + i, level_up = { '护盾'..(i+1) },
        descDetails='< 小秘密 >\n就算护盾为1，它也能完全抵挡一次攻击。'
    })
    if i == 5 then equipDef.level_up = {} end
    table.insert( EquipmentDefList, equipDef )
end

-- 普通的剑-等级1
EQUIPMENT_SWORD1 = { 
    id = '剑1', img = 'spr_weapon/swordbase.spr', category = '剑', baseweapon = '剑1', etype = 'weapon', desc = '剑1', cost = { crystal_white = Equipment_getUpgradeCost( 1 ) }, btn = '打造', att = 1, min_att = 1, att_terrain = 1, energy_max = wn, energy = wn, recharge_cost = { crystal1 = 1 }, range = { { x = 0, y = 1 } }, 
    descDetails='< 狂暴 >\n主动攻击之后，会接着进行两次攻击', 
    level_up =  { '剑2' }, level = 1, force_att_max = 2
}
table.insert( EquipmentDefList, EQUIPMENT_SWORD1 )

-- 普通的剑-等级2
EQUIPMENT_SWORD2 = merge( copy(EQUIPMENT_SWORD1), {
    -- 一次升级(蓝水晶8，att+1，充能3，充能花费4)
    id = '剑2', img = 'spr_weapon/swordbase.spr', desc = '剑2', baseweapon = '剑1', 
    descDetails='< 狂暴 >\n主动攻击之后，会接着进行两次攻击', cost = { crystal1 = Equipment_getUpgradeCost( 2 ) }, btn = '升级', att = 2, energy_max = wn, recharge_cost = { crystal1 = 2 }, level_up = { '剑3', '二段剑1', '彩虹剑1' }, level = 2, force_att_max = 2
})
table.insert( EquipmentDefList, EQUIPMENT_SWORD2 )

-- 普通的剑-等级3
EQUIPMENT_SWORD3 = merge( copy(EQUIPMENT_SWORD1), {
    -- 一次升级(蓝水晶8，att+1，充能3，充能花费4)
    id = '剑3', img = 'spr_weapon/swordbase.spr', desc = '剑3', baseweapon = '剑1', 
    descDetails='< 狂暴 >\n主动攻击之后，会接着进行两次攻击', cost = { crystal1 = Equipment_getUpgradeCost( 3 ) }, btn = '升级', att = 3, energy_max = wn, recharge_cost = { crystal1 = 3 }, level_up = { '轻剑1', '重剑1' }, level = 3, force_att_max = 2
})
table.insert( EquipmentDefList, EQUIPMENT_SWORD3 )

-- 硬铁剑系列
for i = 1, 2, 1 do
    local swordDef = merge( copy(EQUIPMENT_SWORD1), {
        id = '重剑'..i, img = 'spr_weapon/sword_yingtie.spr', category = '重剑', baseweapon = '剑1', 
        descDetails='< 狂暴 >\n主动攻击之后，会接着进行两次攻击', desc = '重剑'..i, cost = { crystal1 = Equipment_getUpgradeCost( i + 3 ) }, att = 3 + i, energy_max = wn, recharge_cost = { crystal1 = 3 + i }, level_up = { '重剑'..(i+1) }, level = i+3, force_att_max = 2
    })
    if i == 2 then swordDef.level_up = {} end
    table.insert( EquipmentDefList, swordDef )
end

-- 斩剑系列
for i = 1, 2, 1 do
    local swordDef = merge( copy(EQUIPMENT_SWORD1), {
        id = '轻剑'..i, img = 'spr_weapon/sword_zhan.spr', category = '轻剑', baseweapon = '剑1', 
        descDetails='< 减轻惯性 >\n主动攻击之后，会接着进行1次攻击。', desc = '轻剑'..i, cost = { crystal1 = Equipment_getUpgradeCost( i + 3 ) }, att = 3 + i, energy_max = wn, recharge_cost = { crystal1 = 3 + i },  level_up = { '轻剑'..(i+1) }, level = i+3, force_att_max = 1
    })
    if i == 2 then swordDef.level_up = {} end
    table.insert( EquipmentDefList, swordDef )
end

-- 二段剑系列
for i = 1, 1 do
    local swordDef = merge( copy(EQUIPMENT_SWORD1), {
        -- 重铸（随机消耗三种不同颜色的水晶，合计6个。可过度充能，范围2格，充能3-5，充能花费4-8）
        id = '二段剑'..i, img = 'spr_weapon/sword_erduanjian.spr', category = '二段充能剑', baseweapon = '剑1', desc = '二段充能剑'..i, cost = { crystal1 = Equipment_getUpgradeCost( i + 2 ) }, btn = '升级', att = 2 + i, energy_max = wn, energy_over_max = 30, charge_buff = BUFF_WEAPON_DOUBLE_CHARGE_SWORD,
        recharge_cost =  { crystal1 = 3 }, level_up = { '二段剑'..(i+1) },
        descDetails='< 狂暴 >\n主动攻击之后，会接着进行两次攻击。\n\n< 二段充能 >\n在充能为白色区间时，有大的攻击范围。' , level = i+2, force_att_max = 2
    })
    if i == 1 then swordDef.level_up = {} end
    table.insert( EquipmentDefList, swordDef )
end

-- 彩虹剑系列
for i = 1, 1, 1 do
    local swordDef = merge( copy(EQUIPMENT_SWORD1), {
        id = '彩虹剑'..i, img = 'spr_weapon/sword_caihong.spr', category = '彩虹剑', baseweapon = '剑1', desc = '彩虹剑'..i, cost = { crystal1 = Equipment_getUpgradeCost( i + 2 ) }, btn = '升级', att = 2 + i, energy_max = wn, recharge_cost =  { crystal1 = 3 },
        descDetails='< 狂暴 >\n主动攻击之后，会接着进行两次攻击。\n\n< 彩虹 >\n其它宝石的掉率会比通常更高，但是相对的，升级该武器则变得比通常困难。' , level = i+2, force_att_max = 2
    })
    if i == 1 then swordDef.level_up = {} end
    table.insert( EquipmentDefList, swordDef )
end

-- 普通的冲刺矛       玩家攻击后会不由自主地往前方再进行一次移动或攻击
for i = 1, 5, 1 do
    local def = {
        id = '冲刺矛'..i, img = 'spr_weapon/spearbase.spr', etype = 'weapon', baseweapon = '冲刺矛1', category = '冲刺矛', btn = '打造', min_att = 1, att_terrain = 1, range = { { x = 0, y = 1 } }, 
        descDetails='< 突刺 >\n在主动攻击之后，会往前方再攻击或移动一次。', desc = '冲刺矛'..i, cost = { crystal2 = Equipment_getUpgradeCost( i ) }, att = 1 + i, 
        energy = wn, energy_max = wn, 
        force_move = 0, force_move_max = 2, cur_force_move = nil, 
        recharge_cost = { crystal2 = i }, level_up = { '冲刺矛'..(i+1) }, level = i,
    }
    if i == 1 then cost = { crystal_white = Equipment_getUpgradeCost( i ) } end
    if i == 5 then def.level_up = {} end
    table.insert( EquipmentDefList, def )
end

-- 普通的弓箭     视野宽阔移动方向前方三格有敌人则会进行射击。在进程射击的话会收到伤害
for i = 1, 5, 1 do
    local def = {
        id = '弓箭'..i, category = '弓箭', img = 'spr_weapon/bowbase.spr', baseweapon = '弓箭1', etype = 'weapon', btn = '打造', 
        sight = 3.5,
        range = { { x = 0, y = 1 },{ x = 0, y = 2 },{ x = 0, y = 3 } }, range_weak = { { x = 0, y = 1 } },
        descDetails='< 远程 >\n能攻击到3格之内的敌人。\n\n< 不善近战 >\n在近战范围内攻击敌人，自己也会受到伤害。', desc = '弓箭'..i, cost = { crystal3 = Equipment_getUpgradeCost( i ) }, att = 1 + i, energy = wn, energy_max = wn, recharge_cost = { crystal3 = i }, level_up = { '弓箭'..(i+1) }, level = i
    }
    if i == 1 then cost = { crystal_white = Equipment_getUpgradeCost( i ) } end
    if i == 5 then def.level_up = {} end
    table.insert( EquipmentDefList, def )
end

-- 普通的劈山斧   劈山斧，地形破坏，攻击前方三格，低充能，有cd。
for i = 1, 5, 1 do
    local def = {
        id = '劈山斧'..i, img = 'spr_weapon/axebase.spr', etype = 'weapon', baseweapon = '劈山斧1', category = '劈山斧', desc = '劈山斧1', cost = { crystal4 = Equipment_getUpgradeCost( i ) }, btn = '打造', att = ( 1 + math.ceil( i * 1.5 ) ), min_att = 1, att_terrain = 3, energy_max = wn, energy = wn, recharge_cost = { crystal4 = i * 2}, range = { { x = 0, y = 1 }, { x = -1, y = 1 }, { x = 1, y = 1 } }, is_aoe = true, att_self_stun = 1,
        descDetails='< 横扫 >\n能攻击前方三格\n\n< 沉重 >\n攻击之后，会需要一回合重新摆好架势。', level_up = { '劈山斧'..(i+1) }, level = i
    }
    if i == 1 then cost = { crystal_white = Equipment_getUpgradeCost( i ) } end
    if i == 5 then def.level_up = {} end
    table.insert( EquipmentDefList, def )
end

AllBaseCategories = { '劈山斧1', '弓箭1', '冲刺矛1', '剑1' }
AllLevelUpCategories = { '彩虹剑1', '二段剑1', '轻剑1', '重剑1', '护盾徽章1' }

FindEquipmentById = function( id )
    for k,v in ipairs( EquipmentDefList ) do
        if id == v.id then return v end
    end
end

FindLevelUpsById = function( id )
    local result = {}
    for k,v in ipairs( EquipmentDefList ) do
        if id == v.id then 
            for kk, vv in ipairs( v.level_up ) do
                table.insert( result, FindEquipmentById( vv ) )
            end
        end
    end
    return result
end

FilterEquipmentByCrafted = function( craftedIds )
    local crafted = {}
    local craftedLevelUp = {}
    local levelUpMissed = {}
    for k,v in ipairs( EquipmentDefList ) do 
        if exists( craftedIds, v.id ) then
			table.insert( crafted, v.id )
            local anyLevelupCrafted = false
            -- check if any level up items have been crafted
            for kk,vv in ipairs( v.level_up ) do
                if  exists( craftedIds, vv ) then
                    anyLevelupCrafted = true
                end
            end
            -- add available level ups
            if anyLevelupCrafted == false then
                for kk,vv in ipairs( v.level_up ) do
                    if not exists( craftedIds, vv ) then
                        table.insert( craftedLevelUp, vv )
                    end
                end
            else
                for kk,vv in ipairs( v.level_up ) do
                    if not exists( craftedIds, vv ) then
                        table.insert( levelUpMissed, vv )
                    end
                end
            end
        end
    end
    return crafted, craftedLevelUp, levelUpMissed
end

FindRequirement = function( id )
    for k,v in ipairs(EquipmentDefList) do
        if exists( v.level_up, id ) then 
            return v.id
        end
    end
    return nil
end