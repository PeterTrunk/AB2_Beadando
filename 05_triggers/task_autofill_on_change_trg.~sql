CREATE OR REPLACE TRIGGER task_autofill_on_change_trg
  AFTER INSERT OR UPDATE OR DELETE ON task
DECLARE
BEGIN
  task_autofill_pkg.fill_todo_from_backlog;
END;
/
