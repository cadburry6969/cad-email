---@alias ContactKind 'discord'|'citizenid'

---@class Contact
---@field id integer
---@field label string
---@field kind ContactKind
---@field target string Discord ID or Citizen ID, depending on kind

---@class ContactTarget
---@field id integer
---@field label string
---@field discord_id? string Saved when the contact is added (older rows may not have it)
---@field citizenid? string Only set for contacts added by Citizen ID or Player ID

---@alias MailStatus 'sent'|'failed'

---@class HistoryEntry
---@field owner string
---@field sender_name string
---@field sender_email string
---@field recipient_id string
---@field recipient_label? string
---@field subject string
---@field body string
---@field status MailStatus
---@field error_code? string
---@field error? string

---@class HistoryRow
---@field id integer
---@field recipient string
---@field subject string
---@field body string
---@field status MailStatus
---@field error? string
---@field sent_at integer Unix time in seconds

DB = {}

---Creates the tables if they are missing and clears old history
function DB.setup()
    MySQL.query.await([[
        CREATE TABLE IF NOT EXISTS `cad_email_contacts` (
            `id` INT NOT NULL AUTO_INCREMENT,
            `owner` VARCHAR(64) NOT NULL,
            `label` VARCHAR(50) NOT NULL,
            `discord_id` VARCHAR(20) NULL,
            `citizenid` VARCHAR(64) NULL,
            `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
            PRIMARY KEY (`id`),
            UNIQUE KEY `owner_discord` (`owner`, `discord_id`),
            UNIQUE KEY `owner_citizenid` (`owner`, `citizenid`)
        )
    ]])

    -- Upgrade older installs that only had Discord ID contacts
    local hasCitizenColumn = MySQL.scalar.await([[
        SELECT COUNT(*) FROM information_schema.COLUMNS
        WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'cad_email_contacts' AND COLUMN_NAME = 'citizenid'
    ]])
    if hasCitizenColumn == 0 then
        MySQL.query.await([[
            ALTER TABLE `cad_email_contacts`
                MODIFY `discord_id` VARCHAR(20) NULL,
                ADD COLUMN `citizenid` VARCHAR(64) NULL AFTER `discord_id`,
                ADD UNIQUE KEY `owner_citizenid` (`owner`, `citizenid`)
        ]])
        Log.console('info', 'Upgraded the mail list table for Citizen ID contacts')
    end

    -- Last known Discord ID of each character, so they can get mail while offline
    MySQL.query.await([[
        CREATE TABLE IF NOT EXISTS `cad_email_accounts` (
            `citizenid` VARCHAR(64) NOT NULL,
            `discord_id` VARCHAR(20) NOT NULL,
            `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
            PRIMARY KEY (`citizenid`)
        )
    ]])

    MySQL.query.await([[
        CREATE TABLE IF NOT EXISTS `cad_email_history` (
            `id` INT NOT NULL AUTO_INCREMENT,
            `owner` VARCHAR(64) NOT NULL,
            `sender_name` VARCHAR(100) NOT NULL,
            `sender_email` VARCHAR(150) NOT NULL,
            `recipient_id` VARCHAR(20) NOT NULL,
            `recipient_label` VARCHAR(50) NULL,
            `subject` VARCHAR(256) NOT NULL,
            `body` TEXT NOT NULL,
            `status` VARCHAR(16) NOT NULL,
            `error_code` VARCHAR(32) NULL,
            `error` VARCHAR(255) NULL,
            `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
            PRIMARY KEY (`id`),
            KEY `owner` (`owner`),
            KEY `status` (`status`)
        )
    ]])

    if Config.Email.HistoryKeepDays > 0 then
        local removed = MySQL.update.await(
            'DELETE FROM `cad_email_history` WHERE `created_at` < NOW() - INTERVAL ? DAY',
            { Config.Email.HistoryKeepDays }
        )
        if removed and removed > 0 then
            Log.console('info', ('Cleared %s old history entries'):format(removed))
        end
    end
end

---Gets a character's saved contacts, A to Z
---@param owner string
---@return Contact[]
function DB.getContacts(owner)
    return MySQL.query.await([[
        SELECT `id`, `label`,
               IF(`citizenid` IS NULL, 'discord', 'citizenid') AS `kind`,
               COALESCE(`citizenid`, `discord_id`) AS `target`
        FROM `cad_email_contacts` WHERE `owner` = ? ORDER BY `label`
    ]], { owner }) or {}
end

---Gets one contact from a character's mail list
---@param owner string
---@param id integer
---@return ContactTarget?
function DB.getContact(owner, id)
    return MySQL.single.await(
        'SELECT `id`, `label`, `discord_id`, `citizenid` FROM `cad_email_contacts` WHERE `id` = ? AND `owner` = ?',
        { id, owner }
    )
end

---Counts how many contacts a character has saved
---@param owner string
---@return integer
function DB.countContacts(owner)
    return MySQL.scalar.await('SELECT COUNT(*) FROM `cad_email_contacts` WHERE `owner` = ?', { owner }) or 0
end

---Finds a contact in the mail list by its Discord ID or Citizen ID
---@param owner string
---@param column 'discord_id'|'citizenid'
---@param value string
---@return ContactTarget?
function DB.findContact(owner, column, value)
    return MySQL.single.await(
        ('SELECT `id`, `label`, `discord_id`, `citizenid` FROM `cad_email_contacts` WHERE `owner` = ? AND `%s` = ?'):format(column),
        { owner, value }
    )
end

---Adds a new contact
---@param owner string
---@param label string
---@param discordId string
---@param citizenId? string
function DB.insertContact(owner, label, discordId, citizenId)
    MySQL.insert.await(
        'INSERT INTO `cad_email_contacts` (`owner`, `label`, `discord_id`, `citizenid`) VALUES (?, ?, ?, ?)',
        { owner, label, discordId, citizenId }
    )
end

---Changes a saved contact's name, Discord ID and Citizen ID
---@param owner string
---@param id integer
---@param label string
---@param discordId string
---@param citizenId? string
function DB.updateContact(owner, id, label, discordId, citizenId)
    MySQL.update.await(
        'UPDATE `cad_email_contacts` SET `label` = ?, `discord_id` = ?, `citizenid` = ? WHERE `id` = ? AND `owner` = ?',
        { label, discordId, citizenId, id, owner }
    )
end

---Saves a newer Discord ID on a contact (when the person switched Discord accounts)
---@param id integer
---@param discordId string
function DB.setContactDiscord(id, discordId)
    MySQL.update.await('UPDATE IGNORE `cad_email_contacts` SET `discord_id` = ? WHERE `id` = ?', { discordId, id })
end

---Remembers which Discord account a character uses
---@param citizenId string
---@param discordId string
function DB.saveAccount(citizenId, discordId)
    MySQL.insert.await(
        'INSERT INTO `cad_email_accounts` (`citizenid`, `discord_id`) VALUES (?, ?) ON DUPLICATE KEY UPDATE `discord_id` = VALUES(`discord_id`)',
        { citizenId, discordId }
    )
end

---Gets the last known Discord ID of a character
---@param citizenId string
---@return string?
function DB.getAccountDiscord(citizenId)
    return MySQL.scalar.await('SELECT `discord_id` FROM `cad_email_accounts` WHERE `citizenid` = ?', { citizenId })
end

---Removes a contact. Only works on the owner's own contacts.
---@param owner string
---@param id integer
---@return boolean removed
function DB.deleteContact(owner, id)
    local changed = MySQL.update.await('DELETE FROM `cad_email_contacts` WHERE `id` = ? AND `owner` = ?', { id, owner })
    return (changed or 0) > 0
end

---Gets a character's latest sent mails, newest first
---@param owner string
---@param limit integer
---@return HistoryRow[]
function DB.getHistory(owner, limit)
    return MySQL.query.await([[
        SELECT `id`, COALESCE(`recipient_label`, `recipient_id`) AS `recipient`, `subject`, `body`,
               `status`, `error`, UNIX_TIMESTAMP(`created_at`) AS `sent_at`
        FROM `cad_email_history` WHERE `owner` = ? ORDER BY `id` DESC LIMIT ?
    ]], { owner, limit }) or {}
end

---Saves a send attempt (delivered or failed)
---@param entry HistoryEntry
function DB.addHistory(entry)
    MySQL.insert.await([[
        INSERT INTO `cad_email_history`
            (`owner`, `sender_name`, `sender_email`, `recipient_id`, `recipient_label`, `subject`, `body`, `status`, `error_code`, `error`)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
    ]], {
        entry.owner, entry.sender_name, entry.sender_email, entry.recipient_id, entry.recipient_label,
        entry.subject, entry.body, entry.status, entry.error_code, entry.error,
    })
end

---Gets the latest failed sends on the whole server
---@param limit integer
---@return table[]
function DB.getRecentFailures(limit)
    return MySQL.query.await([[
        SELECT `sender_name`, COALESCE(`recipient_label`, `recipient_id`) AS `recipient`, `subject`, `error_code`, `error`,
               DATE_FORMAT(`created_at`, '%Y-%m-%d %H:%i') AS `time`
        FROM `cad_email_history` WHERE `status` = 'failed' ORDER BY `id` DESC LIMIT ?
    ]], { limit }) or {}
end
