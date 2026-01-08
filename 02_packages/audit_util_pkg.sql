CREATE OR REPLACE PACKAGE audit_util_pkg IS 
  --Első Visszajelzés Utáni javítás (PKG -ekbe szervezés)
 
  --------------------------------------------------------------------
  -- AUTO ID + CREATED_AT TRIGGER LÉTREHOZÁSA
  -- Dinamikus SQL-lel létrehoz egy BEFORE INSERT triggert,
  -- amely automatikusan tölti az ID-t (sequence-ből) és a CREATED_AT-et.
  --------------------------------------------------------------------
  PROCEDURE create_auto_id_created_trg_prc(p_table_name IN VARCHAR2);

  --------------------------------------------------------------------
  -- HISTORISATION LÉTREHOZÁSA
  -- Létrehozza az _H history táblát + audit mezőket + trigger(eke)t
  -- a megadott alap tábla alapján.
  --------------------------------------------------------------------
  PROCEDURE create_historisation_for_table(p_table_name IN VARCHAR2);

END audit_util_pkg;
/
