-- Ez a Funkció még nem működik!

/*
   TESZT: TASK_AUTOFILL TRIGGER + fill_todo_from_backlog
   Változat: saját teszt boardot és oszlopokat hozunk létre.

   Lépések:
     1) DEVOPS projekt ID beolvasása.
     2) "DEVOPS Autofill Test Board" board lekérdezése VAGY létrehozása.
     3) BACKLOG és TODO oszlop lekérdezése VAGY létrehozása (TODO WIP = 1).
     4) Teszt sprint létrehozása.
     5) 1 TODO + 2 BACKLOG task létrehozása a sprintben.
     6) TODO/BACKLOG aktív task-szám ELŐTTE.
     7) TODO task lezárása → trigger fut.
     8) TODO/BACKLOG aktív task-szám UTÁNA.
     9) Eredmény kiértékelése.
*/

DECLARE
  -- Projekt / board
  v_devops_project_id app_project.id%TYPE;
  v_board_id          board.id%TYPE;
  v_new_board_pos     board.position%TYPE;

  -- Status ID-k
  v_status_backlog_id task_status.id%TYPE;
  v_status_todo_id    task_status.id%TYPE;

  -- Oszlopok
  v_backlog_col_id column_def.id%TYPE;
  v_todo_col_id    column_def.id%TYPE;

  -- Sprint
  v_sprint_id sprint.id%TYPE;

  -- User
  v_user_id app_user.id%TYPE;

  -- Task ID-k
  v_task_todo_id      task.id%TYPE;
  v_task_backlog1_id  task.id%TYPE;
  v_task_backlog2_id  task.id%TYPE;

  -- Darabszámok
  v_todo_before     NUMBER;
  v_backlog_before  NUMBER;
  v_todo_after      NUMBER;
  v_backlog_after   NUMBER;
