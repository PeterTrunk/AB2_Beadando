CREATE OR REPLACE PROCEDURE create_pr_link_prc(p_task_id        IN pr_link.task_id%TYPE
                                              ,p_provider       IN pr_link.provider%TYPE
                                              ,p_repo_full_name IN pr_link.repo_full_name%TYPE
                                              ,p_pr_number      IN pr_link.pr_number%TYPE
                                              ,p_title          IN pr_link.title%TYPE
                                              ,p_state          IN pr_link.state%TYPE
                                              ,p_created_at     IN pr_link.created_at%TYPE
                                              ,p_merged_at      IN pr_link.merged_at%TYPE
                                              ,p_pr_id          OUT pr_link.id%TYPE) IS
BEGIN
  INSERT INTO pr_link
    (task_id
    ,provider
    ,repo_full_name
    ,pr_number
    ,title
    ,state
    ,created_at
    ,merged_at)
  VALUES
    (p_task_id
    ,p_provider
    ,p_repo_full_name
    ,p_pr_number
    ,p_title
    ,p_state
    ,p_created_at
    ,p_merged_at)
  RETURNING id INTO p_pr_id;

EXCEPTION
  WHEN OTHERS THEN
    raise_application_error(-20180,
                            'create_pr_link_prc hiba (task_id = ' ||
                            p_task_id || ', pr_number = ' || p_pr_number ||
                            '): ' || SQLERRM);
END;
/
