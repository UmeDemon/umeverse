-- MI Tablet Gallery Table
-- Run this SQL to create the gallery table for photo storage

CREATE TABLE IF NOT EXISTS `mi_tablet_gallery` (
    `id` INT(11) NOT NULL AUTO_INCREMENT,
    `citizenid` VARCHAR(50) NOT NULL,
    `photo_url` TEXT NOT NULL,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    INDEX `idx_citizenid` (`citizenid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Optional: Add to your existing character cleanup procedures if needed
-- DELETE FROM mi_tablet_gallery WHERE citizenid = ?;
