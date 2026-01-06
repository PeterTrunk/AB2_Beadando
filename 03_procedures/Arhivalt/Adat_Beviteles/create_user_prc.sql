CREATE OR REPLACE PROCEDURE create_user_prc(p_email         IN app_user.email%TYPE
                                           ,p_display_name  IN app_user.display_name%TYPE
                                           ,p_password_hash IN app_user.password_hash%TYPE
                                           ,p_is_active     IN NUMBER DEFAULT 1
                                           ,p_user_id       OUT app_user.id%TYPE) IS
BEGIN
  INSERT INTO app_user
    (email
    ,display_name
    ,password_hash
    ,is_active)
  VALUES
    (p_email
    ,p_display_name
    ,p_password_hash
    ,p_is_active)
  RETURNING id INTO p_user_id;

EXCEPTION
  WHEN dup_val_on_index THEN
    raise_application_error(-20030,
                            'create_user_prc: email "' || p_email ||
                            '" már létezik.');
  WHEN OTHERS THEN
    raise_application_error(-20031,
                            'create_user_prc hiba email = "' || p_email ||
                            '": ' || SQLERRM);
END;
/
