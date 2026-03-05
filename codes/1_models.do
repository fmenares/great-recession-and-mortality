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
	global output  "C:\Users\FELIPEME\OneDrive - Inter-American Development Bank Group\Documents\personal\great_recession\"
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


*models
use  "$data/deaths/mortality_shock_data.dta", clear
*variables
{
g pop_06 = pop *(year == 2006)
g pop_07 = pop *(year == 2007)
g pop_08 = pop *(year == 2008)
bys cz: egen pop06 = max(pop_06)
bys cz: egen pop07 = max(pop_07)
bys cz: egen pop08 = max(pop_08)

	
*Log of rates

*aamr = asdr * proportion_2000
g laamr = log(aamr * 100000)
g laamr_f = log(aamr_f * 100000)
g laamr_m = log(aamr_m * 100000)

*age-adjusted cause specific death rate
global disaese = "cvd nutri infec neoplasm mental digest peri homicide others"

foreach dis in $disease {
	g laamr_`dis' = log(aamr_`dis' * 100000)
}
	
g laamr_non_cvd = log(aamr_non_cvd * 100000)

g laamr_cvd_f = log(aamr_cvd_f * 100000)
g laamr_non_cvd_f = log(aamr_non_cvd_f * 100000)

g laamr_cvd_m = log(aamr_cvd_m * 100000)
g laamr_non_cvd_m = log(aamr_non_cvd_m * 100000)

g lasdr_0_14 = log(asdr_0_14 * 100000)
g lasdr_15_49 = log(asdr_15_49 * 100000)
g lasdr_15_64 = log(asdr_15_64 * 100000)
g lasdr_50_69 = log(asdr_50_69 * 100000)
g lasdr_70 = log(asdr_70 * 100000)


*age-specific death rates by sex
global sex = "female male"
foreach sex in $sex {
	
	g lasdr_`sex'_0_14 = log(asdr_`sex'_0_14 * 100000)
	g lasdr_`sex'_15_49 = log(asdr_`sex'_15_49 * 100000)
	g lasdr_`sex'_15_64 = log(asdr_`sex'_15_64 * 100000) 
	g lasdr_`sex'_50_69 = log(asdr_`sex'_50_69 * 100000) 
	g lasdr_`sex'_70 = log(asdr_`sex'_70 * 100000) 
	
	g lasdr_cvd_`sex'_0_14 = log(asdr_cvd_`sex'_0_14 * 100000)
	g lasdr_cvd_`sex'_15_49 = log(asdr_cvd_`sex'_15_49 * 100000)
	g lasdr_cvd_`sex'_15_64 = log(asdr_cvd_`sex'_15_64 * 100000) 
	g lasdr_cvd_`sex'_50_69 = log(asdr_cvd_`sex'_50_69 * 100000)
	g lasdr_cvd_`sex'_70 = log(asdr_cvd_`sex'_70 * 100000)
	
	g lasdr_non_cvd_`sex'_0_14 = log(asdr_non_cvd_`sex'_0_14 * 100000)
	g lasdr_non_cvd_`sex'_15_49 = log(asdr_non_cvd_`sex'_15_49 * 100000)
	g lasdr_non_cvd_`sex'_15_64 = log(asdr_non_cvd_`sex'_15_64 * 100000) 
	g lasdr_non_cvd_`sex'_50_69 = log(asdr_non_cvd_`sex'_50_69 * 100000)
	g lasdr_non_cvd_`sex'_70 = log(asdr_non_cvd_`sex'_70 * 100000)
}
	
	*by disases
global disaese = "cvd nutri infec neoplasm mental digest peri homicide others"

foreach var in $dis {
	g lasdr_`dis'_0_14 = log(asdr_`dis'_0_14 * 100000)
	g lasdr_`dis'_15_49 = log(asdr_`dis'_15_49 * 100000)
	g lasdr_`dis'_15_64 = log(asdr_`dis'_15_64 * 100000)
	g lasdr_`dis'_50_69 = log(asdr_`dis'_50_69 * 100000)
	g lasdr_`dis'_70 = log(asdr_`dis'_70 * 100000)
}

*Post shock variables

global ratios = "emp_pop emp_w_pop emp_pop_15_64 emp_w_pop_15_64 emp_pop_f emp_w_pop_f emp_pop_f_15_64 emp_w_pop_f_15_64 emp_pop_m emp_w_pop_m emp_pop_m_15_64 emp_w_pop_m_15_64"

foreach var in $ratios {
	gen post_s_`var'_3_8_07 = shock_`var'_03_08 * (year>=2007) 
	gen post_s_`var'_3_8_08 = shock_`var'_03_08 * (year>=2008) 
	gen post_s_`var'_3_8_09 = shock_`var'_03_08 * (year>=2009)
		
	gen post_s_`var'_3_13_07 = shock_`var'_03_13 * (year>=2007) 
	gen post_s_`var'_3_13_08 = shock_`var'_03_13 * (year>=2008) 
	gen post_s_`var'_3_13_09 = shock_`var'_03_13 * (year>=2009)
	
	gen post_s_`var'_8_13_07 = shock_`var'_08_13 * (year>=2007) 
	gen post_s_`var'_8_13_08 = shock_`var'_08_13 * (year>=2008) 
	gen post_s_`var'_8_13_09 = shock_`var'_08_13 * (year>=2009)
}
}

