CREATE OR REPLACE FUNCTION build_next_task_key_fnc(p_project_id IN NUMBER)
  RETURN VARCHAR2 IS
  l_proj_key app_project.proj_key%TYPE;
  l_seq_name app_project.task_seq_name%TYPE;
  l_next_num NUMBER;
BEGIN
  ------------------------------------------------------------------
  -- Projekt kulcs és a hozzá tartozó sequence név beolvasása
  ------------------------------------------------------------------
  SELECT proj_key
        ,task_seq_name
    INTO l_proj_key
        ,l_seq_name
    FROM app_project
   WHERE id = p_project_id;

  ------------------------------------------------------------------
  -- Ha még nincs sequence név eltárolva, generáljuk és hozzuk létre
  ------------------------------------------------------------------
  IF l_seq_name IS NULL
  THEN
    l_seq_name := build_task_seq_name_fnc(l_proj_key);
  
    -- próbáljuk létrehozni a sequence-et; ha már létezik, nem baj
    BEGIN
      EXECUTE IMMEDIATE 'CREATE SEQUENCE ' || l_seq_name ||
                        ' START WITH 1 INCREMENT BY 1';
    END;
  
    UPDATE app_project
       SET task_seq_name = l_seq_name
     WHERE id = p_project_id;
  END IF;

  ------------------------------------------------------------------
  -- Következõ sorszám lekérése a sequence-bõl
  ------------------------------------------------------------------
  EXECUTE IMMEDIATE 'SELECT ' || l_seq_name || '.NEXTVAL FROM dual'
    INTO l_next_num;

  RETURN l_proj_key || '-' || lpad(l_next_num, 4, '0');
END;
/
