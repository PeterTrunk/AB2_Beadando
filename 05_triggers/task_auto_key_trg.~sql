CREATE OR REPLACE TRIGGER task_auto_key_trg
  BEFORE INSERT ON task
  FOR EACH ROW
BEGIN
  IF :NEW.task_key IS NULL THEN
    :NEW.task_key := build_next_task_key_fnc(:NEW.project_id);
  END IF;
END;
/
