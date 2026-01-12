DECLARE
  v_proj_key   app_project.proj_key%TYPE;
  v_task_id    task.id%TYPE;
  v_task_key   task.task_key%TYPE;
  v_link_count PLS_INTEGER;
BEGIN
  --------------------------------------------------------------------
  -- Kiválasztunk egy tetszõleges létezõ taskot, aminek van TASK_KEY-je
  --------------------------------------------------------------------
  SELECT p.proj_key, t.id, t.task_key
    INTO v_proj_key, v_task_id, v_task_key
    FROM app_project p
    JOIN task t ON t.project_id = p.id
   WHERE t.task_key IS NOT NULL
     AND ROWNUM = 1;

  DBMS_OUTPUT.put_line('Tesztelt task: ' || v_task_key ||
                       ' (proj_key=' || v_proj_key || ', id=' || v_task_id || ')');

  --------------------------------------------------------------------
  -- POZITÍV TESZT: létezõ task_key a git üzenetben
  --------------------------------------------------------------------
  v_link_count := git_integration_pkg.process_git_message_fnc(
      p_proj_key       => v_proj_key,
      p_event_type     => 'COMMIT',
      p_message        => 'Fix something in ' || v_task_key || ' and more text',
      p_provider       => 'GITHUB',
      p_repo_full_name => 'trunkpeter/pma-demo',
      p_commit_sha     => substr('OK_' || TO_CHAR(SYSTIMESTAMP,'YYYYMMDDHH24MISSFF'),1,40),
      p_author_email   => 'dev@example.com',
      p_committed_at   => SYSDATE,
      p_pr_number      => NULL,
      p_state          => NULL,
      p_created_at     => NULL,
      p_merged_at      => NULL
  );

  DBMS_OUTPUT.put_line('Pozitiv teszt: Visszatert link_count = ' || v_link_count);

  --------------------------------------------------------------------
  -- 3) NEGATÍV TESZT: nem létezõ task_key a git üzenetben
  --    (ugyanaz a proj_key, de "biztosan" nem létezõ sorszám)
  --------------------------------------------------------------------
  BEGIN
    v_link_count := git_integration_pkg.process_git_message_fnc(
      p_proj_key       => v_proj_key,
      p_event_type     => 'COMMIT',
      p_message        => 'Bad ref to ' || v_proj_key || '-999999 (nem letezo task)',
      p_provider       => 'GITHUB',
      p_repo_full_name => 'trunkpeter/pma-demo',
      p_commit_sha     => substr('BAD_' || TO_CHAR(SYSTIMESTAMP,'YYYYMMDDHH24MISSFF'),1,40),
      p_author_email   => 'dev@example.com',
      p_committed_at   => SYSDATE,
      p_pr_number      => NULL,
      p_state          => NULL,
      p_created_at     => NULL,
      p_merged_at      => NULL
    );

    DBMS_OUTPUT.put_line(
      'Negativ teszt: HIBA: NEM vart siker, link_count = ' || v_link_count
    );
  EXCEPTION
    WHEN pkg_exceptions.git_message_no_task_key THEN
      DBMS_OUTPUT.put_line(
        'Negativ teszt: Elkapott pkg_exceptions.git_message_no_task_key (vart viselkedes, eszrevette hogy nincs ilyen).'
      );
    WHEN OTHERS THEN
      DBMS_OUTPUT.put_line(
        'Negativ teszt: VARATLAN hiba: ' || SQLCODE || ' - ' || SQLERRM
      );
  END;
END;
/
