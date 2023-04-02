CREATE TABLE driver(driver_id integer,reg_date date);

INSERT INTO driver(driver_id,reg_date)
VALUES (1,'01-01-2021'),
(2,'01-03-2021'),
(3,'01-08-2021'),
(4,'01-15-2021');

CREATE TABLE ingredients(ingredients_id integer,ingredients_name varchar(60));

INSERT INTO ingredients(ingredients_id,ingredients_name)
VALUES (1,'Paneer'),
(2,'Chilli Sauce'),
(3,'Chicken'),
(4,'Cheese'),
(5,'Kebab'),
(6,'Mushrooms'),
(7,'Onions'),
(8,'Egg'),
(9,'Peppers'),
(10,'Schezwan Sauce'),
(11,'Tomatoes'),
(12,'Mayonnaise');

CREATE TABLE rolls(roll_id integer,roll_name varchar(30));

INSERT INTO rolls(roll_id ,roll_name) 
VALUES (1,'Non Veg Roll'),
(2,'Veg Roll');

CREATE TABLE rolls_recipes(roll_id integer,ingredients varchar(24));

INSERT INTO rolls_recipes(roll_id ,ingredients) 
VALUES (1,'2,3,4,5,6,7,8,10'),
(2,'1,4,6,7,9,10,11,12');

CREATE TABLE driver_order(order_id integer,driver_id integer,pickup_time datetime,distance VARCHAR(7),duration VARCHAR(10),cancellation VARCHAR(23));

INSERT INTO driver_order(order_id,driver_id,pickup_time,distance,duration,cancellation) 
VALUES
(1,1,'2022-01-01 18:15:34','20km','32 mins',''),
(2,1,'2022-01-01 19:10:54','20km','27 mins',''),
(3,1,'2022-01-03 00:12:37','13.4km','20 mins','NaN'),
(4,2,'2022-01-04 13:53:03','23.4km','40 mins','NaN'),
(5,3,'2022-01-08 21:10:57','10km','15 mins','NaN'),
(6,3,null,null,null,'Cancellation'),
(7,2,'2022-01-08 21:30:45','25km','25 mins',null),
(8,2,'2022-01-10 00:15:02','23.4km','15 mins',null),
(9,2,null,null,null,'Customer Cancellation'),
(10,1,'2022-01-11 18:50:20','10km','10 mins',null);

CREATE TABLE customer_orders(order_id integer, customer_id integer, roll_id integer, not_include_items VARCHAR(4), extra_items_included VARCHAR(4), order_date datetime);

INSERT INTO customer_orders(order_id, customer_id, roll_id, not_include_items, extra_items_included, order_date)
VALUES 
(1,101,1,'','','2022-01-01 18:05:02'),
(2,101,1,'','','2022-01-01 19:00:52'),
(3,102,1,'','','2022-01-02 23:51:23'),
(3,102,2,'','NaN','2022-01-02 23:51:23'),
(4,103,1,'4','','2022-01-04 13:23:46'),
(4,103,1,'4','','2022-01-04 13:23:46'),
(4,103,2,'4','','2022-01-04 13:23:46'),
(5,104,1,null,'1','2022-01-08 21:00:29'),
(6,101,2,null,null,'2022-01-08 21:03:13'),
(7,105,2,null,'1','2022-01-08 21:20:29'),
(8,102,1,null,null,'2022-01-09 23:54:33'),
(9,103,1,'4','1,5','2022-01-10 11:22:59'),
(10,104,1,null,null,'2022-01-11 18:34:49'),
(10,104,1,'2,6','1,4','2022-01-11 18:34:49');


delete from driver_order 

select * from customer_orders;
select * from driver_order;
select * from ingredients;
select * from driver;
select * from rolls;
select * from rolls_recipes;


Queries PART 1 (Roll metrics)

1) How Many total_rolls were ordered?

SELECT COUNT(roll_id) AS total_rolls
FROM customer_orders;


2) How many unique customers orders?

SELECT COUNT(DISTINCT customer_id) AS unique_customers
FROM customer_orders;


3) How many successful orders delivered by each driver?

SELECT driver_id, SUM(successful_orders) AS successfull_orders FROM(
SELECT *,
CASE 
	WHEN cancellation LIKE '%cancel%' THEN 0
	ELSE 1
END AS successful_orders FROM driver_order do
) WHERE successful_orders=1
GROUP BY driver_id


