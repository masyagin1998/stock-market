/* 01. Создание базы данных для биржевых транзакций. */
SELECT N'01. Создание базы данных для биржевых транзакций.' as description
GO
Use master
IF (db_id('ExchangeTransactions') IS NULL)
BEGIN
	CREATE DATABASE ExchangeTransactions
		ON PRIMARY
		(NAME = ExchangeTransactionsPrimaryData,
			FILENAME = 'C:\Program Files\Microsoft SQL Server\MSSQL11.MSSQLSERVER\MSSQL\DATA\mikhail\lab11\exchange_transactions_db.mdf',
			SIZE = 5MB, MAXSIZE = 50MB, FILEGROWTH = 5%),
		(NAME = ExchangeTransactionsSecondaryData,
			FILENAME = 'C:\Program Files\Microsoft SQL Server\MSSQL11.MSSQLSERVER\MSSQL\DATA\mikhail\lab11\exchange_transactions_db1.ndf',
			SIZE = 5MB, MAXSIZE = 50MB, FILEGROWTH = 5%)
		LOG ON
		(NAME = LogOne, 
			FILENAME = 'C:\Program Files\Microsoft SQL Server\MSSQL11.MSSQLSERVER\MSSQL\DATA\mikhail\lab11\exchange_transactions_log.ldf');
END
GO

USE ExchangeTransactions;
GO

/* 02. Создание таблиц. */
SELECT N'02. Создание таблиц.' as description
GO

-- 02.1 Создание таблиц пользователей.
SELECT N'02.1 Создание таблиц пользователей.' as subdescription
GO

IF (NOT EXISTS(SELECT * FROM sysobjects WHERE ((name = 'Users') AND (xtype ='U'))))
BEGIN
	CREATE TABLE Users (
		id bigint IDENTITY(1, 1) NOT NULL PRIMARY KEY,
		login varchar(128) NOT NULL,
		pw_hash varchar(128) NOT NULL,
		balance bigint NOT NULL DEFAULT(0),
		CONSTRAINT users_unique_login UNIQUE(login),
		CONSTRAINT users_non_negative_balance CHECK(balance >= 0)
	)
END
GO

IF (NOT EXISTS(SELECT * FROM sysobjects WHERE ((name = 'Persons') AND (xtype ='U'))))
BEGIN
	CREATE TABLE Persons (
		id bigint NOT NULL,
		first_name varchar(128) NOT NULL,
		second_name varchar(128) NOT NULL,
		last_name varchar(128) NOT NULL,
		CONSTRAINT persons_fk_person_user FOREIGN KEY (id) REFERENCES Users(id) ON DELETE CASCADE,
		CONSTRAINT persons_unique_id UNIQUE(id)
	)
END
GO

IF (NOT EXISTS(SELECT * FROM sysobjects WHERE ((name = 'Companies') AND (xtype ='U'))))
BEGIN
	CREATE TABLE Companies (
		id bigint NOT NULL,
		name varchar(128) NOT NULL,
		CONSTRAINT companies_fk_person_company FOREIGN KEY (id) REFERENCES Users(id) ON DELETE CASCADE,
		CONSTRAINT companies_unique_id UNIQUE(id)
	)
END
GO

-- 02.2 Создание таблицы инструментов.
SELECT N'02.2 Создание таблицы инструментов.' as subdescription
GO

IF (NOT EXISTS(SELECT * FROM sysobjects WHERE ((name = 'Instruments') AND (xtype ='U'))))
BEGIN
	CREATE TABLE Instruments (
		id bigint IDENTITY(1, 1) NOT NULL PRIMARY KEY,
		company_id bigint NOT NULL,
		ISIN char(12) NOT NULL,
		ticker varchar(128) NOT NULL,
		short_name varchar(128) NOT NULL,
		full_name varchar(128) NOT NULL,
		st_reg_num varchar(128) NOT NULL,
		yield bigint NOT NULL,
		lot_size bigint NOT NULL,
		CONSTRAINT instruments_positive_yield CHECK(yield > 0),
		CONSTRAINT instruments_positivie_lot_size CHECK(lot_size > 0),
		CONSTRAINT instruments_fk_company_instruments FOREIGN KEY (company_id) REFERENCES Companies (id),
		CONSTRAINT instruments_unique_isin UNIQUE(ISIN),
		CONSTRAINT instruments_unique_ticker UNIQUE(ticker),
		CONSTRAINT instruments_unique_st_reg_num UNIQUE(st_reg_num)
	)
