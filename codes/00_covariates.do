clear
set more off
capture log close


if c(username)=="felip" {
    
	global deaths "C:\Users\felip\Dropbox\R01_MHAS\Mortality_VitalStatistics_Project\RawData_Mortality_VitalStatistics\"
	global data "C:\Users\felip\Dropbox\2024\70ymas\data/"
	global output "C:/Users/felip/Dropbox/Aplicaciones/Overleaf/70yMas/"
	global iter "C:\Users\felip\Dropbox\R01_MHAS\Progresa_Locality_Mortality_Project\CensusData_ITER\" 
	global SP "C:\Users\felip\Dropbox\R01_MHAS\SocialProgramBeneficiaries"
}

if c(username)=="fmenares" {
    global deaths "/hdir/0/fmenares/Dropbox/R01_MHAS\Mortality_VitalStatistics_Project\RawData_Mortality_VitalStatistics\"
	global data "/data/Dropbox0/fmenares/Dropbox/2024/70ymas/data/"
	global output  "/hdir/0/fmenares/Dropbox/Aplicaciones/Overleaf/70yMas/"
	global iter "/hdir/0/fmenares/Dropbox/R01_MHAS/Progresa_Locality_Mortality_Project\CensusData_ITER\"
	global SP "/hdir/0/fmenares/Dropbox/R01_MHAS\SocialProgramBeneficiaries"


}

if c(username)=="FELIPEME" {
    global deaths "/hdir/0/fmenares/Dropbox/R01_MHAS\Mortality_VitalStatistics_Project\RawData_Mortality_VitalStatistics\"
	global data "C:/Users/FELIPEME/OneDrive - Inter-American Development Bank Group/Documents/personal/70ymas/data/"
	global output  "C:\Users\FELIPEME\OneDrive - Inter-American Development Bank Group\Documents\personal\70ymas\"
	global iter "/hdir/0/fmenares/Dropbox/R01_MHAS/Progresa_Locality_Mortality_Project\CensusData_ITER\"
	global SP "/hdir/0/fmenares/Dropbox/R01_MHAS\SocialProgramBeneficiaries"


}

*\Users\felip\Dropbox\R01_MHAS"


/***********************************
1. Municipalities that change its composition between 2000 and 2015
************************************/
{

import delimited using "$data/mun_changes/AGEEML_202510211155505", clear
gen year =  substr(fecha_act,1,4)
destring(year), replace
/*
M: new 55
P: destroyed 8
W: change of name 56
*/
*I kept only those that affects the composition of the pop
*in the period of study: M and P
keep if inlist(cgo_act, "M", "P")
ta year
destring(cve_ent_ori), replace force
destring(cve_ent_act), replace force
drop if cve_ent_ori == .
drop if cve_ent_act == .
ren (cve_ent_ori cve_mun_ori) (cve_ent cve_mun)

tostring(cve_ent cve_mun), replace
replace cve_ent = "" if cve_ent == "."
replace cve_mun = "" if cve_mun == "."
replace cve_ent = "0" + cve_ent if length(cve_ent) == 1
replace cve_mun = "0" + cve_mun if length(cve_mun) == 2
replace cve_mun = "00" + cve_mun if length(cve_mun) == 1
egen municipality = concat(cve_ent cve_mun)
destring(municipality), g(mun) force
drop nom_*
duplicates drop
save "$data/mun_changes/change_mun", replace
}


/***********************************************************
2. MARGINATION INDEX 
*************************************************************/
{
*CHECK IM
import delimited "$data\marginality_index\Base_Indice_de_marginacion_municipal_90-15.csv", clear
*recovering cve_mun and cve_loc

drop ent mun
g year=año
keep if year >= 2000

ren cve_mun municipality
destring(municipality), g(mun) force

merge m:1 mun year using "$data/mun_changes/change_mun"
*keeping only those muni that does not change
keep if _merge==1
drop _merge
destring(pob_tot analf sprim ovsde ovsee ovsae vhac ovpt po2sm  im ovsdse), replace force
replace ovsde = ovsdse if ovsde == .
*tot_viv is a string because it has asterik for those below a certain number
*gm, check.
count if im == .
count if pob_tot == .

keep mun year pob_tot analf sprim ovsde ovsee ovsae vhac ovpt po2sm  im gm

label def gm_lbl 1 "Very Low" 2 "Low" 3 "Medium" 4 "High" 5 "Very High", replace
encode gm, g(gm_2)
recode gm_2 (1=4) (5=1) (4=5)
drop gm 
ren gm_2 gm

global vars = "im gm pob_tot analf sprim  ovsde ovsee ovsae vhac ovpt po2sm"

foreach var in $vars {
	bys mun (year): replace `var' = `var'[_n+5] if `var' == . & year == 2000
	bys mun (year): replace `var' = `var'[_n-5] if `var' == . & year == 2010
}

preserve
drop gm
	reshape wide im pob_tot analf sprim ovsde ovsee ovsae vhac ovpt po2sm, ///
	i(mun) j(year)
	sort mun
	tempfile wide_im_2000_2015
	save `wide_im_2000_2015'
restore

merge m:1 mun using `wide_im_2000_2015'

drop _
sort mun year
order mun year

** Ipolate variables with data in all quinquenal years from 2000 onwards

foreach var in $vars  {
		by mun: ipolate `var' year, g(`var'_ip)
		replace `var' = `var'_ip if `var' ==.
	}


bys mun: g gm2005 = gm if year == 2005
bys mun: egen gm_2005 = min(gm2005)
drop gm2005

ren (gm_2005) (gm2005)
sort mun year
ren year yod

keep mun yod pob_tot analf sprim ovsde ovsee ovsae vhac ovpt po2sm gm2005 im im2005 pob_tot2005

label val gm2005 gm_lbl

save "$data/marginality_index/mun_im_interpolated_2000_2015", replace


}
/************************************************************
***1.1 PROGRESA (CCT)**
*************************************************************/
use "$data/social_programs/progresa/fams_fase_20134xloc_f.dta", clear

