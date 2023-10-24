
SET search_path TO bookings;
/*
 * Описание базы данных: https://edu.postgrespro.ru/bookings.pdf
 * 
 */


 /* 4 Вывести накопительный итог количества мест в самолетах по каждому аэропорту на каждый день, 
 * учитывая только те самолеты, которые летали пустыми и только те дни, 
 * где из одного аэропорта таких самолетов вылетало более одного.
 * В результате должны быть код аэропорта, дата, количество пустых мест и накопительный итог.
 */

WITH ef AS (
-- пустые перелеты
	SELECT flight_id 
	FROM flights
	LEFT JOIN ticket_flights tf USING (flight_id)
	WHERE tf.flight_id IS NULL AND status IN ('Departed', 'Arrived')
),
tf AS(
-- больше 1 пустого самолета в день из аэропорта
	SELECT *
	FROM (
		SELECT 
			flight_id,
			departure_airport,
			actual_departure,
			aircraft_code,
			count (f.flight_id) OVER (PARTITION BY departure_airport, actual_departure::date) AS cf
		FROM flights f 
		JOIN ef USING (flight_id)
		) t
	WHERE cf > 1
)
SELECT DISTINCT 
	tf.flight_id,
	departure_airport,
	actual_departure,
	count (s.seat_no) OVER (PARTITION BY tf.flight_id),
	count(s.seat_no) OVER (PARTITION BY departure_airport, actual_departure::date ORDER BY actual_departure)
FROM tf
JOIN seats s USING (aircraft_code)
ORDER BY 2,3

--ЗАМЕЧАНИЕ
-- Ложная работа с получением пустых самолетов, так как билеты не имеют отношения к вопросу.

-- Если я правильно понял нужно было проверять посадочные талоны на данный рейс
WITH ef AS (
-- пустые перелеты
	SELECT flight_id 
	FROM flights
	LEFT JOIN boarding_passes tf USING (flight_id)
	WHERE tf.flight_id IS NULL AND status IN ('Departed', 'Arrived')
),
tf AS(
-- больше 1 пустого самолета в день из аэропорта
	SELECT *
	FROM (
		SELECT 
			flight_id,
			departure_airport,
			actual_departure,
			aircraft_code,
			count (f.flight_id) OVER (PARTITION BY departure_airport, actual_departure::date) AS cf
		FROM flights f 
		JOIN ef USING (flight_id)
		) t
	WHERE cf > 1
)
SELECT DISTINCT 
	tf.flight_id,
	departure_airport,
	actual_departure,
	count (s.seat_no) OVER (PARTITION BY tf.flight_id),
	count(s.seat_no) OVER (PARTITION BY departure_airport, actual_departure::date ORDER BY actual_departure)
FROM tf
JOIN seats s USING (aircraft_code)
ORDER BY 2,3




/* 7 Классифицируйте финансовые обороты (сумма стоимости билетов) по маршрутам:
 * До 50 млн - low
 * От 50 млн включительно до 150 млн - middle
 * От 150 млн включительно - high
 * Выведите в результат количество маршрутов в каждом полученном классе.
*/

SELECT 
	CASE 
		WHEN sum_amount < 50000000. THEN 'low'
		WHEN sum_amount > 150000000. THEN 'high'
		ELSE 'middle'
	END AS class_route,
	count(*)
FROM (
	SELECT 
		departure_airport, 
		arrival_airport,
		COALESCE (sum(amount), 0.) AS sum_amount
	FROM flights f 
	LEFT JOIN ticket_flights tf using(flight_id)
	GROUP BY departure_airport , arrival_airport) rt
GROUP BY 1;

--ЗАМЕЧАНИЕ
-- Условия в case не соответствуют условию задания.

