/*
Covid 19 Data Exploration 

Skills used: Joins, CTE's, Temp Tables, Windows Functions, Aggregate Functions, Creating Views, Converting Data Types

*/

Select *
From PortfolioProject..CovidDeaths
Where continent is not null 
order by 3,4


-- Select Data that we are going to be starting with

Select Location, date, total_cases, new_cases, total_deaths, population
From PortfolioProject..CovidDeaths
Where continent is not null 
order by 1,2


-- Total Cases vs Total Deaths
-- Shows likelihood of dying if you contract covid in your country

Select Location, date, total_cases,total_deaths, (total_deaths/total_cases)*100 as DeathPercentage
From PortfolioProject..CovidDeaths
Where location like '%states%'
and continent is not null 
order by 1,2


-- Total Cases vs Population
-- Shows what percentage of population infected with Covid

Select Location, date, Population, total_cases,  (total_cases/population)*100 as PercentPopulationInfected
From PortfolioProject..CovidDeaths
Where location like '%states%'
order by 1,2


-- Countries with Highest Infection Rate compared to Population

Select Location, Population, MAX(total_cases) as HighestInfectionCount,  Max((total_cases/population))*100 as PercentPopulationInfected
From PortfolioProject..CovidDeaths
Where location like '%states%'
Group by Location, Population
order by PercentPopulationInfected desc


-- Countries with Highest Death Count per Population

Select Location, MAX(cast(Total_deaths as int)) as TotalDeathCount
From PortfolioProject..CovidDeaths
--Where location like '%states%'
Where continent is not null 
Group by Location
order by TotalDeathCount desc



-- BREAKING THINGS DOWN BY CONTINENT

-- Showing contintents with the highest death count per population

Select continent, MAX(cast(Total_deaths as int)) as TotalDeathCount
From PortfolioProject..CovidDeaths
Where location like '%states%'
Where continent is not null 
Group by continent
order by TotalDeathCount desc



-- GLOBAL NUMBERS

Select SUM(new_cases) as total_cases, SUM(cast(new_deaths as int)) as total_deaths, SUM(cast(new_deaths as int))/SUM(New_Cases)*100 as DeathPercentage
From PortfolioProject..CovidDeaths
Where location like '%states%'
where continent is not null 
Group By date
order by 1,2



Total Population vs Vaccinations
Shows Percentage of Population that has recieved at least one Covid Vaccine

Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(int,vac.new_vaccinations)) OVER (Partition by dea.Location Order by dea.location, dea.Date) as RollingPeopleVaccinated
(RollingPeopleVaccinated/population)*100
From PortfolioProject..CovidDeaths dea
Join PortfolioProject..CovidVaccinations vac
	On dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null 
order by 2,3


Using CTE to perform Calculation on Partition By in previous query

With PopvsVac (Continent, Location, Date, Population, New_Vaccinations, RollingPeopleVaccinated)
as
(
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(int,vac.new_vaccinations)) OVER (Partition by dea.Location Order by dea.location, dea.Date) as RollingPeopleVaccinated
(RollingPeopleVaccinated/population)*100
From PortfolioProject..CovidDeaths dea
Join PortfolioProject..CovidVaccinations vac
	On dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null 
order by 2,3 
)
Select *, (RollingPeopleVaccinated/Population)*100
From PopvsVac



-- Using Temp Table to perform Calculation on Partition By in previous query

DROP Table if exists #PercentPopulationVaccinated
Create Table #PercentPopulationVaccinated
(
Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
Population numeric,
New_vaccinations numeric,
RollingPeopleVaccinated numeric
)

Insert into #PercentPopulationVaccinated
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(int,vac.new_vaccinations)) OVER (Partition by dea.Location Order by dea.location, dea.Date) as RollingPeopleVaccinated
(RollingPeopleVaccinated/population)*100
From PortfolioProject..CovidDeaths dea
Join PortfolioProject..CovidVaccinations vac
	On dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null 
