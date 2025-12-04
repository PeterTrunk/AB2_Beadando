CREATE OR REPLACE PROCEDURE create_auto_id_created_trg_prc(p_table_name IN VARCHAR2) IS
  v_tab         VARCHAR2(30);
  v_cnt         NUMBER;
  v_has_created NUMBER;
  v_has_joined  NUMBER;  -- JOINED_AT oszlop? (PROJECT_MEMBER-hez)
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
END;
/
