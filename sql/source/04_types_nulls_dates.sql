-- 1. NULL audit: count NULLs in product_category_name and product_weight_g.

select 
	count(case 
		when product_category_name is null then 1
	end) as null_category_count,
	count(case 
		when product_weight_g is null then 1
	end) as null_category_count
from products ;



-- 2. For each month of purchase, what is the average delivery time, and how many orders (and what percentage) were delivered within 30 days of purchase?

with delivery as (
	select order_id,
		date_trunc('month', order_purchase_timestamp) as purchase_month,
		extract(epoch from(order_delivered_customer_date - order_purchase_timestamp)) / 86400.0 as delivery_days
	from orders 
	where order_delivered_customer_date is not null
),
orders_within_30_days as (
	select purchase_month,
		count (*) as orders_within_30_days
	from delivery
	where delivery_days <= 30
	group by purchase_month
)
select d.purchase_month,
	round(avg(d.delivery_days)::numeric, 2) as average_delivery_days,
	coalesce(MAX(o.orders_within_30_days), 0) as orders_within_30_days,
	round(coalesce(MAX(o.orders_within_30_days), 0) * 100 / count(*), 2) as percentage_within_30_days
from delivery d
left join orders_within_30_days o
	on d.purchase_month = o.purchase_month
group by d.purchase_month
order by d.purchase_month;

select count(*) from delivery -- 96476

select * from orders



-- 3. On which day of the week do customers place the most orders? Show each weekday's name and number, and the total orders for that day, sorted from busiest to quietest.

select 
	to_char(order_purchase_timestamp, 'FMDay') as weekday_name,
	extract(dow from order_purchase_timestamp) as weekday_number,
	count(*) as total_orders
from orders
group by 1, 2
order by total_orders desc;



-- 4. What is the total revenue for each product category, shown with its English name? If a category has no English translation, show the original Portuguese name instead. If the product has no category at all, show it as 'unknown'.

select 
	coalesce(
		ct.product_category_name_english,
		p.product_category_name,
		'unknown'
	) as product_category,
	SUM(oi.price) as total_revenue
from order_items oi 
join products p 
	on p.product_id = oi.product_id 
left join category_translation ct 
	on ct.product_category_name = p.product_category_name 
group by 1
order by total_revenue desc;


 
-- 5. Group delivered orders by delivery speed:
--     Fast: 7 days or less from purchase to delivery.
--     Normal: 8 to 14 days.
--     Slow: 15 to 30 days.
--     Very slow: more than 30 days.
--     How many orders fall into each group, and what percentage of the total is each?

with delivery_days as(
	select order_id,
		extract(epoch from(order_delivered_customer_date - order_purchase_timestamp)) / 86400.0 as delivery_days
	from orders
	where order_delivered_customer_date is not null
),
speed_groups as(
	select 
		case
			when delivery_days <= 7 then 'Fast'
			when delivery_days <= 14 then 'Normal'
			when delivery_days <= 30 then 'Slow'
			else 'Very slow'
		end as delivery_speed
	from delivery_days
),
speed_counts as(
	select delivery_speed,
		count(*) as total_orders
	from speed_groups
	group by delivery_speed
)
select delivery_speed,
	total_orders,
	round(total_orders * 100 / sum(total_orders) over(), 2) as percentage
from speed_counts
order by
	case delivery_speed
		when 'Fast' then 1
		when 'Normal' then 2
		when 'Slow' then 3
		when 'Very slow' then 4
	end;





