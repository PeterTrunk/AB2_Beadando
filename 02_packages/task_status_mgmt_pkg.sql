CREATE OR REPLACE PACKAGE task_status_mgmt_pkg IS
  -- ELső Visszajelzés utáni...

  PROCEDURE create_task_status_prc(p_code        IN task_status.code%TYPE
                                  ,p_name        IN task_status.name%TYPE
                                  ,p_description IN task_status.description%TYPE
                                  ,p_is_final    IN task_status.is_final%TYPE
                                  ,p_position    IN task_status.position%TYPE
                                  ,p_status_id   OUT task_status.id%TYPE);

END task_status_mgmt_pkg;
/
