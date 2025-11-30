-- Questions
use bike_store;

select * from brands;
select * from categories;
select * from customers;
select * from order_items;
select * from orders;
select * from products;
select * from staffs;
select * from stocks;
select * from stores;

with total_revenue as (
	select
		order_id,
        item_id,
        product_id,
		sum(quantity*list_price*(1-discount)) as total_revenue
	from
		order_items
        group by item_id
)
select * from total_revenue;
-- 1. Find total sales revenue per month in 2017.
select *from orders;
select *from order_items;
-- total revenue=sum(quantity *list price*(1-discount))
-- calculating total revenue after discount.
-- Total Revenue=∑(Quantity×List Price×(1−Discount))
select 
	monthname(o.order_date) as month_name, 
    round(sum(oi.quantity * oi.list_price * (1 - oi.discount)),2) as total_revenue 
from 
	orders o 
join 
    order_items oi on o.order_id = oi.order_id 
where 
    year(o.order_date) = 2017
group by month_name;


-- 2. a.) Compare total revenue across all stores. b. And which store generated the highest total sales?

select list_price,discount from order_items;


select sum(oi.quantity*oi.list_price*(1-discount)) as total_revenue ,s.store_id 
from order_items oi 
join orders o 
	on oi.order_id=o.order_id 
join stores s 
	on o.store_id=s.store_id 
group by store_id 
order by total_revenue 
limit 1;

-- 3. List the top 3 categories by total sales amount and the number of items sold.

select 
	c.category_name, 
    sum(oi.quantity) as total_soled_items,
    sum(oi.quantity*oi.list_price*(1-oi.discount)) as total_revenue
from order_items oi 
join products p 
	on oi.product_id =p.product_id 
join categories c 
	on c.category_id=p.category_id 
group by c.category_name
order by total_soled_items desc 
limit 3 ;


-- 4. Find each brand’s share of total units sold (as a percentage of overall sales).

with brand_sales as(
	select 
		b.brand_name,
        sum(oi.quantity) as units_sold
	from 
		order_items oi 
	join
		products p on oi.product_id=p.product_id
    join
		brands b on p.brand_id=b.brand_id
	group by 
		b.brand_name
),
total_sales as (
	select sum(units_sold) as total_units from brand_sales
)
select
	bs.brand_name,
    bs.units_sold,
    round((bs.units_sold*100)/ts.total_units,2)as percentage_sales
from 
	brand_sales bs, total_sales ts
order by
	percentage_sales desc;
    

-- 5. a.) Show each staff member’s full name with total revenue handled. b.) Rank staff within each store by performance.	
-- a)answer 
select
	s.staff_id,
	concat(s.first_name,' ',s.last_name) as full_name,
    sum(oi.quantity*list_price*(1-discount)) as total_revenue
from
	staffs s
join 
	 orders o on s.staff_id=o.staff_id
join 
	order_items oi on oi.order_id=o.order_id
group by 
	full_name,staff_id
order by 
	total_revenue desc;
    


-- 6. Classify orders as:
		-- ‘High’ if total > 5000
		-- ‘Medium’ if between 1000–5000
		-- ‘Low’ otherwise.
	-- Show order_id, store_name, and the segment label.
    
select
    o.order_id,
    s.store_name,
    SUM(oi.quantity * oi.list_price * (1 - oi.discount)) as order_total,
    case
        when sum(oi.quantity * oi.list_price * (1 - oi.discount)) > 5000 then 'High'
        when sum(oi.quantity * oi.list_price * (1 - oi.discount)) between 1000 and 5000 then 'Medium'
        else 'Low'
    end as order_segment
from
    orders o
join
    order_items oi on o.order_id = oi.order_id
join 
    stores s on  o.store_id = s.store_id
group by 
    o.order_id, s.store_name
order by 
    order_total desc; 

    
-- 7. What is the average discount percentage applied on all items sold in 2017?

