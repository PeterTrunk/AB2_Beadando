CREATE OR REPLACE PACKAGE git_integration_pkg IS

  PROCEDURE create_integration_prc(p_project_id     IN integration.project_id%TYPE
                                  ,p_provider       IN integration.provider%TYPE
                                  ,p_repo_full_name IN integration.repo_full_name%TYPE
                                  ,p_access_token   IN integration.access_token%TYPE
                                  ,p_webhook_secret IN integration.webhook_secret%TYPE
                                  ,p_is_enabled     IN integration.is_enabled%TYPE DEFAULT 1
                                  ,p_integration_id OUT integration.id%TYPE);

  PROCEDURE add_commit_link_prc(p_task_id        IN commit_link.task_id%TYPE
                               ,p_provider       IN commit_link.provider%TYPE
                               ,p_repo_full_name IN commit_link.repo_full_name%TYPE
                               ,p_commit_sha     IN commit_link.commit_sha%TYPE
                               ,p_message        IN commit_link.message%TYPE
                               ,p_author_email   IN commit_link.author_email%TYPE
                               ,p_committed_at   IN commit_link.committed_at%TYPE);

  PROCEDURE add_pr_link_prc(p_task_id        IN pr_link.task_id%TYPE
                           ,p_provider       IN pr_link.provider%TYPE
                           ,p_repo_full_name IN pr_link.repo_full_name%TYPE
                           ,p_pr_number      IN pr_link.pr_number%TYPE
                           ,p_title          IN pr_link.title%TYPE
                           ,p_state          IN pr_link.state%TYPE
                           ,p_created_at     IN pr_link.created_at%TYPE
                           ,p_merged_at      IN pr_link.merged_at%TYPE);

  ------------------------------------------------------------------
  --    Általános függvény commit/PR webhook esemény feldolgozására
  --    (ezt hívná a backend webhook handler)
  --
  --  - p_proj_key:  pl. 'PMA'
  --  - p_event_type: 'COMMIT' vagy 'PR'
  --  - p_message:   commit üzenet / PR title+body összevonva
  --  - commit esetén: p_commit_sha, p_author_email, p_committed_at
  --  - PR esetén:     p_pr_number, p_state, p_created_at, p_merged_at
  --
  --  Visszatérés: sikeresen taskhoz kötött linkek száma.
  ------------------------------------------------------------------
  FUNCTION process_git_message_fnc(p_proj_key       IN app_project.proj_key%TYPE
                                  ,p_event_type     IN VARCHAR2
                                  , -- 'COMMIT' / 'PR'
                                   p_message        IN VARCHAR2
                                  ,p_provider       IN VARCHAR2
                                  ,p_repo_full_name IN VARCHAR2
                                  ,p_commit_sha     IN VARCHAR2 DEFAULT NULL
                                  ,p_author_email   IN VARCHAR2 DEFAULT NULL
                                  ,p_committed_at   IN DATE DEFAULT NULL
                                  ,p_pr_number      IN NUMBER DEFAULT NULL
                                  ,p_state          IN VARCHAR2 DEFAULT NULL
                                  ,p_created_at     IN DATE DEFAULT NULL
                                  ,p_merged_at      IN DATE DEFAULT NULL)
    RETURN PLS_INTEGER;

END git_integration_pkg;
/
