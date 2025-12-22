CREATE OR REPLACE PROCEDURE assign_user_to_project_prc(p_project_id   IN project_member.project_id%TYPE
                                                      ,p_user_id      IN project_member.user_id%TYPE
                                                      ,p_project_role IN project_member.project_role%TYPE DEFAULT NULL) IS
BEGIN
  INSERT INTO project_member
    (project_id
    ,user_id
    ,project_role)
  VALUES
    (p_project_id
    ,p_user_id
    ,p_project_role);

EXCEPTION
  WHEN dup_val_on_index THEN
    raise_application_error(-20050,
                            'assign_user_to_project_prc: a felhasználó már tagja a projektnek. ' ||
                            '(project_id = ' || p_project_id ||
                            ', user_id = ' || p_user_id || ')');
  
  WHEN OTHERS THEN
    raise_application_error(-20051,
                            'assign_user_to_project_prc hiba (project_id = ' ||
                            p_project_id || ', user_id = ' || p_user_id ||
                            '): ' || SQLERRM);
END;
/
