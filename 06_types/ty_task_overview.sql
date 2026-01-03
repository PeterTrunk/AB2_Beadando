CREATE TYPE ty_task_overview AS OBJECT
(
  task_id          NUMBER,
  task_key         VARCHAR2(32),
  title            VARCHAR2(128),
  description      VARCHAR2(512),
  status_code      VARCHAR2(32),
  status_name      VARCHAR2(64),
  task_position    NUMBER,
  priority         VARCHAR2(32),
  created_at       DATE,
  due_date         DATE,
  closed_at        DATE,
  created_by_id    NUMBER,
  created_by_name  VARCHAR2(120),
  sprint_id        NUMBER,
  sprint_name      VARCHAR2(64),
  
  -- Aggregációs mezõk
  assignees_text VARCHAR2(400),
  attachment_count NUMBER,
  attachment_types VARCHAR2(200),
  labels_text      VARCHAR2(400),
  has_commit       CHAR(1),
  has_pr           CHAR(1)
)
;

CREATE OR REPLACE TYPE ty_task_overview_l AS TABLE OF ty_task_overview;
/