4) How many each type of roll was ordered?

SELECT roll_id, COUNT(roll_id) AS roll_eachtype
FROM customer_orders
GROUP BY roll_id 


5) How many each type of roll was delivered?

SELECT roll_id, COUNT(roll_id) AS roll_eachtype  
FROM customer_orders co 
WHERE order_id IN (
SELECT order_id FROM(
SELECT *,
CASE 
	WHEN cancellation LIKE '%cancel%' THEN 0
	ELSE 1
END AS roll_eachtype FROM driver_order do
) WHERE roll_eachtype=1) GROUP BY roll_id 


6) How many veg and non veg rolls were ordered by each customers

SELECT a.*,b.roll_name FROM(
SELECT customer_id,roll_id,COUNT(roll_id) AS roll_count
FROM customer_orders
GROUP BY roll_id,customer_id
) a INNER JOIN rolls AS b 
ON a.roll_id=b.roll_id;


7) What is the maximum no. of rolls delivered in a single order

SELECT * FROM(
SELECT *,RANK() OVER(ORDER BY cnt DESC) AS rnk FROM(
SELECT order_id, COUNT(roll_id) AS cnt FROM(
SELECT * FROM customer_orders 
WHERE order_id IN(
SELECT order_id FROM(
SELECT *,CASE 
	WHEN cancellation LIKE '%cancel%' THEN 0
	ELSE 1
END AS roll_eachtype FROM driver_order)
WHERE roll_eachtype=1)) GROUP BY order_id)) 
WHERE rnk=1


8) For each customers how many delivered rolls had atleast 1 change and how many had no change?

WITH temp_customer_orders(order_id,customer_id,roll_id,not_include_items,extra_items_included,order_date) AS
( SELECT order_id,customer_id,roll_id,CASE 
	WHEN not_include_items IS NULL or not_include_items = "" or not_include_items = "NaN" THEN "No Change"
	ELSE not_include_items
END AS items_not_included,CASE 
	WHEN extra_items_included IS NULL or extra_items_included = "" or extra_items_included = "NaN" THEN "No Change"
	ELSE extra_items_included
END AS new_extra_items_included,order_date FROM customer_orders),

temp_driver_orders(order_id,driver_id,pickup_time,distance,duration,cancellation) AS
(SELECT order_id,driver_id,pickup_time,distance,duration,CASE 
	WHEN cancellation IN ('Cancellation','Customer Cancellation') THEN 0
	ELSE 1
	END AS newcancellation FROM driver_order)

SELECT customer_id,change_or_nochange,COUNT(order_id) AS at_least_one_change FROM (
SELECT *,CASE 
	WHEN not_include_items = 'No Change' AND extra_items_included = 'No Change' Then 'no change'
	ELSE 'change'
END AS change_or_nochange FROM temp_customer_orders 
WHERE order_id IN (SELECT order_id FROM temp_driver_orders
WHERE cancellation = 1)) GROUP BY customer_id,change_or_nochange


9) How many rolls were delivered that had both exclusions and extras

WITH temp_customer_orders(order_id,customer_id,roll_id,not_include_items,extra_items_included,order_date) AS
( SELECT order_id,customer_id,roll_id,CASE 
	WHEN not_include_items IS NULL or not_include_items = "" or not_include_items = "NaN" THEN "NA"
	ELSE not_include_items
END AS items_not_included,CASE 
	WHEN extra_items_included IS NULL or extra_items_included = "" or extra_items_included = "NaN" THEN "NA"
	ELSE extra_items_included
END AS new_extra_items_included,order_date FROM customer_orders),

temp_driver_orders(order_id,driver_id,pickup_time,distance,duration,cancellation) AS
( SELECT order_id,driver_id,pickup_time,distance,duration,CASE 
	WHEN cancellation IN ('Cancellation','Customer Cancellation') THEN 0
	ELSE 1
	END AS newcancellation FROM driver_order)

SELECT change_or_nochange, COUNT(change_or_nochange) AS no_of_rolls
FROM( SELECT *,CASE 
	WHEN not_include_items != 'NA' AND extra_items_included != 'NA' Then 'both excl & extras'
	ELSE 'either excl or extras'
END AS change_or_nochange FROM temp_customer_orders 
WHERE order_id IN ( SELECT order_id FROM temp_driver_orders
WHERE cancellation = 1)
) GROUP BY change_or_nochange


