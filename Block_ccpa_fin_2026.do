*************************************************************
** No, a supply shortage has not caused the housing crisis **
**						Niko Block 						   **
*************************************************************

* Loading and cleaning the data
*--------------------------------*

* NB: Some lines of code below show the pathnames I personally used. These I mark specifically with a "////". Users wishing to reproduce my analysis should uncomment these lines and insert their own pathnames. 

* Importing the raw data I've constructed in Excel.
//// import excel "/Users/nikoblock/Documents/York/Dissertation/Housing/Cdn prices/Data/CCPA_raw_copied.xlsx", sheet("Sheet1") firstrow

* Changing directory
//// cd "/Users/nikoblock/Documents/York/Dissertation/Housing/Cdn prices/Data"
* Saving 
save "CCPA_housing_1.1.dta"

* First let's clean the data and assign labels.

drop if year==. // Cleaning

* Labels

label var year "Year"
label var pbo_dwellings "PBO dwellings, millions"
label var sc_dwellings "Dwellings, StatsCan"
label var sc_totalpop "Total population, StatsCan"
label var crea_onefam_benchmark "Single family benchmark home price, CREA"
label var gmd_hpi "GMD HPI"
label var jst_hpnom "JST HPI"
label var sc_cpi "CPI, StatsCan"
label var sc_cpi_shelter "CPI for shelter, StatsCan"
label var sc_avinc_2023cad "Average fam income, 2023 CAD, StatsCan"
label var sc_medinc_2023cad "Median fam income, 2023 CAD, StatsCan"
label var sc_agginc "Total personal income, 2023 CAD, StatsCan"
label var hh_cred1 "Total houshold credit, 1970-2020"
label var mort_cred1 "Residential mortgages, 1970-2020"
label var hh_cred2 "Total houshold credit, 1990-2025"
label var mort_cred2 "Residential mortgages, 1990-2025"
label var crea_ont_home "Ontario average home price"
label var sc_ont_medinc_2023cad "Median fam income Ontario, 2023 CAD, StatsCan"
label var ont_dwlls "Total private dwellings in Ontario"
label var ont_popn "Total population of Ontario"
label var pbo_households_mil "Millions of households"


* Figure 1. Real home price 
*--------------------------------------*

* For Figure 1, the first task is to create a level indicator for housing. My strategy here is to take the CREA single family benchmark home. However, because it only goes back to 2005, I'll use the housing price index from the JST database. This indicator was originally produced, mainly, by the UBC Sauder school. Knoll et al. (2017, 36-42) explains their approach in detail. 

* Recalculating the JST HPI so that its 2005 level = 1. 

quietly summarize jst_hpnom if year == 2005, meanonly
scalar jst2005 		= r(mean) // This scalar captures the single 2005 value. 
gen jst_hpi_2005 	= jst_hpnom/jst2005 // New HPI var where 2005 = 1. 
label var jst_hpi_2005 "JST HPI 2005=1"

* Next I create a new var that will capture the benchmark as a level, copying the CREA benchmark level from 2005 onward and extending it back in time using the JST HPI. This will allow for comparison of the post-2005 figures as well.
* Creating an intermediate var using the extension method for all years.  

quietly summarize crea_onefam_benchmark if year == 2005, meanonly
scalar crea2005 = r(mean) // This scalar captures the single 2005 value for thre CREA benchmark. 
gen bench_ext 	= crea2005 * jst_hpi_2005
label var bench_ext "CREA 2005 x JST HPI 2005"

* Doing an eyeball comparison of the two: 
// browse year crea_onefam_benchmark bench_ext
* The JST HPI does seem to register an even higher rate of growth after 2005, so that by 2020 the CREA benchmark shows a price of $619,400 while the benchmark extension gives $657,760. This might cause some issues extending back in time as well. I am struck that in 1970 the benchmark extension shows a price of less than $22,000 while it shoots up to over $100,000 in 1981, with a massive bump over the provious year. Given that interest rates rose at that time I would have expected prices to fall rather than skyrocket. In any case, I'll proceed normally; once this is denominated with income it might make more sense.

* Creating the level var, with the CREA price for 2005 and after and the JST extension before that. 
gen onefam_bench 		= crea_onefam_benchmark
replace onefam_bench 	= bench_ext if year < 2005 
label var onefam_bench "Single family home, estimated price"

* Next I create two indicators: One denominating this by median family income, the other by average family income. In order to do that I have to de-index them, so that the numbers are nominal, and not expressed in 2023 dollars. 

* The present version of CPI takes 2002 as its baseline year. I need to first recalculate it so that 2023 is the baseline, i.e. 2023 = 1. 

quietly summarize sc_cpi if year == 2023, meanonly
scalar cpi2023 	= r(mean)
gen cpi_2023 	= sc_cpi/cpi2023
label var cpi_2023 "CPI 2023=1"

* Next we take the median and average income indicators, which are denominated in 2023 dollars, and convert them back into nominal values. 

