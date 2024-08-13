CREATE TABLE sp500_stocks (
    date DATE,
    symbol VARCHAR(10),
    adj_close DECIMAL(15, 6),
    close DECIMAL(15, 6),
    high DECIMAL(15, 6),
    low DECIMAL(15, 6),
    open DECIMAL(15, 6),
    volume BIGINT
);

copy sp500_stocks
From 'D:\SQLsales\sp500_stocks.csv'
DELIMITER ','
CSV HEADER;

SELECT *
fROM sp500_stocks
lIMIT 5;

CREATE TABLE sp500_index (
    date DATE,
    Index DECIMAL(10, 2)
);


copy sp500_index
From 'D:\SQLsales\sp500_index.csv'
DELIMITER ','
CSV HEADER;

CREATE TABLE sp500_companies (
    exchange VARCHAR(10),
    symbol VARCHAR(10),
    shortname VARCHAR(255),
    longname VARCHAR(255),
    sector VARCHAR(100),
    industry VARCHAR(255),
    currentprice DECIMAL(10, 2),
    marketcap VARCHAR(50),
    ebitda VARCHAR(50),
    revenuegrowth DECIMAL(5, 3),
    city VARCHAR(100),
    state VARCHAR(10),
    country VARCHAR(100),
    fulltimeemployees INT,
    longbusinesssummary TEXT,
    weight DECIMAL(7, 6)
);


copy sp500_companies
From 'D:\SQLsales\sp500_companies.csv'
DELIMITER ','
CSV HEADER;

SELECT *
from sp500_companies
Limit 5

select *
from sp500_stocks
Limit 5;