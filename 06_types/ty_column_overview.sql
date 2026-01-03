CREATE OR REPLACE TYPE ty_column_overview AS OBJECT
(
  column_id   NUMBER,
  column_name VARCHAR2(64),
  wip_limit   NUMBER,
  status_code VARCHAR2(32),
  status_name VARCHAR2(64),
  tasks       ty_task_overview_l
)
;
/

CREATE OR REPLACE TYPE ty_column_overview_l AS TABLE OF ty_column_overview;
/
