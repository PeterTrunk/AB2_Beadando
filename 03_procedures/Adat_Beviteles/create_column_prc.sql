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
END;
/
