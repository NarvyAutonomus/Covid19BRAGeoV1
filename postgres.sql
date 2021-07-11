-- DROP SCHEMA covid;

CREATE SCHEMA covid AUTHORIZATION postgres;


-- covid.covid_casos_full definition

-- Drop table

-- DROP TABLE covid.covid_casos_full;

CREATE TABLE covid.covid_casos_full (
city text NULL,
city_ibge_code text NULL,
"date" text NULL,
epidemiological_week text NULL,
estimated_population text NULL,
estimated_population_2019 text NULL,
is_last text NULL,
is_repeated text NULL,
last_available_confirmed text NULL,
last_available_confirmed_per_100k_inhabitants text NULL,
last_available_date text NULL,
last_available_death_rate text NULL,
last_available_deaths text NULL,
order_for_place text NULL,
place_type text NULL,
state text NULL,
new_confirmed text NULL,
new_deaths text NULL
);

-- covid.municipios definition

-- Drop table

-- DROP TABLE covid.municipios;

CREATE TABLE covid.municipios (
codigo_ibge text NULL,
nome text NULL,
latitude text NULL,
longitude text NULL,
capital text NULL,
codigo_uf text NULL
);
