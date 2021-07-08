-- Riddler classic puzzle
-- https://fivethirtyeight.com/features/can-you-find-an-extra-perfect-square/

-- here is my original creation.
-- I forgot that SQL Server doesn't materialize CTEs unless you make it.
-- see performance of non materialized vs materialized below. 


--  with rowSource
--    as (SELECT 1 as ordinal
--	     UNION ALL 
--		SELECT ordinal+1 FROM rowSource 
--		 WHERE ordinal+1 <= 25000),
--	   squares
--    as (Select ordinal, 
--	           ordinal*ordinal as [square], 
--	           CASE WHEN ordinal > 3 then ordinal*ordinal/10 END  as [LastDigitRemoved],
--	           CASE WHEN ordinal >= 10 then ordinal*ordinal/100 END  as [LastTwoDigitsRemoved]
--	      from rowSource),
--       detailResults
--    as (select a.ordinal,
--	           a.[square],
--               b.[square] as oneDigitRemovedSquare,
--        	   c.[square] as twoDigitsRemovedSquare
--          from squares a
--               left outer join squares b on (a.LastDigitRemoved = b.[square])
--               left outer join squares c on (a.LastTwoDigitsRemoved = c.[square]))
--select count(*) as NumberofSquares,
--	   count(oneDigitRemovedSquare) as OneDigitRemovedAlsoSquareCount,
--	   count(twoDigitsRemovedSquare) as TwoDigitsRemovedAlsoSquareCount,
--	   count(case when oneDigitRemovedSquare is not null and twoDigitsRemovedSquare is not null then 'x' end) as BothDigitsRemovedAlsoSquareCount,
--	   max(case when oneDigitRemovedSquare is not null and twoDigitsRemovedSquare is not null then [square] end) as largestNumberWhereBothareSquares
--  from detailResults      
--option (MAXRECURSION 30000)
--;

-- Try with materialized temp table
--drop table #squaresTemp;

  with rowSource
    as (SELECT 1 as ordinal
	     UNION ALL 
		SELECT ordinal+1 FROM rowSource 
		 WHERE ordinal+1 <= 46340),
	   squares
    as (Select ordinal, 
	           ordinal*ordinal as [square], 
	           CASE WHEN ordinal > 3 then ordinal*ordinal/10 END  as [LastDigitRemoved],
	           CASE WHEN ordinal >= 10 then ordinal*ordinal/100 END  as [LastTwoDigitsRemoved]
	      from rowSource)
select * 
  into #squaresTemp
  from squares
option (MAXRECURSION 0);

  with detailResults
    as (select a.ordinal,
	           a.[square],
               b.[square] as oneDigitRemovedSquare,
        	   c.[square] as twoDigitsRemovedSquare
          from #squaresTemp a
               left outer join #squaresTemp b on (a.LastDigitRemoved = b.[square])
               left outer join #squaresTemp c on (a.LastTwoDigitsRemoved = c.[square]))
select count(*) as NumberofSquares,
	   count(oneDigitRemovedSquare) as OneDigitRemovedAlsoSquareCount,
	   count(twoDigitsRemovedSquare) as TwoDigitsRemovedAlsoSquareCount,
	   count(case when oneDigitRemovedSquare is not null and twoDigitsRemovedSquare is not null then 'x' end) as BothDigitsRemovedAlsoSquareCount,
	   max(case when oneDigitRemovedSquare is not null and twoDigitsRemovedSquare is not null then [square] end) as largestNumberWhereBothareSquares
  from detailResults      ;

-- CTE approach
--    20000 squares - 5min 21 sec
--    25000 squares - 6min 44 sec
-- materialized temp table approach
--    30000 squares - 5 sec!


--select cast(40000*40000 as int)  --works
--select cast(50000*50000 as int)  -- errors out
--select cast(2147483647 as int)  -- max size for INT
--select floor(sqrt(2147483647)) --- max ordinal is 46340
