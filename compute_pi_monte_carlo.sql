DROP table points;

CREATE TABLE points
(x NUMBER,
 y NUMBER,
 point_inside_unit_circle VARCHAR2(1));
 
INSERT INTO points (x,y)
SELECT dbms_random.value(-1,1) AS x,
       dbms_random.value(-1,1) AS y
  FROM all_source;

UPDATE points
   SET point_inside_unit_circle = CASE 
                                    WHEN power(x,2) + power(y,2) <= 1 THEN 'Y'
                                    ELSE 'N'
                                  END;  

SELECT pi_approx, 
       pi_arccos, 
       100 * abs(pi_approx - pi_arccos) / pi_arccos AS error_pct
  FROM (SELECT 4 * included_points / all_points AS pi_approx,
               acos (-1) AS pi_arccos
          FROM (SELECT count(CASE WHEN point_inside_unit_circle='Y' THEN 'x' END) AS included_points,
                       count(*) AS all_points
                  FROM points
               )
       );