10) What was the total no. of rolls ordered for each hour of the day?
|| --> used as CONCAT

SELECT hours_frame, COUNT(order_id) as no_of_rolls FROM
( SELECT *, CAST
(strftime('%H', order_date) AS VARCHAR) 
|| '-' || 
CAST(strftime('%H', order_date)+1 AS VARCHAR) AS hours_frame
FROM customer_orders co ) GROUP BY hours_frame


11) What was the no. orders for each day of the week?

SELECT day_of_the_week, COUNT(DISTINCT order_id) AS orders_each_day
FROM
(SELECT *,CASE CAST(strftime('%w', order_date) AS INTEGER)
	  when 0 then 'Sunday'
	  when 1 then 'Monday'
	  when 2 then 'Tuesday'
	  when 3 then 'Wednesday'
	  when 4 then 'Thursday'
	  when 5 then 'Friday'
	  else 'Saturday' 
  END AS day_of_the_week FROM customer_orders co)
  GROUP BY day_of_the_week


Queries PART 2 (Customer and Driver Experience)

12) What was the average time in mins it took for each driver to arrive at the Roll Company HQ to pickup the order

SELECT driver_id,ROUND(AVG(time_diff)) FROM
(SELECT * FROM
(SELECT *, (ROW_NUMBER() OVER(PARTITION BY order_id ORDER BY time_diff)) AS rnk
FROM(
SELECT a.*,b.driver_id,b.pickup_time,b.distance,b.duration,b.cancellation,
Cast ((JulianDay(pickup_time) - JulianDay(order_date)) * 24 * 60 As Integer) AS time_diff  
FROM customer_orders AS a INNER JOIN driver_order AS b 
ON a.order_id = b.order_id 
WHERE b.pickup_time IS NOT NULL
)) WHERE rnk=1) GROUP BY driver_id


13) Is there any relationship between the number of rolls and the time taken to prepare 

SELECT COUNT(order_id) AS number_of_rolls,AVG(time_diff) AS time
FROM (SELECT a.*,b.driver_id,b.pickup_time,b.distance,b.duration,b.cancellation,
Cast ((JulianDay(pickup_time) - JulianDay(order_date)) * 24 * 60 As Integer) AS time_diff  
FROM customer_orders AS a INNER JOIN driver_order AS b 
ON a.order_id = b.order_id 
WHERE b.pickup_time IS NOT NULL)
GROUP BY order_id


14) What was the average distance travelled for each customer?

SELECT customer_id, AVG(distance) AS average_distance
FROM (SELECT * FROM
(SELECT *, (ROW_NUMBER() OVER(PARTITION BY order_id ORDER BY time_diff)) AS rnk
FROM(
SELECT a.*,b.driver_id,b.pickup_time,b.distance,b.duration,b.cancellation,
Cast ((JulianDay(pickup_time) - JulianDay(order_date)) * 24 * 60 As Integer) AS time_diff  
FROM customer_orders AS a INNER JOIN driver_order AS b 
ON a.order_id = b.order_id 
WHERE b.pickup_time IS NOT NULL
)) WHERE rnk=1) GROUP BY customer_id


15) What was the difference between the longest and shortest delivery times for all orders?

SELECT MAX(duration)-MIN(duration) AS difference
FROM driver_order do 
WHERE duration IS NOT NULL 


16) What was the average speed for each driver for each delivery and do you notice any trend for these values?

SELECT order_id,driver_id,distance*1.0/duration AS speed FROM
(SELECT *,
CAST(TRIM(REPLACE(LOWER(distance),'km','')) AS DECIMAL(4,2)) AS distance,
CAST(CASE WHEN duration like '%min%' THEN LTRIM(duration) ELSE duration END AS REAL) AS duration 
FROM driver_order do 
WHERE distance IS NOT NULL)


17) What is successful delivery percentage for each driver?

SELECT driver_id,(successful_orders*1.0/total_orders)*100 AS suc_del_perc 
FROM
(SELECT driver_id, SUM(del_info) AS successful_orders, COUNT(driver_id) AS total_orders
FROM
(SELECT driver_id,CASE WHEN cancellation like '%cancel%' THEN '0' ELSE '1' 
END AS del_info
FROM driver_order do)
GROUP BY driver_id)






