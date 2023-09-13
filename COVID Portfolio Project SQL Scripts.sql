/* 
Covid 19 Data Exploration

Data from 1/1/2020-8-7-23
Data Source https://ourworldindata.org/covid-deaths

Skills used: Joins, CTE's, Temp Tables, Windows Functions, Aggregate Functions, Creating Views, Converting Data Types

*/

Select *
From PortfolioProject..Covid_Deaths
Where continent is not null
Order by 3,4

--Select the Data that we are going to be using 

Select location, date, total_cases, new_cases, total_deaths, population
From PortfolioProject..Covid_Deaths
Where continent is not null
Order by 1,2


-- Total Cases vs Total Deaths
-- Shows Likelihood Of Dying If you Contract Covid In Your Country

Select location, date, total_cases, (CONVERT(float, total_deaths) / NULLIF(CONVERT(float, total_cases), 0))*100 as DeathPercentage
From PortfolioProject..Covid_Deaths
Where location like '%states%' and continent is not null
Order by 1,2

-- Total Cases Vs Population
-- Shows what percentage of population infected with Covid

Select location, date, population, total_cases,  (total_cases/population)*100 as PercentOfPopulationInfected
From PortfolioProject..Covid_Deaths
Where continent is not null
--Where location like '%states%'
Order by 1,2

--Countries with Highest Infection Rate Relative to Population 

Select location, population, MAX(cast(total_cases as int)) as HighestInfectionCount,  MAX((cast(total_cases as int)/population))*100 as PercentOfPopulationInfected
From PortfolioProject..Covid_Deaths
Where continent is not null
--Where location like '%states%'
Group by location, population
Order by PercentOfPopulationInfected desc

--Countries with Highest Death Count per Population

Select location, MAX(cast(total_deaths as int)) as TotalDeathCount
From PortfolioProject..Covid_Deaths
Where continent is not null
--Where location like '%states%'
Group by location
Order by TotalDeathCount desc

-- BREAKING THINGS DOWN BY CONTINENT

-- Showing contintents with the highest death count per population

Select location, MAX(cast(total_deaths as int)) as TotalDeathCount
From PortfolioProject..Covid_Deaths
Where continent is null AND location not like '%income%'
--Where location like '%states%'
Group by location
Order by TotalDeathCount desc

-- Breaking down by income level

Select location, MAX(cast(total_deaths as int)) as TotalDeathCount
From PortfolioProject..Covid_Deaths
Where continent is null AND location like '%income%'
--Where location like '%states%'
Group by location
Order by TotalDeathCount desc

-- GLOBAL NUMBERS

Select SUM(new_cases) as total_cases, SUM(cast(new_deaths as int)) as total_deaths, SUM(cast(new_deaths as int))/SUM(New_Cases)*100 as DeathPercentage
From PortfolioProject..Covid_Deaths
--Where location like '%states%'
where continent is not null 
--Group By date
order by 1,2

-- Joining Vax & Death tables together and looking at Total Population Vs. Vaccination
-- Shows Percentage of Population that has recieved at least one Covid Vaccine

Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, SUM(CONVERT(bigint,vac.new_vaccinations)) OVER (Partition by dea.location Order by dea.location, dea.date) as RollingPeopleVaccinated
FROM PortfolioProject..Covid_Deaths dea -- dea is an abreviation 
Join PortfolioProject..Covid_Vaccinations vac -- vac is an abreviaton 
	On dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null 
Order by 1,2,3

-- Using CTE to preform Calculation on Partion By in previous query

With PopvsVac (Continent, Location, Date, Population, New_Vaccinations, RollingPeopleVaccinated) 
as
(
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, SUM(CONVERT(bigint,vac.new_vaccinations)) OVER (Partition by dea.location Order by dea.location, dea.date) as RollingPeopleVaccinated
FROM PortfolioProject..Covid_Deaths dea 
Join PortfolioProject..Covid_Vaccinations vac  
	On dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null 
--Order by 1,2,3
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
, SUM(cast(vac.new_vaccinations as bigint)) OVER (Partition by dea.Location Order by dea.location, dea.Date) as RollingPeopleVaccinated
--, (RollingPeopleVaccinated/population)*100
From PortfolioProject..Covid_Deaths dea
Join PortfolioProject..Covid_Vaccinations vac
	On dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null 
--order by 2,3

Select *, (RollingPeopleVaccinated/Population)*100
From #PercentPopulationVaccinated


-- Creating View to store data for later visualizations

USE PortfolioProject
GO
Create View PercentPopulationVaccinated as Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
SUM(cast(vac.new_vaccinations as bigint)) OVER (Partition by dea.Location Order by dea.location, dea.Date) as RollingPeopleVaccinated
--, (RollingPeopleVaccinated/population)*100
From PortfolioProject..Covid_Deaths dea
Join PortfolioProject..Covid_Vaccinations vac
	On dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null 
--order by 2,3

Select * 
From PercentPopulationVaccinated

-- Total Vax by Country
Select location, MAX(RollingPeopleVaccinated) as TotalVaccinated
From PercentPopulationVaccinated
group by location