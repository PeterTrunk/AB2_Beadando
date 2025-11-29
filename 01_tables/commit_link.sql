CREATE TABLE commit_link(
  id                NUMBER          NOT NULL
  ,task_id          NUMBER          NOT NULL
  ,provider         VARCHAR2(16)    NOT NULL
  ,repo_full_name   VARCHAR2(255)   NOT NULL
  ,commit_sha       VARCHAR2(40)    NOT NULL
  ,message          VARCHAR2(4000)  NOT NULL
  ,author_email     VARCHAR2(255)   NOT NULL
  ,committed_at     DATE            NOT NULL
)
TABLESPACE users;

ALTER TABLE commit_link
      ADD CONSTRAINT pk_commit_link PRIMARY KEY (id);
ALTER TABLE commit_link
      ADD CONSTRAINT fk_commit_link_task FOREIGN KEY (task_id) REFERENCES task(id);
ALTER TABLE commit_link
      ADD CONSTRAINT uq_commit_link_task_commit UNIQUE (task_id, provider, repo_full_name, commit_sha);
ALTER TABLE commit_link
      ADD CONSTRAINT chk_commit_link_provider CHECK (provider IN ('GITHUB', 'GITLAB', 'AZURE_DEVOPS')); 
