CREATE TABLE column_def(
  id                NUMBER        NOT NULL
  ,board_id         NUMBER        NOT NULL
  ,column_name      VARCHAR2(64)  NOT NULL
  ,wip_limit        NUMBER        NOT NULL
  ,position         NUMBER        NOT NULL
  ,status_of_task   VARCHAR2(32)  NOT NULL
)
TABLESPACE users;

ALTER TABLE column_def
      ADD (CONSTRAINT pk_column_def PRIMARY KEY (id),
      CONSTRAINT fk_column_def_board FOREIGN KEY (board_id) REFERENCES board(id),
      CONSTRAINT uq_column_def_name_per_board UNIQUE (board_id, column_name),
      CONSTRAINT uq_column_def_pos_per_board UNIQUE (board_id, position),
      CONSTRAINT chk_column_def_wip_positive CHECK (wip_limit > 0),
      CONSTRAINT uq_column_def_status_per_board UNIQUE (board_id, status_of_task));

CREATE SEQUENCE column_def_seq START WITH 1;

COMMENT ON TABLE column_def IS
  'Board oszlopok definíciója, WIP limitek, pozíció és kapcsolt státusz.';

COMMENT ON COLUMN column_def.status_of_task IS
  'Az oszlophoz tartozó feladat státusz (dinamikus mapping a workflow-hoz).';
