


-- create_all_tables_script.sql

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
)
TABLESPACE users;

ALTER TABLE app_user
      ADD CONSTRAINT app_user_pk PRIMARY KEY (id);
      
CREATE SEQUENCE app_user_seq START WITH 100;

COMMENT ON TABLE app_user IS
  'Felhasználói tábla: bejelentkezési adatok, alap profil információk.';

COMMENT ON COLUMN app_user.id IS 'Egyedi felhasználó azonosító.';
COMMENT ON COLUMN app_user.email IS 'E-mail cím, egyedi, belépéshez használt.';
COMMENT ON COLUMN app_user.display_name IS 'Felhasználó megjelenített neve.';
COMMENT ON COLUMN app_user.password_hash IS 'Titkosított jelszó.';
COMMENT ON COLUMN app_user.is_active IS 'Aktivitási státusz.';

CREATE TABLE app_role(
  id           NUMBER         NOT NULL
  ,role_name   VARCHAR2(64)   UNIQUE NOT NULL
  ,description VARCHAR2(255)
  ,created_at  DATE           DEFAULT SYSDATE NOT NULL
)
TABLESPACE users;

ALTER TABLE app_role
      ADD CONSTRAINT pk_app_role PRIMARY KEY (id);

CREATE SEQUENCE app_role_seq START WITH 1;

COMMENT ON TABLE app_role IS
  'Felhasználói szerepkörök (jogkörök csoportosítása).';

COMMENT ON COLUMN app_role.role_name IS 'Szerepkör neve, egyedi.';

CREATE TABLE app_project(
  id              NUMBER          PRIMARY KEY
  ,project_name   VARCHAR2(140)   UNIQUE NOT NULL
  ,proj_key       VARCHAR2(16)    UNIQUE NOT NULL
  ,task_seq_name  VARCHAR2(30)    
  ,description    VARCHAR2(2000)
  ,owner_id       NUMBER
  ,is_archived    NUMBER(1)       DEFAULT 0 NOT NULL
  ,created_at     DATE            DEFAULT SYSDATE NOT NULL
)
TABLESPACE users;

ALTER TABLE app_project
      ADD CONSTRAINT fk_app_project_owner FOREIGN KEY (owner_id) REFERENCES app_user(id);

CREATE SEQUENCE app_project_seq START WITH 1;

COMMENT ON TABLE app_project IS
  'Projekt entitás: feladatok és boardok szervezése.';

COMMENT ON COLUMN app_project.proj_key IS 'Projekt kulcs, pl: PMA, amelyből a task azonosítók képződnek. (pl: PMA-100)';
COMMENT ON COLUMN app_project.is_archived IS 'Archivált-e a projekt, akkor amikor vége van.';

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

CREATE SEQUENCE app_user_role_seq START WITH 1;

COMMENT ON TABLE app_user_role IS
  'Felhasználó - szerepkör hozzárendelések.';

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

COMMENT ON TABLE project_member IS
  'Projekt - felhasználó hozzárendelések a csapattagság kezeléséhez.';

COMMENT ON COLUMN project_member.project_role IS 'Felhasználó projektbeli szerepe (pl. fejlesztő, reviewer, projekt manager, stb).';

