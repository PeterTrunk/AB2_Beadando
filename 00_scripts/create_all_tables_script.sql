-- Close PMA_MANAGER user sessions --

DECLARE
  CURSOR cur IS
    SELECT 'alter system kill session ''' || sid || ',' || serial# || '''' AS command
      FROM v$session
     WHERE username = 'PMA_MANAGER';
BEGIN
  FOR c IN cur
  LOOP
    EXECUTE IMMEDIATE c.command;
  END LOOP;
END;
/

DECLARE
  v_count NUMBER;
BEGIN
  SELECT COUNT(*) INTO v_count FROM dba_users t WHERE t.username='PMA_MANAGER';
  IF v_count = 1 THEN 
    EXECUTE IMMEDIATE 'DROP USER pma_manager CASCADE';
  END IF;
END;
/

CREATE USER pma_manager 
  IDENTIFIED BY "12345678" 
  DEFAULT TABLESPACE users
  QUOTA UNLIMITED ON users
;

GRANT CREATE TRIGGER to pma_manager;
GRANT CREATE SESSION TO pma_manager;
GRANT CREATE TABLE TO pma_manager;
GRANT CREATE VIEW TO pma_manager;
GRANT CREATE SEQUENCE TO pma_manager;
GRANT CREATE PROCEDURE TO pma_manager;
GRANT CREATE TYPE TO pma_manager;

ALTER SESSION SET CURRENT_SCHEMA=pma_manager;

-- Creating tables  --

CREATE TABLE app_user(
  id              NUMBER          NOT NULL
  ,email          VARCHAR2(255)   UNIQUE NOT NULL
  ,display_name   VARCHAR2(120)   NOT NULL
  ,password_hash  VARCHAR2(255)
  ,is_active      number(1)       DEFAULT 0 NOT NULL
  ,created_at     DATE            DEFAULT SYSDATE NOT NULL
  ,last_modified  DATE            DEFAULT SYSDATE NOT NULL
)
TABLESPACE users;

ALTER TABLE app_user
      ADD CONSTRAINT app_user_pk PRIMARY KEY (id);

CREATE TABLE app_role(
  id           NUMBER         NOT NULL
  ,role_name   VARCHAR2(64)   UNIQUE NOT NULL
  ,description VARCHAR2(255)
  ,created_at  DATE           DEFAULT SYSDATE NOT NULL
)
TABLESPACE users;

ALTER TABLE app_role
      ADD CONSTRAINT pk_app_role PRIMARY KEY (id);
      
CREATE TABLE app_project(
  id              NUMBER          PRIMARY KEY
  ,project_name   VARCHAR2(140)   UNIQUE NOT NULL
  ,proj_key       VARCHAR2(16)    UNIQUE NOT NULL
  ,description    VARCHAR2(2000)
  ,owner_id       NUMBER
  ,is_archived    NUMBER(1)       DEFAULT 0 NOT NULL
  ,created_at     DATE            DEFAULT SYSDATE NOT NULL
  ,last_modified  DATE            DEFAULT SYSDATE NOT NULL
)
TABLESPACE users;

ALTER TABLE app_project
      ADD CONSTRAINT fk_app_project_owner FOREIGN KEY (owner_id) REFERENCES app_user(id);

CREATE TABLE app_user_role(
  user_id      NUMBER
  ,role_id     NUMBER 
  ,assigned_at DATE     DEFAULT SYSDATE NOT NULL
)
TABLESPACE users;

ALTER TABLE app_user_role
      ADD (CONSTRAINT pk_app_user_role PRIMARY KEY (user_id, role_id),
      CONSTRAINT fk_app_user_role_user FOREIGN KEY (user_id) REFERENCES app_user(id),
      CONSTRAINT fk_app_user_role_role FOREIGN KEY (role_id) REFERENCES app_role(id));

CREATE TABLE project_member(
  project_id    NUMBER        NOT NULL
  ,user_id      NUMBER        NOT NULL
  ,project_role VARCHAR2(32)
  ,joined_at    DATE          DEFAULT SYSDATE NOT NULL
)
TABLESPACE users;

ALTER TABLE project_member
      ADD (CONSTRAINT pk_project_member PRIMARY KEY (project_id, user_id),
      CONSTRAINT fk_project_member_project FOREIGN KEY (project_id) REFERENCES app_project(id),
      CONSTRAINT fk_project_member_user FOREIGN KEY (user_id) REFERENCES app_user(id));

CREATE TABLE activity(
  id            NUMBER        NOT NULL
  ,project_id   NUMBER        NOT NULL
  ,actor_id     NUMBER        NOT NULL
  ,entity_type  VARCHAR2(64)  NOT NULL
  ,entity_id    NUMBER        NOT NULL
  ,action       VARCHAR2(64)  NOT NULL
  ,payload      VARCHAR2(255)
  ,created_at   DATE          DEFAULT SYSDATE NOT NULL
)
TABLESPACE users;

