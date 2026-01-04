CREATE OR REPLACE PACKAGE BODY label_mgmt_pkg IS

  PROCEDURE create_label_prc(p_project_id IN labels.project_id%TYPE
                            ,p_label_name IN labels.label_name%TYPE
                            ,p_color      IN labels.color%TYPE
                            ,p_label_id   OUT labels.id%TYPE) IS
    l_cnt NUMBER;
  BEGIN
    SELECT COUNT(*) INTO l_cnt FROM app_project WHERE id = p_project_id;
  
    IF l_cnt = 0
    THEN
      err_log_pkg.log_error(p_module_name    => 'LABEL',
                            p_procedure_name => 'create_label_prc',
                            p_error_code     => -20371,
                            p_error_msg      => 'Projekt nem található a label létrehozásához.',
                            p_context        => 'project_id=' ||
                                                p_project_id ||
                                                '; label_name=' ||
                                                p_label_name,
                            p_api            => NULL);
      RAISE pkg_exceptions.label_project_not_found;
    END IF;
  
    INSERT INTO labels
      (project_id
      ,label_name
      ,color)
    VALUES
      (p_project_id
      ,p_label_name
      ,p_color)
    RETURNING id INTO p_label_id;
  
  EXCEPTION
    WHEN dup_val_on_index THEN
      err_log_pkg.log_error(p_module_name    => 'LABEL',
                            p_procedure_name => 'create_label_prc',
                            p_error_code     => -20370,
                            p_error_msg      => 'Label név ütközik projekten belül.',
                            p_context        => 'project_id=' ||
                                                p_project_id ||
                                                '; label_name=' ||
                                                p_label_name,
                            p_api            => NULL);
      RAISE pkg_exceptions.label_name_duplicate;
    
    WHEN OTHERS THEN
      err_log_pkg.log_error(p_module_name    => 'LABEL',
                            p_procedure_name => 'create_label_prc',
                            p_error_code     => SQLCODE,
                            p_error_msg      => SQLERRM,
                            p_context        => 'project_id=' ||
                                                p_project_id ||
                                                '; label_name=' ||
                                                p_label_name,
                            p_api            => NULL);
      RAISE pkg_exceptions.label_generic_error;
  END create_label_prc;

  PROCEDURE assign_label_to_task_prc(p_task_id  IN label_task.task_id%TYPE
                                    ,p_label_id IN label_task.label_id%TYPE) IS
  BEGIN
    INSERT INTO label_task
      (task_id
      ,label_id)
    VALUES
      (p_task_id
      ,p_label_id);
  
  EXCEPTION
    WHEN dup_val_on_index THEN
      err_log_pkg.log_error(p_module_name    => 'LABEL',
                            p_procedure_name => 'assign_label_to_task_prc',
                            p_error_code     => -20373,
                            p_error_msg      => 'Label már hozzá van rendelve ehhez a taskhoz.',
                            p_context        => 'task_id=' || p_task_id ||
                                                '; label_id=' || p_label_id,
                            p_api            => NULL);
      RAISE pkg_exceptions.label_task_duplicate;
    
    WHEN OTHERS THEN
      err_log_pkg.log_error(p_module_name    => 'LABEL',
                            p_procedure_name => 'assign_label_to_task_prc',
                            p_error_code     => SQLCODE,
                            p_error_msg      => SQLERRM,
                            p_context        => 'task_id=' || p_task_id ||
                                                '; label_id=' || p_label_id,
                            p_api            => NULL);
      RAISE pkg_exceptions.label_task_generic;
  END assign_label_to_task_prc;

END label_mgmt_pkg;
/
