CREATE OR REPLACE PACKAGE board_mgmt_pkg IS

  -- BOARD SZINTÛ ELJÁRÁSOK
  
  -- Új board létrehozása egy projekthez
  PROCEDURE create_board_prc(p_project_id IN board.project_id%TYPE
                            ,p_board_name IN board.board_name%TYPE
                            ,p_is_default IN board.is_default%TYPE DEFAULT 0
                            ,p_position   IN board.position%TYPE
                            ,p_board_id   OUT board.id%TYPE);

  -- Alapértelmezett board beállítása egy projekten belül
  PROCEDURE set_default_board_prc(p_project_id IN board.project_id%TYPE
                                 ,p_board_id   IN board.id%TYPE);

  -- Board átnevezése
  PROCEDURE rename_board_prc(p_board_id IN board.id%TYPE
                            ,p_new_name IN board.board_name%TYPE);

  -- Board sorrendjének módosítása projekten belül
  PROCEDURE reorder_board_prc(p_board_id     IN board.id%TYPE
                             ,p_new_position IN board.position%TYPE);

END board_mgmt_pkg;
/