gen sc_avinc 	= sc_avinc_2023cad * cpi_2023
label var sc_avinc "Average family income, nominal"
gen sc_medinc 	= sc_medinc_2023cad * cpi_2023
label var sc_medinc "Median family income, nominal" // add this 

* Finally we calculate the benchmark price relative to average and median income. 

gen bench_avinc = onefam_bench/sc_avinc
label variable bench_avinc "Benchmark home price/average family income"
gen bench_medinc = onefam_bench/sc_medinc
label variable bench_medinc "Benchmark home price/median family income"

* Creating Figure 1: Benchmark home price relative to family income

twoway ///
    (line bench_avinc year, lwidth(medthick) lcolor(dkgreen)) ///
    (line bench_medinc year, lwidth(medthick) lcolor(midgreen)), ///
    xlabel(1970(10)2020) ///
    xscale(range(1970 2025)) ///
    xtitle("") ///
	title("Figure 1. Real home price") ///
	ylabel(2(1)8) ///
	legend(cols(1))
	

* Saving graph as GPH and PNG 

//// graph save "Graph" "/Users/nikoblock/Documents/York/Dissertation/Housing/Cdn prices/Data/Fig1.gph"
//// graph export "/Users/nikoblock/Documents/York/Dissertation/Housing/Cdn prices/Data/Fig1.png", as(png) name("Graph")

* Figure 2. Relative housing stock 
*-------------------------------------------------*

* This figure calculates dwellings relative to the population, total and adults. 

* First we calculate the numerator, total number of dwellings. Unfortunately the PBO estimates are low-resolution, denominated in millions. 
* Rescaling PBO dwellings into total number.

gen pbo_dwellings_tot = pbo_dwellings * 1000000
label var pbo_dwellings_tot "Dwellings, PBO" 

* Calculate a rescaling factor, first as a scalar
* Grabbing the 2000 values from each series

quietly summarize sc_dwellings if year == 2000, meanonly
scalar sc2000 = r(mean)
quietly summarize pbo_dwellings_tot if year == 2000, meanonly
scalar pbo2000 = r(mean)

* Calculating the rescaling factor

scalar resc_dwell = sc2000 / pbo2000
display resc_dwell // .94718812

* Generate adjusted PBO version 

gen pbo_dwell_adj = pbo_dwellings_tot*resc_dwell
label var pbo_dwell_adj "Dwellings, PBO x splice"

* Calculating dwellings

gen dwellings 		= sc_dwellings if year < 2001
replace dwellings 	= pbo_dwell_adj if year > 2000
label var dwellings "Dwellings"

* Next we calculate the two denominators, total population and adult population. 

gen popthou = sc_totalpop / 1000
label var popthou "Population in thousands, StatsCan"

* Creating var for adults by thousands.

gen sc_adults = sc_totalpop - sc_0_4 - sc_5_9 - sc_10_14 - sc_15_19
label var sc_adults "Adult population, StatsCan"
gen adultthou = sc_adults / 1000 
label var adultthou "Adult population in thousands, StatsCan"

* Dropping vars for child population 

drop sc_0_4 sc_5_9 sc_10_14 sc_15_19

* Next I generate ratios of dwellings per 1000 people and per 1000 adults

gen dwelpthou = dwellings / popthou
label var dwelpthou "Dwellings per 1,000 people"
gen dwelpthouadlt = dwellings / adultthou
label var dwelpthouadlt "Dwellings per 1,000 adults"

* Generate Figure 2: Housing stock per capita

twoway ///
    (line dwelpthou year, lwidth(medthick) lcolor(olive)) ///
    (line dwelpthouadlt year, lwidth(medthick) lcolor(brown)), ///
    xlabel(1970(10)2020) ///
    xscale(range(1970 2025)) ///
	xtitle("") ///
    title("Figure 2. Relative housing stock")

* Saving graph as GPH and PNG 

//// graph save "Graph" "/Users/nikoblock/Documents/York/Dissertation/Housing/Cdn prices/Data/Fig2.gph"
//// graph export "/Users/nikoblock/Documents/York/Dissertation/Housing/Cdn prices/Data/Fig2.png", as(png) name("Graph")


* Figure 3: Real household debt 
*-------------------------------------------------*

* There are two numerators here: total household credit and total residential mortgages. To determine these for the full time series, I'll need to draw from two StatsCan tables: "Credit measures" which runs from 1969 to 2020, and "Credit liabilities", which runs from 1990 to 2025. I will use the latter for 1990 to the present, and rescale the series from the former for a smooth time series. All of these tables show the indicator in unadjusted CAD. 

* Total household credit 
* We start by calculating the rescaling factor based on the discrepancy in 1990. 

quietly summarize hh_cred1 if year == 1990
scalar hc1_1990 = r(mean)
quietly summarize hh_cred2 if year == 1990
scalar hc2_1990 = r(mean)

* Calculating the rescaling factor 

scalar resc_hc = hc2_1990/hc1_1990
display resc_hc // 1.0824134 

* Generate rescaled version of hh_cred1

