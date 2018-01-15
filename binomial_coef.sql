SET linesize 110 pagesize 80 numwidth 17
VARIABLE upper_limit NUMBER
EXEC :upper_limit := 130   

DROP TABLE binomial_coefficient CASCADE constraints PURGE;

CREATE TABLE binomial_coefficient
  (n   INTEGER,
   r   INTEGER,
   c1  NUMBER,
   c2  NUMBER,
   c3  NUMBER,
   c4  NUMBER,
   c5  NUMBER)
PCTFREE 70;

INSERT /*+ append */ 
  INTO binomial_coefficient (n,r)
  WITH numbers AS 
   (SELECT LEVEL-1 AS x FROM dual CONNECT BY LEVEL <= :upper_limit + 1)  
SELECT a.x AS n, b.x AS r
  FROM numbers a, numbers b
 WHERE b.x <= a.x
   AND a.x > 0;    

CREATE OR REPLACE FUNCTION factorial
 (n IN integer)
RETURN INTEGER AS
   local_var integer;
BEGIN
   IF (n < 0 OR FLOOR(n) <> n OR n IS NULL) THEN
     raise_application_error(-20001,'Can only compute factorial of positive intergers.');
   END IF;
   CASE n 
     WHEN 0 THEN local_var := 1;
     WHEN 1 THEN local_var := 1;
     WHEN 2 THEN local_var := 2;
     WHEN 3 THEN local_var := 6;
     WHEN 4 THEN local_var := 24;
     ELSE local_var := n * factorial(n-1);
   END CASE;  
   RETURN(local_var);
EXCEPTION
   WHEN VALUE_ERROR THEN RETURN(to_number(NULL));  
END factorial;
/

CREATE OR REPLACE FUNCTION choose1
 (n IN integer, r IN INTEGER)
RETURN INTEGER AS
   local_var integer;
BEGIN
   IF (n < 1 OR FLOOR(n) <> n) THEN
     raise_application_error(-20001,'Can only compute choose where n is positive intergers.');
   END IF;
   IF (r < 0 OR FLOOR(r) <> r OR r > n) THEN
     raise_application_error(-20002,'Can only compute choose where r is positive interger less than or equal n.');
   END IF;
   --simplest implementation.  Just use the formula as-is.
   local_var := factorial(n)/(factorial(r)*factorial(n-r));

   RETURN(local_var);
END choose1;
/

CREATE OR REPLACE FUNCTION choose2
 (n IN integer, r IN INTEGER)
RETURN INTEGER AS
   local_var integer;
BEGIN
   IF (n < 1 OR FLOOR(n) <> n) THEN
     raise_application_error(-20001,'Can only compute choose where n is positive intergers.');
   END IF;
   IF (r < 0 OR FLOOR(r) <> r OR r > n) THEN
     raise_application_error(-20002,'Can only compute choose where r is positive interger less than or equal n.');
   END IF;
   --take care of a few trivial edge cases.  All other cases compute as before.
   CASE   
     WHEN (r=0 OR r=n) THEN local_var := 1;
     WHEN (r=1 OR r=n-1) THEN local_var := n;
     ELSE local_var := factorial(n)/(factorial(r)*factorial(n-r));
   END CASE;  

   RETURN(local_var);
END choose2;
/

CREATE OR REPLACE FUNCTION mult_range
 (i_lower IN INTEGER, i_upper IN INTEGER) 
RETURN INTEGER AS
   local_var  INTEGER := 1;
   local_temp INTEGER;
BEGIN
   IF NOT (i_lower > 0 AND i_upper > 0 AND floor(i_lower) = i_lower AND floor(i_upper) = i_upper AND i_lower <= i_upper) THEN
      raise_application_error(-20003, 'Invalid input.');
   END IF;

   local_temp := i_lower;
   LOOP
      local_var  := local_var * local_temp;
      local_temp := local_temp + 1;
      EXIT WHEN local_temp > i_upper;
   END LOOP;

   RETURN(local_var);
EXCEPTION
   WHEN VALUE_ERROR THEN RETURN(to_number(NULL));  
END mult_range;
/

CREATE OR REPLACE FUNCTION choose3
 (n IN integer, r IN INTEGER)
RETURN INTEGER AS
   local_var integer;
     
BEGIN
   IF (n < 1 OR FLOOR(n) <> n) THEN
     raise_application_error(-20001,'Can only compute choose where n is positive intergers.');
   END IF;
   IF (r < 0 OR FLOOR(r) <> r OR r > n) THEN
     raise_application_error(-20002,'Can only compute choose where r is positive interger less than or equal n.');
   END IF;
   -- factor out some large terms.  Allows us to compute n choose r for n>33 which we could not do before 
   -- as 34! is too large for NUMBER datatype. 
   CASE
     WHEN (r=0 OR r=n) THEN local_var := 1;
     WHEN (r=1 OR r=n-1) THEN local_var := n;
     ELSE local_var := mult_range(n-LEAST(r,n-r)+1,n)/factorial(LEAST(r,n-r));
   END CASE;  

   RETURN(local_var);
