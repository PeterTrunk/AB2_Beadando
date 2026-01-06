CREATE OR REPLACE PROCEDURE assign_user_to_task_prc(p_task_id IN task_assignment.task_id%TYPE
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
    raise_application_error(-20110,
                            'assign_user_to_task_prc: a user már hozzá van rendelve ehhez a taskhoz. ' ||
                            '(task_id = ' || p_task_id || ', user_id = ' ||
                            p_user_id || ')');
  WHEN OTHERS THEN
    raise_application_error(-20111,
                            'assign_user_to_task_prc hiba (task_id = ' ||
                            p_task_id || ', user_id = ' || p_user_id ||
                            '): ' || SQLERRM);
END;
/
