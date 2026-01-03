DECLARE
  l_overview ty_board_overview;
  v_git_info VARCHAR2(100);
BEGIN
  l_overview := board_overview_pkg.get_board_overview_fnc(
                  p_board_id  => 1,
                  p_sprint_id => 1
                );

  FOR i IN 1 .. l_overview.column_list.COUNT LOOP
    DBMS_OUTPUT.put_line('COLUMN: ' || l_overview.column_list(i).column_name);

    IF l_overview.column_list(i).tasks IS NOT NULL THEN
      FOR j IN 1 .. l_overview.column_list(i).tasks.COUNT LOOP
        DBMS_OUTPUT.put_line(
          '  - ' ||
          l_overview.column_list(i).tasks(j).task_key || ' ' ||
          l_overview.column_list(i).tasks(j).title
        );

        -- Assignees
        IF l_overview.column_list(i).tasks(j).assignees_text IS NOT NULL THEN
          DBMS_OUTPUT.put_line(
            '      Assigned to: ' ||
            l_overview.column_list(i).tasks(j).assignees_text
          );
        END IF;

        -- Attachments
        IF NVL(l_overview.column_list(i).tasks(j).attachment_count, 0) > 0 THEN
          DBMS_OUTPUT.put_line(
            '      Attachments: ' ||
            l_overview.column_list(i).tasks(j).attachment_count ||
            ' (' ||
            NVL(l_overview.column_list(i).tasks(j).attachment_types, '') ||
            ')'
          );
        END IF;

        -- Labels
        IF l_overview.column_list(i).tasks(j).labels_text IS NOT NULL THEN
          DBMS_OUTPUT.put_line(
            '      Labels: ' ||
            l_overview.column_list(i).tasks(j).labels_text
          );
        END IF;

        -- Git info (commit / PR)
        v_git_info := NULL;

        IF l_overview.column_list(i).tasks(j).has_commit = 'Y' THEN
          v_git_info := 'commit';
        END IF;

        IF l_overview.column_list(i).tasks(j).has_pr = 'Y' THEN
          v_git_info := v_git_info ||
                        CASE WHEN v_git_info IS NULL THEN '' ELSE ', ' END ||
                        'PR';
        END IF;

        IF v_git_info IS NOT NULL THEN
          DBMS_OUTPUT.put_line('      Git: ' || v_git_info);
        END IF;

      END LOOP;
    END IF;
  END LOOP;
END;
/
