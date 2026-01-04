CREATE OR REPLACE PACKAGE activity_log_pkg IS

  PROCEDURE log_activity_prc(p_project_id  IN app_activity.project_id%TYPE
                            ,p_actor_id    IN app_activity.actor_id%TYPE
                            ,p_entity_type IN app_activity.entity_type%TYPE
                            ,p_entity_id   IN app_activity.entity_id%TYPE
                            ,p_action      IN app_activity.action%TYPE
                            ,p_payload     IN app_activity.payload%TYPE DEFAULT NULL
                            ,p_activity_id OUT app_activity.id%TYPE);

  ------------------------------------------------------------------
  -- Procedúrák tipikus eseményekre
  ------------------------------------------------------------------

  PROCEDURE log_project_created_prc(p_project_id  IN app_activity.project_id%TYPE
                                   ,p_actor_id    IN app_activity.actor_id%TYPE
                                   ,p_activity_id OUT app_activity.id%TYPE);

  PROCEDURE log_task_created_prc(p_project_id  IN app_activity.project_id%TYPE
                                ,p_actor_id    IN app_activity.actor_id%TYPE
                                ,p_task_id     IN app_activity.entity_id%TYPE
                                ,p_task_title  IN VARCHAR2
                                ,p_activity_id OUT app_activity.id%TYPE);

  PROCEDURE log_task_status_change_prc(p_project_id      IN app_activity.project_id%TYPE
                                      ,p_actor_id        IN app_activity.actor_id%TYPE
                                      ,p_task_id         IN app_activity.entity_id%TYPE
                                      ,p_old_status_code IN VARCHAR2
                                      ,p_new_status_code IN VARCHAR2
                                      ,p_activity_id     OUT app_activity.id%TYPE);

  PROCEDURE log_comment_added_prc(p_project_id  IN app_activity.project_id%TYPE
                                 ,p_actor_id    IN app_activity.actor_id%TYPE
                                 ,p_task_id     IN app_activity.entity_id%TYPE
                                 ,p_comment_id  IN NUMBER
                                 ,p_activity_id OUT app_activity.id%TYPE);

  PROCEDURE log_attachment_added_prc(p_project_id    IN app_activity.project_id%TYPE
                                    ,p_actor_id      IN app_activity.actor_id%TYPE
                                    ,p_task_id       IN app_activity.entity_id%TYPE
                                    ,p_attachment_id IN NUMBER
                                    ,p_file_name     IN VARCHAR2
                                    ,p_activity_id   OUT app_activity.id%TYPE);

END activity_log_pkg;
/