/*
foreach var in $ratios {
	forv year = 1998/2015 {
		g sh_`var'_03_08_`year' = shock_`var'_03_08 * (year == `year')
	}
	
}
*check outliers above 1 on emp (informals) vs emp w

foreach var in $ratios {
	drop sh_`var'_03_08_2006	
}
*/

*TABLE 1

/*Shock between 03 and 08*/
*It seems there is an adverse effect on mortality after 2006 (2007, 2008, 2009)
*the effect is significant on shocks using the ratio of employees who receive a salary rather than all of the employees


*2007

local i = 1
global depvar = "post_s_emp_pop_3_8_07 post_s_emp_pop_15_64_3_8_07 post_s_emp_w_pop_3_8_07 post_s_emp_w_pop_15_64_3_8_07"
foreach shock in $depvar {
quiet reghdfe laamr `shock' [pw=pop06], a(year cz) vce(cluster cz)

	local OLS_07_`i'_aux : di %12.4f _b[`shock']*100
	local SE_07_`i' : di %12.4f _se[`shock']
	
	local t_`i' = abs(_b[`shock']/_se[`shock'])
	
	if (`t_`i'' >= 2.576) {
		local OLS_07_`i' = "`OLS_07_`i'_aux'***"	
	} 

	if inrange(`t_`i'', 1.96, 2.575) {
		local OLS_07_`i' = "`OLS_07_`i'_aux'**"	
	} 


	if inrange(`t_`i'', 1.645, 1.95) {
		local OLS_07_`i' = "`OLS_07_`i'_aux'*"	
	} 

	if (`t_`i'' < 1.645) {
		local OLS_07_`i' = "`OLS_07_`i'_aux'"	
	} 
	
	
	sum laamr if e(sample)
	local mean_dep`i': di %12.0fc `r(mean)'
	local N`i': di %12.0fc `e(N)'


	*increment on i 
    local ++i
}



*2008
loca i = 1
global depvar = "post_s_emp_pop_3_8_08 post_s_emp_pop_15_64_3_8_08 post_s_emp_w_pop_3_8_08 post_s_emp_w_pop_15_64_3_8_08"
foreach shock in $depvar {

	quiet reghdfe  laamr `shock' [pw=pop06], a(year cz) vce(cluster cz)
	local OLS_08_`i'_aux : di %12.4f _b[`shock']*100
	local SE_08_`i' : di %12.4f _se[`shock']

		local t_`i' = abs(_b[`shock']/_se[`shock'])
	
	if (`t_`i'' >= 2.576) {
		local OLS_08_`i' = "`OLS_08_`i'_aux'***"	
	} 

	if inrange(`t_`i'', 1.96, 2.575) {
		local OLS_08_`i' = "`OLS_08_`i'_aux'**"	
	} 


	if inrange(`t_`i'', 1.645, 1.95) {
		local OLS_08_`i' = "`OLS_08_`i'_aux'*"	
	} 

	if (`t_`i'' < 1.645) {
		local OLS_08_`i' = "`OLS_08_`i'_aux'"	
	} 
	
	sum laamr if e(sample)
	local mean_dep`i': di %12.0fc `r(mean)'
	local N`i': di %12.0fc `e(N)'


	*increment on i 
    local ++i
}

