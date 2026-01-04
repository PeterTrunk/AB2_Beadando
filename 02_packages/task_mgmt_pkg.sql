CREATE OR REPLACE PACKAGE task_mgmt_pkg IS

  PROCEDURE create_task_prc(p_project_id    IN task.project_id%TYPE
                           ,p_board_id      IN task.board_id%TYPE
                           ,p_column_id     IN task.column_id%TYPE
                           ,p_sprint_id     IN task.sprint_id%TYPE
                           ,p_created_by    IN task.created_by%TYPE
                           ,p_title         IN task.title%TYPE
                           ,p_description   IN task.description%TYPE DEFAULT NULL
                           ,p_status_id     IN task.status_id%TYPE
                           ,p_priority      IN task.priority%TYPE DEFAULT NULL
                           ,p_estimated_min IN task.estimated_min%TYPE DEFAULT NULL
                           ,p_due_date      IN task.due_date%TYPE DEFAULT NULL
                           ,p_task_id       OUT task.id%TYPE);

  PROCEDURE assign_user_to_task_prc(p_task_id IN task_assignment.task_id%TYPE
                                   ,p_user_id IN task_assignment.user_id%TYPE);

  -- Task áthelyezése másik oszlopba (ugyanazon a boardon belül),
  -- p_new_position = NULL esetén az új oszlop végére kerül.
  PROCEDURE move_task_to_column_prc(p_task_id       IN task.id%TYPE
                                   ,p_new_column_id IN task.column_id%TYPE
                                   ,p_actor_id      IN task.created_by%TYPE
                                   ,p_new_position  IN task.position%TYPE DEFAULT NULL);

  -- Task sorrendjének módosítása az adott oszlopban
  PROCEDURE reorder_task_in_column_prc(p_task_id      IN task.id%TYPE
                                      ,p_new_position IN task.position%TYPE);

END task_mgmt_pkg;
/
