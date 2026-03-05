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


global years = "98 99 00 01 02 03 04 05 06 07 08 09 10 11 12 13 14 15"
foreach year in $years  {
    
	use "$deaths/stata/defun`year'.dta", clear

	* ocupacion also could work (changes in time)
	* escolaridad could be a good control (changes in time)

*I include the following variables available from the vital statistics data: 


		/* escolaridad 
		1 Sin escolaridad
		2 Menos de tres años de primaria
		3 De 3 a 5 años de primaria
		4 Primaria completa
		5 Secundaria o equivalente
		6 Preparatoria o equivalente
		7 Profesional
		8 No aplica a menores de 6 años
		9 No especificada*/

	*Recode variables to numeric values from string values
	destring ent_resid, replace
	destring mun_resid, replace
	
	*age at death in years
	g age_at_death = 0*(edad < 4000) + int(edad - 4000) * (edad > 4000)
	replace age_at_death =. if age_at_death == 998
	g mexican = (nacionalid == 1)
	replace mexican = . if mexican == 9
	g female = (sexo == 2)
	replace female = . if sexo == 9
	drop if female == .
	
	ren (ent_resid mun_resid anio_ocur mes_ocurr dia_ocurr anio_regis mes_regis ///
	anio_nacim mes_nacim causa_def) (cve_ent cve_mun yod mod dod yor mor yob mob icd10)
	
	*ever married
	g married = (edo_civil == 2) if yod <= 2003
	replace married = (edo_civil == 5) if inrange(yod, 2004, 2015)
	replace married = . if edo_civil == 9 
	g ever_married = inrange(edo_civil, 2, 6) if yod <= 2003
	replace ever_married = inrange(edo_civil, 2, 5) if inrange(yod, 2004, 2015)
	replace ever_married = . if edo_civil == 9	
	drop if yod == 9999
	keep if yod >= 1998
	* the lag time between the date the death occurred and the date the death was registered, 
	g date_ocurr = mdy(mod, dod, yod)
	*g date_reg = mdy(mor, dor, yor)
	*g lag_reg = date_reg - date_ocurr
	* whether the deceased was receiving assistance from a medical professional at the time 
	g med_assist = (asist_medi == 1)
	* the location of the death (home or medical facility), 
	g home_hosp = (inlist(sitio_ocur, 1, 2, 3))
	g hosp = (inlist(sitio_ocur, 1, 2))
* the type of doctor who signed the death
	g medic_cert = (inlist(cond_cert, 1,2,3))
* whether the deceased was enrolled in Seguro Popular.
	g sp = (derechohab == 7)

	keep cve_ent cve_mun female yod yob age_at_death mexican yod yob mob ///
	ever_married married icd10 derechohab medic_cert date_ocurr lista_mex mod  
	*sp hosp home_hosp med_assist

	
/*
*for 2003, and before, there are other combinations between IMSS/ISSTE/PEMEX
1 Ninguna
2 IMSS
3 ISSSTE
4 PEMEX
5 SEDENA
6 SEMAR
7 Seguro Popular
8 Otra
9 IMSS oportunidades (2013)
99 No especificado
*/

	g ss = 1 - (derechohab == 1)
	*seguro popular is only health insurance, not retirement benefits
	*I assume that other has health insurance*
	*What about IMSS (Oportunidades?) should I exclude them?
	replace ss = 0 if derechohab == 7
	replace ss = . if derechohab == 99
		
	save "$data/deaths/temp/d`year'", replace

}

use "$data/deaths/temp/d98", clear

foreach year in $years {
	append using "$data/deaths/temp/d`year'"
}


*ICD

