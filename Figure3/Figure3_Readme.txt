Figure 3 requires intermediary files created from Large Ensemble simulations output.
Some of these files were created in the steps for Figure1. Some are new.
These scripts are all in ncl. For each script, change name and location of source
data directory and output directory then
> ncl script.ncl
Scripts must be run for both 20th century and RCP8.5 LENS simulations.

The necessary files use the following scripts:

1. create regional ice area, volume files for each of the thickness categories:
   pre_proc_hem_MHolland_NHregions_LE_aicen.ncl

Edit file directories, etc and run Figure3.aicen00x_fcond.ts.ncl
