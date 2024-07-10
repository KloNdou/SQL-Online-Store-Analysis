/* Checking my data to see if there is more cleaning needed, apart from what I did in excel */

SELECT *
FROM Countrydata

Select *
From [Funnel data TLB_Mallorca]

-- Checking Decimal Places in Countrydata
-- Update Engagement_rate, Average_engagement_time, Total_revenue, Tax_amount to have 2, 1, 1, 1 decimal places respectively

Update Countrydata
	SET
		Engagement_rate=ROUND(Engagement_rate,2),
		Average_engagement_time = Round(Average_engagement_time,1),
		Total_revenue = ROUND(Total_revenue,1),
		Tax_amount = ROUND(Tax_amount,1);


-- Similar Update for RegionsPerformanceGoogleAds table (round Cost, Conv_value, Cost_conv to 1 decimal place)

Update RegionsPerformanceGoogleAds
	SET
		Cost=Round(Cost,1),
		Conv_value=ROUND(Conv_value,1),
		Cost_conv=ROUND(Cost_conv,1)

-- Update CountryRegionData table (round Engagement_rate, Average_engagement_time to 1 decimal place, Purchase_revenue to 0 decimal places)
Update CountryRegionData
	SET 
		Engagement_rate= ROUND(Engagement_rate,1),
		Average_engagement_time= ROUND(Average_engagement_time,1),
		Purchase_revenue=ROUND(Purchase_revenue,0)

/* for a temporary change I could use this too: */

Select Cast (Completion_rate AS INT)
From [Funnel data TLB_Mallorca]

/*Checking for null values in different tables */

Select *
From Countrydata Where 
Shipping_amount is NULL
OR Country is NULL
OR Users is NULL
OR New_users is NUll
OR Engagement_rate is NULL
OR Average_engagement_time IS NULL
OR Event_count IS NULL
OR Total_revenue IS NULL
OR Add_to_carts IS NULL
OR Checkouts IS NULL
OR PURCHASES IS NULL

Select *
	From [Funnel data TLB_Mallorca]
Where Step is NUll
	OR Device_category IS NULL
	OR Active_users IS NULL
	OR Completion_rate IS NULL
	OR Abandonments IS NULL
	OR Abandonment_rate IS NULL

-- Handling missing Values in Funnel data table 
-- In the second table I have null values which I intend to clean

Update [Funnel data TLB_Mallorca]
	Set Completion_rate = COALESCE(Completion_rate, '') 

Update [Funnel data TLB_Mallorca]
	Set Abandonments = COALESCE (Abandonments, 0)

ALTER TABLE [Funnel data TLB_Mallorca]
	ADD CONSTRAINT DF_Completion_rate DEFAULT '' FOR Completion_rate;

UPDATE [Funnel data TLB_Mallorca]
	SET Abandonment_rate = '0'
WHERE Abandonment_rate IS NULL;

/* Since in our case zero values would affect the analysis will completely ignore the zero values with this query: */

SELECT *
	FROM [Funnel data TLB_Mallorca]
WHERE 
	Completion_rate <> 0
	Or Abandonment_rate <> 0
	OR Abandonments <> 0

DELETE FROM [Funnel data TLB_Mallorca]
	WHERE Completion_rate = 0;


-- This query identifies potential duplicate rows in the Countrydata table.
-- It assigns a row number to each row within a group defined by Country, VisitDate, Users, New_users, and Engagement_rate.
-- Rows with a rownum greater than 1 are considered potential duplicates because they share the same values in these columns but have different VisitDate.

SELECT *
FROM Countrydata

SELECT DISTINCT *
FROM Countrydata

-- This query uses a Common Table Expression (CTE) to find duplicate rows in the CountryData table.
-- The CTE assigns a row number to each row within a group defined by several columns (Country, VisitDate, Users, New_users, Engagement_rate, Total_revenue, Add_to_carts, Checkouts, Purchases).
-- Rows ordered by VisitDate and having a Row_num greater than 1 are considered duplicates.

SELECT *,
       ROW_NUMBER() OVER (PARTITION BY Country, VisitDate, Users, New_users, Engagement_rate ORDER BY VisitDate) AS rownum
FROM Countrydata;



