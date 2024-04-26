-------------------------------------------------------------------
------ INSTACART MARKET BASKET ANALYSIS
-------------------------------------------------------------------

-------------------------------------------------------------------
-- Number of Orders placed in Q2

select count(distinct order_id)
from [Instacart Case Study].dbo.order_products_Q2

-------------------------------------------------------------------
-- Number of Orders placed in Q3

select count(distinct order_id)
from [Instacart Case Study].dbo.order_products_Q3

-------------------------------------------------------------------
-- Order Count / Department in Q2
with order_count_dept_q2 as
(select d.department, count(distinct opq2.order_id) as order_count
from order_products_Q2 opq2
inner join products p on p.product_id = opq2.product_id
inner join departments d on d.department_id = p.department_id
group by d.department),

-- Order Count / Department in Q3
order_count_dept_q3 as
(select d.department, count(distinct opq3.order_id) as order_count
from order_products_Q3 opq3
inner join products p on p.product_id = opq3.product_id
inner join departments d on d.department_id = p.department_id
group by d.department)

select ocd2.department, ocd2.order_count as Q2_order_count, ocd3.order_count as Q3_order_count, 
       -- Calculate the department order growth percentage
       Round(((cast(ocd3.order_count as float) - ocd2.order_count)/ocd2.order_count) *100, 2) as growth_percentage
from order_count_dept_q2 ocd2
inner join order_count_dept_q3 ocd3 on ocd3.department = ocd2.department

-------------------------------------------------------------------
-- Distribution of Order Size
-- Q2
select t.order_size, COUNT(distinct t.order_id) as order_count
from
(select opq2.order_id, MAX(opq2.add_to_cart_order) as order_size
from [Instacart Case Study].dbo.order_products_Q2 opq2
group by opq2.order_id) t
group by t.order_size
order by t.order_size

-- Q3
select t.order_size, COUNT(distinct t.order_id) as order_count
from
(select opq3.order_id, MAX(opq3.add_to_cart_order) as order_size
from [Instacart Case Study].dbo.order_products_Q3 opq3
group by opq3.order_id) t
group by t.order_size
order by t.order_size

-------------------------------------------------------------------
-- Top Selling and Least Selling Products

-- Declare the top and bottom N
CREATE PROCEDURE GetTopNBottomNSaleDifference
    @TopN INT
AS
BEGIN

with q2_order_count as
(select opq2.product_id, COUNT(distinct opq2.order_id) as q2_order_count
from [Instacart Case Study].dbo.order_products_Q2 opq2
group by opq2.product_id),

q3_order_count as
(select opq3.product_id, COUNT(distinct opq3.order_id) as q3_order_count
from [Instacart Case Study].dbo.order_products_Q3 opq3
group by opq3.product_id),

q2q3_order_count as
(select coalesce(q2oc.product_id, q3oc.product_id) as product_id, coalesce(q2_order_count, 0) as q2_order_count,
       coalesce(q3_order_count, 0) as q3_order_count 
from q2_order_count q2oc
full outer join q3_order_count q3oc on q3oc.product_id = q2oc.product_id),

ordered_results AS
(select *, q23oc.q3_order_count - q23oc.q2_order_count as sale_difference
from q2q3_order_count q23oc
where q23oc.q2_order_count <> q23oc.q3_order_count
),

ordered_results_rank as
(select * , DENSE_RANK() over (order by sale_difference desc) as rn
from ordered_results),

top_n_bottom as
(select * from ordered_results_rank
where rn <= @TopN
union all
select * from ordered_results_rank
where rn >= (select MAX(rn) - (@TopN - 1) from ordered_results_rank))

select p.product_name, tb.sale_difference
from top_n_bottom tb
inner join [Instacart Case Study].dbo.products p on p.product_id = tb.product_id
order by sale_difference desc

END

EXEC GetTopNBottomNSaleDifference @TopN = 10;

-------------------------------------------------------------------
-- Daily Order placed per Quarter

select o.Quarter, 
CASE o.order_dow
    WHEN 0 THEN 'Monday'
    WHEN 1 THEN 'Tuesday'
    WHEN 2 THEN 'Wednesday'
    WHEN 3 THEN 'Thursday'
    WHEN 4 THEN 'Friday'
    WHEN 5 THEN 'Saturday'
    WHEN 6 THEN 'Sunday'
  END AS weekday_name, 
  COUNT(distinct o.order_id) as order_count
from [Instacart Case Study].dbo.orders o
where o.Quarter in ('Q2', 'Q3')
group by o.Quarter, o.order_dow
order by o.Quarter, o.order_dow

-------------------------------------------------------------------
-- Hourly order placement per Quarter

select o.Quarter, 
o.order_hour_of_day,
  COUNT(distinct o.order_id) as order_count
from [Instacart Case Study].dbo.orders o
where o.Quarter in ('Q2', 'Q3')
group by o.Quarter, o.order_hour_of_day
order by o.Quarter, o.order_hour_of_day