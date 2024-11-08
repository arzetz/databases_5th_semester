PGDMP  *                
    |            work_day    16.2    16.2     �           0    0    ENCODING    ENCODING        SET client_encoding = 'UTF8';
                      false            �           0    0 
   STDSTRINGS 
   STDSTRINGS     (   SET standard_conforming_strings = 'on';
                      false            �           0    0 
   SEARCHPATH 
   SEARCHPATH     8   SELECT pg_catalog.set_config('search_path', '', false);
                      false            �           1262    17142    work_day    DATABASE     |   CREATE DATABASE work_day WITH TEMPLATE = template0 ENCODING = 'UTF8' LOCALE_PROVIDER = libc LOCALE = 'Russian_Russia.1251';
    DROP DATABASE work_day;
                postgres    false            �            1255    17163 
   worktime()    FUNCTION     �  CREATE FUNCTION public.worktime() RETURNS TABLE(emp_id integer, total_worktime text)
    LANGUAGE plpgsql
    AS $$
DECLARE
    total_worktime_interval INTERVAL;
    last_entry TIMESTAMP;
    current_employee_id INT; -- Переменная для хранения текущего ID сотрудника
record RECORD;
BEGIN
    -- Цикл по всем уникальным сотрудникам
    FOR current_employee_id IN 
        SELECT DISTINCT wd.employee_id
        FROM workday wd
    LOOP
        -- Сбрасываем переменные для каждого сотрудника
        total_worktime_interval := '0 hours';
        last_entry := NULL;

        -- Внутренний цикл по записям для конкретного сотрудника
        FOR record IN 
            SELECT wd.schedule, wd.employee_status
            FROM workday wd
            WHERE wd.employee_id = current_employee_id
            ORDER BY wd.schedule
        LOOP
            -- Проверяем статус события (1 - вход, 2 - выход)
            IF record.employee_status = 1 THEN
                last_entry := record.schedule;

            ELSIF record.employee_status = 2 AND last_entry IS NOT NULL THEN
                -- Добавляем разницу между временем входа и выхода к общему времени
                total_worktime_interval := total_worktime_interval + (record.schedule - last_entry);
                last_entry := NULL; -- Сброс для следующего входа
            END IF;
        END LOOP;

        -- Формируем итоговое сообщение для текущего сотрудника
        IF total_worktime_interval < INTERVAL '40 hours' THEN
            RETURN QUERY SELECT current_employee_id, total_worktime_interval::TEXT || ' (Меньше нормы)';
        ELSIF total_worktime_interval = INTERVAL '40 hours' THEN
            RETURN QUERY SELECT current_employee_id, total_worktime_interval::TEXT || ' (Норма)';
        ELSE
            RETURN QUERY SELECT current_employee_id, total_worktime_interval::TEXT || ' (Больше нормы)';
        END IF;
    END LOOP;
END;
$$;
 !   DROP FUNCTION public.worktime();
       public          postgres    false            �            1259    17150    workday    TABLE     �   CREATE TABLE public.workday (
    employee_id integer,
    schedule timestamp without time zone,
    employee_status integer
);
    DROP TABLE public.workday;
       public         heap    postgres    false            �          0    17150    workday 
   TABLE DATA           I   COPY public.workday (employee_id, schedule, employee_status) FROM stdin;
    public          postgres    false    215   �       �     x�u�ˑ!DϞ(��n�6��c�Ѫ�֥橅`⇐�S?O�F�y��NѡP4�)��]#�B��|רWʭ,5,C��:A&�����ʗ@5g\3�3u�k?�`���u�rc�Bl�v�N��N5[W�iW�-׎�jc�5���e`n��El]�Í�[����vv�f*�u�jz���7q�S���e��4������(S���ͭB�(]7ku+!�=�-�-��Qn��y���%�,�s����)��4��SV�2�qg+x���?��q���      