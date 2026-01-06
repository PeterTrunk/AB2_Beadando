CREATE OR REPLACE PACKAGE BODY comment_mgmt_pkg IS

  PROCEDURE create_comment_prc(p_task_id      IN app_comment.task_id%TYPE
                              ,p_user_id      IN app_comment.user_id%TYPE
                              ,p_comment_body IN app_comment.comment_body%TYPE
                              ,p_comment_id   OUT app_comment.id%TYPE) IS
    l_task_cnt NUMBER;
    l_user_cnt NUMBER;
  BEGIN
    SELECT COUNT(*) INTO l_task_cnt FROM task WHERE id = p_task_id;
  
    IF l_task_cnt = 0
    THEN
      err_log_pkg.log_error(p_module_name    => 'COMMENT',
                            p_procedure_name => 'create_comment_prc',
                            p_error_code     => -20380,
                            p_error_msg      => 'A megadott task nem létezik kommenthez.',
                            p_context        => 'task_id=' || p_task_id ||
                                                '; user_id=' || p_user_id,
                            p_api            => NULL);
      RAISE pkg_exceptions.comment_task_not_found;
    END IF;
  
    SELECT COUNT(*) INTO l_user_cnt FROM app_user WHERE id = p_user_id;
  
    IF l_user_cnt = 0
    THEN
      err_log_pkg.log_error(p_module_name    => 'COMMENT',
                            p_procedure_name => 'create_comment_prc',
                            p_error_code     => -20381,
                            p_error_msg      => 'A megadott user nem létezik kommenthez.',
                            p_context        => 'task_id=' || p_task_id ||
                                                '; user_id=' || p_user_id,
                            p_api            => NULL);
      RAISE pkg_exceptions.comment_user_not_found;
    END IF;
  
    INSERT INTO app_comment
      (task_id
      ,user_id
      ,comment_body)
    VALUES
      (p_task_id
      ,p_user_id
      ,p_comment_body)
    RETURNING id INTO p_comment_id;
  
  EXCEPTION
    WHEN OTHERS THEN
      err_log_pkg.log_error(p_module_name    => 'COMMENT',
                            p_procedure_name => 'create_comment_prc',
                            p_error_code     => SQLCODE,
                            p_error_msg      => SQLERRM,
                            p_context        => 'task_id=' || p_task_id ||
                                                '; user_id=' || p_user_id,
                            p_api            => NULL);
      RAISE pkg_exceptions.comment_create_generic;
  END create_comment_prc;

END comment_mgmt_pkg;
/
