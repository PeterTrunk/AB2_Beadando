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

COMMENT ON COLUMN app_project.proj_key IS 'Projekt kulcs, pl: PMA, amelybõl a task azonosítók képzõdnek. (pl: PMA-100)';
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

COMMENT ON COLUMN project_member.project_role IS 'Felhasználó projektbeli szerepe (pl. fejlesztõ, reviewer, projekt manager, stb).';

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
COMMENT ON COLUMN app_activity.action IS 'A végrehajtott mûvelet.';

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
  'Projekt - külsõ rendszer (GitHub, GitLab) integráció beállításai.';
  
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
  'Idõszakos fejlesztési ciklus (Scrum sprint), státuszkezeléssel.';

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
COMMENT ON COLUMN task.created_by IS 'Létrehozó felhasználó azonosítója.';
COMMENT ON COLUMN task.closed_at IS 'Lezárás idõpontja, ha van.';

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
  'Feladat - felelõs hozzárendelése, semennyi vagy több assignee.';

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

-- Procedure arra hogy automatikus id és created_at adat kerüljön insertkor

CREATE OR REPLACE PROCEDURE create_auto_id_created_trg_prc(p_table_name IN VARCHAR2) IS
  v_tab         VARCHAR2(30);
  v_cnt         NUMBER;
  v_has_created NUMBER;
  v_has_joined  NUMBER;  -- JOINED_AT oszlop? (PROJECT_MEMBER-hez)
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
  create_auto_id_created_trg_prc('apP_ACTIVITY');
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
  SELECT proj_key
        ,task_seq_name
    INTO l_proj_key
        ,l_seq_name
    FROM app_project
   WHERE id = p_project_id;

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

  -- ha számmal kezdõdne, tegyünk elé 'P_'
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

CREATE OR REPLACE TRIGGER app_project_crea_task_seq_trg
  BEFORE INSERT ON app_project
  FOR EACH ROW
BEGIN
  :NEW.task_seq_name := build_task_seq_name_fnc(:NEW.proj_key);
END app_project_crea_task_seq_trg;
/

BEGIN
  -------------------------------------------------------------------------------
