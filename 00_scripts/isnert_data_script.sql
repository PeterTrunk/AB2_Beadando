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
  task_status_mgmt_pkg.create_task_status_prc(p_code        => 'BACKLOG',
                                              p_name        => 'Backlog',
                                              p_description => 'Ötletek, még nem tervezett feladatok.',
                                              p_is_final    => 0,
                                              p_position    => 1,
                                              p_status_id   => v_backlog_id);

  task_status_mgmt_pkg.create_task_status_prc(p_code        => 'TODO',
                                              p_name        => 'To Do',
                                              p_description => 'Következő sprintben megvalósítandó feladatok.',
                                              p_is_final    => 0,
                                              p_position    => 2,
                                              p_status_id   => v_todo_id);

  task_status_mgmt_pkg.create_task_status_prc(p_code        => 'IN_PROGRESS',
                                              p_name        => 'In Progress',
                                              p_description => 'Folyamatban lévő munka.',
                                              p_is_final    => 0,
                                              p_position    => 3,
                                              p_status_id   => v_inprogress_id);

  task_status_mgmt_pkg.create_task_status_prc(p_code        => 'REVIEW',
                                              p_name        => 'Review',
                                              p_description => 'Kód review / tesztelés alatt.',
                                              p_is_final    => 0,
                                              p_position    => 4,
                                              p_status_id   => v_review_id);

  task_status_mgmt_pkg.create_task_status_prc(p_code        => 'DONE',
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
