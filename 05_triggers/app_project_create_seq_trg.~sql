CREATE OR REPLACE TRIGGER app_project_crea_task_seq_trg
  BEFORE INSERT ON app_project
  FOR EACH ROW
DECLARE
BEGIN
  :NEW.task_seq_name := build_task_seq_name_fnc(:NEW.proj_key);
  
  BEGIN
    EXECUTE IMMEDIATE
      'CREATE SEQUENCE ' || :NEW.task_seq_name ||
      ' START WITH 1 INCREMENT BY 1';
  END;
END;
/
