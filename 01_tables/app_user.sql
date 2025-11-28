CREATE TABLE app_user(
  id              NUMBER          PRIMARY KEY
  ,email          VARCHAR2(255)   NOT NULL
  ,display_name   VARCHAR2(120)   NOT NULL
  ,password_hash  VARCHAR2(255)
  ,is_active      number(1)       DEFAULT 0 NOT NULL
  ,created_at     DATE            DEFAULT SYSDATE NOT NULL
  ,last_modified  DATE            DEFAULT SYSDATE NOT NULL
)
TABLESPACE users;


