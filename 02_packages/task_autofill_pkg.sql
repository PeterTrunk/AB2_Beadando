CREATE OR REPLACE PACKAGE task_autofill_pkg IS
  -- Re-entrancia védelem: ha már épp mozgatunk, ne induljunk újra
  g_autofill_running BOOLEAN := FALSE;

  -- Egyetlen backlog task behúzása To Do-ba (ha van hely)
  PROCEDURE fill_todo_from_backlog;
END task_autofill_pkg;
/
