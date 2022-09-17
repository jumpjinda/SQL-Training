-- First thing first, we fixing 2 tables are customer_orders and runner_orders

-- Fix customer_orders table by create temp table name customer_orders_cleaned that we have fixed 'null' values

CREATE TEMP TABLE customer_orders_cleaned AS
SELECT
  order_id,
  customer_id,
  pizza_id,
  CASE
    WHEN exclusions = '' THEN NULL
    WHEN exclusions = 'null' THEN NULL
    ELSE exclusions
  END AS exclusions,
  CASE
    WHEN extras = '' THEN NULL
    WHEN extras = 'null' THEN NULL
	ELSE extras
  END AS extras,
  order_time
FROM customer_orders
