--Задание 1
CREATE TABLE schedule (
    realtor_id INT,             
    deal_date DATE,    
    start_time TIME,       
    end_time TIME,           
);

CREATE OR REPLACE FUNCTION validate_schedule()
RETURNS TRIGGER AS $$
DECLARE
    deal_count INT;    --Количество сделок на указанную дату
    overlap_count INT; --Количество накладок во времени
    weekday INT;       --День недели (1 = Понедельник, ..., 7 = Воскресенье)
BEGIN
    --Проверка на количество сделок
    SELECT COUNT(*)
    INTO deal_count
    FROM schedule
    WHERE realtor_id = NEW.realtor_id
      AND deal_date = NEW.deal_date;

    IF deal_count >= 3 THEN
        RAISE EXCEPTION 'Превышено количество сделок на дату % для риэлтора %', NEW.deal_date, NEW.realtor_id;
    END IF;

    --Проверка на окно между сделками
    SELECT COUNT(*)
    INTO overlap_count
    FROM schedule
    WHERE realtor_id = NEW.realtor_id
      AND deal_date = NEW.deal_date
      AND (
            (NEW.start_time BETWEEN start_time AND end_time + INTERVAL '1 hour') OR
            (NEW.end_time BETWEEN start_time - INTERVAL '1 hour' AND end_time)
          );

    IF overlap_count > 0 THEN
        RAISE EXCEPTION 'Временное окно между сделками не менее 1 часа';
    END IF;

    --Проверка на отсутствие накладок
    SELECT COUNT(*)
    INTO overlap_count
    FROM schedule
    WHERE realtor_id = NEW.realtor_id
      AND deal_date = NEW.deal_date
      AND (
            (NEW.start_time >= start_time AND NEW.start_time < end_time) OR
            (NEW.end_time > start_time AND NEW.end_time <= end_time) OR
            (NEW.start_time <= start_time AND NEW.end_time >= end_time)
          );

    IF overlap_count > 0 THEN
        RAISE EXCEPTION 'Обнаружено пересечение сделок';
    END IF;

    --Проверка на день недели
    SELECT EXTRACT(ISODOW FROM NEW.deal_date)::INT INTO weekday;

    IF weekday = 7 THEN
        RAISE EXCEPTION 'Сделки могут назначаться только с понедельника по субботу';
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER before_insert_schedule
BEFORE INSERT ON schedule
FOR EACH ROW
EXECUTE FUNCTION validate_schedule();

--Задание 2
CREATE TABLE price_history (
    change_date TIMESTAMP DEFAULT now(),
    real_estate_id INT,       
    new_price NUMERIC,           
    PRIMARY KEY (change_date, real_estate_id)
);

CREATE OR REPLACE FUNCTION log_price_changes()
RETURNS TRIGGER AS $$
BEGIN
    IF TG_OP = 'INSERT' THEN
        INSERT INTO price_history (change_date, real_estate_id, new_price)
        VALUES (now(), NEW.real_estate_id, NEW.price);

    ELSIF TG_OP = 'UPDATE' AND NEW.price IS DISTINCT FROM OLD.price THEN
        INSERT INTO price_history (change_date, real_estate_id, new_price)
        VALUES (now(), NEW.real_estate_id, NEW.price);
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER log_price_changes
AFTER INSERT OR UPDATE ON real_estate
FOR EACH ROW
EXECUTE FUNCTION log_price_changes();

