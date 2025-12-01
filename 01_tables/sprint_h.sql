CREATE TABLE sprint_h(
  id           NUMBER        NOT NULL,
  sprint_id    NUMBER        NOT NULL,
  changed_at   DATE          DEFAULT SYSDATE NOT NULL,
  dml_flag     VARCHAR(1)    NOT NULL,
  project_id   NUMBER,
  board_id     NUMBER,
  sprint_name  VARCHAR2(64),
  goal         VARCHAR2(255),
  start_date   DATE,
  end_date     DATE,
  state        VARCHAR2(16),
  created_at   DATE
)
TABLESPACE users;

CREATE SEQUENCE sprint_h_seq START WITH 1;
