require 'code/class'
require 'code/keycode'
require 'code/util'
require 'units/object'
require 'units/unit_ai'
require 'equipments/equipment_def'
local Tween = require 'code/tween' -- See https://github.com/kikito/tween.lua.

local gain = 2

UnitDef = {
    FIRE_REMAIN = {id = 149, 
        cfg = { img = 'fire_remain', layer = 1, is_terrain = true, is_tile = true, light_range = 1.1 }},
    DESERTED = {id = 32, 
        cfg = { img = 'deserted', layer = 1, is_terrain = true, is_static = true, is_tile = true }},
    GRASS = {id = 18, 
        cfg = { img = 'grasstiles', tile_family = 'ground', layer = 1, is_terrain = true, is_tile = true, is_static = true } },
    GROUND = {id = 0, 
        cfg = { img = 'solidstonetiles', tile_family = 'ground', layer = 1, is_terrain = true, is_tile = true, is_static = true } },
    MARSH = {id = 17, 
        cfg = { img = 'marsh', layer = 1, is_terrain = true, is_tile = true, is_static = true } },
    FOREST = { id = 4, 
        cfg = { img = 'forest', layer = 1, is_terrain = true, can_player_attack = true, can_trample = true, blocking = true, hp = 2, is_tile = true } },
    FOREST_REMAIN = { id = 6, 
        cfg = { img = 'forest_remain', layer = 1, is_terrain = true, is_static = true, is_tile = true } },
    MOUNTAIN = { id = 36, 
        cfg = { img = 'mountain', layer = 1, is_terrain = true, can_player_attack = true, can_trample = true, blocking = true, hp = 10, is_tile = true } },
    SNOWING_LAND = { id = 1001, 
         cfg = { img = 'river', layer = 1, is_terrain = true, can_trample = false, walked_on_damage = true, att = 1, att_img = 'blunt', att_effect_stun = 1, is_tile = true } },
    RIVER = { id = 54, 
    cfg = { img = 'river', layer = 1, is_terrain = true, blocking = true, can_trample = false, is_tile = true } },

    CRYSTAL1 = { id = 52,
        cfg = { img = 'crystal1', layer = 9, blocking = true, can_player_attack = true, hp = 1, dropImg = 'crystal5', crystal = 1 + gain } },
    CRYSTAL2 = { id = 51,
        cfg = { img = 'crystal2', layer = 9, blocking = true, can_player_attack = true, hp = 1, dropImg = 'crystal5', crystal = 1 + gain } },
    CRYSTAL3 = { id = 66,
        cfg = { img = 'crystal3', layer = 9, blocking = true, can_player_attack = true, hp = 1, dropImg = 'crystal5', crystal = 1 + gain } },
    CRYSTAL5 = { id = 50,
        cfg = { img = 'crystal5', layer = 9, blocking = true, can_player_attack = true, hp = 1, dropImg = 'crystal5', crystal = 1 + gain } },
    CRYSTAL2A = { id = 2,
        cfg = { img = 'crystal2a', layer = 9, blocking = true, can_player_attack = true, hp = 1, dropImg = 'crystal5', crystal = 1 + gain } },
    CRYSTAL2B = { id = 3,
        cfg = { img = 'crystal2b', layer = 9, blocking = true, can_player_attack = true, hp = 1, dropImg = 'crystal5', crystal = 1 + gain } },

    SWORD = { id = 20,
        cfg = { img = 'sword', layer = 9, pickup_equipment = '白板武器', is_pickup = true } },
    SHIELD = { id = 22,
        cfg = { img = 'shield_white', layer = 9, pickup_equipment = '白板护盾', is_pickup = true } },
    BADGE = { id = 38,
        cfg = { img = 'badge_white', layer = 9, pickup_equipment = '白板徽章', is_pickup = true } },


    -- 蜘蛛网, 这个地形会stun玩家。被踩两次后会消失。
    SPIDER_WEB = { id = 134,
        cfg = { img = 'spider_web', layer = 10, can_trample = false, walked_on_damage = true, hp = 2, att_effect_stun = 2, att_self_damage = 1 } },

    -- 一个2x2的有固定动作，但威力很大的boss，发现玩家后，直线冲过去，直到碰到障碍物
    SLIMEKING = { id = 64, ids = {64, 65,80,81},
        cfg = { img = 'slime_king', isGridBase = false, layer = 11, blocking = true, can_player_attack = false, alarm_range = 2, width = 3, height = 3, att_trample = 8, att_trample_max = 4, att_trample_stun = 1, 
        is_boss = true, hp = 30, ai = AI_Charge, analysis_is_boss = true, is_stationary = false,
        parts = {
            { x = 0, y = 0, layer = 11, blocking = true, can_player_attack = true, att = 4, analysis_hit_chance = 0.1 / 4, analysis_ambush_chance = 0.3 / 4, att_img = 'blunt', att_terrain = 5, dropImg = 'crystal2', crystal = 10 },
            { x = 1, y = 0, layer = 11, blocking = true, can_player_attack = true, att = 4, analysis_hit_chance = 0.1 / 4, analysis_ambush_chance = 0.3 / 4, att_img = 'blunt', att_terrain = 5, dropImg = 'crystal2', crystal = 5 + gain },
            { x = 2, y = 0, layer = 11, blocking = true, can_player_attack = true, att = 4, analysis_hit_chance = 0.1 / 4, analysis_ambush_chance = 0.3 / 4, att_img = 'blunt', att_terrain = 5, dropImg = 'crystal2', crystal = 2 + gain * 2 },
            { x = 0, y = 2, layer = 11, blocking = true, can_player_attack = true, att = 4, analysis_hit_chance = 0.1 / 4, analysis_ambush_chance = 0.3 / 4, att_img = 'blunt', att_terrain = 5, dropImg = 'crystal2', crystal = 3 + gain * 2 },
            { x = 0, y = 1, layer = 11, blocking = true, can_player_attack = true, att = 4, analysis_hit_chance = 0.1 / 4, analysis_ambush_chance = 0.3 / 4, att_img = 'blunt', att_terrain = 5, dropImg = 'crystal2', crystal = 1 + gain },
            { x = 1, y = 1, layer = 11, blocking = true, can_player_attack = true, att = 4, analysis_hit_chance = 0.1 / 4, analysis_ambush_chance = 0.3 / 4, att_img = 'blunt', att_terrain = 5, dropImg = 'crystal1', crystal = 1 + gain },
            { x = 1, y = 2, layer = 11, blocking = true, can_player_attack = true, att = 4, analysis_hit_chance = 0.1 / 4, analysis_ambush_chance = 0.3 / 4, att_img = 'blunt', att_terrain = 5, dropImg = 'crystal1', crystal = 1 + gain },
            { x = 2, y = 1, layer = 11, blocking = true, can_player_attack = true, att = 4, analysis_hit_chance = 0.1 / 4, analysis_ambush_chance = 0.3 / 4, att_img = 'blunt', att_terrain = 5, dropImg = 'crystal1', crystal = 1 + gain },
            { x = 2, y = 2, layer = 11, blocking = true, can_player_attack = true, att = 4, analysis_hit_chance = 0.1 / 4, analysis_ambush_chance = 0.3 / 4, att_img = 'blunt', att_terrain = 5, dropImg = 'crystal1', crystal = 1 + gain }
    } } },

    POT_GOLD = { id = 168,
        cfg = { img = 'pot_gold', layer = 10, blocking = true, event = 'save_crystals' }
    },

    BONFIRE = { id = 56,
        cfg = { img = 'bonfire', layer = 10, blocking = true, event = 'pray', light_range = 2 }
    },

    TOWER_TECH = { id = 101,
        cfg = { img = 'tower_tech', layer = 9, blocking = true, can_player_attack = true, hp = 5, dropImg = 'crystal5', crystal = 5 + gain * 3, light_range = 2 } },

    PILLAR_HEAL = { id = 101,
        cfg = { img = 'tower_tech', layer = 9, blocking = true, can_player_attack = true, hp = 5, dropImg = 'crystal5', crystal = 5 + gain * 3, light_range = 2 } },

    BLUE_COIN = { id = 100,
    cfg = { img = 'blue_coin', layer = 9, blocking = true, can_player_attack = true, hp = 1, dropImg = 'crystal5', shield = 20 } },

    -- 露天水晶矿
    CRYSTAL_ORE = { id = 1, 
        cfg = { img = 'crystal_ore', layer = 9, blocking = true, can_player_attack = true, hp = 5, dropImg = 'crystal5', crystal = 5 + gain * 3, light_range = 1.2 } },

    POT_STONE = {
        id = 169, cfg = { img = 'stone_pot', layer = 9, blocking = true, can_player_attack = true, hp = 2, no_shield_block = true, dropImg = 'crystal5', crystal = 0, crystal_collector = true }
    },

    -- 毛刺陷阱，起落起落，在其升起的时候，可以看用攻击消灭
    SPIKE = { id = 135,
        cfg = { img = 'spike', layer = 10, blocking = true, att = 10, att_img = 'blunt', dropImg = 'crystal1',   
        ai = AI_StepOnShow, hide_max = 3, show = 2, show_max = 2, walked_on_damage = true,
        analysis_hit_chance = 0.7, analysis_ambush_chance = 1.5 } },
        
    -- 发现玩家后，直线冲过去，直到碰到障碍物
    ROCK = { id = 102,
        cfg = { img = 'rock', layer = 10, blocking = true, alarm_range = 2, width = 1, height = 1, att_trample = 10, att_trample_max = 2, att_trample_stun = 1, 
        att = 10, att_img = 'blunt', att_terrain = 5, dropImg = 'crystal2', ai = AI_Charge,
        analysis_hit_chance = 0.4, analysis_ambush_chance = 0.5 } }
}

