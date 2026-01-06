CREATE OR REPLACE TRIGGER task_status_sync_trg
  BEFORE INSERT OR UPDATE ON task
  FOR EACH ROW
DECLARE
  l_status_id column_def.status_id%TYPE;
BEGIN
  -- Ha nincs column_id, nem tudunk szinkronizálni
  IF :new.column_id IS NULL
  THEN
    RETURN;
  END IF;

  -- Lekérjük az adott oszlophoz tartozó status_id-t
  SELECT status_id
    INTO l_status_id
    FROM column_def
   WHERE id = :new.column_id;

  -- Felülírjuk a task status_id-ját az oszlop statuszával
  :new.status_id := l_status_id;

EXCEPTION
  WHEN no_data_found THEN
    raise_application_error(-21000,
                            'task_status_sync_trg: nincs ilyen column_def.id: ' ||
                            :new.column_id);
END;
/