CREATE TABLE app_activity(
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

ALTER TABLE app_activity
      ADD (CONSTRAINT pk_app_activity PRIMARY KEY (id),
      CONSTRAINT fk_app_activity_project FOREIGN KEY (project_id) REFERENCES app_project(id),
      CONSTRAINT fk_app_activity_user FOREIGN KEY (actor_id) REFERENCES app_user(id));

CREATE SEQUENCE app_activity_seq START WITH 1;

COMMENT ON TABLE app_activity IS
  'Felhasználói események naplózása: KI MIT, MIKOR, MIT módosított / hozzáadott / létrehozott. 
  Olyan napló amit a felhasználók is látnak a UI-on, 
  hogy tudják hogy milyen események történtek a közelmultban.';

COMMENT ON COLUMN app_activity.entity_type IS 'Érintett entitás típusa (TASK, COMMENT, PR, stb).';
COMMENT ON COLUMN app_activity.entity_id IS 'Érintett entitás azonosítója.';
COMMENT ON COLUMN app_activity.action IS 'A végrehajtott művelet.';

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

CREATE SEQUENCE labels_seq START WITH 1;

COMMENT ON TABLE labels IS
  'Feladatok kategorizálására szolgáló címkék egy projekten belül.';

COMMENT ON COLUMN labels.color IS
  'Címke színe hex formátumban (#RRGGBB).';

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
      ADD(
      CONSTRAINT pk_board PRIMARY KEY (id),
      CONSTRAINT fk_board_project FOREIGN KEY (project_id) REFERENCES app_project(id),
      CONSTRAINT uq_board_name_project UNIQUE (project_id, board_name)
      );
      
CREATE SEQUENCE board_seq START WITH 1;

COMMENT ON TABLE board IS
  'Kanban board, amely egy projekt oszlopait és vizuális felépítését adja.';
  
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

CREATE SEQUENCE integration_seq START WITH 1;

COMMENT ON TABLE integration IS
  'Projekt - külső rendszer (GitHub, GitLab) integráció beállításai.';
  
CREATE TABLE column_def(
  id                NUMBER        NOT NULL
  ,board_id         NUMBER        NOT NULL
  ,column_name      VARCHAR2(64)  NOT NULL
  ,wip_limit        NUMBER
  ,position         NUMBER        NOT NULL
  ,status_id        NUMBER
)
TABLESPACE users;

ALTER TABLE column_def
   ADD(
      CONSTRAINT pk_column_def PRIMARY KEY (id),
      CONSTRAINT fk_column_def_board FOREIGN KEY (board_id) REFERENCES board(id),
      CONSTRAINT uq_column_def_name_per_board UNIQUE (board_id, column_name),
      CONSTRAINT uq_column_def_pos_per_board UNIQUE (board_id, position),
      CONSTRAINT chk_column_def_wip_positive CHECK (wip_limit > 0),
      CONSTRAINT uq_column_def_status_per_board UNIQUE (board_id, status_id),
      CONSTRAINT fk_column_def_status FOREIGN KEY (status_id) REFERENCES task_status(id)
   );

CREATE SEQUENCE column_def_seq START WITH 1;

COMMENT ON TABLE column_def IS
  'Board oszlopok definíciója, WIP limitek, pozíció és kapcsolt státusz.';

CREATE TABLE sprint(
  id            NUMBER        NOT NULL
  ,project_id   NUMBER        NOT NULL
  ,board_id     NUMBER        NOT NULL
  ,sprint_name  VARCHAR2(64)  NOT NULL
  ,goal         VARCHAR2(255) NOT NULL
  ,start_date   DATE          DEFAULT SYSDATE NOT NULL
  ,end_date     DATE          NOT NULL
  ,state        VARCHAR2(16)  NOT NULL
)
TABLESPACE users;

ALTER TABLE sprint
      ADD (CONSTRAINT pk_sprint PRIMARY KEY (id),
      CONSTRAINT fk_sprint_project FOREIGN KEY (project_id) REFERENCES app_project(id),
      CONSTRAINT fk_sprint_board FOREIGN KEY (board_id) REFERENCES board(id),
      CONSTRAINT uq_sprint_name_per_project UNIQUE (project_id, sprint_name),
      CONSTRAINT chk_sprint_dates_valid CHECK (end_date >= start_date),
      CONSTRAINT chk_sprint_state CHECK (state IN ('PLANNED', 'ACTIVE', 'COMPLETED', 'CANCELLED')));

CREATE SEQUENCE sprint_seq START WITH 1;

COMMENT ON TABLE sprint IS
  'Időszakos fejlesztési ciklus (Scrum sprint), státuszkezeléssel.';

CREATE TABLE task(
  id              NUMBER        NOT NULL
  ,project_id     NUMBER        NOT NULL
  ,board_id       NUMBER        NOT NULL
  ,column_id      NUMBER        NOT NULL
  ,sprint_id      NUMBER        NOT NULL
  ,created_by     NUMBER        NOT NULL
  ,task_key       VARCHAR2(32)  NOT NULL
  ,title          VARCHAR2(128) NOT NULL
  ,description    VARCHAR2(512)
  ,status_id      NUMBER        NOT NULL
  ,priority       VARCHAR2(32)
  ,estimated_min  NUMBER
  ,due_date       DATE
  ,closed_at      DATE
  ,position       NUMBER
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
COMMENT ON COLUMN task.created_by IS 'Létrehozó felhasználó azonosítója.';
COMMENT ON COLUMN task.closed_at IS 'Lezárás időpontja, ha van.';

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

COMMENT ON TABLE task_assignment IS
  'Feladat - felelős hozzárendelése, semennyi vagy több assignee.';

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


CREATE TABLE app_comment(
  id              NUMBER          NOT NULL
  ,task_id        NUMBER          NOT NULL
  ,user_id        NUMBER          NOT NULL
  ,comment_body   VARCHAR2(1024)  NOT NULL
  ,created_at     DATE            DEFAULT SYSDATE NOT NULL
)
TABLESPACE users;

ALTER TABLE app_comment
      ADD (CONSTRAINT pk_app_comment PRIMARY KEY (id),
      CONSTRAINT fk_app_comment_task FOREIGN KEY (task_id) REFERENCES task(id),
      CONSTRAINT fk_app_comment_app_user FOREIGN KEY (user_id) REFERENCES app_user(id));

CREATE SEQUENCE app_comment_seq START WITH 1;

COMMENT ON TABLE app_comment IS
  'Kommentek feladatokhoz.';

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

CREATE SEQUENCE commit_link_seq START WITH 1;

COMMENT ON TABLE commit_link IS
  'Commit hivatkozások (repo, provider, SHA) taskokhoz kapcsolva. 
  pl: Ha egy taskhoz kapcsolódó commit jött egy taskra, akkor az megjelenjen a task-nál';

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

CREATE SEQUENCE pr_link_seq START WITH 100;

COMMENT ON TABLE pr_link IS
  'Pull Request hivatkozások taskokhoz, állapot és metaadatok.
  A commit-hoz hasonlóan megjelenik a tasknál egy pr, és annak status-át is jelezve';

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
      
CREATE SEQUENCE attachment_seq START WITH 1;

CREATE TABLE app_error_log (
  id              NUMBER          NOT NULL,
  err_time        DATE            DEFAULT SYSDATE NOT NULL,
  module_name     VARCHAR2(128),
  procedure_name  VARCHAR2(128),
  error_code      NUMBER,
  error_msg       VARCHAR2(4000),
  context         VARCHAR2(4000),
  api varchar2(100)
)
TABLESPACE users;

ALTER TABLE app_error_log
  ADD CONSTRAINT pk_app_error_log PRIMARY KEY (id);

CREATE SEQUENCE app_error_log_seq START WITH 1;

COMMENT ON TABLE app_error_log IS
  'Alkalmazás szintű hiba log tábla.';

-- create_all_types_script.sql

CREATE TYPE ty_task_overview AS OBJECT
(
  task_id          NUMBER,
  task_key         VARCHAR2(32),
  title            VARCHAR2(128),
  description      VARCHAR2(512),
  status_code      VARCHAR2(32),
  status_name      VARCHAR2(64),
  task_position    NUMBER,
  priority         VARCHAR2(32),
  last_modified    DATE,
  due_date         DATE,
  closed_at        DATE,
  created_by_id    NUMBER,
  created_by_name  VARCHAR2(120),
  sprint_id        NUMBER,
  sprint_name      VARCHAR2(64),
  
  -- Aggregációs mezők
  assignees_text VARCHAR2(400),
  attachment_count NUMBER,
  attachment_types VARCHAR2(200),
  labels_text      VARCHAR2(400),
  has_commit       CHAR(1),
  has_pr           CHAR(1)
)
;

CREATE OR REPLACE TYPE ty_task_overview_l AS TABLE OF ty_task_overview;
/


CREATE OR REPLACE TYPE ty_column_overview AS OBJECT
(
  column_id   NUMBER,
  column_name VARCHAR2(64),
  wip_limit   NUMBER,
  status_code VARCHAR2(32),
  status_name VARCHAR2(64),
  tasks       ty_task_overview_l
)
;
/

CREATE OR REPLACE TYPE ty_column_overview_l AS TABLE OF ty_column_overview;
/

CREATE OR REPLACE TYPE ty_board_overview AS OBJECT
(
  board_id    NUMBER,
  board_name  VARCHAR2(64),
  sprint_id   NUMBER,
  sprint_name VARCHAR2(64),
  column_list ty_column_overview_l
)
;
/

-- create_all_packages_functions_procedures.sql

-- Procedure arra hogy automatikus id és created_at adat kerüljön insertkor

CREATE OR REPLACE PROCEDURE create_auto_id_created_trg_prc(p_table_name IN VARCHAR2) IS
  v_tab         VARCHAR2(30);
  v_cnt         NUMBER;
  v_has_created NUMBER;
  v_has_joined  NUMBER;
  v_has_id      NUMBER;
  v_has_seq     NUMBER;
  v_sql         VARCHAR2(32767);

  e_invalid_name     EXCEPTION;
  e_name_too_long    EXCEPTION;
  e_table_not_exists EXCEPTION;
  e_id_but_no_seq    EXCEPTION;
BEGIN
  ------------------------------------------------------------------
  -- 0. Bemenet validálása
  ------------------------------------------------------------------
  IF p_table_name IS NULL
     OR TRIM(p_table_name) IS NULL
  THEN
    RAISE e_invalid_name;
  END IF;

  IF length(TRIM(p_table_name)) > 30
  THEN
    RAISE e_name_too_long;
  END IF;

  v_tab := upper(TRIM(p_table_name));

  SELECT COUNT(*) INTO v_cnt FROM user_tables WHERE table_name = v_tab;

  IF v_cnt = 0
  THEN
    RAISE e_table_not_exists;
  END IF;

  ------------------------------------------------------------------
  -- 1. Oszlopok vizsgálata: CREATED_AT, JOINED_AT, ID
  ------------------------------------------------------------------
  SELECT COUNT(*)
    INTO v_has_created
    FROM user_tab_cols
   WHERE table_name = v_tab
     AND column_name = 'CREATED_AT';

  SELECT COUNT(*)
    INTO v_has_joined
    FROM user_tab_cols
   WHERE table_name = v_tab
     AND column_name = 'JOINED_AT';

  SELECT COUNT(*)
    INTO v_has_id
    FROM user_tab_cols
   WHERE table_name = v_tab
     AND column_name = 'ID';

  -- Ha van ID oszlop, legyen hozzá <TABLE>_SEQ sequence is
  IF v_has_id > 0
  THEN
    SELECT COUNT(*)
      INTO v_has_seq
      FROM user_sequences
     WHERE sequence_name = v_tab || '_SEQ';
  
    IF v_has_seq = 0
    THEN
      RAISE e_id_but_no_seq;
    END IF;
  END IF;

  ------------------------------------------------------------------
  -- 2. Ha sem CREATED_AT, sem ID, sem (PROJECT_MEMBER JOINED_AT), nem csinálunk semmit
  ------------------------------------------------------------------
  IF v_has_created = 0
     AND v_has_id = 0
     AND NOT (v_tab = 'PROJECT_MEMBER' AND v_has_joined > 0)
  THEN
    RETURN;
  END IF;

  ------------------------------------------------------------------
  -- 3. Trigger szöveg generálása
  ------------------------------------------------------------------
  v_sql := 'CREATE OR REPLACE TRIGGER ' || v_tab || '_BI_AUTO ' ||
           'BEFORE INSERT ON ' || v_tab || ' ' || 'FOR EACH ROW ' ||
           'BEGIN ';

  -- CREATED_AT töltése, ha van ilyen oszlop
  IF v_has_created > 0
  THEN
    v_sql := v_sql || 'IF :NEW.created_at IS NULL THEN ' ||
             '  :NEW.created_at := SYSDATE; ' || 'END IF; ';
  END IF;

  -- PROJECT_MEMBER esetén a JOINED_AT-et is töltsük
  IF v_tab = 'PROJECT_MEMBER'
     AND v_has_joined > 0
  THEN
    v_sql := v_sql || 'IF :NEW.joined_at IS NULL THEN ' ||
             '  :NEW.joined_at := SYSDATE; ' || 'END IF; ';
  END IF;

  -- ID töltése, ha van ID oszlop + létezik <TABLE>_SEQ
  IF v_has_id > 0
  THEN
    v_sql := v_sql || 'IF :NEW.id IS NULL THEN ' || '  SELECT ' || v_tab ||
             '_SEQ.NEXTVAL INTO :NEW.id FROM dual; ' || 'END IF; ';
  END IF;

  v_sql := v_sql || 'END;';

  ------------------------------------------------------------------
  -- 4. Trigger létrehozása
  ------------------------------------------------------------------
  EXECUTE IMMEDIATE v_sql;

EXCEPTION
  WHEN e_invalid_name THEN
    raise_application_error(-20100,
                            'create_auto_id_created_trg_prc: table name must not be NULL or empty.');
  
  WHEN e_name_too_long THEN
    raise_application_error(-20101,
                            'create_auto_id_created_trg_prc: table name "' ||
                            TRIM(p_table_name) ||
                            '" is longer than 30 characters.');
  
  WHEN e_table_not_exists THEN
    raise_application_error(-20102,
                            'create_auto_id_created_trg_prc: table "' ||
                            v_tab || '" does not exist in current schema.');
  
  WHEN e_id_but_no_seq THEN
    raise_application_error(-20103,
                            'create_auto_id_created_trg_prc: table "' ||
                            v_tab || '" has ID column but no sequence "' ||
                            v_tab || '_SEQ".');
  
  WHEN OTHERS THEN
    raise_application_error(-20199,
                            'create_auto_id_created_trg_prc failed for table: "' ||
                            nvl(v_tab, TRIM(p_table_name)) || '": ' ||
                            SQLERRM);
END;
/

-- Automatikus _h táblák és triggerek létrehozása a táblákhoz

CREATE OR REPLACE PROCEDURE create_historisation_for_table(p_table_name IN VARCHAR2) IS
  v_tab        VARCHAR2(30);
  -- Max 30 karakter hossz miatt limitálom a bementetet.
  v_cnt        NUMBER;
  v_col_list   VARCHAR2(32767);
  v_new_list   VARCHAR2(32767);
  v_old_del_list VARCHAR2(32767);
  v_sql        VARCHAR2(32767);
  
  e_invalid_name      EXCEPTION;
  e_name_too_long     EXCEPTION;
  e_table_not_exists  EXCEPTION;
BEGIN
  ----------------------------------------------------------------------------
  -- 0. Input validáció + korrekció
  ----------------------------------------------------------------------------
  IF p_table_name IS NULL OR TRIM(p_table_name) IS NULL THEN
     RAISE e_invalid_name;
  END IF;

  IF LENGTH(TRIM(p_table_name)) > 30 THEN
    RAISE e_name_too_long;
  END IF;

  v_tab := UPPER(TRIM(p_table_name));
  
  SELECT COUNT(*)
  INTO v_cnt
  FROM user_tables
  WHERE table_name = v_tab;
  IF v_cnt = 0 THEN
    RAISE e_table_not_exists;
  END IF;
  
  ----------------------------------------------------------------------------
  -- 1. Oszlopok hozzáadása: MOD_USER, DML_FLAG, LAST_MODIFIED, VERSION
  ----------------------------------------------------------------------------

  -- MOD_USER
  SELECT COUNT(*) INTO v_cnt
  FROM user_tab_cols
  WHERE table_name = v_tab
    AND column_name = 'MOD_USER';
  -- Ellenörzés hogy létezik e a hozzáadandó oszlop
  
  IF v_cnt = 0 THEN
    EXECUTE IMMEDIATE
      'ALTER TABLE ' || v_tab || ' ADD (mod_user VARCHAR2(300))';
  END IF;

  -- DML_FLAG
  SELECT COUNT(*) INTO v_cnt
  FROM user_tab_cols
  WHERE table_name = v_tab
    AND column_name = 'DML_FLAG';

  IF v_cnt = 0 THEN
    EXECUTE IMMEDIATE
      'ALTER TABLE ' || v_tab || ' ADD (dml_flag VARCHAR2(1))';
  END IF;

  -- LAST_MODIFIED
  SELECT COUNT(*) INTO v_cnt
  FROM user_tab_cols
  WHERE table_name = v_tab
    AND column_name = 'LAST_MODIFIED';

  IF v_cnt = 0 THEN
    EXECUTE IMMEDIATE
      'ALTER TABLE ' || v_tab || ' ADD (last_modified DATE)';
  END IF;

  -- VERSION
  SELECT COUNT(*) INTO v_cnt
  FROM user_tab_cols
  WHERE table_name = v_tab
    AND column_name = 'VERSION';

  IF v_cnt = 0 THEN
    EXECUTE IMMEDIATE
      'ALTER TABLE ' || v_tab || ' ADD (version NUMBER)';
  END IF;

  ------------------------------------------------------------------
  -- 2. HISTORY tábla létrehozása: <TABLE>_H
  --    csak minden oszlop átmásolása
  ------------------------------------------------------------------

  SELECT COUNT(*) INTO v_cnt
  FROM user_tables
  WHERE table_name = v_tab || '_H';

  IF v_cnt = 0 THEN
    v_sql :=
      'CREATE TABLE ' || v_tab || '_H AS ' ||
      'SELECT * FROM ' || v_tab || ' WHERE 1 = 2';
    EXECUTE IMMEDIATE v_sql;
  END IF;

  ------------------------------------------------------------------
  -- 3. Oszloplista legenerálása a triggerekhez
  ------------------------------------------------------------------

  v_col_list := NULL;
  v_new_list := NULL;
  v_old_del_list := NULL;

  FOR c IN (
    SELECT column_name
    FROM user_tab_cols
    WHERE table_name = v_tab
    ORDER BY column_id
  ) LOOP
    -- közös oszloplista
    IF v_col_list IS NULL THEN
      v_col_list := c.column_name;
    ELSE
      v_col_list := v_col_list || ',' || c.column_name;
    END IF;

    -- INSERT/UPDATE esetén :NEW.<column> a DML_FLAG-et már kezeltem a másik triggerben.
    IF v_new_list IS NULL THEN
      v_new_list := ':NEW.' || c.column_name;
    ELSE
      v_new_list := v_new_list || ',:NEW.' || c.column_name;
    END IF;

    -- DELETE esetén: minden :OLD.<column>, KIVÉVE DML_FLAG = 'D'.
    IF c.column_name = 'DML_FLAG' THEN
      IF v_old_del_list IS NULL THEN
        v_old_del_list := '''D''';
      ELSE
        v_old_del_list := v_old_del_list || ',''D''';
      END IF;
    ELSE
      IF v_old_del_list IS NULL THEN
        v_old_del_list := ':OLD.' || c.column_name;
      ELSE
        v_old_del_list := v_old_del_list || ',:OLD.' || c.column_name;
      END IF;
    END IF;
  END LOOP;

  ------------------------------------------------------------------
  -- 4. BEFORE INSERT/UPDATE trigger: <TABLE>_TRG
  --    mod_user, dml_flag, last_modified, version töltése
  ------------------------------------------------------------------

  v_sql :=
    'CREATE OR REPLACE TRIGGER ' || v_tab || '_TRG ' ||
    'BEFORE INSERT OR UPDATE ON ' || v_tab || ' ' ||
    'FOR EACH ROW ' ||
    'BEGIN ' ||
    '  IF INSERTING THEN ' ||
    '    :NEW.mod_user      := sys_context(''USERENV'',''OS_USER''); ' ||
    '    :NEW.dml_flag      := ''I''; ' ||
    '    :NEW.last_modified := SYSDATE; ' ||
    '    :NEW.version       := NVL(:NEW.version, 1); ' ||
    '  ELSE ' ||
    '    :NEW.mod_user      := sys_context(''USERENV'',''OS_USER''); ' ||
    '    :NEW.dml_flag      := ''U''; ' ||
    '    :NEW.last_modified := SYSDATE; ' ||
    '    :NEW.version       := NVL(:OLD.version, 0) + 1; ' ||
    '  END IF; ' ||
    'END;';

  EXECUTE IMMEDIATE v_sql;

  ------------------------------------------------------------------
  -- 5. AFTER INSERT/UPDATE/DELETE trigger: <TABLE>_H_TRG
  --    history logolás <TABLE>_H táblába (dump)
  ------------------------------------------------------------------

  v_sql :=
    'CREATE OR REPLACE TRIGGER ' || v_tab || '_H_TRG ' ||
    'AFTER INSERT OR UPDATE OR DELETE ON ' || v_tab || ' ' ||
    'FOR EACH ROW ' ||
    'BEGIN ' ||
    '  IF DELETING THEN ' ||
    '    INSERT INTO ' || v_tab || '_H (' || v_col_list || ') ' ||
    '    VALUES (' || v_old_del_list || '); ' ||
    '  ELSE ' ||
    '    INSERT INTO ' || v_tab || '_H (' || v_col_list || ') ' ||
    '    VALUES (' || v_new_list || '); ' ||
    '  END IF; ' ||
    'END;';

  EXECUTE IMMEDIATE v_sql;
  
EXCEPTION
  WHEN e_invalid_name THEN
    RAISE_APPLICATION_ERROR(
      -20000,
      'create_historisation_for_table: table name must not be NULL or empty.'
    );
    RAISE;
  WHEN e_name_too_long THEN
    RAISE_APPLICATION_ERROR(
      -20001,
      'create_historisation_for_table: table name: "' || p_table_name ||
      '" is longer than 30 characters (Oracle 11g limit).'
    );
    RAISE;
  WHEN e_table_not_exists THEN
    RAISE_APPLICATION_ERROR(
      -20002,
      'create_historisation_for_table: table "' || v_tab ||
      '" does not exist in current schema.'
    );
    RAISE;
  WHEN OTHERS THEN
    RAISE_APPLICATION_ERROR(
      -20009,
      'create_historisation_for_table failed for table "' ||
      NVL(v_tab, p_table_name) || '": ' || SQLERRM
    );
    RAISE;
END;
/
-- automatikus id és created at trg-k létrehozása

BEGIN
  create_auto_id_created_trg_prc('APP_USER');
  create_auto_id_created_trg_prc('APP_ROLE');
  create_auto_id_created_trg_prc('APP_PROJECT');
  create_auto_id_created_trg_prc('PROJECT_MEMBER');
  create_auto_id_created_trg_prc('TASK_STATUS');
  create_auto_id_created_trg_prc('BOARD');
  create_auto_id_created_trg_prc('COLUMN_DEF');
  create_auto_id_created_trg_prc('SPRINT');
  create_auto_id_created_trg_prc('TASK');
  create_auto_id_created_trg_prc('LABELS');
  create_auto_id_created_trg_prc('TASK_ASSIGNMENT');
  create_auto_id_created_trg_prc('APP_COMMENT');
  create_auto_id_created_trg_prc('INTEGRATION');
  create_auto_id_created_trg_prc('COMMIT_LINK');
  create_auto_id_created_trg_prc('PR_LINK');
  create_auto_id_created_trg_prc('ATTACHMENT');
  create_auto_id_created_trg_prc('APP_ACTIVITY');
END;
/

-- _h history táblák létrehozása
BEGIN
  create_historisation_for_table('APP_PROJECT');
  create_historisation_for_table('TASK');
  create_historisation_for_table('TASK_STATUS');
  create_historisation_for_table('task_assignment');
  create_historisation_for_table('SPRINT');
  create_historisation_for_table('APP_COMMENT');
  create_historisation_for_table('BOARD');
  create_historisation_for_table('COLUMN_DEF');
  create_historisation_for_table('PROJECT_MEMBER');
  create_historisation_for_table('APP_USER_ROLE');
END;
/
-- automatikus project key generálás taskokhoz

CREATE OR REPLACE FUNCTION build_next_task_key_fnc(p_project_id IN NUMBER)
  RETURN VARCHAR2 IS
  l_proj_key app_project.proj_key%TYPE;
  l_seq_name app_project.task_seq_name%TYPE;
  l_next_num NUMBER;
BEGIN
  ------------------------------------------------------------------
  -- Projekt kulcs és a hozzá tartozó sequence név beolvasása
  ------------------------------------------------------------------
  SELECT proj_key
        ,task_seq_name
    INTO l_proj_key
        ,l_seq_name
    FROM app_project
   WHERE id = p_project_id;

  ------------------------------------------------------------------
  -- Ha még nincs sequence név eltárolva, generáljuk és hozzuk létre
  ------------------------------------------------------------------
  IF l_seq_name IS NULL
  THEN
    l_seq_name := build_task_seq_name_fnc(l_proj_key);
  
    -- próbáljuk létrehozni a sequence-et; ha már létezik, nem baj
    BEGIN
      EXECUTE IMMEDIATE 'CREATE SEQUENCE ' || l_seq_name ||
                        ' START WITH 1 INCREMENT BY 1';
    END;
  
    UPDATE app_project
       SET task_seq_name = l_seq_name
     WHERE id = p_project_id;
  END IF;

  ------------------------------------------------------------------
  -- Következő sorszám lekérése a sequence-ből
  ------------------------------------------------------------------
  EXECUTE IMMEDIATE 'SELECT ' || l_seq_name || '.NEXTVAL FROM dual'
    INTO l_next_num;

  RETURN l_proj_key || '-' || lpad(l_next_num, 4, '0');
END;
/

CREATE OR REPLACE FUNCTION build_task_seq_name_fnc(p_proj_key IN VARCHAR2)
  RETURN VARCHAR2 IS
  l_base_name VARCHAR2(30);
  l_seq_name  VARCHAR2(30);
BEGIN
  l_base_name := upper(p_proj_key);

  -- csak A–Z, 0–9, egyébként cseréljük
  l_base_name := regexp_replace(l_base_name, '[^A-Z0-9_]', '_');

  -- ha számmal kezdődne, tegyünk elé 'P_'
  IF regexp_like(l_base_name, '^[0-9]')
  THEN
    l_base_name := 'P_' || l_base_name;
  END IF;

  -- név: <base>_SEQ, max 30 karakter
  l_seq_name := substr(l_base_name || '_SEQ', 1, 30);

  RETURN l_seq_name;
END;
/

CREATE OR REPLACE TRIGGER task_auto_key_trg
  BEFORE INSERT ON task
  FOR EACH ROW
BEGIN
  IF :NEW.task_key IS NULL THEN
    :NEW.task_key := build_next_task_key_fnc(:NEW.project_id);
  END IF;
END task_auto_key_trg;
/

CREATE OR REPLACE TRIGGER task_status_sync_trg
  BEFORE INSERT OR UPDATE ON task
  FOR EACH ROW
DECLARE
  l_status_id column_def.status_id%TYPE;
BEGIN
  -- Ha nincs column_id, nem tudunk szinkronizálni
  IF :new.column_id IS NULL
  THEN
    RETURN;
  END IF;

  -- Lekérjük az adott oszlophoz tartozó status_id-t
  SELECT status_id
    INTO l_status_id
    FROM column_def
   WHERE id = :new.column_id;

  -- Felülírjuk a task status_id-ját az oszlop statuszával
  :new.status_id := l_status_id;

EXCEPTION
  WHEN no_data_found THEN
    raise_application_error(-21000,
                            'task_status_sync_trg: nincs ilyen column_def.id: ' ||
                            :new.column_id);
END;
/



-- Packagek

CREATE OR REPLACE PACKAGE pkg_exceptions IS

  --------------------------------------------------------------------
  -- CREATE_COLUMN
  --------------------------------------------------------------------

  create_column_status_not_found EXCEPTION;
  PRAGMA EXCEPTION_INIT(create_column_status_not_found, -20080);

  create_column_dup EXCEPTION;
  PRAGMA EXCEPTION_INIT(create_column_dup, -20081);

  create_column_generic EXCEPTION;
  PRAGMA EXCEPTION_INIT(create_column_generic, -20082);

  --------------------------------------------------------------------
  -- CREATE_TASK
  --------------------------------------------------------------------
  create_task_dup EXCEPTION;
  PRAGMA EXCEPTION_INIT(create_task_dup, -20100);

  create_task_generic EXCEPTION;
  PRAGMA EXCEPTION_INIT(create_task_generic, -20101);

  assign_user_already_assigned EXCEPTION;
  PRAGMA EXCEPTION_INIT(assign_user_already_assigned, -20110);

  assign_user_generic EXCEPTION;
  PRAGMA EXCEPTION_INIT(assign_user_generic, -20111);

  --------------------------------------------------------------------
  -- BOARD / SET DEFAULT
  --------------------------------------------------------------------
  set_default_board_not_in_proj EXCEPTION;
  PRAGMA EXCEPTION_INIT(set_default_board_not_in_proj, -20120);

  set_default_board_generic EXCEPTION;
  PRAGMA EXCEPTION_INIT(set_default_board_generic, -20121);

  --------------------------------------------------------------------
  -- BOARD RENAME
  --------------------------------------------------------------------
  rename_board_not_found EXCEPTION;
  PRAGMA EXCEPTION_INIT(rename_board_not_found, -20130);

  rename_board_duplicate EXCEPTION;
  PRAGMA EXCEPTION_INIT(rename_board_duplicate, -20131);

  rename_board_generic EXCEPTION;
  PRAGMA EXCEPTION_INIT(rename_board_generic, -20132);

  --------------------------------------------------------------------
  -- BOARD REORDER
  --------------------------------------------------------------------
  reorder_board_pos_invalid EXCEPTION;
  PRAGMA EXCEPTION_INIT(reorder_board_pos_invalid, -20140);

  reorder_board_generic EXCEPTION;
  PRAGMA EXCEPTION_INIT(reorder_board_generic, -20141);

  --------------------------------------------------------------------
  -- COLUMN UPDATE
  --------------------------------------------------------------------
  update_column_not_found EXCEPTION;
  PRAGMA EXCEPTION_INIT(update_column_not_found, -20150);

  update_column_duplicate EXCEPTION;
  PRAGMA EXCEPTION_INIT(update_column_duplicate, -20151);

  update_column_generic EXCEPTION;
  PRAGMA EXCEPTION_INIT(update_column_generic, -20152);

  --------------------------------------------------------------------
  -- COLUMN REORDER
  --------------------------------------------------------------------
  reorder_column_pos_invalid EXCEPTION;
  PRAGMA EXCEPTION_INIT(reorder_column_pos_invalid, -20160);

  reorder_column_generic EXCEPTION;
  PRAGMA EXCEPTION_INIT(reorder_column_generic, -20161);

  --------------------------------------------------------------------
  -- TASK MOVE (move_task_to_column_prc)
  --------------------------------------------------------------------
  move_task_board_mismatch EXCEPTION;
  PRAGMA EXCEPTION_INIT(move_task_board_mismatch, -20210);

  move_task_wip_exceeded EXCEPTION;
  PRAGMA EXCEPTION_INIT(move_task_wip_exceeded, -20211);

  move_task_pos_invalid EXCEPTION;
  PRAGMA EXCEPTION_INIT(move_task_pos_invalid, -20212);

  move_task_not_found EXCEPTION;
  PRAGMA EXCEPTION_INIT(move_task_not_found, -20213);

  move_task_generic EXCEPTION;
  PRAGMA EXCEPTION_INIT(move_task_generic, -20214);

  --------------------------------------------------------------------
  -- TASK REORDER (reorder_task_in_column_prc)
  --------------------------------------------------------------------
  reorder_task_pos_invalid EXCEPTION;
  PRAGMA EXCEPTION_INIT(reorder_task_pos_invalid, -20220);

  reorder_task_not_found EXCEPTION;
  PRAGMA EXCEPTION_INIT(reorder_task_not_found, -20221);

  reorder_task_generic EXCEPTION;
  PRAGMA EXCEPTION_INIT(reorder_task_generic, -20222);

  --------------------------------------------------------------------
  -- TASK STATUS SYNC TRIGGER
  --------------------------------------------------------------------
  task_status_column_not_found EXCEPTION;
  PRAGMA EXCEPTION_INIT(task_status_column_not_found, -20300);

  --------------------------------------------------------------------
  -- BOARD OVERVIEW PKG
  --------------------------------------------------------------------
  board_overview_board_not_found EXCEPTION;
  PRAGMA EXCEPTION_INIT(board_overview_board_not_found, -20310);

  board_overview_sprint_mismatch EXCEPTION;
  PRAGMA EXCEPTION_INIT(board_overview_sprint_mismatch, -20311);

  board_overview_generic EXCEPTION;
  PRAGMA EXCEPTION_INIT(board_overview_generic, -20312);

  --------------------------------------------------------------------
  -- GIT INTEGRATION
  --------------------------------------------------------------------
  git_integration_not_found EXCEPTION;
  PRAGMA EXCEPTION_INIT(git_integration_not_found, -20320);

  git_message_no_task_key EXCEPTION;
  PRAGMA EXCEPTION_INIT(git_message_no_task_key, -20321);

  git_invalid_event_type EXCEPTION;
  PRAGMA EXCEPTION_INIT(git_invalid_event_type, -20322);

  git_integration_generic EXCEPTION;
  PRAGMA EXCEPTION_INIT(git_integration_generic, -20323);

  ------------------------------------------------------------------
  -- AUTH / ROLE / USER
  ------------------------------------------------------------------
  role_name_duplicate EXCEPTION;
  PRAGMA EXCEPTION_INIT(role_name_duplicate, -20330);

  role_generic_error EXCEPTION;
  PRAGMA EXCEPTION_INIT(role_generic_error, -20331);

  user_email_duplicate EXCEPTION;
  PRAGMA EXCEPTION_INIT(user_email_duplicate, -20332);

  user_generic_error EXCEPTION;
  PRAGMA EXCEPTION_INIT(user_generic_error, -20333);

  user_role_duplicate EXCEPTION;
  PRAGMA EXCEPTION_INIT(user_role_duplicate, -20334);

  user_role_generic EXCEPTION;
  PRAGMA EXCEPTION_INIT(user_role_generic, -20335);

  ------------------------------------------------------------------
  -- PROJECT / PROJECT_MEMBER
  ------------------------------------------------------------------
  project_owner_not_found EXCEPTION;
  PRAGMA EXCEPTION_INIT(project_owner_not_found, -20340);

  project_key_duplicate EXCEPTION;
  PRAGMA EXCEPTION_INIT(project_key_duplicate, -20341);

  project_create_generic EXCEPTION;
  PRAGMA EXCEPTION_INIT(project_create_generic, -20342);

  project_member_duplicate EXCEPTION;
  PRAGMA EXCEPTION_INIT(project_member_duplicate, -20343);

  project_member_generic EXCEPTION;
  PRAGMA EXCEPTION_INIT(project_member_generic, -20344);
  ------------------------------------------------------------------
  -- SPRINT
  ------------------------------------------------------------------
  sprint_project_mismatch EXCEPTION;
  PRAGMA EXCEPTION_INIT(sprint_project_mismatch, -20360);

  sprint_date_invalid EXCEPTION;
  PRAGMA EXCEPTION_INIT(sprint_date_invalid, -20361);

  sprint_create_generic EXCEPTION;
  PRAGMA EXCEPTION_INIT(sprint_create_generic, -20362);

  ------------------------------------------------------------------
  -- LABEL
  ------------------------------------------------------------------
  label_name_duplicate EXCEPTION;
  PRAGMA EXCEPTION_INIT(label_name_duplicate, -20370);

  label_project_not_found EXCEPTION;
  PRAGMA EXCEPTION_INIT(label_project_not_found, -20371);

  label_generic_error EXCEPTION;
  PRAGMA EXCEPTION_INIT(label_generic_error, -20372);

  label_task_duplicate EXCEPTION;
  PRAGMA EXCEPTION_INIT(label_task_duplicate, -20373);

  label_task_generic EXCEPTION;
  PRAGMA EXCEPTION_INIT(label_task_generic, -20374);

  ------------------------------------------------------------------
  -- COMMENT
  ------------------------------------------------------------------
  comment_task_not_found EXCEPTION;
  PRAGMA EXCEPTION_INIT(comment_task_not_found, -20380);

  comment_user_not_found EXCEPTION;
  PRAGMA EXCEPTION_INIT(comment_user_not_found, -20381);

  comment_create_generic EXCEPTION;
  PRAGMA EXCEPTION_INIT(comment_create_generic, -20382);

  ------------------------------------------------------------------
  -- ATTACHMENT
  ------------------------------------------------------------------
  attachment_task_not_found EXCEPTION;
  PRAGMA EXCEPTION_INIT(attachment_task_not_found, -20390);

  attachment_user_not_found EXCEPTION;
  PRAGMA EXCEPTION_INIT(attachment_user_not_found, -20391);

  attachment_generic_error EXCEPTION;
  PRAGMA EXCEPTION_INIT(attachment_generic_error, -20392);

  attachment_cnstraint_violation EXCEPTION;
  PRAGMA EXCEPTION_INIT(attachment_cnstraint_violation, -20393);
  
  ------------------------------------------------------------------
  -- ACTIVITY LOG
  ------------------------------------------------------------------
  activity_project_not_found EXCEPTION;
  PRAGMA EXCEPTION_INIT(activity_project_not_found, -20400);

  activity_actor_not_found EXCEPTION;
  PRAGMA EXCEPTION_INIT(activity_actor_not_found, -20401);

  activity_generic_error EXCEPTION;
  PRAGMA EXCEPTION_INIT(activity_generic_error, -20402);

END pkg_exceptions;
/

CREATE OR REPLACE PACKAGE err_log_pkg IS

  PROCEDURE log_error(p_module_name    IN app_error_log.module_name%TYPE
                     ,p_procedure_name IN app_error_log.procedure_name%TYPE
                     ,p_error_code     IN app_error_log.error_code%TYPE
                     ,p_error_msg      IN app_error_log.error_msg%TYPE
                     ,p_context        IN app_error_log.context%TYPE DEFAULT NULL
                     ,p_api            IN app_error_log.api%TYPE DEFAULT NULL);

END err_log_pkg;
/

CREATE OR REPLACE PACKAGE BODY err_log_pkg IS

  PROCEDURE log_error(p_module_name    IN app_error_log.module_name%TYPE
                     ,p_procedure_name IN app_error_log.procedure_name%TYPE
                     ,p_error_code     IN app_error_log.error_code%TYPE
                     ,p_error_msg      IN app_error_log.error_msg%TYPE
                     ,p_context        IN app_error_log.context%TYPE
                     ,p_api            IN app_error_log.api%TYPE) IS
    PRAGMA AUTONOMOUS_TRANSACTION;
    l_id app_error_log.id%TYPE;
  BEGIN
    l_id := app_error_log_seq.nextval;
  
    INSERT INTO app_error_log
      (id
      ,err_time
      ,module_name
      ,procedure_name
      ,ERROR_CODE
      ,error_msg
      ,CONTEXT
      ,api)
    VALUES
      (l_id
      ,SYSDATE
      ,p_module_name
      ,p_procedure_name
      ,p_error_code
      ,substr(p_error_msg, 1, 4000) -- Biztonság kedvéért vágjuk le hogy biztosan le legyen tultöltés
      ,substr(p_context, 1, 4000)
      ,p_api);
  
  EXCEPTION
    WHEN OTHERS THEN
      NULL;
  END log_error;

END err_log_pkg;
/

CREATE OR REPLACE PACKAGE activity_log_pkg IS

  PROCEDURE log_activity_prc(p_project_id  IN app_activity.project_id%TYPE
                            ,p_actor_id    IN app_activity.actor_id%TYPE
                            ,p_entity_type IN app_activity.entity_type%TYPE
                            ,p_entity_id   IN app_activity.entity_id%TYPE
                            ,p_action      IN app_activity.action%TYPE
                            ,p_payload     IN app_activity.payload%TYPE DEFAULT NULL
                            ,p_activity_id OUT app_activity.id%TYPE);

  ------------------------------------------------------------------
  -- Procedúrák tipikus eseményekre
  ------------------------------------------------------------------

  PROCEDURE log_project_created_prc(p_project_id  IN app_activity.project_id%TYPE
                                   ,p_actor_id    IN app_activity.actor_id%TYPE
                                   ,p_activity_id OUT app_activity.id%TYPE);

  PROCEDURE log_task_created_prc(p_project_id  IN app_activity.project_id%TYPE
                                ,p_actor_id    IN app_activity.actor_id%TYPE
                                ,p_task_id     IN app_activity.entity_id%TYPE
                                ,p_task_title  IN VARCHAR2
                                ,p_activity_id OUT app_activity.id%TYPE);

  PROCEDURE log_task_status_change_prc(p_project_id      IN app_activity.project_id%TYPE
                                      ,p_actor_id        IN app_activity.actor_id%TYPE
                                      ,p_task_id         IN app_activity.entity_id%TYPE
                                      ,p_old_status_code IN VARCHAR2
                                      ,p_new_status_code IN VARCHAR2
                                      ,p_activity_id     OUT app_activity.id%TYPE);

  PROCEDURE log_comment_added_prc(p_project_id  IN app_activity.project_id%TYPE
                                 ,p_actor_id    IN app_activity.actor_id%TYPE
                                 ,p_task_id     IN app_activity.entity_id%TYPE
                                 ,p_comment_id  IN NUMBER
                                 ,p_activity_id OUT app_activity.id%TYPE);

  PROCEDURE log_attachment_added_prc(p_project_id    IN app_activity.project_id%TYPE
                                    ,p_actor_id      IN app_activity.actor_id%TYPE
                                    ,p_task_id       IN app_activity.entity_id%TYPE
                                    ,p_attachment_id IN NUMBER
                                    ,p_file_name     IN VARCHAR2
                                    ,p_activity_id   OUT app_activity.id%TYPE);

END activity_log_pkg;
/

CREATE OR REPLACE PACKAGE BODY activity_log_pkg IS

  -- Általános logoló

  PROCEDURE log_activity_prc(p_project_id  IN app_activity.project_id%TYPE
                            ,p_actor_id    IN app_activity.actor_id%TYPE
                            ,p_entity_type IN app_activity.entity_type%TYPE
                            ,p_entity_id   IN app_activity.entity_id%TYPE
                            ,p_action      IN app_activity.action%TYPE
                            ,p_payload     IN app_activity.payload%TYPE DEFAULT NULL
                            ,p_activity_id OUT app_activity.id%TYPE) IS
  BEGIN
    INSERT INTO app_activity
      (project_id
      ,actor_id
      ,entity_type
      ,entity_id
      ,action
      ,payload)
    VALUES
      (p_project_id
      ,p_actor_id
      ,upper(TRIM(p_entity_type))
      ,p_entity_id
      ,p_action
      ,p_payload)
    RETURNING id INTO p_activity_id;
  
  EXCEPTION
    WHEN OTHERS THEN
      err_log_pkg.log_error(p_module_name    => 'ACTIVITY',
                            p_procedure_name => 'log_activity_prc',
                            p_error_code     => SQLCODE,
                            p_error_msg      => SQLERRM,
                            p_context        => 'project_id=' ||
                                                nvl(to_char(p_project_id),
                                                    'NULL') || '; actor_id=' ||
                                                nvl(to_char(p_actor_id),
                                                    'NULL') ||
                                                '; entity_type=' ||
                                                nvl(p_entity_type, 'NULL') ||
                                                '; entity_id=' ||
                                                nvl(to_char(p_entity_id),
                                                    'NULL') || '; action=' ||
                                                nvl(p_action, 'NULL'),
                            p_api            => NULL);
      RAISE;
  END log_activity_prc;

  ------------------------------------------------------------------
  -- Procedúrák tipikus eseményekre
  ------------------------------------------------------------------

  PROCEDURE log_project_created_prc(p_project_id  IN app_activity.project_id%TYPE
                                   ,p_actor_id    IN app_activity.actor_id%TYPE
                                   ,p_activity_id OUT app_activity.id%TYPE) IS
    l_name app_project.project_name%TYPE;
  BEGIN
    SELECT project_name
      INTO l_name
      FROM app_project
     WHERE id = p_project_id;
  
    log_activity_prc(p_project_id  => p_project_id,
                     p_actor_id    => p_actor_id,
                     p_entity_type => 'PROJECT',
                     p_entity_id   => p_project_id,
                     p_action      => 'PROJECT_CREATE',
                     p_payload     => 'Projekt létrehozva: ' || l_name,
                     p_activity_id => p_activity_id);
  
  EXCEPTION
    WHEN OTHERS THEN
      err_log_pkg.log_error(p_module_name    => 'ACTIVITY',
                            p_procedure_name => 'log_project_created_prc',
                            p_error_code     => SQLCODE,
                            p_error_msg      => SQLERRM,
                            p_context        => 'project_id=' ||
                                                nvl(to_char(p_project_id),
                                                    'NULL') || '; actor_id=' ||
                                                nvl(to_char(p_actor_id),
                                                    'NULL'),
                            p_api            => NULL);
      RAISE;
  END log_project_created_prc;

  PROCEDURE log_task_created_prc(p_project_id  IN app_activity.project_id%TYPE
                                ,p_actor_id    IN app_activity.actor_id%TYPE
                                ,p_task_id     IN app_activity.entity_id%TYPE
                                ,p_task_title  IN VARCHAR2
                                ,p_activity_id OUT app_activity.id%TYPE) IS
  BEGIN
    log_activity_prc(p_project_id  => p_project_id,
                     p_actor_id    => p_actor_id,
                     p_entity_type => 'TASK',
                     p_entity_id   => p_task_id,
                     p_action      => 'TASK_CREATE',
                     p_payload     => 'Új task létrehozva: ' || p_task_title,
                     p_activity_id => p_activity_id);
  END log_task_created_prc;

  PROCEDURE log_task_status_change_prc(p_project_id      IN app_activity.project_id%TYPE
                                      ,p_actor_id        IN app_activity.actor_id%TYPE
                                      ,p_task_id         IN app_activity.entity_id%TYPE
                                      ,p_old_status_code IN VARCHAR2
                                      ,p_new_status_code IN VARCHAR2
                                      ,p_activity_id     OUT app_activity.id%TYPE) IS
  BEGIN
    log_activity_prc(p_project_id  => p_project_id,
                     p_actor_id    => p_actor_id,
                     p_entity_type => 'TASK',
                     p_entity_id   => p_task_id,
                     p_action      => 'TASK_STATUS_CHANGE',
                     p_payload     => 'Task státusz: ' || p_old_status_code ||
                                      ' -> ' || p_new_status_code,
                     p_activity_id => p_activity_id);
  END log_task_status_change_prc;

  PROCEDURE log_comment_added_prc(p_project_id  IN app_activity.project_id%TYPE
                                 ,p_actor_id    IN app_activity.actor_id%TYPE
                                 ,p_task_id     IN app_activity.entity_id%TYPE
                                 ,p_comment_id  IN NUMBER
                                 ,p_activity_id OUT app_activity.id%TYPE) IS
  BEGIN
    log_activity_prc(p_project_id  => p_project_id,
                     p_actor_id    => p_actor_id,
                     p_entity_type => 'COMMENT',
                     p_entity_id   => p_comment_id,
                     p_action      => 'COMMENT_ADDED',
                     p_payload     => 'Komment hozzáadva task_id=' ||
                                      p_task_id,
                     p_activity_id => p_activity_id);
  END log_comment_added_prc;

  PROCEDURE log_attachment_added_prc(p_project_id    IN app_activity.project_id%TYPE
                                    ,p_actor_id      IN app_activity.actor_id%TYPE
                                    ,p_task_id       IN app_activity.entity_id%TYPE
                                    ,p_attachment_id IN NUMBER
                                    ,p_file_name     IN VARCHAR2
                                    ,p_activity_id   OUT app_activity.id%TYPE) IS
  BEGIN
    log_activity_prc(p_project_id  => p_project_id,
                     p_actor_id    => p_actor_id,
                     p_entity_type => 'ATTACHMENT',
                     p_entity_id   => p_attachment_id,
                     p_action      => 'ATTACHMENT_ADDED',
                     p_payload     => 'Attachment hozzáadva: ' ||
                                      p_file_name || ' (task_id=' ||
                                      p_task_id || ')',
                     p_activity_id => p_activity_id);
  END log_attachment_added_prc;

END activity_log_pkg;
/

CREATE OR REPLACE PACKAGE auth_mgmt_pkg IS

  PROCEDURE create_role_prc(p_role_name   IN app_role.role_name%TYPE
                           ,p_description IN app_role.description%TYPE
                           ,p_role_id     OUT app_role.id%TYPE);

  PROCEDURE create_user_prc(p_email         IN app_user.email%TYPE
                           ,p_display_name  IN app_user.display_name%TYPE
                           ,p_password_hash IN app_user.password_hash%TYPE
                           ,p_is_active     IN app_user.is_active%TYPE
                           ,p_user_id       OUT app_user.id%TYPE);

  PROCEDURE assign_role_to_user_prc(p_user_id IN app_user_role.user_id%TYPE
                                   ,p_role_id IN app_user_role.role_id%TYPE);

END auth_mgmt_pkg;
/

CREATE OR REPLACE PACKAGE BODY auth_mgmt_pkg IS

  PROCEDURE create_role_prc(p_role_name   IN app_role.role_name%TYPE
                           ,p_description IN app_role.description%TYPE
                           ,p_role_id     OUT app_role.id%TYPE) IS
  BEGIN
    INSERT INTO app_role
      (role_name
      ,description)
    VALUES
      (p_role_name
      ,p_description)
    RETURNING id INTO p_role_id;
  
  EXCEPTION
    WHEN dup_val_on_index THEN
    
      err_log_pkg.log_error(p_module_name    => 'AUTH',
                            p_procedure_name => 'create_role_prc',
                            p_error_code     => -20330,
                            p_error_msg      => 'Szerepkör név ütközik (ROLE_NAME).',
                            p_context        => 'role_name=' || p_role_name,
                            p_api            => NULL);
      RAISE pkg_exceptions.role_name_duplicate;
    
    WHEN OTHERS THEN
      err_log_pkg.log_error(p_module_name    => 'AUTH',
                            p_procedure_name => 'create_role_prc',
                            p_error_code     => SQLCODE,
                            p_error_msg      => SQLERRM,
                            p_context        => 'role_name=' || p_role_name,
                            p_api            => NULL);
      RAISE pkg_exceptions.role_generic_error;
  END create_role_prc;

  PROCEDURE create_user_prc(p_email         IN app_user.email%TYPE
                           ,p_display_name  IN app_user.display_name%TYPE
                           ,p_password_hash IN app_user.password_hash%TYPE
                           ,p_is_active     IN app_user.is_active%TYPE
                           ,p_user_id       OUT app_user.id%TYPE) IS
  BEGIN
    INSERT INTO app_user
      (email
      ,display_name
      ,password_hash
      ,is_active)
    VALUES
      (p_email
      ,p_display_name
      ,p_password_hash
      ,p_is_active)
    RETURNING id INTO p_user_id;
  
  EXCEPTION
    WHEN dup_val_on_index THEN
      err_log_pkg.log_error(p_module_name    => 'AUTH',
                            p_procedure_name => 'create_user_prc',
                            p_error_code     => -20332,
                            p_error_msg      => 'Email ütközik (APP_USER.EMAIL).',
                            p_context        => 'email=' || p_email,
                            p_api            => NULL);
      RAISE pkg_exceptions.user_email_duplicate;
    
    WHEN OTHERS THEN
      err_log_pkg.log_error(p_module_name    => 'AUTH',
                            p_procedure_name => 'create_user_prc',
                            p_error_code     => SQLCODE,
                            p_error_msg      => SQLERRM,
                            p_context        => 'email=' || p_email,
                            p_api            => NULL);
      RAISE pkg_exceptions.user_generic_error;
  END create_user_prc;

  PROCEDURE assign_role_to_user_prc(p_user_id IN app_user_role.user_id%TYPE
                                   ,p_role_id IN app_user_role.role_id%TYPE) IS
  BEGIN
    INSERT INTO app_user_role
      (user_id
      ,role_id)
    VALUES
      (p_user_id
      ,p_role_id);
  
  EXCEPTION
    WHEN dup_val_on_index THEN
      err_log_pkg.log_error(p_module_name    => 'AUTH',
                            p_procedure_name => 'assign_role_to_user_prc',
                            p_error_code     => -20334,
                            p_error_msg      => 'User már rendelkezik ezzel a szerepkörrel.',
                            p_context        => 'user_id=' || p_user_id ||
                                                '; role_id=' || p_role_id,
                            p_api            => NULL);
      RAISE pkg_exceptions.user_role_duplicate;
    
    WHEN OTHERS THEN
      err_log_pkg.log_error(p_module_name    => 'AUTH',
                            p_procedure_name => 'assign_role_to_user_prc',
                            p_error_code     => SQLCODE,
                            p_error_msg      => SQLERRM,
                            p_context        => 'user_id=' || p_user_id ||
                                                '; role_id=' || p_role_id,
                            p_api            => NULL);
      RAISE pkg_exceptions.user_role_generic;
  END assign_role_to_user_prc;

END auth_mgmt_pkg;
/

CREATE OR REPLACE PACKAGE project_mgmt_pkg IS

  PROCEDURE create_project_prc(p_project_name IN app_project.project_name%TYPE
                              ,p_proj_key     IN app_project.proj_key%TYPE
                              ,p_description  IN app_project.description%TYPE
                              ,p_owner_id     IN app_project.owner_id%TYPE
                              ,p_project_id   OUT app_project.id%TYPE);

  PROCEDURE assign_user_to_project_prc(p_project_id   IN project_member.project_id%TYPE
                                      ,p_user_id      IN project_member.user_id%TYPE
                                      ,p_project_role IN project_member.project_role%TYPE);

END project_mgmt_pkg;
/

CREATE OR REPLACE PACKAGE BODY project_mgmt_pkg IS

  PROCEDURE create_project_prc(p_project_name IN app_project.project_name%TYPE
                              ,p_proj_key     IN app_project.proj_key%TYPE
                              ,p_description  IN app_project.description%TYPE
                              ,p_owner_id     IN app_project.owner_id%TYPE
                              ,p_project_id   OUT app_project.id%TYPE) IS
    l_owner_exists NUMBER;
    l_seq_name     app_project.task_seq_name%TYPE;
    l_activity_id  app_activity.id%TYPE;
  BEGIN
    ----------------------------------------------------------------
    -- Owner user létezésének ellenőrzése
    ----------------------------------------------------------------
    SELECT COUNT(*)
      INTO l_owner_exists
      FROM app_user
     WHERE id = p_owner_id;
  
    IF l_owner_exists = 0
    THEN
      err_log_pkg.log_error(p_module_name    => 'PROJECT',
                            p_procedure_name => 'create_project_prc',
                            p_error_code     => -20340,
                            p_error_msg      => 'Owner user nem létezik.',
                            p_context        => 'owner_id=' || p_owner_id ||
                                                '; project_name=' ||
                                                p_project_name,
                            p_api            => NULL);
      RAISE pkg_exceptions.project_owner_not_found;
    END IF;
  
    ----------------------------------------------------------------
    -- Sequence név generálása a PROJ_KEY alapján
    ----------------------------------------------------------------
    l_seq_name := build_task_seq_name_fnc(p_proj_key);
  
    ----------------------------------------------------------------
    -- Projekt beszúrása, task_seq_name eltárolása
    ----------------------------------------------------------------
    INSERT INTO app_project
      (project_name
      ,proj_key
      ,description
      ,owner_id
      ,task_seq_name)
    VALUES
      (p_project_name
      ,p_proj_key
      ,p_description
      ,p_owner_id
      ,l_seq_name)
    RETURNING id INTO p_project_id;
  
    ----------------------------------------------------------------
    -- A projekt saját task sequence-ének létrehozása
    ----------------------------------------------------------------
    BEGIN
      EXECUTE IMMEDIATE 'CREATE SEQUENCE ' || l_seq_name ||
                        ' START WITH 1 INCREMENT BY 1';  
    END;
  
    ----------------------------------------------------------------
    -- Activity log
    ----------------------------------------------------------------
    BEGIN
      activity_log_pkg.log_project_created_prc(p_project_id  => p_project_id,
                                               p_actor_id    => p_owner_id,
                                               p_activity_id => l_activity_id);
    EXCEPTION
      WHEN OTHERS THEN
        NULL;
    END;
  
  EXCEPTION
    WHEN dup_val_on_index THEN
      err_log_pkg.log_error(p_module_name    => 'PROJECT',
                            p_procedure_name => 'create_project_prc',
                            p_error_code     => -20341,
                            p_error_msg      => 'Projekt kulcs ütközik (PROJ_KEY).',
                            p_context        => 'proj_key=' || p_proj_key,
                            p_api            => NULL);
      RAISE pkg_exceptions.project_key_duplicate;
    
    WHEN OTHERS THEN
      err_log_pkg.log_error(p_module_name    => 'PROJECT',
                            p_procedure_name => 'create_project_prc',
                            p_error_code     => SQLCODE,
                            p_error_msg      => SQLERRM,
                            p_context        => 'project_name=' ||
                                                p_project_name ||
                                                '; proj_key=' || p_proj_key,
                            p_api            => NULL);
      RAISE pkg_exceptions.project_create_generic;
  END create_project_prc;

  PROCEDURE assign_user_to_project_prc(p_project_id   IN project_member.project_id%TYPE
                                      ,p_user_id      IN project_member.user_id%TYPE
                                      ,p_project_role IN project_member.project_role%TYPE) IS
  BEGIN
    INSERT INTO project_member
      (project_id
      ,user_id
      ,project_role)
    VALUES
      (p_project_id
      ,p_user_id
      ,p_project_role);
  
  EXCEPTION
    WHEN dup_val_on_index THEN
      err_log_pkg.log_error(p_module_name    => 'PROJECT',
                            p_procedure_name => 'assign_user_to_project_prc',
                            p_error_code     => -20343,
                            p_error_msg      => 'User már tagja ennek a projektnek.',
                            p_context        => 'project_id=' ||
                                                p_project_id || '; user_id=' ||
                                                p_user_id,
                            p_api            => NULL);
      RAISE pkg_exceptions.project_member_duplicate;
    
    WHEN OTHERS THEN
      err_log_pkg.log_error(p_module_name    => 'PROJECT',
                            p_procedure_name => 'assign_user_to_project_prc',
                            p_error_code     => SQLCODE,
                            p_error_msg      => SQLERRM,
                            p_context        => 'project_id=' ||
                                                p_project_id || '; user_id=' ||
                                                p_user_id,
                            p_api            => NULL);
      RAISE pkg_exceptions.project_member_generic;
  END assign_user_to_project_prc;

END project_mgmt_pkg;
/

CREATE OR REPLACE PACKAGE board_mgmt_pkg IS

  -- BOARD SZINTŰ ELJÁRÁSOK
  
  -- Új board létrehozása egy projekthez
  PROCEDURE create_board_prc(p_project_id IN board.project_id%TYPE
                            ,p_board_name IN board.board_name%TYPE
                            ,p_is_default IN board.is_default%TYPE DEFAULT 0
                            ,p_position   IN board.position%TYPE
                            ,p_board_id   OUT board.id%TYPE);

  -- Alapértelmezett board beállítása egy projekten belül
  PROCEDURE set_default_board_prc(p_project_id IN board.project_id%TYPE
                                 ,p_board_id   IN board.id%TYPE);

  -- Board átnevezése
  PROCEDURE rename_board_prc(p_board_id IN board.id%TYPE
                            ,p_new_name IN board.board_name%TYPE);

  -- Board sorrendjének módosítása projekten belül
  PROCEDURE reorder_board_prc(p_board_id     IN board.id%TYPE
                             ,p_new_position IN board.position%TYPE);

END board_mgmt_pkg;
/

CREATE OR REPLACE PACKAGE BODY board_mgmt_pkg IS
  PROCEDURE create_board_prc(p_project_id IN board.project_id%TYPE
                            ,p_board_name IN board.board_name%TYPE
                            ,p_is_default IN board.is_default%TYPE DEFAULT 0
                            ,p_position   IN board.position%TYPE
                            ,p_board_id   OUT board.id%TYPE) IS
    l_project_cnt NUMBER;
    l_position    board.position%TYPE;
  BEGIN
    ------------------------------------------------------------------
    -- Projekt létezésének ellenőrzése
    ------------------------------------------------------------------
    SELECT COUNT(*)
      INTO l_project_cnt
      FROM app_project
     WHERE id = p_project_id;
  
    IF l_project_cnt = 0
    THEN
      raise_application_error(-20110,
                              'create_board_prc: a megadott projekt nem létezik (project_id=' ||
                              p_project_id || ').');
    END IF;
  
    ------------------------------------------------------------------
    -- Pozíció meghatározása
    -- Ha p_position NULL vagy < 1  a projekt board-listájának végére rakjuk
    ------------------------------------------------------------------
    IF p_position IS NULL
       OR p_position < 1
    THEN
      SELECT nvl(MAX(position), 0) + 1
        INTO l_position
        FROM board
       WHERE project_id = p_project_id;
    ELSE
      l_position := p_position;
    END IF;
  
    ------------------------------------------------------------------
    -- Board beszúrása
    ------------------------------------------------------------------
    INSERT INTO board
      (project_id
      ,board_name
      ,is_default
      ,position
      ,created_at)
    VALUES
      (p_project_id
      ,p_board_name
      ,nvl(p_is_default, 0)
      ,l_position
      ,SYSDATE)
    RETURNING id INTO p_board_id;
  
    ------------------------------------------------------------------
    -- Ha default board, akkor a többi default flag-et levesszük
    ------------------------------------------------------------------
    IF nvl(p_is_default, 0) = 1
    THEN
      -- minden más boardról levesszük az is_default-ot
      UPDATE board
         SET is_default = 0
       WHERE project_id = p_project_id
         AND id <> p_board_id;
    
      -- biztos ami biztos, ezt az egyet 1-re tesszük
      UPDATE board SET is_default = 1 WHERE id = p_board_id;
    END IF;
  
  EXCEPTION
    WHEN dup_val_on_index THEN
      raise_application_error(-20111,
                              'create_board_prc: ütközés az egyedi constrainten (valószínűleg (project_id, board_name) vagy (project_id, position)). ' ||
                              '(project_id=' || p_project_id ||
                              ', board_name="' || p_board_name || '")');
    WHEN OTHERS THEN
      raise_application_error(-20112,
                              'create_board_prc hiba (project_id=' ||
                              p_project_id || ', board_name="' ||
                              p_board_name || '"): ' || SQLERRM);
  END create_board_prc;

  PROCEDURE set_default_board_prc(p_project_id IN board.project_id%TYPE
                                 ,p_board_id   IN board.id%TYPE) IS
    l_cnt NUMBER;
  BEGIN
    ------------------------------------------------------------------
    -- Ellenőrzés: a board tényleg ehhez a projekthez tartozik?
    ------------------------------------------------------------------
    SELECT COUNT(*)
      INTO l_cnt
      FROM board
     WHERE id = p_board_id
       AND project_id = p_project_id;
  
    IF l_cnt = 0
    THEN
      err_log_pkg.log_error(p_module_name    => 'BOARD',
                            p_procedure_name => 'set_default_board_prc',
                            p_error_code     => -20120,
                            p_error_msg      => 'A megadott board nem tartozik a projekthez.',
                            p_context        => 'project_id=' ||
                                                p_project_id ||
                                                '; board_id=' || p_board_id,
                            p_api            => NULL);
      RAISE pkg_exceptions.set_default_board_not_in_proj;
    END IF;
  
    ------------------------------------------------------------------
    -- Minden boardot levesszük default-ról
    ------------------------------------------------------------------
    UPDATE board
       SET is_default = 0
     WHERE project_id = p_project_id
       AND is_default = 1;
  
    ------------------------------------------------------------------
    -- A megadott board lesz az alapértelmezett
    ------------------------------------------------------------------
    UPDATE board SET is_default = 1 WHERE id = p_board_id;
  
  EXCEPTION
    WHEN OTHERS THEN
      err_log_pkg.log_error(p_module_name    => 'BOARD',
                            p_procedure_name => 'set_default_board_prc',
                            p_error_code     => SQLCODE,
                            p_error_msg      => SQLERRM,
                            p_context        => 'project_id=' ||
                                                p_project_id ||
                                                '; board_id=' || p_board_id,
                            p_api            => NULL);
      RAISE pkg_exceptions.set_default_board_generic;
  END set_default_board_prc;

  ----------------------------------------------------------------------------------------------------------------------------------------

  PROCEDURE rename_board_prc(p_board_id IN board.id%TYPE
                            ,p_new_name IN board.board_name%TYPE) IS
  BEGIN
    UPDATE board SET board_name = p_new_name WHERE id = p_board_id;
  
    IF SQL%ROWCOUNT = 0
    THEN
      err_log_pkg.log_error(p_module_name    => 'BOARD',
                            p_procedure_name => 'rename_board_prc',
                            p_error_code     => -20130,
                            p_error_msg      => 'Nem található a megadott board.',
                            p_context        => 'board_id=' || p_board_id ||
                                                '; new_name="' || p_new_name || '"',
                            p_api            => NULL);
      RAISE pkg_exceptions.rename_board_not_found;
    END IF;
  
  EXCEPTION
    WHEN dup_val_on_index THEN
      err_log_pkg.log_error(p_module_name    => 'BOARD',
                            p_procedure_name => 'rename_board_prc',
                            p_error_code     => -20131,
                            p_error_msg      => 'Már létezik ilyen nevű board ugyanabban a projektben.',
                            p_context        => 'board_id=' || p_board_id ||
                                                '; new_name="' || p_new_name || '"',
                            p_api            => NULL);
      RAISE pkg_exceptions.rename_board_duplicate;
    
    WHEN OTHERS THEN
      err_log_pkg.log_error(p_module_name    => 'BOARD',
                            p_procedure_name => 'rename_board_prc',
                            p_error_code     => SQLCODE,
                            p_error_msg      => SQLERRM,
                            p_context        => 'board_id=' || p_board_id ||
                                                '; new_name="' || p_new_name || '"',
                            p_api            => NULL);
      RAISE pkg_exceptions.rename_board_generic;
  END rename_board_prc;

  ----------------------------------------------------------------------------------------------------------------------------------------

  PROCEDURE reorder_board_prc(p_board_id     IN board.id%TYPE
                             ,p_new_position IN board.position%TYPE) IS
    l_project_id board.project_id%TYPE;
    l_old_pos    board.position%TYPE;
  BEGIN
    IF p_new_position < 1
    THEN
      err_log_pkg.log_error(p_module_name    => 'BOARD',
                            p_procedure_name => 'reorder_board_prc',
                            p_error_code     => -20140,
                            p_error_msg      => 'A pozíció nem lehet 1-nél kisebb.',
                            p_context        => 'board_id=' || p_board_id ||
                                                '; new_position=' ||
                                                p_new_position,
                            p_api            => NULL);
      RAISE pkg_exceptions.reorder_board_pos_invalid;
    END IF;
  
    ------------------------------------------------------------------
    -- Board jelenlegi adatai
    ------------------------------------------------------------------
    SELECT project_id
          ,position
      INTO l_project_id
          ,l_old_pos
      FROM board
     WHERE id = p_board_id;
  
    IF p_new_position = l_old_pos
    THEN
      RETURN;
    END IF;
  
    ------------------------------------------------------------------
    -- Az azonos projekthez tartozó boardok pozícióinak eltolása
    ------------------------------------------------------------------
    IF p_new_position < l_old_pos
    THEN
      -- Felfelé mozgatjuk: a köztes boardok lejjebb csúsznak
      UPDATE board
         SET position = position + 1
       WHERE project_id = l_project_id
         AND position >= p_new_position
         AND position < l_old_pos;
    ELSE
      -- Lefelé mozgatjuk: a köztes boardok feljebb csúsznak
      UPDATE board
         SET position = position - 1
       WHERE project_id = l_project_id
         AND position <= p_new_position
         AND position > l_old_pos;
    END IF;
  
    ------------------------------------------------------------------
    -- A kiválasztott board új pozíciója
    ------------------------------------------------------------------
    UPDATE board SET position = p_new_position WHERE id = p_board_id;
  
  EXCEPTION
    WHEN OTHERS THEN
      err_log_pkg.log_error(p_module_name    => 'BOARD',
                            p_procedure_name => 'reorder_board_prc',
                            p_error_code     => SQLCODE,
                            p_error_msg      => SQLERRM,
                            p_context        => 'board_id=' || p_board_id ||
                                                '; new_position=' ||
                                                p_new_position,
                            p_api            => NULL);
      RAISE pkg_exceptions.reorder_board_generic;
  END reorder_board_prc;

----------------------------------------------------------------------------------------------------------------------------------------

END board_mgmt_pkg;
/

CREATE OR REPLACE PACKAGE column_mgmt_pkg IS

  -- COLUMN (OSZLOP) SZINTŰ ELJÁRÁSOK
  
  -- Új oszlop létrehozása egy boardon
  PROCEDURE create_column_prc(p_board_id    IN column_def.board_id%TYPE
                             ,p_column_name IN column_def.column_name%TYPE
                             ,p_wip_limit   IN column_def.wip_limit%TYPE
                             ,p_position    IN column_def.position%TYPE
                             ,p_status_code IN task_status.code%TYPE
                             ,p_column_id   OUT column_def.id%TYPE);

  -- Oszlop nevének és WIP-limitjének módosítása
  PROCEDURE update_column_prc(p_column_id     IN column_def.id%TYPE
                             ,p_new_name      IN column_def.column_name%TYPE
                             ,p_new_wip_limit IN column_def.wip_limit%TYPE);

  -- Oszlop sorrendjének módosítása egy boardon belül
  PROCEDURE reorder_column_prc(p_column_id    IN column_def.id%TYPE
                              ,p_new_position IN column_def.position%TYPE);

END column_mgmt_pkg;
/

CREATE OR REPLACE PACKAGE BODY column_mgmt_pkg IS

  --------------------------------------------------------------------
  -- COLUMN ELJÁRÁSOK
  --------------------------------------------------------------------

  PROCEDURE create_column_prc(p_board_id    IN column_def.board_id%TYPE
                             ,p_column_name IN column_def.column_name%TYPE
                             ,p_wip_limit   IN column_def.wip_limit%TYPE
                             ,p_position    IN column_def.position%TYPE
                             ,p_status_code IN task_status.code%TYPE
                             ,p_column_id   OUT column_def.id%TYPE) IS
    l_status_id task_status.id%TYPE;
  BEGIN
    ------------------------------------------------------------------
    -- 1. Status ID kikeresése a code alapján
    ------------------------------------------------------------------
    SELECT id INTO l_status_id FROM task_status WHERE code = p_status_code;
  
    ------------------------------------------------------------------
    -- 2. Oszlop beszúrása
    ------------------------------------------------------------------
    INSERT INTO column_def
      (board_id
      ,column_name
      ,wip_limit
      ,position
      ,status_id)
    VALUES
      (p_board_id
      ,p_column_name
      ,p_wip_limit
      ,p_position
      ,l_status_id)
    RETURNING id INTO p_column_id;
  
  EXCEPTION
    WHEN no_data_found THEN
      -- Nincs ilyen task_status code
      err_log_pkg.log_error(p_module_name    => 'COLUMN',
                            p_procedure_name => 'create_column_prc',
                            p_error_code     => -20080,
                            p_error_msg      => 'Nincs ilyen task_status code: "' ||
                                                p_status_code || '".',
                            p_context        => 'board_id=' || p_board_id ||
                                                '; column_name="' ||
                                                p_column_name || '"' ||
                                                '; status_code="' ||
                                                p_status_code || '"',
                            p_api            => NULL);
      RAISE pkg_exceptions.create_column_status_not_found;
    
    WHEN dup_val_on_index THEN
      -- (board_id, column_name) vagy (board_id, position) unique constraint sérül
      err_log_pkg.log_error(p_module_name    => 'COLUMN',
                            p_procedure_name => 'create_column_prc',
                            p_error_code     => -20081,
                            p_error_msg      => 'Ütközés a column_def egyediségén (név vagy pozíció boardon belül).',
                            p_context        => 'board_id=' || p_board_id ||
                                                '; column_name="' ||
                                                p_column_name || '"' ||
                                                '; position=' || p_position,
                            p_api            => NULL);
      RAISE pkg_exceptions.create_column_dup;
    
    WHEN OTHERS THEN
      err_log_pkg.log_error(p_module_name    => 'COLUMN',
                            p_procedure_name => 'create_column_prc',
                            p_error_code     => SQLCODE,
                            p_error_msg      => SQLERRM,
                            p_context        => 'board_id=' || p_board_id ||
                                                '; column_name="' ||
                                                p_column_name || '"' ||
                                                '; position=' || p_position ||
                                                '; status_code="' ||
                                                p_status_code || '"',
                            p_api            => NULL);
      RAISE pkg_exceptions.create_column_generic;
  END create_column_prc;

  ------------------------------------------------------------------------------------------------------------------------------------

  PROCEDURE update_column_prc(p_column_id     IN column_def.id%TYPE
                             ,p_new_name      IN column_def.column_name%TYPE
                             ,p_new_wip_limit IN column_def.wip_limit%TYPE) IS
  BEGIN
    UPDATE column_def
       SET column_name = p_new_name
          ,wip_limit   = p_new_wip_limit
     WHERE id = p_column_id;
  
    IF SQL%ROWCOUNT = 0
    THEN
      -- Nincs ilyen oszlop
      err_log_pkg.log_error(p_module_name    => 'COLUMN',
                            p_procedure_name => 'update_column_prc',
                            p_error_code     => -20150,
                            p_error_msg      => 'Nem található a megadott column.',
                            p_context        => 'column_id=' || p_column_id ||
                                                '; new_name="' || p_new_name || '"' ||
                                                '; new_wip_limit=' ||
                                                p_new_wip_limit,
                            p_api            => NULL);
      RAISE pkg_exceptions.update_column_not_found;
    END IF;
  
  EXCEPTION
    WHEN dup_val_on_index THEN
      -- (board_id, column_name) vagy (board_id, position) unique megsértése
      err_log_pkg.log_error(p_module_name    => 'COLUMN',
                            p_procedure_name => 'update_column_prc',
                            p_error_code     => -20151,
                            p_error_msg      => 'Ütközés a column egyedi constraintjeivel (név vagy pozíció).',
                            p_context        => 'column_id=' || p_column_id ||
                                                '; new_name="' || p_new_name || '"' ||
                                                '; new_wip_limit=' ||
                                                p_new_wip_limit,
                            p_api            => NULL);
      RAISE pkg_exceptions.update_column_duplicate;
    
    WHEN OTHERS THEN
      err_log_pkg.log_error(p_module_name    => 'COLUMN',
                            p_procedure_name => 'update_column_prc',
                            p_error_code     => SQLCODE,
                            p_error_msg      => SQLERRM,
                            p_context        => 'column_id=' || p_column_id ||
                                                '; new_name="' || p_new_name || '"' ||
                                                '; new_wip_limit=' ||
                                                p_new_wip_limit,
                            p_api            => NULL);
      RAISE pkg_exceptions.update_column_generic;
  END update_column_prc;

  ------------------------------------------------------------------------------------------------------------------------------------
  
  --------------------------------------------------------------------
  -- OSZLOP SORRENDEZÉS BIZTONSÁGOSAN (ÚJRASZÁMOZÁS + IDEIGLENES ELTOLÁS)
  --------------------------------------------------------------------
  PROCEDURE reorder_column_prc(p_column_id    IN column_def.id%TYPE
                              ,p_new_position IN column_def.position%TYPE) IS
    TYPE t_col_id_tab IS TABLE OF column_def.id%TYPE INDEX BY PLS_INTEGER;

    l_all_ids    t_col_id_tab;  -- jelenlegi sorrend
    l_new_ids    t_col_id_tab;  -- új sorrend
    l_board_id   column_def.board_id%TYPE;
    l_old_pos    column_def.position%TYPE;
    l_cnt        PLS_INTEGER := 0;
    l_idx        PLS_INTEGER;
    l_target_pos PLS_INTEGER;
    l_placed     BOOLEAN := FALSE;
  BEGIN
    IF p_new_position < 1 THEN
      raise_application_error(-20160,
        'reorder_column_prc: a pozíció nem lehet 1-nél kisebb.');
    END IF;

    ------------------------------------------------------------------
    -- 1. A rendezendő oszlop boardja és aktuális pozíciója
    ------------------------------------------------------------------
    SELECT board_id, position
      INTO l_board_id, l_old_pos
      FROM column_def
     WHERE id = p_column_id;

    IF p_new_position = l_old_pos THEN
      RETURN;
    END IF;

    ------------------------------------------------------------------
    -- 2. Oszlopok beolvasása az adott boardról, pozíció szerint
    ------------------------------------------------------------------
    FOR r IN (SELECT id
                FROM column_def
               WHERE board_id = l_board_id
               ORDER BY position)
    LOOP
      l_cnt := l_cnt + 1;
      l_all_ids(l_cnt) := r.id;
    END LOOP;

    IF l_cnt = 0 THEN
      raise_application_error(-20162,
        'reorder_column_prc: nem találtam oszlopokat a boardon (board_id=' ||
        l_board_id || ').');
    END IF;

    ------------------------------------------------------------------
    -- 3. Cél pozíció normalizálása (ha nagyobb, mint elemszám  lista vége)
    ------------------------------------------------------------------
    l_target_pos := p_new_position;
    IF l_target_pos > l_cnt THEN
      l_target_pos := l_cnt;
    END IF;

    ------------------------------------------------------------------
    -- 4. Új sorrend felépítése memóriában
    ------------------------------------------------------------------
    l_idx := 1;

    FOR i IN 1 .. l_cnt LOOP
      -- Mozgatott oszlopot kihagyjuk az eredeti sorrendből
      IF l_all_ids(i) = p_column_id THEN
        CONTINUE;
      END IF;

      -- Ha a célpozícióhoz értünk, előbb a mozgatott oszlop megy
      IF l_idx = l_target_pos THEN
        l_new_ids(l_idx) := p_column_id;
        l_idx    := l_idx + 1;
        l_placed := TRUE;
      END IF;

      -- Majd az aktuális oszlop
      l_new_ids(l_idx) := l_all_ids(i);
      l_idx := l_idx + 1;
    END LOOP;

    -- Ha még nem lett berakva (pl. cél pozíció a legvégén volt)
    IF NOT l_placed THEN
      l_new_ids(l_idx) := p_column_id;
      l_idx := l_idx + 1;
    END IF;

    ------------------------------------------------------------------
    -- 5. IDEIGLENES ELTOLÁS: minden oszlop position +1000
    --    (így azonnal megszűnik a 1..N tartományban minden ütközés)
    ------------------------------------------------------------------
    UPDATE column_def
       SET position = position + 1000
     WHERE board_id = l_board_id;

    ------------------------------------------------------------------
    -- 6. Végleges 1..N pozíciók visszaírása – itt már nem tud ütközni
    ------------------------------------------------------------------
    FOR i IN 1 .. l_idx - 1 LOOP
      UPDATE column_def
         SET position = i
       WHERE id = l_new_ids(i);
    END LOOP;

  EXCEPTION
    WHEN NO_DATA_FOUND THEN
      raise_application_error(-20163,
        'reorder_column_prc: a megadott column_id nem található: ' ||
        p_column_id);

    WHEN OTHERS THEN
      raise_application_error(-20161,
        'reorder_column_prc hiba (column_id=' || p_column_id ||
        ', new_position=' || p_new_position || '): ' || SQLERRM);
  END reorder_column_prc;


END column_mgmt_pkg;
/

CREATE OR REPLACE PACKAGE sprint_mgmt_pkg IS

  PROCEDURE create_sprint_prc(p_project_id  IN sprint.project_id%TYPE
                             ,p_board_id    IN sprint.board_id%TYPE
                             ,p_sprint_name IN sprint.sprint_name%TYPE
                             ,p_goal        IN sprint.goal%TYPE
                             ,p_start_date  IN sprint.start_date%TYPE
                             ,p_end_date    IN sprint.end_date%TYPE
                             ,p_state       IN sprint.state%TYPE
                             ,p_sprint_id   OUT sprint.id%TYPE);

END sprint_mgmt_pkg;
/

CREATE OR REPLACE PACKAGE BODY sprint_mgmt_pkg IS

  PROCEDURE create_sprint_prc(p_project_id  IN sprint.project_id%TYPE
                             ,p_board_id    IN sprint.board_id%TYPE
                             ,p_sprint_name IN sprint.sprint_name%TYPE
                             ,p_goal        IN sprint.goal%TYPE
                             ,p_start_date  IN sprint.start_date%TYPE
                             ,p_end_date    IN sprint.end_date%TYPE
                             ,p_state       IN sprint.state%TYPE
                             ,p_sprint_id   OUT sprint.id%TYPE) IS
    l_cnt NUMBER;
  BEGIN
    IF p_end_date < p_start_date
    THEN
      err_log_pkg.log_error(p_module_name    => 'SPRINT',
                            p_procedure_name => 'create_sprint_prc',
                            p_error_code     => -20361,
                            p_error_msg      => 'Sprint end_date kisebb, mint start_date.',
                            p_context        => 'project_id=' ||
                                                p_project_id ||
                                                '; board_id=' || p_board_id ||
                                                '; start_date=' ||
                                                to_char(p_start_date,
                                                        'YYYY-MM-DD') ||
                                                '; end_date=' ||
                                                to_char(p_end_date,
                                                        'YYYY-MM-DD'),
                            p_api            => NULL);
      RAISE pkg_exceptions.sprint_date_invalid;
    END IF;
  
    SELECT COUNT(*)
      INTO l_cnt
      FROM board
     WHERE id = p_board_id
       AND project_id = p_project_id;
  
    IF l_cnt = 0
    THEN
      err_log_pkg.log_error(p_module_name    => 'SPRINT',
                            p_procedure_name => 'create_sprint_prc',
                            p_error_code     => -20360,
                            p_error_msg      => 'A megadott board nem tartozik a projekthez.',
                            p_context        => 'project_id=' ||
                                                p_project_id ||
                                                '; board_id=' || p_board_id,
                            p_api            => NULL);
      RAISE pkg_exceptions.sprint_project_mismatch;
    END IF;
  
    INSERT INTO sprint
      (project_id
      ,board_id
      ,sprint_name
      ,goal
      ,start_date
      ,end_date
      ,state)
    VALUES
      (p_project_id
      ,p_board_id
      ,p_sprint_name
      ,p_goal
      ,p_start_date
      ,p_end_date
      ,p_state)
    RETURNING id INTO p_sprint_id;
  
  EXCEPTION
    WHEN dup_val_on_index THEN
      err_log_pkg.log_error(p_module_name    => 'SPRINT',
                            p_procedure_name => 'create_sprint_prc',
                            p_error_code     => -20362,
                            p_error_msg      => 'Sprint létrehozás – egyedi constraint sérül.',
                            p_context        => 'project_id=' ||
                                                p_project_id ||
                                                '; board_id=' || p_board_id ||
                                                '; sprint_name=' ||
                                                p_sprint_name,
                            p_api            => NULL);
      RAISE pkg_exceptions.sprint_create_generic;
    
    WHEN OTHERS THEN
      err_log_pkg.log_error(p_module_name    => 'SPRINT',
                            p_procedure_name => 'create_sprint_prc',
                            p_error_code     => SQLCODE,
                            p_error_msg      => SQLERRM,
                            p_context        => 'project_id=' ||
                                                p_project_id ||
                                                '; board_id=' || p_board_id ||
                                                '; sprint_name=' ||
                                                p_sprint_name,
                            p_api            => NULL);
      RAISE pkg_exceptions.sprint_create_generic;
  END create_sprint_prc;

END sprint_mgmt_pkg;
/

CREATE OR REPLACE PACKAGE task_mgmt_pkg IS

  PROCEDURE create_task_prc(p_project_id    IN task.project_id%TYPE
                           ,p_board_id      IN task.board_id%TYPE
                           ,p_column_id     IN task.column_id%TYPE
                           ,p_sprint_id     IN task.sprint_id%TYPE
                           ,p_created_by    IN task.created_by%TYPE
                           ,p_title         IN task.title%TYPE
                           ,p_description   IN task.description%TYPE DEFAULT NULL
                           ,p_status_id     IN task.status_id%TYPE
                           ,p_priority      IN task.priority%TYPE DEFAULT NULL
                           ,p_estimated_min IN task.estimated_min%TYPE DEFAULT NULL
                           ,p_due_date      IN task.due_date%TYPE DEFAULT NULL
                           ,p_task_id       OUT task.id%TYPE);

  PROCEDURE assign_user_to_task_prc(p_task_id IN task_assignment.task_id%TYPE
                                   ,p_user_id IN task_assignment.user_id%TYPE);

  -- Task áthelyezése másik oszlopba (ugyanazon a boardon belül),
  -- p_new_position = NULL esetén az új oszlop végére kerül.
  PROCEDURE move_task_to_column_prc(p_task_id       IN task.id%TYPE
                                   ,p_new_column_id IN task.column_id%TYPE
                                   ,p_actor_id      IN task.created_by%TYPE
                                   ,p_new_position  IN task.position%TYPE DEFAULT NULL);

  -- Task sorrendjének módosítása az adott oszlopban
  PROCEDURE reorder_task_in_column_prc(p_task_id      IN task.id%TYPE
                                      ,p_new_position IN task.position%TYPE);

END task_mgmt_pkg;
/

CREATE OR REPLACE PACKAGE BODY task_mgmt_pkg IS

  --------------------------------------------------------------------
  -- TASK LÉTREHOZÁS
  --------------------------------------------------------------------
  PROCEDURE create_task_prc(p_project_id    IN task.project_id%TYPE
                           ,p_board_id      IN task.board_id%TYPE
                           ,p_column_id     IN task.column_id%TYPE
                           ,p_sprint_id     IN task.sprint_id%TYPE
                           ,p_created_by    IN task.created_by%TYPE
                           ,p_title         IN task.title%TYPE
                           ,p_description   IN task.description%TYPE
                           ,p_status_id     IN task.status_id%TYPE
                           ,p_priority      IN task.priority%TYPE
                           ,p_estimated_min IN task.estimated_min%TYPE
                           ,p_due_date      IN task.due_date%TYPE
                           ,p_task_id       OUT task.id%TYPE) IS
    l_task_key task.task_key%TYPE;
    l_position task.position%TYPE;
  BEGIN
    ------------------------------------------------------------------
    -- 1. Task key generálása projekt alapján (PMA-0001, DEVOPS-0001…)
    ------------------------------------------------------------------
    l_task_key := build_next_task_key_fnc(p_project_id);
  
    ------------------------------------------------------------------
    -- 2. POSITION meghatározása az oszlopon belül
    ------------------------------------------------------------------
    SELECT nvl(MAX(position), 0) + 1
      INTO l_position
      FROM task
     WHERE column_id = p_column_id;
  
    ------------------------------------------------------------------
    -- 3. Task beszúrása
    ------------------------------------------------------------------
    INSERT INTO task
      (project_id
      ,board_id
      ,column_id
      ,sprint_id
      ,task_key
      ,title
      ,description
      ,status_id
      ,priority
      ,estimated_min
      ,due_date
      ,created_by
      ,position)
    VALUES
      (p_project_id
      ,p_board_id
      ,p_column_id
      ,p_sprint_id
      ,l_task_key
      ,p_title
      ,p_description
      ,p_status_id
      ,p_priority
      ,p_estimated_min
      ,p_due_date
      ,p_created_by
      ,l_position)
    RETURNING id INTO p_task_id;
  
    --Activity Log
    DECLARE
      l_activity_id app_activity.id%TYPE;
    BEGIN
      activity_log_pkg.log_activity_prc(p_project_id  => p_project_id,
                                        p_actor_id    => p_created_by,
                                        p_entity_type => 'TASK',
                                        p_entity_id   => p_task_id,
                                        p_action      => 'TASK_CREATE',
                                        p_payload     => 'Task létrehozva: ' ||
                                                         p_title,
                                        p_activity_id => l_activity_id);
    END;
  
  EXCEPTION
    WHEN dup_val_on_index THEN
      -- tipikusan TASK_KEY egyedi constraint sérül
      err_log_pkg.log_error(p_module_name    => 'TASK',
                            p_procedure_name => 'create_task_prc',
                            p_error_code     => -20100,
                            p_error_msg      => 'Ütközés az egyedi constrainten (valószínűleg TASK_KEY).',
                            p_context        => 'project_id=' ||
                                                p_project_id ||
                                                '; column_id=' ||
                                                p_column_id || '; task_key=' ||
                                                l_task_key,
                            p_api            => NULL);
      RAISE pkg_exceptions.create_task_dup;
    
    WHEN OTHERS THEN
      err_log_pkg.log_error(p_module_name    => 'TASK',
                            p_procedure_name => 'create_task_prc',
                            p_error_code     => SQLCODE,
                            p_error_msg      => SQLERRM,
                            p_context        => 'project_id=' ||
                                                p_project_id ||
                                                '; board_id=' || p_board_id ||
                                                '; column_id=' ||
                                                p_column_id || '; title=' ||
                                                p_title,
                            p_api            => NULL);
      RAISE pkg_exceptions.create_task_generic;
  END create_task_prc;

  --------------------------------------------------------------------
  -- TASK–USER HOZZÁRENDELÉS
  --------------------------------------------------------------------
  PROCEDURE assign_user_to_task_prc(p_task_id IN task_assignment.task_id%TYPE
                                   ,p_user_id IN task_assignment.user_id%TYPE) IS
  BEGIN
    INSERT INTO task_assignment
      (task_id
      ,user_id
      ,assigned_at)
    VALUES
      (p_task_id
      ,p_user_id
      ,SYSDATE);
  
  EXCEPTION
    WHEN dup_val_on_index THEN
      err_log_pkg.log_error(p_module_name    => 'TASK',
                            p_procedure_name => 'assign_user_to_task_prc',
                            p_error_code     => -20110,
                            p_error_msg      => 'A user már hozzá van rendelve ehhez a taskhoz.',
                            p_context        => 'task_id=' || p_task_id ||
                                                '; user_id=' || p_user_id,
                            p_api            => NULL);
      RAISE pkg_exceptions.assign_user_already_assigned;
    
    WHEN OTHERS THEN
      err_log_pkg.log_error(p_module_name    => 'TASK',
                            p_procedure_name => 'assign_user_to_task_prc',
                            p_error_code     => SQLCODE,
                            p_error_msg      => SQLERRM,
                            p_context        => 'task_id=' || p_task_id ||
                                                '; user_id=' || p_user_id,
                            p_api            => NULL);
      RAISE pkg_exceptions.assign_user_generic;
  END assign_user_to_task_prc;

  --------------------------------------------------------------------
  -- TASK MOZGATÁS / SORRENDEZÉS
  --------------------------------------------------------------------
  PROCEDURE move_task_to_column_prc(p_task_id       IN task.id%TYPE
                                   ,p_new_column_id IN task.column_id%TYPE
                                   ,p_actor_id      IN task.created_by%TYPE
                                   ,p_new_position  IN task.position%TYPE) IS
    l_old_column_id task.column_id%TYPE;
    l_old_board_id  task.board_id%TYPE;
    l_old_position  task.position%TYPE;
  
    l_new_board_id  column_def.board_id%TYPE;
    l_new_status_id column_def.status_id%TYPE;
    l_wip_limit     column_def.wip_limit%TYPE;
  
    l_active_count   NUMBER;
    l_final_position task.position%TYPE;
  BEGIN
    ------------------------------------------------------------------
    -- 0. Pozíció alap validáció (ha meg van adva)
    ------------------------------------------------------------------
    IF p_new_position IS NOT NULL
       AND p_new_position < 1
    THEN
      err_log_pkg.log_error(p_module_name    => 'TASK',
                            p_procedure_name => 'move_task_to_column_prc',
                            p_error_code     => -20212,
                            p_error_msg      => 'Új pozíció nem lehet 1-nél kisebb.',
                            p_context        => 'task_id=' || p_task_id ||
                                                '; new_column_id=' ||
                                                p_new_column_id ||
                                                '; new_position=' ||
                                                p_new_position,
                            p_api            => NULL);
      RAISE pkg_exceptions.move_task_pos_invalid;
    END IF;
  
    ------------------------------------------------------------------
    -- 1. Task jelenlegi adatai
    ------------------------------------------------------------------
    SELECT column_id
          ,board_id
          ,position
      INTO l_old_column_id
          ,l_old_board_id
          ,l_old_position
      FROM task
     WHERE id = p_task_id;
  
    ------------------------------------------------------------------
    -- 2. Ha ugyanabba az oszlopba mozgatjuk, az csak sorrendezés
    ------------------------------------------------------------------
    IF p_new_column_id = l_old_column_id
    THEN
      IF p_new_position IS NOT NULL
         AND p_new_position <> l_old_position
      THEN
        reorder_task_in_column_prc(p_task_id      => p_task_id,
                                   p_new_position => p_new_position);
      END IF;
      RETURN;
    END IF;
  
    ------------------------------------------------------------------
    -- 3. Új oszlop adatai (board, státusz, WIP limit)
    ------------------------------------------------------------------
    SELECT board_id
          ,status_id
          ,wip_limit
      INTO l_new_board_id
          ,l_new_status_id
          ,l_wip_limit
      FROM column_def
     WHERE id = p_new_column_id;
  
    -- Nem engedjük másik boardra mozgatni a taskot
    IF l_new_board_id <> l_old_board_id
    THEN
      err_log_pkg.log_error(p_module_name    => 'TASK',
                            p_procedure_name => 'move_task_to_column_prc',
                            p_error_code     => -20210,
                            p_error_msg      => 'Task csak ugyanazon a boardon belül mozgatható.',
                            p_context        => 'task_id=' || p_task_id ||
                                                '; old_board_id=' ||
                                                l_old_board_id ||
                                                '; new_board_id=' ||
                                                l_new_board_id,
                            p_api            => NULL);
      RAISE pkg_exceptions.move_task_board_mismatch;
    END IF;
  
    ------------------------------------------------------------------
    -- 4. WIP limit ellenőrzés az új oszlopban
    ------------------------------------------------------------------
    IF l_wip_limit IS NOT NULL
       AND l_wip_limit > 0
    THEN
      SELECT COUNT(*)
        INTO l_active_count
        FROM task
       WHERE column_id = p_new_column_id
         AND closed_at IS NULL;
    
      IF l_active_count >= l_wip_limit
      THEN
        err_log_pkg.log_error(p_module_name    => 'TASK',
                              p_procedure_name => 'move_task_to_column_prc',
                              p_error_code     => -20211,
                              p_error_msg      => 'WIP limit elérve az új oszlopban.',
                              p_context        => 'task_id=' || p_task_id ||
                                                  '; new_column_id=' ||
                                                  p_new_column_id ||
                                                  '; wip_limit=' ||
                                                  l_wip_limit ||
                                                  '; active_count=' ||
                                                  l_active_count,
                              p_api            => NULL);
        RAISE pkg_exceptions.move_task_wip_exceeded;
      END IF;
    END IF;
  
    ------------------------------------------------------------------
    -- 5. Régi oszlop pozícióinak "összehúzása"
    ------------------------------------------------------------------
    UPDATE task
       SET position = position - 1
     WHERE column_id = l_old_column_id
       AND position > l_old_position;
  
    ------------------------------------------------------------------
    -- 6. Új oszlopban végső pozíció meghatározása
    ------------------------------------------------------------------
    IF p_new_position IS NULL
    THEN
      -- Ha nincs megadva új pozíció, az oszlop végére kerül
      SELECT nvl(MAX(position), 0) + 1
        INTO l_final_position
        FROM task
       WHERE column_id = p_new_column_id;
    ELSE
      -- Hely felszabadítása az új oszlopban a megadott pozícióra
      UPDATE task
         SET position = position + 1
       WHERE column_id = p_new_column_id
         AND position >= p_new_position;
    
      l_final_position := p_new_position;
    END IF;
  
    ------------------------------------------------------------------
    -- 7. Task frissítése: új oszlop, új státusz, új pozíció
    ------------------------------------------------------------------
    UPDATE task
       SET column_id     = p_new_column_id
          ,status_id     = l_new_status_id
          ,position      = l_final_position
          ,last_modified = SYSDATE
     WHERE id = p_task_id;
  
  EXCEPTION
    ----------------------------------------------------------------
    -- A már korábban *tudatosan* dobott saját exceptionjeinket
    -- NEM csomagoljuk újra, csak továbbdobjuk.
    ----------------------------------------------------------------
    WHEN pkg_exceptions.move_task_board_mismatch
         OR pkg_exceptions.move_task_wip_exceeded
         OR pkg_exceptions.move_task_pos_invalid THEN
      RAISE;
    
    ----------------------------------------------------------------
    -- Ha maga a task vagy az oszlop hiányzik
    ----------------------------------------------------------------
    WHEN no_data_found THEN
      err_log_pkg.log_error(p_module_name    => 'TASK',
                            p_procedure_name => 'move_task_to_column_prc',
                            p_error_code     => -20213,
                            p_error_msg      => 'Task vagy oszlop nem található.',
                            p_context        => 'task_id=' || p_task_id ||
                                                '; new_column_id=' ||
                                                p_new_column_id,
                            p_api            => NULL);
      RAISE pkg_exceptions.move_task_not_found;
    
    ----------------------------------------------------------------
    -- Minden más hiba: általános task-move hiba
    ----------------------------------------------------------------
    WHEN OTHERS THEN
      err_log_pkg.log_error(p_module_name    => 'TASK',
                            p_procedure_name => 'move_task_to_column_prc',
                            p_error_code     => SQLCODE,
                            p_error_msg      => SQLERRM,
                            p_context        => 'task_id=' || p_task_id ||
                                                '; new_column_id=' ||
                                                p_new_column_id,
                            p_api            => NULL);
      RAISE pkg_exceptions.move_task_generic;
  END move_task_to_column_prc;

  --------------------------------------------------------------------
  -- TASK SORRENDEZÉS OSZLOPON BELÜL
  --------------------------------------------------------------------
  --------------------------------------------------------------------
  -- TASK sorrendezés oszlopon belül, egyedi (column_id, position)
  -- constraint biztonságos kezelése mellett.
  --
  -- Lépések:
  --  1) Beolvassuk az adott oszlop összes taskját pozíció szerint.
  --  2) Memóriában felépítjük az új sorrendet, ahova a p_task_id
  --     a p_new_position helyre kerül.
  --  3) Az oszlop összes taskjának position értékét ideiglenesen
  --     +1000-rel eltoljuk (így nem sérül az egyedi index).
  --  4) Az új sorrendnek megfelelően 1..N-re újraszámozzuk a position-t.
  --------------------------------------------------------------------
  PROCEDURE reorder_task_in_column_prc(p_task_id      IN task.id%TYPE
                                      ,p_new_position IN task.position%TYPE) IS
    TYPE t_id_tab IS TABLE OF task.id%TYPE INDEX BY PLS_INTEGER;
  
    l_all_ids    t_id_tab; -- jelenlegi sorrend
    l_new_ids    t_id_tab; -- új sorrend
    l_column_id  task.column_id%TYPE;
    l_old_pos    task.position%TYPE;
    l_cnt        PLS_INTEGER := 0;
    l_idx        PLS_INTEGER;
    l_target_pos PLS_INTEGER;
    l_placed     BOOLEAN := FALSE;
  BEGIN
    IF p_new_position < 1
    THEN
      raise_application_error(-20220,
                              'reorder_task_in_column_prc: a pozíció nem lehet 1-nél kisebb.');
    END IF;
  
    ------------------------------------------------------------------
    -- 1. Task jelenlegi oszlopa és pozíciója
    ------------------------------------------------------------------
    SELECT column_id
          ,position
      INTO l_column_id
          ,l_old_pos
      FROM task
     WHERE id = p_task_id;
  
    IF p_new_position = l_old_pos
    THEN
      RETURN; -- nincs változás
    END IF;
  
    ------------------------------------------------------------------
    -- 2. Az adott oszlop taskjainak beolvasása, jelenlegi sorrend
    ------------------------------------------------------------------
    FOR r IN (SELECT id
                FROM task
               WHERE column_id = l_column_id
               ORDER BY position)
    LOOP
      l_cnt := l_cnt + 1;
      l_all_ids(l_cnt) := r.id;
    END LOOP;
  
    IF l_cnt = 0
    THEN
      raise_application_error(-20221,
                              'reorder_task_in_column_prc: üres oszlop (column_id=' ||
                              l_column_id || ').');
    END IF;
  
    ------------------------------------------------------------------
    -- 3. Célpozíció normalizálása
    ------------------------------------------------------------------
    l_target_pos := p_new_position;
    IF l_target_pos > l_cnt
    THEN
      l_target_pos := l_cnt;
    END IF;
  
    ------------------------------------------------------------------
    -- 4. Új sorrend felépítése memóriában
    ------------------------------------------------------------------
    l_idx := 1;
  
    FOR i IN 1 .. l_cnt
    LOOP
      -- A mozgatott taskot kihagyjuk az eredeti sorrendből
      IF l_all_ids(i) = p_task_id
      THEN
        CONTINUE;
      END IF;
    
      -- Ha elértük a célpozíciót, előbb a mozgatott task kerül be
      IF l_idx = l_target_pos
      THEN
        l_new_ids(l_idx) := p_task_id;
        l_idx := l_idx + 1;
        l_placed := TRUE;
      END IF;
    
      -- Majd az aktuális task
      l_new_ids(l_idx) := l_all_ids(i);
      l_idx := l_idx + 1;
    END LOOP;
  
    -- Ha még nem lett berakva (pl. célpozíció a legvégén volt)
    IF NOT l_placed
    THEN
      l_new_ids(l_idx) := p_task_id;
      l_idx := l_idx + 1;
    END IF;
  
    ------------------------------------------------------------------
    -- 5. Ideiglenes eltolás: minden task position +1000
    ------------------------------------------------------------------
    UPDATE task
       SET position = position + 1000
     WHERE column_id = l_column_id;
  
    ------------------------------------------------------------------
    -- 6. Végleges 1..N pozíciók visszaírása az új sorrend alapján
    ------------------------------------------------------------------
    FOR i IN 1 .. l_idx - 1
    LOOP
      UPDATE task
         SET position      = i
            ,last_modified = SYSDATE -- itt használjuk a LAST_MODIFIED-et
       WHERE id = l_new_ids(i);
    END LOOP;
  
  EXCEPTION
    WHEN no_data_found THEN
      raise_application_error(-20221,
                              'reorder_task_in_column_prc: a megadott task nem található.');
    WHEN OTHERS THEN
      raise_application_error(-20222,
                              'reorder_task_in_column_prc hiba (task_id=' ||
                              p_task_id || ', new_position=' ||
                              p_new_position || '): ' || SQLERRM);
  END reorder_task_in_column_prc;

