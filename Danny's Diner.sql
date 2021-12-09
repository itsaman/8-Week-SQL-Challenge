--Case#1 Danny's Diner

--1 What is the total amount each customer spent at the restaurant?
select s.customer_id, sum(m.price) as amount_spent
from sales s
inner join menu m
on s.product_id = m.product_id
group by s.customer_id

--2 How many days has each customer visited the restaurant?
select customer_id, count(distinct order_date) as days_visited
from sales 
group by customer_id 

--3 What was the first item from the menu purchased by each customer?
select distinct customer_id,order_date,product_name
from(
select 
    product_name,
    price,customer_id,
    order_date, 
    mu.product_id,
    dense_rank()over(partition by customer_id order by order_date asc) as rn
from menu mu
inner join sales sa
on mu.product_id = sa.product_id) temp
where temp.rn =1

--4 the most purchased item on the menu and how many times was it purchased by all customers?
select distinct 
    sa.customer_id, 
    mu.product_name, 
    count(mu.product_id) as total 
from sales sa
inner join menu mu 
on sa.product_id = mu.product_id
group by sa.customer_id, mu.product_name
order by total desc

select distinct mu.product_id, mu.product_name, sa.customer_id,
count(mu.product_id)over(partition by customer_id,product_name) as rn
from menu mu
inner join sales sa
on mu.product_id = sa.product_id
order by rn desc

--5 Which item was the most popular for each customer?
WITH fav_item_cte AS
(
	SELECT 
    s.customer_id, 
    m.product_name, 
    COUNT(m.product_id) AS order_count,
		DENSE_RANK() OVER(PARTITION BY s.customer_id ORDER BY COUNT(s.customer_id) DESC) AS rank
FROM dbo.menu AS m
JOIN dbo.sales AS s
	ON m.product_id = s.product_id
GROUP BY s.customer_id, m.product_name
)

SELECT 
  customer_id, 
  product_name, 
  order_count
FROM fav_item_cte 
WHERE rank = 1;

--6 Which item was purchased first by the customer after they became a member?
with temp as (
select distinct
     m.customer_id as c_id, 
     m.join_date as j_date,
     s.order_date as o_date,
     s.product_id as p_id,
     mn.product_name as p_name,
     dense_rank()over(partition by m.customer_id order by order_date asc) as rn 
from members m
inner join sales s
on m.customer_id = s.customer_id
inner join menu mn
on s.product_id = mn.product_id 
where m.join_date < order_date )

select c_id, j_date, o_date, p_id, p_name
from temp 
where temp.rn =1

--7 Which item was purchased just before the customer became a member? 
with temp as (
select distinct
     m.customer_id as c_id, 
     m.join_date as j_date,
     s.order_date as o_date,
     s.product_id as p_id,
     mn.product_name as p_name,
     dense_rank()over(partition by m.customer_id order by order_date desc) as rn 
from members m
inner join sales s
on m.customer_id = s.customer_id
inner join menu mn
on s.product_id = mn.product_id 
where m.join_date > order_date )

select c_id, j_date, o_date, p_id, p_name
from temp 
where temp.rn =1 


--8 What is the total items and amount spent for each member before they became a member?
select distinct  
     m.customer_id as c_id, 
     count(distinct s.product_id) as unique_items,
     sum(mn.price)
from members m
inner join sales s
    on m.customer_id = s.customer_id
inner join menu mn
    on s.product_id = mn.product_id 
where m.join_date > order_date
group by  m.customer_id;


--9 If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?
with temp as(
select m.product_id, m.product_name,m.price, s.customer_id as c_id, s.order_date,
case when product_name = 'sushi' then price*20 
     when product_name = 'curry' or product_name = 'ramen' then price*10
end as "new_price"
from menu m
inner join sales s
on m.product_id = s.product_id)

select distinct temp.c_id,
sum(temp.new_price)over(partition by temp.c_id) as rn
from temp; 

/*
 10. In the first week after a customer joins the program (including their join date) 
 they earn 2x points on all items,not just sushi - 
 how many points do customer A and B have at the end of January?
*/
with temp as (
select mb.customer_id as c_id, mb.join_date, sl.order_date as o_date, mu.product_name,mu.price,
case when order_date between join_date and DATEADD(week,1,join_date) then price*20
    when order_date not between join_date and DATEADD(week,1,join_date) then (
        case when product_name = 'sushi' then price*20 
        when product_name = 'curry' or product_name = 'ramen' then price*10 end 
    )
end as 'new_price'
from members mb
join sales sl
on mb.customer_id = sl.customer_id
join menu mu
on sl.product_id = mu.product_id)

select c_id,
sum(temp.new_price) as total_points
from temp
where temp.o_date between '2021-01-01' and '2021-01-31'
group by c_id;


----------------------Bonus Questions--------------------------------
--1
select sa.customer_id,
       sa.order_date,
       mu.product_name,
       mu.price,
       case when order_date >= join_date then 'Y' else 'N' end as Member
from sales sa
left join members mb
on sa.customer_id = mb.customer_id
inner join menu mu
on sa.product_id = mu.product_id;


--2
with temp as(
select sa.customer_id as c_id,
       sa.order_date as o_date,
       mu.product_name as p_name,
       mu.price as amount,
       case when order_date >= join_date then 'Y' else 'N' end as Member
from sales sa
left join members mb
on sa.customer_id = mb.customer_id
inner join menu mu
on sa.product_id = mu.product_id)

select *,
    case when temp.member = 'N' then Null
    else rank()over(partition by c_id, member order by o_date) end as ranking
from temp;
