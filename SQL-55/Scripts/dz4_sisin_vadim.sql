--=============== МОДУЛЬ 4. УГЛУБЛЕНИЕ В SQL =======================================
--= ПОМНИТЕ, ЧТО НЕОБХОДИМО УСТАНОВИТЬ ВЕРНОЕ СОЕДИНЕНИЕ И ВЫБРАТЬ СХЕМУ PUBLIC===========
SET search_path TO public;

--======== ОСНОВНАЯ ЧАСТЬ ==============

--ЗАДАНИЕ №1
--База данных: если подключение к облачной базе, то создаёте новую схему с префиксом в --виде фамилии, название должно быть на латинице в нижнем регистре и таблицы создаете --в этой новой схеме, если подключение к локальному серверу, то создаёте новую схему и --в ней создаёте таблицы.
CREATE SCHEMA IF NOT EXISTS dz4;
SET search_path TO dz4;

--Спроектируйте базу данных, содержащую три справочника:
--· язык (английский, французский и т. п.);
--· народность (славяне, англосаксы и т. п.);
--· страны (Россия, Германия и т. п.).
--Две таблицы со связями: язык-народность и народность-страна, отношения многие ко многим. Пример таблицы со связями — film_actor.
--Требования к таблицам-справочникам:
--· наличие ограничений первичных ключей.
--· идентификатору сущности должен присваиваться автоинкрементом;
--· наименования сущностей не должны содержать null-значения, не должны допускаться --дубликаты в названиях сущностей.
--Требования к таблицам со связями:
--· наличие ограничений первичных и внешних ключей.

--В качестве ответа на задание пришлите запросы создания таблиц и запросы по --добавлению в каждую таблицу по 5 строк с данными.
 
--СОЗДАНИЕ ТАБЛИЦЫ ЯЗЫКИ

DROP TABLE IF EXISTS languages;
CREATE TABLE languages(
	id_language serial PRIMARY KEY,
	language_name varchar(50) UNIQUE NOT NULL 
);

--ВНЕСЕНИЕ ДАННЫХ В ТАБЛИЦУ ЯЗЫКИ
INSERT INTO languages 
VALUES 
	(1, 'Русский'),
	(2, 'Английский'),
	(3, 'Немецкий'),
	(4, 'Кельтский'),
	(5, 'Французский'),
	(6, 'Татарский'),
	(7, 'Украинский');


--СОЗДАНИЕ ТАБЛИЦЫ НАРОДНОСТИ
DROP TABLE IF EXISTS ethnicitys;
CREATE TABLE ethnicitys(
	id_ethnicity serial PRIMARY KEY,
	ethnicity_name varchar(50) UNIQUE NOT NULL
);


--ВНЕСЕНИЕ ДАННЫХ В ТАБЛИЦУ НАРОДНОСТИ
INSERT INTO ethnicitys 
VALUES 
	(1, 'Славяне'),
	(2, 'Кельты'),
	(3, 'Англосаксы'),
	(4, 'Французы'),
	(5, 'Немцы'),
	(6, 'Тюрки');



--СОЗДАНИЕ ТАБЛИЦЫ СТРАНЫ
DROP TABLE IF EXISTS countries;
CREATE TABLE countries(
	id_countrie serial PRIMARY KEY,
	countries_name varchar(50) UNIQUE NOT NULL
);


--ВНЕСЕНИЕ ДАННЫХ В ТАБЛИЦУ СТРАНЫ
INSERT INTO countries  
VALUES 
	(1, 'Россия'),
	(2, 'Швейцария'),
	(3, 'Бельгия'),
	(4, 'Великобритания'),
	(5, 'Франция');


--СОЗДАНИЕ ПЕРВОЙ ТАБЛИЦЫ СО СВЯЗЯМИ
DROP TABLE IF EXISTS language_ethnicity;
CREATE TABLE language_ethnicity(
	id_language integer REFERENCES languages,
	id_ethnicity integer REFERENCES ethnicitys,
	PRIMARY KEY (id_language, id_ethnicity)
);


