CREATE OR REPLACE TRIGGER app_comment_h_trg
  AFTER DELETE OR UPDATE OR INSERT ON app_comment
  FOR EACH ROW
BEGIN
  IF deleting
  THEN
    INSERT INTO app_comment_h
      (id
      ,comment_id
      ,changed_at
      ,dml_flag
      ,task_id
      ,user_id
      ,comment_body
      ,created_at
      ,edited_at)
    VALUES
      (app_comment_h_seq.nextval
      ,:old.id
      ,SYSDATE
      ,'D'
      ,:old.task_id
      ,:old.user_id
      ,:old.comment_body
      ,:old.created_at
      ,:old.edited_at);
  ELSE
    INSERT INTO app_comment_h
      (id
      ,comment_id
      ,changed_at
      ,dml_flag
      ,task_id
      ,user_id
      ,comment_body
      ,created_at
      ,edited_at)
    VALUES
      (app_comment_h_seq.nextval
      ,:new.id
      ,SYSDATE
      ,:new.dml_flag
      ,:new.task_id
      ,:new.user_id
      ,:new.comment_body
      ,:new.created_at
      ,:new.edited_at);
  END IF;
END;
/
