CREATE OR REPLACE PACKAGE BODY attachment_mgmt_pkg IS

  PROCEDURE create_attachment_prc(p_task_id         IN attachment.task_id%TYPE
                                 ,p_uploaded_by     IN attachment.uploaded_by%TYPE
                                 ,p_file_name       IN attachment.file_name%TYPE
                                 ,p_content_type    IN attachment.content_type%TYPE
                                 ,p_size_bytes      IN attachment.size_bytes%TYPE
                                 ,p_storage_path    IN attachment.storage_path%TYPE
                                 ,p_attachment_type IN attachment.attachment_type%TYPE
                                 ,p_attachment_id   OUT attachment.id%TYPE) IS
    l_task_cnt   NUMBER;
    l_user_cnt   NUMBER;
    l_project_id task.project_id%TYPE;
  BEGIN

    -- Task létezésének ellenõrzése
    SELECT COUNT(*) INTO l_task_cnt FROM task WHERE id = p_task_id;
  
    IF l_task_cnt = 0
    THEN
      err_log_pkg.log_error(p_module_name    => 'ATTACHMENT',
                            p_procedure_name => 'create_attachment_prc',
                            p_error_code     => -20390,
                            p_error_msg      => 'A megadott task nem létezik attachmenthez.',
                            p_context        => 'task_id=' || p_task_id ||
                                                '; uploaded_by=' ||
                                                p_uploaded_by ||
                                                '; file_name=' ||
                                                p_file_name,
                            p_api            => NULL);
      RAISE pkg_exceptions.attachment_task_not_found;
    END IF;
  

    -- User létezésének ellenõrzése
    SELECT COUNT(*) INTO l_user_cnt FROM app_user WHERE id = p_uploaded_by;
  
    IF l_user_cnt = 0
    THEN
      err_log_pkg.log_error(p_module_name    => 'ATTACHMENT',
                            p_procedure_name => 'create_attachment_prc',
                            p_error_code     => -20391,
                            p_error_msg      => 'A megadott user nem létezik attachmenthez.',
                            p_context        => 'task_id=' || p_task_id ||
                                                '; uploaded_by=' ||
                                                p_uploaded_by ||
                                                '; file_name=' ||
                                                p_file_name,
                            p_api            => NULL);
      RAISE pkg_exceptions.attachment_user_not_found;
    END IF;
  
    -- Attachment beszúrása
    INSERT INTO attachment
      (task_id
      ,uploaded_by
      ,file_name
      ,content_type
      ,size_bytes
      ,storage_path
      ,attachment_type
       )
    VALUES
      (p_task_id
      ,p_uploaded_by
      ,p_file_name
      ,p_content_type
      ,p_size_bytes
      ,p_storage_path
      ,p_attachment_type)
    RETURNING id INTO p_attachment_id;
  
    -- Activity Log
    DECLARE
      l_activity_id app_activity.id%TYPE;
    BEGIN
      SELECT project_id INTO l_project_id FROM task WHERE id = p_task_id;
    
      activity_log_pkg.log_activity_prc(p_project_id  => l_project_id,
                                        p_actor_id    => p_uploaded_by,
                                        p_entity_type => 'ATTACHMENT',
                                        p_entity_id   => p_attachment_id,
                                        p_action      => 'ATTACHMENT_ADD',
                                        p_payload     => 'Attachment: ' ||
                                                         p_file_name || ' (' ||
                                                         p_content_type || ', ' ||
                                                         p_size_bytes ||
                                                         ' byte)',
                                        p_activity_id => l_activity_id);
    END;
  
  EXCEPTION
    WHEN pkg_exceptions.attachment_task_not_found
         OR pkg_exceptions.attachment_user_not_found THEN
      RAISE;
    
    WHEN OTHERS THEN
      err_log_pkg.log_error(p_module_name    => 'ATTACHMENT',
                            p_procedure_name => 'create_attachment_prc',
                            p_error_code     => SQLCODE,
                            p_error_msg      => SQLERRM,
                            p_context        => 'task_id=' || p_task_id ||
                                                '; uploaded_by=' ||
                                                p_uploaded_by ||
                                                '; file_name=' ||
                                                p_file_name,
                            p_api            => NULL);
      RAISE pkg_exceptions.attachment_generic_error;
  END create_attachment_prc;

END attachment_mgmt_pkg;
/
