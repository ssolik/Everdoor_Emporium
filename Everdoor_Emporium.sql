
-- Everdoor Emporium

/* -----------------------------
   Create database and tables
------------------------------*/

-- Drop schema if it already exists and create a new one
DROP SCHEMA IF EXISTS everdoor_emporium;
CREATE SCHEMA everdoor_emporium;
USE everdoor_emporium;

-- Table to store customer details
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

-- Table to store transaction records
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

-- Table to store customer interaction data
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

-- Table to store marketing campaign information
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

-- Table to store customer reviews
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

-- Table to store customer support tickets
CREATE TABLE support_tickets (
	ticket_id VARCHAR(255) PRIMARY KEY,
	customer_id VARCHAR(255) NOT NULL,
	issue_category VARCHAR(255),
	priority VARCHAR(255),
	submission_date DATETIME,
	resolution_date DATETIME,
	resolution_status VARCHAR(255),
	resolution_time_hours FLOAT,
	customer_satisfaction INT,
	notes TEXT
);


/* -----------------------------------
   Load data into tables from CSVs
------------------------------------*/

-- Load each CSV file into its respective table
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


/* -----------------------------
   Validate row counts
------------------------------*/

-- Quick checks to ensure data load matches original Excel counts
SELECT * FROM campaigns;  -- Expected: 200
SELECT * FROM customer_reviews_complete;  -- Expected: 1000
SELECT * FROM customers;  -- Expected: 5000
SELECT * FROM interactions;  -- Expected: 100000
SELECT * FROM support_tickets;  -- Expected: 3000
SELECT * FROM transactions;  -- Expected: 32296 (note: only 32295 loaded)

/* --------------------------------------------
   Analysis: Map transactions to campaign targets
---------------------------------------------*/

WITH 
-- Join transactions with customer data and calculate order totals
customer_transaction AS (
    SELECT 
        t.transaction_id, 
        t.transaction_date, 
        (t.price * t.quantity) AS order_total, 
        t.product_name, 
        t.product_category, 
        t.store_location,
        cus.customer_id, 
        cus.age, 
        cus.gender, 
        cus.city AS customer_city, 
        cus.state AS customer_state, 
        cus.registration_date
    FROM transactions t
    JOIN customers cus ON t.customer_id = cus.customer_id
),  

-- Classify campaign types and define their attrition windows
campaign_segment AS (
    SELECT
        campaign_id,
        campaign_name, 
        target_segment,
        start_date, 
        end_date, 
        (cam.end_date + INTERVAL 30 DAY) AS attrition_window_end_date,
        CASE
            WHEN cam.target_segment IN ('Young Adults (18-25)', 'Adults (26-40)','Seniors (60+)', 'Middle-aged (41-60)', 'Seniors (60+)') THEN 'age_segment'
            WHEN cam.target_segment IN ('East Coast', 'Midwest', 'Southern States', 'West Coast') THEN 'geo_segment'
            WHEN cam.target_segment IN ('Home Improvement', 'Kitchen Enthusiasts', 'Technology Enthusiasts') THEN 'product_segment'
            ELSE ""
        END AS segment_type
    FROM campaigns cam
),  

-- Derive segments based on transaction and customer characteristics
targets AS (
    SELECT 
        ct.transaction_id, 
        ct.transaction_date, 
        ct.order_total, 
        ct.product_name, 
        ct.product_category, 
        ct.store_location, 
        ct.customer_city, 
        ct.customer_state, 
        ct.age, 
        ct.gender, 
        -- Age-based segment
        CASE
            WHEN ct.age BETWEEN 18 AND 25 THEN 'Young Adults (18-25)'
            WHEN ct.age BETWEEN 26 AND 40 THEN 'Adults (26-40)'
            WHEN ct.age BETWEEN 41 AND 60 THEN 'Middle-aged (41-60)'
            WHEN ct.age > 60 THEN 'Seniors (60+)'
            ELSE ''
        END AS age_segment,
        -- Geography-based segment
        CASE
            WHEN ct.customer_state IN ('Connecticut', 'Maine', 'Massachusetts', 'New Hampshire', 'New Jersey', 'New York', 'Rhode Island', 'Pennsylvania', 'Vermont', 'Washington, D.C.')
                THEN 'East Coast'
            WHEN ct.customer_state IN ('Illinois', 'Indiana', 'Iowa', 'Kansas', 'Michigan', 'Minnesota', 'Missouri', 'Nebraska', 'North Dakota', 'Ohio', 'South Dakota', 'Wisconsin')
                THEN 'Midwest'
            WHEN ct.customer_state IN ('Alabama', 'Arkansas', 'Delaware', 'Florida', 'Georgia', 'Kentucky', 'Louisiana', 'Maryland', 'Mississippi', 'North Carolina', 'Oklahoma', 'South Carolina', 'Tennessee', 'Texas', 'Virginia', 'West Virginia')
                THEN 'Southern States'
            WHEN ct.customer_state IN ('Alaska', 'Arizona', 'California', 'Colorado', 'Hawaii', 'Idaho', 'Montana', 'Nevada', 'New Mexico', 'Oregon', 'Utah', 'Washington','Wyoming')
                THEN 'West Coast'
            ELSE ''
        END AS geo_segment,
        -- Product category-based segment
        CASE
            WHEN ct.product_category IN ('Cookware', 'Kitchen Appliances', 'Small Kitchen Appliances') THEN 'Kitchen Enthusiasts'
            WHEN ct.product_category IN ('Bedding', 'Furniture', 'Home Decor', 'Smart Home Devices') THEN 'Home Improvement'
            WHEN ct.product_category IN ('Audio Equipment', 'Computer Accessories', 'Desktop Computers', 'Gaming Consoles', 'Laptops', 'Smartphones', 'Tablets', 'TVs') THEN 'Technology Enthusiasts'
            ELSE ''
        END AS product_segment
    FROM customer_transaction AS ct
)

-- Final selection: match transactions to active campaigns within the attribution window and by target segment
SELECT
    cs.campaign_id,
	cs.campaign_name, 
    cs.target_segment, 
    cs.segment_type, 
    cs.start_date, 
    cs.attrition_window_end_date,
	t.transaction_id,
    t.age, 
    t.customer_city, 
    t.customer_state, 
    t.order_total, 
    t.transaction_date, 
    t.product_category, 
    t.store_location, 
    t.gender
FROM campaign_segment cs
JOIN targets t
    ON t.transaction_date BETWEEN cs.start_date AND cs.attrition_window_end_date
    AND (
        cs.target_segment = t.age_segment 
        OR cs.target_segment = t.geo_segment 
        OR cs.target_segment = t.product_segment
    )
WHERE YEAR(cs.end_date) = '2024'
ORDER BY t.transaction_id, cs.campaign_id;

/* ---------------------------------------------------
   Export output to csv to visualize in Tableau
------------------------------------------------------*/
