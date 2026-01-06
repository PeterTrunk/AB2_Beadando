CREATE OR REPLACE PACKAGE BODY board_mgmt_pkg IS
  PROCEDURE create_board_prc(p_project_id IN board.project_id%TYPE
                            ,p_board_name IN board.board_name%TYPE
                            ,p_is_default IN board.is_default%TYPE DEFAULT 0
                            ,p_position   IN board.position%TYPE
                            ,p_board_id   OUT board.id%TYPE) IS
    l_project_cnt NUMBER;
    l_position    board.position%TYPE;
  BEGIN
    ------------------------------------------------------------------
    -- Projekt létezésének ellenőrzése
    ------------------------------------------------------------------
    SELECT COUNT(*)
      INTO l_project_cnt
      FROM app_project
     WHERE id = p_project_id;
  
    IF l_project_cnt = 0
    THEN
      raise_application_error(-20110,
                              'create_board_prc: a megadott projekt nem létezik (project_id=' ||
                              p_project_id || ').');
    END IF;
  
    ------------------------------------------------------------------
    -- Pozíció meghatározása
    -- Ha p_position NULL vagy < 1 → a projekt board-listájának végére rakjuk
    ------------------------------------------------------------------
    IF p_position IS NULL
       OR p_position < 1
    THEN
      SELECT nvl(MAX(position), 0) + 1
        INTO l_position
        FROM board
       WHERE project_id = p_project_id;
    ELSE
      l_position := p_position;
    END IF;
  
    ------------------------------------------------------------------
    -- Board beszúrása
    ------------------------------------------------------------------
    INSERT INTO board
      (project_id
      ,board_name
      ,is_default
      ,position
      ,created_at)
    VALUES
      (p_project_id
      ,p_board_name
      ,nvl(p_is_default, 0)
      ,l_position
      ,SYSDATE)
    RETURNING id INTO p_board_id;
  
    ------------------------------------------------------------------
    -- Ha default board, akkor a többi default flag-et levesszük
    ------------------------------------------------------------------
    IF nvl(p_is_default, 0) = 1
    THEN
      -- minden más boardról levesszük az is_default-ot
      UPDATE board
         SET is_default = 0
       WHERE project_id = p_project_id
         AND id <> p_board_id;
    
      -- biztos ami biztos, ezt az egyet 1-re tesszük
      UPDATE board SET is_default = 1 WHERE id = p_board_id;
    END IF;
  
  EXCEPTION
    WHEN dup_val_on_index THEN
      raise_application_error(-20111,
                              'create_board_prc: ütközés az egyedi constrainten (valószínűleg (project_id, board_name) vagy (project_id, position)). ' ||
                              '(project_id=' || p_project_id ||
                              ', board_name="' || p_board_name || '")');
    WHEN OTHERS THEN
      raise_application_error(-20112,
                              'create_board_prc hiba (project_id=' ||
                              p_project_id || ', board_name="' ||
                              p_board_name || '"): ' || SQLERRM);
  END create_board_prc;

  PROCEDURE set_default_board_prc(p_project_id IN board.project_id%TYPE
                                 ,p_board_id   IN board.id%TYPE) IS
    l_cnt NUMBER;
  BEGIN
    ------------------------------------------------------------------
    -- Ellenőrzés: a board tényleg ehhez a projekthez tartozik?
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
      RAISE pkg_exceptions.set_default_board_not_in_proj;
    END IF;
  
    ------------------------------------------------------------------
    -- Minden boardot levesszük default-ról
    ------------------------------------------------------------------
    UPDATE board
       SET is_default = 0
     WHERE project_id = p_project_id
       AND is_default = 1;
  
    ------------------------------------------------------------------
    -- A megadott board lesz az alapértelmezett
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
      err_log_pkg.log_error(p_module_name    => 'BOARD',
                            p_procedure_name => 'rename_board_prc',
                            p_error_code     => -20131,
                            p_error_msg      => 'Már létezik ilyen nevű board ugyanabban a projektben.',
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
