CREATE OR REPLACE PROCEDURE create_integration_prc(p_project_id     IN integration.project_id%TYPE
                                                  ,p_provider       IN integration.provider%TYPE
                                                  ,p_repo_full_name IN integration.repo_full_name%TYPE
                                                  ,p_access_token   IN integration.access_token%TYPE
                                                  ,p_webhook_secret IN integration.webhook_secret%TYPE
                                                  ,p_is_enabled     IN integration.is_enabled%TYPE DEFAULT 1
                                                  ,p_integration_id OUT integration.id%TYPE) IS
BEGIN
  INSERT INTO integration
    (project_id
    ,provider
    ,repo_full_name
    ,access_token
    ,webhook_secret
    ,is_enabled)
  VALUES
    (p_project_id
    ,p_provider
    ,p_repo_full_name
    ,p_access_token
    ,p_webhook_secret
    ,nvl(p_is_enabled, 1))
  RETURNING id INTO p_integration_id;

EXCEPTION
  WHEN OTHERS THEN
    raise_application_error(-20160,
                            'create_integration_prc hiba (project_id = ' ||
                            p_project_id || ', provider = "' || p_provider ||
                            '", repo = "' || p_repo_full_name || '"): ' ||
                            SQLERRM);
END;
/
