-- ═══════════════════════════════════════════════════════════════
-- Umeverse Drug System - Database Tables
-- ═══════════════════════════════════════════════════════════════

-- Warehouse rentals
CREATE TABLE IF NOT EXISTS `umeverse_drug_warehouses` (
    `id` INT NOT NULL AUTO_INCREMENT,
    `warehouse_id` VARCHAR(50) NOT NULL,
    `citizenid` VARCHAR(50) NOT NULL,
    `expires` DATETIME NOT NULL,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    UNIQUE KEY `unique_warehouse` (`warehouse_id`),
    INDEX `idx_citizenid` (`citizenid`),
    INDEX `idx_expires` (`expires`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Laundering transaction log
CREATE TABLE IF NOT EXISTS `umeverse_drug_transactions` (
    `id` INT NOT NULL AUTO_INCREMENT,
    `citizenid` VARCHAR(50) NOT NULL,
    `type` VARCHAR(20) NOT NULL COMMENT 'launder, sale',
    `dirty_amount` INT DEFAULT 0,
    `clean_amount` INT DEFAULT 0,
    `location` VARCHAR(100) DEFAULT NULL,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    INDEX `idx_citizenid` (`citizenid`),
    INDEX `idx_type` (`type`),
    INDEX `idx_created` (`created_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Drug specialization XP (per-drug skill trees)
CREATE TABLE IF NOT EXISTS `umeverse_drug_specialization` (
    `id` INT NOT NULL AUTO_INCREMENT,
    `citizenid` VARCHAR(50) NOT NULL,
    `drug_key` VARCHAR(30) NOT NULL,
    `xp` INT DEFAULT 0,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    UNIQUE KEY `unique_spec` (`citizenid`, `drug_key`),
    INDEX `idx_citizenid` (`citizenid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Dynamic pricing demand state per corner per drug
CREATE TABLE IF NOT EXISTS `umeverse_drug_demand` (
    `id` INT NOT NULL AUTO_INCREMENT,
    `corner_index` INT NOT NULL,
    `drug_key` VARCHAR(30) NOT NULL,
    `demand` INT DEFAULT 60,
    `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    UNIQUE KEY `unique_demand` (`corner_index`, `drug_key`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Turf ownership
CREATE TABLE IF NOT EXISTS `umeverse_drug_turf` (
    `id` INT NOT NULL AUTO_INCREMENT,
    `corner_index` INT NOT NULL,
    `citizenid` VARCHAR(50) NOT NULL,
    `captured_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    `last_online` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    UNIQUE KEY `unique_turf` (`corner_index`),
    INDEX `idx_citizenid` (`citizenid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Player heat levels
CREATE TABLE IF NOT EXISTS `umeverse_drug_heat` (
    `id` INT NOT NULL AUTO_INCREMENT,
    `citizenid` VARCHAR(50) NOT NULL,
    `heat` INT DEFAULT 0,
    `last_activity` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    UNIQUE KEY `unique_heat` (`citizenid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- NPC buyer reputation per corner per player
CREATE TABLE IF NOT EXISTS `umeverse_drug_buyer_rep` (
    `id` INT NOT NULL AUTO_INCREMENT,
    `citizenid` VARCHAR(50) NOT NULL,
    `corner_index` INT NOT NULL,
    `rep` INT DEFAULT 0,
    `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    UNIQUE KEY `unique_buyer` (`citizenid`, `corner_index`),
    INDEX `idx_citizenid` (`citizenid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
