CREATE TABLE app_error_log (
  id              NUMBER          NOT NULL,
  err_time        DATE            DEFAULT SYSDATE NOT NULL,
  module_name     VARCHAR2(128),
  procedure_name  VARCHAR2(128),
  error_code      NUMBER,
  error_msg       VARCHAR2(4000),
  context         VARCHAR2(4000),
  api varchar2(100)
)
TABLESPACE users;

ALTER TABLE app_error_log
  ADD CONSTRAINT pk_app_error_log PRIMARY KEY (id);

CREATE SEQUENCE app_error_log_seq START WITH 1;

COMMENT ON TABLE app_error_log IS
  'Alkalmazás szintû hiba log tábla.';
