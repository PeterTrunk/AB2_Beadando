CREATE OR REPLACE PROCEDURE create_comment_prc(p_task_id      IN app_comment.task_id%TYPE
                                              ,p_user_id      IN app_comment.user_id%TYPE
                                              ,p_comment_body IN app_comment.comment_body%TYPE
                                              ,p_comment_id   OUT app_comment.id%TYPE) IS
BEGIN
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
    raise_application_error(-20140,
                            'create_comment_prc hiba (task_id = ' ||
                            p_task_id || ', user_id = ' || p_user_id ||
                            '): ' || SQLERRM);
END;
/
