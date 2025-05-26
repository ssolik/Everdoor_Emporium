-- Everdoor Emporium

/* Create database and tables */

DROP SCHEMA IF EXISTS everdoor_emporium;
CREATE SCHEMA everdoor_emporium;
USE everdoor_emporium;


CREATE TABLE customers (
	customer_id VARCHAR(255) PRIMARY KEY NOT NULL,
	full_name VARCHAR(255),
	age INT,
	gender VARCHAR(255),
	email VARCHAR(255),
	phone VARCHAR(255),
	street_address VARCHAR(255),
	city VARCHAR(255),
	state VARCHAR(255),
	zip_code VARCHAR(255),
	registration_date DATE,
	preferred_channel VARCHAR(255)
);

CREATE TABLE transactions (
	transaction_id VARCHAR(255) PRIMARY KEY,
	customer_id VARCHAR(255) NOT NULL,
	product_name VARCHAR(255),
	product_category VARCHAR(255),
	quantity INT,
	price DECIMAL(15,2),
	transaction_date DATE,
	store_location VARCHAR(255),
	payment_method VARCHAR(255),
	discount_applied INT
);

CREATE TABLE interactions (
	interaction_id VARCHAR(255) PRIMARY KEY,
	customer_id VARCHAR(255) NOT NULL,
	channel VARCHAR(255),
	interaction_type VARCHAR(255),
	interaction_date DATETIME,
	duration INT,
	page_or_product VARCHAR(255),
	session_id VARCHAR(255)
);

CREATE TABLE campaigns (
    campaign_id VARCHAR(255) PRIMARY KEY,
    campaign_name VARCHAR(255),
    campaign_type VARCHAR(255),
    start_date DATE,
    end_date DATE,
    target_segment VARCHAR(255),
    budget DECIMAL(15,2),
    impressions INT,
    clicks INT,
    conversions INT,
    conversion_rate FLOAT,
    roi FLOAT
);

CREATE TABLE customer_reviews_complete (
	review_id VARCHAR(255) PRIMARY KEY,
	customer_id VARCHAR(255) NOT NULL,
	product_name VARCHAR(255),
	product_category VARCHAR(255),
	full_name VARCHAR(255),
	transaction_date DATE,
	review_date DATE,
	rating INT,
	review_title VARCHAR(255),
	review_text TEXT
);

CREATE TABLE support_tickets (
	ticket_id VARCHAR(255) PRIMARY KEY,
	customer_id VARCHAR(255) NOT NULL,
	issue_category VARCHAR(255),
	priority VARCHAR(255),
	submission_date DATETIME,
	resolution_date DATETIME,
	resolution_status VARCHAR(255),
	resolustion_time_hours FLOAT,
	customer_satisfaction INT,
	notes TEXT
);

-- Load data into tables from .csv files

LOAD DATA INFILE "C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/campaigns.csv" INTO TABLE campaigns
FIELDS TERMINATED BY ','
IGNORE 1 LINES;


LOAD DATA INFILE "C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/customer_reviews_complete.csv" INTO TABLE customer_reviews_complete
FIELDS TERMINATED BY ','
IGNORE 1 LINES;

LOAD DATA INFILE "C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/customers.csv" INTO TABLE customers
FIELDS TERMINATED BY ','
IGNORE 1 LINES;

LOAD DATA INFILE "C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/interactions.csv" INTO TABLE interactions
FIELDS TERMINATED BY ','
IGNORE 1 LINES;

LOAD DATA INFILE "C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/support_tickets.csv" INTO TABLE support_tickets
FIELDS TERMINATED BY ','
IGNORE 1 LINES;

LOAD DATA INFILE "C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/transactions.csv" INTO TABLE transactions
FIELDS TERMINATED BY ','
IGNORE 1 LINES;

-- Validate all rows from CSV successfully loaded in db ###

/* 
Num records in Excel: 200
 Num records in SQL: 172
 After Truncating and re-loading the .csv file, Num records in SQL: 200
*/

SELECT *
FROM campaigns;


/* 
Num records in Excel: 1000
Num records in SQL: 1000
*/

SELECT *
FROM customer_reviews_complete;


-- Num records in Excel: 5000
-- Num records in SQL: 5000
SELECT *
FROM customers;


/* Num records in Excel: 100000
Num records in SQL: 100000 */

SELECT *
FROM interactions;


/* Num records in Excel: 3000
 Num records in SQL: 3000 */
SELECT *
FROM support_tickets;


-- Num records in Excel: 32296
-- Num records in SQL: 32295
SELECT *
FROM transactions;