{ 
g icd_l = substr(icd10, 1, 1)
g icd_n = substr(icd10, 2, 2)
destring(icd_n), replace force
g icd_cause = .

*(1) Infectious diseases (certain infectious and parasitic diseases, A00-B99);
replace icd_cause = 1 if inlist(icd_l, "A", "B")
*(2) Neoplasm (C00-D48)
replace icd_cause = 2 if ((icd_l == "C") | (icd_l == "D" & icd_n <= 48))
*(3) Diseases of the circulatory system (I00-I99); 
replace icd_cause = 3 if (icd_l == "I")
*(4) Mental disorders (F00-F99);
replace icd_cause = 4 if (icd_l == "F")
*(5) Endocrine, nutritional and metabolic disorders (E00-E88);
replace icd_cause = 5 if (icd_l == "E" & icd_n <= 88)
*(6) Diseases of the digestive system (K00-K93); 
replace icd_cause = 6 if (icd_l == "K" & icd_n <= 93)
*(7) Certain conditions originating in the perinatal period (P00-P96); 
replace icd_cause = 7 if (icd_l == "P" & icd_n <= 96)
*(8) Homicides (X85-Y09);
replace icd_cause = 8 if ((icd_l == "X" & icd_n>=85) | (icd_l == "Y" & icd_n <= 9))
*(9) Other external causes (V01-X84,Y10-Y89) 
replace icd_cause = 9 if ((icd_l == "V" & inrange(icd_n, 1, 84)) | (icd_l == "Y" & inrange(icd_n, 10, 89)))
*(10) a group of `other causes' not accounted for in the previous nine cause groupings.
replace icd_cause = 10 if icd_cause == .
			
g death = 1

/*ICD 10 classifcation*/
*(1) Infectious diseases (certain infectious and parasitic diseases, A00-B99);
gen death_infec= (icd_cause==1) * death
label var death_infec "Infectious Disease"
			
*(2) Neoplasm (C00-D48)
gen death_neoplasm=(icd_cause==2) * death
label var death_neoplasm "Neoplasms"
			
*(3) Diseases of the circulatory system (I00-I99); 
gen death_cvd = (icd_cause==3) * death
label var death_cvd "Circulatory"
		
*(4) Mental disorders (F00-F99);
gen death_mental=(icd_cause==4) * death
label var death_mental "Mental Disorders"
		
*(5) Endocrine, nutritional and metabolic disorders (E00-E88);
gen death_nutri =(icd_cause==5) * death
label var death_nutri  "Endocrine, Nutritional and Metabolic"
		
*(6) Diseases of the digestive system (K00-K93); 
gen death_digest=(icd_cause==6) * death
label var death_digest "Digestive"
	
*(7) Certain conditions originating in the perinatal period (P00-P96); 
gen death_peri=(icd_cause==7) * death
label var death_peri "Perinatal"
*(8) Homicides (X85-Y09);

gen death_homicide=(icd_cause==8) * death
label var death_homicide "Violence"
	
*(9) Other external causes (V01-X84,Y10-Y89) 
			
gen death_others=(icd_cause==9) * death
label var death_others "Others"

*(10) a group of `other causes' not accounted for in the previous nine cause groupings.
}

*deaths (heterogeneity)
{
	g death_non_cvd = (icd_cause !=3) * death
	g death_non_nutri = (icd_cause !=5) * death
	g death_cvd_nutri = (inlist(icd_cause, 3, 5)) * death
	g death_non_cvd_nutri = (!inlist(icd_cause, 3, 5)) * death

	g death_female = death * female
	g death_male = death * (1-female)

	g death_unmarried = death * (1-married)

	g death_unmarried_f = death_unmarried * death_female
	g death_unmarried_m = death_unmarried * death_male

	g death_married = death * married

	g death_married_f = death_married * death_female
	g death_married_m = death_married * death_male

	g death_i = death * ss
	replace death_i = 0 if death_i == .


	g death_sp = death * (derechohab == 7) 

	g death_i_sp = death_i + death_sp
	g death_ui = death * (1-ss) * (derechohab != 7) 
	replace death_ui = 0 if death_ui == .

	g death_ui_sp = death_ui + death_sp

	g death_ui_sp_f = (death_ui + death_sp) * death_female
	g death_ui_sp_m = (death_ui + death_sp) * death_male

	g death_cvd_f  = death * death_cvd * death_female
	g death_non_cvd_f  = death * death_non_cvd * death_female

	g death_cvd_m  = death * death_cvd * death_male
	g death_non_cvd_m  = death * death_non_cvd * death_male
}

