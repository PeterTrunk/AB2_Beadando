CREATE TABLE integration(
  id              NUMBER          NOT NULL
  ,project_id     NUMBER          UNIQUE NOT NULL
  ,provider       VARCHAR2(16)    UNIQUE NOT NULL
  ,repo_full_name VARCHAR2(255)   UNIQUE NOT NULL
  ,access_token   VARCHAR2(255)   NOT NULL
  ,webhook_secret VARCHAR2(255)   NOT NULL
  ,is_enabled     NUMBER(1)       DEFAULT 1 NOT NULL
  ,created_at     DATE            DEFAULT SYSDATE NOT NULL
)
TABLESPACE users;

ALTER TABLE integration
      ADD CONSTRAINT pk_integration PRIMARY KEY (id),
      CONSTRAINT fk_integration_project FOREIGN KEY (project_id) REFERENCES app_project(id);
