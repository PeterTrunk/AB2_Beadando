CREATE TABLE task(
  id              NUMBER        NOT NULL
  ,project_id     NUMBER        NOT NULL
  ,board_id       NUMBER        NOT NULL
  ,column_id      NUMBER        NOT NULL
  ,sprint_id      NUMBER        NOT NULL
  ,task_key       VARCHAR2(32)  NOT NULL
  ,title          VARCHAR2(128) NOT NULL
  ,description    VARCHAR2(512)
  ,status_id      NUMBER        NOT NULL
  ,priority       VARCHAR2(32)
  ,estimated_min  NUMBER
  ,due_date       DATE
  ,position       NUMBER        NOT NULL
)
TABLESPACE users;

ALTER TABLE task
      ADD(
      CONSTRAINT pk_task PRIMARY KEY (id),
      
      CONSTRAINT uq_task_key_per_project UNIQUE (project_id, task_key),
      
      CONSTRAINT chk_task_priority CHECK (priority IN ('LOW', 'MEDIUM', 'HIGH', 'CRITICAL')),
      
      CONSTRAINT chk_task_estimated_min CHECK (estimated_min IS NULL OR estimated_min >= 0),
      
      CONSTRAINT fk_task_project FOREIGN KEY (project_id) REFERENCES app_project(id),
      CONSTRAINT fk_task_board FOREIGN KEY (board_id) REFERENCES board(id),
      CONSTRAINT fk_task_column FOREIGN KEY (column_id) REFERENCES column_def(id),
      CONSTRAINT fk_task_sprint FOREIGN KEY (sprint_id) REFERENCES sprint(id),
      CONSTRAINT fk_task_app_user FOREIGN KEY (created_by) REFERENCES app_user(id),
      
      CONSTRAINT fk_task_status FOREIGN KEY (status_id) REFERENCES task_status(id),
      CONSTRAINT uq_task_position_per_column UNIQUE (column_id, position)
      );
     
CREATE SEQUENCE task_seq START WITH 100;
 


COMMENT ON TABLE task IS
  'Feladat (issue, user story, bug): scrum/kaban projekt alap egysége.';

COMMENT ON COLUMN task.task_key IS 'Feladat kulcs (pl. PMA-12).';
COMMENT ON COLUMN task.status IS 'Feladat állapota (pl. TODO, IN PROGRESS, DONE stb).';
COMMENT ON COLUMN task.created_by IS 'Létrehozó felhasználó azonosítója.';
COMMENT ON COLUMN task.closed_at IS 'Lezárás idõpontja, ha van.';

