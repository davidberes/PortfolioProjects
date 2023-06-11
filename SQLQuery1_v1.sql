--Select *
--FROM Project..CovidDeaths
--ORDER BY 3,4

--Select *
--FROM Project..CovidVaccinations
--ORDER BY 3,4

-- Adatok kiválasztása, amiket használni fogok

Select Location, date, total_cases, new_cases, total_deaths, population
FROM Project..CovidDeaths
ORDER BY 1,2

-- Összes fertõzöttség és Halál összehasonlítása adott országban

Select Location, date, total_cases, total_deaths, (total_deaths/total_cases) * 100 AS Percentage
FROM Project..CovidDeaths
WHERE location='Hungary'
ORDER BY 1,2

-- Összes fertõzöttség és Lakoosság összehasonlítása

Select Location, date, total_cases, population, (total_cases / population ) * 100 AS Percentage
FROM Project..CovidDeaths
WHERE location='Hungary'
ORDER BY 1,2

-- Az országok a legnagyobb Fertõzés aránnyal Lakossághoz képest

Select Location, population, MAX(total_cases) as HighestInfectionCount, Max((total_cases / population )) * 100 AS Percentage
FROM Project..CovidDeaths
GROUP BY Location, population
ORDER BY Percentage desc

-- Nem országok hibás formázásának kijavítása az adatbázis módosítása nélkül
Select *
From Project..CovidDeaths
WHERE continent is not null
order by 3,4


-- Legnagyobb Halálozási arány Lakossághoz képest országonként
Select Location, MAX(cast(total_deaths as int)) as TotalDeaths
FROM Project..CovidDeaths
WHERE continent is not null
GROUP BY Location, population
ORDER BY TotalDeaths desc


-- Kontinensekre bontás (hibás adatok, location és is null alapján a helyest írja)
-- Kontinensek a legmagasabb halál / lakosság aránnyal
Select continent, MAX(cast(total_deaths as int)) as TotalDeaths
FROM Project..CovidDeaths
WHERE continent is not null
GROUP BY continent
ORDER BY TotalDeaths desc


-- GLOBÁLIS SZÁMOK

	--Napi Fertõzés, Napi Halálozás, illetve a kettõnek az aránya
Select date, SUM(new_cases) AS 'New Cases', SUM(cast(new_deaths as int)) as 'New Deaths', SUM(cast(new_deaths as int))/NULLIF(SUM(new_cases), 0) * 100 
AS 'Mortality Percentage'
FROM Project..CovidDeaths
--WHERE location='Hungary'
WHERE continent is not null
group by date
ORDER BY 1,2

		--Az COVID elejétõl mai napig mért összes Fertõzés / Halál, illetve százaléka
		Select SUM(new_cases) AS 'Total Cases', SUM(cast(new_deaths as int)) as 'Total Deaths', SUM(cast(new_deaths as int))/NULLIF(SUM(new_cases), 0) * 100 
		AS 'Mortality Percentage'
		FROM Project..CovidDeaths
		--WHERE location='Hungary'
		WHERE continent is not null
		ORDER BY 1,2




-- VACCINATIONS DATA

-- Populáció és Oltás összehasonlítása (Napi új oltások, összes oltás addig az országban)
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
,SUM(convert(bigint,vac.new_vaccinations)) OVER (Partition by dea.location Order BY dea.location, dea.date) AS Country_Vaccination
From Project..CovidDeaths dea 
JOIN Project..CovidVaccinations vac
	ON dea.location = vac.location
	AND dea.date = vac.date
where dea.continent is not null
ORDER BY 2,3

	--USE CTE
	WITH PopulationVsVaccination (Continent, Location, Date, Population,new_vaccinations ,Country_Vaccination)
	as
	(
	Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
	,SUM(convert(bigint,vac.new_vaccinations)) OVER (Partition by dea.location Order BY dea.location, dea.date) AS Country_Vaccination
	From Project..CovidDeaths dea 
	JOIN Project..CovidVaccinations vac
	ON dea.location = vac.location
	AND dea.date = vac.date
	where dea.continent is not null
	--ORDER BY 2,3
	)
	Select *, (Country_Vaccination / Population)*100
	From PopulationVsVaccination

-- TEMP TABLE
DROP TABLE if exists #PercentPopulationVaccinated
CREATE Table #PercentPopulationVaccinated
(
	Continent nvarchar(255),
	Location nvarchar(255),
	Date datetime,
	Population numeric,
	new_vaccinations numeric,
	Country_Vaccination numeric
)

INSERT INTO #PercentPopulationVaccinated
	Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
	,SUM(convert(bigint,vac.new_vaccinations)) OVER (Partition by dea.location Order BY dea.location, 
	 dea.date) AS Country_Vaccination
	From Project..CovidDeaths dea 
	JOIN Project..CovidVaccinations vac
	ON dea.location = vac.location
	AND dea.date = vac.date
	where dea.continent is not null
	--ORDER BY 2,3
	
	Select *, (Country_Vaccination / Population)*100
	From #PercentPopulationVaccinated


-- VIEW készítése késõbbi adat megjelenítéshez

Create View PercentPopulationVaccinated as
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
	,SUM(convert(bigint,vac.new_vaccinations)) OVER (Partition by dea.location Order BY dea.location, 
	 dea.date) AS Country_Vaccination
	From Project..CovidDeaths dea 
	JOIN Project..CovidVaccinations vac
	ON dea.location = vac.location
	AND dea.date = vac.date
	where dea.continent is not null
	ORDER BY 2,3

Select *
FROM PercentPopulationVaccinated

