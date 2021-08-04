Figure 2 requires intermediary files created from Large Ensemble simulations output.
These scripts are all in ncl. For each script, change name and location of source
data directory and output directory then
> ncl script.ncl
Scripts must be run for both 20th century and RCP8.5 LENS simulations.

The necessary files use the following scripts:

1. create statistics for hi, hs, Tsfc, fcondtop_ai:
     netCDF_aice_stats.LE.ts_bymonth.ncl
will need to change variable name for each of these four variables (hi, hs, Tsfc, and fcondtop_ai)


Edit file directories, etc and run Figure2.cont_ndiff.ncl
