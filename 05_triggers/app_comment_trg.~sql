CREATE OR REPLACE TRIGGER app_comment_trg
  BEFORE INSERT OR UPDATE ON app_comment
  FOR EACH ROW
BEGIN
  IF (inserting)
  THEN
    IF (:new.id IS NULL)
    THEN
      :new.id := app_comment_seq.nextval;
    END IF;
    :new.created_on    := SYSDATE;
    :new.mod_user      := sys_context(namespace => 'USERENV',
                                      attribute => 'OS_USER') 
    :new.dml_flag := 'I';
    :new.last_modified := SYSDATE;
    :new.version       := 1;
  ELSE
    :new.mod_user      := sys_context(namespace => 'USERENV',
                                      attribute => 'OS_USER');
    :new.dml_flag      := 'U';
    :new.last_modified := SYSDATE;
    :new.version       := :old.version + 1;
  END IF;
END;
