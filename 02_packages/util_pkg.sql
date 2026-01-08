CREATE OR REPLACE PACKAGE util_pkg IS

  --------------------------------------------------------------------
  -- Task sequence név generálása PROJ_KEY alapján
  --------------------------------------------------------------------
  FUNCTION build_task_seq_name_fnc(p_proj_key IN VARCHAR2)
    RETURN VARCHAR2;

  --------------------------------------------------------------------
  -- Következő task_key generálása projekt szinten
  --------------------------------------------------------------------
  FUNCTION build_next_task_key_fnc(p_project_id IN NUMBER)
    RETURN VARCHAR2;

END util_pkg;
/
