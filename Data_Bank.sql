SET search_path = data_bank
--1 How many unique nodes are there on the Data Bank system?

select count(distinct node_id) from data_bank.customer_nodes

--2 What is the number of nodes per region?

select region_id, count(node_id) from data_bank.customer_nodes
group by region_id
order by region_id

--3 How many customers are allocated to each region?


select region_id, count(customer_id) from customer_nodes
group by region_id

--4 How many days on average are customers reallocated to a different node?

with temp as (
select *, end_date - start_date as diff, 
row_number()over(partition by customer_id order by start_date) as rn from customer_nodes
),
diff_table as (
select customer_id, node_id,sum(diff) as su  from temp
where rn<7
group by customer_id, node_id)

select customer_id, round(avg(su),2) from diff_table
group by 1
order by 1 

--5 What is the median, 80th and 95th percentile for this same reallocation days metric for each region?
-- hmm

--6 What is the unique count and total amount for each transaction type?
select * from data_bank.customer_transactions

select distinct txn_type,count(*), sum(txn_amount) as total
from customer_transactions
group by txn_type

--7 What is the average total historical deposit counts and amounts for all customers?
with temp as (
select *, dense_rank()over(partition by customer_id order by txn_type) as dk from customer_transactions
)
select round(avg(txn_amount),2) from temp 
where dk =1

--8 For each month - how many Data Bank customers make more than 1 deposit and either 1 purchase or 1 withdrawal in a single month?

WITH monthly_transactions AS (
  SELECT 
    customer_id, 
    DATE_PART('month', txn_date) AS month,
    SUM(CASE WHEN txn_type = 'deposit' THEN 0 ELSE 1 END) AS deposit_count,
    SUM(CASE WHEN txn_type = 'purchase' THEN 0 ELSE 1 END) AS purchase_count,
    SUM(CASE WHEN txn_type = 'withdrawal' THEN 1 ELSE 0 END) AS withdrawal_count
  FROM data_bank.customer_transactions
  GROUP BY customer_id, month
 )

SELECT
  month,
  COUNT(DISTINCT customer_id) AS customer_count
FROM monthly_transactions
WHERE deposit_count >= 2 
  AND (purchase_count > 1 OR withdrawal_count > 1)
GROUP BY month
ORDER BY month;