ren (CVE_EDO CVE_MUN CVE_LOC anio) (cve_ent cve_mun cve_loc year)
sort cve_ent cve_mun cve_loc year
*DEFINE PROGRESA BENEFICIARY IN EACH YEAR BASED ON FASES
egen pgbenef1997_old=rowtotal(FASE_1-FASE_2)
egen pgbenef1998_old=rowtotal(FASE_3-FASE_6)
egen pgbenef1999_old=rowtotal(FASE_7-FASE_10)
egen pgbenef2000_old=rowtotal(FASE_11-FASE_12)
egen pgbenef2001_old=rowtotal(FASE_13-FASE_15)
egen pgbenef2002_old=rowtotal(FASE_16-FASE_17)
egen pgbenef2003_old=rowtotal(FASE_18-FASE_19)
egen pgbenef2004_old=rowtotal(FASE_20-FASE_23)
egen pgbenef2005_old=rowtotal(FASE_24-FASE_25)
egen pgbenef2006_old=rowtotal(FASE_26-FASE_28)
egen pgbenef2007_old=rowtotal(FASE_29-FASE_32)
egen pgbenef2008_old=rowtotal(FASE_33-FASE_35)
egen pgbenef2009_old=rowtotal(FASE_38-FASE_39)
egen pgbenef2010_old=rowtotal(FASE_40-FASE_42)
egen pgbenef2011_old=rowtotal(FASE_44-FASE_47)
egen pgbenef2012_old=rowtotal(FASE_48-FASE_50)
*note 2013 does not include all bimesters*
egen pgbenef2013_old=rowtotal(FASE_55-FASE_59)
sort cve_ent cve_mun cve_loc
keep cve_ent cve_mun cve_loc pgbenef*
tempfile pg_benef_old
save `pg_benef_old' 

use "$data/social_programs/progresa/newProg_98_16.dta", clear
ren (CVE_EDO CVE_MUN CVE_LOC fams) (cve_ent cve_mun cve_loc pgbenef)
keep cve_ent cve_mun cve_loc year pgbenef
reshape wide pgbenef, i(cve_ent cve_mun cve_loc) j(year)
ren cve_ent cve_edo
*For year 2016 we have to update the beneficiares, because they include 
*with and without corresponsability. Previously, benefits were only those with
*corresposnability. This is the scheme whhen all progresa components work altogether
drop pgbenef2016 
forv i=1998/2015 {
ren pgbenef`i' pgbenef`i'_new
}

ren cve_edo cve_ent
keep cve_ent cve_mun cve_loc pgbenef*
sort cve_ent cve_mun cve_loc
merge 1:1 cve_ent cve_mun cve_loc using `pg_benef_old', nogen
tostring(cve_ent cve_mun), replace
replace cve_ent = "0" + cve_ent if length(cve_ent) == 1
replace cve_mun = "0" + cve_mun if length(cve_mun) == 2
replace cve_mun = "00" + cve_mun if length(cve_mun) == 1
drop pgbenef*_old
ren (pgbenef*_new) (pgbenef*)
reshape long pgbenef, i(cve_ent cve_mun cve_loc) j(yod)
collapse (sum) pgbenef, by(cve_ent cve_mun yod)
compress

tempfile benef_pg_int_mun
save `benef_pg_int_mun' , replace
/****************************
1.2 SEGURO POPULAR DATA FILE (PHI) - 2001-2018
***************************/
use "$data/social_programs/seguro_popular/Seguro_Popular_2001-2018.dta", clear
drop name_edo name_mun _m cve_edo_mun_2 cve_edo cve_mun 
ren (cve_edo_mun) (cve_ent_mun)
g cve_ent = substr(cve_ent_mun,1,2)
g cve_mun = substr(cve_ent_mun, 3,3)
drop if cve_ent=="" | cve_mun==""
sort cve_ent cve_mun
sort cve_ent cve_mun
reshape long spbenef, i(cve_ent cve_mun) j(yod)
keep if yod <=2015
merge 1:m cve_ent cve_mun yod using `benef_pg_int_mun'
g sp = (spbenef != 0 & spbenef!=.)
drop _ cve_ent_mun
tempfile sp_pg_benef_mun
save `sp_pg_benef_mun', replace

