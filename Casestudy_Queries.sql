-- 1. What is the total amount each customer spent at the restaurant?

SELECT s.customer_id, sum(m.price) as total_amount
FROM menu m
INNER JOIN sales s on m.product_id = s.product_id
GROUP BY sales.customer_id;

-- 2. How many days has each customer visited the restaurant?
SELECT customer_id, count(distinct order_date) as visit_count
FROM sales
GROUP BY customer_id;

-- 3. What was the first item from the menu purchased by each customer?
with cte as(
SELECT s.customer_id, s.order_date, m.product_name, rank() over(partition by s.customer_id order by s.order_date asc) as rnk
FROM sales s join menu m 
ON s.product_id=m.product_id)
select customer_id, product_name from cte
where rnk = 1
group by customer_id, product_name;


-- 4. What is the most purchased item on the menu and how many times was it purchased by all customers?

select top 1
m.product_name, count(*) as most_purchased
from sales s join menu m 
on s.product_id = m.product_id 
group by m.product_name
order by most_purchased desc;




-- 5. Which item was the most popular for each customer?

select s.customer_id, m.product_name, count(m.product_name) as order_count
FROM sales s join menu m 
ON s.product_id = m.product_id 
group by s.customer_id, m.product_name
order by order_count desc;




-- 6. Which item was purchased first by the customer after they became a member?

with cte as
(
select s.customer_id, order_date, join_date, m.product_name, rank() over(partition by s.customer_id order by order_date) as rnk
from sales s
join members mem on s.customer_id = mem.customer_id
join menu m on s.product_id = m.product_id
where order_date > = join_date)
select customer_id, product_name
from cte
where rnk = 1;



-- 7. Which item was purchased just before the customer became a member?
with cte as
(
select s.customer_id, order_date, join_date, m.product_name, rank() over(partition by s.customer_id order by order_date desc) as rnk
from sales s
join members mem on s.customer_id = mem.customer_id
join menu m on s.product_id = m.product_id
where order_date < join_date)
select customer_id, product_name
from cte
where rnk = 1;


-- 8. What is the total items and amount spent for each customer before they became a member?

select s.customer_id, count(product_name) as total_items, sum(price) as amount_spent
from sales s 
join menu m on s.product_id = m.product_id
join members mem on s.customer_id = mem.customer_id
where order_date < join_date
group by s.customer_id;


-- 9.  If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?

select 
customer_id,
	sum(CASE 
			when product_name = 'sushi' then price * 10 * 2
			else price * 10
			end
		) as points
from menu m
join sales s on m.product_id = s.product_id
group by customer_id;



-- 10. In the first week after a customer joins the program (including their join date) they earn 2x points on all items, not just sushi - how many points do customer A and B have at the end of January?


with cust_details as(
	select 
		s.customer_id, 
		order_date, 
		join_date, 
		product_name, 
		s.product_id, 
		DATEADD(DAY, 6, join_date) as first_week_of_join_date, 
		m.price
	from sales s join menu m 
	on s.product_id = m.product_id join members mem 
	on s.customer_id = mem.customer_id
)
select 
	customer_id, 
	sum(
		case 
			when product_name = 'sushi' or order_date between join_date and first_week_of_join_date then 20*price
			else 10*price 
			end
	    ) as points
from cust_details
where month(order_date) = 1
group by customer_id
order by customer_id;


