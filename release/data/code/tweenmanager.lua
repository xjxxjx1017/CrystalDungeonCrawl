require 'code/class'
require 'code/keycode'
require 'code/util'
local Tween = require 'code/tween' -- See https://github.com/kikito/tween.lua.


--[[
	Tween Manager class support adding a bunch of tween or tween sequences to it, then
	it will update and render them by the manager's update and render function.
	Tween Manager also support a onComplete callback
]]
TweenManager = class({
	tweens = {},
	sequences = {},
	count = 0,

	getAllFinished = function( self )
		for k,v in ipairs( self.tweens ) do
			return false
		end
		for k,v in ipairs( self.sequences ) do
			return false
		end
		return true
	end,

	addTween = function( self, tween, isblocking, onComplete )
		self.count = self.count + 1
		table.insert(self.tweens, { id = self.count, tween = tween, onComplete = onComplete, isblocking = isblocking })
	end,

	addTweenSequence = function( self, tween, isblocking, onComplete )
		self.count = self.count + 1
		table.insert(self.tweens, { id = self.count, tween = tween, onComplete = onComplete, isblocking = isblocking })
	end,

	addSpriteAnimeSequence = function( self, sas, isblocking, onComplete )
		self.count = self.count + 1
		table.insert(self.sequences, { id = self.count, tween = sas, onComplete = onComplete, isblocking = isblocking })
	end,

	addDelay = function( self, delay, isblocking, onComplete )
		self:addTween( Tween.new( delay, {x = 1}, {x = 0} ), isblocking, onComplete )
	end,

	update = function( self, delta )
		for i = #self.tweens, 1, -1 do
			local t = self.tweens[i]
			local complete = t.tween:update( delta )
			if complete then
				if t.onComplete ~= nil then
					print('call tween onComplete: ' .. t.id)
					t.onComplete()
				end
				table.remove( self.tweens, i )
			end
		end
		for i = #self.sequences, 1, -1 do
			local t = self.sequences[i]
			local complete = t.tween:update( delta )
			if complete then
				if t.onComplete ~= nil then
					print('call tween onComplete: ' .. t.id)
					t.onComplete()
				end
				table.remove( self.sequences, i )
			end
		end
	end,

	render = function(self)
		for i = #self.sequences, 1, -1 do
			local t = self.sequences[i]
			t.tween:render()
		end
	end
})
-- the instance of Tween Manager
tweenManager = TweenManager.new()


--[[
	Sprite Anime Sequence is a class that render a sprite that move along a sequence of tweens.
	After the tweens all finished, the update function will always return true, and the sprite no longer rendering

	example:
	tweenManager:addSpriteAnimeSequence( SpriteAnimeSequence.new( game.weapon.cfg.img, { 
		{ target = { x = mapCfg.mox + px * 32 + dirX * 16, y = mapCfg.moy + py * 32 + dirY * 16, w = 32, h = 32, rotAngle = math.pi * 0 } }, 
		{ duration = 1, easing = 'outExpo', target = { x = mapCfg.mox + px * 32 + dirX * 16, y = mapCfg.moy + py * 32 + dirY * 16, w = 32, h = 32, rotAngle = math.pi * -1 } } 
	} ) )
]]
TweenSequence_DefaultSequence = { duration = 0, easing = 'linear', target = {} }
TweenSequence = class({
	curTween = nil,
	curIndex = 1,
	finished = false,
	subject = nil,
	sequence = {},

	ctor = function( self, subject, sequence )
		if sequence == nil or #sequence < 2 then assert('sequence count needs to be more than 2' ) end
		self.subject = subject
		self.curIndex = self.curIndex + 1
		self.sequence = copy( sequence )
		self.curTween = Tween.new( self.sequence[self.curIndex].duration, self.subject, self.sequence[self.curIndex].target, self.sequence[self.curIndex].easing )
	end,

	update = function( self, delta )
		if self.finished == true then return true end
		local complete = self.curTween:update( delta )
		if complete == true then
			if self.curIndex >= #self.sequence then
				self.finished = true
				return true
			else
				self.curIndex = self.curIndex + 1
				self.curTween = Tween.new( self.sequence[self.curIndex].duration, self.subject, self.sequence[self.curIndex].target, self.sequence[self.curIndex].easing )
			end
		end 
		-- return finished or not
		return false
	end
})


