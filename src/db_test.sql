USE ExchangeTransactions
GO

/* 01. Тест API для создания/обновления/удаления пользователей. */
SELECT N'01. Тест API для создания/обновления/удаления пользователей.' AS test_type
GO

-- 01.1. Тест вставки пользователей.
SELECT N'01.1. Тест вставки пользователей.' AS subtest_type
GO
---- Тест добавления пользователей-юр. лиц.
INSERT INTO GetPersonUsers (login, pw_hash, balance, first_name, second_name, last_name) VALUES
	('m.masyagin1998', (SELECT HASHBYTES('md5', '123456')), 1000, 'Mikhail', 'Mikhailovich', 'Masyagin')
INSERT INTO GetPersonUsers (login, pw_hash, balance, first_name, second_name, last_name) VALUES
	('a.barluka1998', (SELECT HASHBYTES('md5', 'qwerty')), 0, 'Alexander', 'Borisovich', 'Barluka')
INSERT INTO GetPersonUsers (login, pw_hash, balance, first_name, second_name, last_name) VALUES
	('i.zbobnev1998', (SELECT HASHBYTES('md5', 'grafika')), 0, 'Igor', 'Vladimirovich', 'Zbobnev')
INSERT INTO GetPersonUsers (login, pw_hash, balance, first_name, second_name, last_name) VALUES
	('a.koshelev1998', (SELECT HASHBYTES('md5', 'golang')), -1, 'Andrew', 'Alekseevich', 'Koshelev') -- Не сработает.
GO

---- Тест добавления пользователей-физ. лиц.
INSERT INTO GetCompanyUsers (login, pw_hash, balance, name) VALUES
	('liebherr', (SELECT HASHBYTES('md5', 'tractor')), 0, 'Liebherr Inc.')
INSERT INTO GetCompanyUsers (login, pw_hash, balance, name) VALUES
	('cat', (SELECT HASHBYTES('md5', 'tractor')), 0, 'Caterpillar Inc.')
INSERT INTO GetCompanyUsers (login, pw_hash, balance, name) VALUES
	('belaz', (SELECT HASHBYTES('md5', 'tractor')), 0, 'BelAZ Co')
INSERT INTO GetCompanyUsers (login, pw_hash, balance, name) VALUES
	('anime', (SELECT HASHBYTES('md5', 'anime')), -1, 'Anime') -- Не сработает, так как нарушается констрейнт.
GO

SELECT * FROM GetPersonUsers
SELECT * FROM GetCompanyUsers
GO

-- 01.2. Тест обновления пользователей.
SELECT N'01.2. Тест обновления пользователей.' AS subtest_type
GO
---- Тест обновления пользователей-юр. лиц.
UPDATE GetPersonUsers SET balance = balance + 500 WHERE (login = 'a.barluka1998')
UPDATE GetPersonUsers SET balance = balance - 1000 WHERE (login = 'i.zbobnev1998') -- Не сработает, так как нарушается констрейнт.
GO

---- Тест обновления пользователей-физ. лиц.
UPDATE GetCompanyUsers SET balance = balance + 100000 WHERE (login = 'liebherr')
UPDATE GetCompanyUsers SET balance = 5000000, login = 'caterpillar' WHERE (login = 'cat')
UPDATE GetCompanyUsers SET balance = -1 WHERE (login = 'belaz') -- Не сработает, так как нарушается констрейнт.
GO

SELECT * FROM GetPersonUsers
SELECT * FROM GetCompanyUsers
GO

-- 01.3. Тест удаления пользователей.
SELECT N'01.3. Тест удаления пользователей.' AS subtest_type
GO
---- Тест удаления пользователей-юр. лиц.
DELETE FROM GetPersonUsers WHERE (login = 'a.barluka1998') -- Не сработает, так как у a.barluka1998 ненулевой баланс.
DELETE FROM GetPersonUsers WHERE (login = 'i.zbobnev1998')
GO

---- Тест удаления пользователей-физ. лиц.
DELETE FROM GetCompanyUsers WHERE (login = 'liebherr') -- Не сработает, так как у Liebherr ненулевой баланс.
DELETE FROM GetCompanyUsers WHERE (login = 'belaz')
GO

SELECT * FROM GetPersonUsers
SELECT * FROM GetCompanyUsers
GO