### Create a View of Campaign names with their Campaign Type, Target Segment, Start Date and Attrition Window End Date ###
### JOIN with transaction data to analyze


CREATE VIEW campaign_dates_view AS
SELECT campaign_name, campaign_type, target_segment, start_date, (end_date + INTERVAL 30 DAY) AS attrition_window_end_date
FROM campaigns;

SELECT *
FROM campaign_dates_view;

### Campaign view with budget

SELECT campaign_name, campaign_type, target_segment, start_date, (end_date + INTERVAL 30 DAY) AS attrition_window_end_date, budget
FROM campaigns;

CREATE VIEW campaign_budget_view AS
SELECT campaign_name, campaign_type, target_segment, start_date, (end_date + INTERVAL 30 DAY) AS attrition_window_end_date, budget
FROM campaigns;

SELECT *
FROM campaign_budget_view;



### Create calculated field for order total = price * quantity in transactions table
### 

SELECT *
FROM transactions;

SELECT *
FROM campaign_dates_view c
JOIN transactions t
	ON t.transaction_date BETWEEN c.start_date AND c.attrition_window_end_date;
    
    
SELECT *
FROM campaign_dates_view c
INNER JOIN transactions t
	ON t.transaction_date BETWEEN c.start_date AND c.attrition_window_end_date
WHERE YEAR(c.start_date) = '2024'
ORDER BY campaign_name
# GROUP BY campaign_name
;

SELECT c.campaign_name, c.campaign_type, c.target_segment, c.start_date, c.attrition_window_end_date,
	t.product_name, t.product_category, (t.quantity * t.price) AS order_total, t.transaction_date
FROM campaign_dates_view c
INNER JOIN transactions t
	ON t.transaction_date BETWEEN c.start_date AND c.attrition_window_end_date
WHERE YEAR(c.start_date) = '2024'
ORDER BY campaign_name
# GROUP BY campaign_name
;


SELECT c.campaign_name, c.campaign_type, c.target_segment, c.start_date, c.attrition_window_end_date, 
	t.product_name, t.product_category, (t.quantity * t.price) AS order_total, t.transaction_date, t.transaction_id
FROM campaign_dates_view c
INNER JOIN transactions t
	ON t.transaction_date BETWEEN c.start_date AND c.attrition_window_end_date
WHERE YEAR(c.start_date) = '2024'
#GROUP BY campaign_name
ORDER BY campaign_name
;

SELECT c.campaign_name, COUNT(t.transaction_id)
FROM
(SELECT c.campaign_name, c.campaign_type, c.target_segment, c.start_date, c.attrition_window_end_date, COUNT(t.transaction_id),
	t.product_name, t.product_category, (t.quantity * t.price) AS order_total, t.transaction_date, t.transaction_id
FROM campaign_dates_view c
INNER JOIN transactions t
	ON t.transaction_date BETWEEN c.start_date AND c.attrition_window_end_date
WHERE YEAR(c.start_date) = '2024') AS cam_count
;

# GROUP BY campaign_name
# ORDER BY campaign_name


SELECT c.campaign_name, c.campaign_type, c.target_segment, c.start_date, c.attrition_window_end_date, 
	t.product_name, t.product_category, (t.quantity * t.price) AS order_total, t.transaction_date, t.transaction_id
FROM campaign_dates_view c
INNER JOIN transactions t
	ON t.transaction_date BETWEEN c.start_date AND c.attrition_window_end_date
WHERE YEAR(c.start_date) = '2020'
ORDER BY campaign_name
;


CREATE VIEW campaign_sales_2020 AS
SELECT c.campaign_name, c.campaign_type, c.target_segment, c.start_date, c.attrition_window_end_date, 
	t.product_name, t.product_category, (t.quantity * t.price) AS order_total, t.transaction_date, t.transaction_id
FROM campaign_dates_view c
INNER JOIN transactions t
	ON t.transaction_date BETWEEN c.start_date AND c.attrition_window_end_date
WHERE YEAR(c.start_date) = '2020'
;


/* Order Total by Age, Gender, Location, etc. */

SELECT t.transaction_id, t.customer_id, t.product_name, t.product_category, 
	t.quantity, t.price, (t.quantity * t.price) AS order_total, t.transaction_date, t.store_location,
    c.age, c.gender, c.customer_city, c.customer_state
FROM transactions t
JOIN customers c
	ON t.customer_id = c.customer_id
# WHERE YEAR(t.transaction_date) = '2024'
;


SELECT target_segment
FROM campaigns
WHERE YEAR(end_date) = '2024'
GROUP BY target_segment
ORDER BY target_segment
;


