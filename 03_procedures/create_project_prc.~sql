CREATE OR REPLACE PROCEDURE create_project_prc(p_project_name IN app_project.project_name%TYPE
                                                       ,p_proj_key     IN app_project.proj_key%TYPE
                                                       ,p_description  IN app_project.description%TYPE DEFAULT NULL
                                                       ,p_owner_id     IN app_project.owner_id%TYPE
                                                       ,p_project_id   OUT app_project.id%TYPE) IS
  v_seq_name app_project.task_seq_name%TYPE;
  v_cnt      NUMBER;
  v_sql      VARCHAR2(4000);
BEGIN
  ------------------------------------------------------------------
  -- 1. Task sequence név felépítése (pl. 'PMA_SEQ')
  ------------------------------------------------------------------
  v_seq_name := build_task_seq_name_fnc(p_proj_key);

  ------------------------------------------------------------------
  -- 2. Projekt beszúrása app_project-be
  ------------------------------------------------------------------
  INSERT INTO app_project
    (id
    ,project_name
    ,proj_key
    ,task_seq_name
    ,description
    ,owner_id)
  VALUES
    (app_project_seq.nextval
    ,p_project_name
    ,p_proj_key
    ,v_seq_name
    ,p_description
    ,p_owner_id)
  RETURNING id INTO p_project_id;

  ------------------------------------------------------------------
  -- 3. Sequence létrehozása, ha még nem létezik
  ------------------------------------------------------------------
  SELECT COUNT(*)
    INTO v_cnt
    FROM user_sequences
   WHERE sequence_name = v_seq_name;

  IF v_cnt = 0
  THEN
    v_sql := 'CREATE SEQUENCE ' || v_seq_name ||
             ' START WITH 1 INCREMENT BY 1 NOCACHE';
    EXECUTE IMMEDIATE v_sql;
  END IF;
END;
/
