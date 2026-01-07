CREATE OR REPLACE PACKAGE task_autofill_pkg IS
  -- Egyetlen backlog task behúzása To Do-ba (ha van hely)
  PROCEDURE fill_todo_from_backlog;
END task_autofill_pkg;
/
