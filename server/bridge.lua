---@class SenderInfo
---@field owner string Unique character id, used to save the mail list
---@field name string Character name shown on the mail
---@field email string Sender address built from the name

Bridge = {}

---Works out which framework is running
---@return 'qbx'|'qb'|'esx'|'standalone'
local function detectFramework()
    if Config.Email.Framework ~= 'auto' then return Config.Email.Framework end
    if GetResourceState('qbx_core') ~= 'missing' then return 'qbx' end
    if GetResourceState('qb-core') ~= 'missing' then return 'qb' end
    if GetResourceState('es_extended') ~= 'missing' then return 'esx' end
    return 'standalone'
end

local framework = detectFramework()
local QBCore, ESX

---Gets the character id and name of a player
---@param src integer
---@return string? owner
---@return string? name
local function getCharacter(src)
    if framework == 'qbx' then
        local player = exports.qbx_core:GetPlayer(src)
        if not player then return end
        local info = player.PlayerData.charinfo
        return player.PlayerData.citizenid, ('%s %s'):format(info.firstname, info.lastname)
    end

    if framework == 'qb' then
        QBCore = QBCore or exports['qb-core']:GetCoreObject()
        local player = QBCore.Functions.GetPlayer(src)
        if not player then return end
        local info = player.PlayerData.charinfo
        return player.PlayerData.citizenid, ('%s %s'):format(info.firstname, info.lastname)
    end

    if framework == 'esx' then
        ESX = ESX or exports.es_extended:getSharedObject()
        local xPlayer = ESX.GetPlayerFromId(src)
        if not xPlayer then return end
        return xPlayer.identifier, xPlayer.getName()
    end

    -- Standalone: use the Rockstar license and FiveM name
    return GetPlayerIdentifierByType(tostring(src), 'license'), GetPlayerName(src)
end

---Gets the sender details for a player
---@param src integer
---@return SenderInfo?
function Bridge.getSender(src)
    local owner, name = getCharacter(src)
    if not owner or not name then return end

    -- "John Doe" becomes "john_doe"
    local handle = name:lower():gsub('[^%w]+', '_'):gsub('^_+', ''):gsub('_+$', '')
    if handle == '' then handle = 'citizen' end

    return {
        owner = owner,
        name = name,
        email = ('%s@%s'):format(handle, Config.EmailDomain),
    }
end

---Gets the Discord user id linked to an online player
---@param src integer
---@return string?
function Bridge.getDiscordId(src)
    local identifier = GetPlayerIdentifierByType(tostring(src), 'discord')
    if not identifier then return end
    return (identifier:gsub('^discord:', ''))
end

---True when the framework has Citizen IDs (standalone does not)
---@return boolean
function Bridge.hasCitizenIds()
    return framework ~= 'standalone'
end

---Finds the server ID of an online player by their Citizen ID
---@param citizenId string
---@return integer?
function Bridge.getSourceByCitizenId(citizenId)
    if framework == 'qbx' then
        local player = exports.qbx_core:GetPlayerByCitizenId(citizenId)
        return player and player.PlayerData.source
    end

    if framework == 'qb' then
        QBCore = QBCore or exports['qb-core']:GetCoreObject()
        local player = QBCore.Functions.GetPlayerByCitizenId(citizenId)
        return player and player.PlayerData.source
    end

    if framework == 'esx' then
        ESX = ESX or exports.es_extended:getSharedObject()
        local xPlayer = ESX.GetPlayerFromIdentifier(citizenId)
        return xPlayer and xPlayer.source
    end
end

---Checks the framework's own character table for a Citizen ID
---@param citizenId string
---@return boolean
function Bridge.citizenExists(citizenId)
    local query
    if framework == 'qbx' or framework == 'qb' then
        query = 'SELECT 1 FROM `players` WHERE `citizenid` = ? LIMIT 1'
    elseif framework == 'esx' then
        query = 'SELECT 1 FROM `users` WHERE `identifier` = ? LIMIT 1'
    else
        return false
    end

    -- pcall in case the server renamed the table
    local ok, found = pcall(MySQL.scalar.await, query, { citizenId })
    return ok and found ~= nil
end

---Reads the Discord ID the framework saved for an offline character (qbx only, others return nil)
---@param citizenId string
---@return string?
function Bridge.getStoredDiscordId(citizenId)
    if framework ~= 'qbx' then return end

    -- qbx_core keeps each account's identifiers in `users`, linked to characters by userId
    local ok, identifier = pcall(MySQL.scalar.await, [[
        SELECT u.`discord` FROM `players` p JOIN `users` u ON u.`userId` = p.`userId`
        WHERE p.`citizenid` = ? LIMIT 1
    ]], { citizenId })

    if not ok or type(identifier) ~= 'string' or identifier == '' then return end
    return (identifier:gsub('^discord:', ''))
end

---Runs a function each time a player loads into a character
---@param cb fun(src: integer)
function Bridge.onCharacterLoaded(cb)
    if framework == 'qbx' or framework == 'qb' then
        AddEventHandler('QBCore:Server:PlayerLoaded', function(player)
            local src = player and player.PlayerData and player.PlayerData.source
            if src then cb(src) end
        end)
    elseif framework == 'esx' then
        AddEventHandler('esx:playerLoaded', function(src)
            cb(src)
        end)
    end
end

Log.console('debug', ('Framework: %s'):format(framework))
