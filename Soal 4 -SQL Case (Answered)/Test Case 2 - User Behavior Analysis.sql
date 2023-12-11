/*

First, I calculate metrics for each users by considering their fullVisitorId and visitId. The reason for that is if
calculated only by fullVisitorId there will be duplicate timeOnSite values since it is recorded everytime user make any
actions so I worry that will effect average calculations

*/
WITH average_metrics AS (
    SELECT
        fullVisitorId,
        visitId,
        COALESCE(AVG(timeOnSite), 0) AS avgTimeOnSite,
        COALESCE(AVG(pageviews), 0) AS avgPageviews,
        COALESCE(AVG(sessionQualityDim), 0) AS avgSessionQualityDim
    FROM
        "data-to-insights.ecommerce.all_sessions"
    GROUP BY
        fullVisitorId, visitId
)

/*

Finally, I will display average timeOnSite, pageviews, and sessionQualityDim for each users then flag whether or not 
the users spend above-average time on the site but view fewer pages than the average user. "Not Flagged" means that
the user doesn't meet the requirements, while "Flagged" means that the user meet the requirements
 
*/
SELECT
    am.fullVisitorId,
    am.avgTimeOnSite,
    am.avgPageviews,
    am.avgSessionQualityDim,
    CASE
        WHEN am.avgTimeOnSite > global_avg.globalAvgTimeOnSite
             AND am.avgPageviews < global_avg.globalAvgPageviews THEN 'Flagged'
        ELSE 'Not Flagged'
    END AS user_flag
FROM
    average_metrics am
CROSS JOIN (
    -- Calculate global average timeOnSite and pageviews for all users
    SELECT
        COALESCE(AVG(timeOnSite), 0) AS globalAvgTimeOnSite,
        COALESCE(AVG(pageviews), 0) AS globalAvgPageviews
    FROM
        "data-to-insights.ecommerce.all_sessions"
) global_avg;