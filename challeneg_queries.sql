show databases;
use retail_events_db;
show tables;
/*
The below query gives answer for first question
*/
SELECT
    fact_events.product_code,
    MAX(dim_products.product_name) AS product_name,
    COUNT(fact_events.product_code) AS product_count
FROM
    fact_events
INNER JOIN
    dim_products ON fact_events.product_code = dim_products.product_code
WHERE
    base_price > 500
    AND promo_type = "BOGOF"
GROUP BY
    fact_events.product_code;
    

/*This below query gives answer for second question
*/
SELECT
    COUNT(store_id) AS number_of_stores,
    city
FROM
    dim_stores
GROUP BY
    city
ORDER BY
    number_of_stores DESC;

/*This below query gives answer for third question
*/
ALTER TABLE `fact_events`
CHANGE COLUMN `quantity_sold(before_promo)` `quantity_sold_before_promo` int NOT NULL,
CHANGE COLUMN `quantity_sold(after_promo)` `quantity_sold_after_promo` int NOT NULL;


SELECT 
    campaign_name,sum(base_price * quantity_sold_before_promo) AS 'total_revenue(before_promotion)',
    SUM(CASE 
        WHEN promo_type = "25% OFF" THEN ((base_price - (base_price * 0.25)) * quantity_sold_after_promo)
        WHEN promo_type = "33% OFF" THEN ((base_price - (base_price * 0.33)) * quantity_sold_after_promo)
        WHEN promo_type = "50% OFF" THEN ((base_price - (base_price * 0.5)) * quantity_sold_after_promo)
        WHEN promo_type = "500 Cashback" THEN ((base_price - 500) * quantity_sold_after_promo)
        WHEN promo_type = "BOGOF" THEN (base_price * quantity_sold_after_promo)
        ELSE 0
    END) AS 'total_revenue(after_promotion)'
FROM 
    fact_events
INNER JOIN 
    dim_campaigns ON fact_events.campaign_id = dim_campaigns.campaign_id
GROUP BY 
    fact_events.campaign_id;



/*This below query gives answer for fourth question
*/
SELECT
    dim_products.category,
    ((SUM(quantity_sold_after_promo) - SUM(quantity_sold_before_promo)) / NULLIF(SUM(quantity_sold_before_promo), 0)) * 100 AS `ISU%`,
    RANK() OVER (ORDER BY ((SUM(quantity_sold_after_promo) - SUM(quantity_sold_before_promo)) / NULLIF(SUM(quantity_sold_before_promo), 0)) DESC) AS `ISU%_rank`
FROM
    fact_events
INNER JOIN
    dim_products ON fact_events.product_code = dim_products.product_code
WHERE
    campaign_id = 'CAMP_DIW_01'
GROUP BY
    dim_products.category;

/*This below query gives answer for fifth question
*/
SELECT
    product_name,
    category,
    IR_percentage,
    RANK() OVER (ORDER BY IR_percentage DESC) AS IR_percentage_rank
FROM (
    SELECT
        dim_products.category,
        dim_products.product_name,
        ((SUM(fact_events.base_price * fact_events.quantity_sold_after_promo) - SUM(fact_events.base_price * fact_events.quantity_sold_before_promo)) / SUM(fact_events.base_price * fact_events.quantity_sold_before_promo)) * 100 AS IR_percentage
    FROM
        fact_events
    INNER JOIN
        dim_products ON fact_events.product_code = dim_products.product_code
    GROUP BY
        dim_products.category, dim_products.product_name
) AS subquery
ORDER BY
    IR_percentage_rank;