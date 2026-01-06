CREATE OR REPLACE PACKAGE BODY board_overview_pkg IS

  FUNCTION get_board_overview_fnc(p_board_id  IN board.id%TYPE
                                 ,p_sprint_id IN sprint.id%TYPE)
    RETURN ty_board_overview IS

    -- Board meta
    l_board_name       board.board_name%TYPE;
    l_board_project_id board.project_id%TYPE;

    -- Sprint meta
    l_sprint_name       sprint.sprint_name%TYPE;
    l_sprint_project_id sprint.project_id%TYPE;
    l_sprint_board_id   sprint.board_id%TYPE;

    -- Aggregált eredmény
    l_columns ty_column_overview_l := ty_column_overview_l();
    l_tasks   ty_task_overview_l;

  BEGIN
    ----------------------------------------------------------------
    -- Board metaadatok betöltése
    ----------------------------------------------------------------
    BEGIN
      SELECT board_name,
             project_id
        INTO l_board_name,
             l_board_project_id
        FROM board
       WHERE id = p_board_id;
    EXCEPTION
      WHEN no_data_found THEN
        err_log_pkg.log_error(
          p_module_name    => 'BOARD_OVERVIEW',
          p_procedure_name => 'get_board_overview_fnc',
          p_error_code     => -20310,
          p_error_msg      => 'Board not found',
          p_context        => 'board_id=' || p_board_id ||
                              '; sprint_id=' || p_sprint_id,
          p_api            => NULL
        );
        RAISE pkg_exceptions.board_overview_board_not_found;
    END;

    ----------------------------------------------------------------
    -- Sprint metaadatok betöltése
    ----------------------------------------------------------------
    BEGIN
      SELECT sprint_name,
             project_id,
             board_id
        INTO l_sprint_name,
             l_sprint_project_id,
             l_sprint_board_id
        FROM sprint
       WHERE id = p_sprint_id;
    EXCEPTION
      WHEN no_data_found THEN
        err_log_pkg.log_error(
          p_module_name    => 'BOARD_OVERVIEW',
          p_procedure_name => 'get_board_overview_fnc',
          p_error_code     => -20310,
          p_error_msg      => 'Sprint not found',
          p_context        => 'board_id=' || p_board_id ||
                              '; sprint_id=' || p_sprint_id,
          p_api            => NULL
        );
        RAISE pkg_exceptions.board_overview_board_not_found;
    END;

    ----------------------------------------------------------------
    -- Board–Sprint konzisztencia ellenõrzése
    ----------------------------------------------------------------
    IF l_sprint_board_id   <> p_board_id
       OR l_sprint_project_id <> l_board_project_id
    THEN
      err_log_pkg.log_error(
        p_module_name    => 'BOARD_OVERVIEW',
        p_procedure_name => 'get_board_overview_fnc',
        p_error_code     => -20311,
        p_error_msg      => 'Sprint does not belong to the given board/project',
        p_context        => 'board_id=' || p_board_id ||
                            '; board_project_id=' || l_board_project_id ||
                            '; sprint_id=' || p_sprint_id ||
                            '; sprint_board_id=' || l_sprint_board_id ||
                            '; sprint_project_id=' || l_sprint_project_id,
        p_api            => NULL
      );
      RAISE pkg_exceptions.board_overview_sprint_mismatch;
    END IF;

    ----------------------------------------------------------------
    -- Oszlopok bejárása a boardon
    ----------------------------------------------------------------
    FOR c_rec IN (
      SELECT c.id,
             c.column_name,
             c.wip_limit,
             ts.code AS status_code,
             ts.name AS status_name
        FROM column_def c
        JOIN task_status ts
          ON ts.id = c.status_id
       WHERE c.board_id = p_board_id
       ORDER BY c.position
    )
    LOOP
      l_tasks := ty_task_overview_l(); -- reset adott oszlophoz

      ----------------------------------------------------------------
      -- Taskok beolvasása az adott oszlophoz + sprinthez
      ----------------------------------------------------------------
      FOR t_rec IN (
        SELECT t.id,
               t.task_key,
               t.title,
               t.description,
               ts2.code       AS status_code,
               ts2.name       AS status_name,
               t.position     AS task_position,
               t.priority,
               t.last_modified AS last_modified,
               t.due_date,
               t.closed_at,
               u.id           AS created_by_id,
               u.display_name AS created_by_name,
               s.id           AS sprint_id,
               s.sprint_name,

               -- ASSIGNEES
               (SELECT listagg(u2.display_name, ', ')
                         WITHIN GROUP (ORDER BY u2.display_name)
                  FROM task_assignment ta
                  JOIN app_user u2
                    ON u2.id = ta.user_id
                 WHERE ta.task_id = t.id) AS assignees_text,

               -- ATTACHMENTS
               (SELECT COUNT(*)
                  FROM attachment a
                 WHERE a.task_id = t.id) AS attachment_count,

               (SELECT listagg(a.attachment_type, ', ')
                         WITHIN GROUP (ORDER BY a.attachment_type)
                  FROM attachment a
                 WHERE a.task_id = t.id) AS attachment_types,

               -- LABELS
               (SELECT listagg(l.label_name, ', ')
                         WITHIN GROUP (ORDER BY l.label_name)
                  FROM label_task lt
                  JOIN labels l
                    ON l.id = lt.label_id
                 WHERE lt.task_id = t.id) AS labels_text,

               -- GIT FLAGS
               CASE
                 WHEN EXISTS (SELECT 1
                                FROM commit_link cl
                               WHERE cl.task_id = t.id)
                 THEN 'Y'
                 ELSE 'N'
               END AS has_commit,

               CASE
                 WHEN EXISTS (SELECT 1
                                FROM pr_link pl
                               WHERE pl.task_id = t.id)
                 THEN 'Y'
                 ELSE 'N'
               END AS has_pr
          FROM task t
          JOIN task_status ts2
            ON ts2.id = t.status_id
          JOIN app_user u
            ON u.id = t.created_by
          LEFT JOIN sprint s
            ON s.id = t.sprint_id
         WHERE t.board_id  = p_board_id
           AND t.column_id = c_rec.id
           AND t.sprint_id = p_sprint_id
           AND t.closed_at IS NULL
         ORDER BY t.position
      )
      LOOP
        l_tasks.EXTEND;
        l_tasks(l_tasks.LAST) :=
          ty_task_overview(
            t_rec.id,
            t_rec.task_key,
            t_rec.title,
            t_rec.description,
            t_rec.status_code,
            t_rec.status_name,
            t_rec.task_position,
            t_rec.priority,
            t_rec.last_modified,
            t_rec.due_date,
            t_rec.closed_at,
            t_rec.created_by_id,
            t_rec.created_by_name,
            t_rec.sprint_id,
            t_rec.sprint_name,
            t_rec.assignees_text,
            t_rec.attachment_count,
            t_rec.attachment_types,
            t_rec.labels_text,
            t_rec.has_commit,
            t_rec.has_pr
          );
      END LOOP;

      ----------------------------------------------------------------
      -- Oszlop-objektum felvétele a listába
      ----------------------------------------------------------------
      l_columns.EXTEND;
      l_columns(l_columns.LAST) :=
        ty_column_overview(
          c_rec.id,
          c_rec.column_name,
          c_rec.wip_limit,
          c_rec.status_code,
          c_rec.status_name,
          l_tasks
        );
    END LOOP;

    ----------------------------------------------------------------
    -- Board_overview objektum összeállítása
    ----------------------------------------------------------------
    RETURN ty_board_overview(
      p_board_id,
      l_board_name,
      p_sprint_id,
      l_sprint_name,
      l_columns
    );

  EXCEPTION
    WHEN pkg_exceptions.board_overview_board_not_found
         OR pkg_exceptions.board_overview_sprint_mismatch
    THEN
      RAISE;

    WHEN OTHERS THEN
      err_log_pkg.log_error(
        p_module_name    => 'BOARD_OVERVIEW',
        p_procedure_name => 'get_board_overview_fnc',
        p_error_code     => SQLCODE,
        p_error_msg      => SQLERRM,
        p_context        => 'board_id=' || p_board_id ||
                            '; sprint_id=' || p_sprint_id,
        p_api            => NULL
      );
      RAISE pkg_exceptions.board_overview_generic;
  END get_board_overview_fnc;

END board_overview_pkg;
/
