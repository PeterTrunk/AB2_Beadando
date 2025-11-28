CREATE TABLE app_user(
  id              NUMBER          NOT NULL
  ,email          VARCHAR2(255)   UNIQUE NOT NULL
  ,display_name   VARCHAR2(120)   NOT NULL
  ,password_hash  VARCHAR2(255)
  ,is_active      number(1)       DEFAULT 0 NOT NULL
  ,created_at     DATE            DEFAULT SYSDATE NOT NULL
  ,last_modified  DATE            DEFAULT SYSDATE NOT NULL
)
TABLESPACE users;

ALTER TABLE app_user
      ADD CONSTRAINT app_user_pk PRIMARY KEY (id);


CREATE TABLE app_role(
  id           NUMBER         NOT NULL
  ,role_name   VARCHAR2(64)   UNIQUE NOT NULL
  ,description VARCHAR2(255)
  ,created_at  DATE           DEFAULT SYSDATE NOT NULL
)
TABLESPACE users;

ALTER TABLE app_role
      ADD CONSTRAINT pk_app_role PRIMARY KEY (id);
      
      
CREATE TABLE app_project(
  id              NUMBER          PRIMARY KEY
  ,project_name   VARCHAR2(140)   UNIQUE NOT NULL
  ,proj_key       VARCHAR2(16)    UNIQUE NOT NULL
  ,description    VARCHAR2(2000)
  ,owner_id       NUMBER
  ,is_archived    NUMBER(1)       DEFAULT 0 NOT NULL
  ,created_at     DATE            DEFAULT SYSDATE NOT NULL
  ,last_modified  DATE            DEFAULT SYSDATE NOT NULL
)
TABLESPACE users;

ALTER TABLE app_project
      ADD CONSTRAINT fk_app_project_owner FOREIGN KEY (owner_id) REFERENCES app_suer(id);
      
CREATE TABLE app_user_role(
  user_id      NUMBER
  ,role_id     NUMBER 
  ,assigned_at DATE DEFAULT SYSDATE NOT NULL
)
TABLESPACE users;

ALTER TABLE app_user_role
      CONSTRAINT pk_app_user_role PRIMARY KEY (user_id, role_id);
ALTER TABLE app_user_role
      CONSTRAINT fk_app_user_role_user FOREIGN KEY (user_id) REFERENCES app_user(id);
ALTER TABLE app_user_role
      CONSTRAINT fk_app_user_role_role FOREIGN KEY (role_id) REFERENCES app_role(id);
