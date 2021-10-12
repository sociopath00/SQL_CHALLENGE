--  Problem 1
--  What is the total amount each customer spent at the restaurant?

SELECT s.customer_id, SUM(m.price) as total_spent
FROM sales s LEFT JOIN menu m
ON s.product_id = m.product_id 
GROUP BY s.customer_id ;

--  output
--  |customer_id|total_spent|
--  |-----------|-----------|
--  |A          |76         |
--  |B          |74         |
--  |C          |36         |



--  Problem 2
--  How many days has each customer visited the restaurant?

SELECT customer_id, COUNT(DISTINCT order_date) as no_of_days_visited
FROM sales
GROUP BY customer_id;


-- |customer_id|no_of_days_visited|
-- |-----------|------------------|
-- |A          |4                 |
-- |B          |6                 |
-- |C          |2                 |



--  Problem 3
--  What was the first item from the menu purchased by each customer?

WITH cte_customer AS(
	SELECT customer_id, product_id, ROW_NUMBER() OVER(PARTITION BY customer_id ORDER BY order_date) as ranks
	FROM sales
)
SELECT s.customer_id, m.product_name
FROM cte_customer s LEFT JOIN menu m
ON s.product_id = m.product_id 
WHERE ranks = 1;


-- |customer_id|product_name|
-- |-----------|------------|
-- |A          |sushi       |
-- |B          |curry       |
-- |C          |ramen       |



-- Problem 4
-- What is the most purchased item on the menu and how many times was it purchased by all customers?
WITH cte_product AS (
	SELECT s.product_id, COUNT(1) as most_purchased, m.product_name
	FROM sales s LEFT JOIN menu m
	ON s.product_id = m.product_id 
	GROUP BY s.product_id, m.product_name 
	ORDER BY COUNT(1) DESC
	LIMIT 1
)
SELECT s.customer_id, p.product_name, COUNT(1) AS no_of_times_purchased
FROM sales s INNER JOIN cte_product p 
ON s.product_id = p.product_id
GROUP BY s.customer_id, p.product_name;



-- |customer_id|product_name|no_of_times_purchased|
-- |-----------|------------|---------------------|
-- |A          |ramen       |3                    |
-- |B          |ramen       |2                    |
-- |C          |ramen       |3                    |



-- Problem 5
-- Which item was the most popular for each customer?


WITH cte_product_ranks AS (
	SELECT customer_id, product_id, COUNT(1) as purchased_count,
		RANK() OVER(PARTITION BY customer_id ORDER BY COUNT(1) DESC) as ranks
	FROM sales
	GROUP BY customer_id, product_id 
)
SELECT c.customer_id, m.product_name, c.purchased_count
FROM cte_product_ranks c LEFT JOIN menu m
ON c.product_id = m.product_id
WHERE ranks = 1;


-- 
-- |customer_id|product_name|purchased_count|
-- |-----------|------------|---------------|
-- |A          |ramen       |3              |
-- |B          |curry       |2              |
-- |B          |sushi       |2              |
-- |B          |ramen       |2              |
-- |C          |ramen       |3              |



-- Problem 6
-- Which item was purchased first by the customer after they became a member?

WITH cte_sales AS (
	SELECT s.customer_id, s.product_id, s.order_date, ROW_NUMBER() OVER(PARTITION BY s.customer_id ORDER BY s.order_date) as ranks
	FROM sales s LEFT JOIN members m 
	ON s.customer_id = m.customer_id 
	WHERE s.order_date >= m.join_date 
)
SELECT s.customer_id, m.product_name, s.order_date 
FROM cte_sales s LEFT JOIN menu m
ON s.product_id = m.product_id
WHERE s.ranks = 1;



-- |customer_id|product_name|order_date|
-- |-----------|------------|----------|
-- |A          |curry       |2021-01-07|
-- |B          |sushi       |2021-01-11|



-- Problem 7
-- Which item was purchased just before the customer became a member?

WITH cte_products AS (
	SELECT s.customer_id, s.product_id, s.order_date,
		RANK() OVER(PARTITION BY s.customer_id ORDER BY s.order_date DESC) as ranks
	FROM sales s LEFT JOIN members m 
	ON s.customer_id = m.customer_id 
	WHERE s.order_date < m.join_date 
)
SELECT c.customer_id, m.product_name, c.order_date
FROM cte_products c LEFT JOIN menu m
ON c.product_id = m.product_id
WHERE ranks = 1;



-- |customer_id|product_name|order_date|
-- |-----------|------------|----------|
-- |A          |sushi       |2021-01-01|
-- |A          |curry       |2021-01-01|
-- |B          |sushi       |2021-01-04|




-- Problem 8
-- What is the total items and amount spent for each member before they became a member?

WITH cte_products AS (
	SELECT s.customer_id, s.product_id, s.order_date,
		RANK() OVER(PARTITION BY s.customer_id ORDER BY s.order_date DESC) as ranks
	FROM sales s LEFT JOIN members m 
	ON s.customer_id = m.customer_id 
	WHERE s.order_date < m.join_date 
)
SELECT s.customer_id, COUNT(1) as total_items, SUM(me.price) as amount_spent
FROM cte_products s LEFT JOIN menu me
ON s.product_id = me.product_id
GROUP BY s.customer_id ;



-- |customer_id|total_items|amount_spent|
-- |-----------|-----------|------------|
-- |A          |2          |25          |
-- |B          |3          |40          |



-- Problem 9
-- If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?
	

WITH cte_points AS (
	SELECT s.customer_id, 
		CASE
			WHEN m.product_name = 'sushi' THEN m.price * 2
			ELSE m.price
		END AS points
	FROM sales s LEFT JOIN menu m
	ON s.product_id = m.product_id 
)
SELECT customer_id, SUM(points) as total_points
FROM cte_points
GROUP BY customer_id;



-- |customer_id|total_points|
-- |-----------|------------|
-- |A          |86          |
-- |B          |94          |
-- |C          |36          |



-- Problem 10
-- In the first week after a customer joins the program (including their join date) they earn 2x points 
-- on all items, not just sushi - how many points do customer A and B have at the end of January?


WITH cte_rewards AS (
	SELECT s.customer_id, s.product_id, s.order_date, m.join_date, DATE_ADD(m.join_date, INTERVAL 7 DAY) as double_reward_expiry_date
	FROM sales s LEFT JOIN members m 
	ON s.customer_id = m.customer_id 
), 
cte_points AS (
	SELECT c.customer_id, 
		CASE WHEN c.order_date BETWEEN c.join_date AND c.double_reward_expiry_date THEN 2 * mu.price
		ELSE mu.price
		END AS points
	FROM cte_rewards c LEFT JOIN menu mu
	ON c.product_id = mu.product_id 
	WHERE c.order_date < '2021-02-01'
		AND customer_id IN ('A', 'B')
)
SELECT customer_id, SUM(points) as reward_points
FROM cte_points
GROUP BY customer_id;



-- |customer_id|reward_points|
-- |-----------|-------------|
-- |A          |127          |
-- |B          |84           |
