-- 如果数据库是新建的，先执行该sql插入一些默认数据
use product;
INSERT INTO products (id, name, description, picture, price, categories)
VALUES
    (1, '02.1', '02.1 description', 'https://tuchuang.hch1212.online/img/02.webp', 5999.99, '["one", "two"]'),
    (2, '02.2', '02.2 description', 'https://tuchuang.hch1212.online/img/021.webp', 79.99, '["one"]'),
    (3, '02.3', '02.3 description', 'https://tuchuang.hch1212.online/img/0210.webp', 59.99, '["two"]'),
    (4, '02.4', '02.4 description', 'https://tuchuang.hch1212.online/img/0211.webp', 39.99, '["one", "two"]');
INSERT INTO products (id, name, description, picture, price, categories)
VALUES
    (5, '02.5', '02.5 description', 'https://tuchuang.hch1212.online/img/0212.webp', 599.99, '["one", "two"]'),
    (6, '02.6', '02.6 description', 'https://tuchuang.hch1212.online/img/0213.webp', 79.599, '["one"]'),
    (7, '02.7', '02.7 description', 'https://tuchuang.hch1212.online/img/0214.webp', 779.99, '["two"]'),
    (8, '02.8', '02.8 description', 'https://tuchuang.hch1212.online/img/0215.webp', 39.99, '["one", "two"]'),
    (9, '02.9', '02.9 description', 'https://tuchuang.hch1212.online/img/0216.webp', 39.99, '["one", "two"]');


