CREATE TABLE project_counter(
project_id NUMBER NOT NULL
,last_num NUMBER NOT NULL
)
TABLESPACE users;

ALTER TABLE project_counter
      ADD CONSTRAINT pk_project_counter PRIMARY KEY (project_id),
      CONSTRAINT fk_project_counter_project FOREIGN KEY (project_id) REFERENCES app_project(id);
