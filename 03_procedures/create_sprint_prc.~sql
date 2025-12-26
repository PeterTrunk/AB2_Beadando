CREATE OR REPLACE PROCEDURE create_sprint_prc(p_project_id  IN sprint.project_id%TYPE
                                             ,p_board_id    IN sprint.board_id%TYPE
                                             ,p_sprint_name IN sprint.sprint_name%TYPE
                                             ,p_goal        IN sprint.goal%TYPE
                                             ,p_start_date  IN sprint.start_date%TYPE DEFAULT SYSDATE
                                             ,p_end_date    IN sprint.end_date%TYPE
                                             ,p_state       IN sprint.state%TYPE
                                             ,p_sprint_id   OUT sprint.id%TYPE) IS
BEGIN
  INSERT INTO sprint
    (project_id
    ,board_id
    ,sprint_name
    ,goal
    ,start_date
    ,end_date
    ,state)
  VALUES
    (p_project_id
    ,p_board_id
    ,p_sprint_name
    ,p_goal
    ,p_start_date
    ,p_end_date
    ,p_state)
  RETURNING id INTO p_sprint_id;

EXCEPTION
  WHEN dup_val_on_index THEN
    raise_application_error(-20090,
                            'create_sprint_prc: ütközés az egyedi constrainten (pl. sprint név / board kombó). ' ||
                            '(project_id = ' || p_project_id ||
                            ', board_id = ' || p_board_id ||
                            ', sprint_name = "' || p_sprint_name || '")');
  WHEN OTHERS THEN
    raise_application_error(-20091,
                            'create_sprint_prc hiba (project_id = ' ||
                            p_project_id || ', board_id = ' || p_board_id ||
                            ', sprint_name = "' || p_sprint_name || '"): ' ||
                            SQLERRM);
END;
/
