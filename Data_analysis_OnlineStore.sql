

--The database we will explore and analyse today contains many tables. I will select 4 of them an create a view with them to do analysis.
--The tables are:

--CountryRegionData:

--(Country, Region, Users, New_users, 
--Average_engagement_time, Ecommerce_purchases, 

--Purchase_revenue, Add_to_carts, 
--Checkouts, Quantity)


--Funnel data TLB_Mallorca:

--(Step, Device_category, Active_users, 
--Completion_rate, Abandoments, 
--Abandonment_rate)


--GoogleAdsData:

--(Session_Google_Ads_campaign, Date, 
--Users, Sessions, Engaged_sessions, 

--Average_engagement_time_per_session,
--Engaged_sessions_per_user, 

--Events_per_session, Engagement_rate, 
--Conversions, Event_count, Total_revenue)


--SessionSourceData:

--(Session_source_medium, Date, Users, 
--Sessions, Engaged_sessions, 

--Average_engagement_time_per_session, 
--Engaged_sessions_per_user, Events_per_session,

--Engagement_rate, Event_count,
--Conversions, Conversions)


--Starting the analysis with the summary of the main KPI-s and overview of the past year 
-- Our average order value shows that usually the buyers are very often to buy accessories and maintenance products with the shoes. 
-- We know that we made an improvement in how the product page suggest products for upsell.

SELECT SUM(Purchase_revenue) AS Revenue, 
	SUM(Ecommerce_purchases) AS Sales,
	ROUND(AVG(Purchase_revenue), 2) AS Avg_Order_Value
FROM CountryRegionData
 

-- Data indicates that there is high variability in the number of users, new users, and revenue, while the sales data shows relatively low variability. 
-- User and revenue counts can fluctuate widely, while sales counts are more consistent over the observed period.

 SELECT
		ROUND(STDEV(Users), 1) AS Users_stdev,
		ROUND(AVG(Users), 1) AS Users_mean,
		ROUND(STDEV(New_users),1) AS new_users_stdev,
		ROUND(AVG(New_users),1) AS new_users_mean,
		ROUND(STDEV(Ecommerce_purchases),1) AS Sales_stdev,
		ROUND(AVG(Ecommerce_purchases),1) AS sales_mean,
		ROUND(STDEV(Purchase_revenue),1) AS Revenue_stdev,
	    ROUND(AVG(Purchase_revenue),1) AS revenue_mean
FROM CountryRegionData


-- Which were our top selling products during the list year?

/* Models nr 137,135,112,198 and 121 are the best seller products for the last year.
Majority of the sales come from the belts and shoe trees however since their price is very low and we are filtering by revenue they don't make it to the top 5 best selling products */

-- Suggested to the client to shift budget towards the best selling products as a way to maximize revenue as those products are also classics and their sales are not affected a lot by the seasonality.

Select TOP 5 Item_name_new AS Product,
	ROUND(Sum(Items_purchased),0) AS Sales, 
	ROUND(Sum(Item_revenue),0) AS Revenue,
	ROUND((SUM(Item_revenue)/Sum(Items_purchased)),1) AS AOV
From Purchase_data
Group BY Item_name_new
HAVING Sum(Item_revenue) > 0
Order by Revenue DESC, AOV DESC


-- For how many percent of recenue and sales is each product responsible?
-- This is a more detailed view through which we can understand how much is each product contributing in the sales volume and revenue.

-- Shoe trees is the product with the highest number of sales, near 9% of the sales volume but only 2% of the revenue comes from it.
-- Top 3 classic shoes are the 3 best selling products and the made to order model is the 3rd best selling product.

WITH TotalRevenue AS (
    SELECT SUM(Item_revenue) AS total_revenue
    FROM Purchase_data
),
TotalSales AS (
    SELECT SUM(Items_purchased) AS total_sales
    FROM Purchase_data
)
SELECT 
    Item_name_new AS Product,
    ROUND(SUM(Items_purchased), 0) AS Sales,
    ROUND(SUM(Item_revenue), 0) AS Revenue,
    ROUND((SUM(Item_revenue) / CAST(tr.total_revenue AS FLOAT)) * 100, 2) AS Revenue_Percentage,
    ROUND((SUM(Items_purchased) / CAST(ts.total_sales AS FLOAT)) * 100, 2) AS Sales_Percentage
FROM 
    Purchase_data,
    TotalRevenue tr,
    TotalSales ts
GROUP BY 
    Item_name_new, tr.total_revenue, ts.total_sales