END task_mgmt_pkg;
/

CREATE OR REPLACE PROCEDURE create_task_status_prc(p_code        IN task_status.code%TYPE
                                                  ,p_name        IN task_status.name%TYPE
                                                  ,p_description IN task_status.description%TYPE DEFAULT NULL
                                                  ,p_is_final    IN task_status.is_final%TYPE
                                                  ,p_position    IN task_status.position%TYPE
                                                  ,p_status_id   OUT task_status.id%TYPE) IS
BEGIN
  INSERT INTO task_status
    (code
    ,NAME
    ,description
    ,is_final
    ,position)
  VALUES
    (p_code
    ,p_name
    ,p_description
    ,p_is_final
    ,p_position)
  RETURNING id INTO p_status_id;

EXCEPTION
  WHEN dup_val_on_index THEN
    raise_application_error(-20060,
                            'create_task_status_prc: status code "' ||
                            p_code || '" már létezik.');
  WHEN OTHERS THEN
    raise_application_error(-20061,
                            'create_task_status_prc hiba code = "' ||
                            p_code || '": ' || SQLERRM);
END;
/


CREATE OR REPLACE PACKAGE label_mgmt_pkg IS

  PROCEDURE create_label_prc(p_project_id IN labels.project_id%TYPE
                            ,p_label_name IN labels.label_name%TYPE
                            ,p_color      IN labels.color%TYPE
                            ,p_label_id   OUT labels.id%TYPE);

  PROCEDURE assign_label_to_task_prc(p_task_id  IN label_task.task_id%TYPE
                                    ,p_label_id IN label_task.label_id%TYPE);

