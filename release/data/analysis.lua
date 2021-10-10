require 'units/unit_factory'
require 'code/util'

--[[

============================================================

1小时，也许20关，关卡内怪物的分布，及带给玩家的体验。叙述如下：
*先假象以每3关为一个分界线。总关卡与分界线可以以后调整*
1. 1~2 关（3分钟）
   * 上手、热身关。不熟悉的玩家可以探索游戏机制，熟悉的玩家可以积攒到一些稳定的水晶作资本。10%概率出现特殊版本的普通傻傻怪物。
2. 3~5 关（10分钟）
   * 需要小技巧的怪，小陷阱。
   * 每关出现boss的概率为20%，30%，100%。10%概率会出现强力的怪物。
3. 6~8 关（20分钟）
   * 需要小技巧的怪（类别2），陷阱。每一关都会有一处强力怪。10%概率会出现小技巧怪以下的特殊怪。
   * 假装玩家没有很care水晶的使用，50%的时候没有采用最高效率，则玩家的水晶应该在这一关开始吃紧，并且如果死亡了，不会积攒下多少水晶。
   * 如果玩家有过度升级装备，则虽然直到这关都会玩得很轻松，但从这时候开始，水晶会入不敷出。
4. 9~12 关（30分钟）
   * 需要技巧的怪，需要特别小心的陷阱。30%的怪会是强力怪，其余的是需要技巧的怪。10%概率会出现强力怪以下的特殊怪。
   * 每关出现boss的概率为20%，30%，100%。10%概率会出现强力的怪物。这关的boss会难缠很多。boss有20%几率会是强化版本。
   * 如果有特别的武器，在这几关会容易一些。如果没有特别注意武器的升级，则这机关会变得非常困难。正确的使用武器是这机关的关键。
5. 13~16 关（45分钟）
   * 阴险的陷阱到处都是，60%会是强力怪，其它时候是需要技巧的怪。20%概率会出现强力怪以下的特殊怪。
   * 所有事情做完美了，才能在这几关幸存。玩家对游戏的了解跟操作需要做到完美。
6. 17~20 关（1小时）
   * 过多的怪，过多的陷阱，不公平的敌我比例（比如20个史莱姆都在屏幕上）。20%概率会出现强力怪以下的特殊怪（由于怪的数量，这个概率可能会需要降低）。
   * 即使是完美主义的玩家，都需要碰运气，每一步都需要思考，稍不注意就会受到很严重的惩罚。失误2次大概就没机会了。
   * 绝对绝命的boss，打败boss需要几次死在它刀下的经验。boss有20%几率会是强化版本。

============================================================

玩家在每个关卡的武器升级预测曲线
玩家在每个关卡的护盾升级预测曲线
玩家在每个关卡所需累计水晶曲线

玩家技巧对累计水晶曲线的影响。使用武器等级越高，累积水晶越少。使用武器等级越低，累积水晶越多。

玩家使用标准武器，过低武器，过高武器，分别计算累计水晶。
保证两关，或三关内，累计水晶会回到正常值。也就是说，两三关内，水晶累计的差值，会等于武器等级水晶需求的差值。

每一关的risk曲线，根据玩家武器护盾等级计算。
越往后面对risk的预期值是越高的。新手30%到普通100%到老手500%，boss关有risk spike。
老手应该可以负担更高级的武器。

根据risk需求，跟水晶累计需求，计算需要生成多少怪物，以及什么样的怪物。

从上面分析可以看出，武器等级跟水晶累积有关。而怪物设计则是为了配置出上面的曲线。

]]

-- 加载样本武器与护盾, index代表等级
local sampleWeapon = {}
for i = 1,3 do
    table.insert( sampleWeapon, FindEquipmentById( '剑'..i ) )
end
for i = 1,5 do
    --table.insert( sampleWeapon, FindEquipmentById( '重剑'..i ) )
end
local sampleShield = {}
for i = 1,5 do
    table.insert( sampleShield, FindEquipmentById( '护盾'..i ) )
