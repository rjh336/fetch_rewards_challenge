-- NOTE: `fetch_rewards` is my database schema and it contains the three tables described 
-- in the attached entity relationship diagram. 

-- Additionally, I am using the `brandCode`
-- dimension from the receiptItems table to define a brand. Please see `part_3.ipynb`
-- for my rationale in this choice.

-----

-- QUESTION: How does the ranking of the top 5 brands by receipts scanned for the recent month compare to the ranking for the 
-- previous month?

-- I am assuming that we want to see the positional change in rankings for those same 5 brands from the prior 
-- month. So I will show two columns for each brand: `current month rank` and `prior month rank`.

WITH 
    targetMonths as (
        SELECT 
            DISTINCT(TIMESTAMP_TRUNC(TIMESTAMP_MILLIS(dateScanned), MONTH)) as month
        FROM `fetch_rewards.receipts`
        ORDER BY month DESC 
        LIMIT 2
    ), 

    targetReceiptIds as (
        SELECT DISTINCT
            id,
            TIMESTAMP_TRUNC(TIMESTAMP_MILLIS(dateScanned), MONTH) as month
        FROM `fetch_rewards.receipts`
        WHERE TIMESTAMP_TRUNC(TIMESTAMP_MILLIS(dateScanned), MONTH) IN (SELECT month FROM targetMonths)
    ),

    aggReceiptItems as (
        SELECT
            brandCode,
            month,
            COUNT(DISTINCT id) as receiptsScanCount,
            RANK() OVER (PARTITION BY month ORDER BY COUNT(DISTINCT id) DESC) as receiptsScanCountRank
        FROM `fetch_rewards.receiptItems` as receiptItems
        INNER JOIN targetReceiptIds 
            ON receiptItems.receiptId = targetReceiptIds.id
        GROUP BY 1, 2
    ),

    monthRankComparison as (
        SELECT* FROM (
            SELECT 
                brandCode,
                receiptsScanCount,
                receiptsScanCountRank as currMonthRank,
                LAG(receiptsScanCountRank) OVER (PARTITION BY brandCode ORDER BY month) as priorMonthRank
            FROM aggReceiptItems
        )
        WHERE priorMonthRank IS NOT NULL AND currMonthRank <= 5
        ORDER BY currMonthRank
    )

SELECT * FROM monthRankComparison;