/*********************************
1.3 ***70YMAS DATA FILE (UCT)*** 2007-2018 
SOURCE: SEDESOL
provided by Jorge Peniche
*********************************/
use "$data/social_programs/70ymas/70yMas_benef_2007_2018_loc.dta", clear
ren (sta_code mun_code loc_code code) (cve_ent cve_mun cve_loc locality) 
drop if cve_ent=="" | cve_mun==""
destring locality, replace
keep if year <=2015
ren year yod 
collapse (sum) benef70ym, by(cve_ent cve_mun yod)  
merge 1:m cve_ent cve_mun yod using `sp_pg_benef_mun'
save "$data/sp_pg_70_benef_mun", replace


****************
*Infrastructure data
***********

use "$data/Infraestructure01_14/HealthResources_SecretariaSalud_2001_2020.dta", clear
keep clave_entidad clave_municipio clave_localidad tothosp totmobclinic tothealthbrig totmedres totdoctor totnurse year
tostring(clave_entidad), replace
tostring(clave_municipio), replace

g cve_ent = clave_entidad
replace cve_ent =  "0" + clave_entidad if length(clave_entidad) == 1

g cve_mun = clave_municipio
replace cve_mun = "00" + clave_municipio if length(clave_municipio) == 1
replace cve_mun = "0" + clave_municipio if length(clave_municipio) == 2

collapse (sum) tothosp totmobclinic tothealthbrig totmedres totdoctor totnurse, ///
by(cve_ent cve_mun year)
g cve_ent_mun = cve_ent + cve_mun

order tothosp totmobclinic tothealthbrig totmedres totdoctor totnurse, last
label var tothosp "Hospitals N"
label var totmobclinic "Mobile Clinics N"
label var tothealthbrig "Health Brigades No"
label var totmedres "Medical Residents No"
label var totdoctor "Doctors"
label var totnurse "Nurses"

/***********************************
Population at the municipality level
and 5 year ages groups
*2000-2015
***********************************/
import excel "$data/population/1_Grupo_Quinq_00_RM.xlsx", sheet("Sheet 1") firstrow clear
keep if inrange(AÑO, 2000, 2015)
keep CLAVE SEXO AÑO POB_00_04 POB_05_09 POB_10_14 POB_15_19 POB_20_24 POB_25_29 POB_30_34 POB_35_39 POB_40_44 POB_45_49 POB_50_54 POB_55_59 POB_60_64 POB_65_69 POB_70_74 POB_75_79 POB_80_84 POB_85_mm POB_TOTAL
ren (CLAVE SEXO AÑO POB_00_04 POB_05_09 POB_10_14 POB_15_19 POB_20_24 POB_25_29 POB_30_34 POB_35_39 POB_40_44 POB_45_49 POB_50_54 POB_55_59 POB_60_64 POB_65_69 POB_70_74 POB_75_79 POB_80_84 POB_85_mm POB_TOTAL) ///
     (cve_ent_mun sex year pop0 pop5 pop10 pop15 pop20 pop25 pop30 pop35 pop40 pop45 pop50 pop55 pop60 pop65 pop70 pop75 pop80 pop85 pop_tot)
	 
reshape long pop ,i(cve_ent_mun sex year) j(age_at_death)
g female = (sex == "MUJERES")
drop sex
reshape wide pop pop_tot ,i(cve_ent_mun age_at_death year) j(female)
ren (pop0 pop1 pop_tot0 pop_tot1) (pop_m pop_f pop_tot_m pop_tot_f)
g pop = pop_f + pop_m
g pop_tot = pop_tot_f + pop_tot_m

tostring(cve_ent_mun), replace
gen cve_ent = substr(cve_ent_mun, 1,2) if length(cve_ent_mun) == 5
gen cve_mun = substr(cve_ent_mun, 3,5) if length(cve_ent_mun) == 5
replace cve_ent = substr(cve_ent_mun, 1,1) if length(cve_ent_mun) == 4
replace cve_mun = substr(cve_ent_mun, 2,4) if length(cve_ent_mun) == 4

replace cve_ent = "0" + cve_ent if length(cve_ent) == 1
replace cve_mun = "0" + cve_mun if length(cve_mun) == 2
replace cve_mun = "00" + cve_mun if length(cve_mun) == 1

egen municipality= concat(cve_ent cve_mun)

destring(municipality), g(muni) 
drop cve_ent_mun

compress
save "$data/population/pop_5yr_muni", replace



/************************
INEGI ITER DATA POBTOT
***********************/

*POB TOT FROM ITER
global years = "00 05 10"
foreach year in $years {
	local year = "05"
	use "$data/INEGI/population/ITER_NALDBF`year'", clear
	di `year'
	if (`year'== 05) {
	ren P_TOTAL POBTOT 
	ren (entidad mun loc) (ENTIDAD MUN LOC)
	destring(ENTIDAD), g(cve_ent)
	destring(MUN), g(cve_mun)
	destring(LOC), g(cve_loc)
	destring(POBTOT), g(totpop)
	destring(P_SINDER), g(pop_ui)
	destring(P_DERE), g(pop_i)
	destring(P_SEGPOP), g(pop_sp)
	}
	decode(ENTIDAD), g(cve_ent)
	decode(MUN), g(cve_mun)
	decode(LOC), g(cve_loc)
	decode(POBTOT), g(totpop)
	
	egen locality = concat(cve_ent cve_mun cve_loc)
	destring(locality totpop), replace
	count if cve_loc == "9999"
	*173056
	count if cve_loc == "9998"
	*260087
	drop if cve_ent == "00"
    keep locality cve_ent cve_mun cve_loc totpop
	save "$data/population/iter`year'", replace
}



