--[[
The MIT License

Copyright (C) 2021 Tony Wang

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

--[[
Utils.
]]

local function startsWith(str, part)
	return part == '' or string.sub(str, 1, #part) == part
end

local function endsWith(str, part)
	return part == '' or string.sub(str, -#part) == part
end

--[[
Loader.
]]

local load = function (dir, ext)
	-- Prepare.
	if ext == nil then
		ext = 'png'
	end

	-- Get possible frame assets.
	local frames = { }
	local assets = Project.main:getAssets()
	for _, asset in ipairs(assets) do
		if startsWith(asset, dir) and endsWith(asset, ext) then
			table.insert(frames, asset)
		end
	end
	table.sort(frames) -- Ordered by name.

	if #frames == 0 then
		return nil
	end

	-- Creates Image and Sprite table dynamically.
	local imgFull, tblFull = nil, nil
	local xCount = math.ceil(math.sqrt(#frames))
	local yCount = math.ceil(#frames / xCount)
	local frameWidth, frameHeight = nil, nil
	for k, frame in ipairs(frames) do
		-- Read a frame.
		local bytes = Project.main:read(frame)
		local img = Image.new()
		img:fromBytes(bytes)
		-- Check frame size.
		local valid = true
		if frameWidth == nil then
			frameWidth, frameHeight = img.width, img.height -- The sprite size is determined by the first frame.
		else
			if img.width ~= frameWidth or img.height ~= frameHeight then
				valid = false
				warn('Ignored frame ' .. frame .. '.')
			end
		end
		-- Fill in the frame.
		if valid then
			if imgFull == nil then
				imgFull = Image.new() -- Create full Image.
				imgFull:resize(frameWidth * xCount, frameHeight * yCount)
				tblFull = { -- Create full Sprite table.
					width = frameWidth, height = frameHeight,
					count = 0,
					data = {
					},
					ref = nil
				}
			end
			local m, n = tblFull.count % xCount, math.floor(tblFull.count / xCount)
			tblFull.count = tblFull.count + 1 -- Increase frame count.
			local x, y = m * frameWidth, n * frameHeight
			for j = 0, frameHeight - 1 do -- Fill a frame to the full Image.
				for i = 0, frameWidth - 1 do
					local col = img:get(i, j)
					imgFull:set(x + i, y + j, col) -- Fill a pixel.
				end
			end
			table.insert( -- Fill a frame to the full Sprite table.
				tblFull.data,
				{
					x = x, y = y,
					width = frameWidth, height = frameHeight,
					interval = 1 / 20, -- Interval defaults to 0.25.
					key = ''
				}
			)
		end
	end
	local texFull = Resources.load(imgFull, Texture) -- Create full Texture from the Image.
	tblFull.ref = texFull -- Refer to the Texture.

	-- Finish.
	return Resources.load(tblFull, Sprite) -- Load it.
end

--[[
Exporting.
]]

return {
	load = load
}
