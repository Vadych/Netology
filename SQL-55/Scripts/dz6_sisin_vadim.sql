--=============== МОДУЛЬ 6. POSTGRESQL =======================================
--= ПОМНИТЕ, ЧТО НЕОБХОДИМО УСТАНОВИТЬ ВЕРНОЕ СОЕДИНЕНИЕ И ВЫБРАТЬ СХЕМУ PUBLIC===========
SET search_path TO public;

--======== ОСНОВНАЯ ЧАСТЬ ==============

--ЗАДАНИЕ №1
--Напишите SQL-запрос, который выводит всю информацию о фильмах 
--со специальным атрибутом "Behind the Scenes".
EXPLAIN ANALYZE --67.5/0.7
SELECT film_id, title, special_features 
FROM film 
WHERE ARRAY['Behind the Scenes'] <@ special_features;



--ЗАДАНИЕ №2
--Напишите еще 2 варианта поиска фильмов с атрибутом "Behind the Scenes",
--используя другие функции или операторы языка SQL для поиска значения в массиве.
EXPLAIN ANALYZE --67.5/0.7
SELECT film_id, title, special_features
FROM film 
WHERE ARRAY['Behind the Scenes'] && special_features;

EXPLAIN ANALYZE --67.5/0.8
SELECT film_id, title, special_features
FROM film 
WHERE NOT array_position(special_features, 'Behind the Scenes') IS NULL;


--ЗАДАНИЕ №3
--Для каждого покупателя посчитайте сколько он брал в аренду фильмов 
--со специальным атрибутом "Behind the Scenes.

--Обязательное условие для выполнения задания: используйте запрос из задания 1, 
--помещенный в CTE. CTE необходимо использовать для решения задания.

EXPLAIN ANALYZE --691.6/21.9
WITH bs AS (
SELECT film_id 
FROM film 
WHERE ARRAY['Behind the Scenes'] <@ special_features
)
SELECT c.customer_id, count(bs.film_id)
FROM customer c
LEFT JOIN rental r ON c.customer_id = r.customer_id 
JOIN inventory i ON i.inventory_id = r.inventory_id 
JOIN bs ON bs.film_id = i.film_id 
GROUP BY c.customer_id 



--ЗАДАНИЕ №4
--Для каждого покупателя посчитайте сколько он брал в аренду фильмов
-- со специальным атрибутом "Behind the Scenes".

--Обязательное условие для выполнения задания: используйте запрос из задания 1,
--помещенный в подзапрос, который необходимо использовать для решения задания.
EXPLAIN ANALYZE --691.6/22.5
SELECT c.customer_id, count(bs.film_id)
FROM customer c
LEFT JOIN rental r ON c.customer_id = r.customer_id 
JOIN inventory i ON i.inventory_id = r.inventory_id 
JOIN 
	(SELECT *
	FROM film 
	WHERE ARRAY['Behind the Scenes'] <@ special_features
	) AS bs
ON bs.film_id = i.film_id 
GROUP BY c.customer_id 



--ЗАДАНИЕ №5
--Создайте материализованное представление с запросом из предыдущего задания
--и напишите запрос для обновления материализованного представления

CREATE MATERIALIZED VIEW bs_film
AS
SELECT *
FROM film 
WHERE ARRAY['Behind the Scenes'] <@ special_features
WITH NO DATA;

REFRESH MATERIALIZED VIEW bs_film;



--ЗАДАНИЕ №6
--С помощью explain analyze проведите анализ скорости выполнения запросов
-- из предыдущих заданий и ответьте на вопросы:

--1. Каким оператором или функцией языка SQL, используемых при выполнении домашнего задания, 
--   поиск значения в массиве происходит быстрее

/*
 * Не нашлось существенной разницы
 * 
 */

--2. какой вариант вычислений работает быстрее: 
--   с использованием CTE или с использованием подзапроса

/*
 * По стоимости оба запроса получились одинаковы
 * 
 * CTE работает чуть быстрее, но скорее случайный фактор
 */




--======== ДОПОЛНИТЕЛЬНАЯ ЧАСТЬ ==============

--ЗАДАНИЕ №1
--Выполняйте это задание в форме ответа на сайте Нетологии
EXPLAIN ANALYZE
select distinct cu.first_name  || ' ' || cu.last_name as name, 
	count(ren.iid) over (partition by cu.customer_id)
from customer cu
full outer join 
	(select *, r.inventory_id as iid, inv.sf_string as sfs, r.customer_id as cid
	from rental r 
	full outer join 
		(select *, unnest(f.special_features) as sf_string
		from inventory i
		full outer join film f on f.film_id = i.film_id) as inv 
		on r.inventory_id = inv.inventory_id) as ren 
	on ren.cid = cu.customer_id 
