CREATE OR REPLACE PACKAGE BODY task_autofill_pkg IS
  g_autofill_running BOOLEAN := FALSE;

  PROCEDURE fill_todo_from_backlog IS
    -- TODO / BACKLOG oszlopok
    l_todo_column_id    column_def.id%TYPE;
    l_backlog_column_id column_def.id%TYPE;
    l_wip_limit         column_def.wip_limit%TYPE;
  
    l_task_to_move task.id%TYPE;
    l_actor_id     task.created_by%TYPE;
  BEGIN
    -- Ha már futunk (másik trigger hívásból), ne induljunk újra
    IF g_autofill_running
    THEN
      RETURN;
    END IF;
  
    g_autofill_running := TRUE;
  
    ----------------------------------------------------------------
    -- 1. Keresünk EGY olyan boardot, ahol:
    --    - van TODO oszlop wip_limit-tel,
    --    - a TODO-ban kevesebb aktív task van, mint a limit,
    --    - és van BACKLOG oszlop, amiben van aktív task.
    ----------------------------------------------------------------
    BEGIN
      SELECT c_todo.id
            ,c_backlog.id
            ,c_todo.wip_limit
        INTO l_todo_column_id
            ,l_backlog_column_id
            ,l_wip_limit
        FROM column_def c_todo
        JOIN task_status s_todo
          ON s_todo.id = c_todo.status_id
         AND s_todo.code = 'TODO'
        JOIN column_def c_backlog
          ON c_backlog.board_id = c_todo.board_id
        JOIN task_status s_backlog
          ON s_backlog.id = c_backlog.status_id
         AND s_backlog.code = 'BACKLOG'
       WHERE c_todo.wip_limit IS NOT NULL
         AND c_todo.wip_limit > 0
         AND EXISTS (SELECT 1
                FROM task t_b
               WHERE t_b.column_id = c_backlog.id
                 AND t_b.closed_at IS NULL)
         AND (SELECT COUNT(*)
                FROM task t_t
               WHERE t_t.column_id = c_todo.id
                 AND t_t.closed_at IS NULL) < c_todo.wip_limit
         AND rownum = 1; -- csak EGY board/oszloppár
    EXCEPTION
      WHEN no_data_found THEN
        -- Nincs olyan board/oszlop, amit tölteni kellene → NEM hiba, simán kilépünk
        g_autofill_running := FALSE;
        RETURN;
    END;
  
    ----------------------------------------------------------------
    -- 2. Válasszunk EGY taskot a backlogból
    --    (pozíció + last_modified szerint)
    ----------------------------------------------------------------
    BEGIN
      SELECT id
            ,created_by
        INTO l_task_to_move
            ,l_actor_id
        FROM (SELECT id
                    ,created_by
                FROM task
               WHERE column_id = l_backlog_column_id
                 AND closed_at IS NULL
               ORDER BY position
                       ,last_modified -- <-- Itt javítottuk
              )
       WHERE rownum = 1;
    EXCEPTION
      WHEN no_data_found THEN
        -- Közben esetleg eltűnt a backlog task → ez sem igazi hiba
        g_autofill_running := FALSE;
        RETURN;
    END;
  
    ----------------------------------------------------------------
    -- 3. Task áthelyezése backlogból To Do-ba
    ----------------------------------------------------------------
    task_mgmt_pkg.move_task_to_column_prc(p_task_id       => l_task_to_move,
                                          p_new_column_id => l_todo_column_id,
                                          p_actor_id      => l_actor_id,
                                          p_new_position  => NULL -- To Do oszlop vége
                                          );
  
    g_autofill_running := FALSE;
  
  EXCEPTION
    WHEN pkg_exceptions.move_task_board_mismatch
         OR pkg_exceptions.move_task_wip_exceeded
         OR pkg_exceptions.move_task_not_found THEN
      g_autofill_running := FALSE;
    
      err_log_pkg.log_error(p_module_name    => 'TASK_AUTOFILL',
                            p_procedure_name => 'fill_todo_from_backlog',
                            p_error_code     => SQLCODE,
                            p_error_msg      => SQLERRM,
                            p_context        => 'task_id=' ||
                                                nvl(to_char(l_task_to_move),
                                                    'NULL') || '; todo_col=' ||
                                                nvl(to_char(l_todo_column_id),
                                                    'NULL') ||
                                                '; backlog_col=' ||
                                                nvl(to_char(l_backlog_column_id),
                                                    'NULL'),
                            p_api            => NULL);
    
      RAISE; -- ugyanazt továbbdobjuk
  
    WHEN OTHERS THEN
      g_autofill_running := FALSE;
    
      err_log_pkg.log_error(p_module_name    => 'TASK_AUTOFILL',
                            p_procedure_name => 'fill_todo_from_backlog',
                            p_error_code     => SQLCODE,
                            p_error_msg      => SQLERRM,
                            p_context        => 'task_id=' ||
                                                nvl(to_char(l_task_to_move),
                                                    'NULL') || '; todo_col=' ||
                                                nvl(to_char(l_todo_column_id),
                                                    'NULL') ||
                                                '; backlog_col=' ||
                                                nvl(to_char(l_backlog_column_id),
                                                    'NULL'),
                            p_api            => NULL);
      RAISE pkg_exceptions.move_task_generic;
  END fill_todo_from_backlog;

END task_autofill_pkg;
/
