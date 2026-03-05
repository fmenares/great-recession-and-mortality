/*******************************************************************************
 * main.do
 *
 * Master do-file for "Great Recession and Mortality in Mexico"
 *
 * Runs all scripts in order:
 *   1. Data preparation (00_*.do)
 *   2. Analysis (1_*.do)
 *
 * Usage: Run this file from Stata. Set the global `root` below to the path
 *        of the codes/ directory if your working directory differs.
 *******************************************************************************/

clear all
set more off
capture log close
set seed 1234

* ---------------------------------------------------------------------------- *
*  USER PATHS
*  Each user defines the globals used across all scripts. Add a new block
*  following the pattern below if you are a new user.
* ---------------------------------------------------------------------------- *

if c(username) == "felip" {
    global deaths "C:\Users\felip\Dropbox\R01_MHAS\Mortality_VitalStatistics_Project\RawData_Mortality_VitalStatistics\"
    global data   "C:\Users\felip\Dropbox\2024\70ymas\data/"
    global output "C:/Users/felip/Dropbox/Aplicaciones/Overleaf/70yMas/"
    global iter   "C:\Users\felip\Dropbox\R01_MHAS\Progresa_Locality_Mortality_Project\CensusData_ITER\"
    global SP     "C:\Users\felip\Dropbox\R01_MHAS\SocialProgramBeneficiaries"
}

if c(username) == "fmenares" {
    global deaths "/hdir/0/fmenares/Dropbox/R01_MHAS/Mortality_VitalStatistics_Project/RawData_Mortality_VitalStatistics/"
    global data   "/data/Dropbox0/fmenares/Dropbox/2024/70ymas/data/"
    global output "/hdir/0/fmenares/Dropbox/Aplicaciones/Overleaf/70yMas/"
    global iter   "/hdir/0/fmenares/Dropbox/R01_MHAS/Progresa_Locality_Mortality_Project/CensusData_ITER/"
    global SP     "/hdir/0/fmenares/Dropbox/R01_MHAS/SocialProgramBeneficiaries"
}

if c(username) == "FELIPEME" {
    global deaths "C:/Users/FELIPEME/OneDrive - Inter-American Development Bank Group/Documents/personal/70ymas/data/deaths"
    global data   "C:/Users/FELIPEME/OneDrive - Inter-American Development Bank Group/Documents/personal/great_recession/data/"
    global output "C:\Users\FELIPEME\OneDrive - Inter-American Development Bank Group\Documents\personal\great_recession\"
    global iter   "/hdir/0/fmenares/Dropbox/R01_MHAS/Progresa_Locality_Mortality_Project/CensusData_ITER/"
    global SP     "/hdir/0/fmenares/Dropbox/R01_MHAS/SocialProgramBeneficiaries"
}

if c(username) == "INEGI" {
    global deaths "Z:\Procesamiento\Insumos\Estadisticas de Defuniones Registradas\"
    global data   "Z:\Procesamiento\Insumos\FMS\"
    global output "Z:\Resultados\CPV-2018-08-14\LM575-CPV-2018-08-14\"
    global iter   "Z:\Procesamiento\Insumos\ITER\"
    global SP     ""
}

* Resolve the directory where the do-files live (codes/).
* This works whether you open main.do from the Stata GUI or run it via -do-.
if "`c(filename)'" != "" {
    local codedir = subinstr("`c(filename)'", "main.do", "", .)
}
else {
    local codedir "`c(pwd)'/"
}

* ---------------------------------------------------------------------------- *
*  OPEN LOG
* ---------------------------------------------------------------------------- *

log using "`codedir'main_log.log", replace text

di "============================================================"
di " GREAT RECESSION AND MORTALITY IN MEXICO"
di " Started: `c(current_date)' `c(current_time)'"
di "============================================================"

* ---------------------------------------------------------------------------- *
*  STEP 1 — DATA PREPARATION
* ---------------------------------------------------------------------------- *

* 1a. Covariates (marginality, social programs, health infrastructure, population)
di ""
di "--- Running 00_covariates.do ---"
do "`codedir'00_covariates.do"

* 1b. Economic Census → CZ-level employment variables
di ""
di "--- Running 00_economic_census.do ---"
do "`codedir'00_economic_census.do"

* 1c. INEGI death records → mortality_shock_data.dta
*     (merges covariates and employment data internally)
di ""
di "--- Running 00_death_data_INEGI.do ---"
do "`codedir'00_death_data_INEGI.do"

* ---------------------------------------------------------------------------- *
*  STEP 2 — ANALYSIS
* ---------------------------------------------------------------------------- *

* 2a. Descriptive figures (mortality trends by treatment status)
di ""
di "--- Running 1_analysis.do ---"
do "`codedir'1_analysis.do"

* 2b. TWFE regression models and LaTeX tables
di ""
di "--- Running 1_models.do ---"
do "`codedir'1_models.do"

* ---------------------------------------------------------------------------- *
*  DONE
* ---------------------------------------------------------------------------- *

di ""
di "============================================================"
di " ALL SCRIPTS COMPLETED SUCCESSFULLY"
di " Finished: `c(current_date)' `c(current_time)'"
di "============================================================"

log close