--ВНЕСЕНИЕ ДАННЫХ В ТАБЛИЦУ СО СВЯЗЯМИ
INSERT INTO language_ethnicity  
VALUES 
	(1, 1),
	(7, 1),
	(4, 2),
	(2, 3),
	(5, 4),
	(3, 5),
	(6, 6);


--СОЗДАНИЕ ВТОРОЙ ТАБЛИЦЫ СО СВЯЗЯМИ
DROP TABLE IF EXISTS country_ethnicity;
CREATE TABLE country_ethnicity(
	id_country integer REFERENCES countries,
	id_ethnicity integer REFERENCES ethnicitys,
	PRIMARY KEY (id_country, id_ethnicity)
);


--ВНЕСЕНИЕ ДАННЫХ В ТАБЛИЦУ СО СВЯЗЯМИ
INSERT INTO  country_ethnicity
VALUES 
	(1, 1),
	(1, 6),
	(2, 5),
	(2, 4),
	(3, 5),
	(3, 4),
	(4, 3),
	(4, 2),
	(5, 4);

--======== ДОПОЛНИТЕЛЬНАЯ ЧАСТЬ ==============


--ЗАДАНИЕ №1 
--Создайте новую таблицу film_new со следующими полями:
--·   	film_name - название фильма - тип данных varchar(255) и ограничение not null
--·   	film_year - год выпуска фильма - тип данных integer, условие, что значение должно быть больше 0
--·   	film_rental_rate - стоимость аренды фильма - тип данных numeric(4,2), значение по умолчанию 0.99
--·   	film_duration - длительность фильма в минутах - тип данных integer, ограничение not null и условие, что значение должно быть больше 0
--Если работаете в облачной базе, то перед названием таблицы задайте наименование вашей схемы.
CREATE TABLE film_new(
	id_film serial PRIMARY KEY,
	film_name varchar(255) NOT NULL,
	film_year integer CHECK (film_year > 0),
	film_rental_rate numeric(4,2) DEFAULT 0.99,
	film_duration integer not null CHECK (film_duration > 0)
);


--ЗАДАНИЕ №2 
--Заполните таблицу film_new данными с помощью SQL-запроса, где колонкам соответствуют массивы данных:
--·       film_name - array['The Shawshank Redemption', 'The Green Mile', 'Back to the Future', 'Forrest Gump', 'Schindlers List']
--·       film_year - array[1994, 1999, 1985, 1994, 1993]
--·       film_rental_rate - array[2.99, 0.99, 1.99, 2.99, 3.99]
--·   	  film_duration - array[142, 189, 116, 142, 195]

INSERT INTO film_new (film_name, film_year, film_rental_rate, film_duration)
SELECT 
	UNNEST(ARRAY['The Shawshank Redemption', 'The Green Mile', 'Back to the Future', 'Forrest Gump', 'Schindlers List']) AS f1,
	UNNEST(ARRAY[1994, 1999, 1985, 1994, 1993]) AS f2,
	UNNEST(ARRAY[2.99, 0.99, 1.99, 2.99, 3.99]) AS f3,
	UNNEST(ARRAY[142, 189, 116, 142, 195]) AS f4;
	



--ЗАДАНИЕ №3
--Обновите стоимость аренды фильмов в таблице film_new с учетом информации, 
--что стоимость аренды всех фильмов поднялась на 1.41
UPDATE film_new 
SET film_rental_rate = film_rental_rate + 1.41;


--ЗАДАНИЕ №4
--Фильм с названием "Back to the Future" был снят с аренды, 
--удалите строку с этим фильмом из таблицы film_new
DELETE FROM film_new 
WHERE film_name = 'Back to the Future';


--ЗАДАНИЕ №5
--Добавьте в таблицу film_new запись о любом другом новом фильме
INSERT INTO film_new (film_name, film_year, film_duration)
VALUES ('The Revenant', 2015, 156);


--ЗАДАНИЕ №6
--Напишите SQL-запрос, который выведет все колонки из таблицы film_new, 
--а также новую вычисляемую колонку "длительность фильма в часах", округлённую до десятых
SELECT *, round(film_duration/60., 1) AS duration_in_hours
FROM film_new;


--ЗАДАНИЕ №7 
--Удалите таблицу film_new
DROP TABLE IF EXISTS film_new;
