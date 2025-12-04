CREATE OR REPLACE FUNCTION build_next_task_key_fnc(p_project_id IN NUMBER)
  RETURN VARCHAR2 IS
  l_proj_key app_project.proj_key%TYPE;
  l_seq_name app_project.task_seq_name%TYPE;
  l_next_num NUMBER;
BEGIN
  SELECT proj_key
        ,task_seq_name
    INTO l_proj_key
        ,l_seq_name
    FROM app_project
   WHERE id = p_project_id;

  EXECUTE IMMEDIATE 'SELECT ' || l_seq_name || '.NEXTVAL FROM dual'
    INTO l_next_num;

  RETURN l_proj_key || '-' || lpad(l_next_num, 4, '0');
END;
/