/*
Create Temp Table: temp_customer_transaction to JOIN transactions to customers
Export output to csv to visualize in Tableau
*/
CREATE TEMPORARY TABLE temp_customer_transaction
SELECT t.transaction_id, t.transaction_date, (t.price * t.quantity) AS order_total, t.product_name, t.product_category, t.store_location,
	c.customer_id, c.age, c.gender, c.city AS customer_city, c.state AS customer_state, c.registration_date
FROM transactions t
JOIN customers c ON
t.customer_id = c.customer_id
;

SELECT *
FROM temp_customer_transaction
;



WITH 
customer_transaction AS (
    SELECT 
        t.transaction_id, t.transaction_date, (t.price * t.quantity) AS order_total, t.product_name, t.product_category, t.store_location,
	    cus.customer_id, cus.age, cus.gender, cus.city AS customer_city, cus.state AS customer_state, cus.registration_date
    FROM transactions t
        JOIN customers cus ON t.customer_id = cus.customer_id
),  
campaign_segment AS (
    SELECT
        campaign_id, target_segment,
        CASE
            WHEN cam.target_segment IN ('Young Adults (18-25)', 'Adults (26-40)''Seniors (60+)', 'Middle-aged (41-60)', 'Seniors (60+)') THEN 'age_segment'
            WHEN cam.target_segment IN ('East Coast', 'Midwest', 'Southern States', 'West Coast') THEN 'geo_segment'
            WHEN cam.target_segment IN ('Home Improvement', 'Kitchen Enthusiasts', 'Technology Enthusiasts') THEN 'product_segment'
            ELSE ""
        END AS segment_type
    FROM campaigns cam
),  
targets AS (
    SELECT ct.transaction_id, ct.transaction_date, ct.product_category, ct.customer_state, ct.age,
        CASE
            WHEN ct.age BETWEEN 18 AND 25 THEN 'Young Adults (18-25)'
	        WHEN ct.age BETWEEN 26 AND 40 THEN 'Adults (26-40)'
            WHEN ct.age BETWEEN 41 AND 60 THEN 'Middle-aged (41-60)'
            WHEN ct.age > 60 THEN 'Seniors (60+)'
            ELSE ''
        END AS age_segment,	
        CASE
    		WHEN ct.state IN ('Connecticut', 'Maine', 'Massachusetts', 'New Hampshire', 'New Jersey', 'New York', 'Rhode Island', 'Pennsylvania', 'Vermont', 'Washington, D.C.')
    			THEN 'East Coast'
    		WHEN ct.state IN ('Illinois', 'Indiana', 'Iowa', 'Kansas', 'Michigan', 'Minnesota', 'Missouri', 'Nebraska', 'North Dakota', 'Ohio', 'South Dakota', 'Wisconsin')
    			THEN 'Midwest'
    		WHEN ct.state IN ('Alabama', 'Arkansas', 'Delaware', 'Florida', 'Georgia', 'Kentucky', 'Louisiana', 'Maryland', 'Mississippi', 'North Carolina', 'Oklahoma', 'South Carolina', 'Tennessee', 'Texas', 'Virginia', 'West Virginia')
    			THEN 'Southern States'
    		WHEN ct.state IN ('Alaska', 'Arizona', 'California', 'Colorado', 'Hawaii', 'Idaho', 'Montana', 'Nevada', 'New Mexico', 'Oregon', 'Utah', 'Washington','Wyoming')
    			THEN 'West Coast'
            ELSE ''
        END AS geo_segment,
        CASE
            WHEN ct.product_category IN ('Cookware', 'Kitchen Appliances', 'Small Kitchen Appliances') THEN 'Kitchen Enthusiasts'
		    WHEN ct.product_category IN ('Bedding', 'Furniture', 'Home Decor', 'Smart Home Devices') THEN 'Home Improvement'
		    WHEN ct.product_category IN ('Audio Equipment', 'Computer Accessories', 'Desktop Computers', 'Gaming Consoles', 'Laptops', 'Smartphones', 'Tablets', 'TVs') THEN 'Technology Enthusiasts'
            ELSE ''
        END AS product_segment
    FROM customer_transaction AS ct
)


SELECT
    cam.campaign_name, cam.campaign_type, cam.target_segment, campaign_segment.segment_type, cam.start_date, cam.end_date, (cam.end_date + INTERVAL 30 DAY) AS attrition_window_end_date,
    ct.age, ct.customer_state, ct.order_total, ct.transaction_date, ct.transaction_id, ct.product_category, ct.store_location, ct.gender, ct.customer_city