HAVING 
    SUM(Item_revenue) > 0
ORDER BY 
    Revenue_Percentage DESC, Sales_Percentage DESC;


/*
The SHOE TREE are not the main products, however they have high sales volume as they are a shoe care product which people often add in their purchase.
We will check specifically for the shoe trees: revenue and sales volume and how much are they contributing in the totals.
*/


With Total_revenue AS
(Select SUM(Item_revenue) AS Total_revenue 
	From Purchase_data),
Total_Sales AS
	 (SELECT SUM(Items_purchased) AS Total_Sales
	  From Purchase_data)
Select ROUND(Sum(Items_purchased),1) AS Sales,
	   ROUND(Sum(Item_revenue), 0) AS Revenue,
	   ROUND(Sum((Item_revenue)/(tr.Total_revenue))*100,1) AS RevenuePercentage,
	   ROUND(Sum((Items_purchased)/CAST(ts.Total_Sales AS Float)) *100,1) AS SalesPercentage
From Purchase_data pd, Total_revenue tr, Total_Sales ts
Where Item_name_new Like '%Tree%'
Order BY 3 DESC, 4 DESC


-- We have more than 1 type of shoe tree and we need to know the total revenue percentage of each of them 
-- The shoe tree of the main collection has nearly as much sales colume as the whole other types of shoe trees altogether followed by the goya products.



WITH Total_Revenue AS (
    SELECT SUM(Item_revenue) AS total_revenue
    FROM Purchase_data
),
Total_Sales AS (
    SELECT SUM(Items_purchased) AS total_sales
    FROM Purchase_data
)
SELECT 
    pd.Item_name_new AS ItemName,
    ROUND(SUM(pd.Items_purchased), 0) AS Sales, 
    ROUND(SUM(pd.Item_revenue), 0) AS Revenue,
    ROUND((SUM(pd.Item_revenue) / CAST(tr.total_revenue AS FLOAT)) * 100, 1) AS Revenue_Percentage,
    ROUND((SUM(pd.Items_purchased) / CAST(ts.total_sales AS FLOAT)) * 100, 2) AS Sales_Percentage
FROM 
    Purchase_data pd, Total_Revenue tr, Total_Sales ts
WHERE 
    pd.Item_name_new LIKE '%TREE%'
GROUP BY 
    pd.Item_name_new, tr.total_revenue, ts.total_sales
HAVING 
    SUM(pd.Item_revenue) > 0
ORDER BY 
    Sales DESC;



-- The company sells in different countries, mostly focused in US, UK and Spain.
-- How much of the sales volume and revenue is coming from each of the countries?
-- Even though in total our products get sold in 92 countries, US is our biggest market which contributs for more than 50% of the sales and revenue.

WITH Total_Revenue AS (
    SELECT SUM(CAST(Purchase_revenue AS FLOAT)) AS Total_Revenue
    FROM CountryRegionData
),
Total_Sales AS (
    SELECT SUM(CAST(Ecommerce_purchases AS FLOAT)) AS Total_Sales
    FROM CountryRegionData
)
SELECT 
    C.Country,
    ROUND(SUM(C.Purchase_revenue), 0) AS Revenue,
    ROUND(SUM(C.Ecommerce_purchases), 0) AS Sales,
    ROUND(SUM(C.Purchase_revenue) / TR.Total_Revenue * 100, 2) AS Revenue_Percentage,
    ROUND(SUM(C.Ecommerce_purchases) / TS.Total_Sales * 100, 2) AS Sales_Percentage
FROM 
    CountryRegionData AS C
CROSS JOIN 
    Total_Revenue AS TR
CROSS JOIN 
    Total_Sales AS TS
GROUP BY 
    C.Country, TR.Total_Revenue, TS.Total_Sales
HAVING 
    SUM(C.Purchase_revenue) > 0
ORDER BY 
    5 DESC;


/* 
Our TOP 10 Countries are United States (below will find a more detailed overview for each of the states) 53.4% of the sales volume; 
Germany ~ 3.8%
United Kingdom 3.4%
Australia 3.3%
France 3%
*/

-- Even though the brand is well known in Spain and Spain is a much more bigger market we do have more sales and revenue in Hong Kong than in Spain.
-- Hong Kong is known as a business centre and would it makes sense to shift more advertising budget towards it as it seems to have a good potential.

