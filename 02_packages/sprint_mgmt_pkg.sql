CREATE OR REPLACE PACKAGE sprint_mgmt_pkg IS

  PROCEDURE create_sprint_prc(p_project_id  IN sprint.project_id%TYPE
                             ,p_board_id    IN sprint.board_id%TYPE
                             ,p_sprint_name IN sprint.sprint_name%TYPE
                             ,p_goal        IN sprint.goal%TYPE
                             ,p_start_date  IN sprint.start_date%TYPE
                             ,p_end_date    IN sprint.end_date%TYPE
                             ,p_state       IN sprint.state%TYPE
                             ,p_sprint_id   OUT sprint.id%TYPE);

END sprint_mgmt_pkg;
/
