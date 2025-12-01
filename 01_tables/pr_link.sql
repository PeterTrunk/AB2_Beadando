CREATE TABLE pr_link(
  id                NUMBER          NOT NULL
  ,task_id          NUMBER          NOT NULL
  ,provider         VARCHAR2(16)    NOT NULL
  ,repo_full_name   VARCHAR2(255)   NOT NULL
  ,pr_number        NUMBER          NOT NULL
  ,title            VARCHAR2(255)
  ,state            VARCHAR2(24)    NOT NULL
  ,created_at       DATE            DEFAULT SYSDATE NOT NULL
  ,merged_at        DATE
)
TABLESPACE users;

ALTER TABLE pr_link
      ADD (CONSTRAINT pk_pr_link PRIMARY KEY (id),
      CONSTRAINT fk_pr_link_task FOREIGN KEY (task_id) REFERENCES task(id),
      CONSTRAINT uq_pr_link_task_pr UNIQUE (task_id, provider, repo_full_name, pr_number),
      CONSTRAINT chk_pr_link_provider CHECK (provider IN ('GITHUB', 'GITLAB', 'AZURE_DEVOPS')),
      CONSTRAINT chk_pr_link_state CHECK (state IN ('OPEN', 'CLOSED', 'MERGED')));

CREATE SEQUENCE pr_link_seq START WITH 100;

COMMENT ON TABLE pr_link IS
  'Pull Request hivatkozások taskokhoz, állapot és metaadatok.
  A commit-hoz hasonlóan megjelenik a tasknál egy pr, és annak status-át is jelezve';
