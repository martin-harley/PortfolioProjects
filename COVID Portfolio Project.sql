Select *
From PortfolioProject..CovidDeaths
Where continent is not null
order by 3,4


--Select *
--From PortfolioProject..CovidVaccinations
--order by 3,4


 -- Select Data that we are going to be using


 Select Location, date, total_cases, new_cases, total_deaths, population
From PortfolioProject..CovidDeaths
order by 1,2


-- Looking at Total Cases vs Total Deaths
-- Shows likelihood of dying if you contract Covid in your country

 Select Location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 as Death_Percentage
From PortfolioProject..CovidDeaths
Where location like '%states%'
AND continent is not null
order by 1,2


-- Looking at the Total Cases vs Population
-- Shows what percentage of the population has Covid

 Select Location, date, population, total_cases, (total_cases/population)*100 as Percent_Population_Infected
From PortfolioProject..CovidDeaths
--Where location like '%states%'
Where continent is not null
order by 1,2

-- Looking at Countries with Highest Infection rate compared to Population

Select Location, population, MAX(total_cases) as Highest_Infection_Count, MAX((total_cases/population))*100 as Percent_Population_Infected
From PortfolioProject..CovidDeaths
--Where location like '%states%'
Where continent is not null
Group by Location, population
Order by Percent_Population_Infected desc


-- Showing Countries with the Highest Death Count per Population

Select Location, MAX(cast(Total_deaths as int)) as Total_Death_Count
From PortfolioProject..CovidDeaths
--Where location like '%states%'
Where continent is not null
Group by Location
Order by Total_Death_Count desc


-- LET'S BREAK THINGS DOWN BY CONTINENT

-- Showing continents with the highest ddeath count per population

Select continent, MAX(cast(Total_deaths as int)) as Total_Death_Count
From PortfolioProject..CovidDeaths
Where continent is not null
Group by continent
Order by Total_Death_Count desc


-- GLOBAL NUMBERS

Select SUM(new_cases) as Total_Cases, SUM(cast(new_deaths as int)) as Total_Deaths
, ROUND(SUM(cast(new_deaths as int))/SUM(new_cases)*100,2) as Death_Percentage
From PortfolioProject..CovidDeaths
Where continent is not null
--group by date
order by 1,2


-- Looking at Total Population vs Vaccinations

SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(int,vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.location, 
	dea.date) as Rolling_People_Vaccinated
FROM PortfolioProject..CovidDeaths dea
JOIN PortfolioProject..CovidVaccinations vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent is not null
ORDER BY 2,3


-- USE CTE
WITH PopvsVac (Continent, Location, Date, Population, New_Vaccinations, Rolling_People_Vaccinated)
as 
(
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(int,vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.location, 
	dea.date) as Rolling_People_Vaccinated
FROM PortfolioProject..CovidDeaths dea
JOIN PortfolioProject..CovidVaccinations vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent is not null
--ORDER BY 2,3
)
SELECT *, ROUND((Rolling_People_Vaccinated/Population)*100,2)
FROM PopvsVac




-- TEMP TABLE

DROP Table if exists #Percent_Population_Vaccinated
Create Table #Percent_Population_Vaccinated
(
Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
Population numeric,
New_Vaccinations numeric,
Rolling_People_Vaccinated numeric
)

Insert into #Percent_Population_Vaccinated
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(int,vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.location, 
	dea.date) as Rolling_People_Vaccinated
FROM PortfolioProject..CovidDeaths dea
JOIN PortfolioProject..CovidVaccinations vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent is not null
--ORDER BY 2,3

SELECT *, ROUND((Rolling_People_Vaccinated/Population)*100,2)
FROM #Percent_Population_Vaccinated

-- Creating View to store data for later visualizations

Create View Percent_Population_Vaccinated as 
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(int,vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.location, 
	dea.date) as Rolling_People_Vaccinated
FROM PortfolioProject..CovidDeaths dea
JOIN PortfolioProject..CovidVaccinations vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent is not null
--ORDER BY 2,3


SELECT *
FROM Percent_Population_Vaccinated