select
    round(avg(oi.discount) * 100, 2) as avg_discount_percentage
from
    order_items oi
join
    orders o on oi.order_id = o.order_id
where
    year(o.order_date) = 2017;
    
    
-- 8. Find customers who placed more than 3 orders in a single year. Display customer_id, customer_name, and order_count.

select 
	c.customer_id,
    concat(c.first_name,' ',c.last_name) as full_name, 
    extract(year from o.order_date) as order_year,
    count(o.order_id) as order_count 
from 
	customers c 
join 
	orders o on o.customer_id=c.customer_id 
 group by 
	full_name,c.customer_id,order_year
having 
	count(o.order_id) >3 ;
 
-- 9. Find all orders whose total amount is greater than the average order total of that year.

with order_totals as (
    select
        o.order_id,
        extract(year from o.order_date) as order_year,
        sum(oi.quantity * oi.list_price * (1 - oi.discount)) as order_total
    from
        orders o
    join
        order_items oi on o.order_id = oi.order_id
    group by
        o.order_id, order_year
),
yearly_averages as(
    select
        order_year,
        avg(order_total) as avg_order_total
    from
        order_totals
    group by
        order_year
)
select
    ot.order_id,
    ot.order_year,
    ot.order_total
from
    order_totals ot
join 
    yearly_averages ya on ot.order_year = ya.order_year
where
    ot.order_total > ya.avg_order_total
order by
    ot.order_year, ot.order_total desc;


-- 10. Use a CTE to find each category’s top-selling product (highest total revenue). Show category_name, product_name, total_revenue.

with product_revenue as (
    select
        c.category_name,
        p.product_name,
        sum(oi.quantity * oi.list_price * (1 - oi.discount)) as total_revenue
    from
        order_items oi
    join
        products p on oi.product_id = p.product_id
    join
        categories c on p.category_id = c.category_id
    group by
        c.category_name, p.product_name
),
ranked_products as (
    select
        category_name,
        product_name,
        total_revenue,
        rank() over (partition by category_name order by  total_revenue desc) as revenue_rank
    from
        product_revenue
)
select
    category_name,
    product_name,
    total_revenue
from
    ranked_products
where
    revenue_rank = 1
order by
    category_name;

-- 11. Calculate each category’s percentage contribution to total revenue company-wide. Round to 2 decimal places.

with category_revenue as (
    select
        c.category_name,
        sum(oi.quantity * oi.list_price * (1 - oi.discount)) as category_total
    from
        order_items oi
    join 
        products p on oi.product_id = p.product_id
    join
        categories c on p.category_id = c.category_id
	group by
        c.category_name
),
company_total as (
    select sum(category_total) as total_revenue from category_revenue
)
select
    cr.category_name,
    round((cr.category_total * 100.0) / ct.total_revenue, 2) as percentage_contribution
from
    category_revenue cr, company_total ct
order by
    percentage_contribution desc;

-- 12. Show how many staff members are active vs inactive across all stores. (When active = 1 )

select 
    active,
    count(*) as staff_count
from
    staffs
group by
    active;

-- 13. a.) Calculate average days between order_date and shipped_date for each store. b.) Which store ships fastest on average?

select 
    s.store_id,
    s.store_name,
    round(avg(datediff(o.shipped_date, o.order_date)), 2) as avg_shipping_days
from 
    orders o
join 
    stores s on o.store_id = s.store_id
where 
    o.shipped_date is not null
group by
    s.store_id, s.store_name
order by
    avg_shipping_days;

-- 14. a.) Compute each customer’s total spend. b.) Then identify the top 5 highest-value customers.

select 
    c.customer_id,
    concat(c.first_name, ' ', c.last_name) as full_name,
    round(sum(oi.quantity * oi.list_price * (1 - oi.discount)), 2) as total_spend
from 
    customers c
join 
    orders o ON c.customer_id = o.customer_id
JOIN 
    order_items oi on o.order_id = oi.order_id
