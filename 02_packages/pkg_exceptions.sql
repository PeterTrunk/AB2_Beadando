CREATE OR REPLACE PACKAGE pkg_exceptions IS

  --------------------------------------------------------------------
  -- CREATE_COLUMN
  --------------------------------------------------------------------
  
  create_column_status_not_found EXCEPTION;
  PRAGMA EXCEPTION_INIT(create_column_status_not_found, -20080);
  
  create_column_dup EXCEPTION;
  PRAGMA EXCEPTION_INIT(create_column_dup, -20081);
  
  create_column_generic EXCEPTION;
  PRAGMA EXCEPTION_INIT(create_column_generic, -20082);
  
  --------------------------------------------------------------------
  -- CREATE_TASK
  --------------------------------------------------------------------
  create_task_dup EXCEPTION;
  PRAGMA EXCEPTION_INIT(create_task_dup, -20100);

  create_task_generic EXCEPTION;
  PRAGMA EXCEPTION_INIT(create_task_generic, -20101);

  assign_user_already_assigned EXCEPTION;
  PRAGMA EXCEPTION_INIT(assign_user_already_assigned, -20110);

  assign_user_generic  EXCEPTION;
  PRAGMA EXCEPTION_INIT(assign_user_generic, -20111);

  --------------------------------------------------------------------
  -- BOARD / SET DEFAULT
  --------------------------------------------------------------------
  set_default_board_not_in_proj EXCEPTION;
  PRAGMA EXCEPTION_INIT(set_default_board_not_in_proj, -20120);

  set_default_board_generic EXCEPTION;
  PRAGMA EXCEPTION_INIT(set_default_board_generic, -20121);

  --------------------------------------------------------------------
  -- BOARD RENAME
  --------------------------------------------------------------------
  rename_board_not_found EXCEPTION;
  PRAGMA EXCEPTION_INIT(rename_board_not_found, -20130);

  rename_board_duplicate EXCEPTION;
  PRAGMA EXCEPTION_INIT(rename_board_duplicate, -20131);

  rename_board_generic EXCEPTION;
  PRAGMA EXCEPTION_INIT(rename_board_generic, -20132);

  --------------------------------------------------------------------
  -- BOARD REORDER
  --------------------------------------------------------------------
  reorder_board_pos_invalid EXCEPTION;
  PRAGMA EXCEPTION_INIT(reorder_board_pos_invalid, -20140);

  reorder_board_generic EXCEPTION;
  PRAGMA EXCEPTION_INIT(reorder_board_generic, -20141);

  --------------------------------------------------------------------
  -- COLUMN UPDATE
  --------------------------------------------------------------------
  update_column_not_found EXCEPTION;
  PRAGMA EXCEPTION_INIT(update_column_not_found, -20150);

  update_column_duplicate EXCEPTION;
  PRAGMA EXCEPTION_INIT(update_column_duplicate, -20151);

  update_column_generic EXCEPTION;
  PRAGMA EXCEPTION_INIT(update_column_generic, -20152);

  --------------------------------------------------------------------
  -- COLUMN REORDER
  --------------------------------------------------------------------
  reorder_column_pos_invalid EXCEPTION;
  PRAGMA EXCEPTION_INIT(reorder_column_pos_invalid, -20160);

  reorder_column_generic EXCEPTION;
  PRAGMA EXCEPTION_INIT(reorder_column_generic, -20161);

  --------------------------------------------------------------------
  -- TASK MOVE (move_task_to_column_prc)
  --------------------------------------------------------------------
  move_task_board_mismatch EXCEPTION;
  PRAGMA EXCEPTION_INIT(move_task_board_mismatch, -20210);

  move_task_wip_exceeded EXCEPTION;
  PRAGMA EXCEPTION_INIT(move_task_wip_exceeded, -20211);

  move_task_pos_invalid EXCEPTION;
  PRAGMA EXCEPTION_INIT(move_task_pos_invalid, -20212);

  move_task_not_found EXCEPTION;
  PRAGMA EXCEPTION_INIT(move_task_not_found, -20213);

  move_task_generic EXCEPTION;
  PRAGMA EXCEPTION_INIT(move_task_generic, -20214);

  --------------------------------------------------------------------
  -- TASK REORDER (reorder_task_in_column_prc)
  --------------------------------------------------------------------
  reorder_task_pos_invalid EXCEPTION;
  PRAGMA EXCEPTION_INIT(reorder_task_pos_invalid, -20220);

  reorder_task_not_found EXCEPTION;
  PRAGMA EXCEPTION_INIT(reorder_task_not_found, -20221);

  reorder_task_generic EXCEPTION;
  PRAGMA EXCEPTION_INIT(reorder_task_generic, -20222);

  --------------------------------------------------------------------
  -- TASK STATUS SYNC TRIGGER
  --------------------------------------------------------------------
  task_status_column_not_found EXCEPTION;
  PRAGMA EXCEPTION_INIT(task_status_column_not_found, -20300);
  
  --------------------------------------------------------------------
  -- BOARD OVERVIEW PKG
  --------------------------------------------------------------------
  board_overview_board_not_found EXCEPTION;
  PRAGMA EXCEPTION_INIT(board_overview_board_not_found, -20310);

  board_overview_sprint_mismatch EXCEPTION;
  PRAGMA EXCEPTION_INIT(board_overview_sprint_mismatch, -20311);

  board_overview_generic EXCEPTION;
  PRAGMA EXCEPTION_INIT(board_overview_generic, -20312);
  
  --------------------------------------------------------------------
  -- GIT INTEGRATION
  --------------------------------------------------------------------
  git_integration_not_found EXCEPTION;
  PRAGMA EXCEPTION_INIT(git_integration_not_found, -20320);

  git_message_no_task_key EXCEPTION;
  PRAGMA EXCEPTION_INIT(git_message_no_task_key, -20321);

  git_invalid_event_type EXCEPTION;
  PRAGMA EXCEPTION_INIT(git_invalid_event_type, -20322);

  git_integration_generic EXCEPTION;
  PRAGMA EXCEPTION_INIT(git_integration_generic, -20323);


END pkg_exceptions;
/
