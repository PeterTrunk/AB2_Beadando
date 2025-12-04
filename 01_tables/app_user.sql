CREATE TABLE app_user(
  id              NUMBER          NOT NULL
  ,email          VARCHAR2(255)   UNIQUE NOT NULL
  ,display_name   VARCHAR2(120)   NOT NULL
  ,password_hash  VARCHAR2(255)
  ,is_active      number(1)       DEFAULT 0 NOT NULL
  ,created_at     DATE            DEFAULT SYSDATE NOT NULL
)
TABLESPACE users;

ALTER TABLE app_user
      CONSTRAINT app_user_pk PRIMARY KEY (id);
      
CREATE SEQUENCE app_user_seq START WITH 100;

COMMENT ON TABLE app_user IS
  'Felhasználói tábla: bejelentkezési adatok, alap profil információk.';

COMMENT ON COLUMN app_user.id IS 'Egyedi felhasználó azonosító.';
COMMENT ON COLUMN app_user.email IS 'E-mail cím, egyedi, belépéshez használt.';
COMMENT ON COLUMN app_user.display_name IS 'Felhasználó megjelenített neve.';
COMMENT ON COLUMN app_user.password_hash IS 'Titkosított jelszó.';
COMMENT ON COLUMN app_user.is_active IS 'Aktivitási státusz.';

