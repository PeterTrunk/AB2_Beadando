CREATE OR REPLACE PROCEDURE create_board_prc(p_project_id IN board.project_id%TYPE
                                            ,p_board_name IN board.board_name%TYPE
                                            ,p_is_default IN board.is_default%TYPE DEFAULT 0
                                            ,p_position   IN board.position%TYPE
                                            ,p_board_id   OUT board.id%TYPE) IS
BEGIN
  INSERT INTO board
    (project_id
    ,board_name
    ,is_default
    ,position)
  VALUES
    (p_project_id
    ,p_board_name
    ,nvl(p_is_default, 0)
    ,p_position)
  RETURNING id INTO p_board_id;

EXCEPTION
  WHEN dup_val_on_index THEN
    raise_application_error(-20070,
                            'create_board_prc: valószínû ütközés a board egyediségén (pl. név vagy pozíció projekten belül). ' ||
                            '(project_id = ' || p_project_id ||
                            ', board_name = "' || p_board_name || '")');
  WHEN OTHERS THEN
    raise_application_error(-20071,
                            'create_board_prc hiba (project_id = ' ||
                            p_project_id || ', board_name = "' ||
                            p_board_name || '"): ' || SQLERRM);
END;
/
