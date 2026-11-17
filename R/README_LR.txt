Timeline-
1. EB's original models (all data are present in G:/_org_data)
2. Development of M1 models-
	i) New AG panels were built; biophysical data were kept the same
	ii) The AG panel variables are mostly from CoA, ERS, NAICS, etc. The procedure is  described in	
	 Compiling DISES Data Model_M1.ipynb
	iii) The final AG panel for M1 is located at /data/lr/ag_data_std_2012_17_M1.csv
	iv) M1 random forest models and SHAP results are located in /out/SHAP_new_sampling, RF_new_sampling
3. Model M1 missed some important variables. The panels were updated after FG and M2 were developed.
4. Development of M2-
	i) Vars that got updated/included in M2 => irrigation from MIRCA (previously from MIRAD, binary), PRICE, crop-specific one NAICS variable named mean_est_std (previously not crop specific), conservation tillage (combined notill + conservational till acres), AG land value
	ii) M2 AG panel data files are located at: /data/quantitative_data/data_input_RF_2//ag_data_std_2012_17.csv
	iii) AG panel was built using python, all code here: Compiling DISES Data.ipynb
	iv) Random forest models were run on HPC. Function to run RF is in DISES_func_new_sampling_model2.R
	v) RF outputs are located in out/model2_R/RF/*
	vi) SHAP was computed at county scale using the function from DISES_SHAP_calculation_hpc.R
	vii) All variables were aggregated at county scale for SHAP. All crop-specific county aggregated files are in
	located /out/county_agg_mod2_mirca/*
	viii) SHAP outputs are located in /out/model2_R/SHAP/*
5. Figures for M2 are located in figs_model2 folder
__________________________________________________________________________________________________________________

**More info on the code files:**

Two modeling components: random forest and SHAP using treeshap in R

Data required for random forest-
-Crop specific absence and presence, and other biophysical variables ==> crop_AG_MIRCA.rds files
- Other human controlled variables, like irrigation     

Step-by-step procedure to run the model-
i) Input data (AG panel) generation-
	a) COA file - this is the panel data generated for the DISES project. Not crop-specific data. Used Python for 	it; all the codes are there in Compiling DISES Data.ipynb.
		- located at: ./data_input_RF_2/ag_data_std_2012_17.csv

	b) crop-specific presence-absence and other var RDS file- 
	- Built on existing AG panels using function build_ag_panel2 in DISES_func_new.R; the panels are located 	at /out/ag_rds2/crop_name_AG.RDS
	- function build_ag_panel2 builds the RDS panel for model 2.0, while build_ag_panel builds it for model 1.
	- AG panel RDS files for model 1 are saved at ./out/crop_name_AG.RDS
	- AG panel RDS files for model 2.0 are saved at ./out/ag_rds2/crop_name_AG.RDS

ii) Run random forest models-
	a) the models were run on HPC
	b) DISES_RF_model_training.R: script to use to run the RF classifier

iii) SHAP analysis using treeshap
	a) crop-specific SHAP function is in DISES_SHAP_calculation_hpc.R file
	b) SHAP analysis and figures are in DISES_SHAP1_MOD2.R (mostly figures)
	
iv) Delphi_future_suit_M2.R- future suitability raster generation plotting codes
v)  DISES_FG_LR.R- plots generated for focus group meetings
vi) Compare_M1M2.R- comparison between M1 and M2 for GA, NE and OH; used for focus group results
vii) DISES_EDA1.R- Scripts to plot suitability plots, especially the scenario-based plots (example fertilizer reduction, etc.)
viii) MIRCA_OS.R- Codes for generating crop-specific irrigation datasets from MIRCA-OS data. Also, to obtain the county aggregated data, which is an input for the SHAP models.



