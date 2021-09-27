
function asserttest( check )
    if check then
        Debug.setBreakpoint('code/util.lua', 4, true)
        warn(Debug.trace())
    end
	local a = 0
	a = a + 1
end

local builtinIpairs = ipairs
ipairs = function (arg)
    if arg == nil then
        error('Table expected.' .. Debug.trace())
    end

    return builtinIpairs(arg)
end

local builtinPairs = pairs
pairs = function (arg)
    if arg == nil or type(arg) == 'number' then
        error('Table expected.' .. Debug.trace())
    end

    return builtinPairs(arg)
end

selectRandomObjByWeight = function( objListWithWeight, weightKey )
	local weightSum = 0
	for k,v in ipairs(objListWithWeight) do
		weightSum = weightSum + v[weightKey]
	end
	local targetWeightCount = math.random( 0, weightSum )
	local curWeightCount = 0
	for k,v in ipairs(objListWithWeight) do
		curWeightCount = curWeightCount + v[weightKey]
		if curWeightCount >= targetWeightCount then
			return v
		end
	end
end

init2dArray = function( w, h )
	local board = {}
	for i = 1, w do
		local newCol = {}
		for j = 1, h do
			table.insert( newCol, {} )
		end
		table.insert( board, newCol )
	end
	return board
end

loadJson = function( filepath )
	print( 'loading...', '', filepath )
	local bytes = Project.main:read( filepath )
	local js = bytes:readString()
	-- print( 'loading...', '', js )
	if js == '' or js == nil then 
		print( file, '', 'res data not found, returning default' )
		return {} 
	end
	local json = Json.new()
	local o = json:toTable( json:fromString(js) )
	return o
end

printArray = function( prefix, arr )
    l = ''
    for i = 1,#arr do
		if i ~= 1 then l = l .. ', 'end
        l = l .. arr[i]
    end
    print( '', prefix, l )
end

printArrayAsLines = function( arr )
    for i = 1,#arr do
		print( '', arr[i] )
    end
end

local printRecord = {}
printOnce = function( ... )
    local args = table.pack(...)
	local string = ''
    for i = 1, args.n do
        string = string .. tostring(args[i]) .. "\t"
    end
	if not exists( printRecord, string ) then
		table.insert( printRecord, string )
		print( ... )
	end
end

local pressed = {}

function keyClick( k )
	if key(k) and pressed[k] == nil then
		pressed[k] = 1
		return true
	end
	if keyp(k) and pressed[k] ~= nil then
		pressed[k] = nil
	end
	return false
end

local lastMouse = false
function mouseClick( k )
	if lastMouse == true and k == false then 
		lastMouse = k
		return true 
	end
	lastMouse = k
	return false
end

adjust8 = { {x = 0, y = -1}, {x = 1, y = -1}, {x = 1, y = 0}, {x = 1, y = 1}, {x = 0, y = 1}, {x = -1, y = 1}, {x = -1, y = 0}, {x = -1, y = -1} }
adjust4 = { {x = 0, y = -1}, {x = 1, y = 0},{x = 0, y = 1}, {x = -1, y = 0} }

function copy(obj, seen)
    if type(obj) ~= 'table' then return obj end
    if seen and seen[obj] then return seen[obj] end
    local s = seen or {}
    local res = setmetatable({}, getmetatable(obj))
    s[obj] = res
    for k, v in pairs(obj) do res[copy(k, s)] = copy(v, s) end
    return res
end

function sort(lst, pred)
	local keys = {}
	for key, _ in pairs(lst) do
		table.insert(keys, key)
	end
	table.sort(keys, function(keyLhs, keyRhs) 
		return pred( lst[keyLhs], lst[keyRhs] ) 
	end)
	result = {}
	for _, key in ipairs(keys) do
		table.insert( result, lst[key] )
	end
	return result
end
  
function tablelength(T)
    local count = 0
    for _ in pairs(T) do count = count + 1 end
    return count
end

function tablefind(tab,el)
    for index, value in pairs(tab) do
        if value == el then
            return index
        end
    end
end

function intersect( lst1, lst2 )
	local result = {}
	for k,v in ipairs( lst1 ) do
		if exists( lst2, v ) then
			table.insert( result, v )
		end
	end
	return result
end

