-- ============================================================
--  UmeVerse SQL Schema
--  Tested against MySQL 5.7+ and MariaDB 10.3+.
--  Import once before starting the server:
--    mysql -u root -p your_database < sql/umeverse.sql
-- ============================================================

CREATE TABLE IF NOT EXISTS `umeverse_players` (
    `id`         INT UNSIGNED    NOT NULL AUTO_INCREMENT,
    `identifier` VARCHAR(60)     NOT NULL,
    `name`       VARCHAR(100)    NOT NULL DEFAULT 'Unknown',
    `cash`       INT UNSIGNED    NOT NULL DEFAULT 0,
    `bank`       INT UNSIGNED    NOT NULL DEFAULT 0,
    `job`        LONGTEXT        DEFAULT NULL COMMENT 'JSON: {name, label, grade, salary}',
    `inventory`  LONGTEXT        DEFAULT NULL COMMENT 'JSON: {[item]={name,count,weight}}',
    `metadata`   LONGTEXT        DEFAULT NULL COMMENT 'JSON: arbitrary key/value pairs',
    `last_x`     FLOAT           DEFAULT NULL COMMENT 'Last saved X coordinate',
    `last_y`     FLOAT           DEFAULT NULL COMMENT 'Last saved Y coordinate',
    `last_z`     FLOAT           DEFAULT NULL COMMENT 'Last saved Z coordinate',
    `last_heading` FLOAT         DEFAULT NULL COMMENT 'Last saved heading (degrees)',
    `created_at` TIMESTAMP       NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP       NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uq_identifier` (`identifier`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
