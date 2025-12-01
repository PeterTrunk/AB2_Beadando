CREATE TABLE label_task(
  task_id    NUMBER   NOT NULL
  ,label_id  NUMBER   NOT NULL
)
TABLESPACE users;

ALTER TABLE label_task
      ADD (CONSTRAINT pk_label_task PRIMARY KEY (task_id, label_id),
      CONSTRAINT fk_label_task_label_id FOREIGN KEY (label_id) REFERENCES labels(id),
      CONSTRAINT fk_label_task_task_id FOREIGN KEY (task_id) REFERENCES task(id));

COMMENT ON TABLE label_task IS
  'Task - Label kapcsolótábla: címkék hozzárendelése feladatokhoz.';