function mysplit (inputstr, sep)
	if sep == nil then
		sep = "%s"
	end
	local t={}
	for str in string.gmatch(inputstr, "([^"..sep.."]+)") do
		table.insert(t, str)
	end
	return t
end

--[[
    https://stackoverflow.com/questions/17084532/avoiding-lua-callback-hell
    await(transition.to)(obj)
    await(transition.to)(obj)
    if foo then
        await(transition.to)(obj)
    else
        await(transition.to)(obj)
    end
]] 
await = function(f)
    return function(...)
        local self = coroutine.running()
        f(..., {onComplete=function(...)
           coroutine.resume(self, ...)
        end})
        return coroutine.yield()
    end
end

--[[
    https://stackoverflow.com/questions/17084532/avoiding-lua-callback-hell
    async_call(function(cont) 
        transition.to(obj, {onComplete=cont}) 
    end) 
]] 
async_call = function(f)
    local self = coroutine.running()
    local is_async
    local results = nil
    local async_continue = function(...)
        if coroutine.running() ~= self then
            is_async = true
            coroutine.resume(self, ...)
        else
            is_async = false
            results = {...}
        end
    end
    f(async_continue)
    if is_async then
        return coroutine.yield()
    else
        return unpack(results)
    end
end

-- function shuffle(array)
--     -- fisher-yates
--     local output = { }
--     local random = math.random

--     for index = 1, #array do
--         local offset = index - 1
--         local value = array[index]
--         local randomIndex = offset*random()
--         local flooredIndex = randomIndex - randomIndex%1

