--Select *
--FROM Project..CovidDeaths
--ORDER BY 3,4

--Select *
--FROM Project..CovidVaccinations
--ORDER BY 3,4

-- Adatok kiv�laszt�sa, amiket haszn�lni fogok

Select Location, date, total_cases, new_cases, total_deaths, population
FROM Project..CovidDeaths
ORDER BY 1,2

-- �sszes fert�z�tts�g �s Hal�l �sszehasonl�t�sa adott orsz�gban

Select Location, date, total_cases, total_deaths, (total_deaths/total_cases) * 100 AS Percentage
FROM Project..CovidDeaths
WHERE location='Hungary'
ORDER BY 1,2

-- �sszes fert�z�tts�g �s Lakooss�g �sszehasonl�t�sa

Select Location, date, total_cases, population, (total_cases / population ) * 100 AS Percentage
FROM Project..CovidDeaths
WHERE location='Hungary'
ORDER BY 1,2

-- Az orsz�gok a legnagyobb Fert�z�s ar�nnyal Lakoss�ghoz k�pest

Select Location, population, MAX(total_cases) as HighestInfectionCount, Max((total_cases / population )) * 100 AS Percentage
FROM Project..CovidDeaths
GROUP BY Location, population
ORDER BY Percentage desc

-- Nem orsz�gok hib�s form�z�s�nak kijav�t�sa az adatb�zis m�dos�t�sa n�lk�l
Select *
From Project..CovidDeaths
WHERE continent is not null
order by 3,4


-- Legnagyobb Hal�loz�si ar�ny Lakoss�ghoz k�pest orsz�gonk�nt
Select Location, MAX(cast(total_deaths as int)) as TotalDeaths
FROM Project..CovidDeaths
WHERE continent is not null
GROUP BY Location, population
ORDER BY TotalDeaths desc


-- Kontinensekre bont�s (hib�s adatok, location �s is null alapj�n a helyest �rja)
-- Kontinensek a legmagasabb hal�l / lakoss�g ar�nnyal
Select continent, MAX(cast(total_deaths as int)) as TotalDeaths
FROM Project..CovidDeaths
WHERE continent is not null
GROUP BY continent
ORDER BY TotalDeaths desc


-- GLOB�LIS SZ�MOK

	--Napi Fert�z�s, Napi Hal�loz�s, illetve a kett�nek az ar�nya
Select date, SUM(new_cases) AS 'New Cases', SUM(cast(new_deaths as int)) as 'New Deaths', SUM(cast(new_deaths as int))/NULLIF(SUM(new_cases), 0) * 100 
AS 'Mortality Percentage'
FROM Project..CovidDeaths
--WHERE location='Hungary'
WHERE continent is not null
group by date
ORDER BY 1,2

		--Az COVID elej�t�l mai napig m�rt �sszes Fert�z�s / Hal�l, illetve sz�zal�ka
		Select SUM(new_cases) AS 'Total Cases', SUM(cast(new_deaths as int)) as 'Total Deaths', SUM(cast(new_deaths as int))/NULLIF(SUM(new_cases), 0) * 100 
		AS 'Mortality Percentage'
		FROM Project..CovidDeaths
		--WHERE location='Hungary'
		WHERE continent is not null
		ORDER BY 1,2




-- VACCINATIONS DATA

-- Popul�ci� �s Olt�s �sszehasonl�t�sa (Napi �j olt�sok, �sszes olt�s addig az orsz�gban)
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


-- VIEW k�sz�t�se k�s�bbi adat megjelen�t�shez

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

