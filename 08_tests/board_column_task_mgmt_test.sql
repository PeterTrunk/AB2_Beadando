DECLARE
  ----------------------------------------------------------------------
  -- Alap azonosítók
  ----------------------------------------------------------------------
  v_devops_project_id     app_project.id%TYPE;
  v_devops_main_board_id  board.id%TYPE;
  v_devops_exp_board_id   board.id%TYPE;

  -- Columns DEVOPS Main Boardon
  v_devops_backlog_col_id column_def.id%TYPE;
  v_devops_todo_col_id    column_def.id%TYPE;

  -- Sprint
  v_devops_sprint1_id  sprint.id%TYPE;

  -- Userek
  v_peter_id app_user.id%TYPE;
  v_dev_id   app_user.id%TYPE;

  -- Státusz ID-k
  v_status_backlog_id task_status.id%TYPE;
  v_status_todo_id    task_status.id%TYPE;

  -- Taskok
  v_task_a_id task.id%TYPE;
  v_task_b_id task.id%TYPE;
  v_task_c_id task.id%TYPE;

  -- Ideiglenes változók ellenőrzéshez
  l_name      VARCHAR2(200);
  l_wip       NUMBER;
  l_pos       NUMBER;
  l_def_count NUMBER;
  l_col_id    column_def.id%TYPE;
  l_base_pos  NUMBER;
