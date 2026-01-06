CREATE OR REPLACE PACKAGE BODY task_mgmt_pkg IS

  --------------------------------------------------------------------
  -- TASK LÉTREHOZÁS
  --------------------------------------------------------------------
  PROCEDURE create_task_prc(p_project_id    IN task.project_id%TYPE
                           ,p_board_id      IN task.board_id%TYPE
                           ,p_column_id     IN task.column_id%TYPE
                           ,p_sprint_id     IN task.sprint_id%TYPE
                           ,p_created_by    IN task.created_by%TYPE
                           ,p_title         IN task.title%TYPE
                           ,p_description   IN task.description%TYPE
                           ,p_status_id     IN task.status_id%TYPE
                           ,p_priority      IN task.priority%TYPE
                           ,p_estimated_min IN task.estimated_min%TYPE
                           ,p_due_date      IN task.due_date%TYPE
                           ,p_task_id       OUT task.id%TYPE) IS
    l_task_key task.task_key%TYPE;
    l_position task.position%TYPE;
  BEGIN
    ------------------------------------------------------------------
    -- 1. Task key generálása projekt alapján (PMA-0001, DEVOPS-0001…)
    ------------------------------------------------------------------
    l_task_key := build_next_task_key_fnc(p_project_id);
  
    ------------------------------------------------------------------
    -- 2. POSITION meghatározása az oszlopon belül
    ------------------------------------------------------------------
    SELECT nvl(MAX(position), 0) + 1
      INTO l_position
      FROM task
     WHERE column_id = p_column_id;
  
    ------------------------------------------------------------------
    -- 3. Task beszúrása
    ------------------------------------------------------------------
    INSERT INTO task
      (project_id
      ,board_id
      ,column_id
      ,sprint_id
      ,task_key
      ,title
      ,description
      ,status_id
      ,priority
      ,estimated_min
      ,due_date
      ,created_by
      ,position)
    VALUES
      (p_project_id
      ,p_board_id
      ,p_column_id
      ,p_sprint_id
      ,l_task_key
      ,p_title
      ,p_description
      ,p_status_id
      ,p_priority
      ,p_estimated_min
      ,p_due_date
      ,p_created_by
      ,l_position)
    RETURNING id INTO p_task_id;
  
    --Activity Log
    DECLARE
      l_activity_id app_activity.id%TYPE;
    BEGIN
      activity_log_pkg.log_activity_prc(p_project_id  => p_project_id,
                                        p_actor_id    => p_created_by,
                                        p_entity_type => 'TASK',
                                        p_entity_id   => p_task_id,
                                        p_action      => 'TASK_CREATE',
                                        p_payload     => 'Task létrehozva: ' ||
                                                         p_title,
                                        p_activity_id => l_activity_id);
    END;
  
  EXCEPTION
    WHEN dup_val_on_index THEN
      -- tipikusan TASK_KEY egyedi constraint sérül
      err_log_pkg.log_error(p_module_name    => 'TASK',
                            p_procedure_name => 'create_task_prc',
                            p_error_code     => -20100,
                            p_error_msg      => 'Ütközés az egyedi constrainten (valószínûleg TASK_KEY).',
                            p_context        => 'project_id=' ||
                                                p_project_id ||
                                                '; column_id=' ||
                                                p_column_id || '; task_key=' ||
                                                l_task_key,
                            p_api            => NULL);
      RAISE pkg_exceptions.create_task_dup;
    
    WHEN OTHERS THEN
      err_log_pkg.log_error(p_module_name    => 'TASK',
                            p_procedure_name => 'create_task_prc',
                            p_error_code     => SQLCODE,
                            p_error_msg      => SQLERRM,
                            p_context        => 'project_id=' ||
                                                p_project_id ||
                                                '; board_id=' || p_board_id ||
                                                '; column_id=' ||
                                                p_column_id || '; title=' ||
                                                p_title,
                            p_api            => NULL);
      RAISE pkg_exceptions.create_task_generic;
  END create_task_prc;

  --------------------------------------------------------------------
  -- TASK–USER HOZZÁRENDELÉS
  --------------------------------------------------------------------
  PROCEDURE assign_user_to_task_prc(p_task_id IN task_assignment.task_id%TYPE
                                   ,p_user_id IN task_assignment.user_id%TYPE) IS
  BEGIN
    INSERT INTO task_assignment
      (task_id
      ,user_id
      ,assigned_at)
    VALUES
      (p_task_id
      ,p_user_id
      ,SYSDATE);
  
  EXCEPTION
    WHEN dup_val_on_index THEN
      err_log_pkg.log_error(p_module_name    => 'TASK',
                            p_procedure_name => 'assign_user_to_task_prc',
                            p_error_code     => -20110,
                            p_error_msg      => 'A user már hozzá van rendelve ehhez a taskhoz.',
                            p_context        => 'task_id=' || p_task_id ||
                                                '; user_id=' || p_user_id,
                            p_api            => NULL);
      RAISE pkg_exceptions.assign_user_already_assigned;
    
    WHEN OTHERS THEN
      err_log_pkg.log_error(p_module_name    => 'TASK',
                            p_procedure_name => 'assign_user_to_task_prc',
                            p_error_code     => SQLCODE,
                            p_error_msg      => SQLERRM,
                            p_context        => 'task_id=' || p_task_id ||
                                                '; user_id=' || p_user_id,
                            p_api            => NULL);
      RAISE pkg_exceptions.assign_user_generic;
  END assign_user_to_task_prc;

  --------------------------------------------------------------------
  -- TASK MOZGATÁS / SORRENDEZÉS
  --------------------------------------------------------------------
  PROCEDURE move_task_to_column_prc(p_task_id       IN task.id%TYPE
                                   ,p_new_column_id IN task.column_id%TYPE
                                   ,p_actor_id      IN task.created_by%TYPE
                                   ,p_new_position  IN task.position%TYPE) IS
    l_old_column_id task.column_id%TYPE;
    l_old_board_id  task.board_id%TYPE;
    l_old_position  task.position%TYPE;
    l_old_status_id task.status_id%TYPE;
    l_project_id    task.project_id%TYPE;
  
    l_new_board_id  column_def.board_id%TYPE;
    l_new_status_id column_def.status_id%TYPE;
    l_wip_limit     column_def.wip_limit%TYPE;
  
    l_active_count   NUMBER;
    l_final_position task.position%TYPE;
    
    -- Activity Logoláshoz
    l_old_status_code task_status.code%TYPE;
    l_new_status_code task_status.code%TYPE;
    l_activity_id     app_activity.id%TYPE;
  BEGIN
    ------------------------------------------------------------------
    -- 0. Pozíció alap validáció (ha meg van adva)
    ------------------------------------------------------------------
    IF p_new_position IS NOT NULL
       AND p_new_position < 1
    THEN
      err_log_pkg.log_error(p_module_name    => 'TASK',
                            p_procedure_name => 'move_task_to_column_prc',
                            p_error_code     => -20212,
                            p_error_msg      => 'Új pozíció nem lehet 1-nél kisebb.',
                            p_context        => 'task_id=' || p_task_id ||
                                                '; new_column_id=' ||
                                                p_new_column_id ||
                                                '; new_position=' ||
                                                p_new_position,
                            p_api            => NULL);
      RAISE pkg_exceptions.move_task_pos_invalid;
    END IF;
  
    ------------------------------------------------------------------
    -- 1. Task jelenlegi adatai
    ------------------------------------------------------------------
    SELECT column_id
          ,board_id
          ,position
          ,status_id
          ,project_id
      INTO l_old_column_id
          ,l_old_board_id
          ,l_old_position
          ,l_old_status_id
          ,l_project_id
      FROM task
     WHERE id = p_task_id;
  
    ------------------------------------------------------------------
    -- 2. Ha ugyanabba az oszlopba mozgatjuk, az csak sorrendezés
    ------------------------------------------------------------------
    IF p_new_column_id = l_old_column_id
    THEN
      IF p_new_position IS NOT NULL
         AND p_new_position <> l_old_position
      THEN
        reorder_task_in_column_prc(p_task_id      => p_task_id,
                                   p_new_position => p_new_position);
      END IF;
      RETURN;
    END IF;
  
    ------------------------------------------------------------------
    -- 3. Új oszlop adatai (board, státusz, WIP limit)
    ------------------------------------------------------------------
    SELECT board_id
          ,status_id
          ,wip_limit
      INTO l_new_board_id
          ,l_new_status_id
          ,l_wip_limit
      FROM column_def
     WHERE id = p_new_column_id;
  
    -- Nem engedjük másik boardra mozgatni a taskot
    IF l_new_board_id <> l_old_board_id
    THEN
      err_log_pkg.log_error(p_module_name    => 'TASK',
                            p_procedure_name => 'move_task_to_column_prc',
                            p_error_code     => -20210,
                            p_error_msg      => 'Task csak ugyanazon a boardon belül mozgatható.',
                            p_context        => 'task_id=' || p_task_id ||
                                                '; old_board_id=' ||
                                                l_old_board_id ||
                                                '; new_board_id=' ||
                                                l_new_board_id,
                            p_api            => NULL);
      RAISE pkg_exceptions.move_task_board_mismatch;
    END IF;
  
    ------------------------------------------------------------------
    -- 4. WIP limit ellenõrzés az új oszlopban
    ------------------------------------------------------------------
    IF l_wip_limit IS NOT NULL
       AND l_wip_limit > 0
    THEN
      SELECT COUNT(*)
        INTO l_active_count
        FROM task
       WHERE column_id = p_new_column_id
         AND closed_at IS NULL;
    
      IF l_active_count >= l_wip_limit
      THEN
        err_log_pkg.log_error(p_module_name    => 'TASK',
                              p_procedure_name => 'move_task_to_column_prc',
                              p_error_code     => -20211,
                              p_error_msg      => 'WIP limit elérve az új oszlopban.',
                              p_context        => 'task_id=' || p_task_id ||
                                                  '; new_column_id=' ||
                                                  p_new_column_id ||
                                                  '; wip_limit=' ||
                                                  l_wip_limit ||
                                                  '; active_count=' ||
                                                  l_active_count,
                              p_api            => NULL);
        RAISE pkg_exceptions.move_task_wip_exceeded;
      END IF;
    END IF;
  
    ------------------------------------------------------------------
    -- 5. Régi oszlop pozícióinak "összehúzása"
    ------------------------------------------------------------------
    UPDATE task
       SET position = position - 1
     WHERE column_id = l_old_column_id
       AND position > l_old_position;
  
    ------------------------------------------------------------------
    -- 6. Új oszlopban végsõ pozíció meghatározása
    ------------------------------------------------------------------
    IF p_new_position IS NULL
    THEN
      -- Ha nincs megadva új pozíció, az oszlop végére kerül
      SELECT nvl(MAX(position), 0) + 1
        INTO l_final_position
        FROM task
       WHERE column_id = p_new_column_id;
    ELSE
      -- Hely felszabadítása az új oszlopban a megadott pozícióra
      UPDATE task
         SET position = position + 1
       WHERE column_id = p_new_column_id
         AND position >= p_new_position;
    
      l_final_position := p_new_position;
    END IF;
  
    ------------------------------------------------------------------
    -- 7. Task frissítése: új oszlop, új státusz, új pozíció
    ------------------------------------------------------------------
    UPDATE task
       SET column_id = p_new_column_id
          ,status_id = l_new_status_id
          ,position  = l_final_position
     WHERE id = p_task_id;
  
    -- p_actor_id: késõbbi használat activity loghoz
  
    -- Activity Log
    IF p_actor_id IS NOT NULL
    THEN
      BEGIN
        SELECT code
          INTO l_old_status_code
          FROM task_status
         WHERE id = l_old_status_id;
      
        SELECT code
          INTO l_new_status_code
          FROM task_status
         WHERE id = l_new_status_id;
      
        activity_log_pkg.log_task_status_change_prc(p_project_id      => l_project_id,
                                                    p_actor_id        => p_actor_id,
                                                    p_task_id         => p_task_id,
                                                    p_old_status_code => l_old_status_code,
                                                    p_new_status_code => l_new_status_code,
                                                    p_activity_id     => l_activity_id);
      END;
    END IF;
  
  EXCEPTION
    WHEN no_data_found THEN
      -- Vagy a task, vagy az új oszlop nem található
      err_log_pkg.log_error(p_module_name    => 'TASK',
                            p_procedure_name => 'move_task_to_column_prc',
                            p_error_code     => -20213,
                            p_error_msg      => 'Task vagy oszlop nem található.',
                            p_context        => 'task_id=' || p_task_id ||
                                                '; new_column_id=' ||
                                                p_new_column_id,
                            p_api            => NULL);
      RAISE pkg_exceptions.move_task_not_found;
    
    WHEN OTHERS THEN
      err_log_pkg.log_error(p_module_name    => 'TASK',
                            p_procedure_name => 'move_task_to_column_prc',
                            p_error_code     => SQLCODE,
                            p_error_msg      => SQLERRM,
                            p_context        => 'task_id=' || p_task_id ||
                                                '; new_column_id=' ||
                                                p_new_column_id,
                            p_api            => NULL);
      RAISE pkg_exceptions.move_task_generic;
  END move_task_to_column_prc;

  --------------------------------------------------------------------
  -- TASK SORRENDEZÉS OSZLOPON BELÜL
  --------------------------------------------------------------------
  PROCEDURE reorder_task_in_column_prc(p_task_id      IN task.id%TYPE
                                      ,p_new_position IN task.position%TYPE) IS
    l_column_id task.column_id%TYPE;
    l_old_pos   task.position%TYPE;
  BEGIN
    IF p_new_position < 1
    THEN
      err_log_pkg.log_error(p_module_name    => 'TASK',
                            p_procedure_name => 'reorder_task_in_column_prc',
                            p_error_code     => -20220,
                            p_error_msg      => 'A pozíció nem lehet 1-nél kisebb.',
                            p_context        => 'task_id=' || p_task_id ||
                                                '; new_position=' ||
                                                p_new_position,
                            p_api            => NULL);
      RAISE pkg_exceptions.reorder_task_pos_invalid;
    END IF;
  
    ------------------------------------------------------------------
    -- 1. Task jelenlegi oszlopa és pozíciója
    ------------------------------------------------------------------
    SELECT column_id
          ,position
      INTO l_column_id
          ,l_old_pos
      FROM task
     WHERE id = p_task_id;
  
    IF p_new_position = l_old_pos
    THEN
      RETURN; -- nincs változás
    END IF;
  
    ------------------------------------------------------------------
    -- 2. Az adott oszlop többi taskjának pozíció-korrekciója
    ------------------------------------------------------------------
    IF p_new_position < l_old_pos
    THEN
      -- Felfelé mozgatjuk: a köztes taskok lejjebb csúsznak (pos+1)
      UPDATE task
         SET position = position + 1
       WHERE column_id = l_column_id
         AND position >= p_new_position
         AND position < l_old_pos;
    ELSE
      -- Lefelé mozgatjuk: a köztes taskok feljebb csúsznak (pos-1)
      UPDATE task
         SET position = position - 1
       WHERE column_id = l_column_id
         AND position <= p_new_position
         AND position > l_old_pos;
    END IF;
  
    ------------------------------------------------------------------
    -- 3. Kijelölt task új pozíciója
    ------------------------------------------------------------------
    UPDATE task SET position = p_new_position WHERE id = p_task_id;
  
  EXCEPTION
    WHEN no_data_found THEN
      err_log_pkg.log_error(p_module_name    => 'TASK',
                            p_procedure_name => 'reorder_task_in_column_prc',
                            p_error_code     => -20221,
                            p_error_msg      => 'A megadott task nem található.',
                            p_context        => 'task_id=' || p_task_id ||
                                                '; new_position=' ||
                                                p_new_position,
                            p_api            => NULL);
      RAISE pkg_exceptions.reorder_task_not_found;
    
    WHEN OTHERS THEN
      err_log_pkg.log_error(p_module_name    => 'TASK',
                            p_procedure_name => 'reorder_task_in_column_prc',
                            p_error_code     => SQLCODE,
                            p_error_msg      => SQLERRM,
                            p_context        => 'task_id=' || p_task_id ||
                                                '; new_position=' ||
                                                p_new_position,
                            p_api            => NULL);
      RAISE pkg_exceptions.reorder_task_generic;
  END reorder_task_in_column_prc;

END task_mgmt_pkg;
/
