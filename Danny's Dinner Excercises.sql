/*      Case Study #1 - Danny's Diner

		       Case Study Questions
        
Each of the following case study questions can be 
answered using a single SQL statement:

1 - What is the total amount each customer spent at the restaurant?   */

SELECT customer_id AS Customer, sum(price) AS 'Total Amount'
FROM sales
JOIN menu USING (product_id)
GROUP BY Customer;


/* 2 - How many days has each customer visited the restaurant?  */

SELECT customer_id AS Customer, COUNT(DISTINCT order_date) AS 'Days Visited'  FROM sales
GROUP BY customer_id;

/*   3 - What was the first item from the menu purchased by each customer? */

SELECT customer_id AS customer, 
GROUP_CONCAT(DISTINCT product_name SEPARATOR ', ')
AS first_item, 
order_date
FROM sales
JOIN menu USING (product_id)
WHERE order_date = '2021-01-01'
GROUP BY customer_id 
ORDER BY customer_id ASC;


/* 4 - What is the most purchased item on the menu and
 how many times was it purchased by all customers?  */


SELECT product_name AS most_purchased_item, COUNT(*) AS frequency
FROM sales
JOIN menu USING (product_id)
GROUP BY product_name
ORDER BY frequency DESC
LIMIT 1;


/* 5 - Which item was the most popular for each customer?  */

SELECT 
	   customer_id,
       GROUP_CONCAT(product_name ORDER BY product_name SEPARATOR ', ') AS most_purchased_items,
       MAX(frequency) AS frequency
FROM (
    SELECT 
		   s.customer_id,
           m.product_name,
           COUNT(*) AS frequency,
           RANK() OVER (PARTITION BY s.customer_id ORDER BY COUNT(*) DESC) AS rnk
    FROM sales s
    JOIN menu m ON s.product_id = m.product_id
    GROUP BY s.customer_id, m.product_name
) AS ranked
WHERE rnk = 1
GROUP BY customer_id;


/* 6 - Which item was purchased first by the customer after they became a member? */

WITH ranked_sales AS(
	SELECT 
		s.customer_id, 
		s.order_date, 
		m.product_name, 
		ROW_NUMBER () OVER (PARTITION BY s.customer_id
		ORDER BY s.order_date ASC) AS rnk # row number per customer
	FROM sales s
	JOIN menu m ON (s.product_id = m.product_id)
	JOIN members mb ON (s.customer_id = mb.customer_id)
	WHERE s.order_date > mb.join_date
)
SELECT customer_id, order_date, product_name, rnk
FROM ranked_sales
WHERE rnk = 1 # filter only the first purchase per customer after they became a member
ORDER BY customer_id;

/* 7 - Which item was purchased just before the customer became a member? */

WITH just_before_item AS(
	SELECT s.customer_id, m.product_name, order_date,
    RANK () OVER (PARTITION BY s.customer_id ORDER BY s.order_date DESC) AS rnk
	FROM sales s
	JOIN menu m ON (s.product_id = m.product_id)
	JOIN members mb ON (s.customer_id = mb.customer_id)
    WHERE s.order_date < mb.join_date
	ORDER BY customer_id
)
SELECT 
	customer_id, 
    GROUP_CONCAT(DISTINCT product_name ORDER BY  product_name  SEPARATOR ', ') AS product_name,
    MAX(order_date) AS order_date
    FROM just_before_item
    WHERE rnk = 1
	GROUP BY  customer_id
    ORDER BY  customer_id;
    
/* What is the total items and amount spent 
for each member before they became a member? */
    
	SELECT 
			s.customer_id, 
            COUNT(*) AS total_items,
            SUM(m.price) AS amount_spent
	FROM sales s
	JOIN menu m USING(product_id)
	JOIN members mb USING(customer_id)
	WHERE s.order_date < mb.join_date
	GROUP BY s.customer_id
	ORDER BY s.customer_id;
    
/* 9 - If each $1 spent equates to
10 points and sushi has a 2x points multiplier - 
how many points would each customer have? */

SELECT s.customer_id, 
SUM(CASE 
WHEN m.product_name = 'sushi' THEN (price*20)
ELSE
m.price*10 END) AS points
FROM sales s
JOIN menu m USING(product_id)
GROUP BY customer_id;

/* 10 - In the first week after a customer joins the program 
(including their join date) 
they earn 2x points on all items, not just sushi -
 how many points do customer A and B have at the end of January? */

SELECT customer_id, SUM(points) AS total_points
FROM(
	SELECT 
	s.customer_id, 
	SUM(CASE WHEN m.product_name = 'sushi' 
			 THEN (m.price*20)
	         ELSE (m.price*10) END) AS points
	FROM sales s
	JOIN menu m USING(product_id)
	JOIN members mb USING(customer_id)
	WHERE s.order_date < mb.join_date
	GROUP BY s.customer_id


	UNION ALL

	SELECT s.customer_id, SUM(price*20) AS points
	FROM sales s
	JOIN menu m USING(product_id)
	JOIN members mb USING(customer_id)
	WHERE s.order_date >= join_date AND order_date <= DATE_ADD(mb.join_date, INTERVAL 7 DAY)
	GROUP BY s.customer_id
)sub

GROUP BY customer_id
ORDER BY customer_id;


/* BONUS QUESTIONS - Join All The Things */

SELECT 
s.customer_id, 
s.order_date,
m.product_name,
m.price,
(CASE
	WHEN  (s.order_date >= mb.join_date) 
    THEN 'Y'
    ELSE 'N'
    END  ) AS members
FROM sales s
JOIN menu m USING (product_id)
LEFT JOIN members mb USING (customer_id)
ORDER BY s.customer_id, s.order_date;


/* BONUS QUESTIONS - Rank All The Things */
SELECT 
    s.customer_id, 
    s.order_date,
    m.product_name,
    m.price,
    CASE
        WHEN s.order_date >= mb.join_date THEN 'Y'
        ELSE 'N'
    END AS member,
    r.rnk AS ranking
FROM sales s
JOIN menu m USING (product_id)
LEFT JOIN members mb USING (customer_id)
LEFT JOIN (
    SELECT 
        s.customer_id,
        s.order_date,
        s.product_id,
        RANK() OVER (
            PARTITION BY s.customer_id 
            ORDER BY s.order_date
        ) AS rnk
    FROM sales s
    JOIN menu m USING (product_id)
    LEFT JOIN members mb USING (customer_id)
    WHERE s.order_date >= mb.join_date
) r
ON r.customer_id = s.customer_id
AND r.order_date = s.order_date
AND r.product_id = s.product_id
ORDER BY s.customer_id, s.order_date;


SELECT customer_id, date_format(order_date,"%d/%m/%Y")
FROM sales;



DELIMITER $$

CREATE FUNCTION func_format_data(data_X DATETIME)
RETURNS CHAR(20)
DETERMINISTIC

BEGIN
	
    RETURN date_format(data_x,'%d/%m/%Y');

END $$

DELIMITER ;


SELECT customer_id, func_format_data(order_date) AS formatted_data
FROM sales;