/* 02. Тест API для создания/обновления/удаления инструментов. */
SELECT N'02. Тест API для создания/обновления/удаления пользователей.' AS test_type
GO

-- 02.1. Тест вставки инструментов.
SELECT N'02.1. Тест вставки инструментов.' AS subtest_type
GO
INSERT INTO GetCompanyInstruments (company_name, ISIN, ticker, short_name, full_name, st_reg_num, yield, lot_size) VALUES
	('Liebherr Inc.',    'DE1497831032', 'LIEB', 'Liebherr',    'Liebherr Inc.',     '1-05-25632-B', 200000, 20)
INSERT INTO GetCompanyInstruments (company_name, ISIN, ticker, short_name, full_name, st_reg_num, yield, lot_size) VALUES
	('Caterpillar Inc.', 'US1491231015', 'CAT',  'Caterpillar', 'Caterpillar Inc.', '1-02-12500-A', 1000000, 10)
INSERT INTO GetCompanyInstruments (company_name, ISIN, ticker, short_name, full_name, st_reg_num, yield, lot_size) VALUES
	('BelAZ Co',         'BE1317836532', 'BLZ',  'BelAz',       'BelAZ Co',         '2-15-15678-R', 10000, 50) -- Не сработает, так как фирма BelAZ уже удалена.

SELECT * FROM GetCompanyInstruments
SELECT * FROM BlocksOfShares
GO

-- 02.2. Тест обновления инструментов.
SELECT N'02.2. Тест обновления инструментов.' AS subtest_type
GO

-- 02.3. Тест удаления инструментов.
SELECT N'02.3. Тест удаления инструментов.' AS subtest_type
GO

/* 03. Тест API для создания/обновления/удаления заявок в стакане. */
SELECT N'03. Тест API для создания/обновления/удаления заявок в стакане.' AS test_type
GO

-- 03.1. Тест вставки заявок.
SELECT N'03.1. Тест вставки заявок.' AS subtest_type
GO

INSERT INTO GetUserInstrumentDOM (login, ISIN, dir, amount, price) VALUES
	('liebherr', 'DE1497831032', 's', 10000, 10)
INSERT INTO GetUserInstrumentDOM (login, ISIN, dir, amount, price) VALUES
	('caterpillar', 'US1491231015', 's', 5000, 20)
INSERT INTO GetUserInstrumentDOM (login, ISIN, dir, amount, price) VALUES
	('liebherr', 'US1491231015', 'b', 2000, NULL)
INSERT INTO GetUserInstrumentDOM (login, ISIN, dir, amount, price) VALUES
	('liebherr', 'US1491231015', 's', 1000, NULL) -- ничего не произойдет, потому что никто не покупает акции Caterpillar.
INSERT INTO GetUserInstrumentDOM (login, ISIN, dir, amount, price) VALUES
	('liebherr', 'US1491231015', 's', 1000, 19)
INSERT INTO GetUserInstrumentDOM (login, ISIN, dir, amount, price) VALUES
	('m.masyagin1998', 'US1491231015', 'b', 20, 19)
INSERT INTO GetUserInstrumentDOM (login, ISIN, dir, amount, price) VALUES
	('m.masyagin1998', 'US1491231015', 'b', 100, 1)
INSERT INTO GetUserInstrumentDOM (login, ISIN, dir, amount, price) VALUES
	('a.barluka1998', 'DE1497831032', 'b', 10000, NULL)
INSERT INTO GetUserInstrumentDOM (login, ISIN, dir, amount, price) VALUES
	('liebherr', 'DE1497831032', 's', 100000, 1)
INSERT INTO GetUserInstrumentDOM (login, ISIN, dir, amount, price) VALUES
	('liebherr', 'US1491231015', 's', 25, 1)
INSERT INTO GetUserInstrumentDOM (login, ISIN, dir, amount, price) VALUES
	('liebherr', 'US1491231015', 's', 10000, 1) -- ничего не произойдет, потому что у liebherr нет такого кол-ва акций caterpillar.
INSERT INTO GetUserInstrumentDOM (login, ISIN, dir, amount, price) VALUES
	('liebherr', 'US1491231015', 's', 125, 1)
GO
SELECT * FROM GetUserInstrumentDOM
SELECT * FROM BlocksOfShares
SELECT * FROM Users
GO

