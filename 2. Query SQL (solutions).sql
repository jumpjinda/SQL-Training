-- 1. What is the total amount each customer spent at the restaurant?

SELECT
  sales.customer_id,
  SUM(menu.price) AS total_spent
FROM sales
JOIN menu
  ON sales.product_id = menu.product_id
GROUP BY customer_id
ORDER BY customer_id;

-- 2. How many days has each customer visited the restaurant?

SELECT
  customer_id,
  COUNT(DISTINCT(order_date)) AS total_visit
FROM sales
GROUP BY customer_id;

-- 3. What was the first item from the menu purchased by each customer?

WITH first_day_cte AS
(
SELECT
  sales.customer_id,
  sales.order_date,
  menu.product_name,
  DENSE_RANK() OVER(PARTITION BY sales.customer_id ORDER BY sales.order_date) AS rank
FROM sales
JOIN menu
  ON sales.product_id = menu.product_id
)
SELECT
  customer_id,
  product_name
FROM first_day_cte
WHERE rank = 1
GROUP BY customer_id;

-- 4. What is the most purchased item on the menu and how many times was it purchased by all customers?

SELECT
  menu.product_name,
  COUNT(sales.product_id) AS most_purchased_item
FROM menu
JOIN sales
  ON menu.product_id = sales.product_id
GROUP BY menu.product_name
ORDER BY most_purchased_item DESC
LIMIT 1;

-- 5. Which item was the most popular for each customer?

WITH rank_order_cte AS
(
SELECT
  sales.customer_id,
  menu.product_name,
  COUNT(sales.product_id) AS total_order,
  DENSE_RANK() OVER(PARTITION BY sales.customer_id ORDER BY COUNT(sales.product_id) DESC) AS rank
FROM sales
JOIN menu
  ON sales.product_id = menu.product_id
GROUP BY sales.customer_id, menu.product_name
)
SELECT
  customer_id,
  product_name,
  total_order
FROM rank_order_cte
WHERE rank = 1;

-- 6. Which item was purchased first by the customer after they became a member?

WITH order_date_rank_cte AS
(
SELECT
  sales.customer_id,
  sales.order_date,
  members.join_date,
  sales.product_id,
  DENSE_RANK() OVER(PARTITION BY sales.customer_id ORDER BY order_date) AS rank
FROM sales
JOIN members
  ON sales.customer_id = members.customer_id
WHERE sales.order_date >= members.join_date
)
SELECT
  o.customer_id,
  o.order_date,
  o.product_id,
  menu.product_name
FROM order_date_rank_cte AS o
JOIN menu
  ON o.product_id = menu.product_id
WHERE rank = 1;

-- 7. Which item was purchased just before the customer became a member?

SELECT
  sales.customer_id,
  sales.order_date,
  members.join_date,
  menu.product_name
FROM sales
JOIN members
  ON sales.customer_id = members.customer_id
JOIN menu
  ON sales.product_id = menu.product_id
WHERE sales.order_date < members.join_date;

-- 8. What is the total items and amount spent for each member before they became a member?

SELECT
  sales.customer_id,
  COUNT(sales.product_id) AS total_items,
  SUM(menu.price) total_price
FROM sales
JOIN members
  ON sales.customer_id = members.customer_id
JOIN menu
  ON sales.product_id = menu.product_id
WHERE sales.order_date < members.join_date
GROUP BY sales.customer_id;

-- 9.  If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?

WITH price_point AS
(
SELECT
  *,
  CASE
    WHEN product_name = 'sushi' THEN price * 20
    ELSE price * 10
    END AS point
FROM menu
)
SELECT
  sales.customer_id,
  SUM(price_point.point) AS total_point
FROM price_point
JOIN sales
  ON price_point.product_id = sales.product_id
GROUP BY sales.customer_id;

-- 10. In the first week after a customer joins the program (including their join date) they earn 2x points on all items, not just sushi
-- how many points do customer A and B have at the end of January?

-- (This is short term answer of SQL / อันนี้แบบสั้นรวบตารางให้เหลือแค่ผลลัพธ์ที่แท้จริง)

SELECT
  sales.customer_id,
  members.join_date,
  DATE(members.join_date, '+6 days') AS valid_date, /* เอาไว้ show ในตารางเฉยๆ */
  DATE('2021-01-31') AS eomonth,
  SUM(CASE
    WHEN menu.product_name = 'sushi' THEN menu.price * 20
    WHEN sales.order_date BETWEEN members.join_date AND DATE(members.join_date, '+6 days') THEN menu.price * 20
    ELSE 10 * price
    END) AS point
FROM sales
JOIN members
  ON sales.customer_id = members.customer_id
JOIN menu
  ON sales.product_id = menu.product_id
WHERE sales.order_date < eomonth
GROUP BY sales.customer_id;

-- Bonus Questions
-- 1. Join All The Things

SELECT
  sales.customer_id,
  sales.order_date,
  menu.product_name,
  menu.price,
  CASE
    WHEN sales.order_date >= members.join_date THEN "Y"
	WHEN sales.order_date < members.join_date THEN "N"
	ELSE "N"
	END AS member
FROM sales
LEFT JOIN menu /*ใช้ LEFT JOIN เผื่อเอา sales.customer ออกมาทั้งหมด*/
  ON sales.product_id = menu.product_id
LEFT JOIN members
  ON sales.customer_id = members.customer_id
  
-- 2. Rank All The Things
-- Danny also requires further information about the ranking of customer products, but he purposely does not need the ranking for non-member purchases
-- so he expects null ranking values for the records when customers are not yet part of the loyalty program.

WITH members_by_date_cte AS
(
SELECT
  sales.customer_id,
  sales.order_date,
  menu.product_name,
  menu.price,
  CASE
    WHEN sales.order_date >= members.join_date THEN "Y"
	WHEN sales.order_date < members.join_date THEN "N"
	ELSE "N"
	END AS member
FROM sales
LEFT JOIN menu
  ON sales.product_id = menu.product_id
LEFT JOIN members
  ON sales.customer_id = members.customer_id
)
SELECT 
  *,
  CASE
    WHEN member = 'N' THEN NULL
	ELSE
	  DENSE_RANK() OVER(PARTITION BY customer_id, member ORDER BY order_date)
	END AS ranking
FROM members_by_date_cte
