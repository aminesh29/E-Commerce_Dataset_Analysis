/*
Objective 14. Identify the top 5 most valuable customers using a composite score that 
combines three key metrics: (SQL)
Total Revenue (50% weight): The total amount of money spent by the customer.
Order Frequency (30% weight): The number of orders placed by the customer, indicating their loyalty and engagement.
Average Order Value (20% weight): The average value of each order placed by the customer, reflecting the typical transaction size.
*/

select CustomerID, sum(SalePrice) as Total_Revenue, count(*) as Order_Frequency, 
round(avg(SalePrice),1) as Avg_Order_Value,
round(sum(SalePrice)*0.5 + count(*)*0.3 + avg(SalePrice)*0.2,1) as Composite_Score
from orders
group by CustomerID
order by Composite_Score desc
limit 5;

/*
Objective 15. Calculate the month-over-month growth rate in total revenue across the entire dataset. (SQL)
*/

with cte1 as (select concat(right(OrderDate, 4), mid(OrderDate, 3, 3)) as Month_Year,
sum(SalePrice) as Curr_Month_Rev
from orders
group by Month_Year
),
cte2 as (select Month_Year, Curr_Month_Rev,
lag(Curr_Month_Rev) over(order by Month_Year) as Prev_Month_Rev
from cte1)

select Month_Year, Curr_Month_Rev, Prev_Month_Rev,
round((Curr_Month_Rev - Prev_Month_Rev)*100/Prev_Month_Rev,1) as Percentage_Growth
from cte2
order by Month_Year;

/*
Objective 16. Calculate the rolling 3-month average revenue for each product category. (SQL)
*/

with cte1 as (select ProductCategory, concat(right(OrderDate, 4), mid(OrderDate, 3, 3)) as Month_Year,
sum(SalePrice) as Monthly_Revenue
from orders
where ProductCategory is not null
group by ProductCategory, Month_Year
order by ProductCategory, Month_Year)

select ProductCategory, Month_Year, Monthly_Revenue,
round(avg(Monthly_Revenue) over(partition by ProductCategory order by Month_Year
	  rows between 2 preceding and current row),1) as 3_Month_Rolling_Average
from cte1;

/*
Objective 17. Update the orders table to apply a 15% discount on the `Sale Price` for
 orders placed by customers who have made at least 10 orders. (SQL)
*/

update orders 
set SalePrice = SalePrice*0.85
where CustomerID in(select CustomerID from orders
				group by CustomerID having count(OrderID) >= 10);
                
/*
Objective 18. Calculate the average number of days between consecutive orders for customers
 who have placed at least five orders. (SQL)
*/

with cte1 as (select CustomerID, OrderDate,
lead(OrderDate) over(partition by CustomerID order by OrderDate) as NextOrderDate
from orders)

select CustomerID, avg(datediff(OrderDate,NextOrderDate)) AvgDaysBetweenOrders
from cte1 
where NextOrderDate is not null
group by CustomerID
having count(*)>=5
order by CustomerID;

/*
Objective 19. Identify customers who have generated revenue that is more than 30% higher 
than the average revenue per customer. (SQL)
*/

with cte1 as (select CustomerID, sum(SalePrice) as TotalRevenue
			from orders group by CustomerID)
            
Select CustomerID from cte1
where TotalRevenue > (select avg(TotalRevenue)*1.3 from cte1)
order by CustomerID;

/*
Objective 20. Determine the top 3 product categories that have shown the highest increase in sales 
over the past year compared to the previous year. (SQL)   
*/

with cte1 as ( select ProductCategory, year(STR_TO_DATE(OrderDate, '%d-%m-%Y')) as Years,
sum(SalePrice) as TotalRevenue
from orders
where ProductCategory is not null
group by ProductCategory,Years
order by ProductCategory,Years ),

cte2 as ( select ProductCategory, Years, TotalRevenue, 
lag(TotalRevenue) over(partition by ProductCategory order by Years) as PrevYearRevenue,
row_number() over(partition by ProductCategory order by Years desc) as ranking
from cte1 )

select ProductCategory, Years, TotalRevenue, PrevYearRevenue,
round((TotalRevenue-PrevYearRevenue)*100/PrevYearRevenue,1) as PercentageGrowth
from cte2
where ranking =1
order by PercentageGrowth desc
limit 3;

-- XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX             