CREATE OR REPLACE PACKAGE err_log_pkg IS

  PROCEDURE log_error(p_module_name    IN app_error_log.module_name%TYPE
                     ,p_procedure_name IN app_error_log.procedure_name%TYPE
                     ,p_error_code     IN app_error_log.error_code%TYPE
                     ,p_error_msg      IN app_error_log.error_msg%TYPE
                     ,p_context        IN app_error_log.context%TYPE DEFAULT NULL
                     ,p_api            IN app_error_log.api%TYPE DEFAULT NULL);

END err_log_pkg;
/
