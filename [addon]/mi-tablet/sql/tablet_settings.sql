-- MI Tablet Settings Table
-- Stores player tablet settings per character (citizenid)

CREATE TABLE IF NOT EXISTS `mi_tablet_settings` (
    `id` INT(11) NOT NULL AUTO_INCREMENT,
    `citizenid` VARCHAR(50) NOT NULL,
    `wallpaper` VARCHAR(50) DEFAULT 'default',
    `custom_wallpaper` TEXT DEFAULT NULL,
    `brightness` INT(3) DEFAULT 100,
    `dark_mode` TINYINT(1) DEFAULT 0,
    `volume` INT(3) DEFAULT 50,
    `notifications` TINYINT(1) DEFAULT 1,
    `font_size` VARCHAR(20) DEFAULT 'medium',
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    UNIQUE KEY `citizenid` (`citizenid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
