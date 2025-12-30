-------------------------------------------------------------------------------
-- TESZT ADATOK – AUTO ID + CREATED_AT triggerekhez igazítva
-------------------------------------------------------------------------------

-- SZEREPKÖRÖK
INSERT INTO app_role
  (role_name
  ,description)
VALUES
  ('ADMIN'
  ,'Rendszeradminisztrátor');

INSERT INTO app_role
  (role_name
  ,description)
VALUES
  ('PROJECT_OWNER'
  ,'Projekt tulajdonos / vezetõ');

INSERT INTO app_role
  (role_name
  ,description)
VALUES
  ('DEVELOPER'
  ,'Fejlesztõ csapattag');

-- FELHASZNÁLÓK
INSERT INTO app_user
  (email
  ,display_name
  ,password_hash
  ,is_active)
VALUES
  ('admin@example.com'
  ,'Admin Felhasználó'
  ,'hashed_admin_pw'
  ,1);

INSERT INTO app_user
  (email
  ,display_name
  ,password_hash
  ,is_active)
VALUES
  ('peter@example.com'
  ,'Trunk Péter'
  ,'hashed_peter_pw'
  ,1);

INSERT INTO app_user
  (email
  ,display_name
  ,password_hash
  ,is_active)
VALUES
  ('dev@example.com'
  ,'Fejlesztõ Béla'
  ,'hashed_dev_pw'
  ,0);

-- FELHASZNÁLÓ–SZEREPKÖR hozzárendelések
INSERT INTO app_user_role
  (user_id
  ,role_id)
VALUES
  ((SELECT id FROM app_user WHERE email = 'admin@example.com')
  ,(SELECT id FROM app_role WHERE role_name = 'ADMIN'));

INSERT INTO app_user_role
  (user_id
  ,role_id)
VALUES
  ((SELECT id FROM app_user WHERE email = 'admin@example.com')
  ,(SELECT id FROM app_role WHERE role_name = 'PROJECT_OWNER'));

INSERT INTO app_user_role
  (user_id
  ,role_id)
VALUES
  ((SELECT id FROM app_user WHERE email = 'peter@example.com')
  ,(SELECT id FROM app_role WHERE role_name = 'PROJECT_OWNER'));

INSERT INTO app_user_role
  (user_id
  ,role_id)
VALUES
  ((SELECT id FROM app_user WHERE email = 'peter@example.com')
  ,(SELECT id FROM app_role WHERE role_name = 'DEVELOPER'));

INSERT INTO app_user_role
  (user_id
  ,role_id)
VALUES
  ((SELECT id FROM app_user WHERE email = 'dev@example.com')
  ,(SELECT id FROM app_role WHERE role_name = 'DEVELOPER'));

-------------------------------------------------------------------------------
-- PROJEKTEK
-------------------------------------------------------------------------------

INSERT INTO app_project
  (project_name
  ,proj_key
  ,description
  ,owner_id)
VALUES
  ('PMA - Projektmenedzsment app'
  ,'PMA'
  ,'Saját hosztolású projektmenedzsment alkalmazás (kanban + statisztikák + Git integráció).'
  ,(SELECT id FROM app_user WHERE email = 'admin@example.com'));

INSERT INTO app_project
  (project_name
  ,proj_key
  ,description
  ,owner_id)
VALUES
  ('DEVOPS - Demo projekt'
  ,'DEVOPS'
  ,'Demo projekt DevOps pipeline-ok és issue tracking kipróbálásához.'
  ,(SELECT id FROM app_user WHERE email = 'peter@example.com'));

-- PROJEKT TAGSÁGOK (joined_at-et a trigger tölti)
INSERT INTO project_member
  (project_id
  ,user_id
  ,project_role)
VALUES
  ((SELECT id FROM app_project WHERE proj_key = 'PMA')
  ,(SELECT id FROM app_user WHERE email = 'admin@example.com')
  ,'OWNER');

INSERT INTO project_member
  (project_id
  ,user_id
  ,project_role)
VALUES
  ((SELECT id FROM app_project WHERE proj_key = 'PMA')
  ,(SELECT id FROM app_user WHERE email = 'peter@example.com')
  ,'DEVELOPER');

INSERT INTO project_member
  (project_id
  ,user_id
  ,project_role)
VALUES
  ((SELECT id FROM app_project WHERE proj_key = 'PMA')
  ,(SELECT id FROM app_user WHERE email = 'dev@example.com')
  ,'DEVELOPER');

INSERT INTO project_member
  (project_id
  ,user_id
  ,project_role)
VALUES
  ((SELECT id FROM app_project WHERE proj_key = 'DEVOPS')
  ,(SELECT id FROM app_user WHERE email = 'peter@example.com')
  ,'OWNER');

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
  ,commited_at)
VALUES
  ((SELECT t.id FROM task t WHERE t.title = 'Historizáció implementálása')
  ,'GITHUB'
  ,'trunkpeter/pma-demo'
  ,'abcdef1234567890abcdef1234567890abcdef12'
  ,'Add history triggers and audit columns'
  ,'dev@example.com'
  ,DATE '2025-01-05');

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

COMMIT;