*2009
local i=1
global depvar = "post_s_emp_pop_3_8_09 post_s_emp_pop_15_64_3_8_09 post_s_emp_w_pop_3_8_09 post_s_emp_w_pop_15_64_3_8_09"
foreach shock in $depvar {
	quiet reghdfe laamr `shock' [pw=pop06], a(year cz) vce(cluster cz)
	
	local OLS_09_`i'_aux : di %12.4f _b[`shock']*100
	local SE_09_`i' : di %12.4f _se[`shock']

	
	local t_`i' = abs(_b[`shock']/_se[`shock'])
	
	if (`t_`i'' >= 2.576) {
		local OLS_09_`i' = "`OLS_09_`i'_aux'***"	
	} 

	if inrange(`t_`i'', 1.96, 2.575) {
		local OLS_09_`i' = "`OLS_09_`i'_aux'**"	
	} 


	if inrange(`t_`i'', 1.645, 1.95) {
		local OLS_09_`i' = "`OLS_09_`i'_aux'*"	
	} 

	if (`t_`i'' < 1.645) {
		local OLS_09_`i' = "`OLS_09_`i'_aux'"	
	} 
	
	sum laamr if e(sample)
	local mean_dep`i': di %12.4fc `r(mean)'
	local N`i': di %12.0fc `e(N)'
	distinct cz if e(sample)
	local ncz`i' : di %12.0fc `r(ndistinct)'


	*increment on i 
    local ++i
}


/*Shock between 03 and 13*/

*2007

local i = 5
global depvar = "post_s_emp_pop_3_13_07 post_s_emp_pop_15_64_3_13_07 post_s_emp_w_pop_3_13_07 post_s_emp_w_pop_15_64_3_13_07"
foreach shock in $depvar {
quiet reghdfe laamr `shock' [pw=pop06], a(year cz) vce(cluster cz)

	local OLS_07_`i'_aux : di %12.4f _b[`shock']*100
	local SE_07_`i' : di %12.4f _se[`shock']
	
	local t_`i' = abs(_b[`shock']/_se[`shock'])
	
	if (`t_`i'' >= 2.576) {
		local OLS_07_`i' = "`OLS_07_`i'_aux'***"	
	} 

	if inrange(`t_`i'', 1.96, 2.575) {
		local OLS_07_`i' = "`OLS_07_`i'_aux'**"	
	} 


	if inrange(`t_`i'', 1.645, 1.95) {
		local OLS_07_`i' = "`OLS_07_`i'_aux'*"	
	} 

	if (`t_`i'' < 1.645) {
		local OLS_07_`i' = "`OLS_07_`i'_aux'"	
	} 
	
	
	sum laamr if e(sample)
	local mean_dep`i': di %12.0fc `r(mean)'
	local N`i': di %12.0fc `e(N)'


	*increment on i 
    local ++i
}



*2008
loca i = 5
global depvar = "post_s_emp_pop_3_13_08 post_s_emp_pop_15_64_3_13_08 post_s_emp_w_pop_3_13_08 post_s_emp_w_pop_15_64_3_13_08"

foreach shock in $depvar {

	quiet reghdfe  laamr `shock' [pw=pop06], a(year cz) vce(cluster cz)
	local OLS_08_`i'_aux : di %12.4f _b[`shock']*100
	local SE_08_`i' : di %12.4f _se[`shock']

		local t_`i' = abs(_b[`shock']/_se[`shock'])
	
	if (`t_`i'' >= 2.576) {
		local OLS_08_`i' = "`OLS_08_`i'_aux'***"	
	} 

	if inrange(`t_`i'', 1.96, 2.575) {
		local OLS_08_`i' = "`OLS_08_`i'_aux'**"	
	} 


	if inrange(`t_`i'', 1.645, 1.95) {
		local OLS_08_`i' = "`OLS_08_`i'_aux'*"	
	} 

	if (`t_`i'' < 1.645) {
		local OLS_08_`i' = "`OLS_08_`i'_aux'"	
	} 
	
	sum laamr if e(sample)
	local mean_dep`i': di %12.0fc `r(mean)'
	local N`i': di %12.0fc `e(N)'


	*increment on i 
    local ++i
}

*2009

local i=5
global depvar = "post_s_emp_pop_3_13_09 post_s_emp_pop_15_64_3_13_09 post_s_emp_w_pop_3_13_09 post_s_emp_w_pop_15_64_3_13_09"

