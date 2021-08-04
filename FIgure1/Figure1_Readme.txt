Figure 1 requires intermediary files created from Large Ensemble simulations output.
These scripts are all in ncl. For each script, change name and location of source
data directory and output directory then
> ncl script.ncl
Scripts must be run for both 20th century and RCP8.5 LENS simulations.

The necessary files use the following scripts:

1. create regional ice area, volume files:
	pre_proc_hem_MHolland_NHregions_LE.ncl

2. create regional average surface temperature (Tsfc), ocean heat flux (fhocn), conductive heat flux (fcondtop_ai) files:
        pre_proc_hem_MHolland_NHregions_LE_VAR.ncl
will need to change variable name for each of three variables (Tsfc, fhocn and fcondtop_ai)

3. Calculate monthly average conductive heat flux from daily conductive heat flux:
    netCDF_daily2monthlyavg_fcond.le.ncl

4. Calculate conductive heat fluxes using grid cell mean thicknesses and monthly average :
    netCDF_fcond_variations.LE.ncl

5. create regional average conductive heat flux calculation files (fcondtop_mean_ai, fcondtop_nthick_ai, fcondtop_daily2monthly)
         pre_proc_nh_MHolland_NHregions_fcondtop_ai_calcs_LE.ncl
Once again, change variable name to calculate for all three of these fcondtops

Edit file directories, etc and run Figure1.fcond_ts.ncl
