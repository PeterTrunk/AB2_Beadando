CREATE OR REPLACE PACKAGE BODY board_mgmt_pkg IS

  --------------------------------------------------------------------
  -- BOARD ELJÁRÁSOK
  --------------------------------------------------------------------

  PROCEDURE set_default_board_prc(p_project_id IN board.project_id%TYPE
                                 ,p_board_id   IN board.id%TYPE) IS
    l_cnt NUMBER;
  BEGIN
    -- Ellenõrizzük, hogy a board tényleg ehhez a projekthez tartozik
    SELECT COUNT(*)
      INTO l_cnt
      FROM board
     WHERE id = p_board_id
       AND project_id = p_project_id;

    IF l_cnt = 0
    THEN
      raise_application_error(-20120,
                              'set_default_board_prc: a megadott board nem tartozik a projekthez.');
    END IF;

  -- Minden boardot levesszük default-ról
  UPDATE board
     SET is_default = 0
   WHERE project_id = p_project_id
     AND is_default = 1;

  -- A megadott board lesz az alapértelmezett
  UPDATE board
     SET is_default = 1
   WHERE id = p_board_id;

EXCEPTION
  WHEN OTHERS THEN
    RAISE_APPLICATION_ERROR(
      -20121,
      'set_default_board_prc hiba (project_id=' || p_project_id ||
      ', board_id=' || p_board_id || '): ' || SQLERRM
    );
  END set_default_board_prc;
  ----------------------------------------------------------------------------------------------------------------------------------------
  
  
  PROCEDURE rename_board_prc(p_board_id IN board.id%TYPE
                            ,p_new_name IN board.board_name%TYPE) IS
  BEGIN
    UPDATE board SET board_name = p_new_name WHERE id = p_board_id;

    IF SQL%ROWCOUNT = 0
    THEN
      raise_application_error(-20130,
                              'rename_board_prc: nem található a megadott board (id=' ||
                              p_board_id || ').');
    END IF;

  EXCEPTION
    WHEN dup_val_on_index THEN
      -- valószínûleg (project_id, board_name) unique constraint sérül
      raise_application_error(-20131,
                              'rename_board_prc: már létezik ilyen nevû board ugyanabban a projektben.');
    WHEN OTHERS THEN
      raise_application_error(-20132,
                              'rename_board_prc hiba (board_id=' ||
                              p_board_id || '): ' || SQLERRM);
  END rename_board_prc;
  ----------------------------------------------------------------------------------------------------------------------------------------

  PROCEDURE reorder_board_prc(p_board_id     IN board.id%TYPE
                             ,p_new_position IN board.position%TYPE) IS
    l_project_id board.project_id%TYPE;
    l_old_pos    board.position%TYPE;
  BEGIN
    IF p_new_position < 1
    THEN
      raise_application_error(-20140,
                              'reorder_board_prc: a pozíció nem lehet 1-nél kisebb.');
    END IF;

    -- Board jelenlegi adatai
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

    -- Az azonos projekthez tartozó boardok pozícióinak eltolása
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

    -- A kiválasztott board új pozíciója
    UPDATE board SET position = p_new_position WHERE id = p_board_id;

  EXCEPTION
    WHEN OTHERS THEN
      raise_application_error(-20141,
                              'reorder_board_prc hiba (board_id=' ||
                              p_board_id || ', new_position=' ||
                              p_new_position || '): ' || SQLERRM);
  END reorder_board_prc;
  ----------------------------------------------------------------------------------------------------------------------------------------
  
END board_mgmt_pkg;
/