END label_mgmt_pkg;
/

CREATE OR REPLACE PACKAGE BODY label_mgmt_pkg IS

  PROCEDURE create_label_prc(p_project_id IN labels.project_id%TYPE
                            ,p_label_name IN labels.label_name%TYPE
                            ,p_color      IN labels.color%TYPE
                            ,p_label_id   OUT labels.id%TYPE) IS
    l_cnt NUMBER;
  BEGIN
    SELECT COUNT(*) INTO l_cnt FROM app_project WHERE id = p_project_id;
  
    IF l_cnt = 0
    THEN
      err_log_pkg.log_error(p_module_name    => 'LABEL',
                            p_procedure_name => 'create_label_prc',
                            p_error_code     => -20371,
                            p_error_msg      => 'Projekt nem található a label létrehozásához.',
                            p_context        => 'project_id=' ||
                                                p_project_id ||
                                                '; label_name=' ||
                                                p_label_name,
                            p_api            => NULL);
      RAISE pkg_exceptions.label_project_not_found;
    END IF;
  
    INSERT INTO labels
      (project_id
      ,label_name
      ,color)
    VALUES
      (p_project_id
      ,p_label_name
      ,p_color)
    RETURNING id INTO p_label_id;
  
  EXCEPTION
    WHEN dup_val_on_index THEN
      err_log_pkg.log_error(p_module_name    => 'LABEL',
                            p_procedure_name => 'create_label_prc',
                            p_error_code     => -20370,
                            p_error_msg      => 'Label név ütközik projekten belül.',
                            p_context        => 'project_id=' ||
                                                p_project_id ||
                                                '; label_name=' ||
                                                p_label_name,
                            p_api            => NULL);
      RAISE pkg_exceptions.label_name_duplicate;
    
    WHEN OTHERS THEN
      err_log_pkg.log_error(p_module_name    => 'LABEL',
                            p_procedure_name => 'create_label_prc',
                            p_error_code     => SQLCODE,
                            p_error_msg      => SQLERRM,
                            p_context        => 'project_id=' ||
                                                p_project_id ||
                                                '; label_name=' ||
                                                p_label_name,
                            p_api            => NULL);
      RAISE pkg_exceptions.label_generic_error;
  END create_label_prc;

  PROCEDURE assign_label_to_task_prc(p_task_id  IN label_task.task_id%TYPE
                                    ,p_label_id IN label_task.label_id%TYPE) IS
  BEGIN
    INSERT INTO label_task
      (task_id
      ,label_id)
    VALUES
      (p_task_id
      ,p_label_id);
  
  EXCEPTION
    WHEN dup_val_on_index THEN
      err_log_pkg.log_error(p_module_name    => 'LABEL',
                            p_procedure_name => 'assign_label_to_task_prc',
                            p_error_code     => -20373,
                            p_error_msg      => 'Label már hozzá van rendelve ehhez a taskhoz.',
                            p_context        => 'task_id=' || p_task_id ||
                                                '; label_id=' || p_label_id,
                            p_api            => NULL);
      RAISE pkg_exceptions.label_task_duplicate;
    
    WHEN OTHERS THEN
      err_log_pkg.log_error(p_module_name    => 'LABEL',
                            p_procedure_name => 'assign_label_to_task_prc',
                            p_error_code     => SQLCODE,
                            p_error_msg      => SQLERRM,
                            p_context        => 'task_id=' || p_task_id ||
                                                '; label_id=' || p_label_id,
                            p_api            => NULL);
      RAISE pkg_exceptions.label_task_generic;
  END assign_label_to_task_prc;

