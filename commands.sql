CREATE FUNCTION app.insert_emergency_call(
    new_call_time TIMESTAMP,
    new_address VARCHAR,
    new_type_id INT,
    new_description VARCHAR,
    new_reported_by VARCHAR
)
RETURNS INT
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    new_id INT;
BEGIN
   
    IF new_call_time::date <> CURRENT_DATE THEN
        RAISE EXCEPTION 'Время вызова должно быть сегодняшним: %', CURRENT_DATE;
    END IF;

    IF new_address IS NULL OR new_address NOT LIKE '%Новосибирск%' THEN
        RAISE EXCEPTION 'Адрес должен быть в Новосибирске и не может быть пустым';
    END IF;

    IF NOT EXISTS (SELECT 1 FROM ref.IncidentType WHERE id = new_type_id) THEN
        RAISE EXCEPTION 'Тип инцидента с id=% не существует', new_type_id;
    END IF;

    IF new_reported_by IS NULL OR TRIM(new_reported_by) = '' THEN
        new_reported_by := 'Неизвестный заявитель';
    END IF;
    IF new_description IS NULL OR TRIM(new_description) = '' THEN
        RAISE EXCEPTION 'Описание вызова не может быть пустым';
    END IF;
    INSERT INTO app.EmergencyCall(call_time, address, type_id, description, reported_by)
    VALUES (new_call_time, new_address, new_type_id, new_description, new_reported_by)
    RETURNING id INTO new_id;

    RETURN new_id;
END;
$$;



CREATE FUNCTION app.update_equipment(
    new_id INT,
    new_name VARCHAR,
    new_type VARCHAR,
    new_status VARCHAR,
    new_last_maintenance DATE,
    new_fire_station_id INT
)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
 
    IF NOT EXISTS (SELECT 1 FROM app.Equipment WHERE id = new_id) THEN
        RAISE EXCEPTION 'Оборудование с id=% не существует', new_id;
    END IF;
    IF new_name IS NULL OR TRIM(new_name) = '' THEN
        RAISE EXCEPTION 'Название оборудования не может быть пустым';
    END IF;

    IF new_type IS NULL OR TRIM(new_type) = '' THEN
        RAISE EXCEPTION 'Тип оборудования не может быть пустым';
    END IF;

    IF new_status NOT IN ('Используется', 'Не используется') THEN
        RAISE EXCEPTION 'Статус оборудования должен быть "Используется" или "Не используется"';
    END IF;

    IF new_last_maintenance IS NOT NULL AND new_last_maintenance > CURRENT_DATE THEN
        RAISE EXCEPTION 'Дата последнего обслуживания не может быть в будущем';
    END IF;

    IF NOT EXISTS (SELECT 1 FROM app.FireStation WHERE id = new_fire_station_id) THEN
        RAISE EXCEPTION 'Станция с id=% не существует', new_fire_station_id;
    END IF;
    UPDATE app.Equipment
    SET name = new_name,
        type = new_type,
        status = new_status,
        last_maintenance = new_last_maintenance,
        fire_station_id = new_fire_station_id
    WHERE id = new_id;
END;
$$;

GRANT USAGE ON SCHEMA app TO PUBLIC; --только чтобы видеть 


GRANT EXECUTE ON FUNCTION app.insert_emergency_call(
    TIMESTAMP, VARCHAR, INT, VARCHAR, VARCHAR
) TO PUBLIC;

GRANT EXECUTE ON FUNCTION app.update_equipment(
    INT, VARCHAR, VARCHAR, VARCHAR, DATE, INT
) TO PUBLIC;



SELECT app.insert_emergency_call(
    CURRENT_TIMESTAMP::timestamp,
    'г. Новосибирск, ул. Тестовая, 10'::varchar,
    1::int,
    'Проверка вставки 1'::varchar,
    'Tester1'::varchar
) AS new_id;

SELECT app.insert_emergency_call(
    CURRENT_TIMESTAMP::timestamp,
    'г. Новосибирск, ул. Тестовая, 11'::varchar,
    1::int,
    'Проверка вставки 2'::varchar,
    NULL::varchar    
) AS new_id;

SELECT app.insert_emergency_call(
    CURRENT_TIMESTAMP::timestamp,
    'г. Москва, ул. Тестовая, 1'::varchar,
    1::int,
    'Неверный адрес'::varchar,
    'Tester2'::varchar
);

SELECT app.insert_emergency_call(
    (CURRENT_TIMESTAMP - INTERVAL '1 day')::timestamp,
    'г. Новосибирск, ул. Тестовая, 12'::varchar,
    1::int,
    'Неверная дата'::varchar,
    'Tester3'::varchar
);


SELECT app.update_equipment(
    1::int,
    'Оборудование Тестовое 1'::varchar,
    'Тип A'::varchar,
    'Используется'::varchar,
    CURRENT_DATE::date,
    1::int
);

SELECT app.update_equipment(
    1::int,
    'Оборудование Тестовое 2'::varchar,
    'Тип B'::varchar,
    'Не используется'::varchar,
    NULL::date,  
    1::int
);

SELECT app.update_equipment(
    1::int,
    'Оборудование Тестовое 3'::varchar,
    'Тип C'::varchar,
    'В ремонте'::varchar,  
    CURRENT_DATE::date,
    1::int
);

SELECT app.update_equipment(
    999::int, 
    'Оборудование Тестовое 4'::varchar,
    'Тип D'::varchar,
    'Используется'::varchar,
    CURRENT_DATE::date,
    1::int
);


ALTER TABLE app.EmergencyCall
ADD CONSTRAINT check_call_time_not_future
CHECK (call_time <= CURRENT_TIMESTAMP);


