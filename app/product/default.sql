-- 商品初始化脚本
-- 先清空 products 表，然后插入默认商品数据
use product;

-- 清空现有商品数据
TRUNCATE TABLE products;

-- 插入默认商品数据
INSERT INTO products (id, name, description, picture, price, categories)
VALUES
    (1, '02.1', '02.1 description', 'https://cdn.pinduoduo.com/upload/home/img/index/seckill_v2.jpg', 5999.99, '["One", "Two"]'),
    (2, '02.2', '02.2 description', 'https://cdn.pinduoduo.com/upload/home/img/index/sale_v2.jpg', 79.99, '["One"]'),
    (3, '02.3', '02.3 description', 'https://cdn.pinduoduo.com/upload/home/img/index/supermarket_v2.jpg', 59.99, '["Two"]'),
    (4, '02.4', '02.4 description', 'https://cdn.pinduoduo.com/upload/home/img/subject/girlclothes.jpg', 39.99, '["One", "Two"]');

INSERT INTO products (id, name, description, picture, price, categories)
VALUES
    (5, '02.5', '02.5 description', 'https://cdn.pinduoduo.com/upload/home/img/subject/boyshirt.jpg', 599.99, '["One", "Two"]'),
    (6, '02.6', '02.6 description', 'https://cdn.pinduoduo.com/upload/894b1103-7ddb-4a94-a472-9991353a7504.png', 79.599, '["One"]'),
    (7, '02.7', '02.7 description', 'https://cdn.pinduoduo.com/upload/home/img/subject/food.jpg', 779.99, '["Two"]'),
    (8, '02.8', '02.8 description', 'https://cdn.pinduoduo.com/upload/official_website/6b1f700d-70c7-4f9f-890c-eb9f9ae68425.png', 39.99, '["One", "Two"]'),
    (9, '02.9', '02.9 description', 'https://cdn.pinduoduo.com/upload/home/img/subject/home.jpg', 39.99, '["One", "Two"]');

-- 显示插入结果
SELECT COUNT(*) as total_products FROM products;
