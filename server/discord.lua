---@class DiscordResult
---@field ok boolean
---@field code? string Short error code, e.g. 'dms_off'
---@field message? string Readable reason shown to the player
---@field detail? string Raw Discord error, for logs only

---@class MailContent
---@field subject string
---@field body string
---@field fromName string
---@field fromEmail string

Discord = {}

local API = 'https://discord.com/api/v10'

-- Discord error codes we expect, turned into plain language
local KNOWN_ERRORS = {
    [50007] = { code = 'dms_off', message = 'This person has DMs turned off, blocked the bot, or is not in the Discord server.' },
    [10013] = { code = 'unknown_user', message = 'No Discord account was found with that ID.' },
    [50035] = { code = 'invalid_id', message = 'That Discord ID is not valid.' },
    [50001] = { code = 'no_access', message = 'The bot is missing access. Tell a server admin.' },
}

---Reads JSON safely (Discord sometimes replies with plain text)
---@param raw string?
---@return table?
local function decode(raw)
    if type(raw) ~= 'string' or raw == '' then return end
    local ok, data = pcall(json.decode, raw)
    if ok and type(data) == 'table' then return data end
end

---Sends one request to Discord and waits for the reply
---@param method 'GET'|'POST'
---@param endpoint string
---@param payload? table
---@return integer status
---@return table? data
local function request(method, endpoint, payload)
    local body = payload and json.encode(payload) or ''
    local headers = {
        ['Authorization'] = 'Bot ' .. Config.Email.BotToken,
        ['Content-Type'] = 'application/json',
        ['User-Agent'] = 'DiscordBot (cad-email, 2.0.0)',
    }

    local function send()
        local p = promise.new()
        PerformHttpRequest(API .. endpoint, function(status, resBody, _, errorData)
            -- On errors the reply can come in either resBody or errorData
            p:resolve({ status = status or 0, data = decode(resBody) or decode(errorData) })
        end, method, body, headers)
        return Citizen.Await(p)
    end

    local res = send()

    -- Rate limited: wait the time Discord asks for, then try once more
    if res.status == 429 and res.data and res.data.retry_after then
        Log.console('debug', ('Rate limited, retrying in %ss'):format(res.data.retry_after))
        Wait(math.ceil(res.data.retry_after * 1000))
        res = send()
    end

    return res.status, res.data
end

---Turns a failed Discord reply into a readable result
---@param status integer
---@param data table?
---@param step 'channel'|'message'
---@return DiscordResult
local function toError(status, data, step)
    local detail = data and data.message and ('%s (code %s)'):format(data.message, data.code) or ('HTTP %s'):format(status)
    local known = data and KNOWN_ERRORS[data.code]

    if known then
        return { ok = false, code = known.code, message = known.message, detail = detail }
    end

    if status == 401 then
        return { ok = false, code = 'bad_token', message = 'The mail bot is not set up right. Tell a server admin.', detail = detail }
    end

    -- A 403 when sending the message almost always means DMs are closed
    if status == 403 and step == 'message' then
        return { ok = false, code = 'dms_off', message = KNOWN_ERRORS[50007].message, detail = detail }
    end

    if status == 404 then
        return { ok = false, code = 'unknown_user', message = KNOWN_ERRORS[10013].message, detail = detail }
    end

    if status == 0 then
        return { ok = false, code = 'no_connection', message = 'Could not reach Discord. Try again later.', detail = detail }
    end

    if status >= 500 then
        return { ok = false, code = 'discord_down', message = 'Discord is having problems. Try again later.', detail = detail }
    end

    return { ok = false, code = 'discord_error', message = ('Discord refused the mail (error %s).'):format(status), detail = detail }
end

---Checks the bot token on start and prints the result
function Discord.checkToken()
    if Config.Email.BotToken == '' then
        Log.console('error', 'No bot token set. Add  set cad_email_token "YOUR_TOKEN"  to server.cfg')
        return
    end

    local status, data = request('GET', '/users/@me')
    if status == 200 and data then
        Log.console('info', ('Mail bot ready as %s'):format(data.username))
    else
        local err = toError(status, data, 'channel')
        Log.console('error', ('Bot token check failed: %s'):format(err.detail))
    end
end

---Delivers a mail to a Discord user as a DM
---@param discordId string
---@param mail MailContent
---@return DiscordResult
function Discord.sendMail(discordId, mail)
    if Config.Email.BotToken == '' then
        return { ok = false, code = 'no_token', message = 'The mail bot is not set up yet. Tell a server admin.', detail = 'Missing bot token' }
    end

    -- Step 1: open (or reuse) the DM channel with this user
    local status, channel = request('POST', '/users/@me/channels', { recipient_id = discordId })
    if status ~= 200 or not channel or not channel.id then
        return toError(status, channel, 'channel')
    end

    -- Step 2: post the mail in that DM
    local sent
    status, sent = request('POST', ('/channels/%s/messages'):format(channel.id), {
        allowed_mentions = { parse = {} },
        embeds = { {
            title = mail.subject,
            description = mail.body,
            color = Config.Email.EmbedColor,
            author = { name = ('From: %s <%s>'):format(mail.fromName, mail.fromEmail) },
            footer = { text = ('Sent from %s'):format(Config.Email.ServerName) },
            timestamp = os.date('!%Y-%m-%dT%H:%M:%SZ'),
        } },
    })

    if status ~= 200 then
        return toError(status, sent, 'message')
    end

    return { ok = true }
end
