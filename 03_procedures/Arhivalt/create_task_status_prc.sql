CREATE OR REPLACE PROCEDURE create_task_status_prc(p_code        IN task_status.code%TYPE
                                                  ,p_name        IN task_status.name%TYPE
                                                  ,p_description IN task_status.description%TYPE DEFAULT NULL
                                                  ,p_is_final    IN task_status.is_final%TYPE
                                                  ,p_position    IN task_status.position%TYPE
                                                  ,p_status_id   OUT task_status.id%TYPE) IS
BEGIN
  INSERT INTO task_status
    (code
    ,NAME
    ,description
    ,is_final
    ,position)
  VALUES
    (p_code
    ,p_name
    ,p_description
    ,p_is_final
    ,p_position)
  RETURNING id INTO p_status_id;

EXCEPTION
  WHEN dup_val_on_index THEN
    raise_application_error(-20060,
                            'create_task_status_prc: status code "' ||
                            p_code || '" már létezik.');
  WHEN OTHERS THEN
    raise_application_error(-20061,
                            'create_task_status_prc hiba code = "' ||
                            p_code || '": ' || SQLERRM);
END;
/
