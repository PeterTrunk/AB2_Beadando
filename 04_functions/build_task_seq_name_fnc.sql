CREATE OR REPLACE FUNCTION build_task_seq_name_fnc(p_proj_key IN app_project.proj_key%TYPE)
  RETURN VARCHAR2 IS
BEGIN
  -- Pl. 'PMA' -> 'PMA_TASK_SEQ'
  RETURN upper(TRIM(p_proj_key)) || '_TASK_SEQ';
END build_task_seq_name_fnc;
/
