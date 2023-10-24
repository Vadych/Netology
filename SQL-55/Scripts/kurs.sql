
SET search_path TO bookings;
/*
 * Описание базы данных: https://edu.postgrespro.ru/bookings.pdf
 * 
 */

/*
 * 1 Выведите название самолетов, которые имеют менее 50 посадочных мест?
 * 
 */
SELECT a.aircraft_code, a.model, count(s.seat_no)
FROM aircrafts a 
LEFT JOIN seats s USING (aircraft_code) 
GROUP BY a.aircraft_code
HAVING count(s.seat_no) < 50;

/* 
 * 2 Выведите процентное изменение ежемесячной суммы бронирования билетов, округленной до сотых.
 */ 

SELECT 
	dm,
	sum,
	round (COALESCE (
		(sum - lag(sum, 1, 0.) OVER (ORDER BY dm)) * 100. / lag(sum) OVER (ORDER BY dm),
		0.), 2)
FROM (
	SELECT date_trunc('month', book_date)::date AS dm, sum(total_amount)
	FROM bookings 
	GROUP BY 1) AS tmp;



 /*
 * 3 Выведите названия самолетов не имеющих бизнес - класс. Решение должно быть через функцию array_agg.
 */

SELECT 
	aircraft_code,
	model,
	array_agg(s.fare_conditions)
FROM aircrafts a 
JOIN (
	SELECT aircraft_code , fare_conditions
	FROM seats
	GROUP BY aircraft_code , fare_conditions) s
USING (aircraft_code)
GROUP BY aircraft_code
HAVING array_position (array_agg(s.fare_conditions), 'Business') IS NULL;

	
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


 /* 5 Найдите процентное соотношение перелетов по маршрутам от общего количества перелетов. 
 * Выведите в результат названия аэропортов и процентное отношение.
 * Решение должно быть через оконную функцию.
 */
SELECT 
	a.airport_name AS departure_airport_name,
	a2.airport_name AS arrival_airport_name,
	proc
FROM (
	SELECT DISTINCT 
		departure_airport, 
		arrival_airport,
		round(
			count(flight_id) OVER (PARTITION BY departure_airport, arrival_airport) * 100. /
			count(flight_id) OVER (), 2) AS proc
	FROM flights f 
	WHERE status != 'Cancelled') AS proc
JOIN airports a ON a.airport_code = departure_airport
JOIN airports a2 ON a2.airport_code = arrival_airport;


/* 6 Выведите количество пассажиров по каждому коду сотового оператора, если учесть, 
 * что код оператора - это три символа после +7
*/

SELECT 
	substring(contact_data ->>'phone' FROM 3 FOR 3) AS code_phone,
	count (ticket_no)
FROM tickets t 
GROUP BY 1;

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