ALTER TABLE activity
      ADD (CONSTRAINT pk_activity PRIMARY KEY (id),
      CONSTRAINT fk_activity_project FOREIGN KEY (project_id) REFERENCES app_project(id),
      CONSTRAINT fk_activity_user FOREIGN KEY (actor_id) REFERENCES app_user(id));

CREATE TABLE labels(
  id          NUMBER        NOT NULL
  ,project_id NUMBER        NOT NULL
  ,label_name VARCHAR2(64)  NOT NULL
  ,color      VARCHAR2(7)   NOT NULL
)
TABLESPACE users;

ALTER TABLE labels
      ADD (CONSTRAINT pk_labels PRIMARY KEY (id),
      CONSTRAINT fk_labels_project FOREIGN KEY (project_id) REFERENCES app_project(id));

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
      ADD (CONSTRAINT pk_board PRIMARY KEY (id),
      CONSTRAINT fk_board_project FOREIGN KEY (project_id) REFERENCES app_project(id),
      CONSTRAINT uq_board_name_project UNIQUE (project_id, board_name));

CREATE TABLE integration(
  id              NUMBER          NOT NULL
  ,project_id     NUMBER          UNIQUE NOT NULL
  ,provider       VARCHAR2(16)    UNIQUE NOT NULL
  ,repo_full_name VARCHAR2(255)   UNIQUE NOT NULL
  ,access_token   VARCHAR2(255)   NOT NULL
  ,webhook_secret VARCHAR2(255)   NOT NULL
  ,is_enabled     NUMBER(1)       DEFAULT 1 NOT NULL
  ,created_at     DATE            DEFAULT SYSDATE NOT NULL
)
TABLESPACE users;

ALTER TABLE integration
      ADD (CONSTRAINT pk_integration PRIMARY KEY (id),
      CONSTRAINT fk_integration_project FOREIGN KEY (project_id) REFERENCES app_project(id));

CREATE TABLE project_counter(
project_id NUMBER NOT NULL
,last_num NUMBER NOT NULL
)
TABLESPACE users;

ALTER TABLE project_counter
      ADD (CONSTRAINT pk_project_counter PRIMARY KEY (project_id),
      CONSTRAINT fk_project_counter_project FOREIGN KEY (project_id) REFERENCES app_project(id));

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
)
TABLESPACE users;

ALTER TABLE sprint
      ADD (CONSTRAINT pk_sprint PRIMARY KEY (id),
      CONSTRAINT fk_sprint_project FOREIGN KEY (project_id) REFERENCES app_project(id),
      CONSTRAINT fk_sprint_board FOREIGN KEY (board_id) REFERENCES board(id),
      CONSTRAINT uq_sprint_name_per_project UNIQUE (project_id, sprint_name),
      CONSTRAINT chk_sprint_dates_valid CHECK (end_date >= start_date),
      CONSTRAINT chk_sprint_state CHECK (state IN ('PLANNED', 'ACTIVE', 'COMPLETED', 'CANCELLED')));

CREATE TABLE task(
  id              NUMBER        NOT NULL
  ,project_id     NUMBER        NOT NULL
  ,board_id       NUMBER        NOT NULL
  ,column_id      NUMBER        NOT NULL
  ,sprint_id      NUMBER        NOT NULL
  ,task_key       VARCHAR2(32)  NOT NULL
  ,title          VARCHAR2(128) NOT NULL
  ,description    VARCHAR2(512)
  ,status         VARCHAR2(32)  NOT NULL
  ,priority       VARCHAR2(32)
  ,estimated_min  NUMBER
  ,due_date       DATE
  ,created_by     NUMBER        NOT NULL
  ,created_at     DATE          DEFAULT SYSDATE NOT NULL
  ,updated_at     DATE
  ,closed_at      DATE
)
TABLESPACE users;

ALTER TABLE task
      ADD (CONSTRAINT pk_task PRIMARY KEY (id),
      CONSTRAINT uq_task_key_per_project UNIQUE (project_id, task_key),
      CONSTRAINT chk_task_priority CHECK (priority IN ('LOW', 'MEDIUM', 'HIGH', 'CRITICAL')),
      CONSTRAINT chk_task_estimated_min CHECK (estimated_min IS NULL OR estimated_min >= 0),
      CONSTRAINT fk_task_project FOREIGN KEY (project_id) REFERENCES app_project(id),
      CONSTRAINT fk_task_board FOREIGN KEY (board_id) REFERENCES board(id),
      CONSTRAINT fk_task_column FOREIGN KEY (column_id) REFERENCES column_def(id),
      CONSTRAINT fk_task_sprint FOREIGN KEY (sprint_id) REFERENCES sprint(id),
      CONSTRAINT fk_task_app_user FOREIGN KEY (created_by) REFERENCES app_user(id));

CREATE TABLE task_assignment(
  task_id       NUMBER  NOT NULL
  ,user_id      NUMBER  NOT NULL
  ,assigned_at  DATE    DEFAULT SYSDATE NOT NULL
)
TABLESPACE users;

