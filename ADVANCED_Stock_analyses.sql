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


/*
Rank stocks within each sector by their year-to-date performance.
*/

WITH YTD_Performance AS (
    SELECT
        s.symbol,
        c.sector,
        s.date,
        FIRST_VALUE(s.close) OVER (PARTITION BY s.symbol ORDER BY s.date ASC) AS start_close,  -- Get the first closing price of the year
        LAST_VALUE(s.close) OVER (PARTITION BY s.symbol ORDER BY s.date ASC RANGE BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING) AS end_close  -- Get the last closing price up to the current date
    FROM
        sp500_stocks AS s
    INNER JOIN
        sp500_companies AS c ON s.symbol = c.symbol
    WHERE
        s.date BETWEEN '2024-01-01' AND '2024-08-01'  -- Adjust for the date as YTD is a bit tricky due to lack of data after when dataset was downloaded
)
SELECT
    symbol,
    sector,
    ROUND(((end_close - start_close) / start_close) * 100, 2) AS ytd_percent_change,  -- Calculate YTD percentage change
    RANK() OVER (PARTITION BY sector ORDER BY ((end_close - start_close) / start_close) DESC) AS sector_rank  -- Rank within each sector by YTD performance
FROM
    YTD_Performance
GROUP BY
    symbol,
    sector,
    start_close,
    end_close
ORDER BY
    sector,
    sector_rank;

/*

Retrieve the list of stocks that have a higher closing price than a specified stock on the same day.
*/

SELECT
    s.symbol,
    s.date,
    s.close
FROM
    sp500_stocks AS s
WHERE
    s.date = '2023-08-17'  -- Filter for the specific date
    AND s.close > (
        SELECT
            close
        FROM
            sp500_stocks
        WHERE
            date = '2023-08-17'  -- Compare with the closing price on the same date
            AND symbol = 'AAPL'  -- Get the closing price of AAPL
    )
    AND s.symbol <> 'AAPL'  -- Exclude AAPL from the results
ORDER BY
    s.close DESC;  -- Order by closing price in descending order

/*
Find the stocks with a closing price above the average closing price
 of all stocks on the same date.
*/

SELECT
    s.symbol,
    s.date,
    s.close
FROM
    sp500_stocks AS s
WHERE
    s.date = '2023-08-17'  -- Filter for the specific date
    AND s.close > (
        SELECT
            AVG(close)
        FROM
            sp500_stocks
        WHERE
            date = '2023-08-17'  -- Calculate the average close price for the same date
    )
ORDER BY
    s.close DESC;  -- Order by closing price in descending order

/*
Rank the sector based on the most companies in the top 10% by market capitalization.
*/

WITH MarketCapRanking AS (
    SELECT
        symbol,
        sector,
        marketcap,
        NTILE(10) OVER (ORDER BY marketcap DESC) AS marketcap_decile  -- Rank companies into deciles by market cap
    FROM
        sp500_companies
)
SELECT
    sector,
    COUNT(*) AS num_companies
FROM
    MarketCapRanking
WHERE
    marketcap_decile = 1
GROUP BY
    sector
ORDER BY
    num_companies DESC  -- Order by the number of companies in descending order 

/*
Calculate the cumulative return of each stock over a specified year.
*/

WITH StockYearlyPrices AS (
    SELECT
        symbol,
        FIRST_VALUE(close) OVER (PARTITION BY symbol ORDER BY date ASC) AS first_close,  -- First closing price of the year
        LAST_VALUE(close) OVER (PARTITION BY symbol ORDER BY date ASC RANGE BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING) AS last_close  -- Last closing price of the year
    FROM
        sp500_stocks
    WHERE
        EXTRACT(YEAR FROM date) = 2023  -- Specify the year 
)
SELECT
    symbol,
    ROUND(((last_close - first_close) / first_close) * 100, 2) AS cumulative_return  -- Calculate the cumulative return as a percentage
FROM
    StockYearlyPrices
WHERE
    (last_close - first_close) is NOT NULL
GROUP BY
    symbol,
    first_close,
    last_close
ORDER BY
    cumulative_return DESC;  -- Order by cumulative return in descending order