END label_mgmt_pkg;
/

CREATE OR REPLACE PACKAGE comment_mgmt_pkg IS

  PROCEDURE create_comment_prc(p_task_id      IN app_comment.task_id%TYPE
                              ,p_user_id      IN app_comment.user_id%TYPE
                              ,p_comment_body IN app_comment.comment_body%TYPE
                              ,p_comment_id   OUT app_comment.id%TYPE);

END comment_mgmt_pkg;
/

CREATE OR REPLACE PACKAGE BODY comment_mgmt_pkg IS

  PROCEDURE create_comment_prc(p_task_id      IN app_comment.task_id%TYPE
                              ,p_user_id      IN app_comment.user_id%TYPE
                              ,p_comment_body IN app_comment.comment_body%TYPE
                              ,p_comment_id   OUT app_comment.id%TYPE) IS
    l_task_cnt NUMBER;
    l_user_cnt NUMBER;
  BEGIN
    SELECT COUNT(*) INTO l_task_cnt FROM task WHERE id = p_task_id;
  
    IF l_task_cnt = 0
    THEN
      err_log_pkg.log_error(p_module_name    => 'COMMENT',
                            p_procedure_name => 'create_comment_prc',
                            p_error_code     => -20380,
                            p_error_msg      => 'A megadott task nem létezik kommenthez.',
                            p_context        => 'task_id=' || p_task_id ||
                                                '; user_id=' || p_user_id,
                            p_api            => NULL);
      RAISE pkg_exceptions.comment_task_not_found;
    END IF;
  
    SELECT COUNT(*) INTO l_user_cnt FROM app_user WHERE id = p_user_id;
  
    IF l_user_cnt = 0
    THEN
      err_log_pkg.log_error(p_module_name    => 'COMMENT',
                            p_procedure_name => 'create_comment_prc',
                            p_error_code     => -20381,
                            p_error_msg      => 'A megadott user nem létezik kommenthez.',
                            p_context        => 'task_id=' || p_task_id ||
                                                '; user_id=' || p_user_id,
                            p_api            => NULL);
      RAISE pkg_exceptions.comment_user_not_found;
    END IF;
  
    INSERT INTO app_comment
      (task_id
      ,user_id
      ,comment_body)
    VALUES
      (p_task_id
      ,p_user_id
      ,p_comment_body)
    RETURNING id INTO p_comment_id;
    
    -- Activity log
    DECLARE
      l_activity_id app_activity.id%TYPE;
      l_project_id  task.project_id%TYPE;
    BEGIN
      SELECT project_id INTO l_project_id FROM task WHERE id = p_task_id;
    
      activity_log_pkg.log_activity_prc(p_project_id  => l_project_id,
                                        p_actor_id    => p_user_id,
                                        p_entity_type => 'COMMENT',
                                        p_entity_id   => p_comment_id,
                                        p_action      => 'COMMENT_CREATE',
                                        p_payload     => substr(p_comment_body,
                                                                1,
                                                                200),
                                        p_activity_id => l_activity_id);
    END;
  
  EXCEPTION
    WHEN OTHERS THEN
      err_log_pkg.log_error(p_module_name    => 'COMMENT',
                            p_procedure_name => 'create_comment_prc',
                            p_error_code     => SQLCODE,
                            p_error_msg      => SQLERRM,
                            p_context        => 'task_id=' || p_task_id ||
                                                '; user_id=' || p_user_id,
                            p_api            => NULL);
      RAISE pkg_exceptions.comment_create_generic;
  END create_comment_prc;

