CREATE TABLE app_comment_h(
  id           NUMBER          NOT NULL,
  comment_id   NUMBER          NOT NULL,
  changed_at   DATE            DEFAULT SYSDATE NOT NULL,
  dml_flag     VARCHAR2(1)     NOT NULL,
  task_id      NUMBER,
  user_id      NUMBER,
  comment_body VARCHAR2(1024),
  created_at   DATE,
  edited_at    DATE
)
TABLESPACE users;

CREATE SEQUENCE app_comment_h_seq START WITH 1;
