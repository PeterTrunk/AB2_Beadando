CREATE OR REPLACE TRIGGER app_project_h_trg
  AFTER DELETE OR UPDATE OR INSERT ON app_project
  FOR EACH ROW
BEGIN
  IF deleting
  THEN
    INSERT INTO app_project_h
      (id
      ,project_id
      ,changed_at
      ,dml_flag
      ,project_name
      ,proj_key
      ,description
      ,owner_id
      ,is_archived
      ,created_at
      ,last_modified)
    VALUES
      (app_project_h_seq.nextval
      ,:old.id
      ,SYSDATE
      ,'D'
      ,:old.project_name
      ,:old.proj_key
      ,:old.description
      ,:old.owner_id
      ,:old.is_archived
      ,:old.created_at
      ,:old.last_modified);
  
  ELSE
    INSERT INTO app_project_h
      (id
      ,project_id
      ,changed_at
      ,dml_flag
      ,project_name
      ,proj_key
      ,description
      ,owner_id
      ,is_archived
      ,created_at
      ,last_modified)
    VALUES
      (app_project_h_seq.nextval
      ,:new.id
      ,SYSDATE
      ,:new.dml_flag
      ,:new.project_name
      ,:new.proj_key
      ,:new.description
      ,:new.owner_id
      ,:new.is_archived
      ,:new.created_at
      ,:new.last_modified);
  END IF;
END;
/