{
g age_gr = 0 * inrange(age_at_death, 0, 4) + ///
           5 * inrange(age_at_death, 5, 9) + ///
		   10 * inrange(age_at_death, 10, 14) + ///
		   15 * inrange(age_at_death, 15, 19) + ///
		   20 * inrange(age_at_death, 20, 14) + ///
		   25 * inrange(age_at_death, 25, 29) + ///
		   30 * inrange(age_at_death, 30, 34) + ///
		   35 * inrange(age_at_death, 35, 39) + ///
		   40 * inrange(age_at_death, 40, 44) + ///
		   45 * inrange(age_at_death, 45, 49) + ///
		   50 * inrange(age_at_death, 50, 54) + ///
		   55 * inrange(age_at_death, 55, 59) + ///
		   60 * inrange(age_at_death, 60, 64) + ///
		   65 * inrange(age_at_death, 65, 69) + ///
		   70 * inrange(age_at_death, 70, 74) + ///
		   75 * inrange(age_at_death, 75, 79) + ///
		   80 * inrange(age_at_death, 80, 84) + ///
		   85 * inrange(age_at_death, 85, 130)
	
	
tostring(cve_ent cve_mun), replace
replace cve_ent = "" if cve_ent == "."
replace cve_mun = "" if cve_mun == "."
replace cve_ent = "0" + cve_ent if length(cve_ent) == 1
replace cve_mun = "0" + cve_mun if length(cve_mun) == 2
replace cve_mun = "00" + cve_mun if length(cve_mun) == 1

egen municipality = concat(cve_ent cve_mun)
destring(municipality), g(muni) force


collapse (sum) deaths = death ///
			   deaths_cvd = death_cvd ///
			   deaths_non_cvd = death_non_cvd ///
			   deaths_nutri = death_nutri ///
			   deaths_non_nutri = death_non_nutri ///
			   deaths_ui_sp = death_ui_sp ///
			   deaths_sp = death_sp ///
			   deaths_ui = death_ui ///
			   deaths_i = death_i ///
			   deaths_i_sp = death_i_sp ///
			   deaths_cvd_f = death_cvd_f ///
			   deaths_non_cvd_f = death_non_cvd_f ///
			   deaths_cvd_m = death_cvd_m ///
			   deaths_non_cvd_m = death_non_cvd_m ///
			   deaths_female=death_female ///
			   deaths_male=death_male ///
			   deaths_ui_sp_f=death_ui_sp_f ///
			   deaths_ui_sp_m=death_ui_sp_m ///
			   deaths_infec = death_infec ///
			   deaths_neoplasm = death_neoplasm ///
			   deaths_mental = death_mental ///
			   deaths_digest = death_digest ///
			   deaths_peri = death_peri ///
			   deaths_homicide = death_homicide ///
			   deaths_others = death_others ///
			   deaths_unmarried = death_unmarried ///
			   deaths_unmarried_f = death_unmarried_f ///
			   deaths_unmarried_m = death_unmarried_m ///
			   deaths_married = death_married ///
			   deaths_married_f = death_married_f ///
			   deaths_married_m = death_married_m, ///
by(cve_ent cve_mun muni yod age_gr)
ren (age_gr yod) (age_at_death year)

save "$data/deaths/deaths_98_15_clean", replace
}

