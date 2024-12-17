--Триггер 1
CREATE TABLE bonuses (
    realtor_id INT PRIMARY KEY,
    total_bonus NUMERIC DEFAULT 0
);

CREATE OR REPLACE FUNCTION update_realtor_bonus()
RETURNS TRIGGER AS $$
BEGIN
    IF EXISTS (SELECT 1 FROM bonuses WHERE realtor_id = NEW.realtor_id) THEN
        UPDATE bonuses
        SET total_bonus = total_bonus + (NEW.sale_price * 0.05)
        WHERE realtor_id = NEW.realtor_id;
    ELSE
        INSERT INTO bonuses (realtor_id, total_bonus)
        VALUES (NEW.realtor_id, NEW.sale_price * 0.05);
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER insert_bonus
AFTER INSERT ON sale
FOR EACH ROW
EXECUTE FUNCTION update_realtor_bonus();

INSERT INTO sale (sale_id, real_estate_id, sale_date, realtor_id, sale_price, realtor_commission)
VALUES (21, 31, '2024-06-02 12:00:00', 2, 1000000, 2.5);

--Триггер 2
CREATE OR REPLACE FUNCTION check_bonus_limit()
RETURNS TRIGGER AS $$
BEGIN
    IF (SELECT total_bonus FROM bonuses WHERE realtor_id = NEW.realtor_id) > 300000 THEN
        RAISE NOTICE 'Бонус риэлтора % превысил 300000 рублей!', NEW.realtor_id;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER check_bonus_limit
AFTER INSERT ON sale
FOR EACH ROW
EXECUTE FUNCTION check_bonus_limit();

--Триггер 3
ALTER TABLE realtor
ADD COLUMN passport_data VARCHAR(15);

CREATE OR REPLACE FUNCTION passport_check()
RETURNS TRIGGER AS $$
BEGIN
--Юзаем regexp
    IF NEW.passport_data !~ '^[0-9]{4} [0-9]{6}$' THEN
        RAISE EXCEPTION 'Некорректный формат паспортных данных: %.', NEW.passport_data;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER passport_check
BEFORE INSERT OR UPDATE ON realtor
FOR EACH ROW
EXECUTE FUNCTION passport_check();

INSERT INTO realtor (realtor_id, passport_data)
VALUES (101, '1234 567890');