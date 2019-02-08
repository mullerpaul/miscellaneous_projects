
CREATE TABLE primes
(prime NUMBER NOT NULL,
 CONSTRAINT primes_pk PRIMARY KEY (prime))
/

CREATE TABLE factors
(product       NUMBER NOT NULL,
 prime_factor  NUMBER NOT NULL,
 CONSTRAINT factors_fk01 FOREIGN KEY (prime_factor) REFERENCES primes (prime)
)
/

INSERT INTO primes (prime) VALUES (2);
INSERT INTO primes (prime) VALUES (3);
INSERT INTO primes (prime) VALUES (5);
INSERT INTO primes (prime) VALUES (7);
INSERT INTO primes (prime) VALUES (11);
INSERT INTO primes (prime) VALUES (13);
INSERT INTO primes (prime) VALUES (17);
INSERT INTO primes (prime) VALUES (19);
INSERT INTO primes (prime) VALUES (23);

INSERT INTO factors (product, prime_factor) VALUES (4, 2);
INSERT INTO factors (product, prime_factor) VALUES (4, 2);
INSERT INTO factors (product, prime_factor) VALUES (6, 2);
INSERT INTO factors (product, prime_factor) VALUES (6, 3);
INSERT INTO factors (product, prime_factor) VALUES (8, 2);
INSERT INTO factors (product, prime_factor) VALUES (8, 2);
INSERT INTO factors (product, prime_factor) VALUES (8, 2);
INSERT INTO factors (product, prime_factor) VALUES (9, 3);
INSERT INTO factors (product, prime_factor) VALUES (9, 3);

INSERT INTO factors (product, prime_factor) VALUES (10, 2);
INSERT INTO factors (product, prime_factor) VALUES (10, 5);
INSERT INTO factors (product, prime_factor) VALUES (12, 2);
INSERT INTO factors (product, prime_factor) VALUES (12, 2);
INSERT INTO factors (product, prime_factor) VALUES (12, 3);
INSERT INTO factors (product, prime_factor) VALUES (14, 2);
INSERT INTO factors (product, prime_factor) VALUES (14, 7);
INSERT INTO factors (product, prime_factor) VALUES (15, 3);
INSERT INTO factors (product, prime_factor) VALUES (15, 5);
INSERT INTO factors (product, prime_factor) VALUES (16, 2);
INSERT INTO factors (product, prime_factor) VALUES (16, 2);
INSERT INTO factors (product, prime_factor) VALUES (16, 2);
INSERT INTO factors (product, prime_factor) VALUES (16, 2);
INSERT INTO factors (product, prime_factor) VALUES (18, 2);
INSERT INTO factors (product, prime_factor) VALUES (18, 3);
INSERT INTO factors (product, prime_factor) VALUES (18, 3);

INSERT INTO factors (product, prime_factor) VALUES (20, 2);
INSERT INTO factors (product, prime_factor) VALUES (20, 2);
INSERT INTO factors (product, prime_factor) VALUES (20, 5);
INSERT INTO factors (product, prime_factor) VALUES (21, 3);
INSERT INTO factors (product, prime_factor) VALUES (21, 7);
INSERT INTO factors (product, prime_factor) VALUES (22, 2);
INSERT INTO factors (product, prime_factor) VALUES (22, 11);

COMMIT;

SET lines 100 pages 100
COL factors for a40
-- check for mistakes
-- this exp(sum(ln)) trick is a clever way to do a "product aggregate" in SQL
SELECT product, exp(sum(ln(prime_factor))) as product_of_factors
  FROM factors
 GROUP BY product
 ORDER BY 1
/

SELECT product, LISTAGG(TO_CHAR(prime_factor), ', ') WITHIN GROUP (ORDER BY prime_factor) AS factors
  FROM factors
 GROUP BY product 
 UNION ALL 
SELECT prime, TO_CHAR(prime) AS factors 
  FROM primes
 ORDER BY 1
/
