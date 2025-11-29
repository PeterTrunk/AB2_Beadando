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
      ADD CONSTRAINT pk_column_def PRIMARY KEY (id);
ALTER TABLE column_def
      ADD CONSTRAINT fk_column_def_board FOREIGN KEY (board_id) REFERENCES board(id);
ALTER TABLE column_def
      ADD CONSTRAINT uq_column_def_name_per_board UNIQUE (board_id, column_name);
ALTER TABLE column_def
      ADD CONSTRAINT uq_column_def_pos_per_board UNIQUE (board_id, position);
ALTER TABLE column_def
      ADD CONSTRAINT chk_column_def_wip_positive CHECK (wip_limit > 0);
ALTER TABLE column_def
      ADD CONSTRAINT uq_column_def_status_per_board UNIQUE (board_id, status_of_task);
