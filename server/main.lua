---@alias AddMode 'discord'|'citizenid'|'player'

---@class SendRequest
---@field contactId integer Contact from the sender's mail list (mail can only go to saved contacts)
---@field subject string
---@field body string

---@class AddContactRequest
---@field mode AddMode Discord ID, Citizen ID, or an online player's server ID (their Discord ID is looked up and saved)
---@field label string
---@field value string

---@class ActionResult
---@field ok boolean
---@field code? string
---@field message string
---@field data? AppData Fresh app data so the window can refresh

---@class AppData
---@field sender { name: string, email: string, citizenid?: string }
---@field contacts Contact[]
---@field history HistoryRow[]
---@field limits { subject: integer, body: integer, contacts: integer }
---@field features { citizenid: boolean }

local lastSend = {} ---@type table<integer, integer> Last send time for each player
local sending = {} ---@type table<integer, boolean> Players with a mail on the way

---Removes spaces at the start and end. Anything that is not text becomes ''.
---@param value any
---@return string
local function clean(value)
    if type(value) ~= 'string' then return '' end
    return (value:gsub('^%s+', ''):gsub('%s+$', ''))
end

---Checks that text looks like a Discord user id (17 to 20 digits)
---@param id string
---@return boolean
local function isDiscordId(id)
    return id:match('^%d+$') ~= nil and #id >= 17 and #id <= 20
end

---Checks that text looks like a Citizen ID (letters, numbers, : _ -)
---@param id string
---@return boolean
local function isCitizenId(id)
    return id:match('^[%w:_%-]+$') ~= nil and #id >= 3 and #id <= 64
end

---Builds a failed result
---@param code string
---@param message string
---@return ActionResult
local function fail(code, message)
    return { ok = false, code = code, message = message }
end

---Collects everything the mail window shows
---@param sender SenderInfo
---@return AppData
local function buildData(sender)
    local useCitizenIds = Bridge.hasCitizenIds()
    return {
        sender = { name = sender.name, email = sender.email, citizenid = useCitizenIds and sender.owner or nil },
        contacts = DB.getContacts(sender.owner),
        history = DB.getHistory(sender.owner, Config.HistoryLimit),
        limits = { subject = Config.MaxSubjectLength, body = Config.MaxBodyLength, contacts = Config.MaxContacts },
        features = { citizenid = useCitizenIds },
    }
end

---Saves a player's Discord ID against their Citizen ID, so they can get mail while offline
---@param src integer
local function rememberAccount(src)
    if not Bridge.hasCitizenIds() then return end
    local sender = Bridge.getSender(src)
    local discordId = Bridge.getDiscordId(src)
    if sender and discordId then DB.saveAccount(sender.owner, discordId) end
end

---Looks up the Discord ID of a character by Citizen ID
---Order: online player, last Discord we saw them with, then the framework's own records
---@param citizenId string
---@return string? discordId
---@return string? errorCode
---@return string? errorMessage
local function findDiscordByCitizenId(citizenId)
    local src = Bridge.getSourceByCitizenId(citizenId)
    if src then
        local discordId = Bridge.getDiscordId(src)
        if not discordId then
            return nil, 'no_discord', 'That person has not linked Discord to FiveM.'
        end
        DB.saveAccount(citizenId, discordId)
        return discordId
    end

    local discordId = DB.getAccountDiscord(citizenId) or Bridge.getStoredDiscordId(citizenId)
    if discordId then return discordId end

    return nil, 'no_discord', 'That person has no linked Discord on record yet. They need to join once with Discord open.'
end

---Gets the Discord ID to deliver to for a saved contact
---@param contact ContactTarget
---@return string? discordId
---@return string? errorCode
---@return string? errorMessage
local function resolveDiscord(contact)
    if not contact.citizenid then return contact.discord_id end

    -- If they are online, use their current Discord and update the saved one if it changed
    local src = Bridge.getSourceByCitizenId(contact.citizenid)
    local live = src and Bridge.getDiscordId(src)
    if live then
        if live ~= contact.discord_id then DB.setContactDiscord(contact.id, live) end
        return live
    end

    if contact.discord_id then return contact.discord_id end

    -- Older contacts saved before Discord IDs were stored with them
    local discordId, code, message = findDiscordByCitizenId(contact.citizenid)
    if discordId then DB.setContactDiscord(contact.id, discordId) end
    return discordId, code, message
end

