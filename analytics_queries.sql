-- Financial Analytics Queries
-- Author: Sumanth Battu
-- Description: Advanced SQL queries for financial data analysis

-- ============================================
-- 1. Customer Revenue Analysis
-- Window functions + CTEs
-- ============================================
WITH customer_revenue AS (
    SELECT
        customer_id,
        transaction_date,
        amount,
        category,
        SUM(amount) OVER (
            PARTITION BY customer_id
            ORDER BY transaction_date
            ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
        ) AS cumulative_spend,
        AVG(amount) OVER (
            PARTITION BY customer_id
            ORDER BY transaction_date
            ROWS BETWEEN 6 PRECEDING AND CURRENT ROW
        ) AS rolling_7day_avg,
        ROW_NUMBER() OVER (
            PARTITION BY customer_id
            ORDER BY amount DESC
        ) AS transaction_rank
    FROM financial_transactions
    WHERE status = 'completed'
),
customer_segments AS (
    SELECT
        customer_id,
        MAX(cumulative_spend)    AS total_lifetime_value,
        AVG(amount)              AS avg_transaction,
        COUNT(*)                 AS total_transactions,
        MAX(transaction_date)    AS last_transaction_date,
        CASE
            WHEN MAX(cumulative_spend) > 50000 THEN 'Premium'
            WHEN MAX(cumulative_spend) > 10000 THEN 'High Value'
            WHEN MAX(cumulative_spend) > 1000  THEN 'Standard'
            ELSE 'Low Value'
        END AS customer_segment
    FROM customer_revenue
    GROUP BY customer_id
)
SELECT
    customer_segment,
    COUNT(*)                     AS customer_count,
    ROUND(AVG(total_lifetime_value), 2) AS avg_ltv,
    ROUND(AVG(avg_transaction), 2)      AS avg_transaction_value,
    SUM(total_lifetime_value)           AS total_segment_revenue
FROM customer_segments
GROUP BY customer_segment
ORDER BY total_segment_revenue DESC;


-- ============================================
-- 2. Daily KPI Dashboard Query
-- Identifies KPIs that drive the business
-- ============================================
WITH daily_metrics AS (
    SELECT
        DATE_TRUNC('day', transaction_date)     AS report_date,
        COUNT(DISTINCT customer_id)             AS unique_customers,
        COUNT(transaction_id)                   AS total_transactions,
        SUM(amount)                             AS total_revenue,
        AVG(amount)                             AS avg_transaction_value,
        SUM(CASE WHEN status = 'completed'
            THEN amount ELSE 0 END)             AS completed_revenue,
        SUM(CASE WHEN status = 'failed'
            THEN 1 ELSE 0 END)                  AS failed_transactions,
        SUM(CASE WHEN category = 'refund'
            THEN amount ELSE 0 END)             AS total_refunds
    FROM financial_transactions
    GROUP BY DATE_TRUNC('day', transaction_date)
),
daily_growth AS (
    SELECT
        report_date,
        total_revenue,
        unique_customers,
        total_transactions,
        avg_transaction_value,
        failed_transactions,
        total_refunds,
        LAG(total_revenue) OVER (
            ORDER BY report_date
        )                                        AS prev_day_revenue,
        ROUND(
            (total_revenue - LAG(total_revenue)
            OVER (ORDER BY report_date)) /
            NULLIF(LAG(total_revenue)
            OVER (ORDER BY report_date), 0) * 100
        , 2)                                     AS revenue_growth_pct
    FROM daily_metrics
)
SELECT *
FROM daily_growth
ORDER BY report_date DESC;


-- ============================================
-- 3. Anomaly Detection Query
-- Identifies unusual transaction patterns
-- ============================================
WITH transaction_stats AS (
    SELECT
        customer_id,
        AVG(amount)             AS mean_amount,
        STDDEV(amount)          AS stddev_amount,
        COUNT(*)                AS transaction_count
    FROM financial_transactions
    GROUP BY customer_id
    HAVING COUNT(*) >= 5
),
flagged_transactions AS (
    SELECT
        t.transaction_id,
        t.customer_id,
        t.amount,
        t.transaction_date,
        t.category,
        s.mean_amount,
        s.stddev_amount,
        ROUND((t.amount - s.mean_amount) /
            NULLIF(s.stddev_amount, 0), 2)  AS z_score,
        CASE
            WHEN ABS((t.amount - s.mean_amount) /
                NULLIF(s.stddev_amount, 0)) > 3
            THEN 'HIGH ANOMALY'
            WHEN ABS((t.amount - s.mean_amount) /
                NULLIF(s.stddev_amount, 0)) > 2
            THEN 'MEDIUM ANOMALY'
            ELSE 'NORMAL'
        END                                 AS anomaly_flag
    FROM financial_transactions t
    JOIN transaction_stats s
        ON t.customer_id = s.customer_id
)
SELECT *
FROM flagged_transactions
WHERE anomaly_flag != 'NORMAL'
ORDER BY ABS(z_score) DESC;


-- ============================================
-- 4. Monthly Performance Report
-- Executive-level KPI summary
-- ============================================
SELECT
    DATE_TRUNC('month', transaction_date)       AS month,
    COUNT(DISTINCT customer_id)                 AS active_customers,
    COUNT(transaction_id)                       AS total_transactions,
    ROUND(SUM(amount), 2)                       AS total_revenue,
    ROUND(AVG(amount), 2)                       AS avg_transaction,
    ROUND(SUM(CASE WHEN status = 'completed'
        THEN amount ELSE 0 END) /
        NULLIF(SUM(amount), 0) * 100, 2)        AS completion_rate_pct,
    COUNT(DISTINCT CASE
        WHEN amount > 1000 THEN customer_id
    END)                                        AS high_value_customers,
    ROUND(SUM(amount) / COUNT(DISTINCT
        customer_id), 2)                        AS revenue_per_customer
FROM financial_transactions
GROUP BY DATE_TRUNC('month', transaction_date)
ORDER BY month DESC;
