CREATE OR REPLACE PROCEDURE create_label_prc(p_project_id IN labels.project_id%TYPE
                                            ,p_label_name IN labels.label_name%TYPE
                                            ,p_color      IN labels.color%TYPE
                                            ,p_label_id   OUT labels.id%TYPE) IS
BEGIN
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
    raise_application_error(-20120,
                            'create_label_prc: valószínû ütközés (pl. label név projekten belül). ' ||
                            '(project_id = ' || p_project_id ||
                            ', label_name = "' || p_label_name || '")');
  WHEN OTHERS THEN
    raise_application_error(-20121,
                            'create_label_prc hiba (project_id = ' ||
                            p_project_id || ', label_name = "' ||
                            p_label_name || '"): ' || SQLERRM);
END;
/
