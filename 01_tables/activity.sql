CREATE TABLE activity(
  id            NUMBER        NOT NULL
  ,project_id   NUMBER        NOT NULL
  ,actor_id     NUMBER        NOT NULL
  ,entity_type  VARCHAR2(64)  NOT NULL
  ,entity_id    NUMBER        NOT NULL
  ,action       VARCHAR2(64)  NOT NULL
  ,payload      VARCHAR2(255)
  ,created_at   DATE          DEFAULT SYSDATE NOT NULL
)
TABLESPACE users;

ALTER TABLE activity
      ADD CONSTRAINT pk_activity PRIMARY KEY (id),
      CONSTRAINT fk_activity_project FOREIGN KEY (project_id) REFERENCES app_project(id),
      CONSTRAINT fk_activity_user FOREIGN KEY (actor_id) REFERENCES app_user(id);
