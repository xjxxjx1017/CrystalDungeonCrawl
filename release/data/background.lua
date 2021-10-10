
require 'code/class'
require 'code/keycode'
require 'code/util'
require 'units/object'
local Tween = require 'code/tween' -- See https://github.com/kikito/tween.lua.

BG_Forest = 6
BG_Mountain = 7
BG_River = 4

Background = class({
    backgroundObjectList = {},
    background = nil,

    reset = function(self)
	--[[
		self.backgroundObjectList = {}
        self.background = Resources.load( mapCfg.background )
        local xOffset = ( MapTile_WH - 16 ) * -0.5 * 32
        for i = 0, 7 * 2 + MapTile_WH do
            for j = 0, 7 * 2 + MapTile_WH do
                local c = mget(self.background, i, j)
                if c == BG_Forest then
				    local o = Object.new( 'BG_Forest', i, j, { img = 'forest', width = 1, height = 1 }, xOffset, 0 )
                    table.insert( self.backgroundObjectList, o )
                elseif c == BG_Mountain then
				    local o = Object.new( 'BG_Mountain', i, j, { img = 'mountain', width = 1, height = 1 }, xOffset, 0 )
                    table.insert( self.backgroundObjectList, o )
                elseif c == BG_River then
				    local o = Object.new( 'BG_River', i, j, { img = 'river_bg', width = 1, height = 1 }, xOffset, 0 )
                    table.insert( self.backgroundObjectList, o )
                end
            end
        end]]
    end,

    update = function(self, delta)
	--[[
        for k,v in ipairs( self.backgroundObjectList ) do
            if game:isInCamera( v ) then
                v:render( delta )
            end
        end]]
    end

}, object)
bg = Background.new()