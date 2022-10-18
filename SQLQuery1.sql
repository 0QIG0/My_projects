/*
Covid 19 Data Exploration 
*/

select *
from PortfolioProject..['covid_deaths$']
order by 3,4;

select location, date, total_cases, new_cases, total_deaths, population
from PortfolioProject..['covid_deaths$']
order by 1,2;

-- Total Cases vs Total Deaths
-- Shows likelihood of dying if you contract covid in Saudi Arabia
select location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 as death_percentage
from PortfolioProject..['covid_deaths$']
where location = 'Saudi Arabia'
order by 1,2;

-- Total Cases vs Population
-- Shows what percentage of population infected with Covid in Saudi arabia

select location, date, population, total_cases, (total_cases/population)*100 as infection_percentage
from PortfolioProject..['covid_deaths$']
where location = 'Saudi Arabia'
order by 1,2;

-- Countries with Highest Infection Rate compared to Population

select location, population, max(total_cases) as highes_tinfection_count, max((total_cases/population))*100 as highest_infection_percentage
from PortfolioProject..['covid_deaths$']
group by population, location
order by highest_infection_percentage desc;

-- Countries with Highest Death Count per Population

select location, max(cast(total_deaths as int)) as total_death_count
from PortfolioProject..['covid_deaths$']
where continent is not null
group by location
order by total_death_count desc;

-- GLOBAL NUMBERS
select date, sum(new_cases) as total_cases, SUM(cast(new_deaths as int)) as total_deaths, SUM(cast(new_deaths as int))/sum(new_cases)*100 as death_percentage
from PortfolioProject..['covid_deaths$']
where continent is not null
group by date
order by 1;

-- Total Population vs Vaccinations
-- Shows Percentage of Population that has recieved at least one Covid Vaccine

select de.continent, de.location, de.date, de.population, va.new_vaccinations
, SUM(convert(int,va.new_vaccinations)) over (partition by de.location order by de.location, de.date) as rolling_vaccinations
from PortfolioProject..['covid_deaths$'] de
join PortfolioProject..['covid_vaccinations$'] va
on de.location = va.location
and de.date = va.date
where de.continent is not null
order by 2,3;

-- Using CTE to perform Calculation on Partition By in previous query

with PopvsVac (continent, location, date, population, new_vaccinations, rolling_vaccinations) as
(
select de.continent, de.location, de.date, de.population, va.new_vaccinations
, SUM(convert(int,va.new_vaccinations)) over (partition by de.location order by de.location, de.date) as rolling_vaccinations
from PortfolioProject..['covid_deaths$'] de
join PortfolioProject..['covid_vaccinations$'] va
on de.location = va.location
and de.date = va.date
where de.continent is not null
)
select *, (rolling_vaccinations/population)*100
from PopvsVac
order by 2,3;

-- Using Temp Table to perform Calculation on Partition By in previous query

drop table if exists #PercentPopulationVaccinated
create table #PercentPopulationVaccinated
(
continent nvarchar(255),
location nvarchar(255),
date datetime,
population numeric,
new_vaccinations numeric,
rolling_vaccinations numeric,
)

insert into #PercentPopulationVaccinated
select de.continent, de.location, de.date, de.population, va.new_vaccinations
, SUM(cast(va.new_vaccinations as int)) over (partition by de.location order by de.location, de.date) as rolling_vaccinations
from PortfolioProject..['covid_deaths$'] de
join PortfolioProject..['covid_vaccinations$'] va
on de.location = va.location
and de.date = va.date

select *, (rolling_vaccinations/population)*100
from #PercentPopulationVaccinated
order by 2,3;

-- Creating View to store data for later visualizations

create view PercentPopulationVaccinated as
select de.continent, de.location, de.date, de.population, va.new_vaccinations
, SUM(convert(int,va.new_vaccinations)) over (partition by de.location order by de.location, de.date) as rolling_vaccinations
from PortfolioProject..['covid_deaths$'] de
join PortfolioProject..['covid_vaccinations$'] va
on de.location = va.location
and de.date = va.date
where de.continent is not null;