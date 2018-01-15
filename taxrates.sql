drop table tax_bracket cascade constraints purge;
drop table tax_by_income cascade constraints purge;

CREATE TABLE tax_bracket
 (low_bound      NUMBER(9,2),
  high_bound     NUMBER(9,2),
  pct_rate       NUMBER);

CREATE TABLE tax_by_income
 (income         NUMBER(9,2),
  tax_owed       NUMBER(9,2),
  marginal_rate  NUMBER,
  effective_rate NUMBER);

INSERT INTO tax_bracket (low_bound, high_bound, pct_rate)
VALUES (0, 16699.99, 10);
INSERT INTO tax_bracket (low_bound, high_bound, pct_rate)
VALUES (16700, 67899.99, 15);
INSERT INTO tax_bracket (low_bound, high_bound, pct_rate)
VALUES (67900, 137049.99, 25);
INSERT INTO tax_bracket (low_bound, high_bound, pct_rate)
VALUES (137050, 208849.99, 28);
INSERT INTO tax_bracket (low_bound, high_bound, pct_rate)
VALUES (208850, 372949.99, 33);
INSERT INTO tax_bracket (low_bound, high_bound, pct_rate)
VALUES (372950, 9999999.99, 35);

-- points from five thousand to five hundred thousand incremented by five thousand.
INSERT INTO tax_by_income (income)
SELECT rownum*5000 AS income 
  FROM dba_objects 
 WHERE rownum < 101;
-- points from five hundred thousand to two million incremented by twenty five thousand.
INSERT INTO tax_by_income (income)
SELECT 500000 + rownum*25000 AS income 
  FROM dba_objects 
 WHERE rownum < 61;

UPDATE tax_by_income a
   SET marginal_rate = (SELECT pct_rate 
                          FROM tax_bracket b
                         WHERE a.income BETWEEN b.low_bound AND b.high_bound);

-- can compute tax owed and the effective rate all in SQL with a neat join and summation.
UPDATE tax_by_income a
   SET (tax_owed, effective_rate) =
       (SELECT SUM((least(high_bound, a.income) - low_bound) * pct_rate / 100),
	           SUM((least(high_bound, a.income) - low_bound) * pct_rate / 100) * 100 / a.income
          FROM tax_bracket
         WHERE a.income >= low_bound);

