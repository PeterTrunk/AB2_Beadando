CREATE OR REPLACE PACKAGE project_mgmt_pkg IS

  PROCEDURE create_project_prc(p_project_name IN app_project.project_name%TYPE
                              ,p_proj_key     IN app_project.proj_key%TYPE
                              ,p_description  IN app_project.description%TYPE
                              ,p_owner_id     IN app_project.owner_id%TYPE
                              ,p_project_id   OUT app_project.id%TYPE);

  PROCEDURE assign_user_to_project_prc(p_project_id   IN project_member.project_id%TYPE
                                      ,p_user_id      IN project_member.user_id%TYPE
                                      ,p_project_role IN project_member.project_role%TYPE);

END project_mgmt_pkg;
/