foreach shock in $depvar {
	quiet reghdfe laamr `shock' [pw=pop06], a(year cz) vce(cluster cz)
	
	local OLS_09_`i'_aux : di %12.4f _b[`shock']*100
	local SE_09_`i' : di %12.4f _se[`shock']

	
	local t_`i' = abs(_b[`shock']/_se[`shock'])
	
	if (`t_`i'' >= 2.576) {
		local OLS_09_`i' = "`OLS_09_`i'_aux'***"	
	} 

	if inrange(`t_`i'', 1.96, 2.575) {
		local OLS_09_`i' = "`OLS_09_`i'_aux'**"	
	} 


	if inrange(`t_`i'', 1.645, 1.95) {
		local OLS_09_`i' = "`OLS_09_`i'_aux'*"	
	} 

	if (`t_`i'' < 1.645) {
		local OLS_09_`i' = "`OLS_09_`i'_aux'"	
	} 
	
	sum laamr if e(sample)
	local mean_dep`i': di %12.4fc `r(mean)'
	local N`i': di %12.0fc `e(N)'
	distinct cz if e(sample)
	local ncz`i' : di %12.0fc `r(ndistinct)'


	*increment on i 
    local ++i
}


			cap file close sm
		file open sm using "$output/tables/T1_03_08_13.tex", write replace 
		file write sm "\begin{tabular}{lcccccccc} \hline \hline"_n
		file write sm "& \multicolumn{4}{c}{Schock 2003-2008} & \multicolumn{4}{c}{Shock 2003-2013} \\ "_n
		file write sm "& \multicolumn{1}{c}{Emp/Pop} & \multicolumn{1}{c}{Emp/Pop 15-64} & \multicolumn{1}{c}{Emp W/Pop} & \multicolumn{1}{c}{Emp W/Pop 15-64} & \multicolumn{1}{c}{Emp/Pop} & \multicolumn{1}{c}{Emp/Pop 15-64} & \multicolumn{1}{c}{Emp W/Pop} & \multicolumn{1}{c}{Emp W/Pop 15-64}  \\ "_n
		file write sm "\cmidrule(lr){2-2}\cmidrule(lr){3-3}\cmidrule(lr){4-4} \cmidrule(lr){5-5}\cmidrule(lr){6-6}\cmidrule(lr){7-7}\cmidrule(lr){8-8} \cmidrule(lr){9-9}"_n
		file write sm "& (1) & (2) & (3) & (4) & (5) & (6) & (7) & (8) \\  \toprule"_n
		file write sm "\textit{Shock-Post 2007} & `OLS_07_1'  & `OLS_07_2' & `OLS_07_3' & `OLS_07_4' & `OLS_07_5'  & `OLS_07_6' & `OLS_07_7' & `OLS_07_8'\\  "_n
		file write sm "& (`SE_07_1')  & (`SE_07_2') & (`SE_07_3') & (`SE_07_4') & (`SE_07_5')  & (`SE_07_6') & (`SE_07_7') & (`SE_07_8')\\ "_n
		file write sm "\textit{Shock-Post 2008} & `OLS_08_1'  & `OLS_08_2' & `OLS_08_3' & `OLS_08_4' & `OLS_08_5'  & `OLS_08_6' & `OLS_08_7' & `OLS_08_8'\\  "_n
		file write sm " & (`SE_08_1') & (`SE_08_2') & (`SE_08_3') & (`SE_08_4') & (`SE_08_5') & (`SE_08_6') & (`SE_08_7') & (`SE_08_8') \\ "_n
		file write sm "\textit{Shock-Post 2009} & `OLS_09_1'  & `OLS_09_2' & `OLS_09_3' & `OLS_09_4' & `OLS_09_5'  & `OLS_09_6' & `OLS_09_7' & `OLS_09_8' \\  "_n
		file write sm "& (`SE_09_1')  & (`SE_09_2') & (`SE_09_3') & (`SE_09_4') & (`SE_09_5')  & (`SE_09_6') & (`SE_09_7') & (`SE_09_8') \\ "_n
		file write sm "&  &   &  & &  &   &  &   \\ "_n
		file write sm "Mean AAMR & `mean_dep1'  & `mean_dep2' & `mean_dep3' & `mean_dep4' & `mean_dep5'  & `mean_dep6' & `mean_dep7' & `mean_dep8'  \\  "_n
		file write sm "Obs & `N1'  & `N2' & `N3' & `N4' & `N5'  & `N6' & `N7' & `N8' \\ \\  "_n
		file write sm "No. CZ & `ncz1'  & `ncz2' & `ncz3' & `ncz4' & `ncz5'  & `ncz6' & `ncz7' & `ncz8' \\ \\  "_n
		file write sm "&  &  &  & &  &  &  & 	  \\  "_n		
		file write sm "Year FE & Y & Y & Y & Y & Y & Y & Y & Y  \\ "_n
		file write sm "CZ FE & Y & Y & Y & Y & Y & Y & Y & Y \\ "_n	
		file write sm "CZ Controls & N  & N & N & N & N  & N & N & N    \\  "_n
		file write sm "Weight & Y & Y & Y & Y & Y & Y & Y & Y \\ "_n
		file write sm "Cluster SE: CZ & Y & Y & Y & Y & Y & Y & Y & Y \\ "_n
		*file write sm "Year x Age Eligible FE & Y & Y & Y & Y & Y & Y & Y \\ "_n
		*file write sm "Year x Locality Eligible FE & Y & Y & Y & Y & Y & Y & Y \\ "_n
		*file write sm "Age x Locality Eligible FE & Y & Y & Y & Y & Y & Y & Y \\ "_n
		file write sm "\bottomrule"_n
		file write sm "\end{tabular}"
		file close sm
		
		*check TAble 1 from 70 y Mas, it should not say "dynamic"
		*Effects are already %, mean dep is on log(mr), is a 0.3% large or small? how many deads? should the mean dep be on the pre-eligible?
		*Notes: This table shows the results obtained from estimating a difference-in-differences using the logarithm of mortality rate as the dependent variable in a linear regression. Columns (1) to (4), and (5) to (9) captures the effect of the shock measured as the linear percent difference of the ratio of measurements of employment to population between 2003 and 2008, and 2003 and 2013, respectevely. Regression includes year and commuting zone (CZ) fixed effects. Standard errors are clustered at the level of CZ. Post variable correspondes to the year the shock variable is measured, e.g., Post 2007, for column (1), stands for the effect of the shock after 2007, where the shock stands for the percent difference of the ratio of employment to population between 2003 and 2008. 
		
		The reported coefficient corresponds to percent changes. Each estimate captures the effect post-shock for those CZ relative to deaths in non-eligible localities. The period of analysis is from 2002 to 2011. All regressions are weighted using the population aged 60 to 79 in 2005, and control for locality-level time-varying covariates: Marginality index, Progresa penetration, Percentage of deaths medically certified, and lag of death registration. The population offset is interpolated from the 2000, 2005, and 2010 Census data at the locality-age-year level. Number of Deaths Eligible corresponds to those deaths reported as residing in eligible localities above or equal to age 70, a year before the coverage. ***p<0.01,**p<0.05,*p<0.1


		/* 4 Columns TAble

			cap file close sm
		file open sm using "$output/tables/T1_03_08.tex", write replace 
		file write sm "\begin{tabular}{lcccc} \hline \hline"_n
		file write sm "& \multicolumn{1}{c}{Emp/Pop} & \multicolumn{1}{c}{Emp/Pop 15-64} & \multicolumn{1}{c}{Emp W/Pop} & \multicolumn{1}{c}{Emp W/Pop 15-64}  \\ "_n
		file write sm "\cmidrule(lr){2-2}\cmidrule(lr){3-3}\cmidrule(lr){4-4} \cmidrule(lr){5-5}"_n
		file write sm "& (1) & (2) & (3) & (4)\\  \toprule"_n
		file write sm "\textit{Post 2007} & `OLS_07_1'  & `OLS_07_2' & `OLS_07_3' & `OLS_07_4'\\  "_n
		file write sm "& (`SE_07_1')  & (`SE_07_2') & (`SE_07_3') & (`SE_07_4')\\ "_n
		file write sm "\textit{Post 2008} & `OLS_08_1'  & `OLS_08_2' & `OLS_08_3' & `OLS_08_4'\\  "_n
		file write sm " & (`SE_08_1')  & (`SE_08_2') & (`SE_08_3') & (`SE_08_4')\\ "_n
		file write sm "\textit{Post 2009} & `OLS_09_1'  & `OLS_09_2' & `OLS_09_3' & `OLS_09_4'\\  "_n
		file write sm "& (`SE_09_1')  & (`SE_09_2') & (`SE_09_3') & (`SE_09_4')\\ "_n
		file write sm "&  &   &  &   \\ "_n
		file write sm "Mean AAMR & `mean_dep1'  & `mean_dep2' & `mean_dep3' & `mean_dep4'  \\  "_n
		file write sm "Obs & `N1'  & `N2' & `N3' & `N4' \\ \\  "_n
		file write sm "No. CZ & `ncz1'  & `ncz2' & `ncz3' & `ncz4' \\ \\  "_n
		file write sm "&  &  &  & 	  \\  "_n		
		file write sm "Year FE & Y & Y & Y & Y  \\ "_n
		file write sm "CZ FE & Y & Y & Y & Y \\ "_n	
		file write sm "CZ Controls & N  & N & N & N    \\  "_n
		file write sm "Weight & Y & Y & Y & Y \\ "_n
		file write sm "Cluster SE: CZ & Y & Y & Y & Y \\ "_n
		*file write sm "Year x Age Eligible FE & Y & Y & Y & Y & Y & Y & Y \\ "_n
		*file write sm "Year x Locality Eligible FE & Y & Y & Y & Y & Y & Y & Y \\ "_n
		*file write sm "Age x Locality Eligible FE & Y & Y & Y & Y & Y & Y & Y \\ "_n
		file write sm "\bottomrule"_n
		file write sm "\end{tabular}"
		file close sm
		
		*/



