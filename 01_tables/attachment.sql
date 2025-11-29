CREATE TABLE attachment(
id NUMBER NOT NULL
,task_id NUMBER NOT NULL
,uploaded_by NUMBER NOT NULL
,file_name VARCHAR2(255) NOT NULL
,content_type VARCHAR2(128) NOT NULL
,size_bytes NUMBER NOT NULL
,storage_path VARCHAR2(255) NOT NULL
,attachment_type VARCHAR2(16)
,created_at DATE DEFAULT SYSDATE NOT NULL
)
TABLESPACE users;

ALTER TABLE attachment
      ADD CONSTRAINT pk_attachment PRIMARY KEY (id);
ALTER TABLE attachment
      ADD CONSTRAINT fk_attachment_task FOREIGN KEY (task_id) REFERENCES task(id);
ALTER TABLE attachment
      ADD CONSTRAINT fk_attachment_uploaded_by FOREIGN KEY (uploaded_by) REFERENCES app_user(id);
ALTER TABLE attachment
      ADD CONSTRAINT chk_attachment_size_positive CHECK (size_bytes > 0);
ALTER TABLE attachment
      ADD CONSTRAINT uq_attachment_storage_path UNIQUE (storage_path);
