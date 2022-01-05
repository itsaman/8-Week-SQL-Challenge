select * from plans;
select * from subscriptions;

--customer journey

select s.customer_id, p.plan_id, p.plan_name, s.start_date
from plans p 
inner join subscriptions s
on p.plan_id = s.plan_id
where s.customer_id in (1,2,3,4,5,6,7,8)

--1 How many customers has Foodie-Fi ever had?
select count(distinct customer_id) from subscriptions --1000

--2 What is the monthly distribution of trial plan start_date values for our dataset 
--Question is asking for the monthly numbers of users on trial plan.
select * from  subscriptions;

with temp as (
select *, dense_rank()over(order by datepart(month,start_date)) as dk from subscriptions
where plan_id =0
)
select datepart(month,start_date) as months,datename(month,start_date) as month_name , count(dk) as users from temp
group by datepart(month,start_date), datename(month,start_date)
order by months

--3  What plan start_date values occur after the year 2020 for our dataset? 
--Show the breakdown by count of events for each plan_name.

with temp1 as( 
    select p.plan_id, p.plan_name, count(start_date) as events_2020
    from subscriptions s 
    inner join plans p
    on s.plan_id = p.plan_id
where datepart(year, start_date) = '2020'
group by p.plan_id, p.plan_name),
temp2 as (
    select p.plan_id, p.plan_name, count(start_date) as events_2020
    from subscriptions s 
    inner join plans p
    on s.plan_id = p.plan_id
    where datepart(year, start_date) = '2021'
    group by p.plan_id, p.plan_name
    )

select t.plan_id, t.plan_name, t.events_2020, isnull(t2.events_2020,0) as events_2021
from temp1 t
left join temp2 t2
on t.plan_id = t2.plan_id
order by plan_id asc


--4
--What is the customer count and percentage of customers who have churned rounded to 1 decimal place?

select count(*) as churn, 
       round(count(*)*100/(select count(distinct customer_id) from subscriptions),1) as "%churn"
from subscriptions s 
inner join plans p
on s.plan_id = p.plan_id
where plan_name = 'churn'
group by p.plan_name;


--5 How many customers have churned straight after their initial free trial 
--what percentage is this rounded to the nearest whole number?

with temp as (
    select customer_id, start_date,
    count(customer_id)over(partition by customer_id) as ck
    from subscriptions s
    where plan_id = '0' or plan_id = '4'
),
temp2 as (
    select customer_id, start_date,
    lag(start_date)over(partition by customer_id order by customer_id) as dk
    from temp
    where temp.ck>=2 
),
temp3 as (
    select customer_id, start_date, dk 
    from temp2 
    where dk is not null and DATEDIFF(day,dk, start_date) = 7
)

select count(customer_id) as churn_count, 
       (count(customer_id)*100/(select count(distinct customer_id) from subscriptions)) as churn_percentage
from temp3

--6 What is the number and percentage of customer plans after their initial free trial?

with temp as (
    select s.customer_id, p.plan_id as pid, p.plan_name as pname, s.start_date,
    row_number()OVER(partition by customer_id order by p.plan_id) as ranking
    from subscriptions s
    inner join plans p
    on p.plan_id = s.plan_id
)
select pid as next_plan,count(customer_id) as conversion ,round((count(customer_id)*100)/(select count(distinct customer_id) from subscriptions),1) as per  from temp
where pid = '1' and ranking = '2'
group by pid
union all
select pid as next_plan,count(customer_id) as conversion ,round((count(customer_id)*100)/(select count(distinct customer_id) from subscriptions),1) as per  from temp
where pid = '2' and ranking = '2'
group by pid
union all
select pid as next_plan,count(customer_id) as conversion ,round((count(customer_id)*100)/(select count(distinct customer_id) from subscriptions),1) as per  from temp
where pid = '3' and ranking = '2'
group by pid
UNION all
select pid as next_plan,count(customer_id) as conversion ,round((count(customer_id)*100)/(select count(distinct customer_id) from subscriptions),1) as per  from temp
where pid = '4' and ranking = '2'
group by pid;

--7 What is the customer count and percentage breakdown of all 5 plan_name values at 2020-12-31?


--8 How many customers have upgraded to an annual plan in 2020?
with temp as (
select s.customer_id, p.plan_id as pid, p.plan_name as pname, s.start_date,
row_number()OVER(partition by customer_id order by p.plan_id) as ranking
from subscriptions s
inner join plans p
on p.plan_id = s.plan_id
where year(start_date) = '2020' and p.plan_id = '3'
)
select count(distinct customer_id) as annual_plan_user from temp