--         if flooredIndex == offset then
--             output[#output + 1] = value
--         else
--             output[#output + 1] = output[flooredIndex + 1]
--             output[flooredIndex + 1] = value
--         end
--     end

--     return output
-- end

function RotateMatrix(matrix, n)
    local ret = {}
    for ii = 1,n do
        table.insert( ret, {} )
    end
    for i = 1,n do
        for j = 1,n do
            ret[i][j] = matrix[j][n - i + 1]
        end
    end
    return ret
end

--[[
    A B         B D
    C D         A C
]]
function ReverseRotateMatrix(matrix, n)
    local ret = {}
    for ii = 1,n do
        table.insert( ret, {} )
    end
    for i = 1,n do
        for j = 1,n do
            ret[i][j] = matrix[n - j][i]
        end
    end
    return ret
end


--[[
Hyper Dungeon Crawler

Copyright (C) 2021 Tony Wang, all rights reserved

Homepage: https://paladin-t.github.io/games/hdc/
]]

--[[ Maths. ]]

function NaN(val)
	return 0 / 0
end

function isNaN(val)
	return val ~= val
end

function sign(val)
	if val > 0 then
		return 1
	elseif val < 0 then
		return -1
	else
		return 0
	end
end

function clamp(val, min, max)
	if val < min then
		val = min
	elseif val > max then
		val = max
	end

	return val
end

function lerp(val1, val2, factor)
	return val1 + (val2 - val1) * factor
end

--[[ String. ]]

function startsWith(str, part)
	return part == '' or string.sub(str, 1, #part) == part
end

function endsWith(str, part)
	return part == '' or string.sub(str, -#part) == part
end

function format(key, ...)
	local fmt = key
	if fmt == nil then
		return nil
	end

	local args = table.pack(...)
	for i = 1, #args do
		fmt = fmt:gsub('%' .. '{' .. tostring(i) .. '}', tostring(args[i]))
	end

	return fmt
end

--[[ List. ]]

function car(lst)
	if not lst or #lst == 0 then
		return nil
	end

	return lst[1]
end

function cdr(lst)
	if not lst or #lst == 0 then
		return { }
	end
	lst = table.pack(table.unpack(lst))
	table.remove(lst, 1)

	return lst
end

function rep(elem, n)
	local result = { }
	for i = 1, n, 1 do
		table.insert(result, elem)
	end

	return result
end

function concat(first, second)
	if first == nil and second == nil then
		return nil
	end
	local result = { }
	if first ~= nil then
		for _, v in ipairs(first) do
			table.insert(result, v)
		end
	end
	if second ~= nil then
		for _, v in ipairs(second) do
			table.insert(result, v)
		end
	end

	return result
end

function indexOf(lst, elem)
	if not lst then
		return -1
	end
	for i, v in ipairs(lst) do
		if v == elem then
			return i
		end
	end

	return -1
end

function exists(lst, elem)
	if not lst then
		return false
	end
	for _, v in ipairs(lst) do
		if v == elem then
			return true
		end
	end

	return false
end

function remove(lst, elem)
	if not lst then
		return false
	end
	for i, v in ipairs(lst) do
		if v == elem then
			table.remove(lst, i)

			return true
		end
	end

	return false
end

function clear(lst)
	if not lst then
		return
	end
	while #lst > 0 do
		table.remove(lst)
	end
end

function once(lst, idx)
	local item = lst[idx]
	table.remove(lst, idx)

	return item, idx
end

function any(lst, random)
	if not lst or #lst == 0 then
		return nil, nil
	end
	local idx = 0
	if random then
		idx = random:next(#lst)
	else
		idx = math.random(#lst)
	end
	local item = lst[idx]

	return item, idx
end

function anyOnce(lst, random)
	if not lst or #lst == 0 then
		return nil, nil
	end
	local idx = 0
	if random then
		idx = random:next(#lst)
	else
		idx = math.random(#lst)
	end

	return once(lst, idx)
end

function shuffle(lst, random)
	local result = concat(lst, nil)
	for i = 1, #result do
		local idx1, idx2 = 0, 0
		if random then
			idx1 = random:next(#lst)
			idx2 = random:next(#lst)
		else
			idx1 = math.random(#lst)
			idx2 = math.random(#lst)
		end
		result[idx1], result[idx2] = result[idx2], result[idx1]
	end

	return result
end

function associate(lst, pred)
	if not lst then
		return nil
	end
	local result = { }
	for i, v in ipairs(lst) do
		local key, val = pred(v, i)
		if key ~= nil and val ~= nil then
			result[key] = val
		end
	end

	return result
end

function transform(lst, pred)
	if not lst then
		return nil
	end
	local result = { }
	for i, v in ipairs(lst) do
		table.insert(result, pred(v, i))
	end

	return result
end

function reduce(lst, pred, initial)
	if not lst then
		return nil
	end
	local result = initial
	for i, v in ipairs(lst) do
		result = pred(v, i, result)
	end

	return result
end

function filter(lst, pred)
	if not lst then
		return nil
	end
	local result = { }
	for _, v in ipairs(lst) do
		if pred and pred(v) then
			table.insert(result, v)
		elseif not pred and not v then
			return { }
		end
	end

	return result
end

function only(lst, pred, proc)
	if not lst then
		return nil, nil
	end
	for i, v in ipairs(lst) do
		if pred and pred(v) then
			if proc then
				proc(v, i)
			end

			return v, i
		end
	end

	return nil, nil
end

function forEach(lst, pred)
	if not lst or not pred then
		return
	end
	for i, v in ipairs(lst) do
		if pred then
			pred(v, i)
		end
	end
end

function take(lst, n)
	local result = { }
	if lst ~= nil then
		for i = 1, math.min(#lst, n) do
			table.insert(result, lst[i])
		end
	end

	return result
end

function skip(lst, n)
	local result = { }
	if lst ~= nil then
		for i = n + 1, math.min(#lst) do
			table.insert(result, lst[i])
		end
	end

	return result
end

--[[ Dictionary. ]]

function clone(dict)
	if dict == nil then
		return nil
	end
	local result = { }
	if dict then
		for k, v in pairs(dict) do
			result[k] = v
		end
	end

	return result
end

function merge(first, second)
	if first == nil and second == nil then
		return nil
	end
	if second == nil then
		return first
	end
	local result = { }
	if first then
		for k, v in pairs(first) do
			result[k] = v
		end
	end
	if second then
		if t ~= nil and type(t) ~= "table" then warn('merge second not a table ' .. '-' .. type(t) .. '-' ..Debug.trace()) end
		if second[1] ~= nil then 
			warn('merge second not a key indexed table 1:' .. second[1] .. ' ' ..Debug.trace()) 
		end
		for k, v in pairs(second) do
			result[k] = v
		end
	end

	return result
end

--[[ Misc. ]]

if not DEBUG then
	function assert(cond, msg)
		if not cond then
			warn(msg)
		end
	end
end
