CREATE OR REPLACE PACKAGE BODY board_mgmt_pkg IS

  PROCEDURE set_default_board_prc(p_project_id IN board.project_id%TYPE
                                 ,p_board_id   IN board.id%TYPE) IS
    l_cnt NUMBER;
  BEGIN
    ------------------------------------------------------------------
    -- 1. Ellenõrzés: a board tényleg ehhez a projekthez tartozik?
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
      RAISE pkg_exceptions.set_default_board_not_in_project;
    END IF;
  
    ------------------------------------------------------------------
    -- 2. Minden boardot levesszük default-ról
    ------------------------------------------------------------------
    UPDATE board
       SET is_default = 0
     WHERE project_id = p_project_id
       AND is_default = 1;
  
    ------------------------------------------------------------------
    -- 3. A megadott board lesz az alapértelmezett
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
      -- valószínûleg (project_id, board_name) unique constraint sérül
      err_log_pkg.log_error(p_module_name    => 'BOARD',
                            p_procedure_name => 'rename_board_prc',
                            p_error_code     => -20131,
                            p_error_msg      => 'Már létezik ilyen nevû board ugyanabban a projektben.',
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
