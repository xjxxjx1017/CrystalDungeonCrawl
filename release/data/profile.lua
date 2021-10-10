require 'code/class'
require 'code/co'
require 'code/util'
require 'code/keycode'

Profile_OptionDefault = { }

Profile_ProfileDefault = { dateCreated = nil, crystals = copy( CRYSTALS ), upgrades = {}, round = 0, playedTutorial = false }

Profile_HistoryDefault = { dateCreated = nil, dateTimeFrom = nil, dateTimeTo = nil, round = nil,  killedBy = nil, crystal_gain = copy( CRYSTALS ), steps = 0, monster_kill = {}, equipments = {}, mode = nil, isWin = false }

ProfileManager = class({
    cfg = {
        profile = copy( Profile_ProfileDefault ),
        history = {},
        options = copy( Profile_OptionDefault )
    },

    ctor = function( self )
        print('Writable directory: ' .. Path.writableDirectory)
    end,

    loadAll = function( self )
        self.cfg.profile = self:load( 'profile', copy( Profile_ProfileDefault ) )
        self.cfg.history = self:load( 'history', {} )
        self.cfg.options = self:load( 'options', copy( Profile_OptionDefault ) )
    end,

    addNewHistory = function( self, history )
        table.insert( self.cfg.history, history )
    end,

    clearAll = function( self )
        self.cfg = {
            profile = copy( Profile_ProfileDefault ),
            history = {},
            options = copy( self.cfg.options )
        }
    end,

    saveAll = function( self )
        self:save( 'profile', self.cfg.profile )
        self:save( 'history', self.cfg.history )
        self:save( 'options', self.cfg.options )
    end,

    createIfNotExist = function( self, file )
        local path = Path.combine( Path.writableDirectory, file )
        local fileInfo = FileInfo.new( path )
        if fileInfo:exists() == false then
            fileInfo:make()
        end
        return path
    end,
    
    save = function( self, file, obj )
        local json = Json.new()
        local js = json:toString( json:fromTable( obj ) )
        -- print( 'saving...', '', js )
        local p = self:createIfNotExist( file )
        local f = File.new()
        f:open( p, Stream.Write)
        f:writeString( js )
        f:close()
    end,
    
    load = function( self, file, defaultObj )
        local p = self:createIfNotExist( file )
        local f = File.new()
        f:open( p, Stream.Read )
        local js = f:readString()
        f:close()
        -- print( 'loading...', '', js )
        if js == '' or js == nil then 
            print( file, '', 'save data not found, returning default' )
            return defaultObj 
        end
        local json = Json.new()
        local o = json:toTable( json:fromString(js) )
        return o
    end,

    clear = function( self, file )
        local path = Path.combine( Path.writableDirectory, file )
        local fileInfo = FileInfo.new( path )
        if fileInfo:exists() then
            fileInfo:remove(false)
        end
    end
})
profileManager = ProfileManager.new()