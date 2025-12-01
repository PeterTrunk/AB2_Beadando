CREATE TABLE task_h(
  id            NUMBER         NOT NULL,
  task_id       NUMBER         NOT NULL,
  changed_at    DATE           DEFAULT SYSDATE NOT NULL,
  dml_flag      VARCHAR2(1)    NOT NULL,
  project_id    NUMBER,
  board_id      NUMBER,
  column_id     NUMBER,
  sprint_id     NUMBER,
  task_key      VARCHAR2(32),
  title         VARCHAR2(128),
  description   VARCHAR2(512),
  status        VARCHAR2(32),
  priority      VARCHAR2(32),
  estimated_min NUMBER,
  due_date      DATE,
  created_by    NUMBER,
  created_at    DATE,
  updated_at    DATE,
  closed_at     DATE
)
TABLESPACE users;

CREATE SEQUENCE task_history_seq START WITH 1;

