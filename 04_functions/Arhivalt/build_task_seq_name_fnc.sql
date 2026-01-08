CREATE OR REPLACE FUNCTION build_task_seq_name_fnc(p_proj_key IN VARCHAR2)
  RETURN VARCHAR2 IS
  l_base_name VARCHAR2(30);
  l_seq_name  VARCHAR2(30);
BEGIN
  l_base_name := upper(p_proj_key);

  -- csak A–Z, 0–9, egyébként cseréljük
  l_base_name := regexp_replace(l_base_name, '[^A-Z0-9_]', '_');

  -- ha számmal kezdődne, tegyünk elé 'P_'
  IF regexp_like(l_base_name, '^[0-9]')
  THEN
    l_base_name := 'P_' || l_base_name;
  END IF;

  -- név: <base>_SEQ, max 30 karakter
  l_seq_name := substr(l_base_name || '_SEQ', 1, 30);

  RETURN l_seq_name;
END;
/
