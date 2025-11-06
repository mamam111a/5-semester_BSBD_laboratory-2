SET ROLE app_reader;

SELECT app.insert_emergency_call(
    CURRENT_TIMESTAMP::timestamp,
    'Новосибирск, Ленина 10'::varchar,
    1,
    'Тестовый вызов 1'::varchar,
    'Иванов'::varchar
);

SET ROLE app_writer;
SELECT app.insert_emergency_call(
    (CURRENT_TIMESTAMP - INTERVAL '1 day')::timestamp,
    'Новосибирск, Ленина 10'::varchar,
    1,
    'Тестовый вызов 2'::varchar,
    'Иванов'::varchar
);

SET ROLE app_owner;
SELECT app.insert_emergency_call(
    CURRENT_TIMESTAMP::timestamp,
    'Москва, Красная площадь'::varchar,
    1,
    'Тестовый вызов 3'::varchar,
    'Иванов'::varchar
);

SET ROLE ddl_admin;
SELECT app.insert_emergency_call(
    CURRENT_TIMESTAMP::timestamp,
    'Новосибирск, Ленина 20'::varchar,
    9999,  
    'Тестовый вызов 4'::varchar,
    'Иванов'::varchar
);

SET ROLE dml_admin;
SELECT app.insert_emergency_call(
    CURRENT_TIMESTAMP::timestamp,
    'Новосибирск, Ленина 10'::varchar,
    1,
    ''::varchar,
    ''::varchar
);



SET ROLE auditor;
SELECT app.update_equipment(
    1,
    'Новый насос 1'::varchar,
    'Насос'::varchar,
    'Используется'::varchar,
    CURRENT_DATE,
    1
);

SET ROLE postgres;
SELECT app.update_equipment(
    9999,
    'Новый насос 2'::varchar,
    'Насос'::varchar,
    'Используется'::varchar,
    CURRENT_DATE,
    1
);

SELECT app.update_equipment(
    1,
    ''::varchar,
    'Насос'::varchar,
    'Используется'::varchar,
    CURRENT_DATE,
    1
);

SELECT app.update_equipment(
    1,
    'Новый насос 3'::varchar,
    'Насос'::varchar,
    'Неизвестно'::varchar,
    CURRENT_DATE,
    1
);

SELECT app.update_equipment(
    1,
    'Новый насос 4'::varchar,
    'Насос'::varchar,
    'Используется'::varchar,
    CURRENT_DATE + 1,  
    1
);