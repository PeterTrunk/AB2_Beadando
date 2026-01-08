CREATE OR REPLACE PACKAGE BODY project_mgmt_pkg IS

  PROCEDURE create_project_prc(p_project_name IN app_project.project_name%TYPE
                              ,p_proj_key     IN app_project.proj_key%TYPE
                              ,p_description  IN app_project.description%TYPE
                              ,p_owner_id     IN app_project.owner_id%TYPE
                              ,p_project_id   OUT app_project.id%TYPE) IS
    l_owner_exists NUMBER;
    l_seq_name     app_project.task_seq_name%TYPE;
    l_activity_id  app_activity.id%TYPE;
  BEGIN
    ----------------------------------------------------------------
    -- Owner user létezésének ellenőrzése
    ----------------------------------------------------------------
    SELECT COUNT(*)
      INTO l_owner_exists
      FROM app_user
     WHERE id = p_owner_id;
  
    IF l_owner_exists = 0
    THEN
      err_log_pkg.log_error(p_module_name    => 'PROJECT',
                            p_procedure_name => 'create_project_prc',
                            p_error_code     => -20340,
                            p_error_msg      => 'Owner user nem létezik.',
                            p_context        => 'owner_id=' || p_owner_id ||
                                                '; project_name=' ||
                                                p_project_name,
                            p_api            => NULL);
      RAISE pkg_exceptions.project_owner_not_found;
    END IF;
  
    ----------------------------------------------------------------
    -- Sequence név generálása a PROJ_KEY alapján
    ----------------------------------------------------------------
    l_seq_name := util_pkg.build_task_seq_name_fnc(p_proj_key);
  
    ----------------------------------------------------------------
    -- Projekt beszúrása, task_seq_name eltárolása
    ----------------------------------------------------------------
    INSERT INTO app_project
      (project_name
      ,proj_key
      ,description
      ,owner_id
      ,task_seq_name)
    VALUES
      (p_project_name
      ,p_proj_key
      ,p_description
      ,p_owner_id
      ,l_seq_name)
    RETURNING id INTO p_project_id;
  
    ----------------------------------------------------------------
    -- A projekt saját task sequence-ének létrehozása
    ----------------------------------------------------------------
    BEGIN
      EXECUTE IMMEDIATE 'CREATE SEQUENCE ' || l_seq_name ||
                        ' START WITH 1 INCREMENT BY 1';  
    END;
  
    ----------------------------------------------------------------
    -- Activity log
    ----------------------------------------------------------------
    BEGIN
      activity_log_pkg.log_project_created_prc(p_project_id  => p_project_id,
                                               p_actor_id    => p_owner_id,
                                               p_activity_id => l_activity_id);
    EXCEPTION
      WHEN OTHERS THEN
        NULL;
    END;
  
  EXCEPTION
    WHEN dup_val_on_index THEN
      err_log_pkg.log_error(p_module_name    => 'PROJECT',
                            p_procedure_name => 'create_project_prc',
                            p_error_code     => -20341,
                            p_error_msg      => 'Projekt kulcs ütközik (PROJ_KEY).',
                            p_context        => 'proj_key=' || p_proj_key,
                            p_api            => NULL);
      RAISE pkg_exceptions.project_key_duplicate;
    
    WHEN OTHERS THEN
      err_log_pkg.log_error(p_module_name    => 'PROJECT',
                            p_procedure_name => 'create_project_prc',
                            p_error_code     => SQLCODE,
                            p_error_msg      => SQLERRM,
                            p_context        => 'project_name=' ||
                                                p_project_name ||
                                                '; proj_key=' || p_proj_key,
                            p_api            => NULL);
      RAISE pkg_exceptions.project_create_generic;
  END create_project_prc;

  PROCEDURE assign_user_to_project_prc(p_project_id   IN project_member.project_id%TYPE
                                      ,p_user_id      IN project_member.user_id%TYPE
                                      ,p_project_role IN project_member.project_role%TYPE) IS
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
      err_log_pkg.log_error(p_module_name    => 'PROJECT',
                            p_procedure_name => 'assign_user_to_project_prc',
                            p_error_code     => -20343,
                            p_error_msg      => 'User már tagja ennek a projektnek.',
                            p_context        => 'project_id=' ||
                                                p_project_id || '; user_id=' ||
                                                p_user_id,
                            p_api            => NULL);
      RAISE pkg_exceptions.project_member_duplicate;
    
    WHEN OTHERS THEN
      err_log_pkg.log_error(p_module_name    => 'PROJECT',
                            p_procedure_name => 'assign_user_to_project_prc',
                            p_error_code     => SQLCODE,
                            p_error_msg      => SQLERRM,
                            p_context        => 'project_id=' ||
                                                p_project_id || '; user_id=' ||
                                                p_user_id,
                            p_api            => NULL);
      RAISE pkg_exceptions.project_member_generic;
  END assign_user_to_project_prc;

END project_mgmt_pkg;
/
