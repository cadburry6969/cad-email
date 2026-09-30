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
);

CREATE TABLE IF NOT EXISTS `cad_email_accounts` (
    `citizenid` VARCHAR(64) NOT NULL,
    `discord_id` VARCHAR(20) NOT NULL,
    `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`citizenid`)
);

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
);
