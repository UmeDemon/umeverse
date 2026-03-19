-- ═══════════════════════════════════════════════════════════════════
-- Umeverse Jobs - Progression System Database Migration
-- Run this SQL against your database to add the job progression table
-- ═══════════════════════════════════════════════════════════════════

CREATE TABLE IF NOT EXISTS `umeverse_job_progression` (
    `id` INT(11) NOT NULL AUTO_INCREMENT,
    `citizenid` VARCHAR(50) NOT NULL,
    `job_name` VARCHAR(50) NOT NULL,
    `xp` INT(11) NOT NULL DEFAULT 0,
    `streak_count` INT(11) NOT NULL DEFAULT 0,
    `last_shift_time` BIGINT(20) NOT NULL DEFAULT 0,
    `total_shifts` INT(11) NOT NULL DEFAULT 0,
    `total_earned` BIGINT(20) NOT NULL DEFAULT 0,
    PRIMARY KEY (`id`),
    UNIQUE KEY `citizen_job` (`citizenid`, `job_name`),
    INDEX `idx_citizenid` (`citizenid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
