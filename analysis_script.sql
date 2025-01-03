----------------------------
-- COVID-19 ANALYSIS (CANADA)
----------------------------

-- Quick View of Tables
SELECT *
FROM dbo.covid_deaths;

SELECT *
FROM dbo.covid_vaccs;

SELECT *
FROM dbo.tsx;  

-----------------------
-- ANALYSIS BY LOCATION
-----------------------

-- 1) Worldwide > Total Cases, Total Deaths & Death Rate by Country and Date
SELECT 
    d.location       AS region,
    d.date           AS record_date,
    d.total_cases    AS cum_infections,
    d.total_deaths   AS cum_fatalities,
    (d.total_deaths / NULLIF(d.total_cases, 0)) * 100 AS fatality_rate
FROM dbo.covid_deaths AS d
WHERE d.continent IS NOT NULL
ORDER BY d.location, d.date;

-- 2) Canada > Total Cases, Total Deaths & Death Rate by Date
SELECT 
    d.location       AS region,
    d.date           AS record_date,
    d.total_cases    AS cum_infections,
    d.total_deaths   AS cum_fatalities,
    (d.total_deaths / NULLIF(d.total_cases, 0)) * 100 AS fatality_rate
FROM dbo.covid_deaths AS d
WHERE d.location = 'Canada'
ORDER BY d.date;

-- 3) Worldwide > Infection Rate per Population by Country & Date
SELECT 
    d.location     AS region,
    d.date         AS record_date,
    d.total_cases  AS cum_infections,
    d.population   AS pop_count,
    (d.total_cases / NULLIF(d.population, 0)) * 100 AS infection_percentage
FROM dbo.covid_deaths AS d
WHERE d.continent IS NOT NULL
ORDER BY d.location, d.date;

-- 4) Canada > Infection Rate per Population by Date
SELECT 
    d.location     AS region,
    d.date         AS record_date,
    d.total_cases  AS cum_infections,
    d.population   AS pop_count,
    (d.total_cases / NULLIF(d.population, 0)) * 100 AS infection_percentage
FROM dbo.covid_deaths AS d
WHERE d.location = 'Canada'
ORDER BY d.date;

-- 5) Worldwide > Countries with Highest Infection Rate compared to Population
SELECT 
    d.location                             AS region,
    d.population                           AS pop_count,
    MAX(d.total_cases)                     AS highest_cum_infections,
    MAX((d.total_cases / NULLIF(d.population,0))) * 100 AS infection_percentage
FROM dbo.covid_deaths AS d
GROUP BY d.location, d.population
ORDER BY infection_percentage DESC;

-- 6) Canada > Overall Highest Infection Rate
SELECT 
    d.location                             AS region,
    d.population                           AS pop_count,
    MAX(d.total_cases)                     AS highest_cum_infections,
    MAX((d.total_cases / NULLIF(d.population,0))) * 100 AS infection_percentage
FROM dbo.covid_deaths AS d
WHERE d.location = 'Canada'
GROUP BY d.location, d.population;

-- 7) Worldwide > Highest Death Count per Population & Death Rate
SELECT 
    d.location                            AS region,
    d.population                          AS pop_count,
    MAX(d.total_deaths)                   AS highest_cum_fatalities,
    (MAX(d.total_deaths) / NULLIF(d.population,0)) * 100 AS fatality_rate_by_pop
FROM dbo.covid_deaths AS d
WHERE d.continent IS NOT NULL
GROUP BY d.location, d.population
ORDER BY fatality_rate_by_pop DESC;

-- 8) Canada > Highest Death Count by Population & Death Rate
SELECT 
    d.location                            AS region,
    d.population                          AS pop_count,
    MAX(d.total_deaths)                   AS highest_cum_fatalities,
    (MAX(d.total_deaths) / NULLIF(d.population,0)) * 100 AS fatality_rate_by_pop
FROM dbo.covid_deaths AS d
WHERE d.location = 'Canada'
GROUP BY d.location, d.population;

-------------------------
-- ANALYSIS BY CONTINENT
-------------------------

-- Worldwide > Infection Rate & Death Rate by Continent
SELECT 
    cd.location                       AS region,
    cd.population                     AS pop_count,
    MAX(cd.total_cases)              AS cum_infections,
    MAX(cd.total_deaths)             AS cum_fatalities,
    (MAX(cd.total_cases)/NULLIF(cd.population,0)) * 100 AS infection_percentage,
    (MAX(cd.total_deaths)/NULLIF(MAX(cd.total_cases),0)) * 100 AS fatality_perc
FROM dbo.covid_deaths AS cd
JOIN dbo.covid_vaccs AS cv
    ON cd.date = cv.date 
    AND cd.location = cv.location
WHERE cd.continent IS NULL
  AND cd.location NOT IN ('World','International','European Union')
GROUP BY cd.continent, cd.location, cd.population
ORDER BY infection_percentage DESC;

----------------------------------
-- ANALYSIS BY VACCINATION (WORLD)
----------------------------------