/***************
HH Interpolate
******************/
*There is HH counts for 1990. So I can interpolate the 1995 value using 1990 and 2000. 
replace HH = . if HH == 0

expand 2 if year == 2020, g(year_1995)
replace year = 1995 if year_1995 == 1
drop year_1995
sort cve_ent_mun_super year
replace HH = . if year == 1995

bys cve_ent_mun_super: ipolate HH year if year <=2000, g(HH_1995)
replace HH = HH_1995 if year == 1995
drop HH_1995

expand 2 if year == 2020, g(year_2015)
replace year = 2015 if year_2015 == 1
drop year_2015
sort cve_ent_mun_super year

foreach var in HH {
replace `var' = . if year == 2015

bys cve_ent_mun_super: ipolate `var' year if ///
inrange(year,2010,2020), g(`var'2015)
replace `var' = `var'2015 if year == 2015
drop `var'20*
}

keep if year >= `year'
*Now I can interpolate all of the in-between years.
	preserve
		reshape wide HH, i(cve_ent_mun_super) j(year)
		sort cve_ent_mun_super
		tempfile wide
		save `wide'
	restore

	destring(cve_ent_mun_super), g(cve_ent_mun_super2)
	tsset cve_ent_mun_super2 year
	tsfill

	sort cve_ent_mun_super2 year
	bys cve_ent_mun_super2: replace cve_ent_mun_super = cve_ent_mun_super[_n-1] ///
	if cve_ent_mun_super == ""
	sort cve_ent_mun_super
	merge m:1 cve_ent_mun_super using `wide'
	drop _
	sort cve_ent_mun_super year
	order cve_ent_mun_super year


*Interpolation 

foreach var2 in HH {
	by cve_ent_mun_super: ipolate `var2' year, g(`var2'_ip)
	replace `var2' = `var2'_ip if `var2' ==.
	}

ta year

keep cve_ent_mun_super year HH

sort cve_ent_mun_super year

*** Labeling
label var HH "HH count (Interpolated)"
	
sort cve_ent_mun_super year
save "$r01/FinalData/HH_Pop/municipality_level/households_mun_ipolate_recoded_`year'.dta", replace
}
}


foreach year in $years {
	local year = "05"
	use "$data/INEGI/population/ITER_NALDBF`year'", clear

	ren P_TOTAL POBTOT 
	ren (entidad mun loc) (cve_ent cve_mun cve_loc)
	
	destring(POBTOT), g(totpop)
	destring(P_SINDER), g(pop_ui) force
	destring(P_DERE), g(pop_i) force
	destring(P_SEGPOP), g(pop_sp) force
	
	egen locality = concat(cve_ent cve_mun cve_loc)
	destring(locality totpop), replace
	count if cve_loc == "9999"
	*173056
	count if cve_loc == "9998"
	*260087
	drop if cve_ent == "00"
    keep locality cve_ent cve_mun cve_loc totpop pop_ui pop_i pop_sp
	save "$data/population/iter`year'", replace
}



