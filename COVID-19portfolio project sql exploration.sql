
/*
Covid 19 Data Exploration 

Skills used: Joins, CTE's, Temp Tables, Windows Functions, Aggregate Functions, Creating Views, Converting Data Types, Case when function.

*/




--1.
	--Total cases VS total death.
	--Shows likeihood of dying in Malaysia.

SELECT location,
		date,
		population,
		total_cases,
		total_deaths,
		cast(round((total_deaths / total_cases) * 100,2)as varchar ) + '%'  as death_percentage
FROM portofolio_project..CovidDeaths$
WHERE LOCATION LIKE  'Malaysi_'
ORDER BY 1,2;





--2.
	--Shows the top three Ranked locations by total deaths within each continent.
	--Exclude any records where the continent is not specified.Because within continent there has some non-values,Which are world and Europe.

WITH ranked_totalDeaths_by_continent AS (
    SELECT 
        continent,
        location,
        MAX(CAST(total_deaths AS INT)) AS max_total_deaths, -- Cast to INT
        DENSE_RANK() OVER (PARTITION BY continent ORDER BY MAX(CAST(total_deaths AS INT)) DESC) AS death_rank
    FROM 
        portofolio_project..CovidDeaths$
    WHERE 
        total_deaths IS NOT NULL
        AND continent IS NOT NULL
    GROUP BY 
        continent, location
)

SELECT 
    continent,
    location,
    max_total_deaths AS total_deaths,
    death_rank
FROM 
    ranked_totalDeaths_by_continent
WHERE 
    death_rank < 4
ORDER BY 
    continent, death_rank;




--3.
--Identifying the most affected countries (by infection rate) within each continent.

--Comparing infection rates across different regions.


WITH infection_rate AS (
    SELECT
        continent,
        location,
        MAX(total_cases) AS infected_people,
        population,
        (MAX(total_cases) / population) * 100 AS infection_rate
    FROM 
        portofolio_project..CovidDeaths$
    WHERE 
        total_cases IS NOT NULL AND population IS NOT NULL
    GROUP BY 
        continent, location, population
),
ranked_infectionRate AS (
    SELECT
        continent,
        location,
        infected_people,
        population,
        infection_rate,
        DENSE_RANK() OVER (PARTITION BY continent ORDER BY infection_rate DESC) AS rank
    FROM 
        infection_rate
	WHERE continent is not null
)
SELECT 
    continent,
    location,
    infected_people,
    population,
    CAST(infection_rate AS VARCHAR) + '%' AS infection_rate, -- Format as percentage
    rank
FROM 
    ranked_infectionRate
WHERE 
    rank < 4
ORDER BY 
    continent, rank;



--4.
-- Categorize countries based on their COVID-19 vaccination rates relative to their population. 

WITH MaxVaccinations_population AS (
    SELECT
        d.location,
        d.population,
        MAX(v.total_vaccinations) AS max_total_vaccinations
    FROM
        portofolio_project..CovidDeaths$ d
    JOIN
        portofolio_project..CovidVaccinations$ v
    ON
        d.location = v.location AND d.date = v.date
    WHERE
        v.total_vaccinations IS NOT NULL
        AND d.population IS NOT NULL
    GROUP BY
        d.location,
        d.population
)
SELECT
    location,
    population,
    max_total_vaccinations,
    CASE
        WHEN max_total_vaccinations IS NULL OR population IS NULL THEN 'Unknown'  -- errors handleing for those records contains NULL.
        WHEN max_total_vaccinations < (population * 0.25) THEN 'Low'
        WHEN max_total_vaccinations >= (population * 0.25) AND max_total_vaccinations < (population * 0.50) THEN 'Medium'
        WHEN max_total_vaccinations >= (population * 0.50) THEN 'High'
    END AS vaccination_category
FROM
    MaxVaccinations_population
ORDER BY
    location;


--5.
-- Total Population vs Vaccinations
-- Shows the amount of people who has been done the vaccinations over the time and shows the percentage of vaccinated people with the time been.

WITH PopvsVac AS (
    SELECT
        dea.continent,
        dea.location,
        dea.date,
        dea.population,
        vac.new_vaccinations,
        SUM(CAST(ISNULL(vac.new_vaccinations, 0) AS BIGINT)) OVER (PARTITION BY dea.location ORDER BY dea.date) AS RollingPeopleVaccinated
    FROM
        portofolio_project..CovidDeaths$ dea
    JOIN
        portofolio_project..CovidVaccinations$ vac
    ON
        dea.location = vac.location
        AND dea.date = vac.date
    WHERE
        dea.continent IS NOT NULL
        AND dea.population > 0 -- Filter out rows where population is 0 or NULL
)
SELECT
    continent,
    location,
    date,
    population,
    new_vaccinations,
    RollingPeopleVaccinated,
    CONVERT(VARCHAR, (RollingPeopleVaccinated * 100.0 / population)) + '%' AS RollingPeopleVaccinated_rate
FROM
    PopvsVac
ORDER BY
    location, date;



--6.
-- Using Temp Table to perform Calculation on Partition By in previous query

DROP TABLE IF EXISTS #PercentPopulationVaccinated;

CREATE TABLE #PercentPopulationVaccinated
(
    Continent nvarchar(255),
    Location nvarchar(255),
    Date datetime,
    Population numeric,
    New_vaccinations numeric,
    RollingPeopleVaccinated numeric
);

INSERT INTO #PercentPopulationVaccinated
  SELECT
        dea.continent,
        dea.location,
        dea.date,
        dea.population,
        vac.new_vaccinations,
        SUM(CAST(ISNULL(vac.new_vaccinations, 0) AS BIGINT)) OVER (PARTITION BY dea.location ORDER BY dea.date) AS RollingPeopleVaccinated
    FROM
        portofolio_project..CovidDeaths$ dea
    JOIN
        portofolio_project..CovidVaccinations$ vac
    ON
        dea.location = vac.location
        AND dea.date = vac.date
    WHERE
        dea.continent IS NOT NULL
        AND dea.population > 0 -- Filter out rows where population is 0 or NULL

SELECT
    Continent,
    Location,
    Date,
    Population,
    New_vaccinations,
    RollingPeopleVaccinated,
	CONVERT(VARCHAR, (RollingPeopleVaccinated * 100.0 / population)) + '%' AS RollingPeopleVaccinated_rate	
FROM
    #PercentPopulationVaccinated
ORDER BY
    Location, Date;


--7.
-- Creating View to store data for later visualizations

Create View PercentPopulationVaccinated as
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(int,vac.new_vaccinations)) OVER (Partition by dea.Location Order by dea.location, dea.Date) as RollingPeopleVaccinated
--, (RollingPeopleVaccinated/population)*100
From portofolio_project..CovidDeaths$ dea
Join portofolio_project..CovidVaccinations$ vac
	on dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null 

select * from [dbo].[PercentPopulationVaccinated];



