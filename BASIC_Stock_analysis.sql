/*
Retrieve the closing price of a specific stock (e.g., Apple Inc.) for a specific month/year.
*/

SELECT 
    close,
    symbol,
    date
FROM
    sp500_stocks
WHERE 
    symbol = 'AAPL'  -- Filter for Apple Inc. using its stock symbol
    AND EXTRACT(YEAR FROM date) = 2024  -- Filter for the year 2024
    AND EXTRACT(MONTH FROM date) = 6;  -- Filter for the month of June

/* 
If the symbol for the company is not known 
Here we join two tables: sp500_companies contains the company name, 
and sp500_stocks contains the stock close.
*/

SELECT
    close,
    s.symbol,
    date,
    shortname
FROM
    sp500_stocks AS s
INNER JOIN
    sp500_companies AS c ON s.symbol = c.symbol  -- Join sp500_stocks with sp500_companies on the stock symbol
WHERE
    shortname LIKE '%Apple%'  -- Filter for companies with "Apple" in their name
    AND date = '2024-06-03';  -- Filter for a specific date

/*
List all companies in the S&P 500 that belong to a specific sector (e.g., Technology).
*/

--SELECT DISTINCT sector   to Retrieve unique sector values
--FROM sp500_companies;

SELECT
     shortname,
     symbol,
     sector,
     marketcap,
     country
FROM
     sp500_companies
WHERE 
    sector = 'Technology'
ORDER BY 
    marketcap DESC  -- Order the results by market capitalization in descending order
LIMIT 20;  -- Limit the results to the top 20 companies

/*
Calculate the average closing price of each stock over a specific month and year.
*/

SELECT 
    symbol,
    EXTRACT(YEAR FROM date) AS year_,
    EXTRACT(MONTH FROM date) AS month_,
    AVG(close)  -- Calculate the average closing price
FROM
    sp500_stocks
WHERE
    EXTRACT(YEAR FROM date) = 2023  -- Filter for the year 2023
    AND EXTRACT(MONTH FROM date) = 2  -- Filter for the month of February
GROUP BY
    symbol,
    EXTRACT(YEAR FROM date),
    EXTRACT(MONTH FROM date)
HAVING
     AVG(close) IS NOT NULL; -- Ensure the average closing price is not NULL

/*
Find the total trading volume of each stock for a specific year and month.
*/

SELECT
    symbol,
    COALESCE(SUM(volume), 0) AS total_volume  -- Sum the trading volumes, replacing NULL with 0
FROM
    sp500_stocks
WHERE
    EXTRACT(YEAR FROM date) = 2024  -- Filter for the year 2024
    AND EXTRACT(MONTH FROM date) = 3  -- Filter for the month of March
GROUP BY 
    symbol
ORDER BY
    total_volume DESC;  -- Order the results by total trading volume in descending order

/*
Determine the stock with the highest average closing price over the last six months.
*/

SELECT 
    symbol,
    AVG(close) AS avg_close  -- Calculate the average closing price
FROM
    sp500_stocks
WHERE
    date >= DATE_TRUNC('month', CURRENT_DATE) - INTERVAL '6 months'  -- Filter for the last six months
GROUP BY
    symbol
ORDER BY
    AVG(close) DESC;  -- Order the results by average closing price in descending order

/*
Combine stock prices with company information to list the sector and industry of each stock.
*/

SELECT
    C.symbol,
    shortname,
    sector,
    industry,
    country,
    AVG(S.close) AS avg_close,  -- Calculate the average closing price
    EXTRACT(YEAR FROM S.date) AS year_
FROM
    sp500_companies AS C
INNER JOIN
    sp500_stocks AS S ON C.symbol = S.symbol  -- Join company and stock data on the stock symbol
WHERE
    EXTRACT(YEAR FROM S.date) = 2024  -- Filter for the year 2024
GROUP BY
    C.symbol,
    shortname,
    sector,
    industry,
    country,
    year_
HAVING
    AVG(S.close) IS NOT NULL  -- Ensure the average closing price is not NULL
ORDER BY
    avg_close DESC;  -- Order the results by average closing price in descending order

/*
Identify the correlation between the trading volume and the stock price for each company.
*/

SELECT
    symbol,
    CORR(close, volume) AS price_volume_correlation  -- Calculate the Pearson correlation between closing price and volume
FROM
    sp500_stocks
GROUP BY
    symbol  -- Group by each stock symbol to calculate correlation per company
ORDER BY
    price_volume_correlation DESC;  

/*
Find the stock that had the highest single-day percentage increase in price in the last year.
*/

SELECT
    symbol,
    date,
    ROUND(((close - previous_close) / previous_close) * 100, 2) AS highest_perc_inc
FROM (
    SELECT
        symbol,
        date,
        close,
        LAG(close) OVER (PARTITION BY symbol ORDER BY date) AS previous_close
    FROM
        sp500_stocks
    WHERE
        EXTRACT(YEAR FROM date) = 2023  -- Replace 2023 with the desired year
) AS subquery
WHERE
    previous_close IS NOT NULL  -- Exclude rows where the previous day's close is NULL
ORDER BY
    highest_perc_inc DESC