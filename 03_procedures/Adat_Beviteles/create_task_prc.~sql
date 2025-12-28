CREATE OR REPLACE PROCEDURE create_task_prc(p_project_id    IN task.project_id%TYPE
                                           ,p_board_id      IN task.board_id%TYPE
                                           ,p_column_id     IN task.column_id%TYPE
                                           ,p_sprint_id     IN task.sprint_id%TYPE
                                           ,p_created_by    IN task.created_by%TYPE
                                           ,p_title         IN task.title%TYPE
                                           ,p_description   IN task.description%TYPE DEFAULT NULL
                                           ,p_status_id        IN task.status_id%TYPE
                                           ,p_priority      IN task.priority%TYPE DEFAULT NULL
                                           ,p_estimated_min IN task.estimated_min%TYPE DEFAULT NULL
                                           ,p_due_date      IN task.due_date%TYPE DEFAULT NULL
                                           ,p_task_id       OUT task.id%TYPE) IS
  l_task_key task.task_key%TYPE;
BEGIN
  ------------------------------------------------------------------
  -- 1. Task key generálása projekt alapján (PMA-0001, DEVOPS-0001, ...)
  ------------------------------------------------------------------
  l_task_key := build_next_task_key_fnc(p_project_id);

  ------------------------------------------------------------------
  -- 2. Task beszúrása
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
    ,created_by)
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
    ,p_created_by)
  RETURNING id INTO p_task_id;

EXCEPTION
  WHEN dup_val_on_index THEN
    raise_application_error(-20100,
                            'create_task_prc: ütközés az egyedi constrainten (valószínûleg task_key). ' ||
                            '(project_id = ' || p_project_id ||
                            ', task_key = "' || l_task_key || '")');
  WHEN OTHERS THEN
    raise_application_error(-20101,
                            'create_task_prc hiba (project_id = ' ||
                            p_project_id || ', title = "' || p_title ||
                            '"): ' || SQLERRM);
END;
/
