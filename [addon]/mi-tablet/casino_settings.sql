-- Casino Settings Table for MI Tablet
-- Stores casino configuration like current podium vehicle

CREATE TABLE IF NOT EXISTS `casino_settings` (
    `setting` VARCHAR(50) NOT NULL PRIMARY KEY,
    `value` TEXT NOT NULL,
    `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Insert default podium vehicle setting
INSERT INTO `casino_settings` (`setting`, `value`) VALUES ('podium_vehicle', 'Not Set')
ON DUPLICATE KEY UPDATE `setting` = `setting`;
