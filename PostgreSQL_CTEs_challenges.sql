
/*Challenge 1
Write a query to find the films that have been rented more than 30 times. Your query should 
return the film_id, title, and the number of times each film has been rented (rental_count). 
Use a Common Table Expression (CTE) to first calculate the rental count for each film. Then, 
filter the results to include only those films that have been rented more than 30 times.

The expected columns in the output are:

film_id
title
rental_count
*/
--Solution Challenge 1
WITH film_rentals AS (SELECT f.film_id,f.title,COUNT(r.rental_id) AS rental_count
	FROM film f
	JOIN inventory i ON f.film_id = i.film_id
	JOIN rental r ON i.inventory_id = r.inventory_id
	GROUP BY f.film_id,f.title 
	)
SELECT film_id,title,rental_count FROM film_rentals 
WHERE rental_count > 30;


/* Challenge 2
Write a query to find the films that have an average rental duration longer than the 
overall average rental duration of all films. Your query should return the film_id, title,
and the average rental duration (rental_duration) for each film. Use a Common Table Expression 
(CTE) to first calculate the average rental duration for each film. Then, filter the results 
to include only those films whose average rental duration exceeds the overall average rental 
duration.

The expected columns in the output are:

film_id
title
rental_duration
*/
--Solution Challenge 2
    WITH film_duration_cte AS ( SELECT f.film_id, f.title,AVG (r.return_date - r.rental_date) AS rental_duration
    FROM film f
    JOIN inventory i ON f.film_id = i.film_id
    JOIN rental r ON r.inventory_id = i.inventory_id
GROUP BY f.film_id, f.title) 
	SELECT film_id, title,rental_duration FROM film_duration_cte
	WHERE rental_duration > (
    SELECT AVG (rental_duration) FROM film_duration_cte );

/*Challenge 3

Create a CTE to calculate the total rental count and total rental amount for each customer.

Use the CTE to filter customers who have rented more than the average number of films.
The DVD rental database already includes the following tables:
customer
rental
payment
Objective:
Calculate the total rental count and total rental amount for each customer, 
and list customers who have rented more than the average number of films.

Context:
In the DVD rental business, we need to understand customer behavior by calculating 
how many movies each customer has rented and how much they have spent. We will then 
identify customers who rent movies more frequently than the average customer.


Setup:
The DVD rental database already includes the following tables:

customer

rental

payment
*/

--Solution Challenge 3

	WITH rental_details_cte AS
		(  
	SELECT 
	c.customer_id, 
	first_name||' '||last_name AS customer_Name
		,   
	COUNT(r.rental_id) AS rental_count,
	SUM(amount) AS rental_amount
	FROM payment p
	JOIN rental r ON p.rental_id = r.rental_id
	JOIN customer c ON c.customer_id = r.customer_id
	GROUP BY c.customer_id 
	)SELECT 
	customer_id,
	customer_name,	
	rental_count,
	rental_amount 
	FROM rental_details_cte
	WHERE rental_count >( 
	SELECT 
	AVG(rental_count) 
	FROM rental_details_cte 
	) ;

/*
Challenge 4
Objectives:
Identify costumers who has spent more than the average amount on rentals
and list the films that they have rented
*/
--Solution 1 Challenge 4 ( without CTEs)
SELECT DISTINCT
customer_id,
customer_name,
title,
total_amount
FROM ( SELECT c.customer_id,
	  c.first_name||' '||c.last_name AS customer_name,
	  f.title,
	  SUM(p.amount)AS total_amount 
	FROM payment p
	JOIN customer c ON c.customer_id = p.customer_id
	JOIN inventory i ON i.store_id = c.store_id
	JOIN film f ON f.film_id = i.film_id
	GROUP BY c.customer_id, f.title, customer_name ) AS customer_total_amount
	WHERE CAST(total_amount AS numeric) > (
        SELECT AVG(CAST(amount AS numeric)) 
        FROM payment
	) ;

-- Solution 2 Challenge 4 ( with CTE)

