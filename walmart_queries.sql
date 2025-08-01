SELECT * FROM walmart;

-- EDA
SELECT COUNT(*) FROM walmart;

SELECT 
	payment_method, 
	COUNT(*)
FROM walmart
GROUP BY payment_method

SELECT 
	COUNT(DISTINCT branch)
FROM walmart;

SELECT MAX(quantity) FROM walmart;
SELECT MIN(quantity) FROM walmart;

-- Business Problems

-- PROBLEM 1: 
-- Find different payment methods, number of 
-- transaction and number of quantity 

SELECT 
	payment_method, 
	COUNT(*) as total_payments,
	SUM(quantity) as total_sold
FROM walmart
GROUP BY payment_method

-- PROBLEM 2: 
-- Identify highest-rated category in each branch
-- displaying the branch, category and avg rating

SELECT *
FROM
(	SELECT
		branch,
		category,
		AVG(rating) as avg_rating,
		RANK() OVER(PARTITION BY branch ORDER BY AVG(rating)DESC) as rank
	FROM walmart
	GROUP by 1, 2
)
WHERE rank = 1;

-- PROBLEM 3: 
-- Identify the busiest day for each branch based 
-- the number of transactions
SELECT *
FROM
(	SELECT
		branch,
		TO_CHAR(TO_DATE(date, 'DD/MM/YY'), 'Day') as day_name,
		COUNT(*) as total_transactions,
		RANK() OVER(PARTITION BY branch ORDER BY COUNT(*)DESC) as rank
	FROM walmart
	GROUP BY 1,2
)
WHERE rank = 1;

-- Aggregates and ranks days of the week based on how frequently
-- they were the highest-transaction day at individual Walmart branches
WITH ranked_days AS (
    SELECT
        branch,
        TRIM(TO_CHAR(TO_DATE(date, 'DD/MM/YY'), 'Day')) AS day_name,
        COUNT(*) AS total_transactions,
        RANK() OVER (
            PARTITION BY branch
            ORDER BY COUNT(*) DESC
        ) AS rank
    FROM walmart
    GROUP BY branch, day_name
)

SELECT
    day_name,
    COUNT(*) AS num_times_rank_1
FROM ranked_days
WHERE rank = 1
GROUP BY day_name
ORDER BY num_times_rank_1 DESC;
-- Gives us a clearer overview over what are the most common
-- busiest days across branches, compared to the jumbled up version
-- per branch that we previously had
-- when making decisions at a corporate / enterprise level
-- this type of analysis would be more useful


-- PROBLEM 4:
-- Calculate the total quantity of items sold per payment method.
-- List payment_method and total_quantity.

SELECT
	payment_method,
	COUNT(*) as tot_payments,
	SUM(quantity) as tot_qty_sold
FROM walmart
GROUP by payment_method;

-- Compares credit card vs Ewallet on a branch level
-- and which method of payment is more commonly used
SELECT
    payment_method,
    COUNT(*) AS num_branches_won
FROM (
    SELECT
        branch,
        payment_method,
        COUNT(*) AS tot_payments,
        RANK() OVER (PARTITION BY branch ORDER BY COUNT(*) DESC) AS payment_rank
    FROM walmart
    GROUP BY branch, payment_method
) AS ranked_payments
WHERE payment_rank = 1
GROUP BY payment_method
ORDER BY num_branches_won DESC;
-- Interesting finding. While Ewallet and credit card were
-- very close in terms of total count, when we look at it from
-- which payment method wins out per branch the disparity is much larger

-- PROBLEM 5
-- Determine the avg, min, and max rating of category
-- for each city
-- List the city, avg_rating, min_rating, and max_rating

SELECT
	avg(rating) as avg_rating,
	min(rating) as min_rating,
	max(rating) as max_rating,
	category,
	city
	FROM walmart
	GROUP by 4, 5;

-- advanced analysis of top avg ratings per category
-- and what city was responsible for it
SELECT 
	category,
	city,
	avg_rating
FROM (
SELECT
	avg(rating) as avg_rating,
	RANK() OVER (PARTITION BY category ORDER BY AVG(rating) DESC) AS category_rank,
	category,
	city
	FROM walmart
	GROUP by 3, 4
) AS cat_rankings
WHERE category_rank = 1;

-- Problem 6
-- Caculate the total profit for each cateogry
-- total_profit = unit_price * quantity * profit_margin
-- List category and total_profit, in desc order

SELECT
	SUM(unit_price * quantity * profit_margin) as total_profit,
	category
	FROM walmart
	GROUP by category
	ORDER by total_profit DESC;

-- PROBLEM 7
-- Determine the most common payment method for each Branch
-- Display Branch and the preffered_payment method
SELECT
    branch,
	payment_method,
	tot_payments
FROM (
    SELECT
        branch,
        payment_method,
        COUNT(*) AS tot_payments,
        RANK() OVER (PARTITION BY branch ORDER BY COUNT(*) DESC) AS payment_rank
    FROM walmart
    GROUP BY branch, payment_method
) AS ranked_payments
WHERE payment_rank = 1;

-- PROBLEM 8
-- Categorize sales into 3 groups:
-- MORNING, AFTERNOON, EVENING
-- Find the number of invoices per shift

SELECT
	branch,
CASE 
        WHEN EXTRACT(HOUR FROM time::time) < 12 THEN 'Morning'
        WHEN EXTRACT(HOUR FROM time::time) BETWEEN 12 AND 17 THEN 'Afternoon'
        ELSE 'Evening'
    END AS day_time,
	COUNT(*)
FROM walmart
GROUP BY 1,2
ORDER BY 1, 3 DESC;

-- PROBLEM 9
-- Identify 5 branches with the highest decrease ratio
-- in revenue compared to last year(2023 vs 2022)

-- rdr == last_rev - cr+rev / last_rev * 100

SELECT *,
EXTRACT(YEAR FROM TO_DATE(date, 'DD/MM/YY')) AS formatted_date
FROM walmart

-- 2022 sales
WITH revenue_2022
AS

	(
	SELECT
		branch,
		SUM(total) as revenue
	FROM walmart
	WHERE EXTRACT(YEAR FROM TO_DATE(date, 'DD/MM/YY')) = 2022
	GROUP BY 1
),

-- 2023 sales
revenue_2023
AS

	(
	SELECT
		branch,
		SUM(total) as revenue
	FROM walmart
	WHERE EXTRACT(YEAR FROM TO_DATE(date, 'DD/MM/YY')) = 2023
	GROUP BY 1
)


-- JOIN
SELECT
	last.branch,
	last.revenue as last_year_rev,
	current.revenue as curr_year_rev,
	ROUND(
		(last.revenue - current.revenue)::numeric/
		last.revenue::numeric * 100, 
		2) AS rev_dec_ratio
FROM revenue_2022 as last
JOIN 
revenue_2023 as current
ON last.branch = current.branch
WHERE
	last.revenue > current.revenue
ORDER BY rev_dec_ratio DESC
LIMIT 5;



-- Identify 5 branches with the highest increase ratio
-- in revenue compared to last year(2023 vs 2022)
SELECT
	last.branch,
	last.revenue AS last_year_rev,
	current.revenue AS curr_year_rev,
	ROUND(
		((current.revenue - last.revenue) / last.revenue * 100)::numeric, 
		2
	) AS rev_inc_ratio
FROM revenue_2022 AS last
JOIN revenue_2023 AS current
	ON last.branch = current.branch
WHERE current.revenue > last.revenue
ORDER BY rev_inc_ratio DESC
LIMIT 5;