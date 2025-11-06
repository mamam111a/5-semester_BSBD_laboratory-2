
-- ==============================================
-- 1️⃣ SELECT таблиц
-- ==============================================
SET ROLE app_reader;
DO $$
BEGIN
    RAISE NOTICE '== TEST 1a: app_reader SELECT app.Equipment (позитив) ==';
    BEGIN
        PERFORM * FROM app.Equipment LIMIT 1;
        RAISE NOTICE '✅ OK (ожидаемо)';
    EXCEPTION WHEN insufficient_privilege THEN
        RAISE NOTICE '❌ нет прав';
    END;

    RAISE NOTICE '== TEST 1b: app_reader SELECT ref.IncidentType (позитив) ==';
    BEGIN
        PERFORM * FROM ref.IncidentType LIMIT 1;
        RAISE NOTICE '✅ OK (ожидаемо)';
    EXCEPTION WHEN insufficient_privilege THEN
        RAISE NOTICE '❌ нет прав';
    END;
END $$;
RESET ROLE;

SET ROLE auditor;
DO $$
BEGIN
    RAISE NOTICE '== TEST 1c: auditor SELECT app.Equipment (негатив) ==';
    BEGIN
        PERFORM * FROM app.Equipment LIMIT 1;
        RAISE NOTICE '✅ OK';
    EXCEPTION WHEN insufficient_privilege THEN
        RAISE NOTICE '❌ нет прав (ожидаемо)';
    END;

    RAISE NOTICE '== TEST 1d: auditor SELECT ref.IncidentType (негатив) ==';
    BEGIN
        PERFORM * FROM ref.IncidentType LIMIT 1;
        RAISE NOTICE '✅ OK';
    EXCEPTION WHEN insufficient_privilege THEN
        RAISE NOTICE '❌ нет прав (ожидаемо)';
    END;
END $$;
RESET ROLE;

-- ==============================================
-- 2️⃣ DML на запрещённых ролях
-- ==============================================
SET ROLE app_reader;
DO $$
BEGIN
    RAISE NOTICE '== TEST 2a: app_reader DML (негатив) ==';

    BEGIN
        INSERT INTO app.Equipment(name,type,status,last_maintenance,fire_station_id)
        VALUES('Test','Type','Используется',CURRENT_DATE,1);
        RAISE NOTICE '✅ INSERT';
    EXCEPTION WHEN insufficient_privilege THEN
        RAISE NOTICE '❌ INSERT нет прав (ожидаемо)';
    END;

    BEGIN
        UPDATE app.Equipment SET name='Updated' WHERE id=1;
        RAISE NOTICE '✅ UPDATE';
    EXCEPTION WHEN insufficient_privilege THEN
        RAISE NOTICE '❌ UPDATE нет прав (ожидаемо)';
    END;

    BEGIN
        DELETE FROM app.Equipment WHERE id=1;
        RAISE NOTICE '✅ DELETE';
    EXCEPTION WHEN insufficient_privilege THEN
        RAISE NOTICE '❌ DELETE нет прав (ожидаемо)';
    END;
END $$;
RESET ROLE;

SET ROLE app_writer;
DO $$
BEGIN
    RAISE NOTICE '== TEST 2b: app_writer DML (позитив) ==';
    BEGIN
        INSERT INTO app.Equipment(name,type,status,last_maintenance,fire_station_id)
        VALUES('Test','Type','Используется',CURRENT_DATE,1);
        RAISE NOTICE '✅ INSERT OK (ожидаемо)';
    EXCEPTION WHEN insufficient_privilege THEN
        RAISE NOTICE '❌ ошибка';
    END;

    BEGIN
        UPDATE app.Equipment SET name='Updated' WHERE id=1;
        RAISE NOTICE '✅ UPDATE OK (ожидаемо)';
    EXCEPTION WHEN insufficient_privilege THEN
        RAISE NOTICE '❌ ошибка';
    END;
END $$;
RESET ROLE;

-- ==============================================
-- 3️⃣ DDL
-- ==============================================
SET ROLE app_writer;
DO $$
BEGIN
    RAISE NOTICE '== TEST 3a: app_writer CREATE TABLE (негатив) ==';
    BEGIN
        EXECUTE 'CREATE TABLE app.TestDDL(id INT)';
        RAISE NOTICE '✅ CREATE TABLE';
    EXCEPTION WHEN insufficient_privilege THEN
        RAISE NOTICE '❌ нет прав (ожидаемо)';
    END;
END $$;
RESET ROLE;

SET ROLE ddl_admin;
DO $$
BEGIN
    RAISE NOTICE '== TEST 3b: ddl_admin CREATE TABLE (позитив) ==';
    BEGIN
        EXECUTE 'CREATE TABLE IF NOT EXISTS app.TestDDL(id INT)';
        RAISE NOTICE '✅ OK (ожидаемо)';
    EXCEPTION WHEN insufficient_privilege THEN
        RAISE NOTICE '❌ ошибка';
    END;
END $$;
RESET ROLE;

-- ==============================================
-- 4️⃣ DML в audit
-- ==============================================
SET ROLE app_writer;
DO $$
BEGIN
    RAISE NOTICE '== TEST 4a: app_writer INSERT audit (негатив) ==';
    BEGIN
        INSERT INTO audit.EventLog(actor_id,target_table,target_id,action,details)
        VALUES(1,'app.Equipment',1,'INSERT','Test');
        RAISE NOTICE '✅ INSERT OK';
    EXCEPTION WHEN insufficient_privilege THEN
        RAISE NOTICE '❌ нет прав (ожидаемо)';
    END;
END $$;
RESET ROLE;

SET ROLE auditor;
DO $$
BEGIN
    RAISE NOTICE '== TEST 4b: auditor SELECT audit.EventLog (позитив) ==';
    BEGIN
        PERFORM * FROM audit.EventLog LIMIT 1;
        RAISE NOTICE '✅ SELECT OK (ожидаемо)';
    EXCEPTION WHEN insufficient_privilege THEN
        RAISE NOTICE '❌ ошибка';
    END;
END $$;
RESET ROLE;

