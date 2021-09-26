USE case_study;

-- 1. What is the total amount each customer spent at the restaurant?

SELECT s.customer_id, SUM(m.price) 
FROM sales s LEFT JOIN menu m
ON s.product_id = m.product_id
GROUP BY s.customer_id;

-- How many days has each customer visited the restaurant?

SELECT customer_id, COUNT(DISTINCT order_date) as days_visited
FROM sales 
GROUP BY customer_id;


-- What was the first item from the menu purchased by each customer?

WITH sales_new AS(
	SELECT  s.customer_id,
			m.product_name,
            ROW_NUMBER() OVER (PARTITION BY s.customer_id ORDER BY s.order_date) as ORDER_RANK
	FROM sales s LEFT JOIN menu m
    ON s.product_id = m.product_id
)
SELECT customer_id, product_name
FROM sales_new
WHERE order_rank=1;