WITH Total_Revenue AS (
    SELECT SUM(Purchase_revenue) AS Total_Revenue
    FROM CountryRegionData
),
Total_Sales AS (
    SELECT SUM(CAST((Ecommerce_purchases)AS Float)) AS Total_Sales
    FROM CountryRegionData
)
SELECT 
    Top 10 Country,
    ROUND(SUM(C.Purchase_revenue), 0) AS Revenue,
    ROUND(SUM(C.Ecommerce_purchases), 0) AS Sales,
    ROUND(SUM((C.Purchase_revenue) / (TR.Total_Revenue) * 100), 2) AS Revenue_Percentage,
	ROUND(SUM((C.Ecommerce_purchases) / (TS.Total_Sales) * 100), 2) AS Sales_Percentage
FROM 
    CountryRegionData AS C,
    Total_Revenue AS TR,
	Total_Sales as TS
GROUP BY 
    Country
HAVING 
    SUM(C.Purchase_revenue) > 0
ORDER BY 
    5 DESC;



-- We know from which countries we are the sales but need to know which regions/states exactly are the main contributors in the sales volume.
-- In the US highest selling volume came from California, New York, Texas, Florida, Virginia, Illinois and New Jersey as it results from the below query.


WITH Tot_Rev AS (
    SELECT SUM(CAST(Purchase_revenue AS FLOAT)) AS Total_Revenue
    FROM CountryRegionData
),
Tot_Sales AS (
    SELECT SUM(CAST(Ecommerce_Purchases AS FLOAT)) AS Total_Sales 
    FROM CountryRegionData 
)
SELECT 
    C.Region,
    ROUND(SUM(C.Purchase_revenue), 0) AS Revenue,
    ROUND(SUM(C.Ecommerce_purchases), 2) AS Sales,
    ROUND(SUM(C.Purchase_revenue) / TR.Total_Revenue * 100, 1) AS Revenue_Percentage,
    ROUND(SUM(C.Ecommerce_purchases) / TS.Total_Sales * 100, 2) AS Sales_Percentage
FROM 
    CountryRegionData AS C
    CROSS JOIN Tot_Rev AS TR
    CROSS JOIN Tot_Sales AS TS
WHERE 
    C.Region NOT LIKE '%not set%'
GROUP BY 
    C.Region, TR.Total_Revenue, TS.Total_Sales
HAVING 
    SUM(C.Purchase_revenue) > 0
ORDER BY 
    Revenue_Percentage DESC, Sales_Percentage DESC;



