clear
set more off
capture log close
set seed 1234

if c(username)=="felip" {
    
	global deaths "C:\Users\felip\Dropbox\R01_MHAS\Mortality_VitalStatistics_Project\RawData_Mortality_VitalStatistics\"
	global data "C:\Users\felip\Dropbox\2024\70ymas\data/"
	global output "C:/Users/felip/Dropbox/Aplicaciones/Overleaf/70yMas/"
	global iter "C:\Users\felip\Dropbox\R01_MHAS\Progresa_Locality_Mortality_Project\CensusData_ITER\" 
	global SP "C:\Users\felip\Dropbox\R01_MHAS\SocialProgramBeneficiaries"
}


if c(username)=="FELIPEME" {
    global deaths "C:/Users/FELIPEME/OneDrive - Inter-American Development Bank Group/Documents/personal/70ymas/data/deaths"
	global data "C:/Users/FELIPEME/OneDrive - Inter-American Development Bank Group/Documents/personal/great_recession/data/"
	global output  "C:\Users\FELIPEME\OneDrive - Inter-American Development Bank Group\Documents\personal\70ymas\"
	global iter "/hdir/0/fmenares/Dropbox/R01_MHAS/Progresa_Locality_Mortality_Project\CensusData_ITER\"
	global SP "/hdir/0/fmenares/Dropbox/R01_MHAS\SocialProgramBeneficiaries"


}

if c(username)=="INEGI" {
    global deaths "Z:\Procesamiento\Insumos\Estadisticas de Defuniones Registradas\"
	global data "Z:\Procesamiento\Insumos\FMS\"
	global output "Z:\Resultados\CPV-2018-08-14\LM575-CPV-2018-08-14\LM575-CPV-2018-08-14-variables.log"	
	global iter "Z:\Procesamiento\Insumos\ITER\"
	global censo "Z:\Procesamiento\Insumos\CENSO\"
	global enigh "Z:\Procesamiento\Insumos\Encuesta Nacional de Ingresos y Gastos de Hogares\"

}

import delimited "$data/economic_census/SAIC_Exporta_20251029_3digits_cleaned", varnames(5) clear 
drop v17

gen cve_ent= substr(entidad, 1,2)
gen cve_mun= substr(municipio, 1,3)
egen cve_ent_mun  = concat(cve_ent cve_mun)
destring(cve_ent_mun), g(muni)
drop if cve_mun == ""
destring(añocensal), replace
g year = añocensal 
ren (actividadeconómica ueunidadeseconómicas h001apersonalocupadototal ///
	 h001bpersonalocupadototalhombres h001cpersonalocupadototalmujeres ///
	 h001dhorastrabajadasporpersonalo h010apersonalremuneradototal ///
	 h010bpersonalremuneradohombres h010cpersonalremuneradomujeres ///
	 h010dhorastrabajadasporpersonalr j000atotalderemuneracionesmillon ///
	 j600agastosporindemnizaciónoliqu j500autilidadesrepartidasalperso) ///
	(econ_act firms emp_tot emp_tot_male emp_tot_female hours_tot ///
	emp_w_tot emp_w_male emp_w_female hours_w_tot w_tot severance bonuses)
keep if econ_act == "Total municipal"
drop añocensal entidad municipio cve_ent_mun
order year cve_ent cve_mun muni 

label var econ_act "economic activity (SCIAN 2023)"
label var firms "# firms"
label var emp_tot "# employees"
label var emp_tot_male "# male employees"
label var emp_tot_female "# female employees"
label var hours_tot "# hours worked by employees (thousands)"
label var emp_w_tot "# employees with wages (thousands)"
label var emp_w_male "# male employees with wages (thousands)"
label var emp_w_female "# female employees with wages (thousands)"
label var hours_w_tot "# hours worked by employees with wages (thousands)"
label var w_tot "total of wages (millions of pesos)"
label var severance "severance payments (millions of pesos)"
label var bonuses "bonuses payments (millions of pesos)"
drop econ_act
destring(cve_ent cve_mun), replace
*convert everything to 2025 USD, everything is in 2023 MXN
ren (cve_ent cve_mun muni) (CLAVE_ENTIDAD_INEGI_CLAVE_DE_AGE CLAVE_MUNICIPIO_INEGI_CLAVE_DE_A geo2_mx2000)  
merge m:1 geo2_mx2000 using "$data/cz_crosswalk/faber_2020/crosswalk_geo2_mx_cz", keep(1 3)
ren _merge m_faber


/*
           | Matching result from
           |         merge
      year | Master on  Matched ( |     Total
-----------+----------------------+----------
      2002 |       117      2,329 |     2,446 
      2007 |       125      2,329 |     2,454 
      2012 |       126      2,329 |     2,455 
      2017 |       134      2,330 |     2,464 
      2022 |       145      2,326 |     2,471 
-----------+----------------------+----------
     Total |       647     11,643 |    12,290 
*/

merge m:1 CLAVE_ENTIDAD_INEGI_CLAVE_DE_AGE CLAVE_MUNICIPIO_INEGI_CLAVE_DE_A ///
using "$data/cz_crosswalk/banxico/Mercados de trabajo locales", keep(1 3) ///
keepus(MERCADO_TRABAJO_LOCAL)
ren _merge m_banxico

ren (cz MERCADO_TRABAJO_LOCAL CLAVE_ENTIDAD_INEGI_CLAVE_DE_AGE ///
CLAVE_MUNICIPIO_INEGI_CLAVE_DE_A geo2_mx2000) (cz_faber cz_banxico cve_ent cve_mun muni)
drop geo2_mx

save "$data/economic_census/econ_census_cz.dta", replace







