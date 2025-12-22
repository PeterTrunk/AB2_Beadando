CREATE OR REPLACE PROCEDURE assign_role_to_user_prc(p_user_id IN app_user.id%TYPE
                                                   ,p_role_id IN app_role.id%TYPE) IS
BEGIN
  INSERT INTO app_user_role
    (user_id
    ,role_id
    ,assigned_at)
  VALUES
    (p_user_id
    ,p_role_id
    ,SYSDATE);

EXCEPTION
  WHEN dup_val_on_index THEN
    raise_application_error(-20040,
                            'assign_role_to_user_prc: a szerepkör már hozzá van rendelve ehhez a userhez. ' ||
                            '(user_id = ' || p_user_id || ', role_id = ' ||
                            p_role_id || ')');
  WHEN OTHERS THEN
    raise_application_error(-20041,
                            'assign_role_to_user_prc hiba (user_id = ' ||
                            p_user_id || ', role_id = ' || p_role_id ||
                            '): ' || SQLERRM);
END;
/