WITH Duplicate_cte AS
( 
    SELECT *,
           ROW_NUMBER() OVER (
               PARTITION BY Country, VisitDate, Users, New_users, Engagement_rate, Total_revenue, Add_to_carts, Checkouts, Purchases
               ORDER BY VisitDate
           ) AS Row_num
    FROM CountryData
)
SELECT *
FROM Duplicate_cte
WHERE Row_num > 1;


 --This query identifies potential duplicate entries for new users within the Countrydata table.
-- It groups rows by Country, VisitDate, and New_users.
-- The COUNT(*) function calculates the number of rows within each group.
-- The HAVING clause filters the results to include only groups with a COUNT(*) greater than 1.
-- This indicates that there might be multiple entries for new users on the same day in a specific country, potentially due to data inconsistencies.

SELECT Country, VisitDate, New_users, COUNT(*)
FROM Countrydata
GROUP BY Country, VisitDate, New_users
HAVING COUNT(*) > 1;


/* 
  Since I don't have actual duplicates in the data, 
  I'm simulating duplicates for demonstration purposes of duplicate removal techniques.
*/

-- Insert TOP 50 rows from Countrydata into itself (for demonstration)
Insert INTO Countrydata
Select TOP 50 *
From Countrydata;  

-- This query would typically be used to identify existing duplicates, 
-- but here it's selecting all rows after the data is artificially duplicated.
Select *
From Countrydata
Group By Country, VisitDate, Users, New_users, Engagement_rate, Average_engagement_time, Event_count, Total_revenue, Add_to_carts, Checkouts, Purchases, Shipping_amount, Tax_amount
Having Count(*)>1;


-- This section uses a Common Table Expression (CTE) to identify and remove duplicate rows in the CountryData table.

WITH CTE(Country, VisitDate, Users, New_users, Engagement_rate, Average_engagement_time, Event_count, Total_revenue, Add_to_carts, Checkouts, Purchases, Shipping_amount, Tax_amount, DuplicateCount)
AS (
  SELECT Country,
         VisitDate,
         Users,
         New_users,
         Engagement_rate,
         Average_engagement_time,
         Event_count,
         Total_revenue,
         Add_to_carts,
         Checkouts,
         Purchases,
         Shipping_amount,
         Tax_amount,
         ROW_NUMBER() OVER (PARTITION BY Country, VisitDate ORDER BY VisitDate DESC) AS DuplicateCount
  FROM CountryData
)
DELETE FROM CTE
WHERE DuplicateCount > 1;


/* 
  Checking for and handling data with excessive decimal places.
*/

-- View all data in the Funnel data TLB_Mallorca table (for reference).

Select * from [Funnel data TLB_Mallorca];


-- Update the Completion_rate column in the Funnel data TLB_Mallorca table.
-- Round the values to 2 decimal places for improved readability and potential storage efficiency.

Update [Funnel data TLB_Mallorca]
Set Completion_rate = ROUND(Completion_rate,2);


-- Update the Abandonment_rate column in the Funnel data TLB_Mallorca table.
-- Round the values to 2 decimal places for consistency and potential storage efficiency.

Update [Funnel data TLB_Mallorca]
Set Abandonment_rate = ROUND(Abandonment_rate,2);


-- Update the Item_revenue column in the Purchasedata table.
-- Round the values to 1 decimal place for improved readability and potential storage efficiency.

Update Purchasedata
Set Item_revenue = ROUND(Item_revenue,1);




-- Add a new column named Item_name_new to the Purchase_data table. 
-- This new column will be of type VARCHAR(255), allowing it to store variable-length character strings up to 255 characters long.

ALTER TABLE Purchase_data
ADD Item_name_new VARCHAR(255);


-- This UPDATE statement populates the newly created Item_name_new column to avoid having the same product in different sizes as we are not interested in that part in our analysis.
-- It uses a CASE statement to extract the part of the existing Item_name column before the first hyphen ('-').
-- If there is no hyphen in the item name, the entire original name is copied to the new column.

UPDATE Purchase_data
SET Item_name_new = 
  CASE 
    WHEN CHARINDEX('-', Item_name) > 0  -- Check if there's a hyphen in the name
      THEN SUBSTRING(Item_name, 1, CHARINDEX('-', Item_name) - 1)  -- Extract everything before the hyphen
    ELSE Item_name  -- If no hyphen, copy the entire name
  END;

-- This ALTER TABLE statement removes the original Item_name column from the Purchase_data table.
-- It's assumed that after populating the Item_name_new column with the desired data, the original Item_name column is no longer needed.

Alter TABLE Purchase_data
Drop Column Item_name;