UnitDef['SMOKING_POT1'] = {
    id = 170, cfg = { img = 'smoking_pot1', layer = 9, blocking = true, can_player_attack = true, hp = 10, dropImg = 'crystal5', crystal = 0, 
        summon_monster_white = 'WOLF_GANG', summon_level = 0, summon_count = 4, die_summon = true, level = {}, is_drop_badge = true }
}
for i = 1,10 do
    table.insert( UnitDef['SMOKING_POT1'].cfg.level, { hp = 2, summon_level = i } )
end

-- 绕九宫格顺时针走的史莱姆
UnitDef['SLIME'] = { id = 16,
    cfg = { img = 'slime2', layer = 10, blocking = true, can_player_attack = true, is_stationary = false,
    hp = 2, att = 2, att_img = 'blunt', dropImg = 'crystal2', crystal = 6, ai = AI_Loop,
    analysis_hit_chance = 0.3, analysis_ambush_chance = 0, level = {} } }
for i = 1,9 do
    table.insert( UnitDef['SLIME'].cfg.level, { hp = 1 + i, att = 1 + i, crystal = 1 + gain + i } )
end

-- 普通傻傻的怪，没有攻击力，走十字形
UnitDef['SHEEP'] = { id = 69, 
    cfg = { img = 'sheep', layer = 10, blocking = true, can_player_attack = true, hp = 3, dropImg = 'crystal1', crystal = 3, 
    att_img = 'blunt', is_stationary = false,
    ai = AI_Wonder, aiPath = { { x = -1, y = 0 }, { x = 1, y = 0 }, { x = 1, y = 0 }, { x = -1, y = 0 }, { x = 0, y = 0 }, 
    { x = 0, y = -1 }, { x = 0, y = 1 }, { x = 0, y = 1 }, { x = 0, y = -1 }, { x = 0, y = 0 } } , level = {} } }