end
-- 20 关卡内，玩家装备的理想值。数值代表等级
local expectedWeaponLevel = { 1,2, 3,4,5, 5,6,6, 7,7,8,8, 8,9,9,9, 10,10,10,10 }  -- 玩家在每个关卡的武器升级预测曲线
local expectedShieldLevel = { 1,2, 3,4,5, 5,6,6, 7,7,8,8, 8,9,9,9, 10,10,10,10 }  -- 玩家在每个关卡的护盾升级预测曲线
local expectedCrystalSum = {}   -- 玩家在每个关卡所需累计水晶曲线
local sampleWeaponAtt = {}
local sampleShieldEnergy = {}
for i = 1, 20 do
    local temp___sum_multi = 10--[[
    table.insert( expectedCrystalSum, ( Crystals_sum( sampleWeapon[ expectedWeaponLevel[i] ].cost ) + Crystals_sum( sampleShield[ expectedShieldLevel[i] ].cost ) ) * temp___sum_multi )
    table.insert( sampleWeaponAtt, sampleWeapon[ expectedWeaponLevel[i] ].att )
    table.insert( sampleShieldEnergy, sampleShield[ expectedShieldLevel[i] ].energy_power_max )]]
end

local expectedTotalRiskLevel = { 20 ,50 , 75 ,75 ,100 , 85 ,85 ,150 , 100 ,120 ,120 ,200 , 200 ,200 ,200 ,400 , 300 ,300 ,300 ,800  }
local expectedTotalUnitCount = { 12,12, 12, 12, 12, 15,15,15, 15, 15, 15, 15, 20,20,20,20, 20,20,20,20 }
local expectedUnitRiskLevel = {}
for i = 1, 20 do
    table.insert( expectedUnitRiskLevel, math.floor( expectedTotalRiskLevel[i] / expectedTotalUnitCount[i] ) )
end

local expectedUnitGain = {}
for i = 1, 20 do 
    table.insert( expectedUnitGain, math.floor( expectedCrystalSum[i] / expectedTotalUnitCount[i] * 10 ) / 10 )
end

Analysis_ExpectLevelGainAndRisk = function( level )
    return expectedCrystalSum[level], expectedTotalRiskLevel[level] / 100
end

local riskToleranceMin = 0.5
local riskToleranceMax = 2
local gainToleranceMin = 0.5
local gainToleranceMax = 2
local bossGainMultiplier = 5
local bossRiskMultiplier = 5