gen hh_cred1_adj = hh_cred1*resc_hc
label var hh_cred1_adj "Household credit 1, rescaled"

* Generate hh_cred, total household debt 

gen hh_cred 		= hh_cred2
replace hh_cred 	= hh_cred1_adj if year < 1990
label var hh_cred "Total household debt, millions of CAD"

* Now I'll do the same for residential mortgages 

quietly summarize mort_cred1 if year == 1990
scalar mc1_1990 = r(mean)
quietly summarize mort_cred2 if year == 1990
scalar mc2_1990 = r(mean)

* Calculating the rescaling factor 

scalar resc_mc = mc2_1990/mc1_1990
display resc_mc // 1.0011309

* Generate rescaled version of mort_cred1

gen mort_cred1_adj = mort_cred1*resc_mc
label var mort_cred1_adj "Mortgage debt 1, rescaled"

* Generate mort_cred, total mortgage debt

gen mort_cred 		= mort_cred2
replace mort_cred 	= mort_cred1_adj if year < 1990
label var mort_cred "Total mortgage debt, millions of CAD"

* Our two numerators are calculated. Now we need to readjust the denominator, aggreggate household income, 

gen agginc = sc_agginc * cpi_2023
label var agginc "Aggregate personal income, millions of CAD"

* Now we calculate aggregate debt and mortgage debt relative to aggregate income. 
gen agg_cred_inc = hh_cred/agginc
label var agg_cred_inc "Total household debt/income"
gen agg_mort_inc = mort_cred/agginc
label var agg_mort_inc "Total residential mortgage debt/income"

* Generating Figure 3: Debt relative to income

twoway ///
    (line agg_cred_inc year, lwidth(medthick) lcolor(maroon)) ///
    (line agg_mort_inc year, lwidth(medthick) lcolor(cranberry)), ///
    xlabel(1970(10)2020) ///
    xscale(range(1970 2025)) ///
    xtitle("") ///
	title("Figure 3. Real household debt") ///
	legend(cols(1))

* Saving graph as GPH and PNG 

//// graph save "Graph" "/Users/nikoblock/Documents/York/Dissertation/Housing/Cdn prices/Data/Fig3.gph"
//// graph export "/Users/nikoblock/Documents/York/Dissertation/Housing/Cdn prices/Data/Fig3.png", as(png) name("Graph")

* Saving the whole DTA. 

save, replace

*----------------------------------------------------------------*
* Supplementary analysis 1: Households relative to dwellings
*----------------------------------------------------------------*

gen pbo_households_thou = pbo_households_mil * 1000
label var pbo_households_thou "Thousands of households"

gen dwelpthouhh = dwellings/pbo_households_thou
label var "Dwellings per thousand households"

list year dwelpthouhh if inlist(year, 1971, 1976, 1981, 1986, 1991, 1996, ///
	2001, 2006, 2011, 2016, 2021), noobs sepby(year)

/* 

	year   dwelpthouhh
-------------------------------
	1971	1035.932
	1976	1027.203
	1981	1012.153
	1986	1012.303
	1991	1019.523
	1996	1022.576
	2001	1011.134
	2006	1018.212
	2011	1018.922
	2016	1021.83
	2021	1017.034

*/ 

*-----------------------------------------------------*
* Supplementary analysis 2: Indicators for Ontario
*-----------------------------------------------------*

* Calculating the ratio of dwellings per thousand people in Ontario in 2001 and 2021. 

gen dwelpthou_ont = ont_dwlls/(ont_popn/1000)
label var dwelpthou_ont "Dwellings per 1000 people in Ontario"

list year dwelpthou_ont if inlist(year, 2001, 2006, 2011, 2016, 2021), ///
    noobs sepby(year)
	
/*
	year	dwelpthou_ont
----------------------------
	2001	382.9586
	2006	392.7411
	2011	400.2901
	2016	403.444
	2021	399.4782
*/

* Next we'll calculate the average home price relative to average family income in Ontario. 

* The var for median family income in Ontario is denominated in 2023 CAD. De-indexing this.
gen sc_ont_medinc = sc_ont_medinc_2023cad * cpi_2023
label var sc_ont_medinc "Median fam income Ontario"

* Calculate Ontario average home price / median family income
gen ont_bench_medinc = crea_ont_home/sc_ont_medinc
label var ont_bench_medinc "Ontario average home price / median family income"

list year ont_bench_medinc if inlist(year, 2001, 2006, 2011, 2016, 2021), ///
    noobs sepby(year)

/*
	year	ont_bench_medinc
-------------------------------
	2001	3.055202
	2006	4.030519
	2011	4.5443
	2016	5.877674
	2021	7.487337
*/

*----------------------------------------------------------------*
* Supplementary analysis 3: Mortgage propotion of all debt
*----------------------------------------------------------------*

gen mort_portion = agg_mort_inc/agg_cred_inc
label var mort_portion "Mortgage propotion of all debt"

summarize mort_portion // mean = 0.649367


