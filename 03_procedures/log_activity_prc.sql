CREATE OR REPLACE PROCEDURE log_activity_prc(p_project_id  IN app_activity.project_id%TYPE
                                            ,p_actor_id    IN app_activity.actor_id%TYPE
                                            ,p_entity_type IN app_activity.entity_type%TYPE
                                            ,p_entity_id   IN app_activity.entity_id%TYPE
                                            ,p_action      IN app_activity.action%TYPE
                                            ,p_payload     IN app_activity.payload%TYPE DEFAULT NULL
                                            ,p_activity_id OUT app_activity.id%TYPE) IS
BEGIN
  INSERT INTO app_activity
    (project_id
    ,actor_id
    ,entity_type
    ,entity_id
    ,action
    ,payload)
  VALUES
    (p_project_id
    ,p_actor_id
    ,p_entity_type
    ,p_entity_id
    ,p_action
    ,p_payload)
  RETURNING id INTO p_activity_id;

EXCEPTION
  WHEN OTHERS THEN
    raise_application_error(-20150,
                            'log_activity_prc hiba (project_id = ' ||
                            p_project_id || ', actor_id = ' || p_actor_id ||
                            ', entity_type = "' || p_entity_type ||
                            '", entity_id = ' || p_entity_id ||
                            ', action = "' || p_action || '"): ' || SQLERRM);
END;
/
