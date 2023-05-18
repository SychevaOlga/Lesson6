-- 1. Создайте таблицу users_old, аналогичную таблице users. Создайте процедуру, с
-- помощью которой можно переместить любого (одного) пользователя из таблицы
-- users в таблицу users_old. (использование транзакции с выбором commit или rollback
-- – обязательно).

CREATE TABLE users_old LIKE users;
DELIMITER //
CREATE PROCEDURE move_user(IN id INT)
BEGIN
    START TRANSACTION;
    INSERT INTO users_old SELECT * FROM users WHERE id = id;
    DELETE FROM users WHERE id = id;
    IF ROW_COUNT() = 1 THEN
        COMMIT;
    ELSE
        ROLLBACK;
    END IF;
END//
DELIMITER ;

-- 2. Создайте хранимую функцию hello(), которая будет возвращать приветствие, в
-- зависимости от текущего времени суток. С 6:00 до 12:00 функция должна
-- возвращать фразу "Доброе утро", с 12:00 до 18:00 функция должна возвращать
-- фразу "Добрый день", с 18:00 до 00:00 — "Добрый вечер", с 00:00 до 6:00 — "Доброй
-- ночи".

-- Для того чтобы у меня работал NOT DETERMINISTIC мне нужно было задать вот такую переменную
SET GLOBAL log_bin_trust_function_creators = 1;

DROP FUNCTION IF EXISTS hello;
DELIMITER //
CREATE FUNCTION hello() RETURNS text CHARSET utf8mb4 NOT DETERMINISTIC
BEGIN
	DECLARE return_text text;
	if hour(now())>=6 AND hour(now())<=12 then
	  set return_text='Доброе утро';
	elseif hour(now())>12 AND hour(now())<=18 then
	  set return_text='Добрый день';
	elseif hour(now())>18 AND hour(now())<=23 then 
	  set return_text='Добрый вечер';
	else 
	  set return_text='Доброй ночи'; 
	end if;
RETURN return_text;
END//
DELIMITER ;

SELECT hello();

-- 3. (по желанию)* Создайте таблицу logs типа Archive. Пусть при каждом создании
-- записи в таблицах users, communities и messages в таблицу logs помещается время и
-- дата создания записи, название таблицы, идентификатор первичного ключа.

CREATE TABLE logs (
  id INT PRIMARY KEY AUTO_INCREMENT,
  created_at DATETIME,
  table_name VARCHAR(50),
  primary_key_id INT
) ENGINE=ARCHIVE;

CREATE TRIGGER users_create_trigger AFTER INSERT ON users
FOR EACH ROW
INSERT INTO logs (created_at, table_name, primary_key_id) VALUES (NOW(), 'users', NEW.id);

CREATE TRIGGER communities_create_trigger AFTER INSERT ON communities
FOR EACH ROW
INSERT INTO logs (created_at, table_name, primary_key_id) VALUES (NOW(), 'communities', NEW.id);

CREATE TRIGGER messages_create_trigger AFTER INSERT ON messages
FOR EACH ROW
INSERT INTO logs (created_at, table_name, primary_key_id) VALUES (NOW(), 'messages', NEW.id);
