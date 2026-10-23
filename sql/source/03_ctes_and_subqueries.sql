-- 1. Rewrite last week's Q5 (revenue vs payments per order) using two CTEs.
-- Q5.For 5 orders, show item revenue and payment total side by side — without fan-out.

with revenue as (
	select order_id, SUM(price + freight_value) as revenue
	from order_items oi 
	group by order_id
), 
payment as (
	select order_id, SUM(payment_value) as paid
	from order_payments op
	group by order_id
)
select r.order_id, revenue, paid
from revenue r
left join payment p 
	on p.order_id = r.order_id
limit 5;


-- 3. Sellers with no 1-star reviews at all — use NOT EXISTS.

select count(1) from sellers s where seller_id not in (
	select seller_id from order_items oi 
	join order_reviews t 
	on oi.order_id = t.order_id
	where t.review_score = 1
)

select count(1) from sellers s where not exists (
	select 1 from order_items oi
	join order_reviews r
	on oi.order_id = r.order_id 
	where oi.seller_id = s.seller_id and r.review_score = 1
	
)

-- 4. Monthly revenue for delivered orders.

with delivered_orders as (
	select order_id, 
		date_trunc('month', o.order_purchase_timestamp) as order_month
	from orders o
	where o.order_status = 'delivered'
),
order_revenue as(
	select order_id,
		SUM(op.payment_value) as revenue
	from order_payments op 
	group by op.order_id 
)
select d.order_month,
	count(*) as delivered_orders,
	round(sum(r.revenue), 2) as revenue
from delivered_orders d
join order_revenue r
	on d.order_id = r.order_id
group by d.order_month 
order by d.order_month;


-- 5. For each month, which product category earned the most delivered revenue?

with monthly as (
	select date_trunc('month', o.order_purchase_timestamp) as month,
		p.product_category_name as category,
		sum(oi.price + oi.freight_value) as revenue
	from orders o
	join order_items oi 
		on o.order_id = oi.order_id 
	join products p 
		on oi.product_id = p.product_id
	where o.order_status = 'delivered'
	group by 1, 2
),
monthly_max as (
	select month, 
		max(revenue) as top_revenue
	from monthly
	group by month
	order by month
)

select m.month, m.category, m.revenue
from monthly m
join monthly_max x
	on m.month = x.month
	and m.revenue = x.top_revenue
order by m.month;



