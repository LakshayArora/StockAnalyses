CREATE TABLE amazon_sales (
    index SERIAL PRIMARY KEY,
    order_id VARCHAR(255),
    date DATE,
    status VARCHAR(50),
    fulfilment VARCHAR(50),
    sales_channel VARCHAR(50),
    ship_service_level VARCHAR(50),
    style VARCHAR(100),
    sku VARCHAR(50),
    category VARCHAR(50),
    size VARCHAR(50),
    asin VARCHAR(50),
    courier_status VARCHAR(100),
    qty INTEGER,
    currency VARCHAR(10),
    amount NUMERIC(10, 2),
    ship_city VARCHAR(100),
    ship_state VARCHAR(50),
    ship_postal_code VARCHAR(20),
    ship_country VARCHAR(50),
    promotion_ids TEXT,
    b2b BOOLEAN,
    fulfilled_by VARCHAR(50),
    unnamed_22 TEXT
);
copy amazon_sales 
FROM 'D:\SQLsales\amazon_sales.csv' 
DELIMITER ',' CSV HEADER;

SELECT *
FROM amazon_sales
Limit 5

CREATE TABLE int_sales (
    id INT PRIMARY KEY,
    date DATE,
    months int,
    customer VARCHAR(255),
    style VARCHAR(50),
    sku VARCHAR(50),
    size VARCHAR(10),
    pcs DECIMAL(10, 2),
    rate DECIMAL(10, 2),
    gross_amt DECIMAL(10, 2)
);
copy int_sales 
FROM 'D:\SQLsales\int_sales.csv' 
DELIMITER ',' CSV HEADER;

drop table amazon_sales;public
