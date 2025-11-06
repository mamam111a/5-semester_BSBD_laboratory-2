\timing

INSERT INTO app.EmergencyCall(call_time, address, type_id, description, reported_by)
SELECT CURRENT_TIMESTAMP, 'г. Новосибирск, ул. Тестовая', 1, 'Тест CHECK', 'Tester'
FROM generate_series(1, 10000);


