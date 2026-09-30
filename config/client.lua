---@class ClientConfig
---@field Command string
---@field EmailDomain string
---@field SendCooldown integer
---@field MaxContacts integer
---@field HistoryLimit integer
---@field MaxSubjectLength integer
---@field MaxBodyLength integer
Config = {}

-- Chat command that opens the mail app
Config.Command = 'email'