order by 2,3

Select *, (RollingPeopleVaccinated/Population)*100
From #PercentPopulationVaccinated


-- Case Fatality Rate (CFR):


SELECT
    Location,
    Date,
    Total_Cases,
    Total_Deaths,
    (Total_Deaths / Total_Cases) * 100 AS CaseFatalityRate
FROM PortfolioProject..CovidDeaths
WHERE Continent IS NOT NULL
ORDER BY 1, 2;

-- Recovery Rate:


SELECT
    Location,
    Date,
    Total_Cases,
    Total_Deaths,
    (Total_Cases - Total_Deaths) * 100 / Total_Cases AS RecoveryRate
FROM PortfolioProject..CovidDeaths
WHERE Continent IS NOT NULL
ORDER BY 1, 2;

-- Rolling Average for New Cases and Deaths:


SELECT
    Location,
    Date,
    New_Cases,
    AVG(New_Cases) OVER (PARTITION BY Location ORDER BY Date ROWS BETWEEN 7 PRECEDING AND CURRENT ROW) AS RollingAvgNewCases,
    New_Deaths,
    AVG(New_Deaths) OVER (PARTITION BY Location ORDER BY Date ROWS BETWEEN 7 PRECEDING AND CURRENT ROW) AS RollingAvgNewDeaths
FROM PortfolioProject..CovidDeaths
WHERE Continent IS NOT NULL
ORDER BY 1, 2;

-- Vaccination Rate:


SELECT
    Continent,
    Location,
    Date,
    New_Vaccinations,
    (New_Vaccinations / Population) * 100 AS VaccinationRate
FROM PortfolioProject..CovidVaccinations
WHERE Continent IS NOT NULL
ORDER BY 2, 3;

-- Vaccination Coverage:


SELECT
    dea.Continent,
    dea.Location,
    dea.Date,
    dea.Population,
    vac.New_Vaccinations,
    (RollingPeopleVaccinated / Population) * 100 AS PercentPopulationVaccinated
FROM PopvsVac dea
ORDER BY 2, 3;

-- Mortality Rate Over Time:


SELECT
    Location,
    Date,
    Total_Deaths,
    LAG(Total_Deaths) OVER (PARTITION BY Location ORDER BY Date) AS PreviousTotalDeaths,
    (Total_Deaths - LAG(Total_Deaths) OVER (PARTITION BY Location ORDER BY Date)) AS DeathsIncrease
FROM PortfolioProject..CovidDeaths
WHERE Continent IS NOT NULL
ORDER BY 1, 2;

-- Testing Rate:


SELECT
    Location,
    Date,
    Total_Tests,
    (Total_Tests / Population) * 100 AS TestingRate
FROM PortfolioProject..CovidTesting
WHERE Continent IS NOT NULL
ORDER BY 1, 2;

-- Positivity Rate:


SELECT
    Location,
    Date,
    Positive_Tests,
    (Positive_Tests / Total_Tests) * 100 AS PositivityRate
FROM PortfolioProject..CovidTesting
WHERE Continent IS NOT NULL
ORDER BY 1, 2;

-- Vaccination Coverage by Continent:


SELECT
    dea.Continent,
    dea.Location,
    dea.Date,
    dea.Population,
    vac.New_Vaccinations,
    (RollingPeopleVaccinated / Population) * 100 AS PercentPopulationVaccinated
FROM PopvsVac dea
ORDER BY 1, 2, 3;

-- Comparative Analysis - Cases, Deaths, and Vaccinations:


SELECT
    dea.Location,
    dea.Date,
    dea.New_Cases,
    dea.New_Deaths,
    vac.New_Vaccinations
FROM PortfolioProject..CovidDeaths dea
JOIN PortfolioProject..CovidVaccinations vac
ON
    dea.Location = vac.Location
    AND dea.Date = vac.Date

WHERE dea.Continent IS NOT NULL 
ORDER BY 1, 2;