END
GO

-- 02.3 Создание таблицы блоков акций.
SELECT N'02.3 Создание таблицы блоков акций.' as subdescription
GO

IF (NOT EXISTS(SELECT * FROM sysobjects WHERE ((name = 'BlocksOfShares') AND (xtype ='U'))))
BEGIN
	CREATE TABLE BlocksOfShares (
		user_id bigint NOT NULL,
		instrument_id bigint NOT NULL,
		amount bigint NOT NULL
		CONSTRAINT block_of_shares_positive_price CHECK(amount > 0),
		CONSTRAINT block_of_shares_fk_users_block_of_shares FOREIGN KEY (user_id) REFERENCES Users (id),
		CONSTRAINT block_of_shares_fk_instruments_block_of_shares FOREIGN KEY (instrument_id) REFERENCES Instruments (id)
	)
END
GO

-- 02.4 Создание таблицы - стакана.
SELECT N'02.4 Создание таблицы - стакана.' as subdescription
GO

IF (NOT EXISTS(SELECT * FROM sysobjects WHERE ((name = 'DOM') AND (xtype ='U'))))
BEGIN
	CREATE TABLE DOM (
		id bigint IDENTITY(1, 1) NOT NULL PRIMARY KEY,
		user_id bigint NOT NULL,
		instrument_id bigint NOT NULL,
		dir char(1) NOT NULL,
		amount bigint NOT NULL,
		price bigint,
		timestamp DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
		CONSTRAINT dom_dir_buy_or_sell CHECK((DIR = 'b') OR (DIR = 's')),
		CONSTRAINT dom_positive_amount CHECK(amount > 0),
		CONSTRAINT dom_positive_price CHECK(price > 0),
		CONSTRAINT dom_fk_users_dom FOREIGN KEY (user_id) REFERENCES Users (id),
		CONSTRAINT dom_fk_instruments_dom FOREIGN KEY (instrument_id) REFERENCES Instruments (id)
	)
END
GO

/* 03. Создание триггеров. Все триггеры рассчитаны на единичную вставку/обновление/удаление. */
SELECT N'03. Создание триггеров.' as description
GO

-- 03.1. Создание триггеров на создание/обновление/удаление пользователей.
SELECT N'03.1. Создание триггеров на создание/изменение/удаление пользователей.' as description
GO

---- 03.1.1 Создание триггеров на создание/обновление/удаление пользователя-физического лица.
IF Object_ID('dbo.GetPersonUsers') IS NOT NULL
    DROP VIEW dbo.GetPersonUsers;
GO
CREATE VIEW GetPersonUsers WITH SCHEMABINDING AS
	SELECT Users.login AS login, Users.pw_hash AS pw_hash, Users.balance AS balance,
	Persons.first_name AS first_name, Persons.second_name AS second_name, Persons.last_name AS last_name
	FROM dbo.Users JOIN dbo.Persons ON (dbo.Users.id = dbo.Persons.id)
GO

CREATE TRIGGER InsertPersonUser ON GetPersonUsers INSTEAD OF INSERT AS
BEGIN
	INSERT INTO Users (login, pw_hash, balance) (SELECT login, pw_hash, balance FROM inserted)
	INSERT INTO Persons (id, first_name, second_name, last_name) (SELECT id, first_name, second_name, last_name FROM inserted JOIN Users ON (Users.login = inserted.login))
END
GO

CREATE TRIGGER UpdatePersonUser ON GetPersonUsers INSTEAD OF UPDATE AS
BEGIN
	UPDATE Users SET
		login = (SELECT login FROM inserted),
		pw_hash = (SELECT pw_hash FROM inserted),
		balance = (SELECT balance FROM inserted)
		WHERE (login = (SELECT login FROM deleted))
	UPDATE Persons SET
		first_name = (SELECT first_name FROM inserted),
		second_name = (SELECT second_name FROM inserted),
		last_name = (SELECT last_name FROM inserted)
		WHERE (id = (SELECT id FROM Users WHERE (login = (SELECT login FROM deleted))))
END
GO

