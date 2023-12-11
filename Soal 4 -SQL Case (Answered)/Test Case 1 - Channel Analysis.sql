/*

First, I find the top 5 countries based on total transaction revenue to be used in the main query 

*/
WITH RankedCountries AS (
    SELECT
        country,
        COALESCE(SUM(totalTransactionRevenue) / 1e6, 0) AS totalRevenue -- Calculate total revenue, filling NaN values with 0
    FROM
        "data-to-insights.ecommerce.all_sessions"
    GROUP BY
        country
    ORDER BY
        totalRevenue DESC -- Make sure that it's in descending order, so that it shows top 5 countries first
    LIMIT 5 -- Get top 5 countries
)
/*

Finally, I try to display total revenue generated from each channel grouping for the top 5 countries

*/
SELECT
    rc.country,	-- Selected country from the CTE
    e.channelGrouping, -- Selected channel grouping from the main table
    COALESCE(SUM(totalTransactionRevenue) / 1e6, 0) AS totalRevenue -- Total revenue to display, filling NaN values with 0
FROM
    "data-to-insights.ecommerce.all_sessions" e
RIGHT JOIN
    RankedCountries rc ON e.country = rc.country -- Joining with the CTE to get top 5 countries
GROUP BY
    rc.country, e.channelGrouping -- Grouping by country and channel grouping
ORDER BY
    rc.Country; -- Ordering by country name



