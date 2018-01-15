CREATE TABLE plays
 (play_id    NUMBER NOT NULL,
  flip_count NUMBER NOT NULL,
  winnings   NUMBER NOT NULL);

DECLARE
  lc_plays CONSTANT NUMBER := 200000;  -- just over 3 sec for 100K - 23sec for 600K
  lv_flip_counter NUMBER;

BEGIN
  FOR i IN 1 .. lc_plays LOOP
    lv_flip_counter := 0;
    LOOP
      lv_flip_counter := lv_flip_counter + 1;
      EXIT WHEN (dbms_random.value() >= .5);
    END LOOP;
  
    INSERT INTO plays (play_id, flip_count, winnings) VALUES (i, lv_flip_counter, 2 * lv_flip_counter);
  END LOOP;
  COMMIT;
END;
/

SELECT * FROM plays;

SELECT decile_id, COUNT(*) AS game_count, MIN(winnings), MAX(winnings)
  FROM (SELECT play_id, flip_count, winnings, NTILE(10) OVER (ORDER BY winnings) AS decile_id
          FROM plays)
 GROUP BY decile_id
 ORDER BY decile_id;

SELECT AVG(winnings), MEDIAN(winnings), MAX(winnings) FROM plays; 

-- TRUNCATE TABLE plays;
SELECT segment_name, blocks/128 AS mb FROM user_segments;


--- test random expression for 50/50 distribution  
SELECT y, COUNT(*) AS z, ratio_to_report (COUNT(*)) over () AS zz
  FROM (SELECT x, CASE WHEN x >= .5 THEN 1 ELSE 0 END AS y
          FROM (SELECT dbms_random.value() AS x
                  FROM all_objects))
 GROUP BY y;

