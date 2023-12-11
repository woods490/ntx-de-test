/*

For this case I try to replicate the step by step process provided in the Github which the steps are:
1. Computes the total revenue generated by each product (v2ProductName).
	For this step instead of using the TotalRevenue column, I calculate the productQuantity sold with productPrice with productSKU partition, the reason for that is
	there are no documentation of transactions in the data, so using the TotalRevenue column will be innacurate since it isa the total revenue of the user's bought product
	there could be unrecorded other product revenue in there

2. Determines the total quantity sold for each product.
	For this step I just sum the productQuantity with productSKU partition to determine the total quantity of product sold
	
3. Calculates the total refund amount for each product.
	This is the same as step number 2, I use sum function to productQuantity to determine the refund amount for each product
	
4. Rank products based on their net revenue (total revenue minus refunds) in a descending order. Flag any product with a refund amount surpassing 10% of its total revenue.
	For the main query I calculate the net revenue with the formula given in the Github then will flag any product with a refund amount surpassing 10% of its total revenue with
	"High Refund" label. In addition to that I also displayed total quantity of sold product and total refund amount of sold product 


*/


WITH total_revenue AS (
    SELECT
        DISTINCT productSKU,
        v2ProductName,
        COALESCE(SUM(COALESCE(productQuantity, 0) * COALESCE(productPrice / 1e6, 0)) OVER (PARTITION BY productSKU), 0) AS totalRevenue
    FROM
        "data-to-insights.ecommerce.all_sessions"
),
total_quantity AS (
    SELECT
        DISTINCT productSKU,
        COALESCE(SUM(COALESCE(productQuantity, 0)) OVER (PARTITION BY productSKU), 0) AS totalQuantitySold
    FROM
        "data-to-insights.ecommerce.all_sessions"
),
total_refund AS (
    SELECT
        DISTINCT productSKU,
        COALESCE(SUM(COALESCE(productRefundAmount, 0)) OVER (PARTITION BY productSKU), 0) AS totalRefundAmount
    FROM
        "data-to-insights.ecommerce.all_sessions"
)
SELECT
    DISTINCT tr.productSKU,
    tr.v2ProductName,
    trq.totalQuantitySold,
    tr.totalRevenue - COALESCE(trf.totalRefundAmount, 0) AS netRevenue,
    trf.totalRefundAmount AS totalRefund,
    CASE WHEN COALESCE(trf.totalRefundAmount, 0) > 0.1 * tr.totalRevenue THEN 'High Refund' ELSE 'No Refund' END AS refundFlag
FROM
    total_revenue tr
LEFT JOIN
    total_quantity trq ON tr.productSKU = trq.productSKU
LEFT JOIN
    total_refund trf ON tr.productSKU = trf.productSKU
ORDER BY
    netRevenue DESC;