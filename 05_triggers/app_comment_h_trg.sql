CREATE OR REPLACE TRIGGER app_comment_h_trg
  AFTER DELETE OR UPDATE OR INSERT ON app_comment
  FOR EACH ROW
BEGIN
  IF deleting
  THEN
    INSERT INTO app_comment_h
      (id
      ,task_id
      ,user_id
      ,comment_body
      ,created_at
      ,mod_user
      ,dml_flag
      ,last_modified
      ,version)
    VALUES
      (:old.id
      ,:old.task_id
      ,:old.user_id
      ,:old.comment_body
      ,:old.created_at
      ,sys_context('USERENV', 'OS_USER')
      ,'D'
      ,SYSDATE
      ,:old.version + 1);
  ELSE
    INSERT INTO app_comment_h
      (id
      ,task_id
      ,user_id
      ,comment_body
      ,created_at
      ,mod_user
      ,dml_flag
      ,last_modified
      ,version)
    VALUES
      (:new.id
      ,:new.task_id
      ,:new.user_id
      ,:new.comment_body
      ,:new.created_at
      ,:new.mod_user
      ,:new.dml_flag
      ,:new.edited_at
      ,:new.version);
  END IF;
END;
