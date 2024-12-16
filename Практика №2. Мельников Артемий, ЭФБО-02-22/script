Script

create table workday(
	employee_id integer,
	schedule timestamp,
	employee_status integer
);

insert into workday (employee_id, schedule, employee_status)
values 
(101,' 2023-10-14 09:10:00', 1),
(102,' 2023-10-14 08:57:00', 1),
(103,' 2023-10-14 09:15:00', 1),
(101,' 2023-10-14 13:05:00', 2),
(102,' 2023-10-14 13:15:00', 2),
(103,' 2023-10-14 13:15:00', 2),
(101,' 2023-10-14 13:50:00', 1),
(102,' 2023-10-14 13:50:00', 1),
(103,' 2023-10-14 13:50:00', 1),
(101,' 2023-10-14 18:40:00', 2),
(102,' 2023-10-14 18:10:00', 2),
(103,' 2023-10-14 18:05:00', 2)

select * from workday

update workday
set employee_status = 1 where schedule = ' 2023-10-10 13:50:00'

CREATE OR REPLACE FUNCTION worktime()
RETURNS TABLE(emp_id INT, total_worktime TEXT) AS $$
DECLARE
    total_worktime_interval INTERVAL;
    last_entry TIMESTAMP;
    current_employee_id INT;
record RECORD;
BEGIN
    FOR current_employee_id IN  -- цикл по уникальным сотрудникам
        SELECT DISTINCT wd.employee_id
        FROM workday wd
    LOOP
        total_worktime_interval := '0 hours'; -- сброс для каждого сотрудника
        last_entry := NULL; -- сброс для каждого сотрудника
        FOR record IN -- внутренний цикл по записям для конкретного сотрудника
            SELECT wd.schedule, wd.employee_status
            FROM workday wd
            WHERE wd.employee_id = current_employee_id
            ORDER BY wd.schedule
        LOOP
            IF record.employee_status = 1 THEN --проверяем статус 1 вход, 2 выход
                last_entry := record.schedule;
            ELSIF record.employee_status = 2 AND last_entry IS NOT NULL THEN
                total_worktime_interval := total_worktime_interval + (record.schedule - last_entry);
                last_entry := NULL; -- сброс
            END IF;
        END LOOP;

        IF total_worktime_interval < INTERVAL '40 hours' THEN
            RETURN QUERY SELECT current_employee_id, total_worktime_interval::TEXT || ' (Меньше нормы)';
        ELSIF total_worktime_interval = INTERVAL '40 hours' THEN
            RETURN QUERY SELECT current_employee_id, total_worktime_interval::TEXT || ' (Норма)';
        ELSE
            RETURN QUERY SELECT current_employee_id, total_worktime_interval::TEXT || ' (Больше нормы)';
        END IF;
    END LOOP;
END;
$$ LANGUAGE plpgsql;


CREATE OR REPLACE FUNCTION calculate_salary()
RETURNS TABLE(emp_id INT, salary TEXT) AS $$
DECLARE
    base_salary INT := 50000;  -- Базовый оклад
    total_delay_minutes INT;
    delay_factor NUMERIC := 1;  -- Коэффициент A
    last_entry TIMESTAMP;
    total_worktime INTERVAL;
	inner_record RECORD;
    record RECORD;
BEGIN
    FOR record IN
        SELECT DISTINCT wd.employee_id
        FROM workday wd
    LOOP
        total_delay_minutes := 0;
        last_entry := NULL;
        
        FOR inner_record IN
            SELECT wd.schedule, wd.employee_status
            FROM workday wd
            WHERE wd.employee_id = record.employee_id
            ORDER BY wd.schedule
        LOOP
            IF inner_record.employee_status = 1 THEN  -- Время входа
                last_entry := inner_record.schedule;
            ELSIF inner_record.employee_status = 2 AND last_entry IS NOT NULL THEN  -- Время выхода
                total_worktime := inner_record.schedule - last_entry;
                IF inner_record.schedule > last_entry THEN
                    total_delay_minutes := total_delay_minutes + EXTRACT(MINUTE FROM total_worktime);
                END IF;
                last_entry := NULL;
            END IF;
        END LOOP;
        delay_factor := 1 - (total_delay_minutes / 10 * 0.05);  -- Уменьшаем A на 0.05 за каждые 10 минут опоздания
        IF delay_factor < 0 THEN
            delay_factor := 0;
        END IF;

        RETURN QUERY
        SELECT record.employee_id, 
            (base_salary + base_salary * delay_factor);
    END LOOP;
END;
$$ LANGUAGE plpgsql;

SELECT * FROM calculate_salary();

select * from worktime();

DROP FUNCTION worktime()
