# SQL-Data-Exploration-
This Project focuses on analysing Covid - 19 deaths and vaccinations relations and other relevant metrics using Microsoft SQL Server

/*
Covid 19 Data Exploration 
Skills used: Joins, CTE's, Temp Tables, Windows Functions, Aggregate Functions, Creating Views, Converting Data Types
*/

-- Select Data that we are going to be starting with
SELECT *
FROM PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL 
ORDER BY 3, 4;

-- Total Cases vs Total Deaths
-- Shows the likelihood of dying if you contract COVID in your country
SELECT
    Location,
    date,
    total_cases,
    total_deaths,
    (total_deaths / total_cases) * 100 AS DeathPercentage
FROM PortfolioProject..CovidDeaths
WHERE location LIKE '%states%'
    AND continent IS NOT NULL 
ORDER BY 1, 2;

-- Total Cases vs Population
-- Shows what percentage of the population is infected with Covid
SELECT
    Location,
    date,
    Population,
    total_cases,
    (total_cases / population) * 100 AS PercentPopulationInfected
FROM PortfolioProject..CovidDeaths
--WHERE location LIKE '%states%'
ORDER BY 1, 2;

-- Countries with the Highest Infection Rate compared to Population
SELECT
    Location,
    Population,
    MAX(total_cases) AS HighestInfectionCount,
    MAX((total_cases / population)) * 100 AS PercentPopulationInfected
FROM PortfolioProject..CovidDeaths
--WHERE location LIKE '%states%'
GROUP BY Location, Population
ORDER BY PercentPopulationInfected DESC;

-- Countries with the Highest Death Count per Population
SELECT
    Location,
    MAX(CAST(Total_deaths AS INT)) AS TotalDeathCount
FROM PortfolioProject..CovidDeaths
--WHERE location LIKE '%states%'
WHERE continent IS NOT NULL 
GROUP BY Location
ORDER BY TotalDeathCount DESC;

-- BREAKING THINGS DOWN BY CONTINENT
-- Showing continents with the highest death count per population
SELECT
    continent,
    MAX(CAST(Total_deaths AS INT)) AS TotalDeathCount
FROM PortfolioProject..CovidDeaths
--WHERE location LIKE '%states%'
WHERE continent IS NOT NULL 
GROUP BY continent
ORDER BY TotalDeathCount DESC;

-- GLOBAL NUMBERS
SELECT
    SUM(new_cases) AS total_cases,
    SUM(CAST(new_deaths AS INT)) AS total_deaths,
    SUM(CAST(new_deaths AS INT)) / SUM(New_Cases) * 100 AS DeathPercentage
FROM PortfolioProject..CovidDeaths
--WHERE location LIKE '%states%'
WHERE continent IS NOT NULL 
--Group By date
ORDER BY 1, 2;

-- Total Population vs Vaccinations
-- Shows the Percentage of the Population that has received at least one Covid Vaccine
SELECT
    dea.continent,
    dea.location,
    dea.date,
    dea.population,
    vac.new_vaccinations,
    SUM(CONVERT(INT, vac.new_vaccinations)) OVER (PARTITION BY dea.Location ORDER BY dea.location, dea.Date) AS RollingPeopleVaccinated
FROM PortfolioProject..CovidDeaths dea
JOIN PortfolioProject..CovidVaccinations vac
    ON dea.location = vac.location
    AND dea.date = vac.date
WHERE dea.continent IS NOT NULL 
ORDER BY 2, 3;

-- Using CTE to perform Calculation on Partition By in the previous query
WITH PopvsVac (Continent, Location, Date, Population, New_Vaccinations, RollingPeopleVaccinated)
AS
(
    SELECT
        dea.continent,
        dea.location,
        dea.date,
        dea.population,
        vac.new_vaccinations,
        SUM(CONVERT(INT, vac.new_vaccinations)) OVER (PARTITION BY dea.Location ORDER BY dea.location, dea.Date) AS RollingPeopleVaccinated
    FROM PortfolioProject..CovidDeaths dea
    JOIN PortfolioProject..CovidVaccinations vac
        ON dea.location = vac.location
        AND dea.date = vac.date
    WHERE dea.continent IS NOT NULL 
    --order by 2,3
)
SELECT
    *,
    (RollingPeopleVaccinated / Population) * 100
FROM PopvsVac;

-- Using Temp Table to perform Calculation on Partition By in the previous query
IF OBJECT_ID('tempdb..#PercentPopulationVaccinated') IS NOT NULL
    DROP TABLE #PercentPopulationVaccinated;

CREATE TABLE #PercentPopulationVaccinated
(
    Continent NVARCHAR(255),
    Location NVARCHAR(255),
    Date DATETIME,
    Population NUMERIC,
    New_vaccinations NUMERIC,
    RollingPeopleVaccinated NUMERIC
);

INSERT INTO #PercentPopulationVaccinated
SELECT
    dea.continent,
    dea.location,
    dea.date,
    dea.population,
    vac.new_vaccinations,
    SUM(CONVERT(INT, vac.new_vaccinations)) OVER (PARTITION BY dea.Location ORDER BY dea.location, dea.Date) AS RollingPeopleVaccinated
FROM PortfolioProject..CovidDeaths dea
JOIN PortfolioProject..CovidVaccinations vac
    ON dea.location = vac.location
    AND dea.date = vac.date;
--where dea.continent is not null 
--order by 2,3

SELECT
    *,
    (RollingPeopleVaccinated / Population) * 100
FROM #PercentPopulationVaccinated;

-- Creating View to store data for later visualizations
CREATE VIEW PercentPopulationVaccinated AS
SELECT
    dea.continent,
    dea.location,
    dea.date,
    dea.population,
    vac.new_vaccinations,
    SUM(CONVERT(INT, vac.new_vaccinations)) OVER (PARTITION BY dea.Location ORDER BY dea.location, dea.Date) AS RollingPeopleVaccinated
FROM PortfolioProject..CovidDeaths dea
JOIN PortfolioProject..CovidVaccinations vac
    ON dea.location = vac.location
    AND dea.date = vac.date
WHERE dea.continent IS NOT NULL ;

