DECLARE
   lv_true    BOOLEAN := TRUE;
   lv_false   BOOLEAN := FALSE;
   lv_unknown BOOLEAN := NULL;

   FUNCTION p(i_result IN BOOLEAN) RETURN VARCHAR2 IS
      lv_result VARCHAR2(8);
   BEGIN
      CASE
         WHEN (i_result IS NULL) THEN
            lv_result := 'NULL';
         WHEN (i_result) THEN
            lv_result := 'TRUE';
         WHEN (NOT i_result) THEN
            lv_result := 'FALSE';
         ELSE
            lv_result := 'wtf???';
      END CASE;
      RETURN lv_result;
   END p;

BEGIN
   dbms_output.put_line('Three value truth table for AND');
   dbms_output.put_line('true AND false is: ' || p(lv_true AND lv_false));
   dbms_output.put_line('false AND false is: ' || p(lv_false AND lv_false));
   dbms_output.put_line('true AND true is: ' || p(lv_true AND lv_true));
   dbms_output.put_line('true AND NULL is: ' || p(lv_true AND lv_unknown));
   dbms_output.put_line('false AND NULL is: ' || p(lv_false AND lv_unknown));
   dbms_output.put_line('NULL AND NULL is: ' || p(lv_unknown AND lv_unknown));
   dbms_output.put_line('');
   dbms_output.put_line('Three value truth table for OR');
   dbms_output.put_line('true OR false is: ' || p(lv_true OR lv_false));
   dbms_output.put_line('false OR false is: ' || p(lv_false OR lv_false));
   dbms_output.put_line('true OR true is: ' || p(lv_true OR lv_true));
   dbms_output.put_line('true OR NULL is: ' || p(lv_true OR lv_unknown));
   dbms_output.put_line('false OR NULL is: ' || p(lv_false OR lv_unknown));
   dbms_output.put_line('NULL OR NULL is: ' || p(lv_unknown OR lv_unknown));
   dbms_output.put_line('');
   dbms_output.put_line('Three value truth table for NOT');
   dbms_output.put_line('NOT true is: ' || p(NOT lv_true));
   dbms_output.put_line('NOT false is: ' || p(NOT lv_false));
   dbms_output.put_line('NOT NULL is: ' || p(NOT lv_unknown));
   dbms_output.put_line('');
   dbms_output.put_line('equals, not equals, and NULL');
   dbms_output.put_line('NULL = 0 is: ' || p(NULL = 0));
   dbms_output.put_line(q'{NULL = '' is: }' || p(NULL = ''));
   dbms_output.put_line('NULL = NULL is: ' || p(NULL = NULL));
   dbms_output.put_line('NULL is not null is: ' || p(NULL is NOT NULL));
   dbms_output.put_line('NULL is null is: ' || p(NULL IS NULL));
END;
/

-- in SQL, you get a row if the WHERE evaluates to TRUE.  If it evaluates to FALSE, or NULL, no row for you!
SELECT * FROM dual 
 WHERE 1 = NULL;  --null
 
SELECT * FROM dual 
 WHERE 1 = 0;  --false

SELECT * FROM dual 
 WHERE 1 = 1;  --true
 
 
