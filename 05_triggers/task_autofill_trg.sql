CREATE OR REPLACE TRIGGER task_autofill_trg
  AFTER INSERT OR UPDATE OF column_id, closed_at ON task
DECLARE
BEGIN
  -- Megpróbálunk egy feladatot áthúzni Backlog - TODO
  task_autofill_pkg.fill_todo_from_backlog;

EXCEPTION
  --------------------------------------------------------------------
  -- Az ismert, domain-szintű hibákat NEM dobjuk tovább,
  -- mert az eredeti INSERT/UPDATE ettől még lehet sikeres.
  -- A részleteket már a task_autofill_pkg + err_log_pkg logolja.
  --------------------------------------------------------------------
  WHEN pkg_exceptions.move_task_board_mismatch
       OR pkg_exceptions.move_task_wip_exceeded
       OR pkg_exceptions.move_task_not_found
       OR pkg_exceptions.move_task_generic THEN
    NULL;
  WHEN OTHERS THEN
    RAISE;
END task_autofill_trg;
/
