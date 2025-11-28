CREATE TABLE labels(
  id          NUMBER        NOT NULL
  ,project_id NUMBER        NOT NULL
  ,label_name VARCHAR2(64)  NOT NULL
  ,color      VARCHAR2(7)   NOT NULL
)
TABLESPACE users;

ALTER TABLE labels
      ADD CONSTRAINT pk_labels PRIMARY KEY (id);
ALTER TABLE labels
      ADD CONSTRAINT fk_labels_project FOREIGN KEY (project_id) REFERENCES app_project(id);