for i = 1,10 do
    table.insert( UnitDef['SHEEP'].cfg.level, { hp = 1 + i, att = 1 + i, crystal = 1 + gain + i } )
end
-- 普通的傻傻的怪，大白菜怪-被打之后会反击
UnitDef['CABAGE'] = { id = 84,
    cfg = { img = 'cabage', layer = 10, blocking = true, can_player_attack = true, hp = 10, att = 2, att_img = 'blunt', dropImg = 'crystal2', crystal = 7, is_stationary = false,
    ai = AI_Passive_ConterAttack,
    analysis_hit_chance = 1, analysis_ambush_chance = 0 , level = {} } }
for i = 1,10 do
    table.insert( UnitDef['CABAGE'].cfg.level, { hp = 1 + i, att = 3 + i, crystal = 1 + gain + i } )
end
-- 斜线跑来跑去的鱼，没有攻击力
UnitDef['FISH'] = { id = 86, 
    cfg = { img = 'fish', layer = 10, blocking = true, can_player_attack = true, hp = 1, att = 0, att_img = 'blunt', dropImg = 'crystal1', crystal = 2, is_stationary = false,
    ai = AI_Wonder, aiPath = { { x = -1, y = -1 }, { x = -1, y = -1 }, { x = -1, y = -1 }, { x = -1, y = -1 }, { x = 1, y = 1 }, { x = 1, y = 1 }, { x = 1, y = 1 }, { x = 1, y = 1 } },
    analysis_hit_chance = 0.7, analysis_ambush_chance = 1.5 , level = {} } }
