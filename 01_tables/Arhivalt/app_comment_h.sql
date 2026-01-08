CREATE TABLE app_comment_h(
  id           NUMBER          NOT NULL
  ,task_id      NUMBER
  ,user_id      NUMBER
  ,comment_body VARCHAR2(1024)
  ,created_at   DATE
  ,mod_user     VARCHAR2(300)
  ,dml_flag      VARCHAR2(1)    NOT NULL
  ,last_modified DATE
  ,version       NUMBER
)
TABLESPACE users;

