CREATE TABLE board(
  id            NUMBER        NOT NULL
  ,project_id   NUMBER        NOT NULL
  ,board_name   VARCHAR2(64)  NOT NULL
  ,is_default   NUMBER(1)     DEFAULT 0 NOT NULL
  ,position     NUMBER        NOT NULL
  ,created_at   DATE          DEFAULT SYSDATE NOT NULL
)
TABLESPACE users;

ALTER TABLE board
      ADD CONSTRAINT pk_board PRIMARY KEY (id),
      CONSTRAINT fk_board_project FOREIGN KEY (project_id) REFERENCES app_project(id),
      CONSTRAINT uq_board_name_project UNIQUE (project_id, board_name);