FROM
    campaigns cam
    INNER JOIN customer_transaction ct
        ON ct.transaction_date BETWEEN cam.start_date AND (cam.end_date + INTERVAL 30 DAY)
    JOIN campaign_segment
        ON cam.campaign_id = campaign_segment.campaign_id
    LEFT JOIN targets AS target_age
        ON cam.target_segment = target_age.age_segment
    LEFT JOIN targets AS target_geo
        ON cam.target_segment = target_geo.geo_segment
    LEFT JOIN targets AS target_product
        ON cam.target_segment = target_product.product_segment
;    

/*
JOIN temp_customer_transaction to campaigns table to identify sales totals per campaign
Export output to csv to visualize in Tableau
*/
/* This query returns all of the transations between Start Date and Attrition Window End Date for each Campaign in a given year */

SELECT c.campaign_name, c.campaign_type, c.target_segment, c.start_date, c.end_date, (c.end_date + INTERVAL 30 DAY) AS attrition_window_end_date, 
	tct.age, tct.state, tct.order_total, tct.transaction_date, tct.transaction_id, tct.product_category, tct.store_location
FROM campaigns c
INNER JOIN temp_customer_transaction tct
	ON tct.transaction_date BETWEEN c.start_date AND (c.end_date + INTERVAL 30 DAY)
WHERE YEAR(c.end_date) = '2024' AND
	c.target_segment = 
    (CASE
		WHEN c.target_segment = 'East Coast' THEN 
			IF((tct.state IN
				('Connecticut', 'Maine', 'Massachusetts', 'New Hampshire', 'New Jersey', 'New York', 
					'Rhode Island', 'Pennsylvania', 'Vermont', 'Washington, D.C.')
				), 'East Coast', '')
		WHEN c.target_segment = 'Adults (26-40)' THEN IF(tct.age BETWEEN 26 AND 40, 'Adults (26-40)', '')
		WHEN c.target_segment = 'In-Store Shoppers' THEN IF(tct.store_location != 'Online', 'In-Store Shoppers', '')
		WHEN c.target_segment = 'Online Shoppers' THEN IF(tct.store_location = 'Online', 'In-Store Shoppers', '')
		WHEN c.target_segment = 'Middle-aged (41-60)' THEN IF(tct.age BETWEEN 41 AND 60, 'Middle-aged (41-60)', '')
		WHEN c.target_segment = 'Kitchen Enthusiasts' THEN IF(tct.product_category IN ('Cookware', 'Kitchen Appliances', 'Small Kitchen Appliances'), 'Kitchen Enthusiasts', '')
		WHEN c.target_segment = 'Midwest' THEN 
			IF((tct.state IN
				('Illinois', 'Indiana', 'Iowa', 'Kansas', 'Michigan', 'Minnesota', 'Missouri', 'Nebraska', 'North Dakota', 'Ohio', 'South Dakota', 'Wisconsin')
				), 'Midwest', '')
		WHEN c.target_segment = 'Home Improvement' THEN IF(tct.product_category IN ('Bedding', 'Furniture', 'Home Decor', 'Smart Home Devices'), 'Home Improvement', '')
		WHEN c.target_segment = 'Seniors (60+)' THEN IF(tct.age > 60, 'Seniors (60+)', '')
		WHEN c.target_segment = 'West Coast' THEN 
			IF((tct.state IN
				('Alaska', 'Arizona', 'California', 'Colorado', 'Hawaii', 'Idaho', 'Montana', 'Nevada', 'New Mexico', 
				'Oregon', 'Utah', 'Washington','Wyoming')
				), 'West Coast', '')
		WHEN c.target_segment = 'Southern States' THEN 
			IF((tct.state IN
				('Alabama', 'Arkansas', 'Delaware', 'Florida', 'Georgia', 'Kentucky', 'Louisiana', 'Maryland', 'Mississippi', 'North Carolina', 
				'Oklahoma', 'South Carolina', 'Tennessee', 'Texas', 'Virginia', 'West Virginia')
				), 'Southern States', '')
		WHEN c.target_segment = 'Young Adults (18-25)' THEN IF(tct.age BETWEEN 18 AND 25, 'Young Adults (18-25)', '')
		WHEN c.target_segment = 'Technology Enthusiasts' THEN IF(tct.product_category IN ('Audio Equipment', 'Computer Accessories', 'Desktop Computers',
			'Gaming Consoles', 'Laptops', 'Smartphones', 'Tablets', 'TVs'), 'Technology Enthusiasts', '')
		ELSE 'Not Found'
    END)
;
