-- 1. For each seller state, find the 3 sellers who earned the most revenue.

with seller_rev as (
	select s.seller_state, s.seller_id, SUM(oi.price+oi.freight_value) as revenue
	from order_items oi 
	join sellers s 
		on oi.seller_id = s.seller_id 
	group by 1, 2
),
ranked as (
	select *, 
		rank() over(partition by seller_state order by revenue desc ) as rank
	from seller_rev 
)
select seller_state , seller_id, round(revenue, 2) as revenue, rank 
from ranked 
where rank <=3
order by seller_state, rank; 

-- 2. For every customer, show the date of their first order and how many orders they placed in total.

with customer_orders as (
	select 
		c.customer_unique_id,
		MIN(o.order_purchase_timestamp::date ) over(partition by c.customer_unique_id) as first_order_date,
		count(*) over(partition by c.customer_unique_id) as total_orders,
		row_number() over(partition by c.customer_unique_id order by o.order_purchase_timestamp, o.order_id) as row_number
	from orders o
	join customers c
		on o.customer_id  = c.customer_id 
)
select 
	customer_unique_id, 
	 first_order_date,
	 total_orders
from customer_orders 
where "row_number" = 1
order by total_orders desc, 
	customer_unique_id;


-- 3. For each seller, show how their revenue accumulates over time, order by order.

with seller_order_revenue as (
	select
		oi.seller_id,
		oi.order_id,
		o.order_purchase_timestamp,
		SUM(oi.price + oi.freight_value ) as revenue
	from order_items oi 
	join orders o 
		on oi.order_id = o.order_id 
	group by 1, 2, 3
)
select 
	seller_id,
	order_id,
	order_purchase_timestamp,
	ROUND(revenue::numeric, 2) as order_revenue,
	ROUND(SUM(revenue) over(partition by seller_id
		order by order_purchase_timestamp, order_id
		rows between unbounded preceding 
			and current row
	)::numeric, 2) as running_revenue
from seller_order_revenue 
order by seller_id, order_purchase_timestamp, order_id

-- 4. Calculate what percentage of all money paid came from each payment type.
select * from order_payments;

select payment_type,
	SUM(payment_value) as total_paid,
	ROUND(SUM(payment_value) * 100.0
		/ SUM(SUM(payment_value )) over(), 1
	) as percentage_of_total
from order_payments
group by payment_type
order by total_paid desc;


-- 5. Find the order items whose price is higher than the average price in their product category.


with product_prices as (
	select
		oi.order_id,
		oi.product_id,
		p.product_category_name as category,
		oi.price,
		AVG(oi.price) OVER(partition by p.product_category_name) as category_average
	from order_items oi 
	join products p 
		on oi.product_id = p.product_id 
	where p.product_category_name is not null
)
select order_id,
	product_id,
	category,
	price,
	round(category_average::numeric , 2) as category_average
from product_prices
where price > category_average
order by category, price desc;



