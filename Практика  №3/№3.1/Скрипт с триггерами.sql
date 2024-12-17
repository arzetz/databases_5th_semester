--Триггер 1
CREATE OR REPLACE FUNCTION update_real_estate_status()
RETURNS TRIGGER AS $$
BEGIN
    UPDATE real_estate
    SET status = 0
    WHERE real_estate_id = NEW.real_estate_id;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER after_sale_insert
AFTER INSERT ON sale
FOR EACH ROW
EXECUTE FUNCTION update_real_estate_status();

DELETE FROM sale WHERE real_estate_id = 22;
DELETE FROM real_estate WHERE real_estate_id = 22;
INSERT INTO sale (sale_id, real_estate_id, sale_date, realtor_id, sale_price, realtor_commission)
VALUES (11, 22, '2024-03-02 04:40:52.970', 2, 518493.229606477, 2.0);

--Триггер 2

CREATE OR REPLACE FUNCTION difference_attention()
RETURNS TRIGGER AS $$
BEGIN
    IF (SELECT ABS(price - NEW.sale_price) / price * 100 
        FROM real_estate 
        WHERE real_estate_id = NEW.real_estate_id) > 20 THEN
        RAISE NOTICE 'Разница между заявленной и продажной стоимостью более 20%%';
    	END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

create or replace TRIGGER difference_attention
AFTER INSERT ON sale
FOR EACH ROW
EXECUTE FUNCTION difference_attention();

--Триггер 3
CREATE OR REPLACE FUNCTION check_real_estate_status()
RETURNS TRIGGER AS $$
BEGIN
    IF EXISTS (SELECT 1 FROM sale WHERE real_estate_id = NEW.real_estate_id) THEN
        RAISE EXCEPTION 'Невозможно добавить продажу: объект недвижимости уже продан.';
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER check_real_estate_status
BEFORE INSERT ON sale
FOR EACH ROW
EXECUTE FUNCTION check_real_estate_status();

--Триггер 4
CREATE OR REPLACE FUNCTION check_area()
RETURNS TRIGGER AS $$
DECLARE
    total_room_area NUMERIC; --Сумма площадей всех комнат
    total_property_area NUMERIC; --Общая площадь объекта недвижимости
    area_difference NUMERIC;
BEGIN
    SELECT COALESCE(SUM(area), 0) 
    INTO total_room_area
    FROM property_structure
    WHERE real_estate_id = NEW.real_estate_id;

    --Добавляем площадь новой комнаты из вставляемой записи
    total_room_area := total_room_area + NEW.area;
    SELECT area INTO total_property_area
    FROM real_estate
    WHERE real_estate_id = NEW.real_estate_id;
    IF total_room_area > total_property_area THEN
        area_difference := total_room_area - total_property_area;
        RAISE NOTICE 'Превышение общей площади на % м²', area_difference;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER check_area
BEFORE INSERT ON property_structure
FOR EACH ROW
EXECUTE FUNCTION check_area();