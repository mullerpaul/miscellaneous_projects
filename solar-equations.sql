drop table fractionalYear;

  with dayList
    as (select top(365) row_number() over (order by object_id) as dayID from sys.all_columns),
	   hourList
	as (select top(24) row_number() over (order by object_id) - 1 as hourID from sys.all_columns)
select dayID, hourID, 
       dateadd(day, dayID-1, dateadd(hour, hourID, '2021-Jan-01')) as theDateTime,
	   (2 * pi() / 365) * (dayID - 1 + ((hourID - 12) / 24.0)) as gamma,
	   Cast(0 as float) as eqtime,   --to update later
	   Cast(0 as float) as decl      --to update later
  into fractionalYear -- create fractionalYear table
  from dayList
       cross join hourList
 order by 1,2
;

update fractionalYear
   set eqtime = 229.18 * 
                (0.000075 + 
				 0.001868 * cos(gamma) - 
				 0.032077 * sin(gamma) - 
				 0.014615 * cos(2 * gamma) -
				 0.040849 * sin(2 * gamma)
	          0.399912 * cos(gamma) + 
			  0.070257 * sin(gamma) - 
			  0.006758 * cos(2 * gamma) + 
			  0.000907 * sin(2 * gamma) - 