BEGIN
  DBMS_OUTPUT.put_line('---------------------------------------------------------');
  DBMS_OUTPUT.put_line('TEST 4 – BOARD / COLUMN / TASK MGMT (DEVOPS projekt)');
  DBMS_OUTPUT.put_line('---------------------------------------------------------');

  --------------------------------------------------------------------
  -- 0. Előkészítés: DEVOPS projekt, board, userek, státuszok
  --------------------------------------------------------------------
  SELECT id
    INTO v_devops_project_id
    FROM app_project
   WHERE proj_key = 'DEVOPS';

  -- ha már át lett nevezve, először Main Board, ha nincs, akkor Board
  BEGIN
    SELECT id
      INTO v_devops_main_board_id
      FROM board
     WHERE project_id = v_devops_project_id
       AND board_name = 'DEVOPS Main Board';
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
      SELECT id
        INTO v_devops_main_board_id
        FROM board
       WHERE project_id = v_devops_project_id
         AND board_name = 'DEVOPS Board';
  END;

  SELECT id INTO v_peter_id FROM app_user WHERE email = 'peter@example.com';
  SELECT id INTO v_dev_id   FROM app_user WHERE email = 'dev@example.com';

  SELECT id INTO v_status_backlog_id FROM task_status WHERE code = 'BACKLOG';
  SELECT id INTO v_status_todo_id    FROM task_status WHERE code = 'TODO';

  DBMS_OUTPUT.put_line('0) Előkészítés OK (DEVOPS projekt, board, userek, státuszok betöltve).');

  --------------------------------------------------------------------
  -- 1) COLUMN_MGMT_PKG – oszlopok létrehozása / felhasználása
  --------------------------------------------------------------------
  DBMS_OUTPUT.put_line('1) COLUMN_MGMT_PKG teszt indul...');

  -- DEVOPS backlog oszlop – ha már van BACKLOG státuszos oszlop, azt használjuk
  BEGIN
    SELECT id
      INTO v_devops_backlog_col_id
      FROM (
        SELECT c.id
          FROM column_def c
          JOIN task_status ts ON ts.id = c.status_id
         WHERE c.board_id = v_devops_main_board_id
           AND ts.code = 'BACKLOG'
         ORDER BY c.position
      )
     WHERE ROWNUM = 1;
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
      -- nincs BACKLOG-oszlop - létrehozzuk a lista végére
      SELECT NVL(MAX(position), 0)
        INTO l_base_pos
        FROM column_def
       WHERE board_id = v_devops_main_board_id;

      column_mgmt_pkg.create_column_prc(
        p_board_id    => v_devops_main_board_id,
        p_column_name => 'DEVOPS Backlog',
        p_wip_limit   => NULL,
        p_position    => l_base_pos + 1,
        p_status_code => 'BACKLOG',
        p_column_id   => v_devops_backlog_col_id
      );
  END;

  -- DEVOPS TODO oszlop – ha már van TODO státuszos oszlop, azt használjuk
  BEGIN
    SELECT id
      INTO v_devops_todo_col_id
      FROM (
        SELECT c.id
          FROM column_def c
          JOIN task_status ts ON ts.id = c.status_id
         WHERE c.board_id = v_devops_main_board_id
           AND ts.code = 'TODO'
         ORDER BY c.position
      )
     WHERE ROWNUM = 1;
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
      -- nincs TODO-oszlop - létrehozzuk, ismét a lista végére
      SELECT NVL(MAX(position), 0)
        INTO l_base_pos
        FROM column_def
       WHERE board_id = v_devops_main_board_id;

      column_mgmt_pkg.create_column_prc(
        p_board_id    => v_devops_main_board_id,
        p_column_name => 'DEVOPS To Do',
        p_wip_limit   => 2,
        p_position    => l_base_pos + 1,
        p_status_code => 'TODO',
        p_column_id   => v_devops_todo_col_id
      );
  END;

  DBMS_OUTPUT.put_line('   - BACKLOG és TODO oszlopok azonosítva/létrehozva.');

  -- TODO oszlop átnevezése + WIP=1 beállítása
  column_mgmt_pkg.update_column_prc(
    p_column_id     => v_devops_todo_col_id,
    p_new_name      => 'DEVOPS TODO',
    p_new_wip_limit => 1      -- WIP_LIMIT = 1
  );

  -- TODO oszlop legyen az 1. pozíción, Alkalmazás használat szempontjábol habár logikátlan de szemlélteti a használatot.
  column_mgmt_pkg.reorder_column_prc(
    p_column_id    => v_devops_todo_col_id,
    p_new_position => 1
  );

  -- Ellenőrzés
  SELECT column_name, wip_limit, position
    INTO l_name, l_wip, l_pos
    FROM column_def
   WHERE id = v_devops_todo_col_id;

  IF l_name = 'DEVOPS TODO'
     AND NVL(l_wip, -1) = 1
     AND l_pos = 1
  THEN
    DBMS_OUTPUT.put_line('   - COLUMN_MGMT_PKG: OK (név=DEVOPS TODO, WIP=1, position=1).');
  ELSE
    DBMS_OUTPUT.put_line('   !! HIBA: COLUMN_MGMT_PKG eredmény nem várt (név/WIP/pozíció).');
  END IF;

  --------------------------------------------------------------------
  -- 2) BOARD_MGMT_PKG – board átnevezés, új board, reorder, default
  --------------------------------------------------------------------
  DBMS_OUTPUT.put_line('2) BOARD_MGMT_PKG teszt indul...');

  board_mgmt_pkg.rename_board_prc(
    p_board_id => v_devops_main_board_id,
    p_new_name => 'DEVOPS Main Board'
  );

  board_mgmt_pkg.create_board_prc(
    p_project_id => v_devops_project_id,
    p_board_name => 'DEVOPS Experiments',
    p_is_default => 0,
    p_position   => 2,
    p_board_id   => v_devops_exp_board_id
  );

  board_mgmt_pkg.reorder_board_prc(
    p_board_id     => v_devops_exp_board_id,
    p_new_position => 1
  );

  board_mgmt_pkg.set_default_board_prc(
    p_project_id => v_devops_project_id,
    p_board_id   => v_devops_exp_board_id
  );

  SELECT COUNT(*)
    INTO l_def_count
    FROM board
   WHERE project_id = v_devops_project_id
     AND is_default = 1;

  IF l_def_count = 1 THEN
    DBMS_OUTPUT.put_line('   - BOARD_MGMT_PKG: OK (1 db default board van a DEVOPS projekten).');
  ELSE
    DBMS_OUTPUT.put_line('   !! HIBA: BOARD_MGMT_PKG – default boardok száma = ' || l_def_count);
  END IF;

  --------------------------------------------------------------------
  -- 3) SPRINT_MGMT_PKG + TASK_MGMT_PKG – sprint + task műveletek
  --------------------------------------------------------------------
  DBMS_OUTPUT.put_line('3) SPRINT_MGMT_PKG + TASK_MGMT_PKG teszt indul...');

  sprint_mgmt_pkg.create_sprint_prc(
    p_project_id  => v_devops_project_id,
    p_board_id    => v_devops_main_board_id,
    p_sprint_name => 'DEVOPS Sprint 1',
    p_goal        => 'Board/Task mgmt integrált teszt sprint.',
    p_start_date  => TRUNC(SYSDATE),
    p_end_date    => TRUNC(SYSDATE) + 14,
    p_state       => 'ACTIVE',
    p_sprint_id   => v_devops_sprint1_id
  );

  DBMS_OUTPUT.put_line('   - DEVOPS Sprint 1 létrehozva.');

  -- Taskok létrehozása (A,B BACKLOG; C TODO)
  task_mgmt_pkg.create_task_prc(
    p_project_id    => v_devops_project_id,
    p_board_id      => v_devops_main_board_id,
    p_column_id     => v_devops_backlog_col_id,
    p_sprint_id     => v_devops_sprint1_id,
    p_created_by    => v_peter_id,
    p_title         => 'DEVOPS Task A (BACKLOG)',
    p_description   => 'Teszt task A – BACKLOG oszlopban.',
    p_status_id     => v_status_backlog_id,
    p_priority      => 'MEDIUM',
    p_estimated_min => 60,
    p_due_date      => TRUNC(SYSDATE) + 3,
    p_task_id       => v_task_a_id
  );

  task_mgmt_pkg.create_task_prc(
    p_project_id    => v_devops_project_id,
    p_board_id      => v_devops_main_board_id,
    p_column_id     => v_devops_backlog_col_id,
    p_sprint_id     => v_devops_sprint1_id,
    p_created_by    => v_dev_id,
    p_title         => 'DEVOPS Task B (BACKLOG)',
    p_description   => 'Teszt task B – BACKLOG oszlopban.',
    p_status_id     => v_status_backlog_id,
    p_priority      => 'LOW',
    p_estimated_min => 30,
    p_due_date      => TRUNC(SYSDATE) + 5,
    p_task_id       => v_task_b_id
  );

  task_mgmt_pkg.create_task_prc(
    p_project_id    => v_devops_project_id,
    p_board_id      => v_devops_main_board_id,
    p_column_id     => v_devops_todo_col_id,
    p_sprint_id     => v_devops_sprint1_id,
    p_created_by    => v_peter_id,
    p_title         => 'DEVOPS Task C (TODO)',
    p_description   => 'Teszt task C – TODO oszlopban (WIP=1).',
    p_status_id     => v_status_todo_id,
    p_priority      => 'HIGH',
    p_estimated_min => 90,
    p_due_date      => TRUNC(SYSDATE) + 2,
    p_task_id       => v_task_c_id
  );

  DBMS_OUTPUT.put_line('   - Három teszt task létrehozva (A,B BACKLOG, C TODO).');

  -- BACKLOG reorder
  task_mgmt_pkg.reorder_task_in_column_prc(
    p_task_id      => v_task_b_id,
    p_new_position => 1
  );

  SELECT position
    INTO l_pos
    FROM task
   WHERE id = v_task_b_id;

  IF l_pos = 1 THEN
    DBMS_OUTPUT.put_line('   - TASK reorder: OK (Task B pozíciója 1 a BACKLOG oszlopban).');
  ELSE
    DBMS_OUTPUT.put_line('   !! HIBA: TASK reorder – Task B pozíciója = ' || l_pos);
  END IF;
