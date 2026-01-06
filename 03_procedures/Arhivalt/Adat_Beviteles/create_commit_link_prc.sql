CREATE OR REPLACE PROCEDURE create_commit_link_prc(p_task_id        IN commit_link.task_id%TYPE
                                                  ,p_provider       IN commit_link.provider%TYPE
                                                  ,p_repo_full_name IN commit_link.repo_full_name%TYPE
                                                  ,p_commit_sha     IN commit_link.commit_sha%TYPE
                                                  ,p_message        IN commit_link.message%TYPE
                                                  ,p_author_email   IN commit_link.author_email%TYPE
                                                  ,p_committed_at   IN commit_link.committed_at%TYPE) IS
BEGIN
  INSERT INTO commit_link
    (task_id
    ,provider
    ,repo_full_name
    ,commit_sha
    ,message
    ,author_email
    ,committed_at)
  VALUES
    (p_task_id
    ,p_provider
    ,p_repo_full_name
    ,p_commit_sha
    ,p_message
    ,p_author_email
    ,p_committed_at);

EXCEPTION
  WHEN OTHERS THEN
    raise_application_error(-20170,
                            'create_commit_link_prc hiba (task_id = ' ||
                            p_task_id || ', commit_sha = "' || p_commit_sha ||
                            '"): ' || SQLERRM);
END;
/