END comment_mgmt_pkg;
/

CREATE OR REPLACE PACKAGE attachment_mgmt_pkg IS

  PROCEDURE create_attachment_prc(p_task_id         IN attachment.task_id%TYPE
                                 ,p_uploaded_by     IN attachment.uploaded_by%TYPE
                                 ,p_file_name       IN attachment.file_name%TYPE
                                 ,p_content_type    IN attachment.content_type%TYPE
                                 ,p_size_bytes      IN attachment.size_bytes%TYPE
                                 ,p_storage_path    IN attachment.storage_path%TYPE
                                 ,p_attachment_type IN attachment.attachment_type%TYPE
                                 ,p_attachment_id   OUT attachment.id%TYPE);

END attachment_mgmt_pkg;
/

CREATE OR REPLACE PACKAGE BODY attachment_mgmt_pkg IS

  PROCEDURE create_attachment_prc(p_task_id         IN attachment.task_id%TYPE
                                 ,p_uploaded_by     IN attachment.uploaded_by%TYPE
                                 ,p_file_name       IN attachment.file_name%TYPE
                                 ,p_content_type    IN attachment.content_type%TYPE
                                 ,p_size_bytes      IN attachment.size_bytes%TYPE
                                 ,p_storage_path    IN attachment.storage_path%TYPE
                                 ,p_attachment_type IN attachment.attachment_type%TYPE
                                 ,p_attachment_id   OUT attachment.id%TYPE) IS
    l_task_cnt   NUMBER;
    l_user_cnt   NUMBER;
    l_project_id task.project_id%TYPE;
  BEGIN

    -- Task létezésének ellenőrzése
    SELECT COUNT(*) INTO l_task_cnt FROM task WHERE id = p_task_id;
  
    IF l_task_cnt = 0
    THEN
      err_log_pkg.log_error(p_module_name    => 'ATTACHMENT',
                            p_procedure_name => 'create_attachment_prc',
                            p_error_code     => -20390,
                            p_error_msg      => 'A megadott task nem létezik attachmenthez.',
                            p_context        => 'task_id=' || p_task_id ||
                                                '; uploaded_by=' ||
                                                p_uploaded_by ||
                                                '; file_name=' ||
                                                p_file_name,
                            p_api            => NULL);
      RAISE pkg_exceptions.attachment_task_not_found;
    END IF;
  

    -- User létezésének ellenőrzése
    SELECT COUNT(*) INTO l_user_cnt FROM app_user WHERE id = p_uploaded_by;
  
    IF l_user_cnt = 0
    THEN
      err_log_pkg.log_error(p_module_name    => 'ATTACHMENT',
                            p_procedure_name => 'create_attachment_prc',
                            p_error_code     => -20391,
                            p_error_msg      => 'A megadott user nem létezik attachmenthez.',
                            p_context        => 'task_id=' || p_task_id ||
                                                '; uploaded_by=' ||
                                                p_uploaded_by ||
                                                '; file_name=' ||
                                                p_file_name,
                            p_api            => NULL);
      RAISE pkg_exceptions.attachment_user_not_found;
    END IF;
  
    -- Attachment beszúrása
    INSERT INTO attachment
      (task_id
      ,uploaded_by
      ,file_name
      ,content_type
      ,size_bytes
      ,storage_path
      ,attachment_type
       )
    VALUES
      (p_task_id
      ,p_uploaded_by
      ,p_file_name
      ,p_content_type
      ,p_size_bytes
      ,p_storage_path
      ,p_attachment_type)
    RETURNING id INTO p_attachment_id;
  
    -- Activity Log
    DECLARE
      l_activity_id app_activity.id%TYPE;
    BEGIN
      SELECT project_id INTO l_project_id FROM task WHERE id = p_task_id;
    
      activity_log_pkg.log_activity_prc(p_project_id  => l_project_id,
                                        p_actor_id    => p_uploaded_by,
                                        p_entity_type => 'ATTACHMENT',
                                        p_entity_id   => p_attachment_id,
                                        p_action      => 'ATTACHMENT_ADD',
                                        p_payload     => 'Attachment: ' ||
                                                         p_file_name || ' (' ||
                                                         p_content_type || ', ' ||
                                                         p_size_bytes ||
                                                         ' byte)',
                                        p_activity_id => l_activity_id);
    END;
  
  EXCEPTION
    WHEN pkg_exceptions.attachment_task_not_found
         OR pkg_exceptions.attachment_user_not_found THEN
      RAISE;
    
    WHEN OTHERS THEN
      err_log_pkg.log_error(p_module_name    => 'ATTACHMENT',
                            p_procedure_name => 'create_attachment_prc',
                            p_error_code     => SQLCODE,
                            p_error_msg      => SQLERRM,
                            p_context        => 'task_id=' || p_task_id ||
                                                '; uploaded_by=' ||
                                                p_uploaded_by ||
                                                '; file_name=' ||
                                                p_file_name,
                            p_api            => NULL);
      RAISE pkg_exceptions.attachment_generic_error;
  END create_attachment_prc;

END attachment_mgmt_pkg;
/

CREATE OR REPLACE PACKAGE git_integration_pkg IS

  PROCEDURE create_integration_prc(p_project_id     IN integration.project_id%TYPE
                                  ,p_provider       IN integration.provider%TYPE
                                  ,p_repo_full_name IN integration.repo_full_name%TYPE
                                  ,p_access_token   IN integration.access_token%TYPE
                                  ,p_webhook_secret IN integration.webhook_secret%TYPE
                                  ,p_is_enabled     IN integration.is_enabled%TYPE DEFAULT 1
                                  ,p_integration_id OUT integration.id%TYPE);

  PROCEDURE add_commit_link_prc(p_task_id        IN commit_link.task_id%TYPE
                               ,p_provider       IN commit_link.provider%TYPE
                               ,p_repo_full_name IN commit_link.repo_full_name%TYPE
                               ,p_commit_sha     IN commit_link.commit_sha%TYPE
                               ,p_message        IN commit_link.message%TYPE
                               ,p_author_email   IN commit_link.author_email%TYPE
                               ,p_committed_at   IN commit_link.committed_at%TYPE);

  PROCEDURE add_pr_link_prc(p_task_id        IN pr_link.task_id%TYPE
                           ,p_provider       IN pr_link.provider%TYPE
                           ,p_repo_full_name IN pr_link.repo_full_name%TYPE
                           ,p_pr_number      IN pr_link.pr_number%TYPE
                           ,p_title          IN pr_link.title%TYPE
                           ,p_state          IN pr_link.state%TYPE
                           ,p_created_at     IN pr_link.created_at%TYPE
                           ,p_merged_at      IN pr_link.merged_at%TYPE);

  ------------------------------------------------------------------
  --    Általános függvény commit/PR webhook esemény feldolgozására
  --    (ezt hívná a backend webhook handler)
  --
  --  - p_proj_key:  pl. 'PMA'
  --  - p_event_type: 'COMMIT' vagy 'PR'
  --  - p_message:   commit üzenet / PR title+body összevonva
  --  - commit esetén: p_commit_sha, p_author_email, p_committed_at
  --  - PR esetén:     p_pr_number, p_state, p_created_at, p_merged_at
  --
  --  Visszatérés: sikeresen taskhoz kötött linkek száma.
  ------------------------------------------------------------------
  FUNCTION process_git_message_fnc(p_proj_key       IN app_project.proj_key%TYPE
                                  ,p_event_type     IN VARCHAR2
                                  , -- 'COMMIT' / 'PR'
                                   p_message        IN VARCHAR2
                                  ,p_provider       IN VARCHAR2
                                  ,p_repo_full_name IN VARCHAR2
                                  ,p_commit_sha     IN VARCHAR2 DEFAULT NULL
                                  ,p_author_email   IN VARCHAR2 DEFAULT NULL
                                  ,p_committed_at   IN DATE DEFAULT NULL
                                  ,p_pr_number      IN NUMBER DEFAULT NULL
                                  ,p_state          IN VARCHAR2 DEFAULT NULL
                                  ,p_created_at     IN DATE DEFAULT NULL
                                  ,p_merged_at      IN DATE DEFAULT NULL)
    RETURN PLS_INTEGER;

END git_integration_pkg;
/

CREATE OR REPLACE PACKAGE BODY git_integration_pkg IS

  PROCEDURE create_integration_prc(p_project_id     IN integration.project_id%TYPE
                                  ,p_provider       IN integration.provider%TYPE
                                  ,p_repo_full_name IN integration.repo_full_name%TYPE
                                  ,p_access_token   IN integration.access_token%TYPE
                                  ,p_webhook_secret IN integration.webhook_secret%TYPE
                                  ,p_is_enabled     IN integration.is_enabled%TYPE
                                  ,p_integration_id OUT integration.id%TYPE) IS
  BEGIN
    INSERT INTO integration
      (project_id
      ,provider
      ,repo_full_name
      ,access_token
      ,webhook_secret
      ,is_enabled)
    VALUES
      (p_project_id
      ,p_provider
      ,p_repo_full_name
      ,p_access_token
      ,p_webhook_secret
      ,p_is_enabled)
    RETURNING id INTO p_integration_id;
  
  EXCEPTION
    WHEN dup_val_on_index THEN
      err_log_pkg.log_error(p_module_name    => 'GIT_INTEGRATION',
                            p_procedure_name => 'create_integration_prc',
                            p_error_code     => SQLCODE,
                            p_error_msg      => 'Duplicate integration for same project/provider/repo.',
                            p_context        => 'project_id=' ||
                                                p_project_id ||
                                                '; provider=' || p_provider ||
                                                '; repo=' ||
                                                p_repo_full_name,
                            p_api            => NULL);
      RAISE pkg_exceptions.git_integration_generic;
    
    WHEN OTHERS THEN
      err_log_pkg.log_error(p_module_name    => 'GIT_INTEGRATION',
                            p_procedure_name => 'create_integration_prc',
                            p_error_code     => SQLCODE,
                            p_error_msg      => SQLERRM,
                            p_context        => 'project_id=' ||
                                                p_project_id ||
                                                '; provider=' || p_provider ||
                                                '; repo=' ||
                                                p_repo_full_name,
                            p_api            => NULL);
      RAISE pkg_exceptions.git_integration_generic;
  END create_integration_prc;

  PROCEDURE add_commit_link_prc(p_task_id        IN commit_link.task_id%TYPE
                               ,p_provider       IN commit_link.provider%TYPE
                               ,p_repo_full_name IN commit_link.repo_full_name%TYPE
                               ,p_commit_sha     IN commit_link.commit_sha%TYPE
                               ,p_message        IN commit_link.message%TYPE
                               ,p_author_email   IN commit_link.author_email%TYPE
                               ,p_committed_at   IN commit_link.committed_at%TYPE) IS
  BEGIN
    INSERT INTO commit_link
      (task_id
      ,provider
      ,repo_full_name
      ,commit_sha
      ,message
      ,author_email
      ,committed_at)
    VALUES
      (p_task_id
      ,p_provider
      ,p_repo_full_name
      ,p_commit_sha
      ,p_message
      ,p_author_email
      ,p_committed_at);
  
  EXCEPTION
    WHEN dup_val_on_index THEN
      err_log_pkg.log_error(p_module_name    => 'GIT_INTEGRATION',
                            p_procedure_name => 'add_commit_link_prc',
                            p_error_code     => SQLCODE,
                            p_error_msg      => 'Duplicate commit_link for same task/sha.',
                            p_context        => 'task_id=' || p_task_id ||
                                                '; sha=' || p_commit_sha,
                            p_api            => NULL);
      RAISE pkg_exceptions.git_integration_generic;
    
    WHEN OTHERS THEN
      err_log_pkg.log_error(p_module_name    => 'GIT_INTEGRATION',
                            p_procedure_name => 'add_commit_link_prc',
                            p_error_code     => SQLCODE,
                            p_error_msg      => SQLERRM,
                            p_context        => 'task_id=' || p_task_id ||
                                                '; sha=' || p_commit_sha,
                            p_api            => NULL);
      RAISE pkg_exceptions.git_integration_generic;
  END add_commit_link_prc;

  PROCEDURE add_pr_link_prc(p_task_id        IN pr_link.task_id%TYPE
                           ,p_provider       IN pr_link.provider%TYPE
                           ,p_repo_full_name IN pr_link.repo_full_name%TYPE
                           ,p_pr_number      IN pr_link.pr_number%TYPE
                           ,p_title          IN pr_link.title%TYPE
                           ,p_state          IN pr_link.state%TYPE
                           ,p_created_at     IN pr_link.created_at%TYPE
                           ,p_merged_at      IN pr_link.merged_at%TYPE) IS
  BEGIN
    INSERT INTO pr_link
      (task_id
      ,provider
      ,repo_full_name
      ,pr_number
      ,title
      ,state
      ,created_at
      ,merged_at)
    VALUES
      (p_task_id
      ,p_provider
      ,p_repo_full_name
      ,p_pr_number
      ,p_title
      ,p_state
      ,p_created_at
      ,p_merged_at);
  
  EXCEPTION
    WHEN dup_val_on_index THEN
      err_log_pkg.log_error(p_module_name    => 'GIT_INTEGRATION',
                            p_procedure_name => 'add_pr_link_prc',
                            p_error_code     => SQLCODE,
                            p_error_msg      => 'Duplicate pr_link for same task/pr_number.',
                            p_context        => 'task_id=' || p_task_id ||
                                                '; pr_number=' ||
                                                p_pr_number,
                            p_api            => NULL);
      RAISE pkg_exceptions.git_integration_generic;
    
    WHEN OTHERS THEN
      err_log_pkg.log_error(p_module_name    => 'GIT_INTEGRATION',
                            p_procedure_name => 'add_pr_link_prc',
                            p_error_code     => SQLCODE,
                            p_error_msg      => SQLERRM,
                            p_context        => 'task_id=' || p_task_id ||
                                                '; pr_number=' ||
                                                p_pr_number,
                            p_api            => NULL);
      RAISE pkg_exceptions.git_integration_generic;
  END add_pr_link_prc;

  ------------------------------------------------------------------
  -- Általános függvény commit/PR webhook eseményre
  ------------------------------------------------------------------

  FUNCTION process_git_message_fnc(p_proj_key       IN app_project.proj_key%TYPE
                                  ,p_event_type     IN VARCHAR2
                                  ,p_message        IN VARCHAR2
                                  ,p_provider       IN VARCHAR2
                                  ,p_repo_full_name IN VARCHAR2
                                  ,p_commit_sha     IN VARCHAR2
                                  ,p_author_email   IN VARCHAR2
                                  ,p_committed_at   IN DATE
                                  ,p_pr_number      IN NUMBER
                                  ,p_state          IN VARCHAR2
                                  ,p_created_at     IN DATE
                                  ,p_merged_at      IN DATE)
    RETURN PLS_INTEGER IS
  
    l_event_type VARCHAR2(10) := upper(TRIM(p_event_type));
    l_project_id app_project.id%TYPE;
    l_task_key   VARCHAR2(64);
    l_task_id    task.id%TYPE;
    l_occurrence PLS_INTEGER := 1;
    l_link_count PLS_INTEGER := 0;
  
  BEGIN
    -- Event típus validálás
    IF l_event_type NOT IN ('COMMIT', 'PR')
    THEN
      err_log_pkg.log_error(p_module_name    => 'GIT_INTEGRATION',
                            p_procedure_name => 'process_git_message_fnc',
                            p_error_code     => -20322,
                            p_error_msg      => 'Invalid event type (expected COMMIT or PR).',
                            p_context        => 'event_type=' ||
                                                p_event_type,
                            p_api            => NULL);
      RAISE pkg_exceptions.git_invalid_event_type;
    END IF;
  
    -- Projekt ID kikeresése proj_key alapján
    BEGIN
      SELECT id
        INTO l_project_id
        FROM app_project
       WHERE proj_key = p_proj_key;
    EXCEPTION
      WHEN no_data_found THEN
        err_log_pkg.log_error(p_module_name    => 'GIT_INTEGRATION',
                              p_procedure_name => 'process_git_message_fnc',
                              p_error_code     => -20320,
                              p_error_msg      => 'Project not found for proj_key',
                              p_context        => 'proj_key=' || p_proj_key,
                              p_api            => NULL);
        RAISE pkg_exceptions.git_integration_not_found;
    END;
  
    -- Task kulcsok kikeresése az üzenetből: pl. "PMA-123"
    LOOP
      l_task_key := regexp_substr(p_message,
                                  p_proj_key || '-[0-9]+',
                                  1,
                                  l_occurrence);
    
      EXIT WHEN l_task_key IS NULL;
      l_occurrence := l_occurrence + 1;
    
      -- Task ID kikeresése a kulcs alapján
      BEGIN
        SELECT id
          INTO l_task_id
          FROM task
         WHERE project_id = l_project_id
           AND task_key = l_task_key;
      
      EXCEPTION
        WHEN no_data_found THEN
          -- Nem állunk le, csak logoljuk, hogy ismeretlen task key
          err_log_pkg.log_error(p_module_name    => 'GIT_INTEGRATION',
                                p_procedure_name => 'process_git_message_fnc',
                                p_error_code     => -20321,
                                p_error_msg      => 'Task not found for key in git message.',
                                p_context        => 'proj_key=' ||
                                                    p_proj_key ||
                                                    '; task_key=' ||
                                                    l_task_key ||
                                                    '; event_type=' ||
                                                    l_event_type,
                                p_api            => NULL);
          CONTINUE;
      END;
    
      -- Link beszúrása az esemény típusától függően
      IF l_event_type = 'COMMIT'
      THEN
        add_commit_link_prc(p_task_id        => l_task_id,
                            p_provider       => p_provider,
                            p_repo_full_name => p_repo_full_name,
                            p_commit_sha     => p_commit_sha,
                            p_message        => p_message,
                            p_author_email   => p_author_email,
                            p_committed_at   => nvl(p_committed_at, SYSDATE));
      ELSE
        add_pr_link_prc(p_task_id        => l_task_id,
                        p_provider       => p_provider,
                        p_repo_full_name => p_repo_full_name,
                        p_pr_number      => p_pr_number,
                        p_title          => p_message, -- általában title+body
                        p_state          => p_state,
                        p_created_at     => nvl(p_created_at, SYSDATE),
                        p_merged_at      => p_merged_at);
      END IF;
    
      l_link_count := l_link_count + 1;
    END LOOP;
  
    -- Ha végül egyetlen task key sem volt, dobjunk speciális hibát
    IF l_link_count = 0
    THEN
      err_log_pkg.log_error(p_module_name    => 'GIT_INTEGRATION',
                            p_procedure_name => 'process_git_message_fnc',
                            p_error_code     => -20321,
                            p_error_msg      => 'No task key found in git message.',
                            p_context        => 'proj_key=' || p_proj_key ||
                                                '; event_type=' ||
                                                l_event_type || '; message=' ||
                                                substr(p_message, 1, 2000),
                            p_api            => NULL);
      RAISE pkg_exceptions.git_message_no_task_key;
    END IF;
  
    RETURN l_link_count;
  
  EXCEPTION
    WHEN pkg_exceptions.git_invalid_event_type
         OR pkg_exceptions.git_integration_not_found
         OR pkg_exceptions.git_message_no_task_key THEN
      RAISE;
    
    WHEN OTHERS THEN
      err_log_pkg.log_error(p_module_name    => 'GIT_INTEGRATION',
                            p_procedure_name => 'process_git_message_fnc',
                            p_error_code     => SQLCODE,
                            p_error_msg      => SQLERRM,
                            p_context        => 'proj_key=' || p_proj_key ||
                                                '; event_type=' ||
                                                p_event_type,
                            p_api            => NULL);
      RAISE pkg_exceptions.git_integration_generic;
  END process_git_message_fnc;

