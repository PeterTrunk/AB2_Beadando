CREATE TABLE project_member(
  project_id    NUMBER        NOT NULL
  ,user_id      NUMBER        NOT NULL
  ,project_role VARCHAR2(32)
  ,joined_at    DATE          DEFAULT SYSDATE NOT NULL
)
TABLESPACE users;

ALTER TABLE project_member
      ADD CONSTRAINT pk_project_member PRIMARY KEY (project_id, user_id);
ALTER TABLE project_member
      ADD CONSTRAINT fk_project_member_project FOREIGN KEY (project_id) REFERENCES app_project(id);
ALTER TABLE project_member
      ADD CONSTRAINT fk_project_member_user FOREIGN KEY (user_id) REFERENCES app_user(id);