*Mortality +Shock dataset 
{
use "$data/deaths/deaths_98_15_clean", clear

merge 1:1 year age_at_death muni using "$data/population/pop_5yr_muni.dta", keep(3) nogen
*_==1 there a less than 0,3% of deaths without municipality population.
destring(cve_ent cve_mun), replace

merge m:1 year muni using "$data/economic_census/econ_census_cz.dta"
drop if year > 2015
drop if _==2
*economic census data available for three years sampled
g aux = (_==1 & inlist(year, 2003, 2008, 2013))
bys muni: egen muni_index = max(aux)
drop if muni_index == 1
drop _merge aux muni_index
*I will do BANXICO CZ
bys muni: egen cz = min(cz_banxico)

collapse (sum) deaths* pop* firms emp_tot emp_tot_male emp_tot_female hours_tot ///
emp_w_tot emp_w_male emp_w_female hours_w_tot w_tot severance bonuses ///
, by(year age_at_death cz)

*Age Adjuste Mortality Rate (AAMR) using the 2000 age structure
*proportion of 5 year age group of people in 2000
g pop_w_00 = pop/pop_tot if year == 2000
g pop_w_f_00 = pop_f/pop_tot_f if year == 2000
g pop_w_m_00 = pop_m/pop_tot_m if year == 2000

bys cz: egen pop_w = min(pop_w_00)
bys cz: egen pop_w_f = min(pop_w_f_00)
bys cz: egen pop_w_m = min(pop_w_m_00)

*aamr = asdr * proportion_2000
g aamr = (deaths/pop) * pop_w
g aamr_f = (deaths_female/pop_f) * pop_w_f
g aamr_m = (deaths_male/pop_m) * pop_w_m

*age-adjusted cause specific death rate
global disaese = "cvd nutri infec neoplasm mental digest peri homicide others"

foreach dis in $disease {
	g aamr_`dis' = (deaths_`dis'/pop) * pop_w
}
	
g aamr_non_cvd = (deaths_non_cvd/pop) * pop_w

g aamr_cvd_f = (deaths_cvd_f/pop_f) * pop_w_f
g aamr_non_cvd_f = (deaths_non_cvd_f/pop_f) * pop_w_f

g aamr_cvd_m = (deaths_cvd_m/pop_m) * pop_w_m
g aamr_non_cvd_m = (deaths_non_cvd_m/pop_m) * pop_w_m


*age specific death rates
ren (pop_m pop_f deaths_cvd_f deaths_non_cvd_f deaths_cvd_m deaths_non_cvd_m) ///
    (pop_male pop_female d_cvd_female d_non_cvd_female d_cvd_male d_non_cvd_male)

global vars = "deaths deaths_female deaths_male deaths_cvd deaths_non_cvd deaths_nutri d_cvd_female d_non_cvd_female d_cvd_male d_non_cvd_male deaths_infec deaths_neoplasm deaths_mental deaths_digest deaths_peri deaths_homicide deaths_others pop_male pop_female pop"

*age specific counts on deaths and pop
*no need of standardized given the already standardized measure above, instead we look at specific age_groups
foreach var in $vars {

	*asdr 0 - 14	
	bys cz year: egen `var'_0_14_aux = sum(`var') if inrange(age_at_death, 0, 14) 
	bys cz year: egen `var'_0_14 = min(`var'_0_14_aux) 
	*asdr 15 - 49
	bys cz year: egen `var'_15_49_aux = sum(`var') if inrange(age_at_death, 15, 49) 
	bys cz year: egen `var'_15_49 = min(`var'_15_49_aux) 

	*asdr 15 - 64
	bys cz year: egen `var'_15_64_aux = sum(`var') if inrange(age_at_death, 15, 64) 
	bys cz year: egen `var'_15_64 = min(`var'_15_64_aux) 

	*asdr 50 - 69
	bys cz year: egen `var'_50_69_aux = sum(`var') if inrange(age_at_death, 50, 69) 
	bys cz year: egen `var'_50_69 = min(`var'_50_69_aux) 

	*asdr 70+
	bys cz year: egen `var'_70_aux = sum(`var') if age_at_death >= 70
	bys cz year: egen `var'_70 = min(`var'_70_aux) 
	
	
}


g asdr_0_14 = deaths_0_14/pop_0_14
g asdr_15_49 = deaths_15_49/pop_15_49
g asdr_15_64 = deaths_15_64/pop_15_64
g asdr_50_69 = deaths_50_69/pop_50_69
g asdr_70 = deaths_70/pop_70


*age-specific death rates by sex
global sex = "female male"
foreach sex in $sex {
	g asdr_`sex'_0_14 = deaths_`sex'_0_14/pop_`sex'_0_14
	g asdr_`sex'_15_49 = deaths_`sex'_15_49 /pop_`sex'_15_49 
	g asdr_`sex'_15_64 = deaths_`sex'_15_64 /pop_`sex'_15_64 
	g asdr_`sex'_50_69 = deaths_`sex'_50_69/pop_`sex'_50_69 
	g asdr_`sex'_70 = deaths_`sex'_70/pop_`sex'_70 
	
	g asdr_cvd_`sex'_0_14 = d_cvd_`sex'_0_14/pop_`sex'_0_14
	g asdr_cvd_`sex'_15_49 = d_cvd_`sex'_15_49 /pop_`sex'_15_49 
	g asdr_cvd_`sex'_15_64 = d_cvd_`sex'_15_64 /pop_`sex'_15_64 
	g asdr_cvd_`sex'_50_69 = d_cvd_`sex'_50_69/pop_`sex'_50_69 
	g asdr_cvd_`sex'_70 = d_cvd_`sex'_70/pop_`sex'_70 
	
	g asdr_non_cvd_`sex'_0_14 = d_non_cvd_`sex'_0_14/pop_`sex'_0_14
	g asdr_non_cvd_`sex'_15_49 = d_non_cvd_`sex'_15_49 /pop_`sex'_15_49 
	g asdr_non_cvd_`sex'_15_64 = d_non_cvd_`sex'_15_64 /pop_`sex'_15_64 
	g asdr_non_cvd_`sex'_50_69 = d_non_cvd_`sex'_50_69/pop_`sex'_50_69 
	g asdr_non_cvd_`sex'_70 = d_non_cvd_`sex'_70/pop_`sex'_70 
	

}


*by disases
global disaese = "cvd nutri infec neoplasm mental digest peri homicide others"

foreach var in $dis {
	
	g asdr_`dis'_0_14 = deaths_`dis'_0_14/pop_0_14
	g asdr_`dis'_15_49 = deaths_`dis'_15_49/pop_15_49
	g asdr_`dis'_15_64 = deaths_`dis'_15_64/pop_15_64
	g asdr_`dis'_50_69 = deaths_`dis'_50_69/pop_50_69
	g asdr_`dis'_70 = deaths_`dis'_70/pop_70
	
	}


collapse (sum) deaths deaths_sp deaths_ui deaths_i deaths_married deaths_unmarried ///
pop pop_male pop_female ///
(mean) pop_0_14 pop_15_49 pop_15_64 pop_50_69 pop_70 pop_female_0_14 ///
pop_female_15_49 pop_female_15_64 pop_female_50_69 pop_female_70 pop_male_0_14 ///
pop_male_15_49 pop_male_15_64 pop_male_50_69 pop_male_70 asdr* aamr* ///
firms emp_tot emp_tot_male emp_tot_female hours_tot emp_w_tot emp_w_male ///
emp_w_female hours_w_tot w_tot severance bonuses ///
, by(year cz)

bys cz (year): g aux = _n
bys cz: egen cz_index = max(aux)
keep if cz_index == 18
drop aux cz_index
*0.1% of the CZ doesn't have deaths in at least 1 period. 

*employment to population variables
g emp_pop = emp_tot/pop 
g emp_w_pop = emp_w_tot/pop 
g emp_pop_15_64 = emp_tot/pop_15_64
g emp_w_pop_15_64 = emp_w_tot/pop_15_64 


g emp_pop_f = emp_tot_female/pop_female 
g emp_w_pop_f = emp_w_female/pop_female 
g emp_pop_f_15_64 = emp_tot_female/pop_female_15_64
g emp_w_pop_f_15_64 = emp_w_female/pop_female_15_64 

g emp_pop_m = emp_tot_male/pop_male 
g emp_w_pop_m = emp_w_male/pop_male 
g emp_pop_m_15_64 = emp_tot_male/pop_male_15_64
g emp_w_pop_m_15_64 = emp_w_male/pop_male_15_64 

*table year, stat(sum emp_tot deaths pop pop_female pop_male)

global years = "2003 2008 2013"

global ratios = "emp_pop emp_w_pop emp_pop_15_64 emp_w_pop_15_64 emp_pop_f emp_w_pop_f emp_pop_f_15_64 emp_w_pop_f_15_64 emp_pop_m emp_w_pop_m emp_pop_m_15_64 emp_w_pop_m_15_64"

foreach year in $years {
	foreach var in $ratios {
		g `var'_`year'_aux = `var' if year == `year'
		bys cz: egen `var'_`year' = min(`var'_`year'_aux) 
	}
	
}

foreach var in $ratios {
	g shock_`var'_03_08 = (`var'_2008 - `var'_2003)*100
	g shock_`var'_03_13 = (`var'_2013 - `var'_2003)*100
	g shock_`var'_08_13 = (`var'_2013 - `var'_2008)*100

}