END git_integration_pkg;
/

CREATE OR REPLACE PACKAGE task_autofill_pkg IS
  -- Egyetlen backlog task behúzása To Do-ba (ha van hely)
  PROCEDURE fill_todo_from_backlog;
END task_autofill_pkg;
/

CREATE OR REPLACE TRIGGER task_autofill_trg
  AFTER INSERT OR UPDATE OF column_id, closed_at ON task
DECLARE
BEGIN
  -- Megpróbálunk egy feladatot áthúzni Backlog - TODO
  task_autofill_pkg.fill_todo_from_backlog;

EXCEPTION
  --------------------------------------------------------------------
  -- Az ismert, domain-szintű hibákat NEM dobjuk tovább,
  -- mert az eredeti INSERT/UPDATE ettől még lehet sikeres.
  -- A részleteket már a task_autofill_pkg + err_log_pkg logolja.
  --------------------------------------------------------------------
  WHEN pkg_exceptions.move_task_board_mismatch
       OR pkg_exceptions.move_task_wip_exceeded
       OR pkg_exceptions.move_task_not_found
       OR pkg_exceptions.move_task_generic THEN
    NULL;
  WHEN OTHERS THEN
    RAISE;
END task_autofill_trg;
/

CREATE OR REPLACE PACKAGE BODY task_autofill_pkg IS

  -- reentrancia-védelem
  g_autofill_running BOOLEAN := FALSE;

  PROCEDURE fill_todo_from_backlog IS
    -- TODO / BACKLOG oszlopok
    l_todo_column_id     column_def.id%TYPE;
    l_backlog_column_id  column_def.id%TYPE;
    l_wip_limit          column_def.wip_limit%TYPE;
    l_todo_status_id     column_def.status_id%TYPE;

    l_task_to_move       task.id%TYPE;
    l_actor_id           task.created_by%TYPE;
    l_old_backlog_pos    task.position%TYPE;
    l_new_todo_pos       task.position%TYPE;
  BEGIN
    -- Ha már futunk (másik trigger hívásból), ne induljunk újra
    IF g_autofill_running THEN
      RETURN;
    END IF;

    g_autofill_running := TRUE;

    ----------------------------------------------------------------
    -- 1. Keresünk EGY olyan boardot, ahol:
    --    - van TODO oszlop wip_limit-tel,
    --    - a TODO-ban kevesebb aktív task van, mint a limit,
    --    - és van BACKLOG oszlop, amiben van aktív task.
    ----------------------------------------------------------------
    BEGIN
      SELECT c_todo.id,
             c_backlog.id,
             c_todo.wip_limit,
             c_todo.status_id          -- TODO oszlop státusza
        INTO l_todo_column_id,
             l_backlog_column_id,
             l_wip_limit,
             l_todo_status_id
        FROM column_def   c_todo
        JOIN task_status  s_todo
          ON s_todo.id = c_todo.status_id
         AND s_todo.code = 'TODO'
        JOIN column_def   c_backlog
          ON c_backlog.board_id = c_todo.board_id
        JOIN task_status  s_backlog
          ON s_backlog.id = c_backlog.status_id
         AND s_backlog.code = 'BACKLOG'
       WHERE c_todo.wip_limit IS NOT NULL
         AND c_todo.wip_limit > 0
         AND EXISTS (
               SELECT 1
                 FROM task t_b
                WHERE t_b.column_id = c_backlog.id
                  AND t_b.closed_at IS NULL
             )
         AND (
               SELECT COUNT(*)
                 FROM task t_t
                WHERE t_t.column_id = c_todo.id
                  AND t_t.closed_at IS NULL
             ) < c_todo.wip_limit
         AND ROWNUM = 1;  -- csak EGY board/oszloppár
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        -- Nincs olyan board/oszlop, amit tölteni kellene nem hiba
        g_autofill_running := FALSE;
        RETURN;
    END;

    ----------------------------------------------------------------
    -- 2. Válasszunk EGY aktív taskot a backlogból
    --    (position, majd id szerint)
    ----------------------------------------------------------------
    BEGIN
      SELECT id,
             created_by,
             position
        INTO l_task_to_move,
             l_actor_id,
             l_old_backlog_pos
        FROM (
               SELECT id, created_by, position
                 FROM task
                WHERE column_id = l_backlog_column_id
                  AND closed_at IS NULL
                ORDER BY position, id
             )
       WHERE ROWNUM = 1;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        -- Közben esetleg eltűnt a backlog task ez sem igazi hiba
        g_autofill_running := FALSE;
        RETURN;
    END;

    ----------------------------------------------------------------
    -- 3. Új pozíció meghatározása a TODO oszlop végén
    ----------------------------------------------------------------
    SELECT NVL(MAX(position), 0) + 1
      INTO l_new_todo_pos
      FROM task
     WHERE column_id = l_todo_column_id;

    ----------------------------------------------------------------
    -- 4. Backlog pozíciók "összehúzása" a régi oszlopban
    ----------------------------------------------------------------
    UPDATE task
       SET position = position - 1
     WHERE column_id = l_backlog_column_id
       AND position > l_old_backlog_pos;

    ----------------------------------------------------------------
    -- 5. A kiválasztott task átrakása BACKLOG TODO
    --    (közvetlen UPDATE, hogy ne sértsük a unique constraintet)
    ----------------------------------------------------------------
    UPDATE task
       SET column_id  = l_todo_column_id,
           status_id  = l_todo_status_id,
           position   = l_new_todo_pos,
           last_modified = SYSDATE
     WHERE id = l_task_to_move;

    -- (Ha akarsz activity logot, IDE lehetne beszúrni egy logolást
    --  activity_log_pkg.log_activity_prc... )

    g_autofill_running := FALSE;

  EXCEPTION
    WHEN OTHERS THEN
      g_autofill_running := FALSE;

      err_log_pkg.log_error(
        p_module_name    => 'TASK_AUTOFILL',
        p_procedure_name => 'fill_todo_from_backlog',
        p_error_code     => SQLCODE,
        p_error_msg      => SQLERRM,
        p_context        => 'task_id='      || NVL(TO_CHAR(l_task_to_move), 'NULL')
                         || '; todo_col='   || NVL(TO_CHAR(l_todo_column_id), 'NULL')
                         || '; backlog_col='|| NVL(TO_CHAR(l_backlog_column_id), 'NULL'),
        p_api            => NULL
      );

      -- Dobhatunk egy általános hibát, vagy akár el is nyelhetjük;
      -- most inkább jelezzük kifelé is:
      RAISE pkg_exceptions.move_task_generic;
  END fill_todo_from_backlog;

END task_autofill_pkg;
/

CREATE OR REPLACE TRIGGER task_autofill_on_change_trg
  AFTER INSERT OR UPDATE OR DELETE ON task
DECLARE
BEGIN
  task_autofill_pkg.fill_todo_from_backlog;
END;
/


CREATE OR REPLACE PACKAGE board_overview_pkg IS

  -- Egy board adott sprintbeli „hierarchikus” nézete
  --  - csak azokat a taskokat adja vissza, amelyek:
  --      * board = p_board_id
  --      * sprint_id = p_sprint_id
  --      * closed_at IS NULL
  FUNCTION get_board_overview_fnc(p_board_id  IN board.id%TYPE
                                 ,p_sprint_id IN sprint.id%TYPE)
    RETURN ty_board_overview;

END board_overview_pkg;
/

CREATE OR REPLACE PACKAGE BODY board_overview_pkg IS

  FUNCTION get_board_overview_fnc(p_board_id  IN board.id%TYPE
                                 ,p_sprint_id IN sprint.id%TYPE)
    RETURN ty_board_overview IS

    -- Board meta
    l_board_name       board.board_name%TYPE;
    l_board_project_id board.project_id%TYPE;

    -- Sprint meta
    l_sprint_name       sprint.sprint_name%TYPE;
    l_sprint_project_id sprint.project_id%TYPE;
    l_sprint_board_id   sprint.board_id%TYPE;

    -- Aggregált eredmény
    l_columns ty_column_overview_l := ty_column_overview_l();
    l_tasks   ty_task_overview_l;

  BEGIN
    ----------------------------------------------------------------
    -- Board metaadatok betöltése
    ----------------------------------------------------------------
    BEGIN
      SELECT board_name,
             project_id
        INTO l_board_name,
             l_board_project_id
        FROM board
       WHERE id = p_board_id;
    EXCEPTION
      WHEN no_data_found THEN
        err_log_pkg.log_error(
          p_module_name    => 'BOARD_OVERVIEW',
          p_procedure_name => 'get_board_overview_fnc',
          p_error_code     => -20310,
          p_error_msg      => 'Board not found',
          p_context        => 'board_id=' || p_board_id ||
                              '; sprint_id=' || p_sprint_id,
          p_api            => NULL
        );
        RAISE pkg_exceptions.board_overview_board_not_found;
    END;

    ----------------------------------------------------------------
    -- Sprint metaadatok betöltése
    ----------------------------------------------------------------
    BEGIN
      SELECT sprint_name,
             project_id,
             board_id
        INTO l_sprint_name,
             l_sprint_project_id,
             l_sprint_board_id
        FROM sprint
       WHERE id = p_sprint_id;
    EXCEPTION
      WHEN no_data_found THEN
        err_log_pkg.log_error(
          p_module_name    => 'BOARD_OVERVIEW',
          p_procedure_name => 'get_board_overview_fnc',
          p_error_code     => -20310,
          p_error_msg      => 'Sprint not found',
          p_context        => 'board_id=' || p_board_id ||
                              '; sprint_id=' || p_sprint_id,
          p_api            => NULL
        );
        RAISE pkg_exceptions.board_overview_board_not_found;
    END;

    ----------------------------------------------------------------
    -- Board–Sprint konzisztencia ellenőrzése
    ----------------------------------------------------------------
    IF l_sprint_board_id   <> p_board_id
       OR l_sprint_project_id <> l_board_project_id
    THEN
      err_log_pkg.log_error(
        p_module_name    => 'BOARD_OVERVIEW',
        p_procedure_name => 'get_board_overview_fnc',
        p_error_code     => -20311,
        p_error_msg      => 'Sprint does not belong to the given board/project',
        p_context        => 'board_id=' || p_board_id ||
                            '; board_project_id=' || l_board_project_id ||
                            '; sprint_id=' || p_sprint_id ||
                            '; sprint_board_id=' || l_sprint_board_id ||
                            '; sprint_project_id=' || l_sprint_project_id,
        p_api            => NULL
      );
      RAISE pkg_exceptions.board_overview_sprint_mismatch;
    END IF;

    ----------------------------------------------------------------
    -- Oszlopok bejárása a boardon
    ----------------------------------------------------------------
    FOR c_rec IN (
      SELECT c.id,
             c.column_name,
             c.wip_limit,
             ts.code AS status_code,
             ts.name AS status_name
        FROM column_def c
        JOIN task_status ts
          ON ts.id = c.status_id
       WHERE c.board_id = p_board_id
       ORDER BY c.position
    )
    LOOP
      l_tasks := ty_task_overview_l(); -- reset adott oszlophoz

      ----------------------------------------------------------------
      -- Taskok beolvasása az adott oszlophoz + sprinthez
      ----------------------------------------------------------------
      FOR t_rec IN (
        SELECT t.id,
               t.task_key,
               t.title,
               t.description,
               ts2.code       AS status_code,
               ts2.name       AS status_name,
               t.position     AS task_position,
               t.priority,
               t.last_modified AS last_modified,
               t.due_date,
               t.closed_at,
               u.id           AS created_by_id,
               u.display_name AS created_by_name,
               s.id           AS sprint_id,
               s.sprint_name,

               -- ASSIGNEES
               (SELECT listagg(u2.display_name, ', ')
                         WITHIN GROUP (ORDER BY u2.display_name)
                  FROM task_assignment ta
                  JOIN app_user u2
                    ON u2.id = ta.user_id
                 WHERE ta.task_id = t.id) AS assignees_text,

               -- ATTACHMENTS
               (SELECT COUNT(*)
                  FROM attachment a
                 WHERE a.task_id = t.id) AS attachment_count,

               (SELECT listagg(a.attachment_type, ', ')
                         WITHIN GROUP (ORDER BY a.attachment_type)
                  FROM attachment a
                 WHERE a.task_id = t.id) AS attachment_types,

               -- LABELS
               (SELECT listagg(l.label_name, ', ')
                         WITHIN GROUP (ORDER BY l.label_name)
                  FROM label_task lt
                  JOIN labels l
                    ON l.id = lt.label_id
                 WHERE lt.task_id = t.id) AS labels_text,

               -- GIT FLAGS
               CASE
                 WHEN EXISTS (SELECT 1
                                FROM commit_link cl
                               WHERE cl.task_id = t.id)
                 THEN 'Y'
                 ELSE 'N'
               END AS has_commit,

               CASE
                 WHEN EXISTS (SELECT 1
                                FROM pr_link pl
                               WHERE pl.task_id = t.id)
                 THEN 'Y'
                 ELSE 'N'
               END AS has_pr
          FROM task t
          JOIN task_status ts2
            ON ts2.id = t.status_id
          JOIN app_user u
            ON u.id = t.created_by
          LEFT JOIN sprint s
            ON s.id = t.sprint_id
         WHERE t.board_id  = p_board_id
           AND t.column_id = c_rec.id
           AND t.sprint_id = p_sprint_id
           AND t.closed_at IS NULL
         ORDER BY t.position
      )
      LOOP
        l_tasks.EXTEND;
        l_tasks(l_tasks.LAST) :=
          ty_task_overview(
            t_rec.id,
            t_rec.task_key,
            t_rec.title,
            t_rec.description,
            t_rec.status_code,
            t_rec.status_name,
            t_rec.task_position,
            t_rec.priority,
            t_rec.last_modified,
            t_rec.due_date,
            t_rec.closed_at,
            t_rec.created_by_id,
            t_rec.created_by_name,
            t_rec.sprint_id,
            t_rec.sprint_name,
            t_rec.assignees_text,
            t_rec.attachment_count,
            t_rec.attachment_types,
            t_rec.labels_text,
            t_rec.has_commit,
            t_rec.has_pr
          );
      END LOOP;

      ----------------------------------------------------------------
      -- Oszlop-objektum felvétele a listába
      ----------------------------------------------------------------
      l_columns.EXTEND;
      l_columns(l_columns.LAST) :=
        ty_column_overview(
          c_rec.id,
          c_rec.column_name,
          c_rec.wip_limit,
          c_rec.status_code,
          c_rec.status_name,
          l_tasks
        );
    END LOOP;

    ----------------------------------------------------------------
    -- Board_overview objektum összeállítása
    ----------------------------------------------------------------
    RETURN ty_board_overview(
      p_board_id,
      l_board_name,
      p_sprint_id,
      l_sprint_name,
      l_columns
    );

  EXCEPTION
    WHEN pkg_exceptions.board_overview_board_not_found
         OR pkg_exceptions.board_overview_sprint_mismatch
    THEN
      RAISE;

    WHEN OTHERS THEN
      err_log_pkg.log_error(
        p_module_name    => 'BOARD_OVERVIEW',
        p_procedure_name => 'get_board_overview_fnc',
        p_error_code     => SQLCODE,
        p_error_msg      => SQLERRM,
        p_context        => 'board_id=' || p_board_id ||
                            '; sprint_id=' || p_sprint_id,
        p_api            => NULL
      );
      RAISE pkg_exceptions.board_overview_generic;
  END get_board_overview_fnc;

END board_overview_pkg;
/

-- insert_data_script.sql

DECLARE
  -- szerepkör ID-k
  v_admin_role_id         app_role.id%TYPE;
  v_project_owner_role_id app_role.id%TYPE;
  v_developer_role_id     app_role.id%TYPE;

  -- user ID-k
  v_admin_user_id app_user.id%TYPE;
  v_peter_user_id app_user.id%TYPE;
  v_dev_user_id   app_user.id%TYPE;