group by
    c.customer_id, c.first_name, c.last_name
order by
    total_spend desc
limit 5;

-- 15. For each store, list the category with the highest revenue contribution.

with store_category_revenue as (
    select 
        s.store_id,
        s.store_name,
        c.category_name,
        sum(oi.quantity * oi.list_price * (1 - oi.discount)) as total_revenue
    from
        order_items oi
    join 
        orders o on oi.order_id = o.order_id
    join 
        stores s on o.store_id = s.store_id
    join 
        products p on oi.product_id = p.product_id
    join 
        categories c on p.category_id = c.category_id
group by
        s.store_id, s.store_name, c.category_name
),
ranked_categories as (
    select 
        store_id,
        store_name,
        category_name,
        total_revenue,
        rank() over (partition by store_id order by total_revenue desc) as revenue_rank
    from 
        store_category_revenue
)
select 
    store_id,
    store_name,
    category_name,
    total_revenue
from 
    ranked_categories
where 
    revenue_rank = 1
order by
    store_id;

-- 16. a.) Compare total sales revenue between 2016 and 2017. b.) Show growth percentage by store.

with yearly_store_revenue as (
    select
        s.store_id,
        s.store_name,
        extract(year from o.order_date) as order_year,
        sum(oi.quantity * oi.list_price * (1 - oi.discount)) as total_revenue
    from 
        orders o
    join 
        order_items oi on o.order_id = oi.order_id
    join 
        stores s on o.store_id = s.store_id
    where 
        extract(year from o.order_date) in (2016, 2017)
	group by
        s.store_id, s.store_name, extract(year from o.order_date)
),
pivoted as (
    select 
        store_id,
        store_name,
        sum(case when order_year = 2016 then total_revenue else 0 end) as revenue_2016,
        SUM(case when order_year = 2017 then total_revenue else 0 end) as revenue_2017
    from 
        yearly_store_revenue
	group by
        store_id, store_name
)
select 
    store_id,
    store_name,
    round(revenue_2016, 2) as revenue_2016,
    round(revenue_2017, 2) as revenue_2017,
    round(
        case 
            when revenue_2016 = 0 then null
            else ((revenue_2017 - revenue_2016) * 100.0 / revenue_2016)
        end, 2
    ) as growth_percentage
from 
    pivoted
order by
    growth_percentage desc;

-- 17. Use a CTE to find: a.) total orders placed b.) total orders shipped c.) total orders returned/cancelled (if status captured).

with order_status_counts as (
    select 
        order_status,
        count(*) as order_count
    from 
        orders
    group by 
        order_status
)
select 
    order_status,
    order_count
from 
    order_status_counts
where 
    order_status in ('Placed', 'Shipped', 'Returned', 'Cancelled');



-- 18. a.) Which state or city generates the most revenue? b.) Show top 5 by total sales.

select count(city),count(state) from stores;
select 
	s.state, 
	sum(oi.quantity*oi.list_price*(1-oi.discount)) as total_revenue 
from 
	order_items oi 
join 
	orders o on oi.order_id=o.order_id 
join stores s 
	on s.store_id=o.store_id 
group by 
	state
order by 
	total_revenue desc;


-- 19. a.) Assume a 20 % margin on list price; compute estimated profit per brand. b.) Which brand drives the most profit?

-- 19a & 19b: Estimated profit per brand and top profit driver
select
    p.brand_id,
    sum(oi.quantity * p.list_price * 0.20) as estimated_profit
from
    order_items oi
join
    products p on oi.product_id = p.product_id
group by
    p.brand_id
order by
    estimated_profit desc;


-- 20. Find all products with stock quantity < 10 in any store. List store_name, product_name, and quantity.

select 
	st.quantity,
    s.store_name,
    p.product_name 
from 
	stocks st 
join 
	stores s on s.store_id=st.store_id 
join 
	products p on st.product_id=p.product_id 
where
	st.quantity<10;


