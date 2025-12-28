CREATE OR REPLACE PACKAGE column_mgmt_pkg IS

  -- COLUMN (OSZLOP) SZINTÛ ELJÁRÁSOK
  
  -- Új oszlop létrehozása egy boardon
  PROCEDURE create_column_prc(p_board_id    IN column_def.board_id%TYPE
                             ,p_column_name IN column_def.column_name%TYPE
                             ,p_wip_limit   IN column_def.wip_limit%TYPE
                             ,p_position    IN column_def.position%TYPE
                             ,p_status_code IN task_status.code%TYPE
                             ,p_column_id   OUT column_def.id%TYPE);

  -- Oszlop nevének és WIP-limitjének módosítása
  PROCEDURE update_column_prc(p_column_id     IN column_def.id%TYPE
                             ,p_new_name      IN column_def.column_name%TYPE
                             ,p_new_wip_limit IN column_def.wip_limit%TYPE);

  -- Oszlop sorrendjének módosítása egy boardon belül
  PROCEDURE reorder_column_prc(p_column_id    IN column_def.id%TYPE
                              ,p_new_position IN column_def.position%TYPE);

END board_mgmt_pkg;
/
