--Задание 1
--1
CREATE OR REPLACE FUNCTION get_athlete_category(birth_date DATE)
RETURNS VARCHAR AS $$
DECLARE
    age INT;
BEGIN
    age := EXTRACT(YEAR FROM AGE(CURRENT_DATE, birth_date));

    IF age <= 9 THEN RETURN 'Д-1 Дети I';
    ELSIF age BETWEEN 10 AND 11 THEN RETURN 'Д-2 Дети II';
    ELSIF age BETWEEN 12 AND 13 THEN RETURN 'Ю-1 Юниоры I';
    ELSIF age BETWEEN 14 AND 15 THEN RETURN 'Ю-2 Юниоры II';
    ELSIF age BETWEEN 16 AND 18 THEN RETURN 'М Молодежь';
    ELSIF age BETWEEN 19 AND 34 THEN RETURN 'ВЗ Взрослые';
    ELSE RETURN 'С Сеньоры';
    END IF;
END;
$$ LANGUAGE plpgsql;
--2
CREATE OR REPLACE FUNCTION format_full_name(full_name TEXT)
RETURNS TEXT AS $$
DECLARE
    parts TEXT[];
BEGIN
    parts := string_to_array(full_name, ' ');

    IF array_length(parts, 1) = 3 THEN
        RETURN parts[1] || ' ' || LEFT(parts[2], 1) || '.' || LEFT(parts[3], 1) || '.';
    ELSE
        RETURN '#############';
    END IF;
END;
$$ LANGUAGE plpgsql;
--3
CREATE OR REPLACE FUNCTION format_phone_number(phone_number TEXT)
RETURNS TEXT AS $$
DECLARE
    clean_number TEXT;
BEGIN
    clean_number := regexp_replace(phone_number, '\D', '', 'g');

    IF LENGTH(clean_number) = 11 THEN
        RETURN '8-' || SUBSTR(clean_number, 2, 3) || '-' || SUBSTR(clean_number, 5, 3) ||
               '-' || SUBSTR(clean_number, 8, 2) || '-' || SUBSTR(clean_number, 10, 2);
    ELSIF LENGTH(clean_number) = 10 THEN
        RETURN '8-' || SUBSTR(clean_number, 1, 3) || '-' || SUBSTR(clean_number, 4, 3) ||
               '-' || SUBSTR(clean_number, 7, 2) || '-' || SUBSTR(clean_number, 9, 2);
    ELSIF LENGTH(clean_number) = 7 THEN
        RETURN '8-XXX-' || SUBSTR(clean_number, 1, 3) || '-' || SUBSTR(clean_number, 4, 2) || '-' || SUBSTR(clean_number, 6, 2);
    ELSE
        RETURN NULL;
    END IF;
END;
$$ LANGUAGE plpgsql;
--Задание 2
--1
CREATE OR REPLACE PROCEDURE list_athletes_and_coaches()
LANGUAGE plpgsql AS $$
BEGIN
    FOR record IN
        SELECT a.full_name AS athlete, c.full_name AS coach, a.training_start_date
        FROM athletes a
        JOIN coaches c ON a.current_coach_id = c.coach_id
    LOOP
        RAISE NOTICE '% - Тренер: % (Начало: %)', record.athlete, record.coach, record.training_start_date;
    END LOOP;
END;
$$;
--2
CREATE OR REPLACE PROCEDURE list_pair_athletes()
LANGUAGE plpgsql AS $$
BEGIN
    FOR record IN
        SELECT s.name AS sport, a1.full_name AS athlete1, a2.full_name AS athlete2, c.full_name AS coach
        FROM athletes a1
        JOIN athletes a2 ON a1.partner_id = a2.athlete_id
        JOIN coaches c ON a1.current_coach_id = c.coach_id
        JOIN sports s ON c.sport_id = s.sport_id
        WHERE s.type = 'Парный' AND a1.athlete_id < a2.athlete_id
    LOOP
        RAISE NOTICE '%: % - % (% тренер)', record.sport, record.athlete1, record.athlete2, record.coach;
    END LOOP;
END;
$$;
--3
CREATE OR REPLACE PROCEDURE calculate_coach_ratings()
LANGUAGE plpgsql AS $$
BEGIN
    UPDATE coaches c
    SET current_rating = (
        SELECT COALESCE(AVG(a.current_rating), 0)
        FROM athletes a
        WHERE a.current_coach_id = c.coach_id
          OR EXISTS (
              SELECT 1
              FROM previous_coaches pc
              WHERE pc.coach_id = c.coach_id
                AND pc.training_start_date >= CURRENT_DATE - INTERVAL '1 year'
                AND pc.athlete_id = a.athlete_id
          )
    );
END;
$$;
--Задание 3
--1
ALTER TABLE athletes
ADD CONSTRAINT fk_current_coach FOREIGN KEY (current_coach_id) REFERENCES coaches(coach_id);
--2
CREATE OR REPLACE FUNCTION log_coach_change()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.current_coach_id <> OLD.current_coach_id THEN
        INSERT INTO previous_coaches (coach_id, athlete_id, training_start_date)
        VALUES (OLD.current_coach_id, OLD.athlete_id, OLD.training_start_date);
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_log_coach_change
BEFORE UPDATE ON athletes
FOR EACH ROW EXECUTE FUNCTION log_coach_change();
--3
CREATE OR REPLACE FUNCTION increase_coach_rating()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.skill_level > OLD.skill_level THEN
        UPDATE coaches
        SET current_rating = current_rating + 20
        WHERE coach_id = NEW.current_coach_id;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_increase_coach_rating
AFTER UPDATE ON athletes
FOR EACH ROW EXECUTE FUNCTION increase_coach_rating();
--4
CREATE OR REPLACE FUNCTION validate_athlete_fields()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.current_rating < 0 THEN
        RAISE EXCEPTION 'Рейтинг спортсмена не может быть отрицательным';
    END IF;

    IF NEW.gender NOT IN ('М', 'Ж') THEN
        RAISE EXCEPTION 'Пол спортсмена должен быть М или Ж';
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_validate_athlete_fields
BEFORE INSERT OR UPDATE ON athletes
FOR EACH ROW EXECUTE FUNCTION validate_athlete_fields();
--Задание 4
BEGIN TRANSACTION ISOLATION LEVEL SERIALIZABLE;
-- Вставка данных или SELECT
COMMIT;
