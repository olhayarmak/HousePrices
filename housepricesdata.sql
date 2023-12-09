SELECT * 
into #zz
FROM
(
SELECT
*,
(cast([column3] as decimal(30,0))-AVG(cast([column3] as decimal(30,0))) Over())/STDEV(cast([column3] as decimal(30,0))) Over() as Zscore
from [master].[dbo].[pp-monthly-update-new-version.txt]) as z_table
--

select * 

into #pricesdata
from #zz
WHERE Zscore not in 
       (
       select  top 1 percent [Zscore]
       from    zz
       order by 
               [Zscore] asc
       )


	   and  Zscore not in 
       (
       select  top 1 percent [Zscore]
       from    zz
       order by 
               [Zscore] desc
       )

	   order by cast([column3] as decimal(30,0)) desc




/*rename columns, cast as date, re-classify data based on guide provided @ 
https://www.gov.uk/guidance/about-the-price-paid-data#explanations-of-column-headers-in-the-ppd*/

SELECT  [column2] as "Transaction ID"
      ,[column3] as "Sale Price"
      ,cast([column4] as date) as "Date"
      ,[column5] as "PostCode"
      ,case when [column6] = 'D' then 'Detached'
	   when [column6] = 'S' then 'Semi-Detached'
	   when [column6] = 'T' then 'Terraced'
	   when [column6] = 'F' then 'Flat/Maisonette'
	   when [column6] = 'O' then 'Other'
	   end as "Property Type"
      ,case when [column7] = 'Y' then 'New Build'
	  when [column7] = 'N' then 'Old Build'
	  end as "Old/New Build"
      ,case when [column8] = 'F' then 'Freehold'
	  when [column8] = 'L' then 'Leasehold' 
	  end as "Duration"
      ,[column9] as "PAON"
      ,[column10] as "SAON"
      ,[column11] as "Street"
      ,[column12] as "Location"
      ,[column13] as "Town/City"
      ,[column14] as "District"
      ,[column15] as "County"
      ,[column16] as "PPD Category Type"
	  into #prep
  FROM #pricesdata

  
  /*identify lowest/highest by county, property type & duration*/
  select distinct
  row_number() over (partition by a.County, a.Duration order by a.[Sale Price] asc)  as "Lowest by County & Duration"
  ,row_number() over (partition by a.County, a.Duration order by a.[Sale Price] desc)  as "Highest by County & Duration"
  ,row_number() over (partition by a.County, a.[Property Type] order by a.[Sale Price] asc)  as "Lowest by County & Property Type"
  ,row_number() over (partition by a.County, a.[Property Type] order by a.[Sale Price] desc)  as "Highest by County & Property Type"
  ,row_number() over (partition by a.County order by a.[Sale Price] desc)  as "Highest by County"
  ,row_number() over (partition by a.County order by a.[Sale Price] asc)  as "Lowest by County"
  ,a.County
  ,a.Duration
  ,a.[Property Type]
  ,a.[Sale Price]
  into #priceanalysis
  from #prep a



  select 
  a.County,
  a.[Transaction ID],
  a.Date,
  a.District,
  a.Duration,
  a.Location,
  a.[Old/New Build],
  a.PAON,
  a.PostCode,
  a.[PPD Category Type],
  a.[Property Type],
  a.[Sale Price],
  a.SAON,
  a.Street,
  a.[Town/City],
  b.[Sale Price] as "Lowest Sale Price For County",
  c.[Sale Price] as "Highest Sale Price For County",
  d.[Sale Price] as "Lowest Sale Price by County & Duration",
  e.[Sale Price] as "Highest Sale Price by County & Duration",
  f.[Sale Price] as "Lowest Sale Price by County & Property Type",
  g.[Sale Price] as "Highest Sale Price by County & Property Type"


  from #prep a
  left outer join #priceanalysis b
  on a.County = b.County
  and b.[Lowest by County] = 1

  left outer join #priceanalysis c
  on a.County = c.County
  and c.[Highest by County] = 1

  left outer join #priceanalysis d
  on a.County = d.County
  and a.Duration = d.Duration
  and d.[Lowest by County & Duration] = 1

  left outer join #priceanalysis e
  on a.County = e.County
  and a.Duration = e.Duration
  and e.[Highest by County & Duration] = 1

  left outer join #priceanalysis f
  on a.County = f.County
  and a.[Property Type] = f.[Property Type]
  and f.[Lowest by County & Property Type] = 1

    left outer join #priceanalysis g
  on a.County = g.County
  and a.[Property Type] = g.[Property Type]
  and g.[Highest by County & Property Type] = 1


  order by a.[Sale Price] asc

  drop table #prep
  drop table #priceanalysis
  drop table #pricesdata
  drop table #zz