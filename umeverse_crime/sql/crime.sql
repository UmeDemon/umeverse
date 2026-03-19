-- Umeverse Crime System Database Tables

CREATE TABLE IF NOT EXISTS `umeverse_crime_logs` (
    `id` INT PRIMARY KEY AUTO_INCREMENT,
    `identifier` VARCHAR(255) NOT NULL,
    `crime_type` VARCHAR(100) NOT NULL,
    `success` TINYINT(1) NOT NULL DEFAULT 0,
    `reward` INT DEFAULT 0,
    `heat_generated` INT DEFAULT 0,
    `timestamp` BIGINT NOT NULL,
    KEY `idx_identifier` (`identifier`),
    KEY `idx_crime_type` (`crime_type`),
    KEY `idx_timestamp` (`timestamp`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS `umeverse_crime_specializations` (
    `id` INT PRIMARY KEY AUTO_INCREMENT,
    `identifier` VARCHAR(255) UNIQUE NOT NULL,
    `specialization` VARCHAR(100) NOT NULL,
    `level` INT DEFAULT 1,
    `experience` INT DEFAULT 0,
    `unlocked_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS `umeverse_player_heat` (
    `id` INT PRIMARY KEY AUTO_INCREMENT,
    `identifier` VARCHAR(255) UNIQUE NOT NULL,
    `current_heat` INT DEFAULT 0,
    `heat_level` VARCHAR(50) DEFAULT 'low',
    `last_updated` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    KEY `idx_identifier` (`identifier`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS `umeverse_crime_stats` (
    `id` INT PRIMARY KEY AUTO_INCREMENT,
    `identifier` VARCHAR(255) UNIQUE NOT NULL,
    `total_crimes` INT DEFAULT 0,
    `successful_crimes` INT DEFAULT 0,
    `failed_crimes` INT DEFAULT 0,
    `total_earned` INT DEFAULT 0,
    `arrest_count` INT DEFAULT 0,
    `wanted_level` INT DEFAULT 0,
    `last_crime` TIMESTAMP,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
