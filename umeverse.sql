-- ╔══════════════════════════════════════════════════════════════╗
-- ║              Umeverse Framework - Database Schema           ║
-- ║              Run this SQL before starting the server        ║
-- ╚══════════════════════════════════════════════════════════════╝

-- ──────────────────────────────────────
-- Players / Characters
-- ──────────────────────────────────────

CREATE TABLE IF NOT EXISTS `umeverse_players` (
    `id`            INT(11)         NOT NULL AUTO_INCREMENT,
    `identifier`    VARCHAR(64)     NOT NULL,
    `citizenid`     VARCHAR(50)     NOT NULL,
    `firstname`     VARCHAR(50)     DEFAULT '',
    `lastname`      VARCHAR(50)     DEFAULT '',
    `charinfo`      LONGTEXT        DEFAULT '{}',
    `money`         LONGTEXT        DEFAULT '{"cash":5000,"bank":10000,"black":0}',
    `job`           LONGTEXT        DEFAULT '{"name":"unemployed","label":"Unemployed","grade":0,"gradelabel":"Freelancer","onduty":false}',
    `position`      LONGTEXT        DEFAULT '{"x":-269.4,"y":-955.3,"z":31.2,"heading":205.0}',
    `inventory`     LONGTEXT        DEFAULT '[]',
    `status`        LONGTEXT        DEFAULT '{"hunger":100,"thirst":100,"stress":0}',
    `skin`          LONGTEXT        DEFAULT '{}',
    `metadata`      LONGTEXT        DEFAULT '{}',
    `is_dead`       TINYINT(1)      DEFAULT 0,
    `last_login`    TIMESTAMP       DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    `created_at`    TIMESTAMP       DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uk_citizenid` (`citizenid`),
    KEY `idx_identifier` (`identifier`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ──────────────────────────────────────
-- Bans
-- ──────────────────────────────────────

CREATE TABLE IF NOT EXISTS `umeverse_bans` (
    `id`            INT(11)         NOT NULL AUTO_INCREMENT,
    `identifier`    VARCHAR(64)     DEFAULT NULL,
    `citizenid`     VARCHAR(50)     DEFAULT NULL,
    `reason`        TEXT            DEFAULT NULL,
    `banned_by`     VARCHAR(100)    DEFAULT 'System',
    `permanent`     TINYINT(1)      DEFAULT 0,
    `expires`       DATETIME        DEFAULT NULL,
    `created_at`    TIMESTAMP       DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    KEY `idx_ban_identifier` (`identifier`),
    KEY `idx_ban_citizenid` (`citizenid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ──────────────────────────────────────
-- Vehicles
-- ──────────────────────────────────────

CREATE TABLE IF NOT EXISTS `umeverse_vehicles` (
    `id`            INT(11)         NOT NULL AUTO_INCREMENT,
    `citizenid`     VARCHAR(50)     NOT NULL,
    `plate`         VARCHAR(10)     NOT NULL,
    `model`         VARCHAR(50)     NOT NULL,
    `state`         TINYINT(1)      DEFAULT 1 COMMENT '0=out, 1=garaged, 2=impounded',
    `garage`        VARCHAR(50)     DEFAULT 'legion',
    `job`           VARCHAR(50)     DEFAULT NULL COMMENT 'NULL = personal, otherwise job name',
    `fuel`          INT(3)          DEFAULT 100,
    `body`          FLOAT           DEFAULT 1000.0,
    `engine`        FLOAT           DEFAULT 1000.0,
    `mods`          LONGTEXT        DEFAULT '{}',
    `created_at`    TIMESTAMP       DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uk_plate` (`plate`),
    KEY `idx_veh_citizenid` (`citizenid`),
    KEY `idx_veh_state` (`state`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ──────────────────────────────────────
-- Stashes (Inventory)
-- ──────────────────────────────────────

CREATE TABLE IF NOT EXISTS `umeverse_stashes` (
    `stash_id`      VARCHAR(100)    NOT NULL,
    `inventory`     LONGTEXT        DEFAULT '[]',
    `updated_at`    TIMESTAMP       DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`stash_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ──────────────────────────────────────
-- Banking Transactions
-- ──────────────────────────────────────

CREATE TABLE IF NOT EXISTS `umeverse_transactions` (
    `id`            INT(11)         NOT NULL AUTO_INCREMENT,
    `citizenid`     VARCHAR(50)     NOT NULL,
    `type`          VARCHAR(20)     NOT NULL COMMENT 'deposit, withdraw, transfer_in, transfer_out',
    `amount`        INT(11)         NOT NULL DEFAULT 0,
    `description`   VARCHAR(255)    DEFAULT '',
    `created_at`    TIMESTAMP       DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    KEY `idx_tx_citizenid` (`citizenid`),
    KEY `idx_tx_type` (`type`),
    KEY `idx_tx_created` (`created_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ──────────────────────────────────────
-- Owned Keys (Vehicle Keys Persistence)
-- ──────────────────────────────────────

CREATE TABLE IF NOT EXISTS `umeverse_vehicle_keys` (
    `id`            INT(11)         NOT NULL AUTO_INCREMENT,
    `plate`         VARCHAR(10)     NOT NULL,
    `citizenid`     VARCHAR(50)     NOT NULL,
    `granted_at`    TIMESTAMP       DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uk_plate_citizen` (`plate`, `citizenid`),
    KEY `idx_key_citizenid` (`citizenid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
