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
      ,state
      ,created_at)
    VALUES
      (p_project_id
      ,p_board_id
      ,p_sprint_name
      ,p_goal
      ,p_start_date
      ,p_end_date
      ,p_state
      ,SYSDATE)
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