-- 10) Worldwide > Rolling Vaccinations by Country & Date
SELECT 
    cd.continent            AS area,
    cd.location             AS region,
    cd.date                 AS record_date,
    cd.population           AS pop_count,
    cv.new_vaccinations     AS daily_vaccinations,
    SUM(CONVERT(INT, cv.new_vaccinations)) OVER(
        PARTITION BY cd.location
        ORDER BY cd.location, cd.date
    ) AS rolling_vaccinations
FROM dbo.covid_deaths AS cd
JOIN dbo.covid_vaccs AS cv
    ON cd.location = cv.location 
    AND cd.date = cv.date
WHERE cd.continent IS NOT NULL
ORDER BY cd.location, cd.date;

-- 11) Canada > Rolling Vaccinations by Date
SELECT 
    cd.continent            AS area,
    cd.location             AS region,
    cd.date                 AS record_date,
    cd.population           AS pop_count,
    cv.new_vaccinations     AS daily_vaccinations,
    SUM(CONVERT(INT, cv.new_vaccinations)) OVER(
        PARTITION BY cd.location
        ORDER BY cd.location, cd.date
    ) AS rolling_vaccinations
FROM dbo.covid_deaths AS cd
JOIN dbo.covid_vaccs AS cv
    ON cd.location = cv.location 
    AND cd.date = cv.date
WHERE cd.location = 'Canada'
ORDER BY cd.location, cd.date;

-- 12) Canada > Rolling Vaccinations & Percentage of Vaccinated Population (using CTE)
WITH can_vaccination_roll AS
(
    SELECT 
        cd.continent         AS area,
        cd.location          AS region,
        cd.date              AS record_date,
        cd.population        AS pop_count,
        cv.new_vaccinations  AS daily_vaccinations,
        SUM(CONVERT(INT, cv.new_vaccinations)) OVER(
            PARTITION BY cd.location
            ORDER BY cd.location, cd.date
        ) AS rolling_vaccinations
    FROM dbo.covid_deaths AS cd
    JOIN dbo.covid_vaccs AS cv
        ON cd.location = cv.location 
        AND cd.date = cv.date
    WHERE cd.continent IS NOT NULL
      AND cd.location = 'Canada'
)
SELECT 
    area,
    region,
    record_date,
    pop_count,
    daily_vaccinations,
    rolling_vaccinations,
    (rolling_vaccinations / NULLIF(pop_count,0)) * 100 AS vaccinated_percentage
FROM can_vaccination_roll;

-- TEMP TABLE creation
DROP TABLE IF EXISTS perc_pop_vaccinated;
CREATE TABLE perc_pop_vaccinated
(
    area               NVARCHAR(255),
    region             NVARCHAR(255),
    record_date        DATETIME,
    pop_count          NUMERIC,
    daily_vaccinations NUMERIC,
    rolling_vaccinations NUMERIC
);

-- Insert data into TEMP TABLE
INSERT INTO perc_pop_vaccinated
SELECT 
    cd.continent        AS area,
    cd.location         AS region,
    cd.date             AS record_date,
    cd.population       AS pop_count,
    cv.new_vaccinations AS daily_vaccinations,
    SUM(CONVERT(INT, cv.new_vaccinations)) OVER(
        PARTITION BY cd.location
        ORDER BY cd.location, cd.date
    ) AS rolling_vaccinations
FROM dbo.covid_deaths AS cd
JOIN dbo.covid_vaccs AS cv
    ON cd.location = cv.location
    AND cd.date = cv.date
WHERE cd.continent IS NOT NULL;

SELECT 
    *,
    (rolling_vaccinations / NULLIF(pop_count,0)) * 100 AS vaccinated_percentage
FROM perc_pop_vaccinated
WHERE region = 'Canada';

-------------------------------------
-- ANALYSIS OF IMPACT ON TSX (CANADA)
-------------------------------------

-- 13) Canada > Infection & Death Rate vs TSX during “MCO 1.0” 
-- Start = 2020-04-16 (+30 days), End = 2020-07-02 (+60 days)
SELECT 
    cd.date                                  AS record_date,
    cd.location                              AS region,
    cd.new_cases                             AS daily_infections,
    cd.total_cases                           AS cum_infections,
    cd.new_deaths                            AS daily_fatalities,
    cd.total_deaths                          AS cum_fatalities,
    (cd.total_cases / NULLIF(cd.population,0)) * 100  AS infection_percentage,
    (cd.total_deaths / NULLIF(cd.population,0)) * 100 AS fatality_percentage,
    ts.adj_close                             AS adj_close_price
FROM dbo.covid_deaths AS cd
LEFT JOIN dbo.tsx AS ts
    ON cd.date = ts.date
WHERE cd.location = 'Canada'
  AND cd.date BETWEEN '2020-04-16' AND '2020-07-02'
ORDER BY cd.date ASC;

