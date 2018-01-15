DROP TABLE tinkerbell PURGE;

CREATE TABLE tinkerbell
  (n NUMBER,
   x NUMBER,
   y NUMBER);

INSERT INTO tinkerbell (n)
SELECT ROWNUM AS n
FROM all_objects;   

UPDATE tinkerbell
   SET x=-0.72, y=-0.64 
 WHERE n=1;

COMMIT;

DECLARE
  lc_a       CONSTANT NUMBER := 0.9;
  lc_b       CONSTANT NUMBER := -0.6013;
  lc_c       CONSTANT NUMBER := 2;
  lc_d       CONSTANT NUMBER := 0.5;
  
  lv_n                NUMBER := 2;    --index
  lv_current_x        NUMBER;
  lv_current_y        NUMBER;
  lv_prev_x           NUMBER := -0.72;
  lv_prev_y           NUMBER := -0.64;
BEGIN
  LOOP
    lv_current_x := POWER(lv_prev_x, 2) - POWER(lv_prev_y, 2) + lc_a * lv_prev_x + lc_b * lv_prev_y;
    lv_current_y := 2 * lv_prev_x * lv_prev_y + lc_c * lv_prev_x + lc_d * lv_prev_y;

    UPDATE tinkerbell
       SET x = lv_current_x,
           y = lv_current_y
     WHERE n = lv_n;
    
    IF SQL%ROWCOUNT <> 1 THEN
      EXIT;
    END IF;
      
    IF MOD(lv_n,500) = 0 THEN
      COMMIT;
    END IF;
    
    lv_n := lv_n + 1;
    lv_prev_x := lv_current_x;
    lv_prev_y := lv_current_y;
  END LOOP;
  
  COMMIT;
END;
/

      
SELECT x,y FROM tinkerbell ORDER BY n;
         