CREATE TRIGGER DeletePersonUser ON GetPersonUsers INSTEAD OF DELETE AS
BEGIN
	DECLARE @user_id bigint = (SELECT Users.id FROM deleted JOIN Users ON (deleted.login = Users.login))	
	DECLARE @balance bigint = (SELECT Users.balance FROM Users WHERE (Users.id = @user_id))
	IF ((@balance > 0) OR EXISTS(SELECT * FROM BlocksOfShares WHERE (BlocksOfShares.user_id = @user_id)))
	BEGIN
		RAISERROR('Невозможно удалить физическое лицо, так как у него ненулевой баланс или он владеет акциями.', 18, 10)
	END
	ELSE
	BEGIN
		DELETE FROM Users WHERE (Users.id = @user_id) /* Сработает каскадное удаление и также удалится запись в Persons). */
	END
END
GO

---- 03.1.2 Создание триггеров на создание/обновление/удаление пользователя-юридического лица.
IF Object_ID('dbo.GetCompanyUsers') IS NOT NULL
    DROP VIEW dbo.GetPersonUsers;
GO
CREATE VIEW GetCompanyUsers WITH SCHEMABINDING AS
	SELECT Users.login AS login, Users.pw_hash AS pw_hash, Users.balance AS balance,
	Companies.name AS name
	FROM dbo.Users JOIN dbo.Companies ON (dbo.Users.id = dbo.Companies.id)
GO

CREATE TRIGGER InsertCompanyUser ON GetCompanyUsers INSTEAD OF INSERT AS
BEGIN
	INSERT INTO Users (login, pw_hash, balance) (SELECT login, pw_hash, balance FROM inserted)
	INSERT INTO Companies(id, name) (SELECT id, name FROM inserted JOIN Users ON (Users.login = inserted.login))
END
GO

CREATE TRIGGER UpdateCompanyUser ON GetCompanyUsers INSTEAD OF UPDATE AS
BEGIN
	UPDATE USERS SET
		login = (SELECT login FROM inserted),
		pw_hash = (SELECT pw_hash FROM inserted),
		balance = (SELECT balance FROM inserted)
		WHERE (login = (SELECT login FROM deleted))
	UPDATE Companies SET
		name = (SELECT name FROM inserted)
		WHERE (id = (SELECT id FROM Users WHERE (login = (SELECT login FROM deleted))))
END
GO

CREATE TRIGGER DeleteCompanyUser ON GetCompanyUsers INSTEAD OF DELETE AS
BEGIN
	DECLARE @user_id bigint = (SELECT Users.id FROM deleted JOIN Users ON (deleted.login = Users.login))	
	DECLARE @balance bigint = (SELECT Users.balance FROM Users WHERE (Users.id = @user_id))
	IF ((@balance > 0) OR EXISTS(SELECT * FROM BlocksOfShares WHERE (BlocksOfShares.user_id = @user_id)))
	BEGIN
		RAISERROR('Невозможно удалить юридическое лицо, так как у него ненулевой баланс или он владеет акциями.', 18, 10)
	END
	ELSE
	BEGIN
		DELETE FROM Users WHERE (Users.id = @user_id) /* Сработает каскадное удаление и также удалится запись в Companies). */
	END	
END
GO

-- 03.2 Создание триггеров на создание/обновление/удаление новых типов инструментов.
SELECT N'03.2. Создание триггеров на создание/обновление/удаление новых типов инструментов.' as description
GO

IF Object_ID('dbo.GetCompanyInstruments') IS NOT NULL
    DROP VIEW dbo.GetCompanyInstruments;
GO
CREATE VIEW GetCompanyInstruments WITH SCHEMABINDING AS
	SELECT Companies.name AS company_name, Instruments.ISIN AS ISIN, Instruments.ticker AS ticker, 
	Instruments.short_name AS short_name, Instruments.full_name AS full_name,
	Instruments.st_reg_num AS st_reg_num, Instruments.yield AS yield, Instruments.lot_size AS lot_size 
	FROM dbo.Companies JOIN dbo.Instruments ON (dbo.Companies.id = dbo.Instruments.company_id)
GO

CREATE TRIGGER InsertCompanyInstrumet ON GetCompanyInstruments INSTEAD OF INSERT AS
BEGIN
	INSERT INTO Instruments (company_id, ISIN, ticker, short_name, full_name, st_reg_num, yield, lot_size)
	(SELECT id, ISIN, ticker, short_name, full_name, st_reg_num, yield, lot_size FROM inserted JOIN Companies ON (inserted.company_name = Companies.name))
	INSERT INTO BlocksOfShares (user_id, instrument_id, amount) (SELECT company_id, id, yield FROM Instruments WHERE (Instruments.ISIN = (SELECT ISIN FROM inserted)))
END
GO

