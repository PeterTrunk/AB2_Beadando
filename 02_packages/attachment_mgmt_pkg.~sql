CREATE OR REPLACE PACKAGE attachment_mgmt_pkg IS

  PROCEDURE create_attachment_prc(p_task_id         IN attachment.task_id%TYPE
                                 ,p_uploaded_by     IN attachment.uploaded_by%TYPE
                                 ,p_file_name       IN attachment.file_name%TYPE
                                 ,p_content_type    IN attachment.content_type%TYPE
                                 ,p_size_bytes      IN attachment.size_bytes%TYPE
                                 ,p_storage_path    IN attachment.storage_path%TYPE
                                 ,p_attachment_type IN attachment.attachment_type%TYPE
                                 ,p_attachment_id   OUT attachment.id%TYPE);

END attachment_mgmt_pkg;
/
