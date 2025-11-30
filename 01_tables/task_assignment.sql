CREATE TABLE task_assignment(
  task_id       NUMBER  NOT NULL
  ,user_id      NUMBER  NOT NULL
  ,assigned_at  DATE    DEFAULT SYSDATE NOT NULL
)
TABLESPACE users;

ALTER TABLE task_assignment
      ADD CONSTRAINT pk_task_assignment PRIMARY KEY (task_id, user_id),
      CONSTRAINT fk_task_assignment_task FOREIGN KEY (task_id) REFERENCES task(id),
      CONSTRAINT fk_task_assignment_user FOREIGN KEY (user_id) REFERENCES app_user(id);