CREATE TRIGGER UpdateCompanyInstrumet ON GetCompanyInstruments INSTEAD OF UPDATE AS
BEGIN
	RAISERROR('Невозможно обновить инструмент, если он уже был создан.', 18, 10)
	ROLLBACK
END
GO

CREATE TRIGGER DeleteCompanyInstrumet ON GetCompanyInstruments INSTEAD OF DELETE AS
BEGIN
	RAISERROR('Невозможно удалить инструмент, если он уже попал на биржу.', 18, 10)
	ROLLBACK
END
GO

-- 03.3 Создание триггеров на создание/обновление/удаление заявок в биржевом стакане.
SELECT N'03.3. Создание триггеров на создание/обновление/удаление заявок в биржевом стакане.' as description
GO

IF Object_ID('dbo.GetInstrumentDOMInner') IS NOT NULL
    DROP VIEW dbo.GetInstrumentDOMInner;
GO
CREATE VIEW GetInstrumentDOMInner WITH SCHEMABINDING AS
	SELECT Instruments.ISIN AS ISIN, DOM.user_id AS id, DOM.dir AS dir, DOM.amount AS amount, DOM.price AS price, DOM.timestamp AS timestamp
	FROM dbo.Instruments JOIN dbo.DOM ON (Instruments.id = DOM.instrument_id)
GO

IF Object_ID('dbo.GetUserInstrumentDOM') IS NOT NULL
    DROP VIEW dbo.GetUserInstrumentDOM;
GO
CREATE VIEW GetUserInstrumentDOM WITH SCHEMABINDING AS
	SELECT Users.login AS login,
		GetInstrumentDOMInner.ISIN AS ISIN, GetInstrumentDOMInner.dir AS dir,
		GetInstrumentDOMInner.amount AS amount, GetInstrumentDOMInner.price AS price,
		GetInstrumentDOMInner.timestamp AS timestamp
	FROM dbo.Users JOIN dbo.GetInstrumentDOMInner ON (Users.id = GetInstrumentDOMInner.id)
GO

