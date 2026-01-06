DECLARE
  CURSOR c_proj IS
    SELECT id
          ,proj_key
          ,task_seq_name
      FROM app_project
     ORDER BY id;
 
  l_total_projects NUMBER := 0;
  l_error_count    NUMBER := 0;
  l_seq_cnt        NUMBER;
  l_nextval        NUMBER;
BEGIN

  --    Kritérium: TASK_SEQ_NAME nem lehet NULL, és a Projekt rekordján szerepel a SEQ neve.
  --    Ez alapján vannak elválasztva a projektenkénti task számozások,
  --    Csúnyán nézne ki ha 'A'-Projekt Taskjai 'B'-Projekt Taskjainak sorszáma után kezdődnének.
  --    Projekt Létrehozó Procedurában hozza létre a SEQ-eket a projektekhez.

  dbms_output.put_line('- PROJECT TASK SEQUENCE KONZISZTENCIA ELLENÖRZÉS -');

  FOR r IN c_proj
  LOOP
    l_total_projects := l_total_projects + 1;
  
    dbms_output.put_line('-------------------------------------------------');
    dbms_output.put_line('Project ID   : ' || r.id);
    dbms_output.put_line('Project KEY  : ' || r.proj_key);
    dbms_output.put_line('TASK_SEQ_NAME: ' ||
                         nvl(r.task_seq_name, '<NULL>'));
  
    -- 1. Ellenőrizzük hogy a Projekt Rekordjában Be van e jegyezve a SEQ-neve: 
    IF r.task_seq_name IS NULL
    THEN
      dbms_output.put_line('  ERROR: TASK_SEQ_NAME NULL ezen Projekthez.');
      l_error_count := l_error_count + 1;
      CONTINUE;
    END IF;
  
    -- 2. Ellenőrizzük hogy valóban létezik e ilyen néven egy SEQ
    SELECT COUNT(*)
      INTO l_seq_cnt
      FROM user_sequences
     WHERE sequence_name = upper(r.task_seq_name);
  
    IF l_seq_cnt = 0
    THEN
      dbms_output.put_line('  ERROR: SEQ "' || r.task_seq_name ||
                           '" Nem Található!.');
      l_error_count := l_error_count + 1;
      CONTINUE;
    ELSE
      dbms_output.put_line(' OK: SEQ "' || r.task_seq_name ||
                           '" Észlelve');
    END IF;
  
    -- 3. NEXTVAL teszt a SEQ-en
    BEGIN
      EXECUTE IMMEDIATE 'SELECT ' || r.task_seq_name ||
                        '.NEXTVAL FROM dual'
        INTO l_nextval;
    
      dbms_output.put_line(' OK: ' || r.task_seq_name || '.NEXTVAL = ' ||
                           l_nextval);
    EXCEPTION
      WHEN OTHERS THEN
        dbms_output.put_line('  ERROR: SEQ "' || r.task_seq_name ||
                             '" létrejött, de a NEXTVAL sikertelen: ' || SQLERRM);
        l_error_count := l_error_count + 1;
    END;
  END LOOP;

  dbms_output.put_line('-------------------------------------------------');
  dbms_output.put_line('Összes Projekt ellenőrizve: : ' || l_total_projects);
  dbms_output.put_line('Hibás Projektek: ' || l_error_count);

  IF l_error_count = 0
  THEN
    dbms_output.put_line('RESULT: A Projektekhez HELYESEN létrejöttek a SEQ-ek!');
  ELSE
    dbms_output.put_line('RESULT: HIBÁS Létrehozás a SEQ-ekkel kapcsolatban!');
  END IF;
END;
/
