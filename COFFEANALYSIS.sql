create table city(city_id int primary key,
                 city_name varchar(30),
				 population int,
				 estimated_rent float,
				 city_rank int);

create table products(product_id int primary key,
                      product_name varchar(40),
					  price float);
					  
create table customers(customer_id int primary key,
                       customer_name varchar(30),
					   city_id int,
					   constraint t foreign key (city_id) references city(city_id));

create table sales(sale_id int primary key,
                   sale_date date,
					product_id int,
					customer_id	int,
					total float,
					rating int,
					constraint f foreign key (customer_id)references customers(customer_id),
					constraint m foreign key (product_id)references products(product_id));


select*from customers;	
select*from sales;
select*from city;
select*from products;



--mondaycoffe analysis-- data analysis
--Q1.how many people in each city are estimated to consume coffee,given 
--that 25%of the popuATION does
select *from city;
select city_name,round((population*0.25/1000000),2) coffeconumer,city_rank from city
order by 2 desc;


--Q2 total revenue for coffe sales across all city inthe last quareter of 2023
select *from sales;
select*from customers;
select sum(total) as revenue ,cc.city_name
from sales s
join customers c
on s.customer_id=c.customer_id
join city cc
on c.city_id=cc.city_id
where extract(quarter from s.sale_date)=4
and
extract(year from s.sale_date)=2023
group by 2
ORDER BY 1 DESC;

---Q3 SALES COUNT FOR EACH PRODUCT HOW MANY UNITS OF COFFE SOLD
SELECT*FROM PRODUCTS;
select*from sales;
SELECT PRODUCT_NAME,COUNT(*) AS ITEMSOLD
FROM products p
join sales s
on p.product_id=s.product_id
group by product_name
order by 2 desc
limit 5;

--Q4AVG SALES AMOUNT PER CITY
select *from city;
select cc.city_name,sum(s.total)as avgsalesamount,
count( distinct c.customer_id)totalcustomer,
round((sum(s.total))::numeric/count( distinct c.customer_id)::numeric,2)as avgcustomer from sales s
join customers c
on s.customer_id =c.customer_id
join city cc
on c.city_id=cc.city_id
group by 1
order by 2 desc,1 desc;


--Q5 city population and coffeconsumers
--provide a list of cities along with their populations and estimated coffeconsumers
with citytable as(
select  city_name,round((population*0.25/1000000),2) as coffeconsumer
from city),
uniquee as(select cc.city_name,
count(distinct c.customer_id)  uniqueid from sales s
join customers c
on s.customer_id=c.customer_id
join city cc
on c.city_id=cc.city_id
group by 1)
select cc.city_name,coffeconsumer,uniqueid
from citytable cc
join uniquee as u
on cc.city_name=u.city_name;




--Q6
--TOP SELLING PRODUCTS BY CITY
--WHAT ARE THE TOP 3 SELLING PRODUCTS IN EACH CITY BASED ON SALES VOLUME
select*from products;
select*from sales;
select*from city;
select*from customers;

select* from (select cc.city_name,p.product_name,
count(s.sale_id) as totalorder ,
dense_rank() over(partition by cc.city_name order by count(s.sale_id) desc ) as rank from sales s
join products p
on p.product_id=s.product_id
join customers c
on s.customer_id=c.customer_id
join city cc
on c.city_id=cc.city_id
group by 1,2) as t
where rank<=3;


--Q7customer segmentation by city
--how many unique customers are there in city who hve purchaesd
--coffe products



select*from city;
select*from products;
select*from sales;
select cc.city_name,count( distinct  c.customer_id) as uniqueid from customers  c
join sales s on 
c.customer_id=s.customer_id
join products  p on 
s.product_id=p.product_id
join city cc on c.city_id=cc.city_id
where  p.product_id in(select product_id from products pp where p.product_id=pp.product_id)
group by 1
order by 2 desc;




---Q8 avg sales vs rent
--find city and their average sale per customer and avg rent per customer
select*from city;
select *from sales;
select cc.city_name ,cc.estimated_rent ,
count(distinct c.customer_id) totalcustomer ,
(sum(s.total)/count(distinct c.customer_id)) as avgsale
from sales s
join customers c on s.customer_id=c.customer_id
join city cc on cc.city_id=c.city_id
where sale_id in(select sale_id from sales ss where s.sale_id=ss.sale_id)
group by 1,2
order by   4 desc


--Q9monthly sales growth
--sales growth rate: calcuale the percentage  growth in sales over differnt time periods
select*from sales;
select  cc.city_name,extract(month from sale_date) as  month ,sum(s.total) sales,
extract (year from sale_date) as year
from sales s join customers c on c.customer_id=s.customer_id
join city cc on cc.city_id=c.city_id
group by 1,4,2
order by 1,4,2;


WITH monthly_sales AS (
    SELECT 
        cc.city_name,
        EXTRACT(MONTH FROM s.sale_date) AS month,
        EXTRACT(YEAR FROM s.sale_date) AS year,
        SUM(s.total) AS sales
    FROM sales s
    JOIN customers c ON c.customer_id = s.customer_id
    JOIN city cc ON cc.city_id = c.city_id
    GROUP BY cc.city_name, year, month
)
SELECT 
    city_name,
    month,
    year,
    sales,
    LAG(sales, 1) OVER (PARTITION BY city_name ORDER BY year, month) AS lastsale,
   FROM monthly_sales
ORDER BY city_name, year, month;




