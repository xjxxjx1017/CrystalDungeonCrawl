--[[
The MIT License

Copyright (C) 2021 Jackson Xie

Permission is hereby granted, free of charge, to any person obtaining a copy of
this software and associated documentation files (the "Software"), to deal in
the Software without restriction, including without limitation the rights to
use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of
the Software, and to permit persons to whom the Software is furnished to do so,
subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS
FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER
IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
]]

beTilesetLoader_readTileFamily = function( path, tile_family )
	local tex = Resources.load( path..'/'..tile_family..'/'..tile_family..'.png')
	local filepath = path..'/'..tile_family..'/'..tile_family..'.txt'
	local bytes = Project.main:read( filepath )
	bytes:poke(1)
	local js = bytes:readString()
	--print( 'loading...', '', js )
	if js == '' or js == nil then 
		print( file, '', 'res data not found, returning default' )
		return {} 
	end
	local json = Json.new()
	local o = json:toTable( json:fromString(js) )
	return {
		tex = tex,
		json = o
	}
end

local roleMap = {}
beTilesetLoader_getTileRole = function( tileFamily, adjust8Family )
	local rowChecks = {
		{ yes = {1,2,3,4,5,6,7,8}, no = {} },
		{ yes = {2,3,4,5,6,7,8}, no = {1} },
		{ yes = {1,2,4,5,6,7,8}, no = {3} },
		{ yes = {1,2,3,4,6,7,8}, no = {5} },
		{ yes = {1,2,3,4,5,6,8}, no = {7} },
		{ yes = {1,2,3,4,6,8}, no = {5,7} },
		{ yes = {2,3,4,6,7,8}, no = {1,5} },
		{ yes = {2,4,5,6,7,8}, no = {1,3} },
		{ yes = {1,2,4,5,6,8}, no = {3,7} },
		{ yes = {2,4,6,7,8}, no = {1,3,5} },
		{ yes = {2,4,5,6,8}, no = {1,3,7} },
		{ yes = {4,5,6,7,8}, no = {2} },
		{ yes = {6,7,8,1,2}, no = {4} },
		{ yes = {1,2,3,4,8}, no = {6} },
		{ yes = {2,3,4,5,6}, no = {8} },
		{ yes = {2,4,6}, no = {3,5,8} },
		{ yes = {2,6,8}, no = {1,4,7} },
		{ yes = {4,6,8}, no = {2,5,7} },
		{ yes = {2,4,8}, no = {1,3,6} },
		{ yes = {4,6,7,8}, no = {2,5} },
		{ yes = {4,5,6,8}, no = {2,7} },
		{ yes = {2,3,4,6}, no = {5,8} },
		{ yes = {2,4,5,6}, no = {3,8} },
		{ yes = {1,2,6,8}, no = {4,7} },
		{ yes = {2,6,7,8}, no = {1,4} },
		{ yes = {2,3,4,8}, no = {1,6} },
		{ yes = {1,2,4,8}, no = {3,6} },
		{ yes = {4,5,6}, no = {2,8} },
		{ yes = {6,7,8}, no = {2,4} },
		{ yes = {1,2,8}, no = {4,6} },
		{ yes = {2,3,4}, no = {6,8} },
		{ yes = {4,6}, no = {2,5,8} },
		{ yes = {6,8}, no = {2,4,7} },
		{ yes = {2,8}, no = {4,6,1} },
		{ yes = {2,4}, no = {3,6,8} },
		{ yes = {2,4,6,8}, no = {} },
		{ yes = {}, no = {2,4,6,8} },
		{ yes = {2}, no = {4,6,8} },
		{ yes = {4}, no = {2,6,8} },
		{ yes = {6}, no = {2,4,8} },
		{ yes = {8}, no = {2,4,6} },
		{ yes = {4,8}, no = {2,6} },
		{ yes = {2,6}, no = {4,8} },
		{ yes = {2}, no = {4,6,8} },
		{ yes = {4}, no = {2,6,8} },
		{ yes = {6}, no = {2,4,8} },
		{ yes = {8}, no = {2,4,6} },
	}
	local role = 0
	local list = {}
	for ii = 1,8 do
		if adjust8Family[ii] == tileFamily then 
			-- this might be slow
			role = role + 2 ^ ( ii - 1 ) 
		end
	end
	if roleMap[role] == nil then
		for k,v in ipairs( rowChecks ) do
			local match = true
			for k1,v1 in ipairs( v.no ) do
				if adjust8Family[v1] == tileFamily then
					match = false
				end
			end
			for k1,v1 in ipairs( v.yes ) do
				if adjust8Family[v1] ~= tileFamily then
					match = false
				end
			end
			-- if all matched, then cache and return the role
			if match then
				v.role = 0
				for k1,v1 in ipairs( v.yes ) do
					v.role = v.role + 2 ^ ( v1 - 1 )
				end 
				roleMap[role] = v.role
				return roleMap[role]
			end
		end
		-- if all match failed, then keep the role
		roleMap[role] = role
	end
	return roleMap[role]
end 

local filter = function(lst, pred)
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

beTilesetLoader_getTileId = function( source, tileFamily, adjust8Family )
	local role = beTilesetLoader_getTileRole( tileFamily, adjust8Family )
    local cfg = filter( source.json.blob_sets[1].members, function(a) return a.role == role end )
    return cfg[1].id
end