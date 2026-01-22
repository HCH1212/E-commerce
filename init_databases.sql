-- E-commerce 项目数据库初始化脚本
-- 创建所有微服务需要的数据库

CREATE DATABASE IF NOT EXISTS `user` CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE DATABASE IF NOT EXISTS `product` CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE DATABASE IF NOT EXISTS `cart` CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE DATABASE IF NOT EXISTS `order` CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE DATABASE IF NOT EXISTS `payment` CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- 显示所有数据库
SHOW DATABASES;

-- 注意：商品表会由 GORM 的 AutoMigrate 自动创建
-- 商品初始化数据需要在服务启动后手动执行：app/product/default.sql
