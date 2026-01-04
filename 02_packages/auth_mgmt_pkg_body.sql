CREATE OR REPLACE PACKAGE BODY auth_mgmt_pkg IS

  PROCEDURE create_role_prc(p_role_name   IN app_role.role_name%TYPE
                           ,p_description IN app_role.description%TYPE
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
    
      err_log_pkg.log_error(p_module_name    => 'AUTH',
                            p_procedure_name => 'create_role_prc',
                            p_error_code     => -20330,
                            p_error_msg      => 'Szerepkör név ütközik (ROLE_NAME).',
                            p_context        => 'role_name=' || p_role_name,
                            p_api            => NULL);
      RAISE pkg_exceptions.role_name_duplicate;
    
    WHEN OTHERS THEN
      err_log_pkg.log_error(p_module_name    => 'AUTH',
                            p_procedure_name => 'create_role_prc',
                            p_error_code     => SQLCODE,
                            p_error_msg      => SQLERRM,
                            p_context        => 'role_name=' || p_role_name,
                            p_api            => NULL);
      RAISE pkg_exceptions.role_generic_error;
  END create_role_prc;

  PROCEDURE create_user_prc(p_email         IN app_user.email%TYPE
                           ,p_display_name  IN app_user.display_name%TYPE
                           ,p_password_hash IN app_user.password_hash%TYPE
                           ,p_is_active     IN app_user.is_active%TYPE
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
      err_log_pkg.log_error(p_module_name    => 'AUTH',
                            p_procedure_name => 'create_user_prc',
                            p_error_code     => -20332,
                            p_error_msg      => 'Email ütközik (APP_USER.EMAIL).',
                            p_context        => 'email=' || p_email,
                            p_api            => NULL);
      RAISE pkg_exceptions.user_email_duplicate;
    
    WHEN OTHERS THEN
      err_log_pkg.log_error(p_module_name    => 'AUTH',
                            p_procedure_name => 'create_user_prc',
                            p_error_code     => SQLCODE,
                            p_error_msg      => SQLERRM,
                            p_context        => 'email=' || p_email,
                            p_api            => NULL);
      RAISE pkg_exceptions.user_generic_error;
  END create_user_prc;

  PROCEDURE assign_role_to_user_prc(p_user_id IN app_user_role.user_id%TYPE
                                   ,p_role_id IN app_user_role.role_id%TYPE) IS
  BEGIN
    INSERT INTO app_user_role
      (user_id
      ,role_id)
    VALUES
      (p_user_id
      ,p_role_id);
  
  EXCEPTION
    WHEN dup_val_on_index THEN
      err_log_pkg.log_error(p_module_name    => 'AUTH',
                            p_procedure_name => 'assign_role_to_user_prc',
                            p_error_code     => -20334,
                            p_error_msg      => 'User már rendelkezik ezzel a szerepkörrel.',
                            p_context        => 'user_id=' || p_user_id ||
                                                '; role_id=' || p_role_id,
                            p_api            => NULL);
      RAISE pkg_exceptions.user_role_duplicate;
    
    WHEN OTHERS THEN
      err_log_pkg.log_error(p_module_name    => 'AUTH',
                            p_procedure_name => 'assign_role_to_user_prc',
                            p_error_code     => SQLCODE,
                            p_error_msg      => SQLERRM,
                            p_context        => 'user_id=' || p_user_id ||
                                                '; role_id=' || p_role_id,
                            p_api            => NULL);
      RAISE pkg_exceptions.user_role_generic;
  END assign_role_to_user_prc;

END auth_mgmt_pkg;
/
