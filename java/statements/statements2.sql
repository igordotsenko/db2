-- Вывести все товары и категорию, в которой они находятся.
SELECT 
	I.item_name, 
	C.category_title 
FROM 
	item I 
INNER JOIN 
	category C ON I.category_id = C.category_id;

--Вывести все товары из конкретного заказа.
SELECT 
	I.* 
FROM 
	item__order I_O 
INNER JOIN 
	item I ON I_O.item_id = I.item_id 
WHERE I_O.order_id = ?;

--Вывести все заказы с конкретной единицей товара.
SELECT 
	O.* 
FROM 
	item__order I_O 
INNER JOIN 
	"order" O ON I_O.order_id = O.order_id 
WHERE I_O.item_id = ?;

--Вывести все товары, заказанные за последний час.
SELECT 
	I.* 
FROM 
	item__order I_O 
INNER JOIN 
	"order" O ON I_O.order_id = O.order_id 
INNER JOIN 
	item I ON I_O.item_id = I.item_id 
WHERE 
	O.order_created >= now() - interval '1h';

--Вывести все товары, заказанные за сегодня.
SELECT 
	I.* 
FROM 
	item__order I_O 
INNER JOIN 
	"order" O ON I_O.order_id = O.order_id 
INNER JOIN 
	item I ON I_O.item_id = I.item_id 
WHERE 
	DATE(O.order_created) = now()::date;

--Вывести все товары, заказанные за вчера.
SELECT 
	I.* 
FROM 
	item__order I_O 
INNER JOIN 
	"order" O ON I_O.order_id = O.order_id 
INNER JOIN 
	item I ON I_O.item_id = I.item_id 
WHERE 
	O.order_created > current_date - 1;

--Вывести все товары из заданной категории, заказанные за последний час.
SELECT 
	I.* 
FROM 
	item__order I_O 
INNER JOIN 
	"order" O ON I_O.order_id = O.order_id 
INNER JOIN 
	item I ON I_O.item_id = I.item_id 
WHERE 
	O.order_created >= now() - interval '1h' AND I.category_id = ?;

-- Вывести все товары из заданной категории, заказанные за сегодня.
SELECT 
	I.* 
FROM 
	item__order I_O 
INNER JOIN 
	"order" O ON I_O.order_id = O.order_id 
INNER JOIN 
	item I ON I_O.item_id = I.item_id 
WHERE 
	DATE(O.order_created) = now()::date AND I.category_id = ?;

-- Вывести все товары из заданной категории, заказанные за вчера.
SELECT 
	I.* 
FROM 
	item__order I_O 
INNER JOIN 
	"order" O ON I_O.order_id = O.order_id 
INNER JOIN 
	item I ON I_O.item_id = I.item_id 
WHERE 
	O.order_created > current_date - 1 AND I.category_id = ?;

-- Вывести все товары, названия которых начинаются с заданной последовательности букв (см. LIKE).
SELECT * FROM 
	item 
WHERE 
	lower(item_name) LIKE '?%';

-- Вывести все товары, названия которых заканчиваются заданной последовательностью букв (см. LIKE).
SELECT * FROM 
	item 
WHERE 
	lower(item_name) LIKE '%?%';

-- Вывести все товары, названия которых содержат заданные последовательности букв (см. LIKE).
SELECT * FROM 
	item 
WHERE 
	lower(item_name) LIKE '%?%';

-- Вывести список категорий и количество товаров в каждой категории.
SELECT 
	C.*, 
	count(*) AS item_count 
FROM 
	category C, 
	item I 
WHERE 
	C.category_id = I.category_id 
GROUP BY 
	C.category_id 
ORDER BY 
	category_id ASC;

-- Вывести список всех заказов и количество товаров в каждом.
SELECT 
	O.*, 
	count(*) AS item_count 
FROM 
	"order" O, item__order I_O 
WHERE 
	O.order_id = I_O.order_id 
GROUP BY 
	O.order_id 
ORDER BY 
	item_count DESC;

-- Вывести список всех товаров и количество заказов, в которых имеется этот товар.
SELECT 
	I.*, 
	count(*) AS order_count 
FROM 
	item I, 
	item__order I_O 
WHERE 
	I.item_id = I_O.item_id 
GROUP BY 
	I.item_id 
ORDER BY 
	order_count DESC;