for i = 1,10 do
    table.insert( UnitDef['FISH'].cfg.level, { hp = 1 + i, att = 1 + i, crystal = 1 + gain + i } )
end
-- 斜十字线飞的蝙蝠
UnitDef['BAT'] = { id = 85,
    cfg = { img = 'bat', layer = 10, blocking = true, can_player_attack = true, hp = 5, att = 8, att_img = 'blunt', dropImg = 'crystal1', crystal = 10, is_stationary = false,
    ai = AI_Wonder, aiPath = { { x = -1, y = -1 }, { x = 1, y = 1 }, { x = 1, y = 1 }, { x = -1, y = -1 }, 
    { x = 1, y = -1 }, { x = -1, y = 1 }, { x = -1, y = 1 }, { x = 1, y = -1 },
    analysis_hit_chance = 0.3, analysis_ambush_chance = 0 } , level = {} } }
for i = 1,10 do
    table.insert( UnitDef['BAT'].cfg.level, { hp = 1 + i, att = 2 + i, crystal = 1 + gain + i } )
end
-- 有护甲的怪
UnitDef['ROCK_MAN'] = { id = 103,
    cfg = { img = 'rock_man', layer = 10, blocking = true, can_player_attack = true, hp = 10, alarm_range = 1, width = 1, height = 1, att_trample = 10, att_trample_max = 1, att_trample_stun = 1, 
    att = 10, att_img = 'blunt', att_terrain = 5, dropImg = 'crystal2', ai = AI_Charge, level = {} } }
for i = 1,10 do
    table.insert( UnitDef['ROCK_MAN'].cfg.level, { hp = 2 + i, att = 2 + i, crystal = 2 + gain + i } )
end

-- 时不时会躲起来，时不时又会冒出来的地鼠。玩家在它埋在地下的时候，靠近会受到攻击
UnitDef['DIG_MOUSE'] =  { id = 116,
    cfg = { img = 'digmouse', layer = 10, blocking = true, can_player_attack = true, hp = 10, att = 5, att_img = 'blunt', dropImg = 'crystal1', crystal = 18,  is_stationary = false,
    ai = AI_UnhideAttack,  hide_max = 4, show = 3, show_max = 3,
    analysis_hit_chance = 0.8, analysis_ambush_chance = 1 , level = {} } }
for i = 1,10 do
    table.insert( UnitDef['DIG_MOUSE'].cfg.level, { hp = 1 + i, att = 3 + i, crystal = 1 + gain + i } )
end
-- 时不时会躲起来，时不时又会冒出来的草。没有攻击力
UnitDef['SHY_GRASS'] = { id = 121,
    cfg = { img = 'shygrass', layer = 10, blocking = true, can_player_attack = true, hp = 3, dropImg = 'crystal1', crystal = 3, 
    hide_max = 8, show = 1, show_max = 1 , is_stationary = false,level = {} } }
for i = 1,10 do
    table.insert( UnitDef['SHY_GRASS'].cfg.level, { hp = 0 + i, att = 3 + i, crystal = gain + i } )
end
-- 狗gang，绷带背后插刀。喜欢围殴。
UnitDef['DOG_GANG'] = { id = 114,
    cfg = { img = 'dog_gang', layer = 10, blocking = true, can_player_attack = true, hp = 18, att = 4, dropImg = 'crystal2', crystal = 20, 
    ai = AI_GANG_TRACKER, alarm_ally_range = 4,is_stationary = false,
    analysis_hit_chance = 1, att_img = 'blunt', analysis_ambush_chance = 0 , level = {} } }
for i = 1,10 do
    table.insert( UnitDef['DOG_GANG'].cfg.level, { hp = 1 + i, att = 0 + i, crystal = 1 + gain + i } )
end
-- 狼gang，墨镜西装。喜欢围殴。
UnitDef['WOLF_GANG'] = { id = 115,
    cfg = { img = 'wolf_gang', layer = 10, blocking = true, can_player_attack = true, hp = 20, att = 12, dropImg = 'crystal2', crystal = 40, is_stationary = false,
    ai = AI_GANG_TRACKER, att_img = 'blunt', alarm_ally_range = 2,
    analysis_hit_chance = 1, analysis_ambush_chance = 0 , level = {} } }
for i = 1,10 do
    table.insert( UnitDef['WOLF_GANG'].cfg.level, { hp = 0 + i, att = 1 + i, crystal = gain + i } )