BEGIN
  --------------------------------------------------------------------
  -- SZEREPKÖRÖK
  --------------------------------------------------------------------
  auth_mgmt_pkg.create_role_prc(p_role_name   => 'ADMIN',
                                p_description => 'Rendszeradminisztrátor',
                                p_role_id     => v_admin_role_id);

  auth_mgmt_pkg.create_role_prc(p_role_name   => 'PROJECT_OWNER',
                                p_description => 'Projekt tulajdonos / vezető',
                                p_role_id     => v_project_owner_role_id);

  auth_mgmt_pkg.create_role_prc(p_role_name   => 'DEVELOPER',
                                p_description => 'Fejlesztő csapattag',
                                p_role_id     => v_developer_role_id);

  --------------------------------------------------------------------
  -- FELHASZNÁLÓK
  --------------------------------------------------------------------
  auth_mgmt_pkg.create_user_prc(p_email         => 'admin@example.com',
                                p_display_name  => 'Admin Felhasználó',
                                p_password_hash => 'hashed_admin_pw',
                                p_is_active     => 1,
                                p_user_id       => v_admin_user_id);

  auth_mgmt_pkg.create_user_prc(p_email         => 'peter@example.com',
                                p_display_name  => 'Trunk Péter',
                                p_password_hash => 'hashed_peter_pw',
                                p_is_active     => 1,
                                p_user_id       => v_peter_user_id);

  auth_mgmt_pkg.create_user_prc(p_email         => 'dev@example.com',
                                p_display_name  => 'Fejlesztő Béla',
                                p_password_hash => 'hashed_dev_pw',
                                p_is_active     => 0,
                                p_user_id       => v_dev_user_id);

  --------------------------------------------------------------------
  -- FELHASZNÁLÓ–SZEREPKÖR hozzárendelések
  --------------------------------------------------------------------
  -- admin: ADMIN
  auth_mgmt_pkg.assign_role_to_user_prc(p_user_id => v_admin_user_id,
                                        p_role_id => v_admin_role_id);

  -- admin: PROJECT_OWNER
  auth_mgmt_pkg.assign_role_to_user_prc(p_user_id => v_admin_user_id,
                                        p_role_id => v_project_owner_role_id);

  -- Péter: PROJECT_OWNER
  auth_mgmt_pkg.assign_role_to_user_prc(p_user_id => v_peter_user_id,
                                        p_role_id => v_project_owner_role_id);

  -- Péter: DEVELOPER
  auth_mgmt_pkg.assign_role_to_user_prc(p_user_id => v_peter_user_id,
                                        p_role_id => v_developer_role_id);

  -- Dev Béla: DEVELOPER
  auth_mgmt_pkg.assign_role_to_user_prc(p_user_id => v_dev_user_id,
                                        p_role_id => v_developer_role_id);
END;
/

DECLARE
  v_pma_id    app_project.id%TYPE;
  v_devops_id app_project.id%TYPE;

  v_admin_id app_user.id%TYPE;
  v_peter_id app_user.id%TYPE;
  v_dev_id   app_user.id%TYPE;
BEGIN
  --------------------------------------------------------------------
  -- FELHASZNÁLÓ ID-K BETÖLTÉSE
  --------------------------------------------------------------------
  SELECT id
    INTO v_admin_id
    FROM app_user
   WHERE email = 'admin@example.com';
  SELECT id
    INTO v_peter_id
    FROM app_user
   WHERE email = 'peter@example.com';
  SELECT id INTO v_dev_id FROM app_user WHERE email = 'dev@example.com';

  --------------------------------------------------------------------
  -- PROJEKTEK LÉTREHOZÁSA
  --------------------------------------------------------------------
  project_mgmt_pkg.create_project_prc(p_project_name => 'PMA - Projektmenedzsment app',
                                      p_proj_key     => 'PMA',
                                      p_description  => 'Saját hosztolású projektmenedzsment alkalmazás (kanban + statisztikák + Git integráció).',
                                      p_owner_id     => v_admin_id,
                                      p_project_id   => v_pma_id);

  project_mgmt_pkg.create_project_prc(p_project_name => 'DEVOPS - Demo projekt',
                                      p_proj_key     => 'DEVOPS',
                                      p_description  => 'Demo projekt DevOps pipeline-ok és issue tracking kipróbálásához.',
                                      p_owner_id     => v_peter_id,
                                      p_project_id   => v_devops_id);

  --------------------------------------------------------------------
  -- PROJEKT TAGSÁGOK (PROJECT_MEMBER)
  --------------------------------------------------------------------
  -- PMA: admin = OWNER
  project_mgmt_pkg.assign_user_to_project_prc(p_project_id   => v_pma_id,
                                              p_user_id      => v_admin_id,
                                              p_project_role => 'OWNER');

  -- PMA: Péter = DEVELOPER
  project_mgmt_pkg.assign_user_to_project_prc(p_project_id   => v_pma_id,
                                              p_user_id      => v_peter_id,
                                              p_project_role => 'DEVELOPER');

  -- PMA: Dev Béla = DEVELOPER
  project_mgmt_pkg.assign_user_to_project_prc(p_project_id   => v_pma_id,
                                              p_user_id      => v_dev_id,
                                              p_project_role => 'DEVELOPER');

  -- DEVOPS: Péter = OWNER
  project_mgmt_pkg.assign_user_to_project_prc(p_project_id   => v_devops_id,
                                              p_user_id      => v_peter_id,
                                              p_project_role => 'OWNER');
END;
/

DECLARE
  -- projektek
  v_pma_id    app_project.id%TYPE;
  v_devops_id app_project.id%TYPE;

  -- státusz ID-k
  v_backlog_id    task_status.id%TYPE;
  v_todo_id       task_status.id%TYPE;
  v_inprogress_id task_status.id%TYPE;
  v_review_id     task_status.id%TYPE;
  v_done_id       task_status.id%TYPE;

  -- board ID-k
  v_pma_board_id    board.id%TYPE;
  v_devops_board_id board.id%TYPE;

  -- oszlop ID-k
  v_col_backlog_id column_def.id%TYPE;
  v_col_todo_id    column_def.id%TYPE;
  v_col_inprog_id  column_def.id%TYPE;
  v_col_done_id    column_def.id%TYPE;
BEGIN
  --------------------------------------------------------------------
  -- 1. TASK STATUSOK
  --------------------------------------------------------------------
  create_task_status_prc(p_code        => 'BACKLOG',
                         p_name        => 'Backlog',
                         p_description => 'Ötletek, még nem tervezett feladatok.',
                         p_is_final    => 0,
                         p_position    => 1,
                         p_status_id   => v_backlog_id);

  create_task_status_prc(p_code        => 'TODO',
                         p_name        => 'To Do',
                         p_description => 'Következő sprintben megvalósítandó feladatok.',
                         p_is_final    => 0,
                         p_position    => 2,
                         p_status_id   => v_todo_id);

  create_task_status_prc(p_code        => 'IN_PROGRESS',
                         p_name        => 'In Progress',
                         p_description => 'Folyamatban lévő munka.',
                         p_is_final    => 0,
                         p_position    => 3,
                         p_status_id   => v_inprogress_id);

  create_task_status_prc(p_code        => 'REVIEW',
                         p_name        => 'Review',
                         p_description => 'Kód review / tesztelés alatt.',
                         p_is_final    => 0,
                         p_position    => 4,
                         p_status_id   => v_review_id);

  create_task_status_prc(p_code        => 'DONE',
                         p_name        => 'Done',
                         p_description => 'Befejezett, lezárt feladatok.',
                         p_is_final    => 1,
                         p_position    => 5,
                         p_status_id   => v_done_id);

  --------------------------------------------------------------------
  -- 2. PROJEKT ID-K
  --------------------------------------------------------------------
  SELECT id INTO v_pma_id FROM app_project WHERE proj_key = 'PMA';
  SELECT id INTO v_devops_id FROM app_project WHERE proj_key = 'DEVOPS';

  --------------------------------------------------------------------
  -- 3. BOARDOK (board_mgmt_pkg)
  --------------------------------------------------------------------
  board_mgmt_pkg.create_board_prc(p_project_id => v_pma_id,
                                  p_board_name => 'PMA Main Board',
                                  p_is_default => 1,
                                  p_position   => 1,
                                  p_board_id   => v_pma_board_id);

  board_mgmt_pkg.create_board_prc(p_project_id => v_devops_id,
                                  p_board_name => 'DEVOPS Board',
                                  p_is_default => 1,
                                  p_position   => 1,
                                  p_board_id   => v_devops_board_id);

  --------------------------------------------------------------------
  -- 4. OSZLOPOK (column_mgmt_pkg) – PMA Main Board
  --------------------------------------------------------------------
  -- BACKLOG
  column_mgmt_pkg.create_column_prc(p_board_id    => v_pma_board_id,
                                    p_column_name => 'Backlog',
                                    p_wip_limit   => NULL,
                                    p_position    => 1,
                                    p_status_code => 'BACKLOG',
                                    p_column_id   => v_col_backlog_id);

  -- TODO
  column_mgmt_pkg.create_column_prc(p_board_id    => v_pma_board_id,
                                    p_column_name => 'To Do',
                                    p_wip_limit   => 5,
                                    p_position    => 2,
                                    p_status_code => 'TODO',
                                    p_column_id   => v_col_todo_id);

  -- IN PROGRESS
  column_mgmt_pkg.create_column_prc(p_board_id    => v_pma_board_id,
                                    p_column_name => 'In Progress',
                                    p_wip_limit   => 3,
                                    p_position    => 3,
                                    p_status_code => 'IN_PROGRESS',
                                    p_column_id   => v_col_inprog_id);

  -- DONE
  column_mgmt_pkg.create_column_prc(p_board_id    => v_pma_board_id,
                                    p_column_name => 'Done',
                                    p_wip_limit   => NULL,
                                    p_position    => 4,
                                    p_status_code => 'DONE',
                                    p_column_id   => v_col_done_id);
END;
/

DECLARE
  -- projektek / board / sprint
  v_pma_id       app_project.id%TYPE;
  v_pma_board_id board.id%TYPE;
  v_sprint1_id   sprint.id%TYPE;

  -- oszlopok
  v_col_todo_id   column_def.id%TYPE;
  v_col_inprog_id column_def.id%TYPE;
  v_col_done_id   column_def.id%TYPE;

  -- user ID-k
  v_peter_id app_user.id%TYPE;
  v_dev_id   app_user.id%TYPE;
  v_admin_id app_user.id%TYPE;

  -- status ID-k
  v_status_todo_id   task_status.id%TYPE;
  v_status_inprog_id task_status.id%TYPE;
  v_status_done_id   task_status.id%TYPE;

  -- task ID-k
  v_task1_id task.id%TYPE;
  v_task2_id task.id%TYPE;
  v_task3_id task.id%TYPE;
BEGIN
  --------------------------------------------------------------------
  -- 1. PMA projekt, board, oszlopok, user-ek, státuszok betöltése
  --------------------------------------------------------------------
  SELECT id INTO v_pma_id FROM app_project WHERE proj_key = 'PMA';

  SELECT b.id
    INTO v_pma_board_id
    FROM board b
   WHERE b.project_id = v_pma_id
     AND b.board_name = 'PMA Main Board';

  SELECT c.id
    INTO v_col_todo_id
    FROM column_def c
   WHERE c.board_id = v_pma_board_id
     AND c.column_name = 'To Do';

  SELECT c.id
    INTO v_col_inprog_id
    FROM column_def c
   WHERE c.board_id = v_pma_board_id
     AND c.column_name = 'In Progress';

  SELECT c.id
    INTO v_col_done_id
    FROM column_def c
   WHERE c.board_id = v_pma_board_id
     AND c.column_name = 'Done';

  SELECT id
    INTO v_peter_id
    FROM app_user
   WHERE email = 'peter@example.com';
  SELECT id INTO v_dev_id FROM app_user WHERE email = 'dev@example.com';
  SELECT id
    INTO v_admin_id
    FROM app_user
   WHERE email = 'admin@example.com';

  SELECT id INTO v_status_todo_id FROM task_status WHERE code = 'TODO';
  SELECT id
    INTO v_status_inprog_id
    FROM task_status
   WHERE code = 'IN_PROGRESS';
  SELECT id INTO v_status_done_id FROM task_status WHERE code = 'DONE';

  --------------------------------------------------------------------
  -- 2. Sprint 1 létrehozása – PMA
  --------------------------------------------------------------------
  sprint_mgmt_pkg.create_sprint_prc(p_project_id  => v_pma_id,
                                    p_board_id    => v_pma_board_id,
                                    p_sprint_name => 'Sprint 1',
                                    p_goal        => 'Alap adatbázis és backend váz kialakítása.',
                                    p_start_date  => DATE '2025-01-01',
                                    p_end_date    => DATE '2025-01-14',
                                    p_state       => 'ACTIVE',
                                    p_sprint_id   => v_sprint1_id);

  --------------------------------------------------------------------
  -- 3. TASKOK – PMA
  --------------------------------------------------------------------
  -- 1. task – TODO: "DB séma kialakítása"
  task_mgmt_pkg.create_task_prc(p_project_id    => v_pma_id,
                                p_board_id      => v_pma_board_id,
                                p_column_id     => v_col_todo_id,
                                p_sprint_id     => v_sprint1_id,
                                p_created_by    => v_peter_id,
                                p_title         => 'DB séma kialakítása',
                                p_description   => 'Az alap PMA adatbázis táblák és kapcsolatok létrehozása.',
                                p_status_id     => v_status_todo_id,
                                p_priority      => 'HIGH',
                                p_estimated_min => 240,
                                p_due_date      => DATE '2025-01-07',
                                p_task_id       => v_task1_id);

  -- 2. task – IN_PROGRESS: "Historizáció implementálása"
  task_mgmt_pkg.create_task_prc(p_project_id    => v_pma_id,
                                p_board_id      => v_pma_board_id,
                                p_column_id     => v_col_inprog_id,
                                p_sprint_id     => v_sprint1_id,
                                p_created_by    => v_dev_id,
                                p_title         => 'Historizáció implementálása',
                                p_description   => 'DML flag, version, history tábla és triggerek beépítése a kritikus táblákra.',
                                p_status_id     => v_status_inprog_id,
                                p_priority      => 'MEDIUM',
                                p_estimated_min => 180,
                                p_due_date      => DATE '2025-01-10',
                                p_task_id       => v_task2_id);

  -- 3. task – DONE: "Alap felhasználók felvétele"
  task_mgmt_pkg.create_task_prc(p_project_id    => v_pma_id,
                                p_board_id      => v_pma_board_id,
                                p_column_id     => v_col_done_id,
                                p_sprint_id     => v_sprint1_id,
                                p_created_by    => v_admin_id,
                                p_title         => 'Alap felhasználók felvétele',
                                p_description   => 'Admin és fejlesztő felhasználók létrehozása teszteléshez.',
                                p_status_id     => v_status_done_id,
                                p_priority      => 'LOW',
                                p_estimated_min => 60,
                                p_due_date      => DATE '2024-12-20',
                                p_task_id       => v_task3_id);

  -- explicit sorrend + closed_at
  UPDATE task SET position = 1 WHERE id = v_task1_id;
  UPDATE task SET position = 2 WHERE id = v_task2_id;

  UPDATE task
     SET position  = 3
        ,closed_at = DATE '2024-12-21'
   WHERE id = v_task3_id;

  --------------------------------------------------------------------
  -- 4. TASK ASSIGNMENT – hozzárendelések
  --------------------------------------------------------------------
  task_mgmt_pkg.assign_user_to_task_prc(p_task_id => v_task1_id,
                                        p_user_id => v_peter_id);

  task_mgmt_pkg.assign_user_to_task_prc(p_task_id => v_task2_id,
                                        p_user_id => v_dev_id);

  task_mgmt_pkg.assign_user_to_task_prc(p_task_id => v_task3_id,
                                        p_user_id => v_admin_id);
END;
/

DECLARE
  -- projekt
  v_pma_id app_project.id%TYPE;

  -- label ID-k
  v_label_backend_id  labels.id%TYPE;
  v_label_frontend_id labels.id%TYPE;
  v_label_bug_id      labels.id%TYPE;

  -- task ID-k
  v_task_db_schema_id task.id%TYPE;
  v_task_hist_id      task.id%TYPE;
  v_task_users_id     task.id%TYPE;

  -- user ID-k
  v_admin_id app_user.id%TYPE;
  v_peter_id app_user.id%TYPE;

  -- komment ID-k
  v_comment1_id app_comment.id%TYPE;
  v_comment2_id app_comment.id%TYPE;
BEGIN
  --------------------------------------------------------------------
  -- 1. PMA projekt, taskok és userek betöltése
  --------------------------------------------------------------------
  SELECT id INTO v_pma_id FROM app_project WHERE proj_key = 'PMA';

  SELECT id
    INTO v_task_db_schema_id
    FROM task
   WHERE title = 'DB séma kialakítása';

  SELECT id
    INTO v_task_hist_id
    FROM task
   WHERE title = 'Historizáció implementálása';

  SELECT id
    INTO v_task_users_id
    FROM task
   WHERE title = 'Alap felhasználók felvétele';

  SELECT id
    INTO v_admin_id
    FROM app_user
   WHERE email = 'admin@example.com';
  SELECT id
    INTO v_peter_id
    FROM app_user
   WHERE email = 'peter@example.com';

  --------------------------------------------------------------------
  -- 2. LABELS – PMA projekthez
  --------------------------------------------------------------------
  label_mgmt_pkg.create_label_prc(p_project_id => v_pma_id,
                                  p_label_name => 'backend',
                                  p_color      => '#1F77B4',
                                  p_label_id   => v_label_backend_id);

  label_mgmt_pkg.create_label_prc(p_project_id => v_pma_id,
                                  p_label_name => 'frontend',
                                  p_color      => '#FF7F0E',
                                  p_label_id   => v_label_frontend_id);

  label_mgmt_pkg.create_label_prc(p_project_id => v_pma_id,
                                  p_label_name => 'bug',
                                  p_color      => '#D62728',
                                  p_label_id   => v_label_bug_id);

  --------------------------------------------------------------------
  -- 3. LABEL_TASK – feladatok címkézése
  --------------------------------------------------------------------
  -- DB séma kialakítása -> backend
  label_mgmt_pkg.assign_label_to_task_prc(p_task_id  => v_task_db_schema_id,
                                          p_label_id => v_label_backend_id);

  -- Historizáció implementálása -> backend
  label_mgmt_pkg.assign_label_to_task_prc(p_task_id  => v_task_hist_id,
                                          p_label_id => v_label_backend_id);

  -- Alap felhasználók felvétele -> bug
  label_mgmt_pkg.assign_label_to_task_prc(p_task_id  => v_task_users_id,
                                          p_label_id => v_label_bug_id);

  --------------------------------------------------------------------
  -- 4. KOMMENTEK – app_comment
  --------------------------------------------------------------------
  comment_mgmt_pkg.create_comment_prc(p_task_id      => v_task_db_schema_id,
                                      p_user_id      => v_admin_id,
                                      p_comment_body => 'Kérlek nézd át a constraint-eket és a history triggert is.',
                                      p_comment_id   => v_comment1_id);

  comment_mgmt_pkg.create_comment_prc(p_task_id      => v_task_hist_id,
                                      p_user_id      => v_peter_id,
                                      p_comment_body => 'Szerintem a D jelölés DELETE-nél jól működik, nézzük meg még egyszer a logot.',
                                      p_comment_id   => v_comment2_id);
END;
/

DECLARE
  v_pma_id       app_project.id%TYPE;
  v_hist_task_id task.id%TYPE;
  v_db_task_id   task.id%TYPE;
  v_peter_id     app_user.id%TYPE;

  v_integration_id integration.id%TYPE;
  v_pr_id          pr_link.id%TYPE;
  v_attachment_id  attachment.id%TYPE;
BEGIN
  --------------------------------------------------------------------
  -- 1. PMA projekt, taskok, user betöltése
  --------------------------------------------------------------------
  SELECT id INTO v_pma_id FROM app_project WHERE proj_key = 'PMA';

  SELECT id
    INTO v_hist_task_id
    FROM task
   WHERE title = 'Historizáció implementálása';

  SELECT id
    INTO v_db_task_id
    FROM task
   WHERE title = 'DB séma kialakítása';

  SELECT id
    INTO v_peter_id
    FROM app_user
   WHERE email = 'peter@example.com';

  --------------------------------------------------------------------
  -- 2. INTEGRÁCIÓ – GITHUB
  --------------------------------------------------------------------
  git_integration_pkg.create_integration_prc(p_project_id     => v_pma_id,
                                             p_provider       => 'GITHUB',
                                             p_repo_full_name => 'trunkpeter/pma-demo',
                                             p_access_token   => 'dummy-access-token',
                                             p_webhook_secret => 'dummy-webhook-secret',
                                             p_is_enabled     => 1,
                                             p_integration_id => v_integration_id);

  --------------------------------------------------------------------
  -- 3. COMMIT LINK
  --------------------------------------------------------------------
  git_integration_pkg.add_commit_link_prc(p_task_id        => v_hist_task_id,
                                          p_provider       => 'GITHUB',
                                          p_repo_full_name => 'trunkpeter/pma-demo',
                                          p_commit_sha     => 'abcdef1234567890abcdef1234567890abcdef12',
                                          p_message        => 'Add history triggers and audit columns',
                                          p_author_email   => 'dev@example.com',
                                          p_committed_at   => DATE
                                                              '2025-01-05');

  --------------------------------------------------------------------
  -- 4. PR LINK
  --------------------------------------------------------------------
  git_integration_pkg.add_pr_link_prc(p_task_id        => v_hist_task_id,
                                      p_provider       => 'GITHUB',
                                      p_repo_full_name => 'trunkpeter/pma-demo',
                                      p_pr_number      => 42,
                                      p_title          => 'Feature: historisation for core tables',
                                      p_state          => 'MERGED',
                                      p_created_at     => DATE '2025-01-06',
                                      p_merged_at      => DATE '2025-01-07');

  --------------------------------------------------------------------
  -- 5. ATTACHMENT
  --------------------------------------------------------------------
  attachment_mgmt_pkg.create_attachment_prc(p_task_id         => v_db_task_id,
                                            p_uploaded_by     => v_peter_id,
                                            p_file_name       => 'db_schema_v1.png',
                                            p_content_type    => 'image/png',
                                            p_size_bytes      => 123456,
                                            p_storage_path    => '/attachments/db_schema_v1.png',
                                            p_attachment_type => 'DESIGN',
                                            p_attachment_id   => v_attachment_id);
END;
/

COMMIT;



