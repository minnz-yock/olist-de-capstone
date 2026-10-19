


-- 1. Revenue (SUM of price) by customer_state for delivered orders. Top 10 states.


select customer_state, SUM(price) as revenue
from orders o
inner join customers c
	on o.customer_id = c.customer_id
inner join order_items oi 
	on o.order_id = oi.order_id
where o.order_status = 'delivered'
group by customer_state 
order by revenue desc
limit 10;

-- 2. How many orders have no review at all? (anti-join)

select count(*) as without_review 
from orders o
left join order_reviews r 
	on o.order_id = r.order_id 
where r.order_id is null;

-- 3. Top 10 product categories in English by items sold. Why LEFT JOIN to the translation?

select
	ct.product_category_name_english, 
	COUNT(oi.product_id) as items_sold
from order_items oi 
inner join products p
	on oi.product_id = p.product_id 
left join category_translation ct 
	on p.product_category_name = ct.product_category_name 
group by ct.product_category_name_english 
order by items_sold desc
limit 10;

-- A LEFT JOIN keeps all our sales data, if a category has no English name, it shows as NULL instead of disappearing



-- 4. What share of order items were sold by a seller in the same state as the customer?

select 
	round(
		count(case when c.customer_state = s.seller_state then 1 end) * 100.0 / count(*),
		2
	) as same_state_share_percentage
from orders o 
join customers c 
	on o.customer_id = c.customer_id
join order_items oi
	on o.order_id = oi.order_id
join sellers s 
	on oi.seller_id = s.seller_id;
	

-- 5. For 5 orders, show item revenue and payment total side by side — without fan-out.

select 
	i.order_id, i.item_revenue, p.paid
from (
    select order_id, SUM(price + freight_value) as item_revenue
    from raw.order_items 
    group by order_id
) i
join (
    select order_id, SUM(payment_value) as paid
    from raw.order_payments 
    group by order_id
) p
    on p.order_id = i.order_id
limit 5;

select * from order_items;

select * from order_payments;


-- 6. Find orders where payments differ from price + freight by more than 1.00.

with payment_totals as (
    select 
        order_id,
        SUM(payment_value) as payment_total
    from order_payments
    group by order_id
)
select
    oi.order_id,
    SUM(oi.price) as item_total,
    SUM(oi.freight_value) as freight_total,
    SUM(oi.price) + SUM(oi.freight_value) as price_freight_total,
    p.payment_total,
    p.payment_total - (
        SUM(oi.price) + SUM(oi.freight_value)
    ) as difference
from order_items as oi
join payment_totals as p 
    on oi.order_id = p.order_id
group by
    oi.order_id,
    p.payment_total
having
    p.payment_total > SUM(oi.price) + SUM(oi.freight_value) + 1.00
    or
    p.payment_total < SUM(oi.price) + SUM(oi.freight_value) - 1.00
order by oi.order_id;

