WITH product_sale AS (
    SELECT 
        p.category,
        p.product_name,
        ROUND(SUM(o.sales)::NUMERIC, 2) AS product_total_sales,
        ROUND(SUM(o.profit)::NUMERIC, 2) AS product_total_profit,
        DENSE_RANK() OVER (
            PARTITION BY p.category
            ORDER BY SUM(o.sales) DESC
        ) AS product_rank
    FROM orders AS o
    JOIN products AS p ON p.product_id = o.product_id
    GROUP BY p.category, p.product_name
)
SELECT *
FROM product_sale
WHERE product_rank <= 5;

WITH unit_price_calc AS (
    SELECT 
        product_id,
        discount,
        market,
        region,
        ROUND((sales / NULLIF(quantity, 0))::NUMERIC, 2) AS unit_price
    FROM orders
    WHERE quantity IS NOT NULL
),
avg_unit_prices AS (
    SELECT
        product_id,
        discount,
        market,
        region,
        AVG(unit_price) AS avg_price
    FROM unit_price_calc
    GROUP BY product_id, discount, market, region
)
SELECT
    o.product_id,
    o.discount,
    o.market,
    o.region,
    o.sales,
    o.quantity,
    ROUND((o.sales / NULLIF(a.avg_price, 0))::NUMERIC, 0) AS calculated_quantity
FROM orders o
LEFT JOIN avg_unit_prices a
    ON o.product_id = a.product_id
    AND o.discount  = a.discount
    AND o.market    = a.market
    AND o.region    = a.region
WHERE o.quantity IS NULL;
