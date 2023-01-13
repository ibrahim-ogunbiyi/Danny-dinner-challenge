-- Case Study Query

/* Question 1. What is the total amount each customer spent at the restaurant? */
SELECT 
	customer_id,
	SUM(price) AS total_amount
FROM sales
INNER JOIN menu
USING (product_id)
GROUP BY customer_id;

/* Question 2. How many days has each customer visited the restaurant? */


SELECT 
	customer_id,
	COUNT(order_date) AS no_of_days
FROM sales
GROUP BY customer_id;

/* Question 3. What was the first item from the menu purchased by each customer? */

SELECT 
	customer_id,
	FIRST_VALUE(product_name) OVER(PARTITION BY customer_id ORDER BY order_date) As first_item_purchased
FROM sales
INNER JOIN menu
USING (product_id);

/* Question 4. What is the most purchased item on the menu and how many times was it purchased by all customers? */

SELECT 
	product_name,
	COUNT(*) AS no_of_purchased
FROM sales
INNER JOIN menu
USING (product_id)
GROUP BY product_name
ORDER BY no_of_purchased DESC
LIMIT 1;

/* Question 5. Which item was the most popular for each customer? */

WITH result AS(
SELECT
	customer_id,
	product_name,
	COUNT(*),
	ROW_NUMBER()OVER(PARTITION BY customer_id ORDER BY COUNT(*) DESC)
FROM sales
INNER JOIN menu
USING (product_id)
GROUP BY customer_id, product_name)

SELECT 
	*
FROM result
WHERE row_number = 1;

/* Question 6. Which item was purchased first by the customer after they became a member? */

WITH result AS (
SELECT 
	customer_id,
	product_name,
	ROW_NUMBER() OVER(PARTITION BY customer_id ORDER BY order_date)
FROM sales
INNER JOIN menu
USING (product_id)
INNER JOIN members
USING(customer_id)
WHERE order_date > join_date 
)

SELECT
	*
FROM result
WHERE row_number = 1;


/* Question 7. Which item was purchased just before the customer became a member? */

WITH result AS 
(SELECT 
	customer_id,
	product_name,
	ROW_NUMBER()OVER(PARTITION BY customer_id ORDER BY order_date DESC) AS rn
FROM sales
INNER JOIN menu
USING(product_id)
INNER JOIN members
USING(customer_id)
WHERE order_date < join_date
)

SELECT *
FROM result 
where rn = 1;


/* Question 8. What is the total items and amount spent for each member before they became a member? */
SELECT 
	customer_id,
	COUNT(product_id) AS total_items,
	SUM(price) AS total_amount
FROM sales
INNER JOIN menu
USING (product_id)
INNER JOIN members 
USING(customer_id)
WHERE order_date < join_date
GROUP BY customer_id;


/* Question 9. If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have? */

SELECT
	customer_id,
	SUM(CASE WHEN product_name = 'sushi' THEN price * 20
	ELSE price * 10 END) AS points
FROM sales
INNER JOIN menu
USING (product_id)
GROUP BY customer_id
ORDER BY points DESC;

/* Question 10. In the first week after a customer joins the program (including their join date) they earn 2x points on all items, not just sushi - how many points do customer A and B have at the end of January? */
SELECT
	customer_id,
	SUM(CASE WHEN order_date BETWEEN join_date AND join_date::Date + 6 THEN price * 2 ELSE price END) AS points
FROM sales
INNER JOIN members 
USING(customer_id)
INNER JOIN menu
USING(product_id)
WHERE order_date BETWEEN '2021-01-01' AND '2021-01-31'
GROUP BY customer_id
ORDER BY points;

/* Bonus Question */


SELECT 
	customer_id,
	order_date,
	product_name,
	price,
	CASE WHEN order_date < join_date THEN 'N' ELSE 'Y' END members
FROM sales
INNER JOIN menu
USING(product_id)
LEFT JOIN members
USING(customer_id)
ORDER BY customer_id, order_date;

/* Bonus Question 2 */
WITH result AS(
SELECT 
	customer_id,
	order_date,
	product_name,
	price,
	CASE WHEN order_date < join_date THEN 'N' 
		WHEN order_date >= join_date THEN 'Y' END members
FROM sales
INNER JOIN menu
USING(product_id)
LEFT JOIN members
USING(customer_id)
ORDER BY customer_id, order_date)

SELECT 
	*,
	CASE WHEN members = 'Y' THEN DENSE_RANK()OVER(PARTITION BY customer_id, members ORDER BY order_date)
	ELSE NULL END ranking
FROM result;
