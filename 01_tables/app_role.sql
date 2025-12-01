CREATE TABLE app_role(
  id           NUMBER         NOT NULL
  ,role_name   VARCHAR2(64)   UNIQUE NOT NULL
  ,description VARCHAR2(255)
  ,created_at  DATE           DEFAULT SYSDATE NOT NULL
)
TABLESPACE users;

ALTER TABLE app_role
      ADD (CONSTRAINT pk_app_role PRIMARY KEY (id);
      CONSTRAINT pk_app_role PRIMARY KEY (id));

CREATE SEQUENCE app_role_seq START WITH 1;

COMMENT ON TABLE app_role IS
  'Felhasználói szerepkörök (jogkörök csoportosítása).';

COMMENT ON COLUMN app_role.role_name IS 'Szerepkör neve, egyedi.';
