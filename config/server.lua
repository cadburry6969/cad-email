Config = {}

---@class EmailConfig
---@field BotToken string
---@field LogWebhook string
---@field ServerName string
---@field EmbedColor integer
---@field Framework 'auto'|'qbx'|'qb'|'esx'|'standalone'
---@field HistoryKeepDays integer
---@field Debug boolean
Config.Email = {
    -- Discord bot token. Best way is to add this line to server.cfg:
    --   set cad_email_token "YOUR_BOT_TOKEN"
    -- Never share the token or push it to GitHub.
    BotToken = GetConvar('cad_email_token', ''),

    -- Discord webhook for staff logs. Leave empty to turn off.
    --   set cad_email_webhook "https://discord.com/api/webhooks/..."
    LogWebhook = GetConvar('cad_email_webhook', ''),

    -- Name shown at the bottom of every mail
    ServerName = 'Los Santos Mail',

    -- Side color of the mail card in Discord (decimal color)
    EmbedColor = 3447003,

    -- 'auto' picks qbx_core, qb-core or es_extended if found, else 'standalone'
    Framework = 'auto',

    -- Delete sent history older than this many days on start (0 keeps it forever)
    HistoryKeepDays = 30,

    -- Print extra details to the server console
    Debug = false,
}

-- Domain for the sender address, e.g. john_doe@email.com
Config.EmailDomain = 'lsmail.com'

-- Seconds a player must wait between two sends
Config.SendCooldown = 30

-- Max saved contacts in each character's mail list
Config.MaxContacts = 50

-- How many past mails show in the Sent tab
Config.HistoryLimit = 50

-- Text limits (Discord allows up to 256 for the subject and 4096 for the body)
Config.MaxSubjectLength = 120
Config.MaxBodyLength = 2000