--[[
	Sprite Anime Sequence is a class that render a sprite that move along a sequence of tweens.
	After the tweens all finished, the update function will always return true, and the sprite no longer rendering

	example:
	tweenManager:addSpriteAnimeSequence( SpriteAnimeSequence.new( game.weapon.cfg.img, { 
		{ target = { x = mapCfg.mox + px * 32 + dirX * 16, y = mapCfg.moy + py * 32 + dirY * 16, w = 32, h = 32, rotAngle = math.pi * 0 } }, 
		{ duration = 1, easing = 'outExpo', target = { x = mapCfg.mox + px * 32 + dirX * 16, y = mapCfg.moy + py * 32 + dirY * 16, w = 32, h = 32, rotAngle = math.pi * -1 } } 
	} ) )
]]
SpriteAnimeSequence_DefaultSequence = { duration = 0, easing = 'linear', target = {} }
SpriteAnimeSequence = class({
	curTween = nil,
	curIndex = 1,
	finished = false,
	spr = nil,
	renderOptions = nil,
	sequence = {},

	ctor = function( self, img, sequence )
		self.spr = Resources.load( img )
		if sequence == nil or #sequence < 2 then assert('sequence count needs to be more than 2' ) end
		self.renderOptions = copy( sequence[1].target )
		self.curIndex = self.curIndex + 1
		self.sequence = copy( sequence )
		self.curTween = Tween.new( self.sequence[self.curIndex].duration, self.renderOptions, self.sequence[self.curIndex].target, self.sequence[self.curIndex].easing )
	end,

	update = function( self, delta )
		if self.finished == true then return true end
		local complete = self.curTween:update( delta )
		if complete == true then
			if self.curIndex >= #self.sequence then
				self.finished = true
				return true
			else
				self.curIndex = self.curIndex + 1
				self.curTween = Tween.new( self.sequence[self.curIndex].duration, self.renderOptions, self.sequence[self.curIndex].target, self.sequence[self.curIndex].easing )
			end
		end 
		-- return finished or not
		return false
	end,

	render = function( self )
		if self.finished == true then return true end
		spr( self.spr, self.renderOptions.x, self.renderOptions.y, self.renderOptions.w, self.renderOptions.h, self.renderOptions.rotAngle, self.renderOptions.rotCenter, self.renderOptions.col )
	end
})


--[[
	Action Tween class is a tween that provides per-frame update callback and an oncomplete callback
]]
ActionTween = class({
	name = '',
	totalTime = 0,
	curTime = 0,
	finished = true,
	initialValues = {},
	onStart = nil,
	onUpdate = nil,
	onComplete = nil,

	ctor = function(self, name, totalTime, initialValues, onStart, onUpdate, onComplete )
		self.name = name
		self.totalTime = totalTime
		self.curTime = 0
		self.initialValues = copy( initialValues )
		self.finished = false
		self.onStart = onStart
		self.onUpdate = onUpdate
		self.onComplete = onComplete
		if self.onStart ~= nil then
			self:onStart()
		end
	end,

	update = function(self, delta)
		if self.finished then
			return true
		end
		self.curTime = self.curTime + delta
		if DEBUG_FRAME then print('delta'..delta, 'curTime'..self.curTime, 'totalTime'..self.totalTime) end
		if self.curTime >= self.totalTime then
			self.finished = true
			self.curTime = self.totalTime
			if self.onComplete ~= nil then
				self:onComplete()
			end
			return true
		else
			if self.onUpdate ~= nil then
				self:onUpdate( self.initialValues, self.curTime / self.totalTime )
			end
		end
		return false
	end,

	finish = function(self)
		self:update( 9999999 )
	end
})