WITH customer_total_amount AS (
    SELECT 
        c.customer_id,
        c.first_name || ' ' || c.last_name AS customer_name,
        SUM(p.amount) AS total_amount
    FROM 
        payment p
    JOIN 
        customer c ON c.customer_id = p.customer_id
    GROUP BY 
        c.customer_id, c.first_name, c.last_name
), 
avg_total_amount AS (
    SELECT 
        AVG(CAST(total_amount AS NUMERIC)) AS average_amount 
    FROM 
        customer_total_amount
)
SELECT 
    cta.customer_id,
    cta.customer_name,
    cta.total_amount,
    f.film_id,
    f.title
FROM  
    customer_total_amount cta
JOIN 
    rental r ON cta.customer_id = r.customer_id
JOIN 
    inventory i ON r.inventory_id = i.inventory_id
JOIN 
    film f ON i.film_id = f.film_id
WHERE 
    CAST(cta.total_amount AS NUMERIC) > (
        SELECT average_amount FROM avg_total_amount
    );

/*Challenge 5
Objective: Calculate the total rental count and total rental amount for each customer, 
identify customers who have rented more than the average number of films, and list the details 
of the films they have rented.

Context: In the DVD rental business, we need to understand customer behavior by calculating
how many movies each customer has rented and how much they have spent. We will then identify
customers who rent movies more frequently than the average customer and list the details of the
films they have rented.

Note:

High-Rental Customers: Customers who have rented more than the average number of films.

Setup:
The DVD rental database already includes the following tables:

customer

rental

payment

inventory

film

We will use these existing tables to complete the exercise.

Steps to solve the Challenge:
Create a CTE to calculate the total rental count and total rental amount for each customer.

Create a CTE to calculate the average rental count across all customers.

Create a CTE to identify customers who have rented more than the average number of
films (high-rental customers).

List the details of the films rented by these high-rental customers.

Write your SQL query (one query) to achieve the above objectives.
*/

--Solution 1 Challenge 5
WITH customer_total_amount_rentals AS (
    SELECT 
        c.customer_id,
        c.first_name || ' ' || c.last_name AS customer_name,
        SUM(p.amount) AS total_amount,
	    COUNT(r.rental_id) AS total_rentals
    FROM 
        customer c
    JOIN 
        payment p ON c.customer_id = p.customer_id
	JOIN rental r ON r.rental_id = p.rental_id
    GROUP BY 
        c.customer_id, c.first_name, c.last_name
), 
 
average_total_rentals AS 
	( SELECT 
	AVG (ctar.total_rentals) AS avg_rental_count
	FROM customer_total_amount_rentals ctar
		 )

SELECT ctar.customer_id,
       ctar.customer_name,
	   ctar.total_rentals,
	   ctar.total_amount,
	   f.title,
	   f.description
FROM customer_total_amount_rentals ctar
JOIN rental r ON r.customer_id = ctar.customer_id
JOIN inventory i ON i.inventory_id = r.inventory_id
JOIN film f ON f.film_id = i.film_id
WHERE ctar.total_rentals > (SELECT avg_rental_count FROM average_total_rentals )

--Solution 2 Challenge 5 
WITH customer_totals AS (
    SELECT 
        c.customer_id,
        c.first_name || ' ' || c.last_name AS customer_name,
        COUNT(r.rental_id) AS total_rentals,
        SUM(p.amount) AS total_amount
    FROM 
        customer c
    JOIN 
        rental r ON c.customer_id = r.customer_id
    JOIN 
        payment p ON p.rental_id = r.rental_id
    GROUP BY 
        c.customer_id, c.first_name, c.last_name
), 

average_rental_count AS (
    SELECT 
        AVG(total_rentals) AS avg_rental_count
    FROM 
        customer_totals
), 

high_rental_customers AS (
    SELECT 
        ct.customer_id,
        ct.customer_name,
        ct.total_rentals,
        ct.total_amount
    FROM 
        customer_totals ct
    WHERE 
        ct.total_rentals > (SELECT avg_rental_count FROM average_rental_count)
)

SELECT 
    hrc.customer_id,
    hrc.customer_name,
    hrc.total_rentals,
    hrc.total_amount,
    f.film_id,
    f.title,
	f.description
FROM 
    high_rental_customers hrc
JOIN 
    rental r ON hrc.customer_id = r.customer_id
JOIN 
    inventory i ON r.inventory_id = i.inventory_id
JOIN 
    film f ON i.film_id = f.film_id;