ALTER TABLE app.EmergencyCall
DROP CONSTRAINT check_call_time_not_future;
ALTER TABLE

CREATE FUNCTION app.callTime_notFuture()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
    IF NEW.call_time > CURRENT_TIMESTAMP THEN
        RAISE EXCEPTION 'Дата вызова не может быть в будущем: %', NEW.call_time;
    END IF;
    RETURN NEW;
END;
$$;

CREATE TRIGGER callTime_notFuture
BEFORE INSERT OR UPDATE ON app.EmergencyCall
FOR EACH ROW
EXECUTE FUNCTION app.callTime_notFuture();


CREATE TABLE audit.function_calls (
    id SERIAL PRIMARY KEY,
    call_time TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    function_name VARCHAR NOT NULL,
    caller_role VARCHAR NOT NULL,
    input_params JSON NOT NULL,
    success BOOLEAN NOT NULL
);










CREATE OR REPLACE FUNCTION app.insert_emergency_call(
    new_call_time TIMESTAMP,
    new_address VARCHAR,
    new_type_id INT,
    new_description VARCHAR,
    new_reported_by VARCHAR
)
RETURNS TEXT
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    new_id INT;
    error_code INT := 0;
    error_text TEXT := NULL;
BEGIN
    IF new_call_time::date <> CURRENT_DATE THEN
        error_code := 1;
        error_text := format('Время вызова должно быть сегодняшним: %s', CURRENT_DATE);
    END IF;

    IF (error_code = 0) AND (new_address IS NULL OR new_address NOT LIKE '%Новосибирск%') THEN
        error_code := 2;
        error_text := 'Адрес должен быть в Новосибирске и не может быть пустым';
    END IF;

    IF (error_code = 0) AND NOT EXISTS (SELECT 1 FROM ref.IncidentType WHERE id = new_type_id) THEN
        error_code := 3;
        error_text := format('Тип инцидента с id=%s не существует', new_type_id);
    END IF;

    IF (error_code = 0) AND (new_reported_by IS NULL OR TRIM(new_reported_by) = '') THEN
        new_reported_by := 'Неизвестный заявитель';
    END IF;

    IF (error_code = 0) AND (new_description IS NULL OR TRIM(new_description) = '') THEN
        error_code := 5;
        error_text := 'Описание вызова не может быть пустым';
    END IF;

    IF error_code = 0 THEN
        INSERT INTO app.EmergencyCall(call_time, address, type_id, description, reported_by)
        VALUES (new_call_time, new_address, new_type_id, new_description, new_reported_by)
        RETURNING id INTO new_id;
    END IF;

    INSERT INTO audit.function_calls(function_name, caller_role, input_params, success)
    VALUES (
        'insert_emergency_call',
        current_role,
        json_build_object(
            'new_call_time', new_call_time,
            'new_address', new_address,
            'new_type_id', new_type_id,
            'new_description', new_description,
            'new_reported_by', new_reported_by,
            'error_code', error_code,
            'error_text', error_text
        ),
        (error_code = 0)
    );

    IF error_code = 0 THEN
    RETURN 'OK';
    ELSE
        RETURN error_text;
    END IF;
END;
$$;




CREATE OR REPLACE FUNCTION app.update_equipment(
    new_id INT,
    new_name VARCHAR,
    new_type VARCHAR,
    new_status VARCHAR,
    new_last_maintenance DATE,
    new_fire_station_id INT
)
RETURNS TEXT
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    error_code INT := 0;
    error_text TEXT := NULL;
BEGIN
    IF NOT EXISTS (SELECT 1 FROM app.Equipment WHERE id = new_id) THEN
        error_code := 1;
        error_text := format('Оборудование с id=%s не существует', new_id);
    END IF;

    IF error_code = 0 AND (new_name IS NULL OR TRIM(new_name) = '') THEN
        error_code := 2;
        error_text := 'Название оборудования не может быть пустым';
    END IF;

    IF error_code = 0 AND (new_type IS NULL OR TRIM(new_type) = '') THEN
        error_code := 3;
        error_text := 'Тип оборудования не может быть пустым';
    END IF;

    IF error_code = 0 AND new_status NOT IN ('Используется', 'Не используется') THEN
        error_code := 4;
        error_text := 'Статус оборудования должен быть "Используется" или "Не используется"';
    END IF;

    IF error_code = 0 AND new_last_maintenance IS NOT NULL AND new_last_maintenance > CURRENT_DATE THEN
        error_code := 5;
        error_text := 'Дата последнего обслуживания не может быть в будущем';
    END IF;

    IF error_code = 0 AND NOT EXISTS (SELECT 1 FROM app.FireStation WHERE id = new_fire_station_id) THEN
        error_code := 6;
        error_text := format('Станция с id=%s не существует', new_fire_station_id);
    END IF;

    IF error_code = 0 THEN
        UPDATE app.Equipment
        SET name = new_name,
            type = new_type,
            status = new_status,
            last_maintenance = new_last_maintenance,
            fire_station_id = new_fire_station_id
        WHERE id = new_id;
    END IF;

    INSERT INTO audit.function_calls(function_name, caller_role, input_params, success)
    VALUES (
        'update_equipment',
        current_role,
        json_build_object(
            'new_id', new_id,
            'new_name', new_name,
            'new_type', new_type,
            'new_status', new_status,
            'new_last_maintenance', new_last_maintenance,
            'new_fire_station_id', new_fire_station_id,
            'error_code', error_code,
            'error_text', error_text
        ),
        (error_code = 0)
    );

    IF error_code = 0 THEN
    RETURN 'OK';
    ELSE
        RETURN error_text;
    END IF;

END;
$$;