UnitMaster_Analysis_Export_All = function()

    print('')
    printArray( 'Analysis-CrystalSum', expectedCrystalSum )
    printArray( 'Analysis-WeaponLv', expectedWeaponLevel )
    printArray( 'Analysis-WeaponAtt', sampleWeaponAtt )
    printArray( 'Analysis-ShieldLv', expectedShieldLevel )
    printArray( 'Analysis-ShieldEnergy', sampleShieldEnergy )
    printArray( 'Analysis-UnitRisk', expectedUnitRiskLevel )
    printArray( 'Analysis-UnitGain', expectedUnitGain )
    print('')

    local allunits = UnitDef
    local summary = {}
    local levelUnitMap = {}
    for i = 1,20 do table.insert( levelUnitMap, {} ) end
    for kk,k in ipairs( UnitDefKey ) do
        local v = allunits[ k ]
        local c = merge( Config_Base, copy(v.cfg) )
        local line = '' .. c.img -- string.sub(c.img, 1,6)
        local line2 = '' .. c.img -- string.sub(c.img, 1,6)
        local line3 = '' .. c.img -- string.sub(c.img, 1,6)
        local line4 = '' .. c.img -- string.sub(c.img, 1,6)
        local line5 = '' .. c.img
        local level_min = 99
        local level_max = -1
        if k ~= GOAL and ( c.is_terrain == false or c.dropImg ~= nil ) then
            for i = 1,20 do
                local gain, risk = Analysis_UnitMaster( c, i )
                if c.analysis_is_boss then
                    gain = gain / bossGainMultiplier
                    risk = risk / bossRiskMultiplier
                end
                risk = risk -- to avoid 0 risk
                line = line .. '   ' .. string.format('%.1f', gain)
                line2 = line2 .. '   ' .. string.format('%.2f', risk)
                local allYes = true
                if gain <= expectedUnitGain[i] * gainToleranceMax and gain >= expectedUnitGain[i] * gainToleranceMin then 
                    line3 = line3 .. '   '..'Y'
                else 
                    line3 = line3 .. '   '..expectedUnitGain[i]
                    allYes = false
                end
                if risk == 0 then
                    line4 = line4 .. '   '.. '0'
                elseif risk * 100 <= expectedUnitRiskLevel[i] * riskToleranceMax and risk * 100 >= expectedUnitRiskLevel[i] * riskToleranceMin then 
                    line4 = line4 .. '   '..'Y'
                else 
                    line4 = line4 .. '   '.. string.format('%.2f', (expectedUnitRiskLevel[i] / 100)) 
                    allYes = false
                end
                if allYes then
                    level_min = math.min( level_min, i )
                    level_max = math.max( level_max, i )
                end
            end
            if risk ~= 0 or gain ~= 0 then 
                print( 'Analysis-Unit gainValue  ', line )
                print( 'Analysis-Unit gainTarget ', line3 )
                print( 'Analysis-Unit riskValue  ', line2 )
                print( 'Analysis-Unit riskTarget ', line4 )
                print('')
                if level_min ~= 99 or level_max ~= -1 then
                    table.insert( summary, line5 .. '   (level '..level_min.. ' - ' .. level_max .. ' )' )
                else
                    table.insert( summary, line5 .. '   (level '..level_min.. ' - ' .. level_max .. ' )' )
                end
                for i = level_min, level_max do
                    table.insert( levelUnitMap[i], c.img )
                end
            end
        end
    end
    print('')
    print('Units has valid setup for levels: ')
    printArrayAsLines( summary )
    print('')
    for k,v in ipairs( levelUnitMap ) do
        printArray( 'Level'..k, v )
    end
end

Analysis_UnitMaster = function( cfg, level )
    local hitC = cfg.analysis_hit_chance   -- how easy is it for this unit to attack the player
    local ambushC = cfg.analysis_ambush_chance -- how easy is it for this unit to ambush the player
    local att = sampleWeapon[expectedWeaponLevel[level]].att
    local att_cost = math.floor( Crystals_sum( sampleWeapon[ expectedWeaponLevel[level] ].recharge_cost ) * 10 ) / 10 -- preserve 1 decimal
    local analysis_gain = Crystals_sum(cfg)  -- how much to gain after killing this unit
    local analysis_kill_turn = math.ceil( cfg.hp / att )   -- how much does it cost to kill this unit, using level x weapon
    local analysis_kill_cost = analysis_kill_turn * att_cost
    local analysis_damage_potential = cfg.att * ambushC + cfg.att * hitC * analysis_kill_turn + cfg.analysis_child_damage * cfg.max_child / 2  -- how much damage is this unit likely to inflict to player, before it dies
    for k,v in ipairs( cfg.parts ) do
        analysis_damage_potential = analysis_damage_potential + v.att * v.analysis_ambush_chance + v.att * analysis_kill_turn * v.analysis_hit_chance
        analysis_gain = analysis_gain + Crystals_sum( v )
    end
    local unit_per_map = expectedTotalUnitCount[level]
    local shield_level = level * 1
    local player_hp = sampleShield[ expectedShieldLevel[level] ].energy_power_max
    local perfectGain = math.floor( (analysis_gain - analysis_kill_cost) * 10 ) / 10 -- preserve 1 decimal
    local risk = math.floor( ( analysis_damage_potential / ( player_hp ) ) * 100 ) / 100 -- risk of fight a map full of this unit
    return perfectGain, risk
end

Analysis_Level_Equipments = function( level )
    return sampleWeapon[expectedWeaponLevel[level]].id, sampleShield[ expectedShieldLevel[level] ].id
end
