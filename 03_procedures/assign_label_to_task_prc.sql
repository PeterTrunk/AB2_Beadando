CREATE OR REPLACE PROCEDURE assign_label_to_task_prc(p_task_id  IN label_task.task_id%TYPE
                                                    ,p_label_id IN label_task.label_id%TYPE) IS
BEGIN
  INSERT INTO label_task
    (task_id
    ,label_id)
  VALUES
    (p_task_id
    ,p_label_id);

EXCEPTION
  WHEN dup_val_on_index THEN
    raise_application_error(-20130,
                            'assign_label_to_task_prc: ez a label már rá van téve a taskra. ' ||
                            '(task_id = ' || p_task_id || ', label_id = ' ||
                            p_label_id || ')');
  WHEN OTHERS THEN
    raise_application_error(-20131,
                            'assign_label_to_task_prc hiba (task_id = ' ||
                            p_task_id || ', label_id = ' || p_label_id ||
                            '): ' || SQLERRM);
END;
/