-- Просмотреть все пары пользователь/акция, в том числе с пользователями без акций.
INSERT INTO GetPersonUsers (login, pw_hash, balance, first_name, second_name, last_name) VALUES
	('a.koshelev1997', (SELECT HASHBYTES('md5', 'golang')), 0, 'Andrew', 'Alekseevich', 'Koshelev')
-- LEFT JOIN
SELECT * FROM Users LEFT JOIN BlocksOfShares ON (user_id = id)
-- RIGHT JOIN
SELECT * FROM BlocksOfShares RIGHT JOIN Users ON (id = user_id)

-- Подсчитать количество заявок на продажу.
SELECT COUNT(*) AS number_of_sellers FROM GetUserInstrumentDOM WHERE (dir = 's')
-- Подсчитать количество заявок на покупку.
SELECT COUNT(*) AS number_of_buyers FROM GetUserInstrumentDOM WHERE (dir = 'b')
-- GROUP BY
SELECT * FROM BlocksOfShares
SELECT SUM(amount) AS sum_amount FROM BlocksOfShares GROUP BY user_id
SELECT SUM(amount) AS sum_amount FROM BlocksOfShares GROUP BY user_id HAVING MIN(amount) > 1000
-- Найти минимаьную цену на продажу акции 'US1491231015'
SELECT MIN(price) AS min_price FROM GetUserInstrumentDOM WHERE (dir = 's') AND (ISIN = 'US1491231015')
-- Найти минимаьную цену на продажу акции 'DE1497831032'
SELECT MAX(price) AS max_price FROM GetUserInstrumentDOM WHERE (dir = 's') AND (ISIN = 'DE1497831032')
-- Найти среднюю цену на продажу акции 'US1491231015'
SELECT AVG(price) AS avg_price FROM GetUserInstrumentDOM WHERE (dir = 's') AND (ISIN = 'DE1497831032')
-- Найти кол-во продаваемых акций 'US1491231015'
SELECT SUM(amount) AS sum_amount FROM GetUserInstrumentDOM WHERE (dir = 's') AND (ISIN = 'US1491231015')
-- Посмотреть все возможные торгующиеся акции.
SELECT DISTINCT ISIN AS ISIN, dir AS dir FROM GetUserInstrumentDOM

-- Вытащить и просто пользователей, и тех пользоватеелй, у которых есть акции (без дублей).
SELECT login FROM Users UNION SELECT login FROM Users JOIN BlocksOfShares ON (id = user_id)
-- Вытащить и просто пользователей, и тех пользоватеелй, у которых есть акции (мб с дублями).
SELECT login FROM Users UNION ALL SELECT login FROM Users JOIN BlocksOfShares ON (id = user_id)
-- Вытащить ID тех пользователей, у которых есть заявки на продажу в DOM, так и акции в банке (INTERSECT).
SELECT * FROM BlocksOfShares
SELECT * FROM DOM
SELECT user_id FROM DOM WHERE (dir = 's') INTERSECT SELECT user_id FROM BlocksOfShares
-- Вытащить ID тех пользователей, у которых есть заявки в DOM и нет акций в банке (EXCEPT)
INSERT INTO GetUserInstrumentDOM (login, ISIN, dir, amount, price) VALUES
	('m.masyagin1998', 'US1491231015', 's', 45, 10)
SELECT user_id FROM DOM WHERE (dir = 's') EXCEPT SELECT user_id FROM BlocksOfShares
-- ORDER BY DESC
SELECT * FROM GetInstrumentDOMInner WHERE (dir = 's') ORDER BY price DESC, timestamp DESC
-- FULL OUTTER JOIN
SELECT * FROM DOM FULL OUTER JOIN BlocksOfShares ON (DOM.user_id = BlocksOfShares.user_id) AND (DOM.instrument_id = BlocksOfShares.instrument_id)

-- LIKE
SELECT * FROM GetPersonUsers WHERE login LIKE '%1998'
-- IN
SELECT * FROM GetInstrumentDOMInner WHERE price IN (1, 19)
-- BETWEEN
SELECT * FROM GetInstrumentDOMInner WHERE price BETWEEN 1 AND 10


/* Удаление БД */
/*
USE master
GO
ALTER DATABASE ExchangeTransactions SET SINGLE_USER WITH ROLLBACK IMMEDIATE
GO
DROP DATABASE ExchangeTransactions
GO
*/