-- ═══════════════════════════════════════════════════════════════════
-- Umeverse Jobs - Enhancement Systems Database Migration
-- Run this SQL after progression.sql to add tables for all new systems
-- ═══════════════════════════════════════════════════════════════════

-- Add total_tasks and prestige columns to existing progression table
ALTER TABLE `umeverse_job_progression`
    ADD COLUMN IF NOT EXISTS `total_tasks` INT(11) NOT NULL DEFAULT 0,
    ADD COLUMN IF NOT EXISTS `prestige` INT(11) NOT NULL DEFAULT 0;

-- ═══════════════════════════════════════
-- Daily Challenges
-- ═══════════════════════════════════════
CREATE TABLE IF NOT EXISTS `umeverse_job_challenges` (
    `id` INT(11) NOT NULL AUTO_INCREMENT,
    `citizenid` VARCHAR(50) NOT NULL,
    `job_name` VARCHAR(50) NOT NULL,
    `challenge_id` VARCHAR(50) NOT NULL,
    `progress` INT(11) NOT NULL DEFAULT 0,
    `target` INT(11) NOT NULL DEFAULT 0,
    `completed` TINYINT(1) NOT NULL DEFAULT 0,
    `assigned_date` DATE NOT NULL,
    PRIMARY KEY (`id`),
    UNIQUE KEY `citizen_job_challenge_date` (`citizenid`, `job_name`, `challenge_id`, `assigned_date`),
    INDEX `idx_challenge_date` (`assigned_date`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ═══════════════════════════════════════
-- Milestones / Achievements
-- ═══════════════════════════════════════
CREATE TABLE IF NOT EXISTS `umeverse_job_milestones` (
    `id` INT(11) NOT NULL AUTO_INCREMENT,
    `citizenid` VARCHAR(50) NOT NULL,
    `achievement_id` VARCHAR(50) NOT NULL,
    `job_name` VARCHAR(50) DEFAULT NULL,   -- NULL for global milestones
    `unlocked_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    UNIQUE KEY `citizen_achievement_job` (`citizenid`, `achievement_id`, `job_name`),
    INDEX `idx_milestone_citizen` (`citizenid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ═══════════════════════════════════════
-- Contracts
-- ═══════════════════════════════════════
CREATE TABLE IF NOT EXISTS `umeverse_job_contracts` (
    `id` INT(11) NOT NULL AUTO_INCREMENT,
    `citizenid` VARCHAR(50) NOT NULL,
    `job_name` VARCHAR(50) NOT NULL,
    `contract_id` VARCHAR(50) NOT NULL,
    `tasks_done` INT(11) NOT NULL DEFAULT 0,
    `tasks_required` INT(11) NOT NULL,
    `started_at` BIGINT(20) NOT NULL,
    `expires_at` BIGINT(20) NOT NULL,
    `status` ENUM('active', 'completed', 'failed', 'abandoned') NOT NULL DEFAULT 'active',
    PRIMARY KEY (`id`),
    INDEX `idx_contract_citizen` (`citizenid`),
    INDEX `idx_contract_status` (`status`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ═══════════════════════════════════════
-- Global Stats (for leaderboards and global milestones)
-- ═══════════════════════════════════════
CREATE TABLE IF NOT EXISTS `umeverse_job_global_stats` (
    `id` INT(11) NOT NULL AUTO_INCREMENT,
    `citizenid` VARCHAR(50) NOT NULL,
    `night_shifts` INT(11) NOT NULL DEFAULT 0,
    `speed_bonuses` INT(11) NOT NULL DEFAULT 0,
    `perfect_shifts` INT(11) NOT NULL DEFAULT 0,
    `unique_jobs` TEXT DEFAULT NULL,           -- JSON array of job names worked
    PRIMARY KEY (`id`),
    UNIQUE KEY `citizen_global` (`citizenid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ═══════════════════════════════════════
-- Mentorship
-- ═══════════════════════════════════════
CREATE TABLE IF NOT EXISTS `umeverse_job_mentorship` (
    `id` INT(11) NOT NULL AUTO_INCREMENT,
    `mentor_citizenid` VARCHAR(50) NOT NULL,
    `mentee_citizenid` VARCHAR(50) NOT NULL,
    `job_name` VARCHAR(50) NOT NULL,
    `started_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    `active` TINYINT(1) NOT NULL DEFAULT 1,
    PRIMARY KEY (`id`),
    INDEX `idx_mentor` (`mentor_citizenid`),
    INDEX `idx_mentee` (`mentee_citizenid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
