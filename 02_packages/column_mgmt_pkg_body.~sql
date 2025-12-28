CREATE OR REPLACE PACKAGE BODY column_mgmt_pkg IS

  --------------------------------------------------------------------
  -- COLUMN ELJÁRÁSOK
  --------------------------------------------------------------------

  CREATE OR REPLACE PROCEDURE create_column_prc(p_board_id    IN column_def.board_id%TYPE
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
      raise_application_error(-20080,
                              'create_column_prc: nincs ilyen task_status code: "' ||
                              p_status_code || '".');
    
    WHEN dup_val_on_index THEN
      raise_application_error(-20081,
                              'create_column_prc: ütközés a column_def egyediségén (név vagy pozíció boardon belül). ' ||
                              '(board_id = ' || p_board_id ||
                              ', column_name = "' || p_column_name || '")');
    
    WHEN OTHERS THEN
      raise_application_error(-20082,
                              'create_column_prc hiba (board_id = ' ||
                              p_board_id || ', column_name = "' ||
                              p_column_name || '", status_code = "' ||
                              p_status_code || '"): ' || SQLERRM);
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
      raise_application_error(-20150,
                              'update_column_prc: nem található a megadott column (id=' ||
                              p_column_id || ').');
    END IF;
  
  EXCEPTION
    WHEN dup_val_on_index THEN
      -- (board_id, column_name) vagy (board_id, position) unique megsértése
      raise_application_error(-20151,
                              'update_column_prc: ütközés a column egyedi constraintjeivel (név vagy WIP/pozíció).');
    WHEN OTHERS THEN
      raise_application_error(-20152,
                              'update_column_prc hiba (column_id=' ||
                              p_column_id || '): ' || SQLERRM);
  END update_column_prc;
  ------------------------------------------------------------------------------------------------------------------------------------

  PROCEDURE reorder_column_prc(p_column_id    IN column_def.id%TYPE
                              ,p_new_position IN column_def.position%TYPE) IS
    l_board_id column_def.board_id%TYPE;
    l_old_pos  column_def.position%TYPE;
  BEGIN
    IF p_new_position < 1
    THEN
      raise_application_error(-20160,
                              'reorder_column_prc: a pozíció nem lehet 1-nél kisebb.');
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
    WHEN OTHERS THEN
      raise_application_error(-20161,
                              'reorder_column_prc hiba (column_id=' ||
                              p_column_id || ', new_position=' ||
                              p_new_position || '): ' || SQLERRM);
  END reorder_column_prc;
  ------------------------------------------------------------------------------------------------------------------------------------
  
END board_mgmt_pkg;
/
