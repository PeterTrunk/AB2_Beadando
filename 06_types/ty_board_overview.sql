CREATE OR REPLACE TYPE ty_board_overview AS OBJECT
(
  board_id    NUMBER,
  board_name  VARCHAR2(64),
  sprint_id   NUMBER,
  sprint_name VARCHAR2(64),
  column_list ty_column_overview_l
)
;
/
