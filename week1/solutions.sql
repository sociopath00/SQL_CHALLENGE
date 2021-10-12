# Problem 1
# What is the total amount each customer spent at the restaurant?

SELECT s.customer_id, SUM(m.price) as total_spent
FROM sales s LEFT JOIN menu m
ON s.product_id = m.product_id 
GROUP BY s.customer_id ;

# output
# |customer_id|total_spent|
# |-----------|-----------|
# |A          |76         |
# |B          |74         |
# |C          |36         |



# Problem 2
# How many days has each customer visited the restaurant?

SELECT customer_id, COUNT(DISTINCT order_date) as no_of_days_visited
FROM sales
GROUP BY customer_id;


# Problem 3
# What was the first item from the menu purchased by each customer?

WITH cte_customer AS(
	SELECT customer_id, product_id, ROW_NUMBER() OVER(PARTITION BY customer_id ORDER BY order_date) as ranks
	FROM sales
)
SELECT s.customer_id, m.product_name
FROM cte_customer s LEFT JOIN menu m
ON s.product_id = m.product_id 
WHERE ranks = 1;
