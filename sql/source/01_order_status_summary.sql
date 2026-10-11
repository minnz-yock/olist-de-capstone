-- 1.How many customers are there in each state? Show the top 5 state?

select 
	count(*) as customers, 
	customer_state
from customers
group by customer_state
order by customers desc 
limit 5;


-- 2.How many distinct real customers (customer_unique_id) are there?


select 
	count(distinct customer_unique_id) as distinct_customers
from customers;

-- 3.Which payment_type is used most, and what is its total payment_value?

select 
	payment_type, 
	count(*) payment, 
	sum(payment_value)
from order_payments
group by payment_type;


-- 4.How many reviews are there for each review_score (1 to 5)? What is the overall average score?

select * from order_reviews;

select 
	review_score,
	count(*) as review_count
from order_reviews
group by review_score
order by review_score;

select 
	round(avg(review_score), 2) as overall_avg_score
from order_reviews;



-- 5.Sellers by state: which states have more than 50 sellers?

select * from sellers;

select
	count(*) as seller_count,
	seller_state
from sellers 
group by seller_state
having count(*) > 50;

	

-- 6.Average price and freight per order item, rounded to 2 decimals.


select * from order_items;

select
    round(avg(price), 2) as avg_price,
    round(avg(freight_value), 2) as avg_freight
from order_items;

