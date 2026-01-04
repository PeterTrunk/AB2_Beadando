CREATE OR REPLACE PACKAGE comment_mgmt_pkg IS

  PROCEDURE create_comment_prc(p_task_id      IN app_comment.task_id%TYPE
                              ,p_user_id      IN app_comment.user_id%TYPE
                              ,p_comment_body IN app_comment.comment_body%TYPE
                              ,p_comment_id   OUT app_comment.id%TYPE);

END comment_mgmt_pkg;
/