BEGIN
  DBMS_OUTPUT.put_line('===== TASK_AUTOFILL TRIGGER TESZT (saját board) =====');

  --------------------------------------------------------------------
  -- 1. DEVOPS projekt
  --------------------------------------------------------------------
  SELECT id
    INTO v_devops_project_id
    FROM app_project
   WHERE proj_key = 'DEVOPS';

  --------------------------------------------------------------------
  -- 2. Teszt board lekérdezése / létrehozása
  --------------------------------------------------------------------
  BEGIN
    SELECT id
      INTO v_board_id
      FROM board
     WHERE project_id = v_devops_project_id
       AND board_name = 'DEVOPS Autofill Test Board';
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
      -- Következő szabad pozíció a projekten belül
      SELECT NVL(MAX(position), 0) + 1
        INTO v_new_board_pos
        FROM board
       WHERE project_id = v_devops_project_id;

      board_mgmt_pkg.create_board_prc(
        p_project_id => v_devops_project_id,
        p_board_name => 'DEVOPS Autofill Test Board',
        p_is_default => 0,
        p_position   => v_new_board_pos,
        p_board_id   => v_board_id
      );
  END;

  --------------------------------------------------------------------
  -- 3. Státuszok + oszlopok (BACKLOG, TODO)
  --------------------------------------------------------------------
  SELECT id INTO v_status_backlog_id FROM task_status WHERE code = 'BACKLOG';
  SELECT id INTO v_status_todo_id    FROM task_status WHERE code = 'TODO';

  -- BACKLOG oszlop
  BEGIN
    SELECT id
      INTO v_backlog_col_id
      FROM column_def
     WHERE board_id  = v_board_id
       AND status_id = v_status_backlog_id;
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
      column_mgmt_pkg.create_column_prc(
        p_board_id    => v_board_id,
        p_column_name => 'Backlog (autofill teszt)',
        p_wip_limit   => NULL,
        p_position    => 1,
        p_status_code => 'BACKLOG',
        p_column_id   => v_backlog_col_id
      );
  END;

  -- TODO oszlop (WIP_LIMIT = 1)
  BEGIN
    SELECT id
      INTO v_todo_col_id
      FROM column_def
     WHERE board_id  = v_board_id
       AND status_id = v_status_todo_id;
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
      column_mgmt_pkg.create_column_prc(
        p_board_id    => v_board_id,
        p_column_name => 'To Do (autofill teszt)',
        p_wip_limit   => 1,
        p_position    => 2,
        p_status_code => 'TODO',
        p_column_id   => v_todo_col_id
      );
  END;

  -- Biztosan WIP_LIMIT = 1 legyen a TODO-n
  UPDATE column_def
     SET wip_limit = 1
   WHERE id = v_todo_col_id;

  --------------------------------------------------------------------
  -- 4. Teszt sprint létrehozása
  --------------------------------------------------------------------
  sprint_mgmt_pkg.create_sprint_prc(
    p_project_id  => v_devops_project_id,
    p_board_id    => v_board_id,
    p_sprint_name => 'Autofill teszt sprint',
    p_goal        => 'Autofill trigger tesztelése',
    p_start_date  => TRUNC(SYSDATE),
    p_end_date    => TRUNC(SYSDATE) + 7,
    p_state       => 'ACTIVE',
    p_sprint_id   => v_sprint_id
  );

  --------------------------------------------------------------------
  -- 5. User + taskok létrehozása
  --------------------------------------------------------------------
  SELECT id
    INTO v_user_id
    FROM app_user
   WHERE email = 'peter@example.com';

  -- 5.1 TODO task (WIP = 1 oszlopban)
  task_mgmt_pkg.create_task_prc(
    p_project_id    => v_devops_project_id,
    p_board_id      => v_board_id,
    p_column_id     => v_todo_col_id,
    p_sprint_id     => v_sprint_id,
    p_created_by    => v_user_id,
    p_title         => 'Autofill TESZT TODO',
    p_description   => 'Teszt TODO task az autofill triggerhez.',
    p_status_id     => v_status_todo_id,
    p_priority      => 'HIGH',
    p_estimated_min => 60,
    p_due_date      => TRUNC(SYSDATE) + 3,
    p_task_id       => v_task_todo_id
  );

  -- 5.2 BACKLOG task #1
  task_mgmt_pkg.create_task_prc(
    p_project_id    => v_devops_project_id,
    p_board_id      => v_board_id,
    p_column_id     => v_backlog_col_id,
    p_sprint_id     => v_sprint_id,
    p_created_by    => v_user_id,
    p_title         => 'Autofill TESZT BACKLOG 1',
    p_description   => 'Első backlog task az autofill teszthez.',
    p_status_id     => v_status_backlog_id,
    p_priority      => 'MEDIUM',
    p_estimated_min => 30,
    p_due_date      => TRUNC(SYSDATE) + 5,
    p_task_id       => v_task_backlog1_id
  );

  -- 5.3 BACKLOG task #2
  task_mgmt_pkg.create_task_prc(
    p_project_id    => v_devops_project_id,
    p_board_id      => v_board_id,
    p_column_id     => v_backlog_col_id,
    p_sprint_id     => v_sprint_id,
    p_created_by    => v_user_id,
    p_title         => 'Autofill TESZT BACKLOG 2',
    p_description   => 'Második backlog task az autofill teszthez.',
    p_status_id     => v_status_backlog_id,
    p_priority      => 'LOW',
    p_estimated_min => 45,
    p_due_date      => TRUNC(SYSDATE) + 6,
    p_task_id       => v_task_backlog2_id
  );

  --------------------------------------------------------------------
  -- 6. TODO / BACKLOG darabszám ELŐTTE
  --------------------------------------------------------------------
  SELECT COUNT(*)
    INTO v_todo_before
    FROM task
   WHERE column_id = v_todo_col_id
     AND sprint_id = v_sprint_id
     AND closed_at IS NULL;

  SELECT COUNT(*)
    INTO v_backlog_before
    FROM task
   WHERE column_id = v_backlog_col_id
     AND sprint_id = v_sprint_id
     AND closed_at IS NULL;

  DBMS_OUTPUT.put_line('ELŐTTE  - TODO aktív: '  || v_todo_before ||
                       ' | BACKLOG aktív: '     || v_backlog_before);

  --------------------------------------------------------------------
  -- 7. TODO task lezárása → triggernek futnia kell
  --------------------------------------------------------------------
  UPDATE task
     SET closed_at = SYSDATE
   WHERE id = v_task_todo_id;

  --------------------------------------------------------------------
  -- 8. TODO / BACKLOG darabszám UTÁNA
  --------------------------------------------------------------------
  SELECT COUNT(*)
    INTO v_todo_after
    FROM task
   WHERE column_id = v_todo_col_id
     AND sprint_id = v_sprint_id
     AND closed_at IS NULL;

  SELECT COUNT(*)
    INTO v_backlog_after
    FROM task
   WHERE column_id = v_backlog_col_id
     AND sprint_id = v_sprint_id
     AND closed_at IS NULL;

  DBMS_OUTPUT.put_line('UTÁNA  - TODO aktív: '   || v_todo_after   ||
                       ' | BACKLOG aktív: '      || v_backlog_after);

  --------------------------------------------------------------------
  -- 9. Kiértékelés
  --------------------------------------------------------------------
  IF v_todo_before    = 1
     AND v_backlog_before = 2
     AND v_todo_after = 1
     AND v_backlog_after = 1
  THEN
    DBMS_OUTPUT.put_line(
      'RESULT: SIKERES – a trigger lefutott, és a BACKLOG-ból ' ||
      'automatikusan bekerült egy task a To Do oszlopba.'
    );
  ELSE
    DBMS_OUTPUT.put_line(
      'RESULT: HIBA – az autofill logika nem a várt módon ' ||
      'változtatta meg a TODO / BACKLOG darabszámokat.'
    );
  END IF;

  DBMS_OUTPUT.put_line('===== TASK_AUTOFILL TRIGGER TESZT VÉGE =====');

EXCEPTION
  WHEN OTHERS THEN
    DBMS_OUTPUT.put_line('*** TESZT HIBA ***: ' || SQLERRM);
    RAISE;
END;
/
