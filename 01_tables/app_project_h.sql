CREATE TABLE app_project_h(
  id            NUMBER         NOT NULL
  ,project_id    NUMBER         NOT NULL
  ,project_name  VARCHAR2(140)
  ,proj_key      VARCHAR2(16)
  ,description   VARCHAR2(2000)
  ,owner_id      NUMBER
  ,is_archived   NUMBER(1)
  ,created_at    DATE
  ,dml_flag      VARCHAR2(1)    NOT NULL
  ,last_modified DATE           DEFAULT SYSDATE NOT NULL
)
TABLESPACE users;

CREATE SEQUENCE app_project_h_seq START WITH 1;
