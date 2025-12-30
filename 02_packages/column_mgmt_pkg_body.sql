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

  PROCEDURE reorder_column_prc(p_column_id    IN column_def.id%TYPE
                              ,p_new_position IN column_def.position%TYPE) IS
    l_board_id column_def.board_id%TYPE;
    l_old_pos  column_def.position%TYPE;
  BEGIN
    IF p_new_position < 1
    THEN
      err_log_pkg.log_error(p_module_name    => 'COLUMN',
                            p_procedure_name => 'reorder_column_prc',
                            p_error_code     => -20160,
                            p_error_msg      => 'A pozíció nem lehet 1-nél kisebb.',
                            p_context        => 'column_id=' || p_column_id ||
                                                '; new_position=' ||
                                                p_new_position,
                            p_api            => NULL);
      RAISE pkg_exceptions.reorder_column_pos_invalid;
    END IF;
  
    SELECT board_id
          ,position
      INTO l_board_id
          ,l_old_pos
      FROM column_def
     WHERE id = p_column_id;
  
    IF p_new_position = l_old_pos
    THEN
      RETURN;
    END IF;
  
    -- Az adott boardhoz tartozó oszlopok pozícióinak eltolása
    IF p_new_position < l_old_pos
    THEN
      -- Köztes oszlopok pozíciója +1
      UPDATE column_def
         SET position = position + 1
       WHERE board_id = l_board_id
         AND position >= p_new_position
         AND position < l_old_pos;
    ELSE
      -- Lefelé mozgatjuk: köztes oszlopok pozíciója -1
      UPDATE column_def
         SET position = position - 1
       WHERE board_id = l_board_id
         AND position <= p_new_position
         AND position > l_old_pos;
    END IF;
  
    -- Kiválasztott oszlop új pozíciója
    UPDATE column_def SET position = p_new_position WHERE id = p_column_id;
  
  EXCEPTION
    WHEN no_data_found THEN
      -- Nem létezõ column_id
      err_log_pkg.log_error(p_module_name    => 'COLUMN',
                            p_procedure_name => 'reorder_column_prc',
                            p_error_code     => -20150,
                            p_error_msg      => 'A megadott oszlop nem található.',
                            p_context        => 'column_id=' || p_column_id ||
                                                '; new_position=' ||
                                                p_new_position,
                            p_api            => NULL);
      RAISE pkg_exceptions.update_column_not_found;
    
    WHEN OTHERS THEN
      err_log_pkg.log_error(p_module_name    => 'COLUMN',
                            p_procedure_name => 'reorder_column_prc',
                            p_error_code     => SQLCODE,
                            p_error_msg      => SQLERRM,
                            p_context        => 'column_id=' || p_column_id ||
                                                '; new_position=' ||
                                                p_new_position,
                            p_api            => NULL);
      RAISE pkg_exceptions.reorder_column_generic;
  END reorder_column_prc;

END column_mgmt_pkg;
/
