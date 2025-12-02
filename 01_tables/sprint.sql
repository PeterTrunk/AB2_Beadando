CREATE TABLE sprint(
  id            NUMBER        NOT NULL
  ,project_id   NUMBER        NOT NULL
  ,board_id     NUMBER        NOT NULL
  ,sprint_name  VARCHAR2(64)  NOT NULL
  ,goal         VARCHAR2(255) NOT NULL
  ,start_date   DATE          DEFAULT SYSDATE NOT NULL
  ,end_date     DATE          NOT NULL
  ,state        VARCHAR2(16)  NOT NULL
  ,created_at   DATE          DEFAULT SYSDATE NOT NULL
  ,dml_flag      VARCHAR2(1)    NOT NULL
  ,last_modified DATE           DEFAULT SYSDATE NOT NULL
)
TABLESPACE users;

ALTER TABLE sprint
      ADD (CONSTRAINT pk_sprint PRIMARY KEY (id),
      CONSTRAINT fk_sprint_project FOREIGN KEY (project_id) REFERENCES app_project(id),
      CONSTRAINT fk_sprint_board FOREIGN KEY (board_id) REFERENCES board(id),
      CONSTRAINT uq_sprint_name_per_project UNIQUE (project_id, sprint_name),
      CONSTRAINT chk_sprint_dates_valid CHECK (end_date >= start_date),
      CONSTRAINT chk_sprint_state CHECK (state IN ('PLANNED', 'ACTIVE', 'COMPLETED', 'CANCELLED'))),

CREATE SEQUENCE sprint_seq START WITH 1;

COMMENT ON TABLE sprint IS
  'Idõszakos fejlesztési ciklus (Scrum sprint), státuszkezeléssel.';
