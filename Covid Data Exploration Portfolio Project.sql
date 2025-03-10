/*
Covid 19 Data Exploration Project

Skills used: Joins, CTEs, Temp Tables, Window Functions, Aggregate Functions, Creating Views, Converting Data Types, Filtering Data, Data Cleaning

*/


SELECT *
FROM [Portfolio Project]..CovidDeaths
ORDER BY 3,4

UPDATE [Portfolio Project]..CovidDeaths
SET Continent = NULL
WHERE Continent = '';


--Select Data that we are going to be using

SELECT Location, date, total_cases, new_cases, total_deaths, population
FROM [Portfolio Project]..CovidDeaths
ORDER BY 1,2;

--Standardizing data types for accuracy

ALTER TABLE [Portfolio Project]..CovidDeaths
ALTER COLUMN total_deaths FLOAT;

ALTER TABLE [Portfolio Project]..CovidDeaths
ALTER COLUMN total_cases FLOAT;

ALTER TABLE [Portfolio Project]..CovidDeaths
ALTER COLUMN Population FLOAT;

ALTER TABLE [Portfolio Project]..CovidDeaths
ALTER COLUMN date DATE;

ALTER TABLE [Portfolio Project]..CovidDeaths
ALTER COLUMN location NVARCHAR(255);


--Total Cases vs Total Deaths
--Shows likelihood of dying if you contract covid in your country

SELECT Location, date, total_cases, total_deaths, (total_deaths/NULLIF(total_cases, 0)) * 100 AS DeathPercentage
FROM [Portfolio Project]..CovidDeaths
WHERE Location LIKE '%states%'
ORDER BY 1,2

--Total Cases vs Population
--Shows what percentage of population is infected with Covid

SELECT Location, date, total_cases, Population, (total_cases/population)*100 as PercentPopulationInfected
FROM [Portfolio Project]..CovidDeaths
WHERE Location LIKE '%states%'
ORDER BY 1,2;


--Countries with the Highest Infection Rate compaerd to Population

SELECT Location, Population, MAX(total_cases) AS HighestInfectionCount, MAX((total_cases/NULLIF(Population, 0)))*100 as PercentPopulationInfected
FROM [Portfolio Project]..CovidDeaths
GROUP BY Location, Population
ORDER BY PercentPopulationInfected desc


--Countries with the Highest Death Count per Population

SELECT Location, MAX(total_deaths) AS TotalDeathCount
FROM [Portfolio Project]..CovidDeaths
WHERE continent IS NOT NULL
GROUP BY Location
ORDER BY TotalDeathCount desc


--BERAK DOWN BY CONTINENT

--Showing the continents with the highest death counts

SELECT continent, MAX(total_deaths) AS TotalDeathCount
FROM [Portfolio Project]..CovidDeaths
WHERE continent IS NOT NULL 
GROUP BY continent
ORDER BY TotalDeathCount desc



--GLOBAL NUMBERS

SELECT date, SUM(cast(new_cases as int)) as total_cases, SUM(cast(new_deaths as int)) as total_deaths, SUM(cast(new_deaths as int))/NULLIF(SUM(CAST(new_cases AS INT)), 0) AS DeathPercentage
FROM [Portfolio Project]..CovidDeaths
--WHERE Location LIKE '%states%'
WHERE continent is not null
GROUP BY date
ORDER BY 1,2


--Looking at Total Population vs Vaccinations
-- Shows Percentage of Population that has recieved at least one Covid Vaccine

SELECT 
    dea.continent, dea.location, dea.date, dea.population, CAST(vac.new_vaccinations AS INT) AS new_vaccinations, 
	SUM(CAST(vac.new_vaccinations AS INT)) OVER (
        PARTITION BY dea.location 
        ORDER BY dea.location, dea.date
    ) AS RollingVaccinations
FROM [Portfolio Project]..CovidDeaths dea
JOIN [Portfolio Project]..CovidVaccines vac
    ON dea.location = vac.location
    AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
ORDER BY 2,3


-- Using CTE to perform Calculation on Partition By in previous query

With PopvsVac (Continent, Location, Date, Population, new_vaccinations, RollingVaccinations)
as
(
SELECT 
    dea.continent, dea.location, dea.date, dea.population, CAST(vac.new_vaccinations AS INT) AS new_vaccinations, 
	SUM(CAST(vac.new_vaccinations AS INT)) OVER (
        PARTITION BY dea.location 
        ORDER BY dea.location, dea.date
    ) AS RollingVaccinations
FROM [Portfolio Project]..CovidDeaths dea
JOIN [Portfolio Project]..CovidVaccines vac
    ON dea.location = vac.location
    AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
)

SELECT *, (RollingVaccinations/Nullif(Population, 0))*100
FROM PopvsVac


-- Using Temp Table to perform Calculation on Partition By in previous query


DROP TABLE if exists #PercentPopulationVaccinated
CREATE TABLE #PercentPopulationVaccinated
(
Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
Population numeric, 
New_Vaccinations numeric, 
RollingVaccinations numeric
)



Insert Into #PercentPopulationVaccinated
SELECT 
    dea.continent, dea.location, dea.date, dea.population, CAST(vac.new_vaccinations AS INT) AS new_vaccinations, 
	SUM(CAST(vac.new_vaccinations AS INT)) OVER (
        PARTITION BY dea.location 
        ORDER BY dea.location, dea.date
    ) AS RollingVaccinations
FROM [Portfolio Project]..CovidDeaths dea
JOIN [Portfolio Project]..CovidVaccines vac
    ON dea.location = vac.location
    AND dea.date = vac.date



SELECT *, (RollingVaccinations/Nullif(Population, 0))*100
FROM #PercentPopulationVaccinated
ORDER BY 2,3



--Creating View to store for later visualizations


CREATE VIEW PercentPopulationVaccinated AS
SELECT 
    dea.continent, dea.location, dea.date, dea.population, CAST(vac.new_vaccinations AS INT) AS new_vaccinations, 
	SUM(CAST(vac.new_vaccinations AS INT)) OVER (
        PARTITION BY dea.location 
        ORDER BY dea.location, dea.date
    ) AS RollingVaccinations
FROM [Portfolio Project]..CovidDeaths dea
JOIN [Portfolio Project]..CovidVaccines vac
    ON dea.location = vac.location
    AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
--ORDER BY 2,3


