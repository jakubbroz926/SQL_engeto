##### 1.èást SQL - time and covid data ####
#Jako èasový úsek byl zvolen únor 2020
CREATE OR REPLACE table t_jakub_broz_sqlcovid 
select cbd.*, ct.tests_performed, (select population from countries c2
where c2.country = cbd.country) as country_pop
from covid19_basic_differences cbd
left join covid19_tests ct 
on cbd.country = ct.country
and cbd.`date` = ct.`date` 
where cbd.`date` BETWEEN "2020-02-01" and "2020-02-28"
order by cbd.country ;
#Sql pro vytvoøení datový sloupcù- tento dotaz byl napsán jako první a pozdìji už jsem ho nechtìl vytváøet jako jednoho dotazu, ale pøedpokládám, že 
#to bude tøeba pøepsat.
CREATE OR REPLACE table t_times_slots as (select c.country, cbd.`date` ,
case when WEEKDAY(cbd.`date`) < 5 then 0 else 1 end as weekday,
QUARTER(cbd.`date`)-1 as period
from countries c
join covid19_basic_differences cbd on c.country  = cbd.country
where cbd.`date` between "2020-02-01" and "2020-02-28")# zde lze zmìnit parametr výbìru datumù
;

##### 2.èást SQL - religion, economies, countries, life_expectancy#####

#Script na výpoèet life_expectancy 

CREATE OR REPLACE TABLE t_jakub_broz_sql_life select le.country,
le2.life_expectancy - le.life_expectancy as difference_of_life_exp
from life_expectancy le,life_expectancy le2 
where le.`year` = 1965 and le2.`year` = 2015
and le.country = le2.country 
order by country ;

#Script vytváøející tabulku podílù náboženství v jednotlivých zemích.Jako èasový údaj byl zvolen rok 2010. 
CREATE OR REPLACE table t_jakub_broz_sql_rel SELECT r.country,
sum(case when r.religion = 'Christianity' then round(r.population /c2.population,5
)*100 else 0 end) as christianity_population_percent,
sum(case when r.religion = 'Islam' then round(r.population /c2.population,5
)*100 else 0 end) as islam_population_percent,
sum(case when r.religion = 'Unaffiliated Religions' then round(r.population /c2.population,5
)*100 else 0 end) as unaffiliated_population_percent,
sum(case when r.religion = 'Hinduism' then round(r.population /c2.population,5
)*100 else 0 end) as hinduism_population_percent,
sum(case when r.religion = 'Buddhism' then round(r.population /c2.population,5
)*100 else 0 end) as buddhism_population_percent,
sum(case when r.religion = 'Folk Religions' then round(r.population /c2.population,5
)*100 else 0 end) as folk_rel_population_percent,
sum(case when r.religion = 'Other Religions' then round(r.population /c2.population,5
)*100 else 0 end) as other_rel_population_percent,
sum(case when r.religion = 'Judaism' then round(r.population /c2.population,5
)*100 else 0 end) as judaism_population_percent
from religions r 
inner join countries c2 on
c2.country = r.country 
where year = 2010
group by c2.country 

#Script na spojení t_jakub_broz_sql_rel,t_jakub_broz_sql_life, dat z countries a economies 
create or replace table t_jakub_broz_sql_comdata SELECT c.country ,
c.population_density ,
round(e.GDP/e.population) as GDP_p_capita,
(case when e.gini is null then 0 else e.gini end) as gini,
e.mortaliy_under5 ,
c.median_age_2018,
jb_rel.christianity_population_percent,
jb_rel.islam_population_percent, 
jb_rel.unaffiliated_population_percent,
jb_rel.hinduism_population_percent,
jb_rel.buddhism_population_percent,
jb_rel.folk_rel_population_percent,
jb_rel.other_rel_population_percent,
jb_rel.judaism_population_percent,
jb_life.difference_of_life_exp
from countries c  
inner join economies e on 
c.country = e.country 
inner join t_jakub_broz_sql_life as jb_life on 
c.country = jb_life.country 
inner join t_jakub_broz_sql_rel as jb_rel on
c.country = jb_rel.country 
where e.`year` = 2018
order by country ;

#### 3.èást SQL - weather #### pouze pro mìsíc únor
#Data pro hlavní mìsta evropy byla vztažena na celou zemi, data pro neevropské zemì chybí
CREATE OR REPLACE TABLE t_jakub_broz_sql_weather2 select c2.country ,
`date`,
avg(case when hour between 6 and 18 then temp end) as avg_daily_temperature, 
sum(case when rain > 0 then 3 else 0 end) as rainy_hours,
max(wind) as maximal_wind
FROM weather w 
left join countries c2 on
c2.capital_city = w.city 
where date between "2020-02-01" and "2020-02-28" 
and city != "Brno"
group by city,`date` ;


#Finální script, který spojuje všechny podtabulky a vytváøí výslednou tabulku
CREATE OR REPLACE table t_jakub_broz_project_final_sql
SELECT tt.*,
cov.confirmed,
cov.deaths,
cov.recovered,
cov.tests_performed,
cov.country_pop,
com.population_density,
com.GDP_p_capita,
com.gini ,
com.mortaliy_under5 ,
com.christianity_population_percent,
com.islam_population_percent,
com.unaffiliated_population_percent,
com.hinduism_population_percent,
com.buddhism_population_percent,
com.folk_rel_population_percent,
com.other_rel_population_percent,
com.judaism_population_percent,
com.median_age_2018 ,
w2.avg_daily_temperature ,
w2.rainy_hours ,
w2.maximal_wind 
FROM `data`.t_times_slots as tt
inner join `data`.t_jakub_broz_sql_comdata as com
on com.country = tt.country 
Left join `data`.t_jakub_broz_sql_weather2 as w2
on com.country = w2.country and tt.`date` = w2.`date`
inner join t_jakub_broz_sqlcovid as cov
on com.country = cov.country
order by com.country;

select * from t_jakub_broz_project_final_sql



