-- does benfords law work with rate data??
SELECT count(*), count(rate), count(distinct rate), min(Rate), max(rate), avg(rate), STDEV(rate)
  FROM ProcurementRate
;
-- data spans multiple orders of magnitude

-- bin by order of magnitude
with bins
  as (select rate, 
         case 
           when rate < 1 then 1
           when rate < 10 then 2
           when rate < 100 then 3
           when rate < 1000 then 4
           when rate < 10000 then 5
           when rate < 100000 then 6
		   else 7
         end as binID
      FROM ProcurementRate)
select binID, count(*) 
  from bins 
 group by binID
 order by 1;
 -- yep, many orders of magnitude

 -- how to get the first digit??
  with data 
    as (select 2.5 as x union all select 57.2 union all select 0.45 union all select 0.003 union all select 7245)
select x,
       log10(x) as log10x,
	   floor(log10(x)) as floorLog10x,
	   -1 * floor(log10(x)) as q,
	   power(10.000, -1 * floor(log10(x))) as r,  -- have to have 10.0000 instead of 10 or else power returns 0
	   x * power(10.000, -1 * floor(log10(x))) as s,
	   floor(x * power(10.000, -1 * floor(log10(x)))) as t  -- this works!
  from data 
  order by x;

-- check for benford distribution
with bins
  as (select rate, 
             floor(rate * power(10.000, -1 * floor(log10(rate)))) as firstDigit
        FROM ProcurementRate
       where rate > 0)  -- exclude rate = 0 since that causes runtime errors from log10
select firstDigit, count(*)
  from bins
group by firstDigit
 order by 1;

