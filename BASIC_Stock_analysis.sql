
/*
Q1 Retrieve the closing price of a specific
 stock (e.g., Apple Inc.) for a specific month/year.
*/

SELECT 
    close,
    symbol,
    date
FROM
    sp500_stocks
WHERE 
    symbol = 'AAPL' 
    AND
    EXTRACT(YEAR FROM date) = 2024
    AND
    EXTRACT(MONTH FROM date) = 6;


/* If the symbol for the company is not known 

Here we have joined two tables wherein sp500_companies contains the comapony name and
sp500_stocks contain the stock close
*/

SELECT
    close,
    s.symbol,
    date,
    shortname
FROM
    sp500_stocks as s
INNER JOIN
    sp500_companies as c
ON
    s.symbol=c.symbol
WHERE
    shortname LIKE '%Apple%'
    AND
    date = '2024-06-03';
--    EXTRACT(YEAR FROM date) = 2024
 --   AND
 --   EXTRACT(MONTH FROM date) = 6; 


/*
List all companies in the S&P 500 that belong to a specific sector
 (e.g., Technology)
*/

--Getting unique values from sector column

SELECT DISTINCT sector
FROM sp500_companies;

--Listing companies where sector = "Utilities and ordering by marketcap DESC "

SELECT
     shortname,
     symbol,
     sector,
     marketcap,
     country
FROM
     sp500_companies
--WHERE
--     sector = 'Utilities'
ORDER BY 
    marketcap DESC
LIMIT 20;

/*
Calculate the average closing price of each stock over a specific month and year
*/

SELECT 
    symbol,
    EXTRACT(YEAR FROM date) AS year_,
    EXTRACT(MONTH FROM date) AS month_,
    AVG(close) 
FROM
    sp500_stocks
WHERE
    EXTRACT(YEAR FROM date) = 2023
    AND EXTRACT(MONTH FROM date) = 2
GROUP BY
    symbol,
    EXTRACT(YEAR FROM date),
    EXTRACT(MONTH FROM date)
HAVING
     AVG(close) IS NOT NULL; --To clear if any null values due to delisting or other reasons

/*
Find the total trading volume of each stock for the specific year and month.
*/

SELECT
    symbol,
    COALESCE(SUM(volume)) as total_volume
FROM
    sp500_stocks
WHERE
    EXTRACT(YEAR FROM date) = 2024
    AND EXTRACT(MONTH FROM date) = 3
    AND volume IS NOT NULL -- to remove NULL trading volumes
GROUP BY 
    symbol
ORDER BY
    total_volume DESC;


/*
Determine the stock with the highest average closing price over the last six months.
*/

SELECT 
    symbol,
    AVG(close) AS avg_close
FROM
    sp500_stocks
WHERE
    date >= DATE_TRUNC('month', CURRENT_DATE) - INTERVAL '6 months'
GROUP BY
    symbol
ORDER BY
    AVG(close)DESC;

/*
Combine stock prices with company information to list the sector and industry of each stock.
*/

SELECT
    C.symbol,
    shortname,
    sector,
    industry,
    country,
    AVG(S.close) as avg_close,
    EXTRACT(YEAR FROM S.date) as year_
FROM
    sp500_companies as C
INNER JOIN
    sp500_stocks as S
on
    C.symbol=S.symbol
WHERE
    EXTRACT(YEAR FROM S.date) = 2024
GROUP BY
    C.symbol,
    shortname,
    sector,
    industry,
    country,
    year_
HAVING
    AVG(S.close) is not NULL
ORDER BY
    avg_close DESC
;