end
-- 蜘蛛巢，在打掉之前，周围会有最多三只在巢四周随机移动的小蜘蛛，会补充。
UnitDef['SPIDER_CAVE'] = { id = 119,
    cfg = { img = 'spider_cave', layer = 9, blocking = true, can_player_attack = true, hp = 50, dropImg = 'crystal5', crystal = 20, 
    ai = AI_MONTHER, child_id = 118, max_child = 8, born_interval = 2, analysis_child_damage = 2 , level = {} } }
for i = 1,10 do
    table.insert( UnitDef['SPIDER_CAVE'].cfg.level, { hp = i * 2, crystal = i * 2 + gain * 3 } )
end
-- 在巢四周随机移动的小蜘蛛
UnitDef['SPIDERLING'] = { id = 118,
    cfg = { img = 'spiderling', layer = 10, blocking = true, can_player_attack = true, hp = 1, att = 8, att_img = 'blunt', hasParent = true, is_stationary = false,
    ai = AI_Wonder, aiPath = { { x = 0, y = -1 }, { x = 0, y = 1 }, { x = 1, y = 0 }, { x = -1, y = 0 } },
    analysis_hit_chance = 0.2, analysis_ambush_chance = 0 , level = {} } }
for i = 1,10 do
    table.insert( UnitDef['SPIDERLING'].cfg.level, { hp = 1, att = math.ceil( i * 0.5 ) } )
end
-- 影，会瞬移出现在玩家身旁，被攻击后再瞬移离开。有CD的武器对付起来会比较辛苦
UnitDef['SHADOW'] = { id = 117,
    cfg = { img = 'shadow', layer = 10, blocking = true, can_player_attack = true, hp = 12, att = 16, dropImg = 'crystal2', crystal = 40, att_img = 'blunt', is_stationary = false,
    ai = AI_BLINK_ASSASIN, blink_range_min = 3, blink_range_max = 5, alarm_range = 3,
    analysis_hit_chance = 0.5, analysis_ambush_chance = 0.8 , level = {} } }
for i = 1,10 do
    table.insert( UnitDef['SHADOW'].cfg.level, { hp = i, att = 10, crystal = i + gain } )
end

PLAYER = { id = 19 }
GOAL = { id = 21, cfg = { img = 'goal', layer = 2, is_terrain = true } }

UnitDef['PLAYER'] = PLAYER
UnitDef['GOAL'] = GOAL

UnitDefKey = { 'SLIME', 'SHEEP', 'CABAGE', 'FISH', 'BAT', 'SPIKE', 'DIG_MOUSE', 'SHY_GRASS', 'ROCK', 
    'DOG_GANG', 'WOLF_GANG', 'SPIDER_CAVE', 'SHADOW', 'SLIMEKING', 'CRYSTAL_ORE', 'CRYSTAL1', 'CRYSTAL2', 'CRYSTAL3', 'CRYSTAL5', 
    'POT_STONE', 'POT_GOLD', 'BONFIRE', 'BLUE_COIN', 'SPIER_WEB', 'TOWER_TECH', 'ROCK_MAN', 'PILLAR_HEAL', 'PLAYER', 'GOAL' }


UnitFactory_DefByIdMap = {}
for k,v in pairs( UnitDef ) do 
    while #UnitFactory_DefByIdMap < v.id do
        table.insert( UnitFactory_DefByIdMap, {} )
    end
    UnitFactory_DefByIdMap[v.id] =  v
end

UnitFactory_GetUnitFullDefById = function( id )
    local v = UnitFactory_DefByIdMap[id]
    if v ~= nil then
        return merge( Config_Base, copy(v.cfg) )
    end
    return nil
end

