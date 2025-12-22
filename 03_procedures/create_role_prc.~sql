CREATE OR REPLACE PROCEDURE create_role_prc(p_role_name   IN app_role.role_name%TYPE
                                           ,p_description IN app_role.description%TYPE DEFAULT NULL
                                           ,p_role_id     OUT app_role.id%TYPE) IS
BEGIN
  INSERT INTO app_role
    (role_name
    ,description)
  VALUES
    (p_role_name
    ,p_description)
  RETURNING id INTO p_role_id;

EXCEPTION
  WHEN dup_val_on_index THEN
    raise_application_error(-20020,
                            'create_role_prc: role_name "' || p_role_name ||
                            '" már létezik.');
  WHEN OTHERS THEN
    raise_application_error(-20021,
                            'create_role_prc hiba role_name = "' ||
                            p_role_name || '": ' || SQLERRM);
END;
/