CREATE TRIGGER InsertUserInstrumentDOM ON GetUserInstrumentDOM INSTEAD OF INSERT AS
BEGIN
	/* Рыночные заявки не сохраняются, лимитные заявки сохраняются. */
	-- 1. Всевозможные проверки.
	DECLARE @login varchar(128)
	DECLARE @ISIN char(12)
	DECLARE @dir char(1)
	DECLARE @amount bigint
	DECLARE @price bigint
	SELECT @login = login, @ISIN = ISIN, @dir = dir, @amount = amount, @price = price FROM inserted
	DECLARE @instrument_id bigint = (SELECT id FROM Instruments WHERE (ISIN = @ISIN))
	DECLARE @user_id bigint = (SELECT id FROM Users WHERE (login = @login))
	DECLARE @balance bigint = (SELECT balance FROM Users WHERE (id = @user_id))
	DECLARE @target_amount bigint = 0
	-- Проверка наличия инструмента.
	IF (NOT EXISTS(SELECT * FROM Instruments WHERE (Instruments.ISIN = @ISIN)))
	BEGIN
		RAISERROR('Невозможно подать заявку с несуществующим инструментом.', 18, 10)
		ROLLBACK
	END
	-- Если заявка направлена на продажу, то проверка того, возможно ли пользователю выставить столько пакетов акций или нет.
	IF (@dir = 's')
	BEGIN
		DECLARE @curr_amount bigint = (SELECT amount FROM BlocksOfShares WHERE (user_id = @user_id) AND (instrument_id = @instrument_id))
		IF (@curr_amount < @amount)
		BEGIN
			RAISERROR('Невозможно подать заявку на продажу акций, не имея достаточное их кол-во.', 18, 10)
			ROLLBACK	
		END
		IF (@curr_amount = @amount) DELETE FROM BlocksOfShares WHERE (user_id = @user_id) AND (instrument_id = @instrument_id)
		ELSE UPDATE BlocksOfShares SET amount = amount - @amount WHERE (user_id = @user_id) AND (instrument_id = @instrument_id)
	END
	-- Если заявка направлена на покупку с лимитом, то проверка того, есть ли столько денег у пользователя.
	IF ((@dir = 'b') AND (@balance < @amount * @price))
	BEGIN
		RAISERROR('Невозможно подать лимитную заявку на покупку акций, не имея достаточного кол-ва денег.', 18, 10)
		ROLLBACK		
	END

	-- 2. Попытка свести ее сейчас же, если это возможно.
	DECLARE @dom_id bigint
	DECLARE @dom_user_id bigint
	DECLARE @dom_amount bigint
	DECLARE @dom_price bigint
	DECLARE @lookup_dom CURSOR
	-- В случае новой заявки на продажу, вытаскиваем все имеющиеся лимитные заявки на покупку и сортируем их по цене/времени.
	IF (@dir = 's')
	BEGIN
		SET @lookup_dom = CURSOR FORWARD_ONLY STATIC FOR SELECT id, user_id, amount, price FROM DOM
		WHERE ((dir = 'b') AND (instrument_id = @instrument_id) AND (price IS NOT NULL)) ORDER BY price ASC, timestamp ASC
	END
	-- В случае новой заявки на покупку, вытаскиваем все имеющиеся лимитные заявки на продажу и сортируем их по цене/времени.
	ELSE IF (@dir = 'b')
	BEGIN
		SET @lookup_dom = CURSOR FORWARD_ONLY STATIC FOR SELECT id, user_id, amount, price FROM DOM
		WHERE ((dir = 's') AND (instrument_id = @instrument_id) AND (price IS NOT NULL)) ORDER BY price ASC, timestamp ASC
	END
	OPEN @lookup_dom
	FETCH NEXT FROM @lookup_dom INTO @dom_id, @dom_user_id, @dom_amount, @dom_price
	DECLARE @count bigint
	WHILE (@@FETCH_STATUS = 0)
	BEGIN
		-- Можно переписать IF'ы более грамотно, но так нагляднее.
		-- Идет продажа по лимитной заявке.
		IF ((@dir = 's') AND (@price IS NOT NULL))
		BEGIN
			IF ((@dom_price < @price) OR (@amount = 0)) BREAK -- Если не выполняется условие продажи по лимитной заявке.
			SET @count = @amount
			IF (@count > @dom_amount) SET @count = @dom_amount
			SET @balance = @balance + @count * @dom_price
			UPDATE Users SET balance = balance - @count * @dom_price WHERE (id = @dom_user_id)
			SET @amount = @amount - @count
			IF (@dom_amount - @count > 0) UPDATE DOM SET amount = amount - @count WHERE (id = @dom_id)
			ELSE DELETE FROM DOM WHERE (id = @dom_id)
			IF (EXISTS(SELECT * FROM BlocksOfShares WHERE (user_id = @dom_user_id) AND (instrument_id = @instrument_id))) UPDATE BlocksOfShares SET amount = amount + @count WHERE (user_id = @dom_user_id) AND (instrument_id = @instrument_id)
			ELSE INSERT INTO BlocksOfShares (user_id, instrument_id, amount) (SELECT @dom_user_id, @instrument_id, @count)
				 
		END
		-- Идет продажа по рыночной заявке.
		IF ((@dir = 's') AND (@price IS NULL))
		BEGIN
			IF (@amount = 0) BREAK -- Если не выполняется условие продажи по рыночной заявке.
			SET @count = @amount
			IF (@count > @dom_amount) SET @count = @dom_amount
			SET @balance = @balance + @count * @dom_price
			UPDATE Users SET balance = balance - @count * @dom_price WHERE (id = @dom_user_id)
			SET @amount = @amount - @count
			IF (@dom_amount - @count > 0) UPDATE DOM SET amount = amount - @count WHERE (id = @dom_id)
			ELSE DELETE FROM DOM WHERE (id = @dom_id)
			IF (EXISTS(SELECT * FROM BlocksOfShares WHERE (user_id = @dom_user_id) AND (instrument_id = @instrument_id))) UPDATE BlocksOfShares SET amount = amount + @count WHERE (user_id = @dom_user_id) AND (instrument_id = @instrument_id)
			ELSE INSERT INTO BlocksOfShares (user_id, instrument_id, amount) (SELECT @dom_user_id, @instrument_id, @count)
		END
		-- Идет покупка по лимитной заявке.
		IF ((@dir = 'b') AND (@price IS NOT NULL))
		BEGIN
			IF ((@dom_price > @price) OR (@amount = 0)) BREAK -- Если не выполняется условие покупки по лимитной заявке.
			SET @count = @amount
			IF (@count > @dom_amount) SET @count = @dom_amount
			SET @balance = @balance - @count * @dom_price
			UPDATE Users SET balance = balance + @count * @dom_price WHERE (id = @dom_user_id)
			SET @target_amount = @target_amount + @count
			SET @amount = @amount - @count
			IF (@dom_amount - @count > 0) UPDATE DOM SET amount = amount - @count WHERE (id = @dom_id)
			ELSE DELETE FROM DOM WHERE (id = @dom_id)
		END
		-- Идет покупка по рыночной заявке.
		IF ((@dir = 'b') AND (@price IS NULL))
		BEGIN
			IF ((@amount = 0) OR (@price > @balance)) BREAK -- Если не выполняется условие покупки по рыночной заявке.
			SET @count = @amount
			IF (@count > (@balance / @dom_price)) SET @count = (@balance / @dom_price)
			SET @balance = @balance - @count * @dom_price
			UPDATE Users SET balance = balance + @count * @dom_price WHERE (id = @dom_user_id)
			SET @target_amount = @target_amount + @count
			SET @amount = @amount - @count
			IF (@dom_amount - @count > 0) UPDATE DOM SET amount = amount - @count WHERE (id = @dom_id)
			ELSE DELETE FROM DOM WHERE (id = @dom_id)
		END
		FETCH NEXT FROM @lookup_dom INTO @dom_id, @dom_user_id, @dom_amount, @dom_price
	END
	CLOSE @lookup_dom
	DEALLOCATE @lookup_dom

	-- 3. Сохранение того, что сразу же заработал пользователь.
	IF (@dir = 's')
	BEGIN
		UPDATE Users SET balance = @balance WHERE (id = @user_id)
		IF (@price IS NULL) UPDATE BlocksOfShares SET amount = amount + @amount WHERE (user_id = @user_id) AND (instrument_id = @instrument_id)
	END
	IF (@dir = 'b')
	BEGIN
		UPDATE Users SET balance = @balance WHERE (id = @user_id)
		IF (EXISTS(SELECT * FROM BlocksOfShares WHERE (user_id = @user_id) AND (instrument_id = @instrument_id))) UPDATE BlocksOfShares SET amount = amount + @target_amount WHERE (user_id = @user_id) AND (instrument_id = @instrument_id)
		ELSE INSERT INTO BlocksOfShares (user_id, instrument_id, amount) (SELECT @user_id, @instrument_id, @target_amount)
	END

	-- 4. Добавление заявки в биржевой стакан, если еще что-то осталось.
	IF ((@dir = 's') AND (@price IS NOT NULL) AND (@amount > 0)) INSERT INTO DOM (user_id, instrument_id, dir, amount, price) (SELECT @user_id, @instrument_id, @dir, @amount, @price)
	IF ((@dir = 'b') AND (@price IS NOT NULL) AND (@amount > 0)) INSERT INTO DOM (user_id, instrument_id, dir, amount, price) (SELECT @user_id, @instrument_id, @dir, @amount, @price)	
