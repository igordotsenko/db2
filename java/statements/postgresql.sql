SELECT * FROM shop.categories;
-- #1 Создать базу данных shop.
CREATE DATABASE shop;
CREATE SCHEMA shop;

--#2 Создать юзера shop и дать ему полный доступ к БД shop.
CREATE USER shop;
GRANT ALL PRIVILEGES ON DATABASE shop TO shop;

--#3 Создать юзера viewer и дать ему доступ на чтение БД shop.
CREATE USER view;
GRANT SELECT ON ALL TABLES IN SCHEMA shop TO view;

--#4 Создать таблицу для хранения категорий (хранить название).
CREATE TABLE shop.categories (
   id INTEGER PRIMARY KEY,
   category_name TEXT 
);

--#5 Добавить несколько категорий.
INSERT INTO shop.categories(id, category_name)
	VALUES (1, 'drugs');
INSERT INTO shop.categories (id, category_name)
	VALUES (2, 'guns');
INSERT INTO shop.categories (id, category_name)
	VALUES (3, 'dildos');

--#6 Создать таблицу для хранения товаров (название, категория, цена).
CREATE TABLE shop.products (
	id INTEGER PRIMARY KEY,
	product_name TEXT,
	category TEXT,
	price MONEY,
	FOREIGN KEY(category) REFERENCES shop.categories(category_name)
);

--#7 Внести несколько товаров по цене 1.00
INSERT INTO products(id, product_name, category, price) VALUES 
	(1, "cocainum", "drugs", 1.00 ),
	(2, "big gun", "guns", 1.00),
	(3, "big black dildo", "dildos", 1.00),
	(4, "blue meth", "drugs", 1.00),
	(5, "exterminatus gun", "guns", 1.00),
	(6, "little dildy", "dildos", 1.00);

--#8 Обновить цену первого товара — 3.50
UPDATE products
SET price = 3.50
WHERE id = 1;

--#9 Увеличить цену всех товаров на 10%.
UPDATE products
SET price = price * 1.1;

--#10 Удалить товар № 2.
DELETE FROM products
WHERE id = 2;

--#11 Выбрать все товары с сортировкой по названию.
SELECT product_name
FROM products
ORDER BY product_name;

--#12 Выбрать все товары с сортировкой по убыванию цены.
SELECT product_name, price
FROM products
ORDER BY price DESC;

--#13 Выбрать 3 самых дорогих товара.
SELECT product_name, price
FROM products
ORDER BY price DESC
LIMIT 3;

--#14 Выбрать 3 самых дешевых товара.
SELECT product_name, price
FROM products
ORDER BY price ASC
LIMIT 3;

--#15 Выбрать вторую тройку самых дорогих товаров (с 4 по 6).
SELECT product_name, price
FROM products
ORDER BY price DESC
LIMIT 3, 6;

--#16 Выбрать наименование самого дорогого товара.
SELECT product_name, MAX(price) 
FROM products;

--#17 Выбрать наименование самого дешевого товара.
SELECT product_name, MIN(price) 
FROM products;

--#18 Выбрать количество всех товаров.
SELECT COUNT(*) 
FROM products;

--#19 Выбрать среднюю цену всех товаров.
SELECT AVG(price) 
FROM products;

--#20 Создать представление (create view) с отображением 3 самых дорогих товаров. 
CREATE VIEW expensive_products AS
SELECT id, product_name, category, price
FROM products
ORDER BY price DESC
LIMIT 3;