---Adds or renames a contact after checking the input
---Contacts added by Citizen ID or Player ID get their Discord ID looked up and saved right away
---@param owner string
---@param req AddContactRequest
---@return boolean ok
---@return string message
---@return string? code
local function addContact(owner, req)
    local label = clean(req.label):sub(1, 50)
    local value = clean(req.value)
    local mode = req.mode

    if label == '' then return false, 'Give the contact a name.' end
    if value == '' then return false, 'Enter who to add.' end

    local discordId, citizenId

    if mode == 'discord' then
        if not isDiscordId(value) then return false, 'Enter a valid Discord ID (17 to 20 numbers).', 'invalid_id' end
        discordId = value

    elseif mode == 'player' then
        if not Bridge.hasCitizenIds() then return false, 'Citizen IDs are not used on this server.' end

        local src = tonumber(value)
        local player = src and GetPlayerName(src) and Bridge.getSender(src)
        if not player then return false, 'No player is online with that ID.', 'player_offline' end

        discordId = Bridge.getDiscordId(src)
        if not discordId then return false, 'That player has not linked Discord to FiveM.', 'no_discord' end

        -- Save their Citizen ID too, so the contact keeps working after they leave
        citizenId = player.owner
        DB.saveAccount(citizenId, discordId)

    elseif mode == 'citizenid' then
        if not Bridge.hasCitizenIds() then return false, 'Citizen IDs are not used on this server.' end
        if not isCitizenId(value) then return false, 'That Citizen ID is not valid.', 'invalid_citizenid' end

        local code, message
        discordId, code, message = findDiscordByCitizenId(value)
        if not discordId then
            -- Tell apart "no such citizen" and "citizen exists but has no Discord"
            if not Bridge.citizenExists(value) then
                return false, 'No citizen found with that Citizen ID.', 'invalid_citizenid'
            end
            return false, message --[[@as string]], code
        end
        citizenId = value

    else
        return false, 'Something went wrong. Try again.'
    end

    -- Same person already saved? Update that entry instead of adding a second one
    local byCitizen = citizenId and DB.findContact(owner, 'citizenid', citizenId)
    local byDiscord = DB.findContact(owner, 'discord_id', discordId)

    if byCitizen and byDiscord and byCitizen.id ~= byDiscord.id then
        return false, ('This Discord account is already in your mail list as "%s".'):format(byDiscord.label)
    end

    local existing = byCitizen or byDiscord
    if existing then
        if byDiscord and not byCitizen and byDiscord.citizenid and citizenId then
            -- Same Discord, different character: mail would land in the same DM
            return false, ('This Discord account is already in your mail list as "%s".'):format(byDiscord.label)
        end
        DB.updateContact(owner, existing.id, label, discordId, citizenId or existing.citizenid)
        return true, 'Contact updated.'
    end

    if DB.countContacts(owner) >= Config.MaxContacts then
        return false, ('Your mail list is full (max %s).'):format(Config.MaxContacts)
    end

    DB.insertContact(owner, label, discordId, citizenId)
    return true, 'Contact saved.'
end

-- Tables are created before anyone can use the app
MySQL.ready(function()
    DB.setup()
    Discord.checkToken()

    -- Catch players already online (for example after a resource restart)
    for _, id in ipairs(GetPlayers()) do
        rememberAccount(tonumber(id) --[[@as integer]])
    end
end)

Bridge.onCharacterLoaded(rememberAccount)

AddEventHandler('playerDropped', function()
    lastSend[source] = nil
    sending[source] = nil
end)

-- Loads the app data when a player opens the window
lib.callback.register('cad-email:getData', function(src)
    local sender = Bridge.getSender(src)
    if not sender then return end
    rememberAccount(src)
    return buildData(sender)
end)