END
GO

CREATE TRIGGER UpdateUserInstrumentDOM ON GetUserInstrumentDOM INSTEAD OF UPDATE AS
BEGIN
	RAISERROR('Невозможно обновить заявку, если она уже в стакане. Ее можно только удалить.', 18, 10)
	ROLLBACK	
END
GO

CREATE TRIGGER DeleteUserInstrumentDOM ON GetUserInstrumentDOM INSTEAD OF DELETE AS
BEGIN
	DECLARE @login varchar(128)
	DECLARE @ISIN char(12)
	DECLARE @dir char(1)
	DECLARE @amount bigint
	DECLARE @price bigint
	DECLARE @timestamp DATETIME
	SELECT @login = login, @ISIN = ISIN, @dir = dir, @amount = amount, @price = price, @timestamp = timestamp FROM deleted
	DECLARE @instrument_id bigint = (SELECT id FROM Instruments WHERE (ISIN = @ISIN))
	DECLARE @user_id bigint = (SELECT id FROM Users WHERE (login = @login))
	IF (@dir = 's')
	BEGIN
		IF (EXISTS(SELECT * FROM BlocksOfShares WHERE (user_id = @user_id) AND (instrument_id = @instrument_id))) UPDATE BlocksOfShares SET amount = amount + @amount WHERE (user_id = @user_id) AND (instrument_id = @instrument_id)
		ELSE INSERT INTO BlocksOfShares (user_id, instrument_id, amount) (SELECT @user_id, @instrument_id, @amount)
	END
	DELETE FROM DOM WHERE (user_id = @user_id) AND (instrument_id = @instrument_id) AND (timestamp = @timestamp)
END
GO