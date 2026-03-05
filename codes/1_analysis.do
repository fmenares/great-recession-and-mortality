
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

*Figure 1
* a) age adjusted mortality rate all, female, male (3 lines)
* b) age specific mortality rate by age-groups, 0-14; 15-49; 50-74; 75+ (4 lines)
* c) age sex (female)-specific mortality rate by age-groups, 0-14; 15-49; 50-74; 75+ 
* d) age sex (male)-specific mortality rate by age-groups, 0-14; 15-49; 50-74; 75+ 
*Figure 2 cause-specific mortality rate by age-groups (8 group of disases)
* a) 0-14; 
* b) 15-49; 
* c) 50-74
* d) 75+
*Figure 3 MALES: cause-specific mortality rate by age-groups (8 group of disases)
* a) 0-14; 
* b) 15-49; 
* c) 50-74
* d) 75+
*Figure 4 Females: cause-specific mortality rate by age-groups (8 group of disases)
* a) 0-14; 
* b) 15-49; 
* c) 50-74
* d) 75+

*Table 1

*Figure 1: Event Study

	
/*****************
Figures A1 
*******************/


*Raw data (a) in Sample
{


local age_l = 60
local age_u = 79

use "$data/deaths_02_15_did_panel", clear
keep if inrange(age_at_death, `age_l' , `age_u')
drop if cve_loc == 7777
g age = 60 * (inrange(age_at_death, 60, 69)) + ///
		70 * (inrange(age_at_death, 70, 79))

collapse (sum) deaths, by(yod age locality covered)
		
ren age age_at_death
merge 1:1 yod age_at_death locality using "$data/population/population_locality_interpolated_10yr_2000_2011_60_79", keepus(pop pop_f pop_m pop60_05) nogen keep(3)

g a70 = (age_at_death >= 70)
collapse (sum) deaths pop pop_m pop_f , by(yod a70 covered)


bys covered a70: egen long tot_pop_cov_2002 = total(pop) if yod == 2002
g pop_age_weights_cov_2002_a = pop/tot_pop_cov_2002

bys a70 covered: egen pop_age_weights_cov_2002 = min(pop_age_weights_cov_2002_a)

g asdr = deaths/pop 
g asdr_standard = asdr * pop_age_weights_cov_2002 

collapse (sum) deaths pop_m pop_f pop asdr dr_standard=asdr_standard, by(yod covered a70)

g cmr = (deaths/pop)* 1000
g aamr_standard = dr_standard  * 1000

gegen covered_a70 = group(covered a70)

*1: 0 - 70-
*2: 0 - 70+
*3: 2007 - 70-
*4: 2007 - 70+

drop asdr dr_standard a70 covered

reshape wide deaths pop_m pop_f pop cmr aamr_standard, i(yod) j(covered_a70)


local axissize =  1
local lsize = 1
local labsize = 1
twoway (scatter aamr_standard4 aamr_standard2 yod, yaxis(1) ///
		connect(l l) mc(red black) lc(red black) ms(O S) lp(solid solid)) ///
		(scatter  aamr_standard3 aamr_standard1  yod, yaxis(2) ///
		connect(l l) mc(red%50 black%50) lc(red%50 black%50) ms(O S) lp(dash dash)), ///
		ylabel(25(5)45, axis(1) labsize(*`labsize') angle(h)) ///
		ylabel(12(1)22, axis(2) labsize(*`labsize') angle(h)) ///
		xlabel(2002(1)2011, gmax angle(horizontal) labsize(*`labsize')) ///
		xline(2006, lcolor("253 181 21")) ///
		xline(2007, lpattern(dash) lcolor(maroon)) ///
		title("`title'") ///
		xtitle("Year", size(*`axissize')) ///
		ytitle("AA-Mortality Rate Ages {&isin} [70, 79] (Per 1,000)", axis(1) size(*`axissize')) ///
		ytitle("AA-Mortality Rate Ages {&isin} [60, 69] (Per 1,000)", axis(2) size(*`axissize')) ///
		graphregion(color(white)) ///
		legend(order(1 "Pop {&lt} 2,500 / Age {&isin} [70, 79]" ///
						 2 "Pop {&isin} [30k, 100k) / Age {&isin} [70, 79]" ///
						 3 "Pop {&lt} 2,500 / Age {&isin} [60, 69]" ///
						 4 "Pop {&isin} [30k, 100k) / Age {&isin} [60, 69]") ///
		on pos(6) ring(1) col(2) size(*`lsize')) 
graph export "$output/figures/raw_data/death_rates_nc_2007_second_60_79.pdf", replace


}
