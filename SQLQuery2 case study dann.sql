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


select * from sales;
select * from menu;
select * from members;


---1.What is the total amount each customer spent at the restaurant?
select s.customer_id, sum(m.price) as total_amount from 
sales as s
join menu as m on s.product_id=m.product_id
group by customer_id

--2.How many days has each customer visited the restaurant?
select customer_id, count(distinct order_date) as noofvisits
from sales
group by customer_id

--3.What was the first item from the menu purchased by each customer?
select * from sales;
select * from menu;

with cte as (
select s.customer_id,s.order_date,m.product_name,DENSE_RANK() over (partition by customer_id order by order_date) as rn 
from sales as s
join menu as m on s.product_id=m.product_id
)
select  distinct customer_id,product_name
from cte  where rn =1



---4.What is the most purchased item on the menu and how many times was it purchased by all customers?
select * from sales;
select * from menu;


select top 1 product_name, count(product_name)as  noofpurchase
from sales as s 
join menu as m on s.product_id=m.product_id
group by product_name
order by noofpurchase desc

--5.Which item was the most popular for each customer?

select customer_id,product_name from (
select customer_id,product_name, count(product_name) as c,DENSE_RANK() over (partition by customer_id order by count(product_name) desc ) as rn
from sales as s 
join menu as m on s.product_id=m.product_id
group by customer_id,product_name) as sn
where rn =1


---6.Which item was purchased first by the customer after they became a member?

select * from sales;
select * from menu;
select * from members;

 with cte as (select s.customer_id,s.order_date,s.product_id,m.product_name,m.price,ms.join_date
from sales as s
join menu as m on s.product_id=m.product_id
left join members as ms on s.customer_id=ms.customer_id
where s.order_date> ms.join_date
), cte2 as (
select * ,  DENSE_RANK() over (partition by customer_id order by order_date ) as rn from cte  )
select customer_id,product_name from cte2
where rn =1
group by customer_id,product_name;

---7.Which item was purchased just before the customer became a member?

with cte as (
select   s.customer_id,s.order_date,s.product_id,m.product_name,m.price,ms.join_date
from sales as s
join menu as m on s.product_id=m.product_id
left join members as ms on s.customer_id=ms.customer_id
where s.order_date<ms.join_date),
cte2 as (
select * , DENSE_RANK() over ( partition by customer_id  order by  order_date desc  ) as rn from cte )
select  distinct customer_id,product_name  from cte2
where  rn =1   


---8.What is the total items and amount spent for each member before they became a member?
with cte as (
select  s.customer_id,s.order_date,s.product_id,m.product_name,m.price,ms.join_date
from sales as s
join menu as m on s.product_id=m.product_id
left join members as ms on s.customer_id=ms.customer_id
where s.order_date<ms.join_date)
select customer_id,count(product_name) as totalitems,sum(price) as amountspent from  cte 
group by customer_id

--9.If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?

select * from sales;
select * from menu;

with cte as(
select s.customer_id,s.order_date,s.product_id,m.product_name,m.price,
case when product_name='sushi' then 2*10*price else 10* price end as point
from sales as s
join menu as m on s.product_id=m.product_id)
select customer_id,sum(point) as totalpoint  from cte 
group by customer_id

---10.In the first week after a customer joins the program (including their join date) they earn 2x points on all items,
--not just sushi - how many points do customer A and B have at the end of January?

with cte as (
select  s.customer_id,s.order_date,m.price,ms.join_date, DATEADD(DAY, 6, ms.join_date) AS valid_date,
  DATEADD(MONTH, DATEDIFF(MONTH, 0, '2021-01-31'), 0) AS last_date,
	sum(CASE
    WHEN m.product_name = 'sushi' THEN 2 * 10 * m.price
	WHEN s.order_date BETWEEN ms.join_date AND DATEADD(DAY, 6, ms.join_date) THEN 2 * 10 * m.price
    ELSE 10 * m.price  end)   as es
from sales as s
join menu as m on s.product_id=m.product_id
left join members as ms on s.customer_id=ms.customer_id
where s.order_date>=DATEADD(MONTH, DATEDIFF(MONTH, 0, '2021-01-31'), 0)
group by  s.customer_id,s.order_date,m.price,ms.join_date
)
select customer_id, sum(es)as totalpoint
from cte 
where customer_id ='A' OR customer_id ='B'
group by customer_id;

----use to quickly derive insights without needing to join the underlying tables using SQL.

select s.customer_id,s.order_date,m.product_name,m.price,
case when s.order_date<ms.join_date then 'N' 
WHEN S.order_date>=ms.join_date THEN 'Y' 
ELSE 'N' END AS Member
from sales as s
join menu as m on s.product_id=m.product_id
left join members as ms on s.customer_id=ms.customer_id


--
--Danny also requires further information about the ranking of customer products, but he purposely does not need the ranking for non-member purchases so he expects null ranking values for the records when customers are not yet part of the loyalty progra
with cte as (
select s.customer_id,s.order_date,m.product_name,m.price,
case when s.order_date<ms.join_date then 'N' 
WHEN S.order_date>=ms.join_date THEN 'Y' 
ELSE 'N' END AS Member
from sales as s
join menu as m on s.product_id=m.product_id
left join members as ms on s.customer_id=ms.customer_id)
select *,case when member='N' then null
else RANK() over (partition by customer_id,member order by order_date)  end as c
from cte

/*Insights
From the analysis, we discover a few interesting insights that would be certainly useful for Danny.

1.Customer B is the most frequent visitor with 6 visits in Jan 2021.
2.Danny’s Diner’s most popular item is ramen, followed by curry and sushi.
3.Customer A and C loves ramen whereas Customer B seems to enjoy sushi, curry and ramen equally. Who knows, I might be Customer B!
4.Customer A is the 1st member of Danny’s Diner and his first order is curry. Gotta fulfill his curry cravings!
5.The last item ordered by Customers A and B before they became members are sushi and curry. Does it mean both of these items are the deciding factor? It must be really delicious for them to sign up as members!
6.Before they became members, both Customers A and B spent $25 and $40.
7.Throughout Jan 2021, their points for Customer A: 860, Customer B: 940 and Customer C: 360.
8.Assuming that members can earn 2x a week from the day they became a member with bonus 2x points for sushi, Customer A has 660 points and Customer B has 340 by the end of Jan 2021.*/
	