ALTER TABLE task_assignment
      ADD (CONSTRAINT pk_task_assignment PRIMARY KEY (task_id, user_id),
      CONSTRAINT fk_task_assignment_task FOREIGN KEY (task_id) REFERENCES task(id),
      CONSTRAINT fk_task_assignment_user FOREIGN KEY (user_id) REFERENCES app_user(id));

CREATE TABLE label_task(
  task_id    NUMBER   NOT NULL
  ,label_id  NUMBER   NOT NULL
)
TABLESPACE users;

ALTER TABLE label_task
      ADD (CONSTRAINT pk_label_task PRIMARY KEY (task_id, label_id),
      CONSTRAINT fk_label_task_label_id FOREIGN KEY (label_id) REFERENCES labels(id),
      CONSTRAINT fk_label_task_task_id FOREIGN KEY (task_id) REFERENCES task(id));

CREATE TABLE app_comment(
  id              NUMBER          NOT NULL
  ,task_id        NUMBER          NOT NULL
  ,user_id        NUMBER          NOT NULL
  ,comment_body   VARCHAR2(1024)  NOT NULL
  ,created_at     DATE            DEFAULT SYSDATE NOT NULL
  ,edited_at      DATE
)
TABLESPACE users;

ALTER TABLE app_comment
      ADD (CONSTRAINT pk_app_comment PRIMARY KEY (id),
      CONSTRAINT fk_app_comment_task FOREIGN KEY (task_id) REFERENCES task(id),
      CONSTRAINT fk_app_comment_app_user FOREIGN KEY (user_id) REFERENCES app_user(id));

CREATE TABLE commit_link(
  id                NUMBER          NOT NULL
  ,task_id          NUMBER          NOT NULL
  ,provider         VARCHAR2(16)    NOT NULL
  ,repo_full_name   VARCHAR2(255)   NOT NULL
  ,commit_sha       VARCHAR2(40)    NOT NULL
  ,message          VARCHAR2(4000)  NOT NULL
  ,author_email     VARCHAR2(255)   NOT NULL
  ,committed_at     DATE            NOT NULL
)
TABLESPACE users;

ALTER TABLE commit_link
      ADD (CONSTRAINT pk_commit_link PRIMARY KEY (id),
      CONSTRAINT fk_commit_link_task FOREIGN KEY (task_id) REFERENCES task(id),
      CONSTRAINT uq_commit_link_task_commit UNIQUE (task_id, provider, repo_full_name, commit_sha),
      CONSTRAINT chk_commit_link_provider CHECK (provider IN ('GITHUB', 'GITLAB', 'AZURE_DEVOPS'))); 

CREATE TABLE pr_link(
  id                NUMBER          NOT NULL
  ,task_id          NUMBER          NOT NULL
  ,provider         VARCHAR2(16)    NOT NULL
  ,repo_full_name   VARCHAR2(255)   NOT NULL
  ,pr_number        NUMBER          NOT NULL
  ,title            VARCHAR2(255)
  ,state            VARCHAR2(24)    NOT NULL
  ,created_at       DATE            DEFAULT SYSDATE NOT NULL
  ,merged_at        DATE
)
TABLESPACE users;

ALTER TABLE pr_link
      ADD (CONSTRAINT pk_pr_link PRIMARY KEY (id),
      CONSTRAINT fk_pr_link_task FOREIGN KEY (task_id) REFERENCES task(id),
      CONSTRAINT uq_pr_link_task_pr UNIQUE (task_id, provider, repo_full_name, pr_number),
      CONSTRAINT chk_pr_link_provider CHECK (provider IN ('GITHUB', 'GITLAB', 'AZURE_DEVOPS')),
      CONSTRAINT chk_pr_link_state CHECK (state IN ('OPEN', 'CLOSED', 'MERGED')));

CREATE TABLE attachment(
  id                NUMBER            NOT NULL
  ,task_id          NUMBER            NOT NULL
  ,uploaded_by      NUMBER            NOT NULL
  ,file_name        VARCHAR2(255)     NOT NULL
  ,content_type     VARCHAR2(128)     NOT NULL
  ,size_bytes       NUMBER            NOT NULL
  ,storage_path     VARCHAR2(255)     NOT NULL
  ,attachment_type  VARCHAR2(16)
  ,created_at       DATE              DEFAULT SYSDATE NOT NULL
)
TABLESPACE users;

ALTER TABLE attachment
      ADD (CONSTRAINT pk_attachment PRIMARY KEY (id),
      CONSTRAINT fk_attachment_task FOREIGN KEY (task_id) REFERENCES task(id),
      CONSTRAINT fk_attachment_uploaded_by FOREIGN KEY (uploaded_by) REFERENCES app_user(id),
      CONSTRAINT chk_attachment_size_positive CHECK (size_bytes > 0),
      CONSTRAINT uq_attachment_storage_path UNIQUE (storage_path));




