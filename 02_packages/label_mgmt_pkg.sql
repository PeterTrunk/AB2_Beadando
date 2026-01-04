CREATE OR REPLACE PACKAGE label_mgmt_pkg IS

  PROCEDURE create_label_prc(p_project_id IN labels.project_id%TYPE
                            ,p_label_name IN labels.label_name%TYPE
                            ,p_color      IN labels.color%TYPE
                            ,p_label_id   OUT labels.id%TYPE);

  PROCEDURE assign_label_to_task_prc(p_task_id  IN label_task.task_id%TYPE
                                    ,p_label_id IN label_task.label_id%TYPE);

END label_mgmt_pkg;
/
