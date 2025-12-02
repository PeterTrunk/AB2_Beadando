CREATE TABLE task_status (
  id          NUMBER        NOT NULL,
  code        VARCHAR2(32)  NOT NULL,    -- pl. 'INBACKLOG' 'TODO', 'WIP', 'REVIEW', 'DONE'
  name        VARCHAR2(64)  NOT NULL,    -- pl. 'In Backlog' 'To-Do', 'Work in progress'
  description VARCHAR2(512),
  is_final    NUMBER(1)     DEFAULT 0 NOT NULL,  -- 0 = nem lezárt, 1 = lezárt
  position    NUMBER        NOT NULL            -- sorrend riportokhoz / listákhoz
)
TABLESPACE users;

ALTER TABLE task_status
  ADD (
    CONSTRAINT pk_task_status PRIMARY KEY (id),
    CONSTRAINT uq_task_status_code UNIQUE (code),
    CONSTRAINT chk_task_status_is_final CHECK (is_final IN (0,1))
  );

CREATE SEQUENCE task_status_seq START WITH 1;
