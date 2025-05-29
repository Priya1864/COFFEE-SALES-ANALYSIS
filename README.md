# Coffee Sales Analysis

## About
This project analyzes coffee sales data across different cities using SQL. It aims to provide insights into customer behavior, product performance, sales trends, and city-wise coffee consumption. The analysis helps understand market size, revenue generation, and product popularity to aid business decisions in the coffee industry.

## Database Schema

### Tables:

- **city**  
  Stores information about cities including population, estimated rent, and city rank.
  - city_id (INT, Primary Key)  
  - city_name (VARCHAR)  
  - population (INT)  
  - estimated_rent (FLOAT)  
  - city_rank (INT)

- **products**  
  Contains product details such as product name and price.
  - product_id (INT, Primary Key)  
  - product_name (VARCHAR)  
  - price (FLOAT)

- **customers**  
  Contains customer information along with their city.
  - customer_id (INT, Primary Key)  
  - customer_name (VARCHAR)  
  - city_id (INT, Foreign Key referencing city.city_id)

- **sales**  
  Records individual sales transactions, including product, customer, sale date, total amount, and rating.
  - sale_id (INT, Primary Key)  
  - sale_date (DATE)  
  - product_id (INT, Foreign Key referencing products.product_id)  
  - customer_id (INT, Foreign Key referencing customers.customer_id)  
  - total (FLOAT)  
  - rating (INT)

## Key Analysis Questions

- Estimate the number of coffee consumers in each city (assuming 25% of the population).
- Calculate total coffee sales revenue by city for the last quarter of 2023.
- Determine sales count for each coffee product and identify top sellers.
- Find average sales amount per customer by city.
- Analyze the relationship between city rent and average sales.
- Identify top 3 selling products in each city.
- Segment customers by city based on coffee purchases.
- Calculate monthly sales growth rate per city.

## Sample Queries
-- Estimating coffee consumers per city:
 ```sql
SELECT city_name, ROUND((population * 0.25 / 1000000), 2) AS coffee_consumers
FROM city
ORDER BY coffee_consumers DESC;

-- Q2 total revenue for coffee sales across all cities in the last quarter of 2023:
 ```sql
SELECT SUM(total) AS revenue, cc.city_name
FROM sales s
JOIN customers c ON s.customer_id = c.customer_id
JOIN city cc ON c.city_id = cc.city_id
WHERE EXTRACT(QUARTER FROM s.sale_date) = 4
  AND EXTRACT(YEAR FROM s.sale_date) = 2023
GROUP BY cc.city_name
ORDER BY revenue DESC;

-- Q3 SALES COUNT FOR EACH PRODUCT HOW MANY UNITS OF COFFEE SOLD:
 ```sql
SELECT product_name, COUNT(*) AS item_sold
FROM products p
JOIN sales s ON p.product_id = s.product_id
GROUP BY product_name
ORDER BY item_sold DESC
LIMIT 5;

-- Q4 AVG SALES AMOUNT PER CITY:
 ```sql
SELECT cc.city_name,
       SUM(s.total) AS avg_sales_amount,
       COUNT(DISTINCT c.customer_id) AS total_customer,
       ROUND((SUM(s.total)::NUMERIC / COUNT(DISTINCT c.customer_id)::NUMERIC), 2) AS avg_per_customer
FROM sales s
JOIN customers c ON s.customer_id = c.customer_id
JOIN city cc ON c.city_id = cc.city_id
GROUP BY cc.city_name
ORDER BY avg_sales_amount DESC, cc.city_name DESC;

-- Q5 city population and coffee consumers:
 ```sql
WITH city_table AS (
  SELECT city_name, ROUND((population * 0.25 / 1000000), 2) AS coffee_consumer
  FROM city
),
uniquee AS (
  SELECT cc.city_name, COUNT(DISTINCT c.customer_id) AS unique_id
  FROM sales s
  JOIN customers c ON s.customer_id = c.customer_id
  JOIN city cc ON c.city_id = cc.city_id
  GROUP BY cc.city_name
)
SELECT ct.city_name, ct.coffee_consumer, u.unique_id
FROM city_table ct
JOIN uniquee u ON ct.city_name = u.city_name;

-- Q6 TOP SELLING PRODUCTS BY CITY WHAT ARE THE TOP 3 SELLING PRODUCTS IN EACH CITY BASED ON SALES VOLUME:
 ```sql
SELECT *
FROM (
  SELECT cc.city_name, p.product_name,
         COUNT(s.sale_id) AS total_order,
         DENSE_RANK() OVER (PARTITION BY cc.city_name ORDER BY COUNT(s.sale_id) DESC) AS rank
  FROM sales s
  JOIN products p ON p.product_id = s.product_id
  JOIN customers c ON s.customer_id = c.customer_id
  JOIN city cc ON c.city_id = cc.city_id
  GROUP BY cc.city_name, p.product_name
) AS t
WHERE rank <= 3;

-- Q7 customer segmentation by city how many unique customers are there in city who have purchased coffee products:
 ```sql
SELECT cc.city_name, COUNT(DISTINCT c.customer_id) AS unique_id
FROM customers c
JOIN sales s ON c.customer_id = s.customer_id
JOIN products p ON s.product_id = p.product_id
JOIN city cc ON c.city_id = cc.city_id
GROUP BY cc.city_name
ORDER BY unique_id DESC;

-- Q8 avg sales vs rent find city and their average sale per customer and avg rent per customer:
 ```sql
SELECT cc.city_name, cc.estimated_rent,
       COUNT(DISTINCT c.customer_id) AS total_customer,
       (SUM(s.total) / COUNT(DISTINCT c.customer_id)) AS avg_sale
FROM sales s
JOIN customers c ON s.customer_id = c.customer_id
JOIN city cc ON cc.city_id = c.city_id
GROUP BY cc.city_name, cc.estimated_rent
ORDER BY avg_sale DESC;

-- Q9 monthly sales growth sales growth rate: calculate the percentage growth in sales over different time periods:
 ```sql
SELECT cc.city_name,
       EXTRACT(MONTH FROM sale_date) AS month,
       SUM(s.total) AS sales,
       EXTRACT(YEAR FROM sale_date) AS year
FROM sales s
JOIN customers c ON c.customer_id = s.customer_id
JOIN city cc ON cc.city_id = c.city_id
GROUP BY cc.city_name, year, month
ORDER BY cc.city_name, year, month;

WITH monthly_sales AS (
    SELECT cc.city_name,
           EXTRACT(MONTH FROM s.sale_date) AS month,
           EXTRACT(YEAR FROM s.sale_date) AS year,
           SUM(s.total) AS sales
    FROM sales s
    JOIN customers c ON c.customer_id = s.customer_id
    JOIN city cc ON cc.city_id = c.city_id
    GROUP BY cc.city_name, year, month
)
SELECT city_name,
       month,
       year,
       sales,
       LAG(sales, 1) OVER (PARTITION BY city_name ORDER BY year, month) AS last_sale
FROM monthly_sales
ORDER BY city_name, year, month;
