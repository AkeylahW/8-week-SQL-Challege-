--CREATE SCHEMA dannys_diner;

--SET search_path = dannys_diner;
CREATE TABLE sales (
  "customer_id" VARCHAR(1),
  "order_date" DATE,
  "product_id" INTEGER
);

INSERT INTO sales
  ("customer_id", "order_date", "product_id")
VALUES
  ('A', '2021-01-01', '1'),
  ('A', '2021-01-01', '2'),
  ('A', '2021-01-07', '2'),
  ('A', '2021-01-10', '3'),
  ('A', '2021-01-11', '3'),
  ('A', '2021-01-11', '3'),
  ('B', '2021-01-01', '2'),
  ('B', '2021-01-02', '2'),
  ('B', '2021-01-04', '1'),
  ('B', '2021-01-11', '1'),
  ('B', '2021-01-16', '3'),
  ('B', '2021-02-01', '3'),
  ('C', '2021-01-01', '3'),
  ('C', '2021-01-01', '3'),
  ('C', '2021-01-07', '3');
 

CREATE TABLE menu (
  "product_id" INTEGER,
  "product_name" VARCHAR(5),
  "price" INTEGER
);

INSERT INTO menu
  ("product_id", "product_name", "price")
VALUES
  ('1', 'sushi', '10'),
  ('2', 'curry', '15'),
  ('3', 'ramen', '12');
  

CREATE TABLE members (
  "customer_id" VARCHAR(1),
  "join_date" DATE
);

INSERT INTO members
  ("customer_id", "join_date")
VALUES
  ('A', '2021-01-07'),
  ('B', '2021-01-09');
  --Question 1: What is the total amount each customer spent at the restaurant?
  select customer_id
  ,Format (sum(price), '$,##') as 'total spent'
  from menu 
  inner join sales 
  on menu.product_id = sales.product_id
  group by customer_id
--Question 2: How many days has each customer visited the restaurant 
select distinct customer_id 
,count (distinct order_date) as "DaysVisted "
from sales 
group by customer_id 
 
--Question 3: What was the first item from the menu purchased by each customer 
 select distinct customer_id 
 ,menu.product_name
 ,order_date
 from sales 
 inner join menu 
 on menu.product_id = sales.product_id
 group by customer_id
 ,menu.product_name
 ,order_date
--Question 4:What is the most purchased item on the menu and
--how many times was it purchased by all customers? 

SELECT count (sales.product_id) as 'TimesPurchased'
,menu.product_name
from sales 
inner join menu
on menu.product_id = sales.product_id
group by menu.product_name
order by count (sales.product_id) desc 

--Question 5: Which item was the most popular for each customer?
select  distinct customer_id 
,menu.product_name 
,count(sales.product_id) as 'PopularItemFrequency'
from sales 
inner join menu 
on menu.product_id = sales.product_id
group by customer_id 
,menu.product_name
order by count(sales.product_id) desc 


--Question 6: Which item was purchased first by the customer after they became a memeber 

With Rank as
(
Select  S.customer_id,
        M.product_name,
	Dense_rank() OVER (Partition by S.Customer_id Order by S.Order_date) as Rank
From Sales S
Join Menu M
ON m.product_id = s.product_id
JOIN Members Mem
ON Mem.Customer_id = S.customer_id
Where S.order_date >= Mem.join_date  
)
Select *
From Rank
Where Rank = 1

with rank as 
(
  SELECT sales.customer_id
  ,menu.product_name,
  Dense_rank() over (Partition by sales.customer_id order by sales.order_date) as rank
  from sales 
  join menu 
  on menu.product_id = sales.product_id 
  join members 
  on members.customer_id = sales.customer_id 
  where sales.order_date >= members.join_date 
)
select * from rank 
where rank = 1

--Question 7 Which item was purchased just before the customer became a member?
with rank as 
(
  SELECT sales.customer_id
  ,menu.product_name,
  Dense_rank() over (Partition by sales.customer_id order by sales.order_date) as rank
  from sales 
  join menu 
  on menu.product_id = sales.product_id 
  join members 
  on members.customer_id = sales.customer_id 
  where sales.order_date < members.join_date 
)
select customer_id
,product_name
from rank 
where rank = 1

--Question 8 WHat is the total items and amount spent for each member before they became a member
SELECT sales.customer_id
,count (sales.customer_id) as 'totalitems '
  , format (sum( menu.price), '$,##')  as 'total spent '
  from sales 
  join menu 
  on menu.product_id = sales.product_id 
  join members 
  on members.customer_id = sales.customer_id 
  where sales.order_date < members.join_date 
  group by sales.customer_id
  
  -- Question 9 f each $1 spent equates to 10 points and sushi has a 2x points multiplier - 
  --how many points would each customer have?

with points as 
(
select *
,Case when product_id = 1 then price *20
else price *10
end as Points 
from menu 
)
Select sales.customer_id,
sum(P.points) as Points 
from sales 
Join Points p 
on p.product_id = sales.product_id 
group by sales.customer_id 

-- Question 10: In the first week after a customer joins the program (including their join date) they earn 2x points on all items, not just sushi - 
--how many points do customer A and B have at the end of January?
WITH dates_cte as 
(
  select *,
DATEADD ( day,6,join_date) as valid_date, 
EOMONTH ('2021-01-31') as last_date 
FROM members as m 

)
SELECT 
  d.customer_id, 
  s.order_date, 
  d.join_date, 
  d.valid_date, 
  d.last_date, 
  m.product_name, 
  m.price,
	SUM( 
    CASE WHEN m.product_name = 'sushi' THEN 2 * 10 * m.price
		WHEN s.order_date BETWEEN d.join_date AND d.valid_date THEN 2 * 10 * m.price
		ELSE 10 * m.price END) AS points
FROM dates_cte AS d
JOIN sales AS s
	ON d.customer_id = s.customer_id
JOIN menu AS m
	ON s.product_id = m.product_id
WHERE s.order_date < d.last_date
GROUP BY d.customer_id, s.order_date, d.join_date, d.valid_date, d.last_date, m.product_name, m.price