-- 14) Canada > Infection & Death Rate vs TSX during “MCO 2.0” 
-- Start = 2021-02-12 (+30 days), End = 2021-06-02 (+60 days)
SELECT 
    cd.date                                  AS record_date,
    cd.location                              AS region,
    cd.new_cases                             AS daily_infections,
    cd.total_cases                           AS cum_infections,
    cd.new_deaths                            AS daily_fatalities,
    cd.total_deaths                          AS cum_fatalities,
    (cd.total_cases / NULLIF(cd.population,0)) * 100  AS infection_percentage,
    (cd.total_deaths / NULLIF(cd.population,0)) * 100 AS fatality_percentage,
    ts.adj_close                             AS adj_close_price
FROM dbo.covid_deaths AS cd
LEFT JOIN dbo.tsx AS ts
    ON cd.date = ts.date
WHERE cd.location = 'Canada'
  AND cd.date BETWEEN '2021-02-12' AND '2021-06-02'
ORDER BY cd.date ASC;

-- 15) Canada > Infection & Death Rate vs TSX during “MCO 3.0”  Start = 2021-06-06 (+30 days), End = 2021-07-30 (+60 days)
SELECT 
    cd.date                                  AS record_date,
    cd.location                              AS region,
    cd.new_cases                             AS daily_infections,
    cd.total_cases                           AS cum_infections,
    cd.new_deaths                            AS daily_fatalities,
    cd.total_deaths                          AS cum_fatalities,
    (cd.total_cases / NULLIF(cd.population,0)) * 100  AS infection_percentage,
    (cd.total_deaths / NULLIF(cd.population,0)) * 100 AS fatality_percentage,
    ts.adj_close                             AS adj_close_price
FROM dbo.covid_deaths AS cd
LEFT JOIN dbo.tsx AS ts
    ON cd.date = ts.date
WHERE cd.location = 'Canada'
  AND cd.date BETWEEN '2021-06-06' AND '2021-07-30'
ORDER BY cd.date ASC;

-- 16) Canada > Infection & Death Rate vs TSX in descending date order
SELECT 
    cd.date                                  AS record_date,
    cd.location                              AS region,
    cd.new_cases                             AS daily_infections,
    cd.total_cases                           AS cum_infections,
    cd.new_deaths                            AS daily_fatalities,
    cd.total_deaths                          AS cum_fatalities,
    (cd.total_cases / NULLIF(cd.population,0)) * 100  AS infection_percentage,
    (cd.total_deaths / NULLIF(cd.population,0)) * 100 AS fatality_percentage,
    ts.adj_close                             AS adj_close_price
FROM dbo.covid_deaths AS cd
LEFT JOIN dbo.tsx AS ts
    ON cd.date = ts.date
WHERE cd.location = 'Canada'
ORDER BY cd.date DESC;

-- 17) Canada > Vaccination Rate by Date
SELECT 
    cv.date                      AS record_date,
    cv.location                  AS region,
    cv.new_vaccinations          AS daily_vaccinations,
    cv.total_vaccinations        AS total_doses,
    (cv.total_vaccinations / NULLIF(cd.population,0)) * 100 AS vaccination_rate,
    ts.adj_close                 AS adj_close_price
FROM dbo.covid_vaccs AS cv
LEFT JOIN dbo.covid_deaths AS cd
    ON cv.location = cd.location
    AND cv.date = cd.date
LEFT JOIN dbo.tsx AS ts
    ON cv.date = ts.date
WHERE cv.location = 'Canada'
  AND (cv.total_vaccinations / NULLIF(cd.population,0)) * 100 > 1
ORDER BY cv.date DESC;

-----------------------------
-- AGGREGATE VIEWS 
-----------------------------

CREATE VIEW covid_cases_deaths_view AS
SELECT 
    cd.continent      AS area,
    cd.location       AS region,
    cd.population     AS pop_count,
    MAX(cd.total_cases)  AS cum_infections,
    MAX(cd.total_deaths) AS cum_fatalities,
    (MAX(cd.total_cases)/NULLIF(cd.population,0)) * 100 AS infection_percentage,
    (MAX(cd.total_deaths)/NULLIF(cd.population,0)) * 100 AS fatality_percentage,
    (MAX(cd.total_cases)/1000000) * 100               AS infection_rate_million,
    (MAX(cd.total_deaths)/1000000) * 100              AS fatality_rate_million
FROM dbo.covid_deaths AS cd
WHERE cd.continent IS NOT NULL
GROUP BY cd.continent, cd.location, cd.population;

CREATE VIEW covid_vaccinations_view AS
SELECT 
    cv.continent              AS area,
    cv.location               AS region,
    cv.population             AS pop_count,
    MAX(cv.total_vaccinations) AS total_doses,
    (MAX(cv.total_vaccinations)/NULLIF(cv.population,0)) * 100 AS people_vaccinated
FROM dbo.covid_vaccs AS cv
WHERE cv.continent IS NOT NULL
GROUP BY cv.continent, cv.location, cv.population;

----------------
-- Final Check --
----------------

SELECT *
FROM dbo.covid_vaccs;   -- For Canada checks
