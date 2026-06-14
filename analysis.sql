
-- Overview of the dataset (understanding the dataset)

SELECT  *
FROM `my-first-sql-project-499312.practice_data.user_events` 
LIMIT 200;

-- Sales funnel and different stages (Total number of customers going through all stages of the sales process)

 WITH sales_funnel AS (
SELECT COUNT(DISTINCT CASE WHEN event_type = 'page_view' THEN user_id END ) AS stage_1_pg_view,
       COUNT(DISTINCT CASE WHEN event_type = 'add_to_cart' THEN user_id END ) AS stage_2_cart,
       COUNT(DISTINCT CASE WHEN event_type = 'checkout_start' THEN user_id END ) AS stage_3_checkout,
       COUNT(DISTINCT CASE WHEN event_type = 'payment_info' THEN user_id END ) AS stage_4_payment,
       COUNT(DISTINCT CASE WHEN event_type = 'purchase' THEN user_id END ) AS stage_5_purchase,

FROM `my-first-sql-project-499312.practice_data.user_events` 

WHERE event_date >= TIMESTAMP_SUB(
    (SELECT MAX(event_date) FROM `my-first-sql-project-499312.practice_data.user_events`),
    INTERVAL 30 DAY
  ))

SELECT *
FROM sales_funnel 

-- Conversion rates at each stage of selling (At what stage are we actually loosing our customers)

WITH sales_funnel AS (
SELECT COUNT(DISTINCT CASE WHEN event_type = 'page_view' THEN user_id END ) AS stage_1_pg_view,
       COUNT(DISTINCT CASE WHEN event_type = 'add_to_cart' THEN user_id END ) AS stage_2_cart,
       COUNT(DISTINCT CASE WHEN event_type = 'checkout_start' THEN user_id END ) AS stage_3_checkout,
       COUNT(DISTINCT CASE WHEN event_type = 'payment_info' THEN user_id END ) AS stage_4_payment,
       COUNT(DISTINCT CASE WHEN event_type = 'purchase' THEN user_id END ) AS stage_5_purchase,

FROM `my-first-sql-project-499312.practice_data.user_events` 

WHERE event_date >= TIMESTAMP_SUB(
    (SELECT MAX(event_date) FROM `my-first-sql-project-499312.practice_data.user_events`),
    INTERVAL 30 DAY
  ))

SELECT stage_1_pg_view,
      ROUND (stage_2_cart*100/stage_1_pg_view) AS view_to_cart_rate,
      ROUND (stage_3_checkout*100/stage_2_cart) AS cart_to_checkout_rate,
      ROUND (stage_4_payment*100/stage_3_checkout) AS checkout_to_payment_rate,
      ROUND (stage_5_purchase*100/stage_4_payment) AS payment_to_purchase_rate,
      ROUND (stage_5_purchase*100/stage_1_pg_view) AS overal_conversion_rate

FROM sales_funnel

-- We dont have any technical issues when customers are making payments (92.0 % payment to purchase rate)
-- People are viewing product but few proceed to cart (31.0 % view_to_cart_rate); 
  -- UI/UX can be improved for people to see products easily 

--Sales funnel by traffic source

WITH source_funnel AS (
SELECT traffic_source,
      COUNT(DISTINCT CASE WHEN event_type = 'page_view' THEN user_id END ) AS views,
      COUNT(DISTINCT CASE WHEN event_type = 'add_to_cart' THEN user_id END ) AS carts,
      COUNT(DISTINCT CASE WHEN event_type = 'purchase' THEN user_id END ) AS purchases,
      
FROM `my-first-sql-project-499312.practice_data.user_events` 
WHERE event_date >= TIMESTAMP_SUB(
    (SELECT MAX(event_date) FROM `my-first-sql-project-499312.practice_data.user_events`),
    INTERVAL 30 DAY)
    GROUP BY traffic_source)

SELECT 
        traffic_source,
        views,
        carts,
        purchases,
      ROUND (carts*100/views) AS view_to_cart_rate,
      ROUND (purchases*100/views) AS purchases_to_views_rate,
      ROUND (purchases*100/carts) AS purchases_to_carts_rate,
  
FROM source_funnel
ORDER BY purchases DESC

--Social media is driving more views but very few customers purchase
--Emails bring more view but conversion rate is very high as compared to social media
--We should focus more on email marketing than social media

---Time to conversion analysis

WITH conversion_journey AS (
SELECT MIN(CASE WHEN event_type = 'page_view' THEN event_date END ) AS view_time,
       MIN(CASE WHEN event_type = 'add_to_cart' THEN event_date END ) AS cart_time,
       MIN(CASE WHEN event_type = 'purchase' THEN event_date END ) AS purchase_time,

FROM `my-first-sql-project-499312.practice_data.user_events` 

WHERE event_date >= TIMESTAMP_SUB(
    (SELECT MAX(event_date) FROM `my-first-sql-project-499312.practice_data.user_events`),
    INTERVAL 30 DAY
  )
  GROUP BY user_id
  HAVING MIN(CASE WHEN event_type = 'purchase' THEN event_date END ) IS NOT NULL )


SELECT COUNT (*) AS converted_users,
              ROUND(AVG(TIMESTAMP_DIFF(cart_time,view_time,MINUTE)),2) AS avg_view_to_cart_minutes,
              ROUND(AVG(TIMESTAMP_DIFF(purchase_time, cart_time,MINUTE)),2) AS avg_view_to_purchase_minutes,
              ROUND(AVG(TIMESTAMP_DIFF(purchase_time, view_time,MINUTE)),2) AS avg_total_journey_in_minutes
FROM conversion_journey

--it takes 24.55 minutes for a customer to complete the journey and make a purchase---
--Seems normal; No red flag here

--Revenue funnel analysis

WITH revenue_funnel AS (
SELECT COUNT(DISTINCT CASE WHEN event_type = 'page_view' THEN event_date END ) AS total_visitors,
       COUNT(DISTINCT CASE WHEN event_type = 'purchase' THEN event_date END ) AS total_buyers,
       ROUND(SUM(CASE WHEN event_type = 'purchase' THEN amount END ),2) AS total_revenue,
      COUNT(CASE WHEN event_type = 'purchase' THEN 1 END ) AS total_orders
       
FROM `my-first-sql-project-499312.practice_data.user_events` 

WHERE event_date >= TIMESTAMP_SUB(
    (SELECT MAX(event_date) FROM `my-first-sql-project-499312.practice_data.user_events`),
    INTERVAL 30 DAY
  ))
   
SELECT total_visitors,
total_buyers,
total_orders,
total_revenue,
total_revenue/total_buyers AS average_order_value,
total_revenue/total_orders AS revenue_per_buyer,
total_revenue/total_visitors AS revenue_per_visitor
   
FROM revenue_funnel
-- END

