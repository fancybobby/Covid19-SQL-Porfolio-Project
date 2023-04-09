/*
Covid 19 Data Exploration 

Skills used: Joins, CTE's, Temp Tables, Windows Functions, Aggregate Functions, Creating Views, Converting Data Types
*/

SELECT*
FROM COVID_DEATHS
Where continent is not null
ORDER BY 3,4 

SELECT*
FROM COVID_VACCINATIONS
ORDER BY 3,4

SELECT location, date, total_cases, new_cases, total_deaths, population
FROM COVID_DEATHS
ORDER BY 1,2

--What are the Total Cases vs Total Deaths
-- The Death_percentage shows the likelihood of dying if you contract covid in UK
SELECT location, date, total_cases, total_deaths, cast(total_deaths as bigint) /NULLIF (cast( total_cases as float),0)*100 AS Death_Percentage
FROM COVID_DEATHS
WHERE location like '%kingdom%'
and continent is not null
ORDER BY 1,2, Death_Percentage

-- What are the total cases vs Population
-- Shows the percentage of population that got covid

Select Location, date, Population, total_cases,  cast(total_cases as bigint) /NULLIF (cast(population as float),0)*100 as Population_Infected_Percentage
From COVID_DEATHS
Where location like '%kingdom%'
order by 1,2

-- Countries with highest rates of infection compared to population

Select Location, population, MAX(total_cases) as Highest_Countof_Infection,  Max(cast(total_cases as bigint) /NULLIF (cast(population as float),0))*100 as
   Percentageof_Population_Infected
From COVID_DEATHS
--Where location like '%kingdom%'
Group by Location, Population
order by Percentageof_Population_Infected desc

-- Countries with highest death count per population

Select Location, population, MAX(cast(total_deaths as bigint)) as Total_Death_Count  
from COVID_DEATHS
--Where location like '%kingdom%'
where continent is not null and location not like '%ncome%'
Group by Location, Population
order by Total_Death_Count desc


-- BREAKDOWN BY CONTINENT
--Showing death count in all continents per population

Select continent, MAX(cast(total_deaths as int)) as Total_Death_Count  
from COVID_DEATHS
where continent is not null 
Group by continent
order by Total_Death_Count desc



-- GLOBAL NUMBERS: Showing the Total Cases, Total Deaths and the Death Percentage group by Date:

select date, SUM(CAST (new_cases AS float)) as total_cases, SUM (cast (new_deaths as float)) as total_deaths, SUM(
    cast(new_deaths as float))/NULLIF (SUM (cast(new_cases AS float)),0)*100 as Death_Percentage
From COVID_DEATHS
where continent is not null
Group by date
order by 1,2

--Total deaths globally = 0.89%

select SUM(CAST (new_cases AS float)) as total_cases, SUM (cast (new_deaths as float)) as total_deaths, SUM(
    cast(new_deaths as float))/NULLIF (SUM (cast(new_cases AS float)),0)*100 as Death_Percentage
From COVID_DEATHS
where continent is not null
order by 1,2

--Total Vaccination vs Population
-- Showing Percentage of Population that has recieved at least one Covid Vaccine (Joined deaths and vaccination tables)

Select deaths.continent, deaths.location, deaths.date, deaths.population, vacc.new_vaccinations
  , SUM(CONVERT(bigint,vacc.new_vaccinations))
OVER (Partition by deaths.Location Order by deaths.location, deaths.Date) as Rolling_People_Vaccinated --(Rolling_People_Vaccinated/population)*100
From COVID_DEATHS deaths
Join COVID_VACCINATIONS vacc
	On deaths.location = vacc.location
	and deaths.date = vacc.date
where deaths.continent is not null 
order by 2,3

-- -- To perform Calculation on Partition By in previous query i used  CTE 

With PopvsVac (Continent, Location, Date, Population, New_Vaccinations, RollingPeopleVaccinated)
as
( Select deaths.continent, deaths.location, deaths.date, deaths.population, vacc.new_vaccinations
  , SUM(CONVERT(bigint,vacc.new_vaccinations))
OVER (Partition by deaths.Location Order by deaths.location, deaths.Date) as Rolling_People_Vaccinated --(Rolling_People_Vaccinated/population)*100
From COVID_DEATHS deaths
Join COVID_VACCINATIONS vacc
	On deaths.location = vacc.location
	and deaths.date = vacc.date
where deaths.continent is not null 
--order by 2,3
)
Select *,(RollingPeopleVaccinated/Population)*100
From PopvsVac


-- CREATING TEMP TABLES to perform Calculation on Partition By in previous query

DROP Table if exists #PercentPopulationVaccinated
Create Table #PercentPopulationVaccinated
(
Continent nvarchar(255),
Location nvarchar(255),
Date nvarchar(255),
Population float,
New_vaccinations float,
RollingPeopleVaccinated float
)
Insert into #PercentPopulationVaccinated
Select deaths.continent, deaths.location, deaths.date, deaths.population, vacc.new_vaccinations
, SUM(CONVERT(bigint,vacc.new_vaccinations)) OVER (Partition by deaths.Location Order by deaths.location, deaths.Date) as RollingPeopleVaccinated
--, (RollingPeopleVaccinated/population)*100
From COVID_DEATHS deaths
Join COVID_VACCINATIONS vacc
	On deaths.location = vacc.location
	and deaths.date = vacc.date
--where dea.continent is not null 
--order by 2,3
Select *, (RollingPeopleVaccinated/Population)*100
From #PercentPopulationVaccinated


-- Creating View to store data for later visualizations
Create View PercentPopulationVaccinated as
Select deaths.continent, deaths.location, deaths.date, deaths.population, vacc.new_vaccinations
, SUM(CONVERT(bigint,vacc.new_vaccinations)) OVER (Partition by deaths.Location Order by deaths.location, deaths.Date) as RollingPeopleVaccinated
--, (RollingPeopleVaccinated/population)*100
From COVID_DEATHS deaths
Join COVID_VACCINATIONS vacc
	On deaths.location = vacc.location
	and deaths.date = vacc.date
where deaths.continent is not null 


select*
from PercentPopulationVaccinated