save "$data/deaths/mortality_shock_data.dta", replace
}

(mean) pop00 pop05 pop10 pob_tot iml medic_cert lag_reg ///
		sp pg_int_pob analf sprim  vsaguae vsee vpisot poch2sm vsdye vhac gm_2005 iml2005

			
*adding population CONAPO
merge m:1 locality yod using "$data/locality_im_interpolated_2000_2011"

drop if _==2
ren _merge _conapo
*CONTEO / ITER DATA
merge m:1 locality using "$data/population/iter_00_05_10.dta" , keepus(locality pop00 pop05 pop10)
destring(pop00 pop05 pop10), replace
drop if _merge == 2


merge m:1 cve_ent cve_mun  yod using "$data/sp_muni_indicator"
drop if _merge==2
replace sp = 0 if _merge==1
drop _merge
merge m:1 cve_ent cve_mun yod using "$data/sp_pg_benef"
drop if _merge==2
drop _merge
**There are localitites that I am not able to identify because they are confidential
*in the death records. LOC = 7777
*I have to check what about SP and PG intensity
g pg_int_pob = pgbenef/pob_tot
replace pg_int_pob = 0 if pg_int_pob == .
*206 localities with intensity above 1
destring(cve_ent cve_mun cve_loc), replace
compress		


			