END choose3;
/

CREATE OR REPLACE FUNCTION log_add_range
 (i_lower IN INTEGER, i_upper IN INTEGER) 
RETURN NUMBER AS
   local_var  NUMBER := 0;
   local_temp INTEGER;
BEGIN
   IF NOT (i_lower > 0 AND i_upper > 0 AND floor(i_lower) = i_lower AND floor(i_upper) = i_upper AND i_lower <= i_upper) THEN
      raise_application_error(-20003, 'Invalid input.');
   END IF;

   local_temp := i_lower;
   LOOP
      local_var  := local_var + LN(local_temp);
      local_temp := local_temp + 1;
      EXIT WHEN local_temp > i_upper;
   END LOOP;

   RETURN(local_var);
END log_add_range;
/

CREATE OR REPLACE FUNCTION choose4
 (n IN integer, r IN INTEGER)
RETURN INTEGER AS
   local_var integer;
     
BEGIN
   IF (n < 1 OR FLOOR(n) <> n) THEN
     raise_application_error(-20001,'Can only compute choose where n is positive intergers.');
   END IF;
   IF (r < 0 OR FLOOR(r) <> r OR r > n) THEN
     raise_application_error(-20002,'Can only compute choose where r is positive interger less than or equal n.');
   END IF;
   -- Even after eliminating similar terms, we still blow up the datatype when computing 50 choose 25.
   -- we could use some cleverness and eliminate more terms, but I suspect that would prove to be lots of
   -- work for a marginal gain in our ability to compute for large numbers.  
   -- Better to switch gears entirely and use logarithm in our algorithm.
   -- Add/subtract all logarithms together before using exp to get the final answer.  We want to keep 
   -- all arguments to operations to nearly similar size whenever possibile to retain precision.
   CASE
     WHEN (r=0 OR r=n) THEN local_var := 1;
     WHEN (r=1 OR r=n-1) THEN local_var := n;
     ELSE local_var := exp(log_add_range(n-LEAST(r,n-r)+1,n) - log_add_range(1,LEAST(r,n-r)));
   END CASE;  

   RETURN(local_var);
END choose4;
/

CREATE OR REPLACE FUNCTION choose5
 (n IN integer, r IN INTEGER)
RETURN INTEGER result_cache    --cache makes a HUGE difference in performance
AS
   local_var integer;
     
BEGIN
   IF (n < 1 OR FLOOR(n) <> n) THEN
     raise_application_error(-20001,'Can only compute choose where n is positive intergers.');
   END IF;
   IF (r < 0 OR FLOOR(r) <> r OR r > n) THEN
     raise_application_error(-20002,'Can only compute choose where r is positive interger less than or equal n.');
   END IF;
   -- Pascal's triangle leads us to a recursive solution.
   -- This is only possible due to the Oracle 11g function result cache feature. Without it, this 
   -- implementation would take an EXTREMELY long time to compute values where n > 30 or so.  After
   -- the cache is loaded, this method gives the best performance, range, and accuracy of all methods.  
   -- I found that this function caching concept is called "Memoization"
   -- http://en.wikipedia.org/wiki/Memoization
   
   -- However, if we have to load a cache, I think we might as well just pre-build a table with 
   -- the results.  A simple SQL lookup would be even faster!
   
   CASE
     WHEN (r=0 OR r=n) THEN local_var := 1;
     WHEN (r=1 OR r=n-1) THEN local_var := n;
     ELSE local_var := choose5(n-1,r-1) + choose5(n-1,r);
   END CASE;  

   RETURN(local_var);
END choose5;
/

exec dbms_monitor.session_trace_enable;
SET timing ON echo ON
UPDATE binomial_coefficient
   SET c1 = choose1(n,r);
UPDATE binomial_coefficient
   SET c2 = choose2(n,r);
UPDATE binomial_coefficient
   SET c3 = choose3(n,r);
UPDATE binomial_coefficient
   SET c4 = choose4(n,r);
UPDATE binomial_coefficient
   SET c5 = choose5(n,r);
COMMIT;
SET timing OFF echo OFF

SELECT n,r,c4,c5
  FROM binomial_coefficient
 WHERE c4 <> c5
    OR c4 IS NULL 
    OR c5 IS NULL
 ORDER BY n,r;

REM choose4 AND choose5 give identical answers UNTIL 123 CHOOSE 60
REM lets see which IS correct BY adding 122 CHOOSE 59 AND 122 CHOOSE 60
SET numwidth 40 
col LABEL FOR a15
col diff FOR a10
SELECT to_char(n) || ' choose ' || to_char(r) as label,
       c4, c5, to_char(c4-c5) as diff
  FROM binomial_coefficient
 WHERE (n=123 and r=60)
    OR (n=122 and r in (59, 60));

REM Our recursive solution gives THE correct answer AND our logarithim solution IS OFF BY just 1.
REM One part IN 7.3E+35 seems TO be a reasonable accuracy.

exec dbms_monitor.session_trace_disable;

