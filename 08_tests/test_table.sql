CREATE TABLE test_table(
    id         NUMBER
    ,name      VARCHAR2(64)
)
TABLESPACE users;

create sequence test_table_seq start with 1;
/
begin
  create_auto_id_created_trg_prc('test_table');
  create_historisation_for_table('test_table');
end;
/
