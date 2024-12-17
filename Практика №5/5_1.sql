CREATE TABLE sports (
    sport_id SERIAL PRIMARY KEY,
    name VARCHAR(40) NOT NULL,
    type VARCHAR(10) CHECK (type IN ('Индивидуальный', 'Парный')) NOT NULL
);
CREATE TABLE coaches (
    coach_id SERIAL PRIMARY KEY,
    full_name VARCHAR(100) NOT NULL,
    sport_id INT REFERENCES sports(sport_id),
    skill_level VARCHAR(10) NOT NULL,
    current_rating INT CHECK (current_rating >= 0) DEFAULT 0
);
CREATE TABLE athletes (
    athlete_id INT PRIMARY KEY,
    full_name VARCHAR(40) NOT NULL,
    birth_date DATE NOT NULL,
    gender CHAR(1) CHECK (gender IN ('М', 'Ж')) NOT NULL,
    skill_level VARCHAR(10),
    current_coach_id INT REFERENCES coaches(coach_id),
    training_start_date DATE NOT NULL,
    current_rating INT DEFAULT 0 CHECK (current_rating >= 0),
    partner_id INT REFERENCES athletes(athlete_id),
    address VARCHAR(40) NOT NULL,
    mobile_phone VARCHAR(11),
    home_phone VARCHAR(11)
);
CREATE TABLE previous_coaches (
    record_id SERIAL PRIMARY KEY,
    coach_id INT REFERENCES coaches(coach_id),
    athlete_id INT REFERENCES athletes(athlete_id),
    training_start_date DATE NOT NULL
);

--Задание 2
--1
SELECT a.full_name AS athlete, c.full_name AS coach, s.name AS sport
FROM athletes a
JOIN coaches c ON a.current_coach_id = c.coach_id
JOIN sports s ON c.sport_id = s.sport_id
ORDER BY a.full_name;
--2
SELECT a.full_name AS athlete, c.full_name AS coach
FROM athletes a
JOIN coaches c ON a.current_coach_id = c.coach_id
WHERE a.athlete_id NOT IN (SELECT athlete_id FROM previous_coaches);
--3
SELECT DISTINCT a.full_name, s.name AS sport
FROM athletes a
JOIN previous_coaches pc ON a.athlete_id = pc.athlete_id
JOIN coaches c ON pc.coach_id = c.coach_id
JOIN sports s ON c.sport_id = s.sport_id;
--4
SELECT c.full_name AS coach, 
       ROUND((COUNT(CASE WHEN a.skill_level IN ('КМС', 'МС') THEN 1 END)::NUMERIC /
       COUNT(a.athlete_id))::NUMERIC, 2) AS coach_rating
FROM coaches c
LEFT JOIN athletes a ON c.coach_id = a.current_coach_id
GROUP BY c.full_name
ORDER BY coach_rating DESC;
--5
SELECT s.name AS sport, COUNT(a.athlete_id) AS athlete_count
FROM sports s
LEFT JOIN coaches c ON s.sport_id = c.sport_id
LEFT JOIN athletes a ON c.coach_id = a.current_coach_id
GROUP BY s.name;

--Задание 3
--1
CREATE VIEW athlete_transitions AS
SELECT a.full_name AS athlete, c.full_name AS coach, s.name AS sport,
       pc.training_start_date AS start_date, 
       COALESCE(NULLIF(a.training_start_date, pc.training_start_date), 'по настоящее время') AS end_date
FROM athletes a
JOIN previous_coaches pc ON a.athlete_id = pc.athlete_id
JOIN coaches c ON pc.coach_id = c.coach_id
JOIN sports s ON c.sport_id = s.sport_id;
--2
CREATE VIEW pair_sport_errors AS
SELECT a.athlete_id, a.full_name, a.partner_id, s.name AS sport
FROM athletes a
JOIN coaches c ON a.current_coach_id = c.coach_id
JOIN sports s ON c.sport_id = s.sport_id
WHERE s.type = 'Парный' AND 
      (a.partner_id IS NULL OR NOT EXISTS (
          SELECT 1 FROM athletes p WHERE p.athlete_id = a.partner_id AND p.partner_id = a.athlete_id
      ));
--3
CREATE VIEW athletes_without_contacts AS
SELECT athlete_id, full_name, address
FROM athletes
WHERE mobile_phone IS NULL AND home_phone IS NULL;


INSERT INTO sports (name, type) VALUES
('Теннис', 'Парный'),
('Бокс', 'Индивидуальный'),
('Шахматы', 'Индивидуальный'),
('Бадминтон', 'Парный'),
('Фехтование', 'Индивидуальный');

INSERT INTO coaches (full_name, sport_id, skill_level, current_rating) VALUES
('Иванов Петр Сергеевич', 1, 'МС', 95),
('Сидоров Алексей Иванович', 2, 'КМС', 80),
('Кузнецов Дмитрий Владимирович', 3, 'МС', 88),
('Петрова Елена Николаевна', 4, 'МСМК', 90),
('Федоров Василий Сергеевич', 5, 'КМС', 70);

INSERT INTO athletes (athlete_id, full_name, birth_date, gender, skill_level, 
                      current_coach_id, training_start_date, current_rating, 
                      partner_id, address, mobile_phone, home_phone)
VALUES
(100001, 'Смирнов Александр Игоревич', '2000-05-10', 'М', 'КМС', 1, '2020-01-15', 85, 100002, 'ул. Ленина 12', '89012345678', NULL),
(100002, 'Козлова Анна Сергеевна', '2002-03-22', 'Ж', 'МС', 1, '2019-11-10', 92, 100001, 'ул. Гагарина 8', NULL, '1234567'),
(100003, 'Иванов Сергей Петрович', '1998-07-15', 'М', '2 разряд', 2, '2018-02-20', 70, NULL, 'ул. Советская 3', '89098765432', NULL),
(100004, 'Васильева Мария Павловна', '2001-10-05', 'Ж', 'МС', 3, '2017-06-25', 88, NULL, 'ул. Победы 5', NULL, NULL),
(100005, 'Сидоров Виктор Дмитриевич', '1999-12-12', 'М', '1 разряд', 4, '2019-09-15', 76, 100006, 'ул. Калинина 7', '89123456789', NULL),
(100006, 'Соколова Ирина Александровна', '2000-04-18', 'Ж', '2 разряд', 4, '2019-09-15', 70, 100005, 'ул. Мира 14', NULL, '8765432');

INSERT INTO previous_coaches (coach_id, athlete_id, training_start_date) VALUES
(2, 100001, '2018-01-01'),
(3, 100002, '2018-06-01'),
(4, 100003, '2017-09-01'),
(1, 100004, '2019-01-01'),
(5, 100005, '2020-03-01');


UPDATE athletes_without_contacts
SET mobile_phone = '12345678901'
WHERE athlete_id = 1;
