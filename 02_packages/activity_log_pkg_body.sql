CREATE OR REPLACE PACKAGE BODY activity_log_pkg IS

  -- Általános logoló

  PROCEDURE log_activity_prc(p_project_id  IN app_activity.project_id%TYPE
                            ,p_actor_id    IN app_activity.actor_id%TYPE
                            ,p_entity_type IN app_activity.entity_type%TYPE
                            ,p_entity_id   IN app_activity.entity_id%TYPE
                            ,p_action      IN app_activity.action%TYPE
                            ,p_payload     IN app_activity.payload%TYPE DEFAULT NULL
                            ,p_activity_id OUT app_activity.id%TYPE) IS
    l_proj_cnt    NUMBER;
    l_actor_cnt   NUMBER;
    l_entity_type VARCHAR2(64);
  BEGIN
    l_entity_type := norm_entity_type(p_entity_type);
  
    SELECT COUNT(*)
      INTO l_proj_cnt
      FROM app_project
     WHERE id = p_project_id;
  
    IF l_proj_cnt = 0
    THEN
      err_log_pkg.log_error(p_module_name    => 'ACTIVITY',
                            p_procedure_name => 'log_activity_prc',
                            p_error_code     => -20400,
                            p_error_msg      => 'Project nem található activity logoláskor.',
                            p_context        => 'project_id=' ||
                                                p_project_id ||
                                                '; actor_id=' || p_actor_id ||
                                                '; action=' || p_action,
                            p_api            => NULL);
      RAISE pkg_exceptions.activity_project_not_found;
    END IF;
  
    SELECT COUNT(*) INTO l_actor_cnt FROM app_user WHERE id = p_actor_id;
  
    IF l_actor_cnt = 0
    THEN
      err_log_pkg.log_error(p_module_name    => 'ACTIVITY',
                            p_procedure_name => 'log_activity_prc',
                            p_error_code     => -20401,
                            p_error_msg      => 'Actor user nem található activity logoláskor.',
                            p_context        => 'project_id=' ||
                                                p_project_id ||
                                                '; actor_id=' || p_actor_id ||
                                                '; action=' || p_action,
                            p_api            => NULL);
      RAISE pkg_exceptions.activity_actor_not_found;
    END IF;
  
    INSERT INTO app_activity
      (project_id
      ,actor_id
      ,entity_type
      ,entity_id
      ,action
      ,payload
       
       )
    VALUES
      (p_project_id
      ,p_actor_id
      ,l_entity_type
      ,p_entity_id
      ,p_action
      ,p_payload)
    RETURNING id INTO p_activity_id;
  
  EXCEPTION
    WHEN OTHERS THEN
      err_log_pkg.log_error(p_module_name    => 'ACTIVITY',
                            p_procedure_name => 'log_activity_prc',
                            p_error_code     => SQLCODE,
                            p_error_msg      => SQLERRM,
                            p_context        => 'project_id=' ||
                                                p_project_id ||
                                                '; actor_id=' || p_actor_id ||
                                                '; entity_type=' ||
                                                l_entity_type ||
                                                '; entity_id=' ||
                                                p_entity_id || '; action=' ||
                                                p_action,
                            p_api            => NULL);
      RAISE pkg_exceptions.activity_generic_error;
  END log_activity_prc;

  ------------------------------------------------------------------
  -- Procedúrák tipikus eseményekre
  ------------------------------------------------------------------

  PROCEDURE log_project_created_prc(p_project_id  IN app_activity.project_id%TYPE
                                   ,p_actor_id    IN app_activity.actor_id%TYPE
                                   ,p_activity_id OUT app_activity.id%TYPE) IS
    l_name app_project.project_name%TYPE;
  BEGIN
    SELECT project_name
      INTO l_name
      FROM app_project
     WHERE id = p_project_id;
  
    log_activity_prc(p_project_id  => p_project_id,
                     p_actor_id    => p_actor_id,
                     p_entity_type => 'PROJECT',
                     p_entity_id   => p_project_id,
                     p_action      => 'PROJECT_CREATE',
                     p_payload     => 'Projekt létrehozva: ' || l_name,
                     p_activity_id => p_activity_id);
  EXCEPTION
    WHEN OTHERS THEN
      RAISE;
  END log_project_created_prc;

  PROCEDURE log_task_created_prc(p_project_id  IN app_activity.project_id%TYPE
                                ,p_actor_id    IN app_activity.actor_id%TYPE
                                ,p_task_id     IN app_activity.entity_id%TYPE
                                ,p_task_title  IN VARCHAR2
                                ,p_activity_id OUT app_activity.id%TYPE) IS
  BEGIN
    log_activity_prc(p_project_id  => p_project_id,
                     p_actor_id    => p_actor_id,
                     p_entity_type => 'TASK',
                     p_entity_id   => p_task_id,
                     p_action      => 'TASK_CREATE',
                     p_payload     => 'Új task létrehozva: ' || p_task_title,
                     p_activity_id => p_activity_id);
  END log_task_created_prc;

  PROCEDURE log_task_status_change_prc(p_project_id      IN app_activity.project_id%TYPE
                                      ,p_actor_id        IN app_activity.actor_id%TYPE
                                      ,p_task_id         IN app_activity.entity_id%TYPE
                                      ,p_old_status_code IN VARCHAR2
                                      ,p_new_status_code IN VARCHAR2
                                      ,p_activity_id     OUT app_activity.id%TYPE) IS
  BEGIN
    log_activity_prc(p_project_id  => p_project_id,
                     p_actor_id    => p_actor_id,
                     p_entity_type => 'TASK',
                     p_entity_id   => p_task_id,
                     p_action      => 'TASK_STATUS_CHANGE',
                     p_payload     => 'Task státusz: ' || p_old_status_code ||
                                      ' -> ' || p_new_status_code,
                     p_activity_id => p_activity_id);
  END log_task_status_change_prc;

  PROCEDURE log_comment_added_prc(p_project_id  IN app_activity.project_id%TYPE
                                 ,p_actor_id    IN app_activity.actor_id%TYPE
                                 ,p_task_id     IN app_activity.entity_id%TYPE
                                 ,p_comment_id  IN NUMBER
                                 ,p_activity_id OUT app_activity.id%TYPE) IS
  BEGIN
    log_activity_prc(p_project_id  => p_project_id,
                     p_actor_id    => p_actor_id,
                     p_entity_type => 'COMMENT',
                     p_entity_id   => p_comment_id,
                     p_action      => 'COMMENT_ADDED',
                     p_payload     => 'Komment hozzáadva task_id=' ||
                                      p_task_id,
                     p_activity_id => p_activity_id);
  END log_comment_added_prc;

  PROCEDURE log_attachment_added_prc(p_project_id    IN app_activity.project_id%TYPE
                                    ,p_actor_id      IN app_activity.actor_id%TYPE
                                    ,p_task_id       IN app_activity.entity_id%TYPE
                                    ,p_attachment_id IN NUMBER
                                    ,p_file_name     IN VARCHAR2
                                    ,p_activity_id   OUT app_activity.id%TYPE) IS
  BEGIN
    log_activity_prc(p_project_id  => p_project_id,
                     p_actor_id    => p_actor_id,
                     p_entity_type => 'ATTACHMENT',
                     p_entity_id   => p_attachment_id,
                     p_action      => 'ATTACHMENT_ADDED',
                     p_payload     => 'Attachment hozzáadva: ' ||
                                      p_file_name || ' (task_id=' ||
                                      p_task_id || ')',
                     p_activity_id => p_activity_id);
  END log_attachment_added_prc;

END activity_log_pkg;
/