Config_Base = { 
    type = 'xxx', img = '', layer = 0, ai = nil, curLevel = -2, level = {},
    blocking = false, 
    is_terrain = false, -- can affect att damage (拥有地形破坏能力的武器有的时候会有伤害加成)
    can_player_attack = false, can_trample = false, is_boss = false, is_pickup = false, 
    is_stationary = true, -- 是否会在攻击时做出移动动画
    is_tile = false, -- 该属性为false的单位在生成的时候不能overlap
    tile_family = nil, -- 根据周围同种类地块，应用地块渲染的边角逻辑
    is_bullet = false, -- 该属性为true的单位在生成的时候可以overlap，无视is_tile属性
    hp = 0, shield = 0, shield_max = 0, sheild_generate = 0, no_shield_block = false, 
    att = 0, att_terrain = 0, att_img = '', att_effect_stun = 0, att_self_damage = 0,
    dropImg = nil, crystal = 0, crystal_white = false,
    width = 1, height = 1, shape = { x = 0, y = 0 }, 
    stun = 0, att_self_stun_max = 0, move_self_stun_max = 0, att_trample = 0, att_trample_max = 0, att_trample_stun = 0,
    alarmed = false, alarm_range = 0, alarm_ally_range = 0,
    curDx = 0, curDy = 0, -- moving in current directing, two 0 means not moving in current direction
    aiLazy = false, aiPath = {}, aiStep = 0, aiStepDir = 1,-- the step that AI is on currently
    aiX = 0, aiY = 0, -- the tile where the unit is supposed to center its AI on
    aiKilled = nil,
    angry = 0, -- add one after been attacked
    hide = 0, hide_max = 0, show = 0, show_max = 9999,
    blink_range_min = 0, blink_range_max = 0,
    walked_on_damage = false,
    parts = {}, owner = nil, child = {}, parent = nil, max_child = 0, child_id = -1, born_interval = 1, born = 0, hasParent = false, 
    summon_monster_white = nil, die_summon = false, summon_level = 0, summon_count = 0,
    seen = false, light_range = 0, isGridBase = true,
    crystal_collector = false, crystal_collected = copy( CRYSTALS ),-- crystal collector will attract all the crystals around
    pickup_equipment = nil,
    is_drop_badge = false, -- whether will drop a blank badge for special skills
    -- analysis fields
    analysis_hit_chance = 0,   -- how easy is it for this unit to attack the player
    analysis_ambush_chance = 0,   -- how easy is it for this unit to ambush the player
    analysis_child_damage = 0, -- how much damage can the unit's children afflicted to player
    analysis_is_boss = false, -- boss will have a different tolerance level
}

getVacancy = function( posList, x, y)
    local r = {}
    for k,v in ipairs( posList ) do
        local xx = v.x + x
        local yy = v.y + y
        if game:canCreateUnit( xx, yy ) then
            table.insert( r, v )
        end
    end
    return shuffle( r )
end

UnitFactory_CreateUnit = function ( id, x, y, createAtCenter, count, level, parent, cfgOverwrite )
    if DEBUG_UNIT_GENERATE then print( 'creating unit ', id, x, y, count, level ) end
    -- if level is -1 this means that a random level of 1~10 needs to be generated
    if level <= 0 then
        level = math.random(1,10)
    end

    -- print('', 'UnitFactory-creating id: '..id )

    local v = UnitFactory_DefByIdMap[id]
    if v == nil then warn( 'id'..id..' x'..x, ' y'..y..' '..Debug.trace()) end
    local c = merge( Config_Base, copy(v.cfg) )
    if c.is_terrain then
        if DEBUG_HIDE_TERRAIN == false then
            UnitMaster.new( 'tile.'..c.img, c, x, y, level, cfgOverwrite )
        end
    else
        local header = 'unit.'
        -- find 8 grids around to generate units
        local va = getVacancy( adjust8, x, y )
        if c.ai == AI_Loop or createAtCenter then
            -- add center location
            va = concat( {{ x = 0, y = 0 }}, va )
        end
        va = take( va, count )
        if #c.parts > 0 then 
            header = 'boss.' 
            -- boss can only appear at one point and can only generate 1 boss
            va = {{ x = 0, y = 0 }}
        end
        -- for all location that can generate a unit
        for k,v in ipairs( va ) do
            -- check conditions for not to create the unit
            local posX, posY = x + v.x, y + v.y
            local canCreate = game:canCreateUnit( posX, posY )
            if posX < 0 or posX > MapTile_WH-1 or posY < 0 or posY > MapTile_WH-1 then
                canCreate = false
            end

            if canCreate then
                if parent ~= nil then
                    -- assign parent for parts of a boss
                    c.parent = parent
                end
                c.aiX, c.aiY = x, y
                -- create a normal unit
                UnitMaster.new( header..c.img, c, posX, posY, level, cfgOverwrite )
            else
                warn( '', 'Not creating unit for '..c.img..'x'..posX..'y'..posY )
            end
        end
    end
    
    ---------------------- 其它 --------------------------
    if id == PLAYER.id then
        game.player = Player.new( x, y )
    elseif id == GOAL.id then
        game.goal = UnitMaster.new( 'tile.goal', { img = 'goal', layer = 2, is_terrain = true }, x, y, 1 )
    end
end