-- Вывести список заказов, упорядоченный по дате заказа и суммарную стоимость товаров в каждом из них.
SELECT 
	O.*, 
	sum(I_O.item__order_quantity * I.item_price) AS total_sum 
FROM 
	"order" O  
INNER JOIN 
		item__order I_O ON I_O.order_id = O.order_id 
INNER JOIN 
	item I ON I_O.item_id = I.item_id 
WHERE 
	I_O.item_id = I.item_id 
GROUP BY 
	O.order_id 
ORDER BY 
	O.order_created DESC;

-- Вывести список товаров, цену, количество и суммарную стоимость каждого из них в заказе с заданным ID.
SELECT 
	I.item_id, 
	I.item_name, 
	I.item_price, 
	I_O.item__order_quantity, 
	I_O.item__order_quantity * I.item_price AS total_sum 
FROM 
	item I 
INNER JOIN 
	item__order I_O ON I.item_id = I_O.item_id 
WHERE 
	I.item_id = I_O.item_id AND I_O.order_id = ?;

-- Для заданного ID заказа вывести список категорий, товары из которых присутствуют в этом заказе. Для каждой из категорий вывести суммарное количество и суммарную стоимость товаров.
SELECT 
	C.category_id, 
	C.category_title,
	sum(I_O.item__order_quantity) AS item_quantity,
	sum(I_O.item__order_quantity * I.item_price) AS total_sum
FROM 
	category C, item I 
INNER JOIN 
	item__order I_O on I.item_id = I_O.item_id 
WHERE 
	I.category_id = C.category_id AND I_O.order_id = ? 
GROUP BY 
C.category_id;

-- Вывести список клиентов, которые заказывали товары из категории с заданным ID за последние 3 дня.
SELECT 
	CU.*,
	O.order_created
FROM 
	item__order I_O
INNER JOIN
	"order" O on O.order_id = I_O.order_id
INNER JOIN
	item I on I.item_id = I_O.item_id
INNER JOIN
	customer CU on O.customer_id = CU.customer_id
WHERE 
	I.category_id = ? AND O.order_created > current_date - 3
GROUP BY 
	CU.customer_id,
	O.order_created,
	I_O.order_id
ORDER BY 
	CU.customer_id;

-- Вывести имена всех клиентов, производивших заказы за последние сутки.
SELECT 
	CU.customer_name,
	O.order_created
FROM 
	item__order I_O
INNER JOIN
	"order" O ON O.order_id = I_O.order_id
INNER JOIN
	item I ON I.item_id = I_O.item_id
INNER JOIN
	customer CU ON O.customer_id = CU.customer_id
WHERE 
	O.order_created >= now() - interval '24h'
GROUP BY
	CU.customer_id,
	O.order_created,
	I_O.order_id
ORDER BY 
	CU.customer_id;

-- Вывести всех клиентов, производивших заказы, содержащие товар с заданным ID.
SELECT
	CU.*
FROM
	item__order I_O
INNER JOIN
	"order" O ON O.order_id = I_O.order_id
INNER JOIN
	customer CU ON O.customer_id = CU.customer_id
WHERE 
	I_O.item_id = ?;

-- Для каждой категории вывести урл загрузки изображения с именем category_image в формате 'http://img.domain.com/category/<category_id>.jpg' для включенных категорий, и 'http://img.domain.com/category/<category_id>_disabled.jpg' для выключеных.
SELECT
	category.*,
	CASE 
		WHEN category_enabled = TRUE 
			THEN 'http://img.domain.com/category' || category_id
			ELSE 'http://img.domain.com/category/' || category_id || '_disabled.jpg'
	END AS category_download_url
FROM
	category;

-- Для товаров, которые были заказаны за все время во всех заказах общим количеством более X единиц, установить item_popular = TRUE, для остальных — FALSE.
UPDATE 
	item
SET 
	item_popular = TRUE
FROM (
	SELECT 
		item_id, 
		sum(item__order_quantity) AS total_orders 
	FROM 
		item__order 
	GROUP BY 
		item_id 
	ORDER BY 
		item_id
	) AS item_total_orders
WHERE 
	item.item_id = item_total_orders.item_id AND item_total_orders.total_orders > 10;

-- Одним запросом для указанных ID категорий установить флаг category_enabled = TRUE, для остальных — FALSE. Не применять WHERE.
UPDATE category SET category_enabled = id IN (?)

