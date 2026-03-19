-- Umeverse Gangs System Database Tables

CREATE TABLE IF NOT EXISTS `umeverse_gangs` (
    `id` INT PRIMARY KEY AUTO_INCREMENT,
    `gang_name` VARCHAR(100) UNIQUE NOT NULL,
    `label` VARCHAR(255) NOT NULL,
    `leader_id` VARCHAR(255) NOT NULL,
    `bank_balance` INT DEFAULT 0,
    `reputation` INT DEFAULT 0,
    `founded_date` BIGINT NOT NULL,
    `disbanded_date` BIGINT,
    `territory` VARCHAR(100) DEFAULT 'none',
    `color` INT DEFAULT 0,
    `description` TEXT,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    KEY `idx_gang_name` (`gang_name`),
    KEY `idx_leader_id` (`leader_id`),
    KEY `idx_territory` (`territory`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS `umeverse_gang_members` (
    `id` INT PRIMARY KEY AUTO_INCREMENT,
    `identifier` VARCHAR(255) NOT NULL,
    `gang_name` VARCHAR(100) NOT NULL,
    `rank` INT DEFAULT 0,
    `joined_date` BIGINT NOT NULL,
    `reputation` INT DEFAULT 0,
    `wars_participated` INT DEFAULT 0,
    `crimes_completed` INT DEFAULT 0,
    `earnings` INT DEFAULT 0,
    `left_date` BIGINT,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    UNIQUE KEY `unique_member` (`identifier`, `gang_name`),
    KEY `idx_gang_name` (`gang_name`),
    KEY `idx_identifier` (`identifier`),
    FOREIGN KEY (`gang_name`) REFERENCES `umeverse_gangs` (`gang_name`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS `umeverse_gang_territories` (
    `id` INT PRIMARY KEY AUTO_INCREMENT,
    `territory_name` VARCHAR(100) UNIQUE NOT NULL,
    `gang_name` VARCHAR(100),
    `influence_level` INT DEFAULT 0,
    `contested` TINYINT(1) DEFAULT 0,
    `drug_multiplier` FLOAT DEFAULT 1.0,
    `contested_by` VARCHAR(100),
    `last_contested` BIGINT,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    KEY `idx_gang_name` (`gang_name`),
    KEY `idx_territory` (`territory_name`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS `umeverse_gang_wars` (
    `id` INT PRIMARY KEY AUTO_INCREMENT,
    `attacker_gang` VARCHAR(100) NOT NULL,
    `defender_gang` VARCHAR(100) NOT NULL,
    `territory_name` VARCHAR(100),
    `started_at` BIGINT NOT NULL,
    `ended_at` BIGINT,
    `winner` VARCHAR(100),
    `attacker_kills` INT DEFAULT 0,
    `defender_kills` INT DEFAULT 0,
    `status` VARCHAR(50) DEFAULT 'active',
    `reason` TEXT,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    KEY `idx_attacker` (`attacker_gang`),
    KEY `idx_defender` (`defender_gang`),
    KEY `idx_status` (`status`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS `umeverse_gang_stash` (
    `id` INT PRIMARY KEY AUTO_INCREMENT,
    `gang_name` VARCHAR(100) UNIQUE NOT NULL,
    `weapons` JSON,
    `items` JSON,
    `capacity_used` INT DEFAULT 0,
    `max_capacity` INT DEFAULT 500000,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (`gang_name`) REFERENCES `umeverse_gangs` (`gang_name`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS `umeverse_gang_enterprises` (
    `id` INT PRIMARY KEY AUTO_INCREMENT,
    `gang_name` VARCHAR(100) NOT NULL,
    `enterprise_type` VARCHAR(100) NOT NULL,
    `active` TINYINT(1) DEFAULT 1,
    `revenue` INT DEFAULT 0,
    `last_run` BIGINT,
    `runs_completed` INT DEFAULT 0,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    KEY `idx_gang_name` (`gang_name`),
    KEY `idx_enterprise_type` (`enterprise_type`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Insert default gangs
INSERT INTO `umeverse_gangs` (gang_name, label, leader_id, founded_date, territory, description) VALUES
    ('ballas', 'The Ballas', 'system', UNIX_TIMESTAMP(), 'south_ls', 'South Los Santos criminal organization'),
    ('families', 'Families', 'system', UNIX_TIMESTAMP(), 'grove_street', 'Grove Street families crew'),
    ('vagos', 'Los Santos Vagos', 'system', UNIX_TIMESTAMP(), 'east_ls', 'East Los Santos street gang'),
    ('lost', 'The Lost MC', 'system', UNIX_TIMESTAMP(), 'north_ls', 'Motorcycle club'),
    ('mexican', 'Cartel Del Los Santos', 'system', UNIX_TIMESTAMP(), 'vinewood', 'Drug trafficking organization')
ON DUPLICATE KEY UPDATE updated_at = CURRENT_TIMESTAMP;

-- Insert default territories
INSERT INTO `umeverse_gang_territories` (territory_name, gang_name, influence_level, drug_multiplier) VALUES
    ('south_ls', 'ballas', 100, 1.5),
    ('grove_street', 'families', 100, 1.5),
    ('east_ls', 'vagos', 100, 1.5),
    ('north_ls', 'lost', 100, 1.3),
    ('vinewood', 'mexican', 100, 1.8)
ON DUPLICATE KEY UPDATE updated_at = CURRENT_TIMESTAMP;