/*Shock between 08 and 13*/

*2007
global depvar = "post_s_emp_pop_8_13_07 post_s_emp_pop_15_64_8_13_07 post_s_emp_w_pop_8_13_07 post_s_emp_w_pop_15_64_8_13_07"
foreach shock in $depvar {
	reghdfe laamr `shock' [pw=pop06], a(year cz) vce(cluster cz)
}

*2008
global depvar = "post_s_emp_pop_8_13_08 post_s_emp_pop_15_64_8_13_08 post_s_emp_w_pop_8_13_08 post_s_emp_w_pop_15_64_8_13_08"
foreach shock in $depvar {
	reghdfe laamr `shock' [pw=pop06], a(year cz) vce(cluster cz)
}

*2009
global depvar = "post_s_emp_pop_8_13_09 post_s_emp_pop_15_64_8_13_09 post_s_emp_w_pop_8_13_09 post_s_emp_w_pop_15_64_8_13_09"
foreach shock in $depvar {
	reghdfe laamr `shock' [pw=pop06], a(year cz) vce(cluster cz)
}



			cap file close sm
		file open sm using "$output/tables/10yr/T1_2007.tex", write replace 
		file write sm "\begin{tabular}{lccccccc} \hline \hline"_n
		file write sm "& & & & \multicolumn{4}{c}{By Disease Status} \\ "_n
		file write sm " \cmidrule(lr){5-8}"_n
		file write sm "&  & \multicolumn{2}{c}{By Sex}  & \multicolumn{2}{c}{CVD} & \multicolumn{2}{c}{non-CVD} \\ "_n
		file write sm " \cmidrule(lr){3-4} \cmidrule(lr){5-6}\cmidrule(lr){7-8} "_n
		file write sm "& \multicolumn{1}{c}{Pooled} & \multicolumn{1}{c}{Females} & \multicolumn{1}{c}{Males} & \multicolumn{1}{c}{Females} & \multicolumn{1}{c}{Males} & \multicolumn{1}{c}{Females} & \multicolumn{1}{c}{Males} \\ "_n
		file write sm "\cmidrule(lr){2-2}\cmidrule(lr){3-3}\cmidrule(lr){4-4} \cmidrule(lr){5-5}\cmidrule(lr){6-6}\cmidrule(lr){7-7} \cmidrule(lr){8-8} "_n
		file write sm "& (1) & (2) & (3) & (4) & (5) & (6) & (7)  \\  \toprule"_n
		file write sm " \textit{After 70 y Más} & `Poi1'  & `Poi2' & `Poi3' & `Poi4'  & `Poi5' & `Poi6' & `Poi7' \\  "_n
		file write sm "  & (`SE1')  & (`SE2') & (`SE3') & (`SE4')  & (`SE5') & (`SE6') & (`SE7') \\ "_n		
		file write sm "  &  &   &  &  &   &  &  &          \\ "_n
		file write sm " No. Deaths & `tot_y_d1'  & `tot_y_d2' & `tot_y_d3' & `tot_y_d4'  & `tot_y_d5' & `tot_y_d6' & `tot_y_d7'   \\  "_n
		file write sm " No. Deaths Eligibles & `tot_y_cov_1'  & `tot_y_cov_2' & `tot_y_cov_3' & `tot_y_cov_4'  & `tot_y_cov_5' & `tot_y_cov_6' & `tot_y_cov_7'  \\  "_n
		file write sm " No. Deaths Ineligibles & `tot_y_ncov1'  & `tot_y_ncov2' & `tot_y_ncov3' & `tot_y_ncov4'  & `tot_y_ncov5' & `tot_y_ncov6' & `tot_y_ncov7'  \\  "_n
		file write sm " No. Deaths Eligibles   & `tot_y_cov1'  & `tot_y_cov2' & `tot_y_cov3' & `tot_y_cov4'  & `tot_y_cov5' & `tot_y_cov6' & `tot_y_cov7'  \\  "_n
		file write sm "  (year before coverage) &   \\ \\ "_n
		file write sm " No. Localities & `nloc1'  & `nloc2' & `nloc3' & `nloc4'  & `nloc5' & `nloc6' & `nloc7'  \\ \\  "_n
		file write sm " No. Locality-Age cells (obs.) & `NO1'  & `NO2' & `NO3' & `NO4'  & `NO5' & `NO6' & `NO7' \\  "_n
		file write sm " No. Locality-Age Eligible cells (obs.) & `n_cell_el1'  & `n_cell_el2' & `n_cell_el3' & `n_cell_el4'  & `n_cell_el5' & `n_cell_el6' & `n_cell_el7' \\  "_n
		file write sm " No. Locality-Age Ineligible cells (obs.) & `n_cell_inel1'  & `n_cell_inel2' & `n_cell_inel3' & `n_cell_inel4'  & `n_cell_inel5' & `n_cell_inel6' & `n_cell_inel7'  \\  "_n
		file write sm " No. Locality-Age non-zero cells (obs.) & `NO_non_0_el1'  & `NO_non_0_el2' & `NO_non_0_el3' & `NO_non_0_el4'  & `NO_non_0_el5' & `NO_non_0_el6' & `NO_non_0_el7'  \\  "_n
		file write sm " &  &  & &  &  &   	  \\  "_n		
		file write sm " Locality Controls & Y  & Y & Y & Y  & Y & Y & Y  \\  "_n
		file write sm " Year FE & Y & Y & Y & Y & Y & Y & Y  \\ "_n
		file write sm " Locality FE & Y & Y & Y & Y & Y & Y & Y  \\ "_n
		file write sm " Age FE & Y & Y & Y & Y & Y & Y & Y  \\ "_n
		file write sm " Year x Age Eligible FE & Y & Y & Y & Y & Y & Y & Y \\ "_n
		file write sm " Year x Locality Eligible FE & Y & Y & Y & Y & Y & Y & Y \\ "_n
		file write sm " Age x Locality Eligible FE & Y & Y & Y & Y & Y & Y & Y \\ "_n
		file write sm "\bottomrule"_n
		file write sm "\end{tabular}"
		file close sm

/*************************
******Event Studies******
*************************/

*1. shock of employment (with wages) over pop between 2003 and 2008
*We will study event studies for those results that are significant

*2007
set showomitted off
global depvar = "shock_emp_w_pop_03_08 shock_emp_w_pop_15_64_03_08"
foreach shock in $depvar {
	reghdfe laamr c.`shock'##ib2006.year [pw=pop06], a(year cz) vce(cluster cz)
}

*2008

foreach shock in $depvar {
	reghdfe laamr c.`shock'##ib2007.year [pw=pop06], a(year cz) vce(cluster cz)
}

*2009

foreach shock in $depvar {
	reghdfe laamr c.`shock'##ib2008.year [pw=pop06], a(year cz) vce(cluster cz)
}

*2. shock between 2008 and 2013

*2008

foreach shock in $depvar {
	reghdfe laamr c.`shock'##ib2007.year [pw=pop06], a(year cz) vce(cluster cz)
}

*2009

foreach shock in $depvar {
	reghdfe laamr c.`shock'##ib2008.year [pw=pop06], a(year cz) vce(cluster cz)
}
	





