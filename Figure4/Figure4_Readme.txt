Figure 4 requires intermediary files created from Large Ensemble simulations output.
Some of these files were created in the steps for Figure1. Some are new.
These scripts are all in ncl. For each script, change name and location of source
data directory and output directory then
> ncl script.ncl
Scripts must be run for both 20th century and RCP8.5 LENS simulations.

The necessary files use the following scripts:

1. create regional average surface heat flux ice components:
   pre_proc_hem_MHolland_NHregions_LE_cice_surfaceheatflux.ncl

2. create regional average surface heat flux ocn components:
   pre_proc_hem_MHolland_NHregions_LE_ocn_surfaceheatflux.ncl

Edit file directories, etc and run Figure4.contour.SHF_month_year.ncl
