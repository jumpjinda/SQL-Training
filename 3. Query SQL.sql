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
	DENSE_RANK() OVER(PARTITION BY sales.customer_id
                      ORDER BY sales.order_date) AS rank
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
	DENSE_RANK() OVER(PARTITION BY sales.customer_id
					  ORDER BY COUNT(sales.product_id) DESC) AS rank
FROM sales
JOIN menu
	ON sales.product_id = menu.product_id
GROUP BY sales.customer_id, menu.product_name
)
SELECT customer_id, product_name, total_order
FROM rank_order_cte
WHERE rank = 1;

-- 6. Which item was purchased first by the customer after they became a member?

-- 7. Which item was purchased just before the customer became a member?
-- 8. What is the total items and amount spent for each member before they became a member?
-- 9.  If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?
-- 10. In the first week after a customer joins the program (including their join date) they earn 2x points on all items, not just sushi - how many points do customer A and B have at the end of January?
