--=============== МОДУЛЬ 3. ОСНОВЫ SQL =======================================
--= ПОМНИТЕ, ЧТО НЕОБХОДИМО УСТАНОВИТЬ ВЕРНОЕ СОЕДИНЕНИЕ И ВЫБРАТЬ СХЕМУ PUBLIC===========
SET search_path TO public;

--======== ОСНОВНАЯ ЧАСТЬ ==============

--ЗАДАНИЕ №1
--Выведите для каждого покупателя его адрес проживания, 
--город и страну проживания.

SELECT 
	concat_ws(' ', last_name, first_name) AS customer_name,
	address,
	city,
	country
FROM customer
LEFT JOIN address USING (address_id)
LEFT JOIN city USING (city_id)
LEFT JOIN country USING (country_id);

/*
 * Выбран LEFT JOIN, т.к. вдруг в базе пошло что-то не так.
 * Но в принципе, т.к. по всем полям _id стоит признак Not Null, LEFT можно убрать
 */


--ЗАДАНИЕ №2
--С помощью SQL-запроса посчитайте для каждого магазина количество его покупателей.

SELECT store_id,
	COUNT (customer_id) AS customer_count
FROM store
LEFT JOIN customer USING (store_id)
GROUP BY store_id;



--Доработайте запрос и выведите только те магазины, 
--у которых количество покупателей больше 300-от.
--Для решения используйте фильтрацию по сгруппированным строкам 
--с использованием функции агрегации.

SELECT store_id,
	COUNT (customer_id) AS customer_count
FROM store
LEFT JOIN customer USING (store_id)
GROUP BY store_id
HAVING COUNT (customer_id) > 300;




-- Доработайте запрос, добавив в него информацию о городе магазина, 
--а также фамилию и имя продавца, который работает в этом магазине.

SELECT 
	s.store_id,
	count(cu.store_id),
	max(ct.city) AS city,
	max(concat_ws(' ', st.last_name, st.first_name)) AS personal_name
FROM store s
JOIN address a ON a.address_id = s.address_id 
JOIN city ct ON ct.city_id = a.city_id 
JOIN staff st ON st.store_id = s.store_id 
JOIN customer cu ON cu.store_id = s.store_id 
GROUP BY s.store_id
HAVING count(cu.store_id) > 300;



--ЗАДАНИЕ №3
--Выведите ТОП-5 покупателей, 
--которые взяли в аренду за всё время наибольшее количество фильмов

SELECT 
	customer_id,
	concat_ws(' ', last_name, first_name) AS customer_name,
	count(rental_id) AS count_rental
FROM customer 
JOIN rental USING (customer_id)
GROUP BY customer_id
ORDER BY count_rental DESC 
LIMIT 5;


--ЗАДАНИЕ №4
--Посчитайте для каждого покупателя 4 аналитических показателя:
--  1. количество фильмов, которые он взял в аренду
--  2. общую стоимость платежей за аренду всех фильмов (значение округлите до целого числа)
--  3. минимальное значение платежа за аренду фильма
--  4. максимальное значение платежа за аренду фильма

SELECT 
	c.customer_id,
	concat_ws(' ', c.last_name, c.first_name) AS customer_name,
	count(r.rental_id) AS count_rental,
	round(sum(p.amount), 0) AS total_payment,
	min(p.amount) AS minimum_payment,
	max(p.amount) AS maximum_payment 
FROM customer c
LEFT JOIN rental r ON c.customer_id = r.customer_id
LEFT JOIN payment p ON p.rental_id = r.rental_id
GROUP BY c.customer_id;


--ЗАДАНИЕ №5
--Используя данные из таблицы городов составьте одним запросом всевозможные пары городов таким образом,
 --чтобы в результате не было пар с одинаковыми названиями городов. 
 --Для решения необходимо использовать декартово произведение.
 
/*
 * Я немного запутался, что именно нужно в этом задании.
 * Данный вопрос выводит список всех возможных уникальных пар с учетом возможного дубля 
 * в названии городов
 */


SELECT 
	c.city AS city1,
	c2.city AS city2 
FROM city c 
INNER JOIN city c2 ON TRUE 
WHERE c.city_id > c2.city_id AND c.city != c2.city
GROUP BY c.city, c2.city;


--ЗАДАНИЕ №6
--Используя данные из таблицы rental о дате выдачи фильма в аренду (поле rental_date)
--и дате возврата фильма (поле return_date), 
--вычислите для каждого покупателя среднее количество дней, за которые покупатель возвращает фильмы.
 
SELECT 
	customer_id, 
	round(avg(return_date::date - rental_date::date),2) AS avg_rental
FROM rental 
GROUP BY customer_id;



--======== ДОПОЛНИТЕЛЬНАЯ ЧАСТЬ ==============

--ЗАДАНИЕ №1
--Посчитайте для каждого фильма сколько раз его брали в аренду и значение общей стоимости аренды фильма за всё время.
SELECT 
	film_id,
	title,
	count(rental_id) AS count_rental,
	sum(amount) AS sum_amount
FROM film
LEFT JOIN inventory USING (film_id)
LEFT JOIN rental USING (inventory_id)
LEFT JOIN payment USING (rental_id)
GROUP BY film_id;


--ЗАДАНИЕ №2
--Доработайте запрос из предыдущего задания и выведите с помощью запроса фильмы, которые ни разу не брали в аренду.
SELECT 
	film_id,
	title,
	count(rental_id) AS count_rental
FROM film
LEFT JOIN inventory USING (film_id)
LEFT JOIN rental USING (inventory_id)
LEFT JOIN payment USING (rental_id)
GROUP BY film_id 
HAVING count(rental_id) = 0;


--ЗАДАНИЕ №3
--Посчитайте количество продаж, выполненных каждым продавцом. Добавьте вычисляемую колонку "Премия".
--Если количество продаж превышает 7300, то значение в колонке будет "Да", иначе должно быть значение "Нет".

SELECT 
	staff.staff_id,
	last_name || ' ' || first_name AS staff_name,
	count(rental.rental_id) AS count_rental,
	CASE 
		WHEN count(rental.rental_id) > 7300 THEN 'Да'
		ELSE 'Нет'
	END AS bonus	
FROM staff
LEFT JOIN rental USING (staff_id)
LEFT JOIN payment USING (rental_id)
GROUP BY staff.staff_id ;






