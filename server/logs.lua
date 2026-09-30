---@alias LogLevel 'info'|'warn'|'error'|'debug'
---@alias LogColor 'success'|'info'|'warn'|'error'

---@class LogField
---@field name string
---@field value string
---@field inline? boolean

Log = {}

local consoleColors = { info = '^5', warn = '^3', error = '^1', debug = '^6' }
local embedColors = { success = 3066993, info = 3447003, warn = 16763904, error = 15158332 }

---Cuts text down so it fits in a Discord field
---@param text any
---@param max integer
---@return string
local function shorten(text, max)
    text = tostring(text or '-')
    if text == '' then return '-' end
    if #text > max then return text:sub(1, max - 3) .. '...' end
    return text
end

---Prints a line to the server console
---@param level LogLevel
---@param message string
function Log.console(level, message)
    if level == 'debug' and not Config.Email.Debug then return end
    print(('%s[cad-email] [%s]^7 %s'):format(consoleColors[level] or '^7', level:upper(), message))
end

---Posts a log card to the staff webhook. Does nothing if no webhook is set.
---@param title string
---@param color LogColor
---@param fields LogField[]
function Log.webhook(title, color, fields)
    local url = Config.Email.LogWebhook
    if url == '' then return end

    for _, field in ipairs(fields) do
        field.value = shorten(field.value, 1024)
    end

    local payload = json.encode({
        username = 'Email Logs',
        allowed_mentions = { parse = {} },
        embeds = { {
            title = title,
            color = embedColors[color],
            fields = fields,
            timestamp = os.date('!%Y-%m-%dT%H:%M:%SZ'),
        } },
    })

    PerformHttpRequest(url, function(status)
        if status < 200 or status >= 300 then
            Log.console('warn', ('Log webhook failed (status %s). Check cad_email_webhook.'):format(status))
        end
    end, 'POST', payload, { ['Content-Type'] = 'application/json' })
end
