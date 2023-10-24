--=============== МОДУЛЬ 5. РАБОТА С POSTGRESQL =======================================
--= ПОМНИТЕ, ЧТО НЕОБХОДИМО УСТАНОВИТЬ ВЕРНОЕ СОЕДИНЕНИЕ И ВЫБРАТЬ СХЕМУ PUBLIC===========
SET search_path TO public;

--======== ОСНОВНАЯ ЧАСТЬ ==============

--ЗАДАНИЕ №1
--Сделайте запрос к таблице payment и с помощью оконных функций добавьте вычисляемые колонки согласно условиям:
--Пронумеруйте все платежи от 1 до N по дате
--Пронумеруйте платежи для каждого покупателя, сортировка платежей должна быть по дате
--Посчитайте нарастающим итогом сумму всех платежей для каждого покупателя, сортировка должна 
--быть сперва по дате платежа, а затем по сумме платежа от наименьшей к большей
--Пронумеруйте платежи для каждого покупателя по стоимости платежа от наибольших к меньшим 
--так, чтобы платежи с одинаковым значением имели одинаковое значение номера.
--Можно составить на каждый пункт отдельный SQL-запрос, а можно объединить все колонки в одном запросе.

SELECT 
	payment_id,
	customer_id,
	amount,
	payment_date,
	ROW_NUMBER() OVER() AS payment_number,
	ROW_NUMBER() OVER (PARTITION BY customer_id ORDER BY payment_date::date) AS customer_payment_number,
	sum(amount) over(PARTITION BY customer_id ORDER BY payment_date::date, amount) AS sum_amount,
	rank() OVER (PARTITION BY customer_id ORDER BY amount DESC) AS payment_rank
FROM payment p
ORDER BY customer_id, payment_rank;

--ЗАДАНИЕ №2
--С помощью оконной функции выведите для каждого покупателя стоимость платежа и стоимость 
--платежа из предыдущей строки со значением по умолчанию 0.0 с сортировкой по дате.

SELECT 
	payment_id,
	customer_id,
	amount,
	LAG(amount, 1, 0.) OVER (PARTITION BY customer_id ORDER BY payment_date) AS prev_amount
FROM payment;

-- тут не стал приводить payment_date к date, что бы была однозначность в сортировке

--ЗАДАНИЕ №3
--С помощью оконной функции определите, на сколько каждый следующий платеж покупателя больше или меньше текущего.

SELECT 
	payment_id,
	customer_id,
	amount,
	LEAD(amount) OVER (PARTITION BY customer_id ORDER BY payment_date) - amount AS delta
FROM payment;



--ЗАДАНИЕ №4
--С помощью оконной функции для каждого покупателя выведите данные о его последней оплате аренды.

WITH max_date AS (
	SELECT *,
		ROW_NUMBER () OVER (PARTITION BY customer_id ORDER BY payment_date DESC) AS rn
	FROM payment
)
SELECT *
FROM max_date
WHERE rn = 1;
-- Не уверен, что нашел правильное решение. Хотелось бы увидеть решение эксперта, если можно


--======== ДОПОЛНИТЕЛЬНАЯ ЧАСТЬ ==============

--ЗАДАНИЕ №1
--С помощью оконной функции выведите для каждого сотрудника сумму продаж за август 2005 года 
--с нарастающим итогом по каждому сотруднику и по каждой дате продажи (без учёта времени) 
--с сортировкой по дате.

SELECT 
	s.staff_id,
	s.last_name,
	s.first_name,
	sp.pd,
	sp.aug_sum
FROM staff s 
JOIN 
	(SELECT 
		staff_id,
		payment_date::date AS pd,
		sum(amount) OVER (PARTITION BY staff_id ORDER BY payment_date::date) AS aug_sum,
		ROW_NUMBER () OVER (PARTITION BY staff_id, payment_date::date) AS rn
	FROM payment
	WHERE date_trunc('month', payment_date) = '2005-08-01') AS sp
ON s.staff_id = sp.staff_id
WHERE sp.rn = 1;

--ЗАДАНИЕ №2
--20 августа 2005 года в магазинах проходила акция: покупатель каждого сотого платежа получал
--дополнительную скидку на следующую аренду. С помощью оконной функции выведите всех покупателей,
--которые в день проведения акции получили скидку
WITH pay_action AS (
	SELECT *,
		ROW_NUMBER () OVER (ORDER BY payment_date) AS rn
	FROM payment 
	WHERE payment_date::date = '2005-08-20'
)
SELECT customer_id 
FROM pay_action
WHERE rn % 100 = 0;


--ЗАДАНИЕ №3 
--Для каждой страны определите и выведите одним SQL-запросом покупателей, которые попадают под условия:
-- 1. покупатель, арендовавший наибольшее количество фильмов
-- 2. покупатель, арендовавший фильмов на самую большую сумму
-- 3. покупатель, который последним арендовал фильм

WITH cust_coutry AS (
	SELECT c.customer_id, c3.country_id, c3.country 
	FROM customer c
	JOIN address a USING (address_id)
	JOIN city c2 USING (city_id)
	JOIN country c3 USING (country_id)
)
SELECT DISTINCT 
	country_id,
	LAST_VALUE(cnt_rental.customer_id) OVER (PARTITION BY cnt_rental.country_id) AS max_rental,
	LAST_VALUE(pay_country.customer_id) OVER (PARTITION BY pay_country.country_id) AS max_pay,
	LAST_VALUE(rent_country.customer_id) OVER (PARTITION BY rent_country.country_id) AS last_rent
FROM (
	SELECT DISTINCT 
		country_id,
		customer_id, 
		count (*) OVER (PARTITION BY country_id, customer_id) AS cnt
	FROM cust_coutry cc
	JOIN rental r USING (customer_id)
	ORDER BY country_id, cnt) AS cnt_rental
	JOIN (
	SELECT DISTINCT 
		country_id,
		customer_id, 
		sum(amount) OVER (PARTITION BY country_id, customer_id) AS pay
	FROM cust_coutry cc
	JOIN payment r USING (customer_id)
	ORDER BY country_id, pay) AS pay_country
USING (country_id)
JOIN(
	SELECT DISTINCT 
		country_id,
		customer_id, 
		ROW_NUMBER () OVER (PARTITION BY country_id ORDER BY rental_date) AS rn
	FROM cust_coutry cc
	JOIN rental r USING (customer_id)
	ORDER BY country_id, rn
) AS rent_country
USING (country_id);

WITH cust_coutry AS (
	SELECT c.customer_id, c3.country_id, c3.country 
	FROM customer c
	JOIN address a USING (address_id)
	JOIN city c2 USING (city_id)
	JOIN country c3 USING (country_id)
)
SELECT 
		country_id,
		customer_id, 
		ROW_NUMBER () OVER (PARTITION BY country_id ORDER BY rental_date) AS rn
	FROM cust_coutry cc
	JOIN rental r USING (customer_id)
	ORDER BY country_id, rn DESC






