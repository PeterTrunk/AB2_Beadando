CREATE OR REPLACE PACKAGE BODY audit_util_pkg IS
  
  PROCEDURE create_auto_id_created_trg_prc(p_table_name IN VARCHAR2) IS
    v_tab         VARCHAR2(30);
    v_cnt         NUMBER;
    v_has_created NUMBER;
    v_has_joined  NUMBER;
    v_has_id      NUMBER;
    v_has_seq     NUMBER;
    v_sql         VARCHAR2(32767);

    e_invalid_name     EXCEPTION;
    e_name_too_long    EXCEPTION;
    e_table_not_exists EXCEPTION;
    e_id_but_no_seq    EXCEPTION;
  BEGIN
    ------------------------------------------------------------------
    -- 0. Bemenet validálása
    ------------------------------------------------------------------
    IF p_table_name IS NULL
       OR TRIM(p_table_name) IS NULL
    THEN
      RAISE e_invalid_name;
    END IF;

    IF length(TRIM(p_table_name)) > 30
    THEN
      RAISE e_name_too_long;
    END IF;

    v_tab := upper(TRIM(p_table_name));

    SELECT COUNT(*) INTO v_cnt FROM user_tables WHERE table_name = v_tab;

    IF v_cnt = 0
    THEN
      RAISE e_table_not_exists;
    END IF;

    ------------------------------------------------------------------
    -- 1. Oszlopok vizsgálata: CREATED_AT, JOINED_AT, ID
    ------------------------------------------------------------------
    SELECT COUNT(*)
      INTO v_has_created
      FROM user_tab_cols
     WHERE table_name = v_tab
       AND column_name = 'CREATED_AT';

    SELECT COUNT(*)
      INTO v_has_joined
      FROM user_tab_cols
     WHERE table_name = v_tab
       AND column_name = 'JOINED_AT';

    SELECT COUNT(*)
      INTO v_has_id
      FROM user_tab_cols
     WHERE table_name = v_tab
       AND column_name = 'ID';

    -- Ha van ID oszlop, legyen hozzá <TABLE>_SEQ sequence is
    IF v_has_id > 0
    THEN
      SELECT COUNT(*)
        INTO v_has_seq
        FROM user_sequences
       WHERE sequence_name = v_tab || '_SEQ';
    
      IF v_has_seq = 0
      THEN
        RAISE e_id_but_no_seq;
      END IF;
    END IF;

    ------------------------------------------------------------------
    -- 2. Ha sem CREATED_AT, sem ID, sem (PROJECT_MEMBER JOINED_AT), nem csinálunk semmit
    ------------------------------------------------------------------
    IF v_has_created = 0
       AND v_has_id = 0
       AND NOT (v_tab = 'PROJECT_MEMBER' AND v_has_joined > 0)
    THEN
      RETURN;
    END IF;

    ------------------------------------------------------------------
    -- 3. Trigger szöveg generálása
    ------------------------------------------------------------------
    v_sql := 'CREATE OR REPLACE TRIGGER ' || v_tab || '_BI_AUTO ' ||
             'BEFORE INSERT ON ' || v_tab || ' ' || 'FOR EACH ROW ' ||
             'BEGIN ';

    -- CREATED_AT töltése, ha van ilyen oszlop
    IF v_has_created > 0
    THEN
      v_sql := v_sql || 'IF :NEW.created_at IS NULL THEN ' ||
               '  :NEW.created_at := SYSDATE; ' || 'END IF; ';
    END IF;

    -- PROJECT_MEMBER esetén a JOINED_AT-et is töltsük
    IF v_tab = 'PROJECT_MEMBER'
       AND v_has_joined > 0
    THEN
      v_sql := v_sql || 'IF :NEW.joined_at IS NULL THEN ' ||
               '  :NEW.joined_at := SYSDATE; ' || 'END IF; ';
    END IF;

    -- ID töltése, ha van ID oszlop + létezik <TABLE>_SEQ
    IF v_has_id > 0
    THEN
      v_sql := v_sql || 'IF :NEW.id IS NULL THEN ' || '  SELECT ' || v_tab ||
               '_SEQ.NEXTVAL INTO :NEW.id FROM dual; ' || 'END IF; ';
    END IF;

    v_sql := v_sql || 'END;';

    ------------------------------------------------------------------
    -- 4. Trigger létrehozása
    ------------------------------------------------------------------
    EXECUTE IMMEDIATE v_sql;

  EXCEPTION
    WHEN e_invalid_name THEN
      raise_application_error(-20100,
                              'create_auto_id_created_trg_prc: table name must not be NULL or empty.');
    
    WHEN e_name_too_long THEN
      raise_application_error(-20101,
                              'create_auto_id_created_trg_prc: table name "' ||
                              TRIM(p_table_name) ||
                              '" is longer than 30 characters.');
    
    WHEN e_table_not_exists THEN
      raise_application_error(-20102,
                              'create_auto_id_created_trg_prc: table "' ||
                              v_tab || '" does not exist in current schema.');
    
    WHEN e_id_but_no_seq THEN
      raise_application_error(-20103,
                              'create_auto_id_created_trg_prc: table "' ||
                              v_tab || '" has ID column but no sequence "' ||
                              v_tab || '_SEQ".');
    
    WHEN OTHERS THEN
      raise_application_error(-20199,
                              'create_auto_id_created_trg_prc failed for table: "' ||
                              nvl(v_tab, TRIM(p_table_name)) || '": ' ||
                              SQLERRM);
  END create_auto_id_created_trg_prc;

  
  PROCEDURE create_historisation_for_table(p_table_name IN VARCHAR2) IS
    v_tab VARCHAR2(30);
    -- Max 30 karakter hossz miatt limitálom a bementetet.
    v_cnt          NUMBER;
    v_col_list     VARCHAR2(32767);
    v_new_list     VARCHAR2(32767);
    v_old_del_list VARCHAR2(32767);
    v_sql          VARCHAR2(32767);

    e_invalid_name     EXCEPTION;
    e_name_too_long    EXCEPTION;
    e_table_not_exists EXCEPTION;
  BEGIN
    ----------------------------------------------------------------------------
    -- 0. Input validáció + korrekció
    ----------------------------------------------------------------------------
    IF p_table_name IS NULL
       OR TRIM(p_table_name) IS NULL
    THEN
      RAISE e_invalid_name;
    END IF;

    IF length(TRIM(p_table_name)) > 30
    THEN
      RAISE e_name_too_long;
    END IF;

    v_tab := upper(TRIM(p_table_name));

    SELECT COUNT(*) INTO v_cnt FROM user_tables WHERE table_name = v_tab;
    IF v_cnt = 0
    THEN
      RAISE e_table_not_exists;
    END IF;

    ----------------------------------------------------------------------------
    -- 1. Oszlopok hozzáadása: MOD_USER, DML_FLAG, LAST_MODIFIED, VERSION
    ----------------------------------------------------------------------------

    -- MOD_USER
    SELECT COUNT(*)
      INTO v_cnt
      FROM user_tab_cols
     WHERE table_name = v_tab
       AND column_name = 'MOD_USER';
    -- Ellenörzés hogy létezik e a hozzáadandó oszlop

    IF v_cnt = 0
    THEN
      EXECUTE IMMEDIATE 'ALTER TABLE ' || v_tab ||
                        ' ADD (mod_user VARCHAR2(300))';
    END IF;

    -- DML_FLAG
    SELECT COUNT(*)
      INTO v_cnt
      FROM user_tab_cols
     WHERE table_name = v_tab
       AND column_name = 'DML_FLAG';

    IF v_cnt = 0
    THEN
      EXECUTE IMMEDIATE 'ALTER TABLE ' || v_tab ||
                        ' ADD (dml_flag VARCHAR2(1))';
    END IF;

    -- LAST_MODIFIED
    SELECT COUNT(*)
      INTO v_cnt
      FROM user_tab_cols
     WHERE table_name = v_tab
       AND column_name = 'LAST_MODIFIED';

    IF v_cnt = 0
    THEN
      EXECUTE IMMEDIATE 'ALTER TABLE ' || v_tab ||
                        ' ADD (last_modified DATE)';
    END IF;

    -- VERSION
    SELECT COUNT(*)
      INTO v_cnt
      FROM user_tab_cols
     WHERE table_name = v_tab
       AND column_name = 'VERSION';

    IF v_cnt = 0
    THEN
      EXECUTE IMMEDIATE 'ALTER TABLE ' || v_tab || ' ADD (version NUMBER)';
    END IF;

    ------------------------------------------------------------------
    -- 2. HISTORY tábla létrehozása: <TABLE>_H
    --    csak minden oszlop átmásolása
    ------------------------------------------------------------------

    SELECT COUNT(*)
      INTO v_cnt
      FROM user_tables
     WHERE table_name = v_tab || '_H';

    IF v_cnt = 0
    THEN
      v_sql := 'CREATE TABLE ' || v_tab || '_H AS ' || 'SELECT * FROM ' ||
               v_tab || ' WHERE 1 = 2';
      EXECUTE IMMEDIATE v_sql;
    END IF;

    ------------------------------------------------------------------
    -- 3. Oszloplista legenerálása a triggerekhez
    ------------------------------------------------------------------

    v_col_list     := NULL;
    v_new_list     := NULL;
    v_old_del_list := NULL;

    FOR c IN (SELECT column_name
                FROM user_tab_cols
               WHERE table_name = v_tab
               ORDER BY column_id)
    LOOP
      -- közös oszloplista
      IF v_col_list IS NULL
      THEN
        v_col_list := c.column_name;
      ELSE
        v_col_list := v_col_list || ',' || c.column_name;
      END IF;
    
      -- INSERT/UPDATE esetén :NEW.<column> a DML_FLAG-et már kezeltem a másik triggerben.
      IF v_new_list IS NULL
      THEN
        v_new_list := ':NEW.' || c.column_name;
      ELSE
        v_new_list := v_new_list || ',:NEW.' || c.column_name;
      END IF;
    
      -- DELETE esetén: minden :OLD.<column>, KIVÉVE DML_FLAG = 'D'.
      IF c.column_name = 'DML_FLAG'
      THEN
        IF v_old_del_list IS NULL
        THEN
          v_old_del_list := '''D''';
        ELSE
          v_old_del_list := v_old_del_list || ',''D''';
        END IF;
      ELSE
        IF v_old_del_list IS NULL
        THEN
          v_old_del_list := ':OLD.' || c.column_name;
        ELSE
          v_old_del_list := v_old_del_list || ',:OLD.' || c.column_name;
        END IF;
      END IF;
    END LOOP;

    ------------------------------------------------------------------
    -- 4. BEFORE INSERT/UPDATE trigger: <TABLE>_TRG
    --    mod_user, dml_flag, last_modified, version töltése
    ------------------------------------------------------------------

    v_sql := 'CREATE OR REPLACE TRIGGER ' || v_tab || '_TRG ' ||
             'BEFORE INSERT OR UPDATE ON ' || v_tab || ' ' || 'FOR EACH ROW ' ||
             'BEGIN ' || '  IF INSERTING THEN ' ||
             '    :NEW.mod_user      := sys_context(''USERENV'',''OS_USER''); ' ||
             '    :NEW.dml_flag      := ''I''; ' ||
             '    :NEW.last_modified := SYSDATE; ' ||
             '    :NEW.version       := NVL(:NEW.version, 1); ' || '  ELSE ' ||
             '    :NEW.mod_user      := sys_context(''USERENV'',''OS_USER''); ' ||
             '    :NEW.dml_flag      := ''U''; ' ||
             '    :NEW.last_modified := SYSDATE; ' ||
             '    :NEW.version       := NVL(:OLD.version, 0) + 1; ' ||
             '  END IF; ' || 'END;';

    EXECUTE IMMEDIATE v_sql;

    ------------------------------------------------------------------
    -- 5. AFTER INSERT/UPDATE/DELETE trigger: <TABLE>_H_TRG
    --    history logolás <TABLE>_H táblába (dump)
    ------------------------------------------------------------------

    v_sql := 'CREATE OR REPLACE TRIGGER ' || v_tab || '_H_TRG ' ||
             'AFTER INSERT OR UPDATE OR DELETE ON ' || v_tab || ' ' ||
             'FOR EACH ROW ' || 'BEGIN ' || '  IF DELETING THEN ' ||
             '    INSERT INTO ' || v_tab || '_H (' || v_col_list || ') ' ||
             '    VALUES (' || v_old_del_list || '); ' || '  ELSE ' ||
             '    INSERT INTO ' || v_tab || '_H (' || v_col_list || ') ' ||
             '    VALUES (' || v_new_list || '); ' || '  END IF; ' || 'END;';

    EXECUTE IMMEDIATE v_sql;

  EXCEPTION
    WHEN e_invalid_name THEN
      raise_application_error(-20000,
                              'create_historisation_for_table: table name must not be NULL or empty.');
      RAISE;
    WHEN e_name_too_long THEN
      raise_application_error(-20001,
                              'create_historisation_for_table: table name: "' ||
                              p_table_name ||
                              '" is longer than 30 characters (Oracle 11g limit).');
      RAISE;
    WHEN e_table_not_exists THEN
      raise_application_error(-20002,
                              'create_historisation_for_table: table "' ||
                              v_tab || '" does not exist in current schema.');
      RAISE;
    WHEN OTHERS THEN
      raise_application_error(-20009,
                              'create_historisation_for_table failed for table "' ||
                              nvl(v_tab, p_table_name) || '": ' || SQLERRM);
      RAISE;
  END create_historisation_for_table;
  
END audit_util_pkg;
/
