--setup tables
drop TABLE test_Results PURGE;
CREATE TABLE test_Results 
  (number_of_seats NUMBER, 
   result_text VARCHAR2(32), 
   last_guy_assigned_seat NUMBER, 
   last_guy_actual_seat NUMBER);
DROP TABLE seats PURGE;
CREATE TABLE seats
  (seat_id INTEGER NOT NULL,   -- can we get rid of this column??
   planned_person INTEGER NOT NULL,
   actual_person INTEGER);
ALTER TABLE seats 
ADD CONSTRAINT seats_pk
PRIMARY key (seat_id);
ALTER TABLE seats 
ADD CONSTRAINT seats_planned_uk
UNIQUE (planned_person);
ALTER TABLE seats 
ADD CONSTRAINT seats_actual_uk
UNIQUE (actual_person);
ALTER TABLE seats 
ADD CONSTRAINT seats_planned_ck
CHECK (planned_person > 0 AND planned_person < 101);
ALTER TABLE seats 
ADD CONSTRAINT seats_actual_ck
CHECK (actual_person > 0 AND actual_person < 101);

--
CREATE OR REPLACE PROCEDURE load_seats IS
  lc_number_of_seats CONSTANT INTEGER := 100;
  lv_random_offset   INTEGER;
  lv_temp_person_id  NUMBER;
  lv_assigned_seat   NUMBER;
  lv_last_avail_seat NUMBER;
BEGIN
  -- wipe and load seats table
  lv_random_offset := dbms_random.value(low => 0, HIGH=>lc_number_of_seats-1);
  
  EXECUTE IMMEDIATE ('TRUNCATE TABLE seats');
  
  INSERT INTO seats (seat_id, planned_person)
  SELECT ROWNUM, 1+ MOD(ROWNUM + lv_random_offset, lc_number_of_seats)
  FROM all_objects
  WHERE ROWNUM < lc_number_of_seats + 1;
  
  -- first guy picks a random seat
  UPDATE seats
     SET actual_person = 1
   WHERE seat_id = trunc(dbms_random.value(low => 1, high => lc_number_of_seats + 1));

  --loop through guys 2 through 99
  FOR i IN 2 .. (lc_number_of_seats - 1) LOOP
    SELECT actual_person
      INTO lv_temp_person_id
      FROM seats
     WHERE planned_person = i;
  
    IF lv_temp_person_id IS NULL
    THEN
      -- unoccupied
      UPDATE seats SET actual_person = i WHERE planned_person = i;
    ELSE
      -- already taken.  Pick another.
      UPDATE seats
         SET actual_person = i
       WHERE seat_id = (SELECT seat_id
                          FROM (SELECT seat_id
                                  FROM seats
                                 WHERE actual_person IS NULL
                                 ORDER BY dbms_random.value)
                         WHERE rownum < 2);
    END IF;
  END LOOP;
  
  COMMIT;
  
  -- finished loading all but the last guy.  Lets see what is left.
  SELECT seat_id
    INTO lv_assigned_seat
    FROM seats
   WHERE planned_person = lc_number_of_seats;

  SELECT seat_id
    INTO lv_last_avail_seat
    FROM seats
   WHERE actual_person IS NULL; --should be exactly one row. if it isn't we'll get a runtime error here.

  IF lv_assigned_seat = lv_last_avail_seat
  THEN
    dbms_output.put_line('same!');
    INSERT INTO test_Results (number_of_seats, result_text, last_guy_assigned_seat)
    VALUES (lc_number_of_seats, 'same', lv_assigned_seat);
    
  ELSE
    dbms_output.put_line('differrent! last guy assigned: ' ||
                         to_char(lv_assigned_seat) ||
                         '  last guy actual: ' ||
                         to_char(lv_last_avail_seat));
    INSERT INTO test_Results (number_of_seats, result_text, last_guy_assigned_seat, last_guy_actual_seat)
    VALUES (lc_number_of_seats, 'different', lv_assigned_seat, lv_last_avail_seat);
                         
  END IF;
  COMMIT;

END;
/

-- single run  
BEGIN
  load_seats;
END;
/

-- take look at the table
SELECT seat_id, planned_person, actual_person, 
       CASE 
         WHEN actual_person IS NULL THEN 'last_seat'
         WHEN planned_person = actual_person THEN 'correct seat'
         ELSE 'incorrect seat'
       END AS result_test      
  FROM seats 
 ORDER BY seat_id;
 
-- now try a bunch of runs
BEGIN
  FOR j IN 1 .. 120 LOOP
    load_seats;
    UPDATE seats SET actual_person = NULL; 
    COMMIT;
  END LOOP;  
END;
/

-- how do our results look?
SELECT * FROM test_Results; 
SELECT result_text,COUNT(*) FROM test_results GROUP BY result_text;  


                