where ren.sfs like '%Behind the Scenes%'
order by count desc
/*
 Unique  (cost=1090.36..1090.40 rows=5 width=44) (actual time=58.861..59.447 rows=600 loops=1)
  ->  Sort  (cost=1090.36..1090.38 rows=5 width=44) (actual time=58.860..59.041 rows=8632 loops=1)
        Sort Key: (count(r.inventory_id) OVER (?)) DESC, ((((cu.first_name)::text || ' '::text) || (cu.last_name)::text))
        Sort Method: quicksort  Memory: 1058kB
        ->  WindowAgg  (cost=1090.19..1090.30 rows=5 width=44) (actual time=48.771..51.051 rows=8632 loops=1)
              ->  Sort  (cost=1090.19..1090.20 rows=5 width=21) (actual time=48.756..49.064 rows=8632 loops=1)
                    Sort Key: cu.customer_id
                    Sort Method: quicksort  Memory: 1057kB
                    ->  Nested Loop Left Join  (cost=82.09..1090.13 rows=5 width=21) (actual time=2.038..44.842 rows=8632 loops=1)
                          ->  Nested Loop Left Join  (cost=81.82..1088.66 rows=5 width=6) (actual time=2.027..34.171 rows=8632 loops=1)
                                ->  Subquery Scan on inv  (cost=77.50..996.42 rows=5 width=4) (actual time=2.000..10.430 rows=2494 loops=1)
                                      Filter: (inv.sf_string ~~ '%Behind the Scenes%'::text)
                                      Rows Removed by Filter: 7274
                                      ->  ProjectSet  (cost=77.50..423.80 rows=45810 width=712) (actual time=1.997..9.396 rows=9768 loops=1)
                                            ->  Hash Full Join  (cost=77.50..160.39 rows=4581 width=63) (actual time=1.985..3.526 rows=4623 loops=1)
                                                  Hash Cond: (i.film_id = f.film_id)
                                                  ->  Seq Scan on inventory i  (cost=0.00..70.81 rows=4581 width=6) (actual time=0.012..0.401 rows=4581 loops=1)
                                                  ->  Hash  (cost=65.00..65.00 rows=1000 width=63) (actual time=1.961..1.961 rows=1000 loops=1)
                                                        Buckets: 1024  Batches: 1  Memory Usage: 104kB
                                                        ->  Seq Scan on film f  (cost=0.00..65.00 rows=1000 width=63) (actual time=0.020..0.597 rows=1000 loops=1)
                                ->  Bitmap Heap Scan on rental r  (cost=4.32..18.41 rows=4 width=6) (actual time=0.006..0.008 rows=3 loops=2494)
                                      Recheck Cond: (inventory_id = inv.inventory_id)
                                      Heap Blocks: exact=8602
                                      ->  Bitmap Index Scan on idx_fk_inventory_id  (cost=0.00..4.32 rows=4 width=0) (actual time=0.004..0.004 rows=3 loops=2494)
                                            Index Cond: (inventory_id = inv.inventory_id)
                          ->  Index Scan using customer_pkey on customer cu  (cost=0.28..0.30 rows=1 width=17) (actual time=0.001..0.001 rows=1 loops=8632)
                                Index Cond: (customer_id = r.customer_id)
Planning Time: 2.456 ms
Execution Time: 59.633 ms
 */


--ЗАДАНИЕ №2
--Используя оконную функцию выведите для каждого сотрудника
--сведения о самой первой продаже этого сотрудника.
SELECT DISTINCT 
	s.staff_id,
	FIRST_VALUE (r.rental_id) OVER (PARTITION BY s.staff_id ORDER BY r.rental_date DESC)
FROM staff s 
LEFT JOIN rental r ON s.staff_id = r.staff_id 




--ЗАДАНИЕ №3
--Для каждого магазина определите и выведите одним SQL-запросом следующие аналитические показатели:
-- 1. день, в который арендовали больше всего фильмов (день в формате год-месяц-день)
-- 2. количество фильмов взятых в аренду в этот день
-- 3. день, в который продали фильмов на наименьшую сумму (день в формате год-месяц-день)
-- 4. сумму продажи в этот день
EXPLAIN ANALYZE 
WITH sd AS (
	SELECT 
		s.store_id,
		r.rental_date::date AS sd_date,
		count(r.rental_id) AS cr,
		sum (p.amount) AS sp
	FROM staff s  
	LEFT JOIN rental r ON r.staff_id = s.staff_id 
	LEFT JOIN payment p ON p.rental_id = r.rental_id 
	GROUP BY 1, 2),
sdd AS (
	SELECT DISTINCT 
		store_id,
		FIRST_VALUE (sd_date) over(PARTITION BY store_id ORDER BY cr DESC) AS cd,
		FIRST_VALUE (sd_date) over(PARTITION BY store_id ORDER BY sp) AS sd
	FROM sd)
SELECT 
	s.store_id, 
	sd1.sd_date AS max_date,
	sd1.cr AS max_count,
	sd2.sd_date AS min_date,
	sd2.sp AS min_amount
FROM store s
LEFT JOIN sd sd1 ON sd1.store_id = s.store_id 
JOIN sdd sdd1 ON sd1.sd_date = sdd1.cd AND sdd1.store_id = sd1.store_id
LEFT JOIN sd sd2 ON sd2.store_id = s.store_id 
JOIN sdd sdd2 ON sd2.sd_date = sdd2.sd AND sdd2.store_id = sd2.store_id










