-- Umeverse Gangs System - Additional Tables

-- Gang infrastructure upgrades
CREATE TABLE IF NOT EXISTS `umeverse_gang_infrastructure` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `gang_name` VARCHAR(100) NOT NULL,
    `type` VARCHAR(50) NOT NULL,
    `level` INT DEFAULT 1,
    `xp` INT DEFAULT 0,
    `created_at` BIGINT,
    UNIQUE KEY `idx_gang_type` (`gang_name`, `type`),
    INDEX `idx_gang` (`gang_name`)
);

-- Gang alliances
CREATE TABLE IF NOT EXISTS `umeverse_gang_alliances` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `alliance_id` VARCHAR(50) UNIQUE NOT NULL,
    `gang1` VARCHAR(100) NOT NULL,
    `gang2` VARCHAR(100) NOT NULL,
    `type` VARCHAR(50) NOT NULL,
    `start_time` BIGINT NOT NULL,
    `duration` INT NOT NULL,
    `active` BOOLEAN DEFAULT FALSE,
    `created_at` BIGINT,
    INDEX `idx_gang1` (`gang1`),
    INDEX `idx_gang2` (`gang2`),
    INDEX `idx_active` (`active`)
);

-- Territory expansion missions
CREATE TABLE IF NOT EXISTS `umeverse_territory_expansion` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `mission_id` VARCHAR(50) UNIQUE NOT NULL,
    `gang_name` VARCHAR(100) NOT NULL,
    `player_id` VARCHAR(50) NOT NULL,
    `mission_type` VARCHAR(50) NOT NULL,
    `reward` INT NOT NULL,
    `influence_reward` INT NOT NULL,
    `start_time` BIGINT NOT NULL,
    `duration` INT NOT NULL,
    `status` VARCHAR(50) DEFAULT 'active',
    INDEX `idx_gang` (`gang_name`),
    INDEX `idx_player` (`player_id`),
    INDEX `idx_status` (`status`)
);

-- Gang messages (board)
CREATE TABLE IF NOT EXISTS `umeverse_gang_messages` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `gang_name` VARCHAR(100) NOT NULL,
    `author` VARCHAR(50) NOT NULL,
    `title` VARCHAR(255) NOT NULL,
    `content` TEXT,
    `posted_at` BIGINT NOT NULL,
    `deleted_at` BIGINT,
    INDEX `idx_gang` (`gang_name`),
    INDEX `idx_posted` (`posted_at`)
);

-- Gang challenges (weekly)
CREATE TABLE IF NOT EXISTS `umeverse_gang_challenges` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `challenge_id` VARCHAR(50) UNIQUE NOT NULL,
    `gang_name` VARCHAR(100) NOT NULL,
    `type` VARCHAR(50) NOT NULL,
    `target` INT NOT NULL,
    `reward` INT NOT NULL,
    `start_time` BIGINT NOT NULL,
    `end_time` BIGINT NOT NULL,
    `created_at` BIGINT,
    INDEX `idx_gang` (`gang_name`),
    INDEX `idx_active` (`end_time`)
);

-- Gang tournaments (monthly)
CREATE TABLE IF NOT EXISTS `umeverse_gang_tournaments` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `tournament_id` VARCHAR(50) UNIQUE NOT NULL,
    `gang_name` VARCHAR(100) NOT NULL,
    `start_time` BIGINT NOT NULL,
    `end_time` BIGINT NOT NULL,
    `winner_id` VARCHAR(50),
    `winner_score` INT,
    `created_at` BIGINT,
    INDEX `idx_gang` (`gang_name`),
    INDEX `idx_active` (`end_time`)
);

-- Gang member activity tracking
CREATE TABLE IF NOT EXISTS `umeverse_gang_member_activity` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `gang_name` VARCHAR(100) NOT NULL,
    `identifier` VARCHAR(50) NOT NULL,
    `activity_type` VARCHAR(50) NOT NULL,
    `amount` INT NOT NULL,
    `description` TEXT,
    `logged_at` BIGINT NOT NULL,
    INDEX `idx_gang` (`gang_name`),
    INDEX `idx_identifier` (`identifier`),
    INDEX `idx_logged` (`logged_at`)
);

-- Gang customization
CREATE TABLE IF NOT EXISTS `umeverse_gang_customization` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `gang_name` VARCHAR(100) UNIQUE NOT NULL,
    `primary_color` VARCHAR(7),
    `secondary_color` VARCHAR(7),
    `logo_url` TEXT,
    `description` TEXT,
    `headquarters_coords` VARCHAR(100),
    `custom_flag` TEXT,
    `updated_at` BIGINT,
    INDEX `idx_gang` (`gang_name`)
);
