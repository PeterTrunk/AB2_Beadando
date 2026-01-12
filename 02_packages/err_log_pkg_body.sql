CREATE OR REPLACE PACKAGE BODY err_log_pkg IS

  PROCEDURE log_error(p_module_name    IN app_error_log.module_name%TYPE
                     ,p_procedure_name IN app_error_log.procedure_name%TYPE
                     ,p_error_code     IN app_error_log.error_code%TYPE
                     ,p_error_msg      IN app_error_log.error_msg%TYPE
                     ,p_context        IN app_error_log.context%TYPE
                     ,p_api            IN app_error_log.api%TYPE) IS
    PRAGMA AUTONOMOUS_TRANSACTION;
    l_id app_error_log.id%TYPE;
  BEGIN
    l_id := app_error_log_seq.nextval;
  
    INSERT INTO app_error_log
      (id
      ,err_time
      ,module_name
      ,procedure_name
      ,ERROR_CODE
      ,error_msg
      ,CONTEXT
      ,api)
    VALUES
      (l_id
      ,SYSDATE
      ,p_module_name
      ,p_procedure_name
      ,p_error_code
      ,substr(p_error_msg, 1, 4000) -- Biztonság kedvéért vágjuk le hogy biztosan le legyen tultöltés
      ,substr(p_context, 1, 4000)
      ,p_api);
    
    Commit;
  EXCEPTION
    WHEN OTHERS THEN
      NULL;
  END log_error;

END err_log_pkg;
/