-- TESZT ADATOK – AUTO ID + CREATED_AT triggerekhez igazítva
-------------------------------------------------------------------------------

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
  create_role_prc(p_role_name   => 'ADMIN',
                  p_description => 'Rendszeradminisztrátor',
                  p_role_id     => v_admin_role_id);

  create_role_prc(p_role_name   => 'PROJECT_OWNER',
                  p_description => 'Projekt tulajdonos / vezetõ',
                  p_role_id     => v_project_owner_role_id);

  create_role_prc(p_role_name   => 'DEVELOPER',
                  p_description => 'Fejlesztõ csapattag',
                  p_role_id     => v_developer_role_id);

  --------------------------------------------------------------------
  -- FELHASZNÁLÓK
  --------------------------------------------------------------------
  create_user_prc(p_email         => 'admin@example.com',
                  p_display_name  => 'Admin Felhasználó',
                  p_password_hash => 'hashed_admin_pw',
                  p_is_active     => 1,
                  p_user_id       => v_admin_user_id);

  create_user_prc(p_email         => 'peter@example.com',
                  p_display_name  => 'Trunk Péter',
                  p_password_hash => 'hashed_peter_pw',
                  p_is_active     => 1,
                  p_user_id       => v_peter_user_id);

  create_user_prc(p_email         => 'dev@example.com',
                  p_display_name  => 'Fejlesztõ Béla',
                  p_password_hash => 'hashed_dev_pw',
                  p_is_active     => 0,
                  p_user_id       => v_dev_user_id);

  --------------------------------------------------------------------
  -- FELHASZNÁLÓ–SZEREPKÖR hozzárendelések
  --------------------------------------------------------------------
  -- admin: ADMIN
  assign_role_to_user_prc(p_user_id => v_admin_user_id,
                          p_role_id => v_admin_role_id);

  -- admin: PROJECT_OWNER
  assign_role_to_user_prc(p_user_id => v_admin_user_id,
                          p_role_id => v_project_owner_role_id);

  -- Péter: PROJECT_OWNER
  assign_role_to_user_prc(p_user_id => v_peter_user_id,
                          p_role_id => v_project_owner_role_id);

  -- Péter: DEVELOPER
  assign_role_to_user_prc(p_user_id => v_peter_user_id,
                          p_role_id => v_developer_role_id);

  -- Dev Béla: DEVELOPER
  assign_role_to_user_prc(p_user_id => v_dev_user_id,
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
  -- PROJEKTEK LÉTREHOZÁSA
  --------------------------------------------------------------------
  create_project_prc(p_project_name => 'PMA - Projektmenedzsment app', p_proj_key => 'PMA', p_description => 'Saját hosztolású projektmenedzsment alkalmazás (kanban + statisztikák + Git integráció).', p_owner_id => (
    SELECT id
      FROM app_user
     WHERE email = 'admin@example.com'), p_project_id => v_pma_id);

  create_project_prc(p_project_name => 'DEVOPS - Demo projekt', p_proj_key => 'DEVOPS', p_description => 'Demo projekt DevOps pipeline-ok és issue tracking kipróbálásához.', p_owner_id => (
    SELECT id
      FROM app_user
     WHERE email = 'peter@example.com'), p_project_id => v_devops_id);

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
  -- PROJEKT TAGSÁGOK (PROJECT_MEMBER)
  --------------------------------------------------------------------
  -- PMA: admin = OWNER
  assign_user_to_project_prc(p_project_id   => v_pma_id,
                             p_user_id      => v_admin_id,
                             p_project_role => 'OWNER');

  -- PMA: Péter = DEVELOPER
  assign_user_to_project_prc(p_project_id   => v_pma_id,
                             p_user_id      => v_peter_id,
                             p_project_role => 'DEVELOPER');

  -- PMA: Dev Béla = DEVELOPER
  assign_user_to_project_prc(p_project_id   => v_pma_id,
                             p_user_id      => v_dev_id,
                             p_project_role => 'DEVELOPER');

  -- DEVOPS: Péter = OWNER
  assign_user_to_project_prc(p_project_id   => v_devops_id,
                             p_user_id      => v_peter_id,
                             p_project_role => 'OWNER');
END;
/


-------------------------------------------------------------------------------
-- TASK STATUSOK
-------------------------------------------------------------------------------

INSERT INTO task_status
  (code
  ,NAME
  ,description
  ,is_final
  ,position)
VALUES
  ('BACKLOG'
  ,'Backlog'
  ,'Ötletek, még nem tervezett feladatok.'
  ,0
  ,1);

INSERT INTO task_status
  (code
  ,NAME
  ,description
  ,is_final
  ,position)
VALUES
  ('TODO'
  ,'To Do'
  ,'Következõ sprintben megvalósítandó feladatok.'
  ,0
  ,2);

INSERT INTO task_status
  (code
  ,NAME
  ,description
  ,is_final
  ,position)
VALUES
  ('IN_PROGRESS'
  ,'In Progress'
  ,'Folyamatban lévõ munka.'
  ,0
  ,3);

INSERT INTO task_status
  (code
  ,NAME
  ,description
  ,is_final
  ,position)
VALUES
  ('REVIEW'
  ,'Review'
  ,'Kód review / tesztelés alatt.'
  ,0
  ,4);

INSERT INTO task_status
  (code
  ,NAME
  ,description
  ,is_final
  ,position)
VALUES
  ('DONE'
  ,'Done'
  ,'Befejezett, lezárt feladatok.'
  ,1
  ,5);

-------------------------------------------------------------------------------
-- LABELS (címkék) – PMA projekthez
-------------------------------------------------------------------------------

INSERT INTO labels
  (project_id
  ,label_name
  ,color)
VALUES
  ((SELECT id FROM app_project WHERE proj_key = 'PMA')
  ,'backend'
  ,'#1F77B4');

INSERT INTO labels
  (project_id
  ,label_name
  ,color)
VALUES
  ((SELECT id FROM app_project WHERE proj_key = 'PMA')
  ,'frontend'
  ,'#FF7F0E');

INSERT INTO labels
  (project_id
  ,label_name
  ,color)
VALUES
  ((SELECT id FROM app_project WHERE proj_key = 'PMA')
  ,'bug'
  ,'#D62728');

-------------------------------------------------------------------------------
-- BOARDOK
-------------------------------------------------------------------------------

INSERT INTO board
  (project_id
  ,board_name
  ,is_default
  ,position)
VALUES
  ((SELECT id FROM app_project WHERE proj_key = 'PMA')
  ,'PMA Main Board'
  ,1
  ,1);

INSERT INTO board
  (project_id
  ,board_name
  ,is_default
  ,position)
VALUES
  ((SELECT id FROM app_project WHERE proj_key = 'DEVOPS')
  ,'DEVOPS Board'
  ,1
  ,1);

-------------------------------------------------------------------------------
-- OSZLOPOK (COLUMN_DEF) – PMA board
-------------------------------------------------------------------------------

-- BACKLOG
INSERT INTO column_def
  (board_id
  ,column_name
  ,wip_limit
  ,position
  ,status_id)
VALUES
  ((SELECT b.id
     FROM board b
     JOIN app_project p
       ON p.id = b.project_id
    WHERE p.proj_key = 'PMA'
      AND b.board_name = 'PMA Main Board')
  ,'Backlog'
  ,NULL
  ,1
  ,(SELECT id FROM task_status WHERE code = 'BACKLOG'));

-- TODO
INSERT INTO column_def
  (board_id
  ,column_name
  ,wip_limit
  ,position
  ,status_id)
VALUES
  ((SELECT b.id
     FROM board b
     JOIN app_project p
       ON p.id = b.project_id
    WHERE p.proj_key = 'PMA'
      AND b.board_name = 'PMA Main Board')
  ,'To Do'
  ,5
  ,2
  ,(SELECT id FROM task_status WHERE code = 'TODO'));

-- IN PROGRESS
INSERT INTO column_def
  (board_id
  ,column_name
  ,wip_limit
  ,position
  ,status_id)
VALUES
  ((SELECT b.id
     FROM board b
     JOIN app_project p
       ON p.id = b.project_id
    WHERE p.proj_key = 'PMA'
      AND b.board_name = 'PMA Main Board')
  ,'In Progress'
  ,3
  ,3
  ,(SELECT id FROM task_status WHERE code = 'IN_PROGRESS'));

-- DONE
INSERT INTO column_def
  (board_id
  ,column_name
  ,wip_limit
  ,position
  ,status_id)
VALUES
  ((SELECT b.id
     FROM board b
     JOIN app_project p
       ON p.id = b.project_id
    WHERE p.proj_key = 'PMA'
      AND b.board_name = 'PMA Main Board')
  ,'Done'
  ,NULL
  ,4
  ,(SELECT id FROM task_status WHERE code = 'DONE'));

-------------------------------------------------------------------------------
-- SPRINT – PMA
-------------------------------------------------------------------------------

INSERT INTO sprint
  (project_id
  ,board_id
  ,sprint_name
  ,goal
  ,start_date
  ,end_date
  ,state)
VALUES
  ((SELECT id FROM app_project WHERE proj_key = 'PMA')
  ,(SELECT b.id
     FROM board b
     JOIN app_project p
       ON p.id = b.project_id
    WHERE p.proj_key = 'PMA'
      AND b.board_name = 'PMA Main Board')
  ,'Sprint 1'
  ,'Alap adatbázis és backend váz kialakítása.'
  ,DATE '2025-01-01'
  ,DATE '2025-01-14'
  ,'ACTIVE');

-------------------------------------------------------------------------------
-- TASKOK – PMA (task_key-t a függvény számolja, ID-t + created_at-et triggerek)
-------------------------------------------------------------------------------

-- 1. task – TODO
INSERT INTO task
  (project_id
  ,board_id
  ,column_id
  ,sprint_id
  ,created_by
  ,task_key
  ,title
  ,description
  ,status_id
  ,priority
  ,estimated_min
  ,due_date
  ,position)
VALUES
  ((SELECT id FROM app_project WHERE proj_key = 'PMA')
  ,(SELECT b.id
     FROM board b
     JOIN app_project p
       ON p.id = b.project_id
    WHERE p.proj_key = 'PMA'
      AND b.board_name = 'PMA Main Board')
  ,(SELECT c.id
     FROM column_def c
     JOIN board b
       ON c.board_id = b.id
     JOIN app_project p
       ON p.id = b.project_id
    WHERE p.proj_key = 'PMA'
      AND b.board_name = 'PMA Main Board'
      AND c.column_name = 'To Do')
  ,(SELECT s.id
     FROM sprint s
     JOIN app_project p
       ON p.id = s.project_id
    WHERE p.proj_key = 'PMA'
      AND s.sprint_name = 'Sprint 1')
  ,(SELECT id FROM app_user WHERE email = 'peter@example.com')
  ,build_next_task_key_fnc((SELECT id
                             FROM app_project
                            WHERE proj_key = 'PMA'))
  ,'DB séma kialakítása'
  ,'Az alap PMA adatbázis táblák és kapcsolatok létrehozása.'
  ,(SELECT id FROM task_status WHERE code = 'TODO')
  ,'HIGH'
  ,240
  ,DATE '2025-01-07'
  ,1);

-- 2. task – IN_PROGRESS
INSERT INTO task
  (project_id
  ,board_id
  ,column_id
  ,sprint_id
  ,created_by
  ,task_key
  ,title
  ,description
  ,status_id
  ,priority
  ,estimated_min
  ,due_date
  ,position)
VALUES
  ((SELECT id FROM app_project WHERE proj_key = 'PMA')
  ,(SELECT b.id
     FROM board b
     JOIN app_project p
       ON p.id = b.project_id
    WHERE p.proj_key = 'PMA'
      AND b.board_name = 'PMA Main Board')
  ,(SELECT c.id
     FROM column_def c
     JOIN board b
       ON c.board_id = b.id
     JOIN app_project p
       ON p.id = b.project_id
    WHERE p.proj_key = 'PMA'
      AND b.board_name = 'PMA Main Board'
      AND c.column_name = 'In Progress')
  ,(SELECT s.id
     FROM sprint s
     JOIN app_project p
       ON p.id = s.project_id
    WHERE p.proj_key = 'PMA'
      AND s.sprint_name = 'Sprint 1')
  ,(SELECT id FROM app_user WHERE email = 'dev@example.com')
  ,build_next_task_key_fnc((SELECT id
                             FROM app_project
                            WHERE proj_key = 'PMA'))
  ,'Historizáció implementálása'
  ,'DML flag, version, history tábla és triggerek beépítése a kritikus táblákra.'
  ,(SELECT id FROM task_status WHERE code = 'IN_PROGRESS')
  ,'MEDIUM'
  ,180
  ,DATE '2025-01-10'
  ,2);

-- 3. task – DONE
INSERT INTO task
  (project_id
  ,board_id
  ,column_id
  ,sprint_id
  ,created_by
  ,task_key
  ,title
  ,description
  ,status_id
  ,priority
  ,estimated_min
  ,due_date
  ,closed_at
  ,position)
VALUES
  ((SELECT id FROM app_project WHERE proj_key = 'PMA')
  ,(SELECT b.id
     FROM board b
     JOIN app_project p
       ON p.id = b.project_id
    WHERE p.proj_key = 'PMA'
      AND b.board_name = 'PMA Main Board')
  ,(SELECT c.id
     FROM column_def c
     JOIN board b
       ON c.board_id = b.id
     JOIN app_project p
       ON p.id = b.project_id
    WHERE p.proj_key = 'PMA'
      AND b.board_name = 'PMA Main Board'
      AND c.column_name = 'Done')
  ,(SELECT s.id
     FROM sprint s
     JOIN app_project p
       ON p.id = s.project_id
    WHERE p.proj_key = 'PMA'
      AND s.sprint_name = 'Sprint 1')
  ,(SELECT id FROM app_user WHERE email = 'admin@example.com')
  ,build_next_task_key_fnc((SELECT id
                             FROM app_project
                            WHERE proj_key = 'PMA'))
  ,'Alap felhasználók felvétele'
  ,'Admin és fejlesztõ felhasználók létrehozása teszteléshez.'
  ,(SELECT id FROM task_status WHERE code = 'DONE')
  ,'LOW'
  ,60
  ,DATE '2024-12-20'
  ,DATE '2024-12-21'
  ,3);

-------------------------------------------------------------------------------
-- TASK ASSIGNMENT
-------------------------------------------------------------------------------

INSERT INTO task_assignment
  (task_id
  ,user_id)
VALUES
  ((SELECT t.id FROM task t WHERE t.title = 'DB séma kialakítása')
  ,(SELECT id FROM app_user WHERE email = 'peter@example.com'));

INSERT INTO task_assignment
  (task_id
  ,user_id)
VALUES
  ((SELECT t.id FROM task t WHERE t.title = 'Historizáció implementálása')
  ,(SELECT id FROM app_user WHERE email = 'dev@example.com'));

INSERT INTO task_assignment
  (task_id
  ,user_id)
VALUES
  ((SELECT t.id FROM task t WHERE t.title = 'Alap felhasználók felvétele')
  ,(SELECT id FROM app_user WHERE email = 'admin@example.com'));

-------------------------------------------------------------------------------
-- LABEL_TASK (feladatok címkézése)
-------------------------------------------------------------------------------

INSERT INTO label_task
  (task_id
  ,label_id)
VALUES
  ((SELECT t.id FROM task t WHERE t.title = 'DB séma kialakítása')
  ,(SELECT l.id
     FROM labels l
     JOIN app_project p
       ON p.id = l.project_id
    WHERE p.proj_key = 'PMA'
      AND l.label_name = 'backend'));

INSERT INTO label_task
  (task_id
  ,label_id)
VALUES
  ((SELECT t.id FROM task t WHERE t.title = 'Historizáció implementálása')
  ,(SELECT l.id
     FROM labels l
     JOIN app_project p
       ON p.id = l.project_id
    WHERE p.proj_key = 'PMA'
      AND l.label_name = 'backend'));

INSERT INTO label_task
  (task_id
  ,label_id)
VALUES
  ((SELECT t.id FROM task t WHERE t.title = 'Alap felhasználók felvétele')
  ,(SELECT l.id
     FROM labels l
     JOIN app_project p
       ON p.id = l.project_id
    WHERE p.proj_key = 'PMA'
      AND l.label_name = 'bug'));

-------------------------------------------------------------------------------
-- KOMMENTEK (app_comment – ID, created_at, mod_user, dml_flag, version triggerek)
-------------------------------------------------------------------------------

INSERT INTO app_comment
  (task_id
  ,user_id
  ,comment_body)
VALUES
  ((SELECT t.id FROM task t WHERE t.title = 'DB séma kialakítása')
  ,(SELECT id FROM app_user WHERE email = 'admin@example.com')
  ,'Kérlek nézd át a constraint-eket és a history triggert is.');

INSERT INTO app_comment
  (task_id
  ,user_id
  ,comment_body)
VALUES
  ((SELECT t.id FROM task t WHERE t.title = 'Historizáció implementálása')
  ,(SELECT id FROM app_user WHERE email = 'peter@example.com')
  ,'Szerintem a D jelölés DELETE-nél jól mûködik, nézzük meg még egyszer a logot.');

-------------------------------------------------------------------------------
-- INTEGRÁCIÓ – GITHUB
-------------------------------------------------------------------------------

INSERT INTO integration
  (project_id
  ,provider
  ,repo_full_name
  ,access_token
  ,webhook_secret
  ,is_enabled)
VALUES
  ((SELECT id FROM app_project WHERE proj_key = 'PMA')
  ,'GITHUB'
  ,'trunkpeter/pma-demo'
  ,'dummy-access-token'
  ,'dummy-webhook-secret'
  ,1);

-------------------------------------------------------------------------------
-- COMMIT / PR / ATTACHMENT
-------------------------------------------------------------------------------

-- Commit link
INSERT INTO commit_link
  (task_id
  ,provider
  ,repo_full_name
  ,commit_sha
  ,message
  ,author_email
  ,committed_at)
VALUES
  ((SELECT t.id FROM task t WHERE t.title = 'Historizáció implementálása')
  ,'GITHUB'
  ,'trunkpeter/pma-demo'
  ,'abcdef1234567890abcdef1234567890abcdef12'
  ,'Add history triggers and audit columns'
  ,'dev@example.com'
  ,DATE '2025-01-05');
COMMIT;
-- PR link
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
  ((SELECT t.id FROM task t WHERE t.title = 'Historizáció implementálása')
  ,'GITHUB'
  ,'trunkpeter/pma-demo'
  ,42
  ,'Feature: historisation for core tables'
  ,'MERGED'
  ,DATE '2025-01-06'
  ,DATE '2025-01-07');

-- Attachment
INSERT INTO attachment
  (task_id
  ,uploaded_by
  ,file_name
  ,content_type
  ,size_bytes
  ,storage_path
  ,attachment_type)
VALUES
  ((SELECT t.id FROM task t WHERE t.title = 'DB séma kialakítása')
  ,(SELECT id FROM app_user WHERE email = 'peter@example.com')
  ,'db_schema_v1.png'
  ,'image/png'
  ,123456
  ,'/attachments/db_schema_v1.png'
  ,'DESIGN');

-------------------------------------------------------------------------------
-- APP_ACTIVITY – példa logok
-------------------------------------------------------------------------------

INSERT INTO app_activity
  (project_id
  ,actor_id
  ,entity_type
  ,entity_id
  ,action
  ,payload)
VALUES
  ((SELECT id FROM app_project WHERE proj_key = 'PMA')
  ,(SELECT id FROM app_user WHERE email = 'admin@example.com')
  ,'PROJECT'
  ,(SELECT id FROM app_project WHERE proj_key = 'PMA')
  ,'PROJECT_CREATE'
  ,'Projekt létrehozva: PMA - Projektmenedzsment app');

INSERT INTO app_activity
  (project_id
  ,actor_id
  ,entity_type
  ,entity_id
  ,action
  ,payload)
VALUES
  ((SELECT id FROM app_project WHERE proj_key = 'PMA')
  ,(SELECT id FROM app_user WHERE email = 'peter@example.com')
  ,'TASK'
  ,(SELECT t.id FROM task t WHERE t.title = 'DB séma kialakítása')
  ,'TASK_CREATE'
  ,'Új task létrehozva: DB séma kialakítása');

INSERT INTO app_activity
  (project_id
  ,actor_id
  ,entity_type
  ,entity_id
  ,action
  ,payload)
VALUES
  ((SELECT id FROM app_project WHERE proj_key = 'PMA')
  ,(SELECT id FROM app_user WHERE email = 'dev@example.com')
  ,'TASK'
  ,(SELECT t.id FROM task t WHERE t.title = 'Historizáció implementálása')
  ,'TASK_STATUS_CHANGE'
  ,'Task státusz beállítva: IN_PROGRESS');


END;
/






