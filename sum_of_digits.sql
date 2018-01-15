create table tt1
( tens           number(1),
  ones           number(1),
  num_val        number(3),
  sum_of_digits  number(3))
/

insert into tt1
with i as (select level as i from dual connect by level <= 9),
     j as (select level-1  as j from dual connect by level <= 10)
select i.i as tens, 
       j.j as ones, 
       10 * i.i + j.j as num_val, 
       i.i+j.j as sum_of_digits
from i, j
/

--look at the data
SELECT * FROM tt1
/

-- what are the most common values when we add the two digits togather?
select sum_of_digits, occurances, 
       to_char(round(100*ratio_to_report(occurances) over (),2)) || '%' as percent_of_total
from (
  select SUM_OF_DIGITS,count(*) as occurances
  from tt1
  group by SUM_OF_DIGITS)
order by 1
/

-- I expect you could extend this to 3, 4, or more digits and we see that there is a spike at n * 5   
-- since each digit has an average value of 5.
