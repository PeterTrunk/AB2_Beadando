CREATE OR REPLACE PROCEDURE create_attachment_prc(p_task_id         IN attachment.task_id%TYPE
                                                 ,p_uploaded_by     IN attachment.uploaded_by%TYPE
                                                 ,p_file_name       IN attachment.file_name%TYPE
                                                 ,p_content_type    IN attachment.content_type%TYPE
                                                 ,p_size_bytes      IN attachment.size_bytes%TYPE
                                                 ,p_storage_path    IN attachment.storage_path%TYPE
                                                 ,p_attachment_type IN attachment.attachment_type%TYPE
                                                 ,p_attachment_id   OUT attachment.id%TYPE) IS
BEGIN
  INSERT INTO attachment
    (task_id
    ,uploaded_by
    ,file_name
    ,content_type
    ,size_bytes
    ,storage_path
    ,attachment_type)
  VALUES
    (p_task_id
    ,p_uploaded_by
    ,p_file_name
    ,p_content_type
    ,p_size_bytes
    ,p_storage_path
    ,p_attachment_type)
  RETURNING id INTO p_attachment_id;

EXCEPTION
  WHEN OTHERS THEN
    raise_application_error(-20190,
                            'create_attachment_prc hiba (task_id = ' ||
                            p_task_id || ', file_name = "' || p_file_name ||
                            '"): ' || SQLERRM);
END;
/
