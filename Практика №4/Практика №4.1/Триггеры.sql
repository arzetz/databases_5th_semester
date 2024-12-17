--Триггер 1
CREATE OR REPLACE FUNCTION manage_realtor_bonus()
RETURNS TRIGGER AS $$
BEGIN
    IF TG_OP = 'INSERT' THEN
        IF EXISTS (SELECT 1 FROM bonuses WHERE realtor_id = NEW.realtor_id) THEN
            UPDATE bonuses
            SET total_bonus = total_bonus + (NEW.sale_price * 0.05)
            WHERE realtor_id = NEW.realtor_id;
        ELSE
            INSERT INTO bonuses (realtor_id, total_bonus)
            VALUES (NEW.realtor_id, NEW.sale_price * 0.05);
        END IF;
    END IF;

    IF TG_OP = 'DELETE' THEN
        UPDATE bonuses
        SET total_bonus = total_bonus - (OLD.sale_price * 0.05)
        WHERE realtor_id = OLD.realtor_id;

        DELETE FROM bonuses WHERE total_bonus <= 0;
    END IF;

    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE or replace TRIGGER insert_bonus
AFTER insert or delete ON sale
FOR EACH ROW
EXECUTE FUNCTION manage_realtor_bonus();

--Триггер 2
--Меняем функцию, отсылающую на триггер
CREATE OR REPLACE FUNCTION update_real_estate_status()
RETURNS TRIGGER AS $$
BEGIN
    IF TG_OP = 'INSERT' THEN
        UPDATE real_estate
        SET status = 0
        WHERE real_estate_id = NEW.real_estate_id;

    ELSIF TG_OP = 'DELETE' THEN
        UPDATE real_estate
        SET status = 1
        WHERE real_estate_id = OLD.real_estate_id;
    END IF;

    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

--Триггер 3
CREATE OR REPLACE FUNCTION format_contact_phone()
RETURNS TRIGGER AS $$
BEGIN
    IF LENGTH(NEW.contact_phone) = 11 AND NEW.contact_phone ~ '^[0-9]{11}$' THEN
        NEW.contact_phone := 
            '+7 (' || SUBSTRING(NEW.contact_phone FROM 2 FOR 3) || ') ' || 
            SUBSTRING(NEW.contact_phone FROM 5 FOR 3) || ' ' ||
            SUBSTRING(NEW.contact_phone FROM 8 FOR 2) || ' ' ||
            SUBSTRING(NEW.contact_phone FROM 10 FOR 2);
    ELSE
        RAISE EXCEPTION 'Некорректный формат номера телефона: %', NEW.contact_phone;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER format_contact_phone
BEFORE INSERT OR UPDATE ON realtor
FOR EACH ROW
EXECUTE FUNCTION format_contact_phone();

--Триггер 4
CREATE TABLE journal (
    operation_time TIMESTAMP DEFAULT now(),
    operation_type VARCHAR(10),            
    user_name VARCHAR(50)                  
);

CREATE OR REPLACE FUNCTION log_sale_insert()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO journal (operation_time, operation_type, user_name)
    VALUES (now(), TG_OP, current_user); --Логируем пользователя

    RETURN NEW; --Для AFTER триггера
END;
$$ LANGUAGE plpgsql;

CREATE or replace TRIGGER log_sale_insert
AFTER INSERT OR UPDATE OR DELETE ON sale
FOR EACH ROW
EXECUTE FUNCTION log_sale_insert();

INSERT INTO sale (sale_id, real_estate_id, sale_date, realtor_id, sale_price, realtor_commission)
VALUES (28, 29, '2024-06-02 12:00', 2, 1000000, 2.5);