/* Igeiglenesen kommentelve
  -- WIP limit teszt – próbáljuk A-t TODO-ba mozgatni (már van C így hibának kell keletkeznie)
  BEGIN
    task_mgmt_pkg.move_task_to_column_prc(
      p_task_id       => v_task_a_id,
      p_new_column_id => v_devops_todo_col_id,
      p_actor_id      => v_peter_id,
      p_new_position  => NULL
    );
    DBMS_OUTPUT.put_line('   !! HIBA: WIP limit teszt – nem dobott hibát!');
  EXCEPTION
    WHEN pkg_exceptions.move_task_wip_exceeded THEN
      DBMS_OUTPUT.put_line('   - WIP limit teszt: OK (move_task_wip_exceeded).');
  END;
*/
  -- C lezárása, utána A áthelyezése TODO-ba (most már sikerülnie kell)
  UPDATE task
     SET closed_at = SYSDATE
   WHERE id = v_task_c_id;

  task_mgmt_pkg.move_task_to_column_prc(
    p_task_id       => v_task_a_id,
    p_new_column_id => v_devops_todo_col_id,
    p_actor_id      => v_peter_id,
    p_new_position  => NULL
  );

  SELECT column_id
    INTO l_col_id
    FROM task
   WHERE id = v_task_a_id;

  IF l_col_id = v_devops_todo_col_id THEN
    DBMS_OUTPUT.put_line('   - Task move: OK (Task A TODO oszlopba került WIP sértése nélkül).');
  ELSE
    DBMS_OUTPUT.put_line('   !! HIBA: Task move – Task A column_id=' || l_col_id ||
                         ', elvárt=' || v_devops_todo_col_id);
  END IF;

  DBMS_OUTPUT.put_line('---------------------------------------------------------');
  DBMS_OUTPUT.put_line('TEST 4 vége.');

EXCEPTION
  WHEN OTHERS THEN
    DBMS_OUTPUT.put_line('!! FATAL HIBA a TEST 4 futása közben: ' || SQLERRM);
    RAISE;
END;
/
