CREATE TABLE task_h(
  id              NUMBER        NOT NULL
  ,project_id     NUMBER        NOT NULL
  ,board_id       NUMBER        NOT NULL
  ,column_id      NUMBER        NOT NULL
  ,sprint_id      NUMBER        NOT NULL
  ,task_key       VARCHAR2(32)  NOT NULL
  ,title          VARCHAR2(128) NOT NULL
  ,description    VARCHAR2(512)
  ,status_id      NUMBER        NOT NULL
  ,priority       VARCHAR2(32)
  ,estimated_min  NUMBER
  ,due_date       DATE
  ,position       NUMBER        NOT NULL
  ,created_by     NUMBER        NOT NULL
  ,created_at     DATE          DEFAULT SYSDATE NOT NULL
  ,updated_at     DATE
  ,closed_at      DATE
  ,dml_flag      VARCHAR2(1)    NOT NULL
  ,last_modified DATE           DEFAULT SYSDATE NOT NULL
)
TABLESPACE users;

CREATE SEQUENCE task_history_seq START WITH 1;