-- Sends a mail to a contact's Discord DM. req is a SendRequest from the window.
lib.callback.register('cad-email:send', function(src, req)
    local sender = Bridge.getSender(src)
    if not sender then return fail('no_character', 'Could not find your character. Try again.') end
    if type(req) ~= 'table' then return fail('bad_request', 'Something went wrong. Try again.') end

    if sending[src] then return fail('busy', 'Your last mail is still sending.') end

    local waitLeft = (lastSend[src] or 0) + Config.SendCooldown - os.time()
    if waitLeft > 0 then
        return fail('cooldown', ('Please wait %s seconds before sending again.'):format(waitLeft))
    end

    local subject, body = clean(req.subject), clean(req.body)
    if subject == '' then return fail('no_subject', 'Add a subject.') end
    if body == '' then return fail('no_body', 'Write a message.') end
    if #subject > Config.MaxSubjectLength then return fail('too_long', 'The subject is too long.') end
    if #body > Config.MaxBodyLength then return fail('too_long', 'The message is too long.') end

    -- Mail can only go to someone in the sender's mail list
    local contact = type(req.contactId) == 'number' and DB.getContact(sender.owner, req.contactId)
    if not contact then
        return fail('not_in_list', 'You can only mail people in your mail list. Add them first.')
    end

    sending[src] = true
    lastSend[src] = os.time()

    local discordId, errorCode, errorMessage = resolveDiscord(contact)

    ---@type DiscordResult
    local result
    if discordId then
        result = Discord.sendMail(discordId, {
            subject = subject,
            body = body,
            fromName = sender.name,
            fromEmail = sender.email,
        })
    else
        result = { ok = false, code = errorCode, message = errorMessage, detail = ('No Discord for Citizen ID %s'):format(contact.citizenid) }
    end

    sending[src] = nil

    DB.addHistory({
        owner = sender.owner,
        sender_name = sender.name,
        sender_email = sender.email,
        recipient_id = discordId or '-',
        recipient_label = contact.label,
        subject = subject,
        body = body,
        status = result.ok and 'sent' or 'failed',
        error_code = result.code,
        error = result.message,
    })

    -- Logs
    local who = ('%s (ID %s)'):format(sender.name, src)
    local to = contact.citizenid and ('Citizen ID %s'):format(contact.citizenid) or ('Discord user %s'):format(discordId)
    local recipientField = ('%s\n%s'):format(contact.label, to)
    if discordId then recipientField = ('%s\n<@%s>'):format(recipientField, discordId) end

    local fields = {
        { name = 'Sender', value = ('%s\n%s\n%s'):format(who, sender.email, sender.owner), inline = true },
        { name = 'Recipient', value = recipientField, inline = true },
        { name = 'Subject', value = subject },
    }

    if result.ok then
        Log.console('info', ('%s mailed %s (%s): "%s"'):format(who, contact.label, to, subject))
        Log.webhook('Mail delivered', 'success', fields)
    else
        -- Setup problems are errors for the owner, the rest are normal warnings
        local level = (result.code == 'bad_token' or result.code == 'no_token' or result.code == 'no_access') and 'error' or 'warn'
        Log.console(level, ('%s could not mail %s (%s) [%s] %s'):format(who, contact.label, to, result.code, result.detail or result.message))
        fields[#fields + 1] = { name = 'Reason', value = ('%s\n%s'):format(result.message, result.detail or '') }
        Log.webhook('Mail failed', level == 'error' and 'error' or 'warn', fields)

        -- Do not make players wait after a failed send
        lastSend[src] = nil
    end

    return {
        ok = result.ok,
        code = result.code,
        message = result.ok and ('Mail delivered to %s.'):format(contact.label) or result.message,
        data = buildData(sender),
    }
end)

-- Adds or renames a contact in the mail list. data is an AddContactRequest.
lib.callback.register('cad-email:saveContact', function(src, data)
    local sender = Bridge.getSender(src)
    if not sender or type(data) ~= 'table' then return fail('bad_request', 'Something went wrong. Try again.') end

    local ok, message, code = addContact(sender.owner, data)
    if ok then Log.console('debug', ('%s saved contact "%s" (%s)'):format(sender.name, clean(data.label), data.mode)) end

    return { ok = ok, code = code, message = message, data = buildData(sender) }
end)

-- Removes a contact from the mail list
lib.callback.register('cad-email:deleteContact', function(src, id)
    local sender = Bridge.getSender(src)
    if not sender or type(id) ~= 'number' then return fail('bad_request', 'Something went wrong. Try again.') end

    local removed = DB.deleteContact(sender.owner, id)
    return {
        ok = removed,
        message = removed and 'Contact removed.' or 'That contact no longer exists.',
        data = buildData(sender),
    }
end)

-- Console command: shows the latest failed sends. Usage: emailfailures [amount]
RegisterCommand('emailfailures', function(src, args)
    if src ~= 0 then return end

    local rows = DB.getRecentFailures(math.min(tonumber(args[1]) or 10, 50))
    if #rows == 0 then
        return Log.console('info', 'No failed mails found.')
    end

    Log.console('info', ('Last %s failed mails:'):format(#rows))
    for _, row in ipairs(rows) do
        print(('  %s | %s -> %s | %s | [%s] %s'):format(row.time, row.sender_name, row.recipient, row.subject, row.error_code or '?', row.error or ''))
    end
end, true)
