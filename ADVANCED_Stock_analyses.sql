/*
Identify the top 10 companies by 
market capitalization and retrieve their most recent closing stock price.
*/

WITH TopCompanies AS (
    SELECT 
        symbol,
        shortname,
        sector,
        industry,
        country,
        marketcap
    FROM 
        sp500_companies
    ORDER BY 
        marketcap DESC
),
RecentPrices AS (
    SELECT 
        symbol,
        close,
        ROW_NUMBER() OVER (PARTITION BY symbol ORDER BY date DESC) AS rn
    FROM 
        sp500_stocks
)
SELECT
    C.symbol,
    C.shortname,
    C.sector,
    C.industry,
    C.country,
    C.marketcap,
    R.close
FROM
    TopCompanies AS C
LEFT JOIN
    RecentPrices AS R
ON
    C.symbol = R.symbol
WHERE
    R.rn = 1
ORDER BY
    C.marketcap DESC
LIMIT 10;

/*
Calculate the percentage change in the closing price of a 
stock over a specified period for everyday.
*/
SELECT
    symbol,
    date,
    close,
    LAG(close) OVER (PARTITION BY symbol ORDER BY date) AS previous_close,
    ROUND(((close - LAG(close) OVER (PARTITION BY symbol ORDER BY date)) / LAG(close) 
        OVER 
        (PARTITION BY symbol ORDER BY date)) * 100, 2) AS percent_change
FROM
    sp500_stocks
WHERE
    symbol = 'AAPL'  -- Replace 'AAPL' with the desired stock symbol
    AND date BETWEEN '2023-01-01' AND '2023-01-31'  -- Replace with your specific date range
ORDER BY
    date;

/*
Companies with highest percentage change over a specified date.
*/

WITH Prices AS (
    SELECT
        symbol,
        close,
        date,
        ROW_NUMBER() OVER (PARTITION BY symbol ORDER BY date) AS rn,
        ROW_NUMBER() OVER (PARTITION BY symbol ORDER BY date DESC) AS rn_max
    FROM
        sp500_stocks
    WHERE
        date BETWEEN '2023-01-01' AND '2023-12-31'  -- Replace with your specific start and end dates
)
SELECT
    p1.symbol,
    p1.close AS start_close,
    p2.close AS end_close,
    ROUND(((p2.close - p1.close) / p1.close) * 100, 2) AS percent_change
FROM
    Prices p1
JOIN
    Prices p2 ON p1.symbol = p2.symbol 
WHERE
    p1.rn = 1 AND p2.rn = p1.rn_max AND
    ROUND(((p2.close - p1.close) / p1.close) * 100, 2) is NOT NULL
ORDER BY
    percent_change DESC;


/*
Identify stocks that have consistently 
increased in price for five consecutive trading days over a specific week.
*/

WITH ConsecutiveIncreases AS (
    SELECT
        symbol,
        date,
        close,
        CASE 
            WHEN close > LAG(close, 1) OVER (PARTITION BY symbol ORDER BY date) THEN 1
            ELSE 0
        END AS is_increase
    FROM
        sp500_stocks
),
Streaks AS (
    SELECT
        symbol,
        date,
        close,
        SUM(is_increase) OVER (PARTITION BY symbol ORDER BY date ROWS BETWEEN 4 PRECEDING AND CURRENT ROW) AS increase_streak
    FROM
        ConsecutiveIncreases
)
SELECT DISTINCT
    symbol
FROM
    Streaks
WHERE
    increase_streak = 5
    AND
    date BETWEEN '2023-03-31' AND '2023-04-07'
ORDER BY
    symbol;


/*
List the top 10 stocks by year-to-date percentage gain and their corresponding sectors.
*/
WITH perc_gain AS (
WITH Prices AS (
    SELECT
        symbol,
        close,
        date,
        ROW_NUMBER() OVER (PARTITION BY symbol ORDER BY date) AS rn,
        ROW_NUMBER() OVER (PARTITION BY symbol ORDER BY date DESC) AS rn_max
    FROM
        sp500_stocks
    WHERE
        date BETWEEN '2023-01-01' AND '2023-12-31'  -- Replace with your specific start and end dates
)
SELECT
    p1.symbol,
    p1.close AS start_close,
    p2.close AS end_close,
    ROUND(((p2.close - p1.close) / p1.close) * 100, 2) AS percent_change
FROM
    Prices p1
JOIN
    Prices p2 ON p1.symbol = p2.symbol 
WHERE
    p1.rn = 1 AND p2.rn = p1.rn_max AND
    ROUND(((p2.close - p1.close) / p1.close) * 100, 2) is NOT NULL
ORDER BY
    percent_change DESC
)

SELECT
    perc_gain.percent_change,
    perc_gain.symbol,
    s.sector
FROM
    perc_gain
INNER JOIN
    sp500_companies AS s
    ON
    s.symbol=perc_gain.symbol
ORDER BY 
    perc_gain.percent_change DESC;

/*
Calculate the moving average of the closing price for each stock over any 10 days.
*/

WITH MovingAverages AS (
    SELECT
        symbol,
        AVG(close) OVER (PARTITION BY symbol ORDER BY date DESC ROWS BETWEEN 9 PRECEDING AND CURRENT ROW) AS moving_avg_10_days,
        ROW_NUMBER() OVER (PARTITION BY symbol ORDER BY date DESC) AS rn
    FROM
        sp500_stocks
    WHERE
        date <= DATE '2023-01-31'  -- Up to the desired end date
)
SELECT
    symbol,
    moving_avg_10_days
FROM
    MovingAverages
WHERE
    rn = 1;