-- Main objective for the company is our ROAS (return on ad spent to be higher than 14X in order to be in the profit. 
--Our total ROAS is 49.2X and attributed to Google conversions are 19.5X. We already know there are discrepencies in between data from advertising platform and analytics.


SELECT 
    SUM(CAST(CRD.Purchase_revenue AS FLOAT)) AS Total_Revenue,
    SUM(CAST(RPG.Cost AS FLOAT)) AS Total_GoogleSpent,
    SUM(RPG.Conv_value) AS Total_GoogleRevenue,
	ROUND(SUM(CAST(CRD.Purchase_revenue AS FLOAT))/ SUM(CAST(RPG.Cost AS FLOAT)),1) AS Return_on_ad_spent,
	ROUND(SUM(RPG.Conv_value)/SUM(CAST(RPG.Cost AS FLOAT)),1) AS ROAS_Google_attributed
FROM 
    CountryRegionData CRD
LEFT JOIN 
    RegionsPerformanceGoogleAds RPG
ON 
    CRD.Region = RPG.Region_Matched;


-- The company requires to confront often the region data to see how well aligned is the total ROAS per region with the ROAS per Region based on Google ads distribution.
-- California has a much higher return on ad spent on 
SELECT 
    CRD.Region,
    SUM(CAST(CRD.Purchase_revenue AS FLOAT)) OVER (PARTITION BY CRD.Region) AS Total_Revenue,
    SUM(CAST(RPG.Cost AS FLOAT)) OVER (PARTITION BY CRD.Region) AS Total_GoogleSpent,
    SUM(RPG.Conv_value) OVER (PARTITION BY CRD.Region) AS Total_GoogleRevenue,
    FORMAT(SUM(CAST(CRD.Purchase_revenue AS FLOAT)) OVER (PARTITION BY CRD.Region) / 
        NULLIF(SUM(CAST(RPG.Cost AS FLOAT)) OVER (PARTITION BY CRD.Region), 0),'0.##') AS Return_on_ad_spent,
    FORMAT(SUM(RPG.Conv_value) OVER (PARTITION BY CRD.Region) / 
        NULLIF(SUM(CAST(RPG.Cost AS FLOAT)) OVER (PARTITION BY CRD.Region), 0),'0.##') AS ROAS_Google_attributed
FROM 
    CountryRegionData CRD
LEFT JOIN 
    RegionsPerformanceGoogleAds RPG
ON 
    CRD.Region = RPG.Region_Matched
WHERE CRD.Region != '(not set)'
ORDER BY 2 DESC,
    5 DESC




-- Comparing the above table with the regions listed in base of the revenue they bring to the Google ads spending we have in each of those regions 
-- States such as Illinois, Pennsylvania, Virginia, New Jersye have high ROAS which shows that an increase in advertising spent in these stats can affect the sales. 
-- We can test to increase the advertising budget in the states and regions with very high ROAS (return on ad spent) and analyze how much does this increase the overall revenue and ROAS.

SELECT 
    COALESCE(CR.Region, 'Total') AS Region,
    ROUND(SUM(RG.Cost), 0) AS GoogleSpent,
    ROUND(SUM(RG.Conv_value), 0) AS RevenueGoogle,
    ROUND(SUM(CR.Purchase_revenue), 0) AS Real_Revenue,
    ROUND(SUM(CR.Purchase_revenue) / NULLIF(SUM(RG.Cost), 0), 1) AS ROAS,
    ROUND(SUM(RG.Conversions), 0) AS Google_Purchases,
    ROUND(SUM(CR.Ecommerce_purchases), 0) AS Real_Sales
FROM 
    CountryRegionData CR
LEFT JOIN
    RegionsPerformanceGoogleAds AS RG
    ON CR.Region = RG.Region_Matched
GROUP BY 
    CR.Region 
WITH ROLLUP
ORDER BY 
    6 DESC, 7 DESC;



-- With the above query we got an overview of performance and Google ads spending.
-- we want to know specifically how many percent of the revenue and Google ads spending is attributed to each of the regions.
-- In New York we are spending 33% of the ads budget which brings total of 6.5% revenue meanwhile in California we spend 15.7% and it brought 9.4% of the revenue.

WITH Totals AS (
    SELECT 
        SUM(CAST(CRD.Purchase_revenue AS FLOAT)) AS Total_Revenue,
        SUM(CAST(RG.Cost AS FLOAT)) AS Google_Spent,
        SUM(RG.Conv_value) AS Google_Revenue
    FROM 
        CountryRegionData CRD
    LEFT JOIN 
        RegionsPerformanceGoogleAds RG
    ON 
        CRD.Region = RG.Region_Matched
)
SELECT Region,
    ROUND(SUM(RG.Cost) / T.Google_Spent * 100, 1) AS Spent_Percentage,
	ROUND(SUM(CR.Purchase_revenue) / T.Total_Revenue * 100, 1) AS Revenue_Percentage
FROM 
    CountryRegionData CR
LEFT JOIN
    RegionsPerformanceGoogleAds RG
    ON CR.Region = RG.Region_Matched
CROSS JOIN 
    Totals T
GROUP BY 
    CR.Region, T.Total_Revenue, T.Google_Revenue, T.Google_Spent
ORDER BY 
    2 DESC, 3 DESC;



-- Specific product sales by country, for 3 and more products for each country
-- Sales for product type for each country are very spread out and we have a wide distribution of sales volume.

Select Country, ItemName, Count(ItemName) As ItemSales  
From Purchase_data_Country
Group by Country,ItemName
Having Count(ItemName)>3
Order by Count(ItemName) DESC, Country 


-- Top countries with more than 7 product purchases for each country and US is the only country which appears.
-- In US which is also our biggest market (it can be considered an outlier compared to the rest of the markets) models 107,135,136,198 and 117 are our best sellers. 


SELECT TOP 10 Country, ItemName, COUNT(ItemName) As ItemSales  
FROM Purchase_data_Country
GROUP BY Country,ItemName
HAVING COUNT(ItemName)>7
ORDER BY COUNT(ItemName) DESC



-- Funnel rates are crucial to measure and improve. How many add to carts are converted to checkouts and after that how many of them are completed purchases? 
-- There is a lower overall conversion rate (6.39%) from initial interest to completed sale. This suggests there may be issues or barriers earlier in the funnel.
-- The Checkout-to-Sales Conversion Rate is relatively high, indicating the checkout process is efficient.
-- The Cart-to-Checkout Conversion Rate and Cart-to-Sales CR suggests there is room for improvement in getting users from adding items to their cart to completing the purchase.



WITH TOTALS AS (
    SELECT 
        SUM(Add_to_carts) AS ATC,
        SUM(Checkouts) AS CH,
        SUM(Ecommerce_purchases) AS Sales
    FROM 
        CountryRegionData
)
SELECT 
    FORMAT((T.CH * 100.0 / T.ATC), '0.##') AS AddToCarts_Checkout,
    FORMAT((T.Sales * 100.0 / T.CH), '0.##') AS Checkout_Sales,
    FORMAT((T.Sales * 100.0 / T.ATC), '0.##') AS AddToCarts_Sales
FROM 
    TOTALS T;


-- The store converting rate range from a region to another. New York, Virginia, Illinois, Washington, Califronia have small differencies 

SELECT 
    Region,
    FORMAT(IIF(SUM(Add_to_carts) <> 0, (SUM(Checkouts) * 100.0 / SUM(Add_to_carts)), 0), '0.##') AS TOF_rate,
    FORMAT(IIF(SUM(Checkouts) <> 0, (SUM(Ecommerce_purchases) * 100.0 / SUM(Checkouts)), 0), '0.##') AS BOF_rate,
    FORMAT(IIF(SUM(Add_to_carts) <> 0, (SUM(Ecommerce_purchases) * 100.0 / SUM(Add_to_carts)), 0), '0.##') AS Complete_CVR,
	SUM(Ecommerce_purchases) AS Sales_Volume
FROM 
    CountryRegionData
WHERE 
    Region != '(not set)'
GROUP BY 
    Region
HAVING 
    SUM(Add_to_carts) > 0
    AND SUM(Ecommerce_purchases) > 5
ORDER BY 
   5 DESC, 2 DESC, 3 DESC, 4 DESC;



/* 
Majority of the revenue came from the direct traffic and Google (organic and PPC).
We know that users after landing through Google CPC campaigns on website they return through the website url or through keywords to finish the purchase.
*/

SELECT Session_source_medium,
	SUM(Total_revenue) AS Revenue
FROM
	SessionSourceData
GROUP BY	
	Session_source_medium
ORDER BY Revenue desc;



--Google campaigns had the highest engagement time per session which in average was 135 seconds per session. 
-- Among direct, Google Organic and CPC, the last one brings users who have the longest stay on website. However Bing has a much higher average engagement time all the main sources.

SELECT 
    Session_source_medium, SUM(Users) As Users,
    ROUND(AVG(Average_engagement_time_per_session), 2) AS Avg_Eng_Time_seconds
FROM 
    SessionSourceData
WHERE 
    Session_source_medium NOT LIKE '%(not set)%'
GROUP BY 
    Session_source_medium
ORDER BY 
    Users DESC

-- In average the highest number of visitors come by typing the url, throght organic keywords is the second way and through ads is the third way. 
-- However users coming through keywords engage more on the website and have a higher intent of buying meanwhile PPC ads are second to them.

SELECT Session_source_medium,
	AVG(Users) AS Users_avg,
	AVG(Sessions) AS Sessions_avg,
	ROUND(AVG(Events_per_session),2) AS Events_per_session_avg,
	ROUND(AVG(Conversions),2) AS Conv_avg
FROM SessionSourceData
GROUP BY Session_source_medium
ORDER BY 2 DESC, 5 DESC

-- All the referral sources can't be grouped together by the above query as they are not identical strings.
-- To get a clear idea of the impact the referrals had we will check specifically for any sesson_source_medium which contain 'referral'.

SELECT 
    COALESCE(Session_source_medium, 'Total') AS Session_source_medium,
	SUM(Users) AS Users,
	SUM(Sessions) AS Sessions,
	ROUND(AVG(Events_per_session),2) AS Events_per_session,
	ROUND(SUM(Conversions),2) AS Convs
FROM SessionSourceData
WHERE Session_source_medium LIKE '%referral%'
GROUP BY Session_source_medium WITH ROLLUP
ORDER BY
	CASE WHEN Session_source_medium IS NULL THEN 1 ELSE 0 END,
	Users DESC;


-- The below overview brings for each month the top sources by volume of purchases and revenue.
-- Especially in October and November we see that apart from the main sources (Direct, Organic and CPC) email campaigns have been working quite good. 


WITH MonthlyTotals AS (
    SELECT
        YEAR([Date]) AS Year,
        MONTH([Date]) AS Month,
        Session_source_medium,
        SUM(Conversions) AS Purchases,
        SUM(Total_revenue) AS Revenue,
        ROW_NUMBER() OVER (PARTITION BY YEAR([Date]), MONTH([Date]) ORDER BY SUM(Conversions) DESC) AS RowNum
    FROM SessionSourceData
    GROUP BY YEAR([Date]), MONTH([Date]), Session_source_medium
)
SELECT
    Year,
    Month,
    Session_source_medium,
    Purchases,
    Revenue
FROM MonthlyTotals
WHERE Session_source_medium != '(not set)'
AND RowNum IN (1, 2,3,4)
AND Purchases > 0
ORDER BY Year, Month;


-- How did the sales and revenue performed month over month?
-- Our poorest performing months were June and July, meanwhile from September we see a sudden increased which culminates in November.
SELECT
    FORMAT(Date, 'yyyy-MM') AS month,
    SUM(Total_revenue) AS Revenue,
	SUM(Conversions) AS Sales
FROM SessionSourceData
GROUP BY FORMAT(Date, 'yyyy-MM')
ORDER BY month;

-- November stands our with nearly double of purchases compared ot each of the other months and we would like to know more regarding the revenue and sales distribution by day
/*
We can see that the sales spike from the 23 to 29 November which corresponds to the Black Friday.
We know this was also the only period of the year where the client did offers and we can see that the users reacted very well to them.
*/

SELECT
    CAST(Date AS DATE) AS day,
    SUM(Total_revenue) AS Revenue,
    SUM(Conversions) AS Sales
FROM SessionSourceData
WHERE FORMAT(Date, 'yyyy-MM') = '2023-11' 
GROUP BY CAST(Date AS DATE)
ORDER BY day; 

-- Checking the main metrics month by month to understand how much each month contributed to the totals. 
-- Notice that even though the % of users increased in Oct. and Nov., their % increase is much lower compared to sales percentage and revenue percentage.

SELECT
    FORMAT(Date, 'yyyy-MM') AS Month,
	SUM(Conversions) AS Purchases,
	FORMAT(ROUND(SUM(Conversions) * 100.0 / SUM(SUM(Conversions)) OVER (), 1), '0.#') AS Sales_percent,
	SUM(Total_revenue) AS Revenue,
	FORMAT(ROUND(SUM(Total_revenue) * 100.0 / SUM(SUM(Total_revenue)) OVER (), 1), '0.#') AS Revenue_percent,
    SUM(Users) AS Tot_users,
    FORMAT(ROUND(SUM(Users) * 100.0 / SUM(SUM(Users)) OVER (), 1), '0.#') AS Users_percent,
    SUM(Sessions) AS Sessions,
    FORMAT(ROUND(SUM(Sessions) * 100.0 / SUM(SUM(Sessions)) OVER (), 1), '0.#') AS Sessions_percent
FROM SessionSourceData
GROUP BY FORMAT(Date, 'yyyy-MM')
ORDER BY Month;



-- For each product we will check the percentage of the sales they have in each country.
-- This table will be specifically used to change the creatives for each of the countries. 

SELECT
    ItemName,
    Country,
    SUM(Items_purchased) AS Product_Sales,
    CAST(ROUND(SUM(Items_purchased) * 100.0 / SUM(SUM(Items_purchased)) OVER (PARTITION BY Country), 1) AS DECIMAL(5,1)) AS Sales_percentage
FROM Purchase_data_Country
WHERE Items_purchased > 0
GROUP BY ItemName, Country
ORDER BY ItemName;



-- The best selling products for each month. To avoid complimentary products will filter by revenue.
-- Our 135 and 117 models appear mostly as best selling products however the 117 is in Summer and 135 is in Winter mostly.

WITH MonthlySales AS (
    SELECT
        YEAR(Purchasedate) AS Year,
        MONTH(Purchasedate) AS Month,
        Item_Name,
        SUM(Items_purchased) AS Total_Items_Purchased,
        SUM(Item_revenue) AS Total_Item_Revenue,
        ROW_NUMBER() OVER (PARTITION BY YEAR(Purchasedate), MONTH(Purchasedate) ORDER BY SUM(Item_revenue) DESC) AS RowNum
    FROM Purchasedata
    GROUP BY YEAR(Purchasedate), MONTH(Purchasedate), Item_Name
)
SELECT
    Year,
    Month,
    Item_Name,
    Total_Items_Purchased,
    Total_Item_Revenue
FROM MonthlySales
WHERE RowNum = 1
ORDER BY Year, Month;