merge m:1 locality using "$data/change_localities"
ta yod _merge
	drop if _==2 // This localities that change are not in my dataset
	distinct locality if _merge==3
	drop if _==3 // this people died in localities that changed (1429)

drop _merge
			
compress
save "$data/deaths_00_15_clean", replace 
***


use "$data/deaths_02_15_clean", clear
*keep if inrange(age_at_death, 65, 84)
keep if inrange(yod, 2002, 2011)

compress
save "$data/deaths_02_15_panel", replace

use "$data/deaths_02_15_panel", clear 

keep if inrange(yod, 2002, 2015)

ren cve_ent state
	
g cve_ent_mun = int(locality/10000)
*There are localitites that I am not able to identify because they are confidential
*in the death records. LOC = 7777
merge m:1 locality yod using "$data/health_data_loc", keep(1 3)
ren _merge _m_loc

global health_var = "tothosp totmobclinic tothealthbrig totmedres totdoctor totnurse"
foreach var in $health_var {
	replace `var'_loc = 0 if _m_loc == 1
}


merge m:1 yod age_at_death covered using "$data/population_2000_2010_eligibility_age_interpolated", ///
keep(3) nogen keepus(pop_exp)

*** Labeling
	lab var analf "% illiterate population"
	lab var sprim "% with primary education"
	lab var vsaguae "% without potable/running water"
	lab var vsdye "% without sweage nor toilette"
	lab var vsee "% without electricity"
	lab var vpisot "% of houses with dirt floor"
	lab var vhac "% of houses overcrowded"
	lab var poch2sm "% earning less than 2 min wage"
	lab var iml "margination index"
	lab var gm_2005 "margination index level in 2005"
	lab var pop_exp "Population by age, treatment, year (exp interpolated)"
	
compress
save "$data/deaths_02_15_did_panel", replace