-- Невнимательность :(
SELECT 
	CASE 
		WHEN sum_amount < 50000000. THEN 'low'
		WHEN sum_amount >= 150000000. THEN 'high'
		ELSE 'middle'
	END AS class_route,
	count(*)
FROM (
	SELECT 
		departure_airport, 
		arrival_airport,
		COALESCE (sum(amount), 0.) AS sum_amount
	FROM flights f 
	LEFT JOIN ticket_flights tf using(flight_id)
	GROUP BY departure_airport , arrival_airport) rt
GROUP BY 1;


/* 8* Вычислите медиану стоимости билетов, медиану размера бронирования и 
 * отношение медианы бронирования к медиане стоимости билетов, округленной до сотых.
*/
WITH m_t AS (
	SELECT percentile_cont(0.5) WITHIN GROUP (ORDER BY amount) AS t_val
	FROM ticket_flights),
m_b AS 
	(SELECT percentile_cont(0.5) WITHIN GROUP (ORDER BY total_amount) AS b_val
	FROM bookings)
SELECT t_val, b_val, round(t_val::numeric / b_val::numeric, 2)
FROM m_t
JOIN m_b ON TRUE;

--ЗАМЕЧАНИЕ
--Отношение не соответствует условию задания.

-- Невнимательность :(
WITH m_t AS (
	SELECT percentile_cont(0.5) WITHIN GROUP (ORDER BY amount) AS t_val
	FROM ticket_flights),
m_b AS 
	(SELECT percentile_cont(0.5) WITHIN GROUP (ORDER BY total_amount) AS b_val
	FROM bookings)
SELECT t_val, b_val, round(b_val::numeric / t_val::numeric, 2)
FROM m_t
JOIN m_b ON TRUE;



/* 9* Найдите значение минимальной стоимости полета 1 км для пассажиров. 
 * То есть нужно найти расстояние между аэропортами и с учетом стоимости билетов 
 * получить искомый результат.
 * Для поиска расстояния между двумя точка на поверхности Земли нужно использовать
 * дополнительный модуль earthdistance (https://postgrespro.ru/docs/postgresql/15/earthdistance). 
 * Для работы данного модуля нужно установить еще один модуль 
 * cube (https://postgrespro.ru/docs/postgresql/15/cube). 
 * Установка дополнительных модулей происходит через оператор create extension название_модуля.
 * Функция earth_distance возвращает результат в метрах.
 * В облачной базе данных модули уже установлены.
 * 
 */

WITH ds AS (
-- вычисляем расстояние между аэропортами
	SELECT 
		f.departure_airport,
		f.arrival_airport,
		earth_distance(
				ll_to_earth(a1.latitude, a1.longitude),
				ll_to_earth(a2.latitude, a2.longitude)
				) / 1000. AS dist
		FROM (
			SELECT f.departure_airport,
				f.arrival_airport
			FROM flights f 
			GROUP BY 1, 2) AS f
	JOIN airports a1 ON f.departure_airport = a1.airport_code 
	JOIN airports a2 ON f.arrival_airport = a2.airport_code
),
aa AS (
-- вычисляем среднюю стоимость билета
	SELECT 
		flight_id,
		avg(amount) AS avg_amount
	FROM ticket_flights tf 
	GROUP BY flight_id 
)
SELECT 
	f.flight_id,
	f.departure_airport, 
	f.arrival_airport,
	aa.avg_amount / ds.dist AS min_amount,
	ds.dist,
	aa.avg_amount
FROM flights f
JOIN aa ON aa.flight_id = f.flight_id 
JOIN ds ON ds.departure_airport = f.departure_airport AND 
		   ds.arrival_airport = f.arrival_airport
WHERE f.flight_id IN (27740, 28727)
ORDER BY min_amount
LIMIT 1;

--ЗАМЕЧАНИЕ
--В задании нет речи о чем-то среднем, вопрос о минимальном значении.
--Что такое 27740, 28727? Никакой ручной подстановки значений быть не должно.

-- 27740, 28727 - это я забыл удалить отладочные данные :(
-- Теперь про среднее. Как я понял задание. Нужно найти среднюю стоимость билета в самолете
-- и соотнести ее с растоянием. Среднюю, потому что меня смутило само слово "паcсажиров".
-- Теперь понимаю, что нужна была сумма всех билетов
-- Было бы "пассажира" - тут все понятно. 

WITH ds AS (
-- вычисляем расстояние между аэропортами
	SELECT 
		f.departure_airport,
		f.arrival_airport,
		earth_distance(
				ll_to_earth(a1.latitude, a1.longitude),
				ll_to_earth(a2.latitude, a2.longitude)
				) / 1000. AS dist
		FROM (
			SELECT f.departure_airport,
				f.arrival_airport
			FROM flights f 
			GROUP BY 1, 2) AS f
	JOIN airports a1 ON f.departure_airport = a1.airport_code 
	JOIN airports a2 ON f.arrival_airport = a2.airport_code
),
aa AS (
-- вычисляем среднюю стоимость билета
	SELECT 
		flight_id,
		sum(amount) AS avg_amount
	FROM ticket_flights tf 
	GROUP BY flight_id 
)
SELECT 
	f.flight_id,
	f.departure_airport, 
	f.arrival_airport,
	aa.avg_amount / ds.dist AS min_amount
FROM flights f
JOIN aa ON aa.flight_id = f.flight_id 
JOIN ds ON ds.departure_airport = f.departure_airport AND 
		   ds.arrival_airport = f.arrival_airport
ORDER BY min_amount
LIMIT 1;
