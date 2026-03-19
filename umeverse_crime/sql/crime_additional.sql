-- Umeverse Crime System - Additional Tables

-- Criminal records for player tracking
CREATE TABLE IF NOT EXISTS `umeverse_criminal_records` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `identifier` VARCHAR(50) NOT NULL,
    `crime_type` VARCHAR(100) NOT NULL,
    `recorded_at` BIGINT NOT NULL,
    `status` VARCHAR(50) DEFAULT 'active',
    `conviction` BOOLEAN DEFAULT FALSE,
    INDEX `idx_identifier` (`identifier`),
    INDEX `idx_timestamp` (`recorded_at`)
);

-- Bounty system
CREATE TABLE IF NOT EXISTS `umeverse_bounties` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `bounty_id` VARCHAR(50) UNIQUE NOT NULL,
    `target_identifier` VARCHAR(50) NOT NULL,
    `poster_identifier` VARCHAR(50) NOT NULL,
    `amount` INT NOT NULL,
    `reason` TEXT,
    `posted_at` BIGINT NOT NULL,
    `expires_at` BIGINT NOT NULL,
    `claimed_by` VARCHAR(50),
    `claimed_at` BIGINT,
    `status` VARCHAR(50) DEFAULT 'active',
    INDEX `idx_target` (`target_identifier`),
    INDEX `idx_status` (`status`)
);

-- Safehouse rentals
CREATE TABLE IF NOT EXISTS `umeverse_safehouse_rentals` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `rental_id` VARCHAR(50) UNIQUE NOT NULL,
    `identifier` VARCHAR(50) NOT NULL,
    `location_index` INT NOT NULL,
    `rented_at` BIGINT NOT NULL,
    `expires_at` BIGINT NOT NULL,
    `cost` INT NOT NULL,
    `status` VARCHAR(50) DEFAULT 'active',
    INDEX `idx_identifier` (`identifier`),
    INDEX `idx_status` (`status`)
);

-- Prison management
CREATE TABLE IF NOT EXISTS `umeverse_prison_records` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `identifier` VARCHAR(50) NOT NULL,
    `sentence_minutes` INT NOT NULL,
    `sentence_start` BIGINT NOT NULL,
    `sentence_end` BIGINT NOT NULL,
    `crime_type` VARCHAR(100),
    `officer` VARCHAR(100),
    `status` VARCHAR(50) DEFAULT 'active',
    INDEX `idx_identifier` (`identifier`),
    INDEX `idx_status` (`status`)
);
