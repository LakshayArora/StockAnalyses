/* 
Identify the top 10 companies by market capitalization and retrieve their most recent closing stock price.
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
        marketcap DESC  -- Order by market capitalization in descending order
),
RecentPrices AS (
    SELECT 
        symbol,
        close,
        ROW_NUMBER() OVER (PARTITION BY symbol ORDER BY date DESC) AS rn  -- Get the most recent closing price per symbol
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
    RecentPrices AS R ON C.symbol = R.symbol  -- Join top companies with their most recent closing prices
WHERE
    R.rn = 1  -- Filter to keep only the most recent price
ORDER BY
    C.marketcap DESC  -- Order by market capitalization
LIMIT 10;  -- Limit to top 10 companies

/*
Calculate the percentage change in the closing price of a stock over a specified period for every day.
*/

SELECT
    symbol,
    date,
    close,
    LAG(close) OVER (PARTITION BY symbol ORDER BY date) AS previous_close,  -- Get the previous day's closing price
    ROUND(((close - LAG(close) OVER (PARTITION BY symbol ORDER BY date)) / LAG(close) 
        OVER (PARTITION BY symbol ORDER BY date)) * 100, 2) AS percent_change  -- Calculate the percentage change
FROM
    sp500_stocks
WHERE
    symbol = 'AAPL'  -- Replace 'AAPL' with the desired stock symbol
    AND date BETWEEN '2023-01-01' AND '2023-01-31'  -- Filter by the specific date range
ORDER BY
    date;  -- Order by date to see changes over time

/*
Companies with the highest percentage change over a specified date range.
*/

WITH Prices AS (
    SELECT
        symbol,
        close,
        date,
        ROW_NUMBER() OVER (PARTITION BY symbol ORDER BY date) AS rn,  -- Get the earliest date row number per symbol
        ROW_NUMBER() OVER (PARTITION BY symbol ORDER BY date DESC) AS rn_max  -- Get the latest date row number per symbol
    FROM
        sp500_stocks
    WHERE
        date BETWEEN '2023-01-01' AND '2023-12-31'  -- Replace with your specific start and end dates
)
SELECT
    p1.symbol,
    p1.close AS start_close,
    p2.close AS end_close,
    ROUND(((p2.close - p1.close) / p1.close) * 100, 2) AS percent_change  -- Calculate the percentage change
FROM
    Prices p1
JOIN
    Prices p2 ON p1.symbol = p2.symbol  -- Join start and end prices for the same symbol
WHERE
    p1.rn = 1 AND p2.rn = p1.rn_max AND  -- Filter for the first and last dates
    ROUND(((p2.close - p1.close) / p1.close) * 100, 2) IS NOT NULL  -- Ensure the calculation is valid
ORDER BY
    percent_change DESC;  -- Order by percentage change in descending order

/*
Identify stocks that have consistently increased in price for five consecutive trading days over a specific week.
*/

WITH ConsecutiveIncreases AS (
    SELECT
        symbol,
        date,
        close,
        CASE 
            WHEN close > LAG(close, 1) OVER (PARTITION BY symbol ORDER BY date) THEN 1  -- Check if the price increased from the previous day
            ELSE 0
        END AS is_increase  -- Mark 1 for increase, 0 otherwise
    FROM
        sp500_stocks
),
Streaks AS (
    SELECT
        symbol,
        date,
        close,
        SUM(is_increase) OVER (PARTITION BY symbol ORDER BY date ROWS BETWEEN 4 PRECEDING AND CURRENT ROW) AS increase_streak  -- Sum increases over the last 5 days
    FROM
        ConsecutiveIncreases
)
SELECT DISTINCT
    symbol
FROM
    Streaks
WHERE
    increase_streak = 5  -- Filter for a streak of 5 consecutive increases
    AND date BETWEEN '2023-03-31' AND '2023-04-07'  -- Specify the week to analyze
ORDER BY
    symbol;  -- Order by stock symbol

/*
List the top 10 stocks by year-to-date percentage gain and their corresponding sectors.
*/

WITH perc_gain AS (
WITH Prices AS (
    SELECT
        symbol,
        close,
        date,
        ROW_NUMBER() OVER (PARTITION BY symbol ORDER BY date) AS rn,  -- Get the earliest date row number per symbol
        ROW_NUMBER() OVER (PARTITION BY symbol ORDER BY date DESC) AS rn_max  -- Get the latest date row number per symbol
    FROM
        sp500_stocks
    WHERE
        date BETWEEN '2023-01-01' AND '2023-12-31'  -- Replace with your specific start and end dates
)
SELECT
    p1.symbol,
    p1.close AS start_close,
    p2.close AS end_close,
    ROUND(((p2.close - p1.close) / p1.close) * 100, 2) AS percent_change  -- Calculate the percentage gain
FROM
    Prices p1
JOIN
    Prices p2 ON p1.symbol = p2.symbol  -- Join start and end prices for the same symbol
WHERE
    p1.rn = 1 AND p2.rn = p1.rn_max AND
    ROUND(((p2.close - p1.close) / p1.close) * 100, 2) IS NOT NULL  -- Ensure the calculation is valid
ORDER BY
    percent_change DESC  -- Order by percentage gain in descending order
)

SELECT
    perc_gain.percent_change,
    perc_gain.symbol,
    s.sector
FROM
    perc_gain
INNER JOIN
    sp500_companies AS s ON s.symbol = perc_gain.symbol  -- Join with the sector information
ORDER BY 
    perc_gain.percent_change DESC;  -- Order by percentage gain

/*
Calculate the moving average of the closing price for each stock over any 10 days.
*/

WITH MovingAverages AS (
    SELECT
        symbol,
        AVG(close) OVER (PARTITION BY symbol ORDER BY date DESC ROWS BETWEEN 9 PRECEDING AND CURRENT ROW) AS moving_avg_10_days,  -- Calculate the 10-day moving average
        ROW_NUMBER() OVER (PARTITION BY symbol ORDER BY date DESC) AS rn  -- Rank rows by date in descending order
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
    rn = 1;  -- Select the most recent moving average for each symbol