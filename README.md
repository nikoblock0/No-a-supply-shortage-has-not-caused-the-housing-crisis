# No-a-supply-shortage-has-not-caused-the-housing-crisis
This page shows technical documentation for my article for the Canadian Centre for Policy Alternatives, "No, a supply shortage has not caused the housing crisis." 

Here is a brief rundown of the contents of this package: 

* * "Block_ccpa_fin_2026_technical.pdf" shows a thorough version of the article, with footnotes, citations, and a technical appendix. 

* "Block_ccpa_fin_2026_input.xlsx" contains all of the untransformed raw data used in this analysis, most of it copied from StatsCan tables. Sheet 2 is the same as Sheet 1 but displays details of the data sources at the bottom. 

* "Block_ccpa_fin_2026.do" shows the Stata code I used to transform and analyze the data. 

* "Block_ccpa_fin_2026_output.xlsx" is the output data, i.e. after it has been transformed by the Stata code. 

***********************************************************

Additionally, I will give a brief note on how to reproduce the three graphs using Excel or other non-Stata software. 

* Figure 1. Real home price 

To recreate Figure 1 on real home price, graph the following two variables from "Block_ccpa_fin_2026_output.xlsx": 
	* bench_avinc
	* bench_medinc

* Figure 2. Relative housing stock 

To recreate Figure 2 on relative housing stock, graph the following two variables: 
	* dwelpthou
	* dwelpthouadlt

* Figure 3. Real household debt 

To recreate Figure 3 on real household debt, graph the following two variables: 
	* agg_cred_inc
	* agg_mort_inc
