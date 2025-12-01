CREATE OR REPLACE TRIGGER sprint_h_trg
  AFTER DELETE OR UPDATE OR INSERT ON sprint
  FOR EACH ROW
BEGIN
  IF deleting
  THEN
    INSERT INTO sprint_h
      (id
      ,sprint_id
      ,changed_at
      ,dml_type
      ,project_id
      ,board_id
      ,sprint_name
      ,goal
      ,start_date
      ,end_date
      ,state
      ,created_at)
    VALUES
      (sprint_h_seq.nextval
      ,:new.id
      ,SYSDATE
      ,'D'
      ,:new.project_id
      ,:new.board_id
      ,:new.sprint_name
      ,:new.goal
      ,:new.start_date
      ,:new.end_date
      ,:new.state
      ,:new.created_at);
  
  ELSE
    INSERT INTO sprint_h
      (id
      ,sprint_id
      ,changed_at
      ,dml_type
      ,project_id
      ,board_id
      ,sprint_name
      ,goal
      ,start_date
      ,end_date
      ,state
      ,created_at)
    VALUES
      (sprint_h_seq.nextval
      ,:new.id
      ,SYSDATE
      ,:new.dml_flag
      ,:new.project_id
      ,:new.board_id
      ,:new.sprint_name
      ,:new.goal
      ,:new.start_date
      ,:new.end_date
      ,:new.state
      ,:new.created_at);
  
 
  END IF;
END;
/
