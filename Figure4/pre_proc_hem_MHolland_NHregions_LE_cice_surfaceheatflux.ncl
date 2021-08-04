; modified to calculate regional totals for surface heat flux
; related variables from cice output.
; Variables are:
;         fswabs_ai			absorbed solar flux (normalized by ice area and passed to coupler)
;         fsens_ai			sensible heat flux (normalized by ice area passed to coupler)
;         flat_ai                       latent heat flux (normalized by ice area and passed to coupler)
;         flwup_ai                      longwave heat flux (up and normalized by ice area and passed to coupler)
;         flwdn				downward longwave heat flux (from atm)
;         fswdn				downward shorwave heat flux (from atm)
; Script also uses aice field to create flwd_ai and fswdn_ai
; June, 2020
;
; Modified for LE
;
; Modified to include regional definitions from MHolland
; Feb 2017
;
;***************************************************************
; This script is a copy of pre_process.ncl from the ice diagnostics
; package modified to use already processed monthly aice, hi, hs 
; files.
; Laura Landrum
; December, 2010
;
; modified to create pre processed ice file from single-variable
; files that are saved by hemisphere (e.g. Large Ensemble).
; September, 2014
;***************************************************************
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/shea_util.ncl"

begin
  LE_20thC_case = "b.e11.B20TRC5CNBDRD.f09_g16."
  LE_rcp_case = "b.e11.BRCP85C5CNBDRD.f09_g16."
  case_numbers = ispan(1,40,1)
  case_numbers(35:) = ispan(101,105,1)
  scnumbers = sprinti("%0.3i",case_numbers)

  hist_case = LE_20thC_case+scnumbers(0)
  c20thC_case = LE_20thC_case+ scnumbers
  rcp85_case = LE_rcp_case+scnumbers

;  case_names = c20thC_case
  case_names = rcp85_case
  ncase = dimsizes(case_names)

  tseries_dir = "/glade/collections/cdg/data/cesmLE/CESM-CAM5-BGC-LE/ice/proc/tseries/monthly/"
  out_dir = "/glade/p/cesm/pcwg/landrum/LE/shf/ice/"

  yr1 = new(ncase,integer)
;  yr1 = 1920							; start and end yrs for time series
;  yr1(0) = 1850
  yr1 = 2081
  yr1(33:) = 2006
  yr2 = yr1
  yr2 = 2100
;  yr2(33:) = 2100
  yr1_proc = 2081                                                  ; start and end yrs for pre-processed time series
  yr2_proc = 2100

  nyears = yr2_proc - yr1_proc + 1

  offset = (yr1_proc - yr1)*12

  styrs = sprinti("%0.4i",yr1) + "01-"+sprinti("%0.4i",yr2)+"12"
  styrs_proc = sprinti("%0.4i",yr1_proc) + "-"+sprinti("%0.4i",yr2_proc)

  faice_nh = tseries_dir+"aice/"+case_names+".cice.h.aice_nh."+styrs+".nc"
  ffswabs_ai_nh = tseries_dir+"fswabs_ai/"+case_names+".cice.h.fswabs_ai_nh."+styrs+".nc"
  ffsens_ai_nh = tseries_dir+"fsens_ai/"+case_names+".cice.h.fsens_ai_nh."+styrs+".nc"
  fflat_ai_nh = tseries_dir+"flat_ai/"+case_names+".cice.h.flat_ai_nh."+styrs+".nc"
  fflwup_ai_nh = tseries_dir+"flwup_ai/"+case_names+".cice.h.flwup_ai_nh."+styrs+".nc"
  fflwdn_nh = tseries_dir+"flwdn/"+case_names+".cice.h.flwdn_nh."+styrs+".nc"
  ffswdn_nh = tseries_dir+"fswdn/"+case_names+".cice.h.fswdn_nh."+styrs+".nc"
  ffsurf_ai_nh = tseries_dir+"fsurf_ai/"+case_names+".cice.h.fsurf_ai_nh."+styrs+".nc"

  faice_sh = tseries_dir+"aice/"+case_names+".cice.h.aice_sh."+styrs+".nc"
  ffswabs_ai_sh = tseries_dir+"fswabs_ai/"+case_names+".cice.h.fswabs_ai_sh."+styrs+".nc"
  ffsens_ai_sh = tseries_dir+"fsens_ai/"+case_names+".cice.h.fsens_ai_sh."+styrs+".nc"
  fflat_ai_sh = tseries_dir+"flat_ai/"+case_names+".cice.h.flat_ai_sh."+styrs+".nc"
  fflwup_ai_sh = tseries_dir+"flwup_ai/"+case_names+".cice.h.flwup_ai_sh."+styrs+".nc"
  fflwdn_sh = tseries_dir+"flwdn/"+case_names+".cice.h.flwdn_sh."+styrs+".nc"
  ffswdn_sh = tseries_dir+"fswdn/"+case_names+".cice.h.fswdn_sh."+styrs+".nc"
  ffsurf_ai_sh = tseries_dir+"fsurf_ai/"+case_names+".cice.h.fsurf_ai_sh."+styrs+".nc"

  if (.not.(isfilepresent(out_dir))) then
     system("mkdir "+out_dir)
  end if

;****************************************************************
; Boundary areas for regional masks:
; Northern Hemisphere:
;       Lab            Lab Sea
;       GIN            GIN Sea
;       Bar            Barents/Kara Sea
;       ArcOc          Arctic Ocean
;       Sib            Siberian Sea
;       Beau           Beaufort Sea
;       CArc           Central Arctic
;       Bering         Bering Sea
;       Okhotsk        Sea of Okhotsk
;       Hudson         Hudson Bay
;       CAArch         Canadian Archipelago
;       Chukchi        Chukchi Sea
;       Kara           Kara Sea
;       Laptev         Laptev Sea
;
;Southern Hemisphere:
;       Wed            Weddell Sea
;       Ross           Ross Sea
;       Ind            Indian sector
;       Pac            Pacific sector
;       BAm            Bellingshausen-Amundsen Sea
;
;******************************************************************
  nh50_90_lat = (/50.,90./)

  Lab_lat = (/50.,78./)
  Lab_long = (/284.,315./)
  GIN_lat = (/65.,80./)
  GIN_long1 = (/315.,360./)
  GIN_long2 = (/0.,15./)
  Bar_lat = (/66.,80./)
  Bar_long = (/15.,55./)
  ArcOc_lat1 = (/80.,90./)
  ArcOc_lat2 = ArcOc_lat1
  ArcOc_lat3 = (/68.,90./)
  ArcOc_long1 = (/243.,360./)
  ArcOc_long2 = (/0.,100./)
  ArcOc_long3 = (/100.,243./)
  Kara_lat = (/68.,80./)
  Kara_long = (/55.,100./)
  Laptev_lat = (/68.,80./)
  Laptev_long = (/100.,145./)

  Sib_lat = (/68.,80./)
  Sib_long = (/145.,185./)
  Beau_lat = (/68.,80./)
  Beau_long = (/205.,240./)
  Chukchi_lat = (/68.,80./)
  Chukchi_long = (/185.,205./)
;  Okhotsk_lat = (/45.,63./)			; have below - more complicated - but roughly 44-64N, 133-168E
;  Okhotsk_long = (/135.,160./)

  CArc_lat = (/80.,90./)			; Central Arctic
  CArc_long = (/0.,360./)

;  Bering_lat = (/50.,65./)			; have below - more complicated - but roughly 52.5-68N, 162-204E
;  Bering_long = (/163.,205./)

;---------------------------------------------------------------
; These Arctic regions are more complicated geographically
; and will be defined by polygons rather than min,max lat,lon
;--------------------------------------------------------------
  Lab_poly_lat = (/50., 64., 74., 78., 78., 50./)
  Lab_poly_long = (/295., 292., 280., 280., 315., 315./)
  Bering_poly_lat = (/56., 60., 68., 68., 58., 52.5, 52.5/)
  Bering_poly_long = (/162., 162., 178., 200., 204., 190., 180./)
  Okhotsk_poly_lat = (/44., 44., 46., 51., 60., 64., 60., 55., 44./)
  Okhotsk_poly_long = (/142., 145., 150., 157., 162., 168., 140., 133., 142./)
  Hudson_poly_lat = (/50., 66., 66., 70., 70., 68., 62., 60., 50./)
  Hudson_poly_long = (/265., 265., 274., 274., 290., 290., 292., 295., 295./)
  CAArch_poly_lat = (/67., 80., 80., 70., 67./)
  CAArch_poly_long = (/243., 243., 281., 281., 275./)
; ------SH regions------------------
  sh50_90_lat = (/-90.,-50./)
  Wed_lat = (/-90.,-50./)
  Wed_long1 = (/300.,360./)
  Wed_long2 = (/0.,20./)
  Ross_lat = (/-90.,-50./)
  Ross_long = (/160.,220./)
  Ind_lat = (/-90.,-50./)
  Ind_long = (/20.,90./)
  Pac_lat = (/-90.,-50./)
  Pac_long = (/90.,160./)
  BAm_lat = (/-90.,-50./)
  BAm_long = (/220.,300./)

  HF_swabs_ai_mo_nh = new((/nyears*12/),float)
  HF_sens_ai_mo_nh = new((/nyears*12/),float)
  HF_lat_ai_mo_nh = new((/nyears*12/),float)
  HF_lwup_ai_mo_nh = new((/nyears*12/),float)
  HF_lwup_ai_mo_nh = new((/nyears*12/),float)
  HF_lwdn_ai_mo_nh = new((/nyears*12/),float)
  HF_swdn_ai_mo_nh = new((/nyears*12/),float)
  HF_surf_ai_mo_nh = new((/nyears*12/),float)
  HF_lwdn_mo_nh = new((/nyears*12/),float)
  HF_swdn_mo_nh = new((/nyears*12/),float)
  HF_lwdn_mo_nh50_90 = new((/nyears*12/),float) 			  ; to limit to higher latitude NH
  HF_swdn_mo_nh50_90 = new((/nyears*12/),float)

  HF_swabs_ai_mo_sh = new((/nyears*12/),float)
  HF_sens_ai_mo_sh = new((/nyears*12/),float)
  HF_lat_ai_mo_sh = new((/nyears*12/),float)
  HF_lwup_ai_mo_sh = new((/nyears*12/),float)
  HF_lwdn_mo_sh = new((/nyears*12/),float)
  HF_swdn_mo_sh = new((/nyears*12/),float)
  HF_lwdn_ai_mo_sh = new((/nyears*12/),float)
  HF_swdn_ai_mo_sh = new((/nyears*12/),float)
  HF_surf_ai_mo_sh = new((/nyears*12/),float)
  HF_lwdn_mo_sh50_90 = new((/nyears*12/),float)                     ; to limit to higher latitude NH
  HF_swdn_mo_sh50_90 = new((/nyears*12/),float)

;*****************************
; regional arrays: Arctic
;*****************************
  HF_swabs_ai_mo_Lab = new((/nyears*12/),float)
  HF_sens_ai_mo_Lab = new((/nyears*12/),float)
  HF_lat_ai_mo_Lab = new((/nyears*12/),float)
  HF_lwup_ai_mo_Lab = new((/nyears*12/),float)
  HF_lwdn_ai_mo_Lab = new((/nyears*12/),float)
  HF_swdn_ai_mo_Lab = new((/nyears*12/),float)
  HF_surf_ai_mo_Lab = new((/nyears*12/),float)
  HF_lwdn_mo_Lab = new((/nyears*12/),float)
  HF_swdn_mo_Lab = new((/nyears*12/),float)

  HF_swabs_ai_mo_GIN = new((/nyears*12/),float)
  HF_sens_ai_mo_GIN = new((/nyears*12/),float)
  HF_lat_ai_mo_GIN = new((/nyears*12/),float)
  HF_lwup_ai_mo_GIN = new((/nyears*12/),float)
  HF_lwdn_ai_mo_GIN = new((/nyears*12/),float)
  HF_swdn_ai_mo_GIN = new((/nyears*12/),float)
  HF_surf_ai_mo_GIN = new((/nyears*12/),float)
  HF_lwdn_mo_GIN = new((/nyears*12/),float)
  HF_swdn_mo_GIN = new((/nyears*12/),float)

  HF_swabs_ai_mo_Bar = new((/nyears*12/),float)
  HF_sens_ai_mo_Bar = new((/nyears*12/),float)
  HF_lat_ai_mo_Bar = new((/nyears*12/),float)
  HF_lwup_ai_mo_Bar = new((/nyears*12/),float)
  HF_lwdn_ai_mo_Bar = new((/nyears*12/),float)
  HF_swdn_ai_mo_Bar = new((/nyears*12/),float)
  HF_surf_ai_mo_Bar = new((/nyears*12/),float)
  HF_lwdn_mo_Bar = new((/nyears*12/),float)
  HF_swdn_mo_Bar = new((/nyears*12/),float)

  HF_swabs_ai_mo_ArcOc = new((/nyears*12/),float)
  HF_sens_ai_mo_ArcOc = new((/nyears*12/),float)
  HF_lat_ai_mo_ArcOc = new((/nyears*12/),float)
  HF_lwup_ai_mo_ArcOc = new((/nyears*12/),float)
  HF_lwdn_ai_mo_ArcOc = new((/nyears*12/),float)
  HF_swdn_ai_mo_ArcOc = new((/nyears*12/),float)
  HF_surf_ai_mo_ArcOc = new((/nyears*12/),float)
  HF_lwdn_mo_ArcOc = new((/nyears*12/),float)
  HF_swdn_mo_ArcOc = new((/nyears*12/),float)

  HF_swabs_ai_mo_Kara = new((/nyears*12/),float)
  HF_sens_ai_mo_Kara = new((/nyears*12/),float)
  HF_lat_ai_mo_Kara = new((/nyears*12/),float)
  HF_lwup_ai_mo_Kara = new((/nyears*12/),float)
  HF_lwdn_ai_mo_Kara = new((/nyears*12/),float)
  HF_swdn_ai_mo_Kara = new((/nyears*12/),float)
  HF_surf_ai_mo_Kara = new((/nyears*12/),float)
  HF_lwdn_mo_Kara = new((/nyears*12/),float)
  HF_swdn_mo_Kara = new((/nyears*12/),float)

  HF_swabs_ai_mo_Laptev = new((/nyears*12/),float)
  HF_sens_ai_mo_Laptev = new((/nyears*12/),float)
  HF_lat_ai_mo_Laptev = new((/nyears*12/),float)
  HF_lwup_ai_mo_Laptev = new((/nyears*12/),float)
  HF_lwdn_ai_mo_Laptev = new((/nyears*12/),float)
  HF_swdn_ai_mo_Laptev = new((/nyears*12/),float)
  HF_surf_ai_mo_Laptev = new((/nyears*12/),float)
  HF_lwdn_mo_Laptev = new((/nyears*12/),float)
  HF_swdn_mo_Laptev = new((/nyears*12/),float)

  HF_swabs_ai_mo_Chukchi = new((/nyears*12/),float)
  HF_sens_ai_mo_Chukchi = new((/nyears*12/),float)
  HF_lat_ai_mo_Chukchi = new((/nyears*12/),float)
  HF_lwup_ai_mo_Chukchi = new((/nyears*12/),float)
  HF_lwdn_ai_mo_Chukchi = new((/nyears*12/),float)
  HF_swdn_ai_mo_Chukchi = new((/nyears*12/),float)
  HF_surf_ai_mo_Chukchi = new((/nyears*12/),float)
  HF_lwdn_mo_Chukchi = new((/nyears*12/),float)
  HF_swdn_mo_Chukchi = new((/nyears*12/),float)

  HF_swabs_ai_mo_Sib = new((/nyears*12/),float)
  HF_sens_ai_mo_Sib = new((/nyears*12/),float)
  HF_lat_ai_mo_Sib = new((/nyears*12/),float)
  HF_lwup_ai_mo_Sib = new((/nyears*12/),float)
  HF_lwdn_mo_Sib = new((/nyears*12/),float)
  HF_swdn_mo_Sib = new((/nyears*12/),float)
  HF_lwdn_ai_mo_Sib = new((/nyears*12/),float)
  HF_swdn_ai_mo_Sib = new((/nyears*12/),float)
  HF_surf_ai_mo_Sib = new((/nyears*12/),float)

  HF_swabs_ai_mo_Beau = new((/nyears*12/),float)
  HF_sens_ai_mo_Beau = new((/nyears*12/),float)
  HF_lat_ai_mo_Beau = new((/nyears*12/),float)
  HF_lwup_ai_mo_Beau = new((/nyears*12/),float)
  HF_lwdn_ai_mo_Beau = new((/nyears*12/),float)
  HF_swdn_ai_mo_Beau = new((/nyears*12/),float)
  HF_surf_ai_mo_Beau = new((/nyears*12/),float)
  HF_lwdn_mo_Beau = new((/nyears*12/),float)
  HF_swdn_mo_Beau = new((/nyears*12/),float)

  HF_swabs_ai_mo_CArc = new((/nyears*12/),float)
  HF_sens_ai_mo_CArc = new((/nyears*12/),float)
  HF_lat_ai_mo_CArc = new((/nyears*12/),float)
  HF_lwup_ai_mo_CArc = new((/nyears*12/),float)
  HF_lwdn_ai_mo_CArc = new((/nyears*12/),float)
  HF_swdn_ai_mo_CArc = new((/nyears*12/),float)
  HF_surf_ai_mo_CArc = new((/nyears*12/),float)
  HF_lwdn_mo_CArc = new((/nyears*12/),float)
  HF_swdn_mo_CArc = new((/nyears*12/),float)

  HF_swabs_ai_mo_Bering = new((/nyears*12/),float)
  HF_sens_ai_mo_Bering = new((/nyears*12/),float)
  HF_lat_ai_mo_Bering = new((/nyears*12/),float)
  HF_lwup_ai_mo_Bering = new((/nyears*12/),float)
  HF_lwdn_ai_mo_Bering = new((/nyears*12/),float)
  HF_swdn_ai_mo_Bering = new((/nyears*12/),float)
  HF_surf_ai_mo_Bering = new((/nyears*12/),float)
  HF_lwdn_mo_Bering = new((/nyears*12/),float)
  HF_swdn_mo_Bering = new((/nyears*12/),float)

  HF_swabs_ai_mo_Okhotsk = new((/nyears*12/),float)
  HF_sens_ai_mo_Okhotsk = new((/nyears*12/),float)
  HF_lat_ai_mo_Okhotsk = new((/nyears*12/),float)
  HF_lwup_ai_mo_Okhotsk = new((/nyears*12/),float)
  HF_lwdn_ai_mo_Okhotsk = new((/nyears*12/),float)
  HF_swdn_ai_mo_Okhotsk = new((/nyears*12/),float)
  HF_surf_ai_mo_Okhotsk = new((/nyears*12/),float)
  HF_lwdn_mo_Okhotsk = new((/nyears*12/),float)
  HF_swdn_mo_Okhotsk = new((/nyears*12/),float)

  HF_swabs_ai_mo_Hudson = new((/nyears*12/),float)
  HF_sens_ai_mo_Hudson = new((/nyears*12/),float)
  HF_lat_ai_mo_Hudson = new((/nyears*12/),float)
  HF_lwup_ai_mo_Hudson = new((/nyears*12/),float)
  HF_lwdn_ai_mo_Hudson = new((/nyears*12/),float)
  HF_swdn_ai_mo_Hudson = new((/nyears*12/),float)
  HF_surf_ai_mo_Hudson = new((/nyears*12/),float)
  HF_lwdn_mo_Hudson = new((/nyears*12/),float)
  HF_swdn_mo_Hudson = new((/nyears*12/),float)

  HF_swabs_ai_mo_CAArch = new((/nyears*12/),float)
  HF_sens_ai_mo_CAArch = new((/nyears*12/),float)
  HF_lat_ai_mo_CAArch = new((/nyears*12/),float)
  HF_lwup_ai_mo_CAArch = new((/nyears*12/),float)
  HF_lwdn_mo_CAArch = new((/nyears*12/),float)
  HF_swdn_mo_CAArch = new((/nyears*12/),float)
  HF_lwdn_ai_mo_CAArch = new((/nyears*12/),float)
  HF_swdn_ai_mo_CAArch = new((/nyears*12/),float)
  HF_surf_ai_mo_CAArch = new((/nyears*12/),float)
;*****************************
; regional arrays: Antarctic
;*****************************
  HF_swabs_ai_mo_Wed = new((/nyears*12/),float)
  HF_sens_ai_mo_Wed = new((/nyears*12/),float)
  HF_lat_ai_mo_Wed = new((/nyears*12/),float)
  HF_lwup_ai_mo_Wed = new((/nyears*12/),float)
  HF_lwdn_ai_mo_Wed = new((/nyears*12/),float)
  HF_swdn_ai_mo_Wed = new((/nyears*12/),float)
  HF_surf_ai_mo_Wed = new((/nyears*12/),float)
  HF_lwdn_mo_Wed = new((/nyears*12/),float)
  HF_swdn_mo_Wed = new((/nyears*12/),float)

  HF_swabs_ai_mo_Ross = new((/nyears*12/),float)
  HF_sens_ai_mo_Ross = new((/nyears*12/),float)
  HF_lat_ai_mo_Ross = new((/nyears*12/),float)
  HF_lwup_ai_mo_Ross = new((/nyears*12/),float)
  HF_lwdn_ai_mo_Ross = new((/nyears*12/),float)
  HF_swdn_ai_mo_Ross = new((/nyears*12/),float)
  HF_surf_ai_mo_Ross = new((/nyears*12/),float)
  HF_lwdn_mo_Ross = new((/nyears*12/),float)
  HF_swdn_mo_Ross = new((/nyears*12/),float)

  HF_swabs_ai_mo_Ind = new((/nyears*12/),float)
  HF_sens_ai_mo_Ind = new((/nyears*12/),float)
  HF_lat_ai_mo_Ind = new((/nyears*12/),float)
  HF_lwup_ai_mo_Ind = new((/nyears*12/),float)
  HF_lwdn_mo_Ind = new((/nyears*12/),float)
  HF_swdn_mo_Ind = new((/nyears*12/),float)
  HF_lwdn_ai_mo_Ind = new((/nyears*12/),float)
  HF_swdn_ai_mo_Ind = new((/nyears*12/),float)
  HF_surf_ai_mo_Ind = new((/nyears*12/),float)
 
  HF_swabs_ai_mo_Pac = new((/nyears*12/),float)
  HF_sens_ai_mo_Pac = new((/nyears*12/),float)
  HF_lat_ai_mo_Pac = new((/nyears*12/),float)
  HF_lwup_ai_mo_Pac = new((/nyears*12/),float)
  HF_lwdn_ai_mo_Pac = new((/nyears*12/),float)
  HF_swdn_ai_mo_Pac = new((/nyears*12/),float)
  HF_surf_ai_mo_Pac = new((/nyears*12/),float)
  HF_lwdn_mo_Pac = new((/nyears*12/),float)
  HF_swdn_mo_Pac = new((/nyears*12/),float)

  HF_swabs_ai_mo_BAm = new((/nyears*12/),float)
  HF_sens_ai_mo_BAm = new((/nyears*12/),float)
  HF_lat_ai_mo_BAm = new((/nyears*12/),float)
  HF_lwup_ai_mo_BAm = new((/nyears*12/),float)
  HF_lwdn_ai_mo_BAm = new((/nyears*12/),float)
  HF_swdn_ai_mo_BAm = new((/nyears*12/),float)
  HF_surf_ai_mo_BAm = new((/nyears*12/),float)
  HF_lwdn_mo_BAm = new((/nyears*12/),float)
  HF_swdn_mo_BAm = new((/nyears*12/),float)

;  time = new((/nyears*12/),float)

do ii = 0,ncase-1
   print("calculating area totals for "+case_names(ii))
   f1_nh = addfile(ffswabs_ai_nh(ii),"r")
   f2_nh = addfile(ffsens_ai_nh(ii),"r")
   f3_nh = addfile(fflat_ai_nh(ii),"r")
   f4_nh = addfile(fflwup_ai_nh(ii),"r")
   f5_nh = addfile(fflwdn_nh(ii),"r")
   f6_nh = addfile(ffswdn_nh(ii),"r")
   f7_nh = addfile(faice_nh(ii),"r")
   f8_nh = addfile(ffsurf_ai_nh(ii),"r")

   f1_sh = addfile(ffswabs_ai_sh(ii),"r")
   f2_sh = addfile(ffsens_ai_sh(ii),"r")
   f3_sh = addfile(fflat_ai_sh(ii),"r")
   f4_sh = addfile(fflwup_ai_sh(ii),"r")
   f5_sh = addfile(fflwdn_sh(ii),"r")
   f6_sh = addfile(ffswdn_sh(ii),"r")
   f7_sh = addfile(faice_sh(ii),"r")
   f8_sh = addfile(ffsurf_ai_sh(ii),"r")

   do nn = 0, nyears-1

      imo1 = 12*nn
      imo2 = 12*nn+11

      imo1_datain = offset(ii) + 12*nn
      imo2_datain = offset(ii) + 12*nn+11

      if ((ii.eq.0).and.(nn .eq. 0)) then
         tarea_nh = f1_nh->tarea
         tlat_nh  = f1_nh->TLAT
         tlon_nh = f1_nh->TLON
         it2 = offset(ii) + (nyears*12) - 1
         time = f1_nh->time(imo1_datain:it2)

         tarea_sh = f1_sh->tarea
         tlat_sh  = f1_sh->TLAT
         tlon_sh = f1_sh->TLON
      end if

      fswabs_ai_nh = f1_nh->fswabs_ai(imo1_datain:imo2_datain,:,:)
      fsens_ai_nh = f2_nh->fsens_ai(imo1_datain:imo2_datain,:,:)
      flat_ai_nh = f3_nh->flat_ai(imo1_datain:imo2_datain,:,:)
      flwup_ai_nh = f4_nh->flwup_ai(imo1_datain:imo2_datain,:,:)
      flwdn_nh = f5_nh->flwdn(imo1_datain:imo2_datain,:,:)
      fswdn_nh = f6_nh->fswdn(imo1_datain:imo2_datain,:,:)
      aice_nh = f7_nh->aice(imo1_datain:imo2_datain,:,:)
      fsurf_ai_nh = f8_nh->fsurf_ai(imo1_datain:imo2_datain,:,:)

      if (max(aice_nh).gt.1.1) then				; need fraction not %
         aice_nh = 0.01*aice_nh
      end if

      tlat2_nh = conform(flat_ai_nh,tlat_nh,(/1,2/))
      tlon2_nh = conform(flat_ai_nh,tlon_nh,(/1,2/))
      HF_swabs_ai_nh = fswabs_ai_nh*conform(fswabs_ai_nh,tarea_nh,(/1,2/))
      HF_sens_ai_nh = fsens_ai_nh*conform(fsens_ai_nh,tarea_nh,(/1,2/))
      HF_lat_ai_nh = flat_ai_nh*conform(flat_ai_nh,tarea_nh,(/1,2/))
      HF_surf_ai_nh = fsurf_ai_nh*conform(flat_ai_nh,tarea_nh,(/1,2/))
      HF_lwup_ai_nh = flwup_ai_nh*conform(flwup_ai_nh,tarea_nh,(/1,2/))
      HF_lwdn_ai_nh = aice_nh*flwdn_nh*conform(flwdn_nh,tarea_nh,(/1,2/))
      HF_swdn_ai_nh = aice_nh*fswdn_nh*conform(fswdn_nh,tarea_nh,(/1,2/))
      HF_lwdn_nh = flwdn_nh*conform(flwdn_nh,tarea_nh,(/1,2/))
      HF_swdn_nh = fswdn_nh*conform(fswdn_nh,tarea_nh,(/1,2/))

      fswabs_ai_sh = f1_sh->fswabs_ai(imo1_datain:imo2_datain,:,:)
      fsens_ai_sh = f2_sh->fsens_ai(imo1_datain:imo2_datain,:,:)
      flat_ai_sh = f3_sh->flat_ai(imo1_datain:imo2_datain,:,:)
      flwup_ai_sh = f4_sh->flwup_ai(imo1_datain:imo2_datain,:,:)
      flwdn_sh = f5_sh->flwdn(imo1_datain:imo2_datain,:,:)
      fswdn_sh = f6_sh->fswdn(imo1_datain:imo2_datain,:,:)
      aice_sh = f7_sh->aice(imo1_datain:imo2_datain,:,:)
      fsurf_ai_sh = f8_sh->fsurf_ai(imo1_datain:imo2_datain,:,:)
      if (max(aice_sh).gt.1.1) then
         aice_sh = 0.01*aice_sh
      end if

      tlat2_sh = conform(flat_ai_sh,tlat_sh,(/1,2/))
      tlon2_sh = conform(flat_ai_sh,tlon_sh,(/1,2/))
      HF_swabs_ai_sh = fswabs_ai_sh*conform(fswabs_ai_sh,tarea_sh,(/1,2/))
      HF_sens_ai_sh = fsens_ai_sh*conform(fsens_ai_sh,tarea_sh,(/1,2/))
      HF_lat_ai_sh = flat_ai_sh*conform(flat_ai_sh,tarea_sh,(/1,2/))
      HF_surf_ai_sh = fsurf_ai_sh*conform(flat_ai_sh,tarea_sh,(/1,2/))
      HF_lwup_ai_sh = flwup_ai_sh*conform(flwup_ai_sh,tarea_sh,(/1,2/))
      HF_lwdn_ai_sh = aice_sh*flwdn_sh*conform(flwdn_sh,tarea_sh,(/1,2/))
      HF_swdn_ai_sh = aice_sh*fswdn_sh*conform(fswdn_sh,tarea_sh,(/1,2/))
      HF_lwdn_sh = flwdn_sh*conform(flwdn_sh,tarea_sh,(/1,2/))
      HF_swdn_sh = fswdn_sh*conform(fswdn_sh,tarea_sh,(/1,2/))

;-------------------------------------------------------------
; create masks for Labrador Sea, Bering Sea, Sea of Okhotsk,
; Hudson Bay and Canadian Archipelago here. They are not simply
; rectangles...........
; Only need to do this once (first year of nyears)
;------------------------------------------------------------
      if ((ii.eq.0).and.(nn .eq. 0)) then
         Lab_mask = new(dimsizes(HF_lat_ai_nh),typeof(HF_lat_ai_nh),HF_lat_ai_nh@_FillValue)
         Bering_mask = new(dimsizes(HF_lat_ai_nh),typeof(HF_lat_ai_nh),HF_lat_ai_nh@_FillValue)
         Okhotsk_mask = new(dimsizes(HF_lat_ai_nh),typeof(HF_lat_ai_nh),HF_lat_ai_nh@_FillValue)
         CAArch_mask = new(dimsizes(HF_lat_ai_nh),typeof(HF_lat_ai_nh),HF_lat_ai_nh@_FillValue)
         Hudson_mask = new(dimsizes(HF_lat_ai_nh),typeof(HF_lat_ai_nh),HF_lat_ai_nh@_FillValue)
         np_nh = dimsizes(tlat_nh)
         nlat_nh = np_nh(0)
         nlon = np_nh(1)							;nlon same for both hemispheres
         do i=0,nlat_nh-1
            do j=0,nlon-1
	       plat = tlat_nh(i,j)
               plon = tlon_nh(i,j)
 	       if ((.not.(ismissing(plat))).and.(plat.ge.min(Okhotsk_poly_lat)).and.(plon.ge.min(Okhotsk_poly_long))) then
                  Lab_inout = gc_inout(plat,plon,Lab_poly_lat,Lab_poly_long)
                  Bering_inout = gc_inout(plat,plon,Bering_poly_lat,Bering_poly_long)
                  Okhotsk_inout = gc_inout(plat,plon,Okhotsk_poly_lat,Okhotsk_poly_long)
                  Hudson_inout = gc_inout(plat,plon,Hudson_poly_lat,Hudson_poly_long)
                  CAArch_inout = gc_inout(plat,plon,CAArch_poly_lat,CAArch_poly_long)
                  if (Lab_inout .eq. True) then
	              Lab_mask(:,i,j) = 1.
	          end if
                  if (Bering_inout .eq. True) then
                     Bering_mask(:,i,j) = 1.
                  end if
                  if (Okhotsk_inout .eq. True) then
                     Okhotsk_mask(:,i,j) = 1.
                  end if
                  if (Hudson_inout .eq. True) then
                     Hudson_mask(:,i,j) = 1.
                  end if
                  if (CAArch_inout .eq. True) then
                     CAArch_mask(:,i,j) = 1.
                  end if
	       end if
            end do
         end do
      end if

      HF_lwdn_nh50_90 = mask(HF_lwdn_nh,(tlat2_nh.ge.nh50_90_lat(0) .and. tlat2_nh.le.nh50_90_lat(1)),True)
      HF_swdn_nh50_90 = mask(HF_swdn_nh,(tlat2_nh.ge.nh50_90_lat(0) .and. tlat2_nh.le.nh50_90_lat(1)),True)

      HF_sens_ai_Lab = mask(HF_sens_ai_nh,(Lab_mask .eq. 1.), True)
      HF_swabs_ai_Lab = mask(HF_swabs_ai_nh,(Lab_mask .eq. 1.), True)
      HF_lat_ai_Lab = mask(HF_lat_ai_nh,(Lab_mask .eq. 1.), True)
      HF_surf_ai_Lab = mask(HF_surf_ai_nh,(Lab_mask .eq. 1.), True)
      HF_lwup_ai_Lab = mask(HF_lwup_ai_nh,(Lab_mask .eq. 1.), True)
      HF_lwdn_ai_Lab = mask(HF_lwdn_ai_nh,(Lab_mask .eq. 1.), True)
      HF_swdn_ai_Lab = mask(HF_swdn_ai_nh,(Lab_mask .eq. 1.), True)
      HF_lwdn_Lab = mask(HF_lwdn_nh,(Lab_mask .eq. 1.), True)
      HF_swdn_Lab = mask(HF_swdn_nh,(Lab_mask .eq. 1.), True)
 
      HF_sens_ai_GIN = mask(HF_sens_ai_nh,(tlat2_nh.ge.GIN_lat(0) .and. tlat2_nh.le.GIN_lat(1) .and.\
                  ((tlon2_nh.ge.GIN_long1(0) .and. tlon2_nh.le.GIN_long1(1)) .or.\
		   (tlon2_nh.ge.GIN_long2(0) .and. tlon2_nh.le.GIN_long2(1)))), True)
      HF_swabs_ai_GIN = mask(HF_swabs_ai_nh,(tlat2_nh.ge.GIN_lat(0) .and. tlat2_nh.le.GIN_lat(1) .and.\
                  ((tlon2_nh.ge.GIN_long1(0) .and. tlon2_nh.le.GIN_long1(1)) .or.\
                   (tlon2_nh.ge.GIN_long2(0) .and. tlon2_nh.le.GIN_long2(1)))), True)
      HF_lat_ai_GIN = mask(HF_lat_ai_nh,(tlat2_nh.ge.GIN_lat(0) .and. tlat2_nh.le.GIN_lat(1) .and.\
                  ((tlon2_nh.ge.GIN_long1(0) .and. tlon2_nh.le.GIN_long1(1)) .or.\
                   (tlon2_nh.ge.GIN_long2(0) .and. tlon2_nh.le.GIN_long2(1)))), True)
      HF_surf_ai_GIN = mask(HF_surf_ai_nh,(tlat2_nh.ge.GIN_lat(0) .and. tlat2_nh.le.GIN_lat(1) .and.\
                  ((tlon2_nh.ge.GIN_long1(0) .and. tlon2_nh.le.GIN_long1(1)) .or.\
                   (tlon2_nh.ge.GIN_long2(0) .and. tlon2_nh.le.GIN_long2(1)))), True)
      HF_lwup_ai_GIN = mask(HF_lwup_ai_nh,(tlat2_nh.ge.GIN_lat(0) .and. tlat2_nh.le.GIN_lat(1) .and.\
                  ((tlon2_nh.ge.GIN_long1(0) .and. tlon2_nh.le.GIN_long1(1)) .or.\
                   (tlon2_nh.ge.GIN_long2(0) .and. tlon2_nh.le.GIN_long2(1)))), True)
      HF_lwdn_ai_GIN = mask(HF_lwdn_ai_nh,(tlat2_nh.ge.GIN_lat(0) .and. tlat2_nh.le.GIN_lat(1) .and.\
                  ((tlon2_nh.ge.GIN_long1(0) .and. tlon2_nh.le.GIN_long1(1)) .or.\
                   (tlon2_nh.ge.GIN_long2(0) .and. tlon2_nh.le.GIN_long2(1)))), True)
      HF_swdn_ai_GIN = mask(HF_swdn_ai_nh,(tlat2_nh.ge.GIN_lat(0) .and. tlat2_nh.le.GIN_lat(1) .and.\
                  ((tlon2_nh.ge.GIN_long1(0) .and. tlon2_nh.le.GIN_long1(1)) .or.\
                   (tlon2_nh.ge.GIN_long2(0) .and. tlon2_nh.le.GIN_long2(1)))), True)
      HF_lwdn_GIN = mask(HF_lwdn_nh,(tlat2_nh.ge.GIN_lat(0) .and. tlat2_nh.le.GIN_lat(1) .and.\
                  ((tlon2_nh.ge.GIN_long1(0) .and. tlon2_nh.le.GIN_long1(1)) .or.\
                   (tlon2_nh.ge.GIN_long2(0) .and. tlon2_nh.le.GIN_long2(1)))), True)
      HF_swdn_GIN = mask(HF_swdn_nh,(tlat2_nh.ge.GIN_lat(0) .and. tlat2_nh.le.GIN_lat(1) .and.\
                  ((tlon2_nh.ge.GIN_long1(0) .and. tlon2_nh.le.GIN_long1(1)) .or.\
                   (tlon2_nh.ge.GIN_long2(0) .and. tlon2_nh.le.GIN_long2(1)))), True)

      HF_sens_ai_Bar = mask(HF_sens_ai_nh,(tlat2_nh.ge.Bar_lat(0) .and. tlat2_nh.le.Bar_lat(1) .and.\
                  tlon2_nh.ge.Bar_long(0) .and. tlon2_nh.le.Bar_long(1)), True)
      HF_swabs_ai_Bar = mask(HF_swabs_ai_nh,(tlat2_nh.ge.Bar_lat(0) .and. tlat2_nh.le.Bar_lat(1) .and.\
                  tlon2_nh.ge.Bar_long(0) .and. tlon2_nh.le.Bar_long(1)), True)
      HF_lat_ai_Bar = mask(HF_lat_ai_nh,(tlat2_nh.ge.Bar_lat(0) .and. tlat2_nh.le.Bar_lat(1) .and.\
                  tlon2_nh.ge.Bar_long(0) .and. tlon2_nh.le.Bar_long(1)), True)
      HF_surf_ai_Bar = mask(HF_surf_ai_nh,(tlat2_nh.ge.Bar_lat(0) .and. tlat2_nh.le.Bar_lat(1) .and.\
                  tlon2_nh.ge.Bar_long(0) .and. tlon2_nh.le.Bar_long(1)), True)
      HF_lwup_ai_Bar = mask(HF_lwup_ai_nh,(tlat2_nh.ge.Bar_lat(0) .and. tlat2_nh.le.Bar_lat(1) .and.\
                  tlon2_nh.ge.Bar_long(0) .and. tlon2_nh.le.Bar_long(1)), True)
      HF_lwdn_ai_Bar = mask(HF_lwdn_ai_nh,(tlat2_nh.ge.Bar_lat(0) .and. tlat2_nh.le.Bar_lat(1) .and.\
                  tlon2_nh.ge.Bar_long(0) .and. tlon2_nh.le.Bar_long(1)), True)
      HF_swdn_ai_Bar = mask(HF_swdn_ai_nh,(tlat2_nh.ge.Bar_lat(0) .and. tlat2_nh.le.Bar_lat(1) .and.\
                  tlon2_nh.ge.Bar_long(0) .and. tlon2_nh.le.Bar_long(1)), True)
      HF_lwdn_Bar = mask(HF_lwdn_nh,(tlat2_nh.ge.Bar_lat(0) .and. tlat2_nh.le.Bar_lat(1) .and.\
                  tlon2_nh.ge.Bar_long(0) .and. tlon2_nh.le.Bar_long(1)), True)
      HF_swdn_Bar = mask(HF_swdn_nh,(tlat2_nh.ge.Bar_lat(0) .and. tlat2_nh.le.Bar_lat(1) .and.\
                  tlon2_nh.ge.Bar_long(0) .and. tlon2_nh.le.Bar_long(1)), True)

      HF_sens_ai_ArcOc = mask(HF_sens_ai_nh,((tlat2_nh.ge.ArcOc_lat1(0) .and. (tlon2_nh.ge.ArcOc_long1(0) .or.\
                  tlon2_nh.le.ArcOc_long2(1))) .or. (tlat2_nh.ge.ArcOc_lat3(0) .and.\
                   (tlon2_nh.ge.ArcOc_long3(0) .and. tlon2_nh.le.ArcOc_long3(1)))), True)
      HF_swabs_ai_ArcOc = mask(HF_swabs_ai_nh,((tlat2_nh.ge.ArcOc_lat1(0) .and. (tlon2_nh.ge.ArcOc_long1(0) .or.\
                  tlon2_nh.le.ArcOc_long2(1))) .or. (tlat2_nh.ge.ArcOc_lat3(0) .and.\
                   (tlon2_nh.ge.ArcOc_long3(0) .and. tlon2_nh.le.ArcOc_long3(1)))), True)
      HF_lat_ai_ArcOc = mask(HF_lat_ai_nh,((tlat2_nh.ge.ArcOc_lat1(0) .and. (tlon2_nh.ge.ArcOc_long1(0) .or.\
                  tlon2_nh.le.ArcOc_long2(1))) .or. (tlat2_nh.ge.ArcOc_lat3(0) .and.\
                   (tlon2_nh.ge.ArcOc_long3(0) .and. tlon2_nh.le.ArcOc_long3(1)))), True)
      HF_surf_ai_ArcOc = mask(HF_surf_ai_nh,((tlat2_nh.ge.ArcOc_lat1(0) .and. (tlon2_nh.ge.ArcOc_long1(0) .or.\
                  tlon2_nh.le.ArcOc_long2(1))) .or. (tlat2_nh.ge.ArcOc_lat3(0) .and.\
                   (tlon2_nh.ge.ArcOc_long3(0) .and. tlon2_nh.le.ArcOc_long3(1)))), True)
      HF_lwup_ai_ArcOc = mask(HF_lwup_ai_nh,((tlat2_nh.ge.ArcOc_lat1(0) .and. (tlon2_nh.ge.ArcOc_long1(0) .or.\
                  tlon2_nh.le.ArcOc_long2(1))) .or. (tlat2_nh.ge.ArcOc_lat3(0) .and.\
                   (tlon2_nh.ge.ArcOc_long3(0) .and. tlon2_nh.le.ArcOc_long3(1)))), True)
      HF_lwdn_ai_ArcOc = mask(HF_lwdn_ai_nh,((tlat2_nh.ge.ArcOc_lat1(0) .and. (tlon2_nh.ge.ArcOc_long1(0) .or.\
                  tlon2_nh.le.ArcOc_long2(1))) .or. (tlat2_nh.ge.ArcOc_lat3(0) .and.\
                   (tlon2_nh.ge.ArcOc_long3(0) .and. tlon2_nh.le.ArcOc_long3(1)))), True)
      HF_swdn_ai_ArcOc = mask(HF_swdn_ai_nh,((tlat2_nh.ge.ArcOc_lat1(0) .and. (tlon2_nh.ge.ArcOc_long1(0) .or.\
                  tlon2_nh.le.ArcOc_long2(1))) .or. (tlat2_nh.ge.ArcOc_lat3(0) .and.\
                   (tlon2_nh.ge.ArcOc_long3(0) .and. tlon2_nh.le.ArcOc_long3(1)))), True)
      HF_lwdn_ArcOc = mask(HF_lwdn_nh,((tlat2_nh.ge.ArcOc_lat1(0) .and. (tlon2_nh.ge.ArcOc_long1(0) .or.\
                  tlon2_nh.le.ArcOc_long2(1))) .or. (tlat2_nh.ge.ArcOc_lat3(0) .and.\
                   (tlon2_nh.ge.ArcOc_long3(0) .and. tlon2_nh.le.ArcOc_long3(1)))), True)
      HF_swdn_ArcOc = mask(HF_swdn_nh,((tlat2_nh.ge.ArcOc_lat1(0) .and. (tlon2_nh.ge.ArcOc_long1(0) .or.\
                  tlon2_nh.le.ArcOc_long2(1))) .or. (tlat2_nh.ge.ArcOc_lat3(0) .and.\
                   (tlon2_nh.ge.ArcOc_long3(0) .and. tlon2_nh.le.ArcOc_long3(1)))), True)

      HF_sens_ai_Kara = mask(HF_sens_ai_nh,(tlat2_nh.ge.Kara_lat(0) .and. tlat2_nh.le.Kara_lat(1) .and.\
                  tlon2_nh.ge.Kara_long(0) .and. tlon2_nh.le.Kara_long(1)), True)
      HF_swabs_ai_Kara = mask(HF_swabs_ai_nh,(tlat2_nh.ge.Kara_lat(0) .and. tlat2_nh.le.Kara_lat(1) .and.\
                  tlon2_nh.ge.Kara_long(0) .and. tlon2_nh.le.Kara_long(1)), True)
      HF_lat_ai_Kara = mask(HF_lat_ai_nh,(tlat2_nh.ge.Kara_lat(0) .and. tlat2_nh.le.Kara_lat(1) .and.\
                  tlon2_nh.ge.Kara_long(0) .and. tlon2_nh.le.Kara_long(1)), True)
      HF_surf_ai_Kara = mask(HF_surf_ai_nh,(tlat2_nh.ge.Kara_lat(0) .and. tlat2_nh.le.Kara_lat(1) .and.\
                  tlon2_nh.ge.Kara_long(0) .and. tlon2_nh.le.Kara_long(1)), True)
      HF_lwup_ai_Kara = mask(HF_lwup_ai_nh,(tlat2_nh.ge.Kara_lat(0) .and. tlat2_nh.le.Kara_lat(1) .and.\
                  tlon2_nh.ge.Kara_long(0) .and. tlon2_nh.le.Kara_long(1)), True)
      HF_lwdn_ai_Kara = mask(HF_lwdn_ai_nh,(tlat2_nh.ge.Kara_lat(0) .and. tlat2_nh.le.Kara_lat(1) .and.\
                  tlon2_nh.ge.Kara_long(0) .and. tlon2_nh.le.Kara_long(1)), True)
      HF_swdn_ai_Kara = mask(HF_swdn_ai_nh,(tlat2_nh.ge.Kara_lat(0) .and. tlat2_nh.le.Kara_lat(1) .and.\
                  tlon2_nh.ge.Kara_long(0) .and. tlon2_nh.le.Kara_long(1)), True)
      HF_lwdn_Kara = mask(HF_lwdn_nh,(tlat2_nh.ge.Kara_lat(0) .and. tlat2_nh.le.Kara_lat(1) .and.\
                  tlon2_nh.ge.Kara_long(0) .and. tlon2_nh.le.Kara_long(1)), True)
      HF_swdn_Kara = mask(HF_swdn_nh,(tlat2_nh.ge.Kara_lat(0) .and. tlat2_nh.le.Kara_lat(1) .and.\
                  tlon2_nh.ge.Kara_long(0) .and. tlon2_nh.le.Kara_long(1)), True)

      HF_sens_ai_Laptev = mask(HF_sens_ai_nh,(tlat2_nh.ge.Laptev_lat(0) .and. tlat2_nh.le.Laptev_lat(1) .and.\
                  tlon2_nh.ge.Laptev_long(0) .and. tlon2_nh.le.Laptev_long(1)), True)
      HF_swabs_ai_Laptev = mask(HF_swabs_ai_nh,(tlat2_nh.ge.Laptev_lat(0) .and. tlat2_nh.le.Laptev_lat(1) .and.\
                  tlon2_nh.ge.Laptev_long(0) .and. tlon2_nh.le.Laptev_long(1)), True)
      HF_lat_ai_Laptev = mask(HF_lat_ai_nh,(tlat2_nh.ge.Laptev_lat(0) .and. tlat2_nh.le.Laptev_lat(1) .and.\
                  tlon2_nh.ge.Laptev_long(0) .and. tlon2_nh.le.Laptev_long(1)), True)
      HF_surf_ai_Laptev = mask(HF_surf_ai_nh,(tlat2_nh.ge.Laptev_lat(0) .and. tlat2_nh.le.Laptev_lat(1) .and.\
                  tlon2_nh.ge.Laptev_long(0) .and. tlon2_nh.le.Laptev_long(1)), True)
      HF_lwup_ai_Laptev = mask(HF_lwup_ai_nh,(tlat2_nh.ge.Laptev_lat(0) .and. tlat2_nh.le.Laptev_lat(1) .and.\
                  tlon2_nh.ge.Laptev_long(0) .and. tlon2_nh.le.Laptev_long(1)), True)
      HF_lwdn_ai_Laptev = mask(HF_lwdn_ai_nh,(tlat2_nh.ge.Laptev_lat(0) .and. tlat2_nh.le.Laptev_lat(1) .and.\
                  tlon2_nh.ge.Laptev_long(0) .and. tlon2_nh.le.Laptev_long(1)), True)
      HF_swdn_ai_Laptev = mask(HF_swdn_ai_nh,(tlat2_nh.ge.Laptev_lat(0) .and. tlat2_nh.le.Laptev_lat(1) .and.\
                  tlon2_nh.ge.Laptev_long(0) .and. tlon2_nh.le.Laptev_long(1)), True)
      HF_lwdn_Laptev = mask(HF_lwdn_nh,(tlat2_nh.ge.Laptev_lat(0) .and. tlat2_nh.le.Laptev_lat(1) .and.\
                  tlon2_nh.ge.Laptev_long(0) .and. tlon2_nh.le.Laptev_long(1)), True)
      HF_swdn_Laptev = mask(HF_swdn_nh,(tlat2_nh.ge.Laptev_lat(0) .and. tlat2_nh.le.Laptev_lat(1) .and.\
                  tlon2_nh.ge.Laptev_long(0) .and. tlon2_nh.le.Laptev_long(1)), True)

      HF_sens_ai_Chukchi = mask(HF_sens_ai_nh,(tlat2_nh.ge.Chukchi_lat(0) .and. tlat2_nh.le.Chukchi_lat(1) .and.\
                  tlon2_nh.ge.Chukchi_long(0) .and. tlon2_nh.le.Chukchi_long(1)), True)
      HF_swabs_ai_Chukchi = mask(HF_swabs_ai_nh,(tlat2_nh.ge.Chukchi_lat(0) .and. tlat2_nh.le.Chukchi_lat(1) .and.\
                  tlon2_nh.ge.Chukchi_long(0) .and. tlon2_nh.le.Chukchi_long(1)), True)
      HF_lat_ai_Chukchi = mask(HF_lat_ai_nh,(tlat2_nh.ge.Chukchi_lat(0) .and. tlat2_nh.le.Chukchi_lat(1) .and.\
                  tlon2_nh.ge.Chukchi_long(0) .and. tlon2_nh.le.Chukchi_long(1)), True)
      HF_surf_ai_Chukchi = mask(HF_surf_ai_nh,(tlat2_nh.ge.Chukchi_lat(0) .and. tlat2_nh.le.Chukchi_lat(1) .and.\
                  tlon2_nh.ge.Chukchi_long(0) .and. tlon2_nh.le.Chukchi_long(1)), True)
      HF_lwup_ai_Chukchi = mask(HF_lwup_ai_nh,(tlat2_nh.ge.Chukchi_lat(0) .and. tlat2_nh.le.Chukchi_lat(1) .and.\
                  tlon2_nh.ge.Chukchi_long(0) .and. tlon2_nh.le.Chukchi_long(1)), True)
      HF_lwdn_ai_Chukchi = mask(HF_lwdn_ai_nh,(tlat2_nh.ge.Chukchi_lat(0) .and. tlat2_nh.le.Chukchi_lat(1) .and.\
                  tlon2_nh.ge.Chukchi_long(0) .and. tlon2_nh.le.Chukchi_long(1)), True)
      HF_swdn_ai_Chukchi = mask(HF_swdn_ai_nh,(tlat2_nh.ge.Chukchi_lat(0) .and. tlat2_nh.le.Chukchi_lat(1) .and.\
                  tlon2_nh.ge.Chukchi_long(0) .and. tlon2_nh.le.Chukchi_long(1)), True)
      HF_lwdn_Chukchi = mask(HF_lwdn_nh,(tlat2_nh.ge.Chukchi_lat(0) .and. tlat2_nh.le.Chukchi_lat(1) .and.\
                  tlon2_nh.ge.Chukchi_long(0) .and. tlon2_nh.le.Chukchi_long(1)), True)
      HF_swdn_Chukchi = mask(HF_swdn_nh,(tlat2_nh.ge.Chukchi_lat(0) .and. tlat2_nh.le.Chukchi_lat(1) .and.\
                  tlon2_nh.ge.Chukchi_long(0) .and. tlon2_nh.le.Chukchi_long(1)), True)

      HF_sens_ai_Sib = mask(HF_sens_ai_nh,(tlat2_nh.ge.Sib_lat(0) .and. tlat2_nh.le.Sib_lat(1) .and.\
                  tlon2_nh.ge.Sib_long(0) .and. tlon2_nh.le.Sib_long(1)), True)
      HF_swabs_ai_Sib = mask(HF_swabs_ai_nh,(tlat2_nh.ge.Sib_lat(0) .and. tlat2_nh.le.Sib_lat(1) .and.\
                  tlon2_nh.ge.Sib_long(0) .and. tlon2_nh.le.Sib_long(1)), True)
      HF_lat_ai_Sib = mask(HF_lat_ai_nh,(tlat2_nh.ge.Sib_lat(0) .and. tlat2_nh.le.Sib_lat(1) .and.\
                  tlon2_nh.ge.Sib_long(0) .and. tlon2_nh.le.Sib_long(1)), True)
      HF_surf_ai_Sib = mask(HF_surf_ai_nh,(tlat2_nh.ge.Sib_lat(0) .and. tlat2_nh.le.Sib_lat(1) .and.\
                  tlon2_nh.ge.Sib_long(0) .and. tlon2_nh.le.Sib_long(1)), True)
      HF_lwup_ai_Sib = mask(HF_lwup_ai_nh,(tlat2_nh.ge.Sib_lat(0) .and. tlat2_nh.le.Sib_lat(1) .and.\
                  tlon2_nh.ge.Sib_long(0) .and. tlon2_nh.le.Sib_long(1)), True)
      HF_lwdn_ai_Sib = mask(HF_lwdn_ai_nh,(tlat2_nh.ge.Sib_lat(0) .and. tlat2_nh.le.Sib_lat(1) .and.\
                  tlon2_nh.ge.Sib_long(0) .and. tlon2_nh.le.Sib_long(1)), True)
      HF_swdn_ai_Sib = mask(HF_swdn_ai_nh,(tlat2_nh.ge.Sib_lat(0) .and. tlat2_nh.le.Sib_lat(1) .and.\
                  tlon2_nh.ge.Sib_long(0) .and. tlon2_nh.le.Sib_long(1)), True)
      HF_lwdn_Sib = mask(HF_lwdn_nh,(tlat2_nh.ge.Sib_lat(0) .and. tlat2_nh.le.Sib_lat(1) .and.\
                  tlon2_nh.ge.Sib_long(0) .and. tlon2_nh.le.Sib_long(1)), True)
      HF_swdn_Sib = mask(HF_swdn_nh,(tlat2_nh.ge.Sib_lat(0) .and. tlat2_nh.le.Sib_lat(1) .and.\
                  tlon2_nh.ge.Sib_long(0) .and. tlon2_nh.le.Sib_long(1)), True)

      HF_sens_ai_Beau = mask(HF_sens_ai_nh,(tlat2_nh.ge.Beau_lat(0) .and. tlat2_nh.le.Beau_lat(1) .and.\
                  tlon2_nh.ge.Beau_long(0) .and. tlon2_nh.le.Beau_long(1)), True)
      HF_swabs_ai_Beau = mask(HF_swabs_ai_nh,(tlat2_nh.ge.Beau_lat(0) .and. tlat2_nh.le.Beau_lat(1) .and.\
                  tlon2_nh.ge.Beau_long(0) .and. tlon2_nh.le.Beau_long(1)), True)
      HF_lat_ai_Beau = mask(HF_lat_ai_nh,(tlat2_nh.ge.Beau_lat(0) .and. tlat2_nh.le.Beau_lat(1) .and.\
                  tlon2_nh.ge.Beau_long(0) .and. tlon2_nh.le.Beau_long(1)), True)
      HF_surf_ai_Beau = mask(HF_surf_ai_nh,(tlat2_nh.ge.Beau_lat(0) .and. tlat2_nh.le.Beau_lat(1) .and.\
                  tlon2_nh.ge.Beau_long(0) .and. tlon2_nh.le.Beau_long(1)), True)
      HF_lwup_ai_Beau = mask(HF_lwup_ai_nh,(tlat2_nh.ge.Beau_lat(0) .and. tlat2_nh.le.Beau_lat(1) .and.\
                  tlon2_nh.ge.Beau_long(0) .and. tlon2_nh.le.Beau_long(1)), True)
      HF_lwdn_ai_Beau = mask(HF_lwdn_ai_nh,(tlat2_nh.ge.Beau_lat(0) .and. tlat2_nh.le.Beau_lat(1) .and.\
                  tlon2_nh.ge.Beau_long(0) .and. tlon2_nh.le.Beau_long(1)), True)
      HF_swdn_ai_Beau = mask(HF_swdn_ai_nh,(tlat2_nh.ge.Beau_lat(0) .and. tlat2_nh.le.Beau_lat(1) .and.\
                  tlon2_nh.ge.Beau_long(0) .and. tlon2_nh.le.Beau_long(1)), True)
      HF_lwdn_Beau = mask(HF_lwdn_nh,(tlat2_nh.ge.Beau_lat(0) .and. tlat2_nh.le.Beau_lat(1) .and.\
                  tlon2_nh.ge.Beau_long(0) .and. tlon2_nh.le.Beau_long(1)), True)
      HF_swdn_Beau = mask(HF_swdn_nh,(tlat2_nh.ge.Beau_lat(0) .and. tlat2_nh.le.Beau_lat(1) .and.\
                  tlon2_nh.ge.Beau_long(0) .and. tlon2_nh.le.Beau_long(1)), True)

      HF_sens_ai_CArc = mask(HF_sens_ai_nh,(tlat2_nh.ge.CArc_lat(0) .and. tlat2_nh.le.CArc_lat(1) .and.\
                  tlon2_nh.ge.CArc_long(0) .and. tlon2_nh.le.CArc_long(1)), True)
      HF_swabs_ai_CArc = mask(HF_swabs_ai_nh,(tlat2_nh.ge.CArc_lat(0) .and. tlat2_nh.le.CArc_lat(1) .and.\
                  tlon2_nh.ge.CArc_long(0) .and. tlon2_nh.le.CArc_long(1)), True)
      HF_lat_ai_CArc = mask(HF_lat_ai_nh,(tlat2_nh.ge.CArc_lat(0) .and. tlat2_nh.le.CArc_lat(1) .and.\
                  tlon2_nh.ge.CArc_long(0) .and. tlon2_nh.le.CArc_long(1)), True)
      HF_surf_ai_CArc = mask(HF_surf_ai_nh,(tlat2_nh.ge.CArc_lat(0) .and. tlat2_nh.le.CArc_lat(1) .and.\
                  tlon2_nh.ge.CArc_long(0) .and. tlon2_nh.le.CArc_long(1)), True)
      HF_lwup_ai_CArc = mask(HF_lwup_ai_nh,(tlat2_nh.ge.CArc_lat(0) .and. tlat2_nh.le.CArc_lat(1) .and.\
                  tlon2_nh.ge.CArc_long(0) .and. tlon2_nh.le.CArc_long(1)), True)
      HF_lwdn_ai_CArc = mask(HF_lwdn_ai_nh,(tlat2_nh.ge.CArc_lat(0) .and. tlat2_nh.le.CArc_lat(1) .and.\
                  tlon2_nh.ge.CArc_long(0) .and. tlon2_nh.le.CArc_long(1)), True)
      HF_swdn_ai_CArc = mask(HF_swdn_ai_nh,(tlat2_nh.ge.CArc_lat(0) .and. tlat2_nh.le.CArc_lat(1) .and.\
                  tlon2_nh.ge.CArc_long(0) .and. tlon2_nh.le.CArc_long(1)), True)
      HF_lwdn_CArc = mask(HF_lwdn_nh,(tlat2_nh.ge.CArc_lat(0) .and. tlat2_nh.le.CArc_lat(1) .and.\
                  tlon2_nh.ge.CArc_long(0) .and. tlon2_nh.le.CArc_long(1)), True)
      HF_swdn_CArc = mask(HF_swdn_nh,(tlat2_nh.ge.CArc_lat(0) .and. tlat2_nh.le.CArc_lat(1) .and.\
                  tlon2_nh.ge.CArc_long(0) .and. tlon2_nh.le.CArc_long(1)), True)

      HF_sens_ai_Bering = mask(HF_sens_ai_nh,(Bering_mask .eq. 1.), True)
      HF_swabs_ai_Bering = mask(HF_swabs_ai_nh,(Bering_mask .eq. 1.), True)
      HF_lat_ai_Bering = mask(HF_lat_ai_nh,(Bering_mask .eq. 1.), True)
      HF_surf_ai_Bering = mask(HF_surf_ai_nh,(Bering_mask .eq. 1.), True)
      HF_lwup_ai_Bering = mask(HF_lwup_ai_nh,(Bering_mask .eq. 1.), True)
      HF_lwdn_ai_Bering = mask(HF_lwdn_ai_nh,(Bering_mask .eq. 1.), True)
      HF_swdn_ai_Bering = mask(HF_swdn_ai_nh,(Bering_mask .eq. 1.), True)
      HF_lwdn_Bering = mask(HF_lwdn_nh,(Bering_mask .eq. 1.), True)
      HF_swdn_Bering = mask(HF_swdn_nh,(Bering_mask .eq. 1.), True)

      HF_sens_ai_Okhotsk = mask(HF_sens_ai_nh,(Okhotsk_mask .eq. 1.), True)
      HF_swabs_ai_Okhotsk = mask(HF_swabs_ai_nh,(Okhotsk_mask .eq. 1.), True)
      HF_lat_ai_Okhotsk = mask(HF_lat_ai_nh,(Okhotsk_mask .eq. 1.), True)
      HF_surf_ai_Okhotsk = mask(HF_surf_ai_nh,(Okhotsk_mask .eq. 1.), True)
      HF_lwup_ai_Okhotsk = mask(HF_lwup_ai_nh,(Okhotsk_mask .eq. 1.), True)
      HF_lwdn_ai_Okhotsk = mask(HF_lwdn_ai_nh,(Okhotsk_mask .eq. 1.), True)
      HF_swdn_ai_Okhotsk = mask(HF_swdn_ai_nh,(Okhotsk_mask .eq. 1.), True)
      HF_lwdn_Okhotsk = mask(HF_lwdn_nh,(Okhotsk_mask .eq. 1.), True)
      HF_swdn_Okhotsk = mask(HF_swdn_nh,(Okhotsk_mask .eq. 1.), True)

      HF_sens_ai_Hudson = mask(HF_sens_ai_nh,(Hudson_mask .eq. 1.), True)
      HF_swabs_ai_Hudson = mask(HF_swabs_ai_nh,(Hudson_mask .eq. 1.), True)
      HF_lat_ai_Hudson = mask(HF_lat_ai_nh,(Hudson_mask .eq. 1.), True)
      HF_surf_ai_Hudson = mask(HF_surf_ai_nh,(Hudson_mask .eq. 1.), True)
      HF_lwup_ai_Hudson = mask(HF_lwup_ai_nh,(Hudson_mask .eq. 1.), True)
      HF_lwdn_ai_Hudson = mask(HF_lwdn_ai_nh,(Hudson_mask .eq. 1.), True)
      HF_swdn_ai_Hudson = mask(HF_swdn_ai_nh,(Hudson_mask .eq. 1.), True)
      HF_lwdn_Hudson = mask(HF_lwdn_nh,(Hudson_mask .eq. 1.), True)
      HF_swdn_Hudson = mask(HF_swdn_nh,(Hudson_mask .eq. 1.), True)

      HF_sens_ai_CAArch = mask(HF_sens_ai_nh,(CAArch_mask .eq. 1.), True)
      HF_swabs_ai_CAArch = mask(HF_swabs_ai_nh,(CAArch_mask .eq. 1.), True)
      HF_lat_ai_CAArch = mask(HF_lat_ai_nh,(CAArch_mask .eq. 1.), True)
      HF_surf_ai_CAArch = mask(HF_surf_ai_nh,(CAArch_mask .eq. 1.), True)
      HF_lwup_ai_CAArch = mask(HF_lwup_ai_nh,(CAArch_mask .eq. 1.), True)
      HF_lwdn_ai_CAArch = mask(HF_lwdn_ai_nh,(CAArch_mask .eq. 1.), True)
      HF_swdn_ai_CAArch = mask(HF_swdn_ai_nh,(CAArch_mask .eq. 1.), True)
      HF_lwdn_CAArch = mask(HF_lwdn_nh,(CAArch_mask .eq. 1.), True)
      HF_swdn_CAArch = mask(HF_swdn_nh,(CAArch_mask .eq. 1.), True)

      HF_lwdn_sh50_90 = mask(HF_lwdn_sh,(tlat2_sh.ge.sh50_90_lat(0) .and. tlat2_sh.le.sh50_90_lat(1)),True)
      HF_swdn_sh50_90 = mask(HF_swdn_sh,(tlat2_sh.ge.sh50_90_lat(0) .and. tlat2_sh.le.sh50_90_lat(1)),True)

      HF_sens_ai_Wed = mask(HF_sens_ai_sh,(tlat2_sh.le.Wed_lat(1) .and. ((tlon2_sh.ge.Wed_long1(0) \
                  .and. tlon2_sh.le.Wed_long1(1)) .or. (tlon2_sh.ge.Wed_long2(0) \
                   .and. tlon2_sh.le.Wed_long2(1)))), True)
      HF_swabs_ai_Wed = mask(HF_swabs_ai_sh,(tlat2_sh.le.Wed_lat(1) .and.((tlon2_sh.ge.Wed_long1(0) \
                  .and. tlon2_sh.le.Wed_long1(1)) .or. (tlon2_sh.ge.Wed_long2(0) \
                  .and. tlon2_sh.le.Wed_long2(1)))), True)
      HF_lat_ai_Wed = mask(HF_lat_ai_sh,(tlat2_sh.le.Wed_lat(1) .and.((tlon2_sh.ge.Wed_long1(0) \
                  .and. tlon2_sh.le.Wed_long1(1)) .or. (tlon2_sh.ge.Wed_long2(0) \
                  .and. tlon2_sh.le.Wed_long2(1)))), True)
      HF_surf_ai_Wed = mask(HF_surf_ai_sh,(tlat2_sh.le.Wed_lat(1) .and.((tlon2_sh.ge.Wed_long1(0) \
                  .and. tlon2_sh.le.Wed_long1(1)) .or. (tlon2_sh.ge.Wed_long2(0) \
                  .and. tlon2_sh.le.Wed_long2(1)))), True)
      HF_lwup_ai_Wed = mask(HF_lwup_ai_sh,(tlat2_sh.le.Wed_lat(1) .and. ((tlon2_sh.ge.Wed_long1(0) \ 
                  .and. tlon2_sh.le.Wed_long1(1)) .or. (tlon2_sh.ge.Wed_long2(0) \
		  .and. tlon2_sh.le.Wed_long2(1)))), True)
      HF_lwdn_ai_Wed = mask(HF_lwdn_ai_sh,(tlat2_sh.le.Wed_lat(1) .and. ((tlon2_sh.ge.Wed_long1(0) \
                  .and. tlon2_sh.le.Wed_long1(1)) .or. (tlon2_sh.ge.Wed_long2(0) \
                  .and. tlon2_sh.le.Wed_long2(1)))), True)
      HF_swdn_ai_Wed = mask(HF_swdn_ai_sh,(tlat2_sh.le.Wed_lat(1) .and. ((tlon2_sh.ge.Wed_long1(0) \
                  .and. tlon2_sh.le.Wed_long1(1)) .or. (tlon2_sh.ge.Wed_long2(0) \
                  .and. tlon2_sh.le.Wed_long2(1)))), True)
      HF_lwdn_Wed = mask(HF_lwdn_sh,(tlat2_sh.le.Wed_lat(1) .and. ((tlon2_sh.ge.Wed_long1(0) \
                  .and. tlon2_sh.le.Wed_long1(1)) .or. (tlon2_sh.ge.Wed_long2(0) \
                  .and. tlon2_sh.le.Wed_long2(1)))), True)
      HF_swdn_Wed = mask(HF_swdn_sh,(tlat2_sh.le.Wed_lat(1) .and. ((tlon2_sh.ge.Wed_long1(0) \
                  .and. tlon2_sh.le.Wed_long1(1)) .or. (tlon2_sh.ge.Wed_long2(0) \
                  .and. tlon2_sh.le.Wed_long2(1)))), True)

      HF_sens_ai_Ross = mask(HF_sens_ai_sh,(tlat2_sh.le.Ross_lat(1) .and. tlon2_sh.ge.Ross_long(0) \
		   .and. tlon2_sh.le.Ross_long(1)), True)
      HF_swabs_ai_Ross = mask(HF_swabs_ai_sh,(tlat2_sh.le.Ross_lat(1) .and. tlon2_sh.ge.Ross_long(0) \
		   .and. tlon2_sh.le.Ross_long(1)), True)
      HF_lat_ai_Ross = mask(HF_lat_ai_sh,(tlat2_sh.le.Ross_lat(1) .and. tlon2_sh.ge.Ross_long(0) \
                   .and. tlon2_sh.le.Ross_long(1)), True)
      HF_surf_ai_Ross = mask(HF_surf_ai_sh,(tlat2_sh.le.Ross_lat(1) .and. tlon2_sh.ge.Ross_long(0) \
                   .and. tlon2_sh.le.Ross_long(1)), True)
      HF_lwup_ai_Ross = mask(HF_lwup_ai_sh,(tlat2_sh.le.Ross_lat(1) .and. tlon2_sh.ge.Ross_long(0) \
		   .and. tlon2_sh.le.Ross_long(1)), True)
      HF_lwdn_ai_Ross = mask(HF_lwdn_ai_sh,(tlat2_sh.le.Ross_lat(1) .and. tlon2_sh.ge.Ross_long(0) \
                   .and. tlon2_sh.le.Ross_long(1)), True)
      HF_swdn_ai_Ross = mask(HF_swdn_ai_sh,(tlat2_sh.le.Ross_lat(1) .and. tlon2_sh.ge.Ross_long(0) \
                   .and. tlon2_sh.le.Ross_long(1)), True)
      HF_lwdn_Ross = mask(HF_lwdn_sh,(tlat2_sh.le.Ross_lat(1) .and. tlon2_sh.ge.Ross_long(0) \
                   .and. tlon2_sh.le.Ross_long(1)), True)
      HF_swdn_Ross = mask(HF_swdn_sh,(tlat2_sh.le.Ross_lat(1) .and. tlon2_sh.ge.Ross_long(0) \
                   .and. tlon2_sh.le.Ross_long(1)), True)

      HF_sens_ai_Ind = mask(HF_sens_ai_sh,(tlat2_sh.le.Ind_lat(1) .and. tlon2_sh.ge.Ind_long(0) \
                   .and. tlon2_sh.le.Ind_long(1)), True)
      HF_swabs_ai_Ind = mask(HF_swabs_ai_sh,(tlat2_sh.le.Ind_lat(1) .and. tlon2_sh.ge.Ind_long(0) \
                   .and. tlon2_sh.le.Ind_long(1)), True)
      HF_lat_ai_Ind = mask(HF_lat_ai_sh,(tlat2_sh.le.Ind_lat(1) .and. tlon2_sh.ge.Ind_long(0) \
                   .and. tlon2_sh.le.Ind_long(1)), True)
      HF_surf_ai_Ind = mask(HF_surf_ai_sh,(tlat2_sh.le.Ind_lat(1) .and. tlon2_sh.ge.Ind_long(0) \
                   .and. tlon2_sh.le.Ind_long(1)), True)
      HF_lwup_ai_Ind = mask(HF_lwup_ai_sh,(tlat2_sh.le.Ind_lat(1) .and. tlon2_sh.ge.Ind_long(0) \
                   .and. tlon2_sh.le.Ind_long(1)), True)
      HF_lwdn_ai_Ind = mask(HF_lwdn_ai_sh,(tlat2_sh.le.Ind_lat(1) .and. tlon2_sh.ge.Ind_long(0) \
                   .and. tlon2_sh.le.Ind_long(1)), True)
      HF_swdn_ai_Ind = mask(HF_swdn_ai_sh,(tlat2_sh.le.Ind_lat(1) .and. tlon2_sh.ge.Ind_long(0) \
                   .and. tlon2_sh.le.Ind_long(1)), True)
      HF_lwdn_Ind = mask(HF_lwdn_sh,(tlat2_sh.le.Ind_lat(1) .and. tlon2_sh.ge.Ind_long(0) \
                   .and. tlon2_sh.le.Ind_long(1)), True)
      HF_swdn_Ind = mask(HF_swdn_sh,(tlat2_sh.le.Ind_lat(1) .and. tlon2_sh.ge.Ind_long(0) \
                   .and. tlon2_sh.le.Ind_long(1)), True)

      HF_sens_ai_Pac = mask(HF_sens_ai_sh,(tlat2_sh.le.Pac_lat(1) .and. tlon2_sh.ge.Pac_long(0) \
                   .and. tlon2_sh.le.Pac_long(1)), True)
      HF_swabs_ai_Pac = mask(HF_swabs_ai_sh,(tlat2_sh.le.Pac_lat(1) .and. tlon2_sh.ge.Pac_long(0) \
                   .and. tlon2_sh.le.Pac_long(1)), True)
      HF_lat_ai_Pac = mask(HF_lat_ai_sh,(tlat2_sh.le.Pac_lat(1) .and. tlon2_sh.ge.Pac_long(0) \
                   .and. tlon2_sh.le.Pac_long(1)), True)
      HF_surf_ai_Pac = mask(HF_surf_ai_sh,(tlat2_sh.le.Pac_lat(1) .and. tlon2_sh.ge.Pac_long(0) \
                   .and. tlon2_sh.le.Pac_long(1)), True)
      HF_lwup_ai_Pac = mask(HF_lwup_ai_sh,(tlat2_sh.le.Pac_lat(1) .and. tlon2_sh.ge.Pac_long(0) \
                   .and. tlon2_sh.le.Pac_long(1)), True)
      HF_lwdn_ai_Pac = mask(HF_lwdn_ai_sh,(tlat2_sh.le.Pac_lat(1) .and. tlon2_sh.ge.Pac_long(0) \
                   .and. tlon2_sh.le.Pac_long(1)), True)
      HF_swdn_ai_Pac = mask(HF_swdn_ai_sh,(tlat2_sh.le.Pac_lat(1) .and. tlon2_sh.ge.Pac_long(0) \
                   .and. tlon2_sh.le.Pac_long(1)), True)
      HF_lwdn_Pac = mask(HF_lwdn_sh,(tlat2_sh.le.Pac_lat(1) .and. tlon2_sh.ge.Pac_long(0) \
                   .and. tlon2_sh.le.Pac_long(1)), True)
      HF_swdn_Pac = mask(HF_swdn_sh,(tlat2_sh.le.Pac_lat(1) .and. tlon2_sh.ge.Pac_long(0) \
                   .and. tlon2_sh.le.Pac_long(1)), True)

      HF_sens_ai_BAm = mask(HF_sens_ai_sh,(tlat2_sh.le.BAm_lat(1) .and. tlon2_sh.ge.BAm_long(0) \
                   .and. tlon2_sh.le.BAm_long(1)), True)
      HF_swabs_ai_BAm = mask(HF_swabs_ai_sh,(tlat2_sh.le.BAm_lat(1) .and. tlon2_sh.ge.BAm_long(0) \
                   .and. tlon2_sh.le.BAm_long(1)), True)
      HF_lat_ai_BAm = mask(HF_lat_ai_sh,(tlat2_sh.le.BAm_lat(1) .and. tlon2_sh.ge.BAm_long(0) \
                   .and. tlon2_sh.le.BAm_long(1)), True)
      HF_surf_ai_BAm = mask(HF_surf_ai_sh,(tlat2_sh.le.BAm_lat(1) .and. tlon2_sh.ge.BAm_long(0) \
                   .and. tlon2_sh.le.BAm_long(1)), True)
      HF_lwup_ai_BAm = mask(HF_lwup_ai_sh,(tlat2_sh.le.BAm_lat(1) .and. tlon2_sh.ge.BAm_long(0) \
                   .and. tlon2_sh.le.BAm_long(1)), True)
      HF_lwdn_ai_BAm = mask(HF_lwdn_ai_sh,(tlat2_sh.le.BAm_lat(1) .and. tlon2_sh.ge.BAm_long(0) \
                   .and. tlon2_sh.le.BAm_long(1)), True)
      HF_swdn_ai_BAm = mask(HF_swdn_ai_sh,(tlat2_sh.le.BAm_lat(1) .and. tlon2_sh.ge.BAm_long(0) \
                   .and. tlon2_sh.le.BAm_long(1)), True)
      HF_lwdn_BAm = mask(HF_lwdn_sh,(tlat2_sh.le.BAm_lat(1) .and. tlon2_sh.ge.BAm_long(0) \
                   .and. tlon2_sh.le.BAm_long(1)), True)
      HF_swdn_BAm = mask(HF_swdn_sh,(tlat2_sh.le.BAm_lat(1) .and. tlon2_sh.ge.BAm_long(0) \
                   .and. tlon2_sh.le.BAm_long(1)), True)

;********************************
; northern hemisphere monthly ...
;********************************
      HF_lwdn_mo_nh50_90(imo1:imo2) = dim_sum(dim_sum(HF_lwdn_nh50_90))*1.0e-15
      HF_swdn_mo_nh50_90(imo1:imo2) = dim_sum(dim_sum(HF_swdn_nh50_90))*1.0e-15

      HF_lat_ai_mo_nh(imo1:imo2) = dim_sum(dim_sum(HF_lat_ai_nh))*1.0e-12 
      HF_surf_ai_mo_nh(imo1:imo2) = dim_sum(dim_sum(HF_surf_ai_nh))*1.0e-12
      HF_swabs_ai_mo_nh(imo1:imo2) = dim_sum(dim_sum(HF_swabs_ai_nh))*1.0e-12 
      HF_sens_ai_mo_nh(imo1:imo2) = dim_sum(dim_sum(HF_sens_ai_nh))*1.0e-12
      HF_lwup_ai_mo_nh(imo1:imo2) = dim_sum(dim_sum(HF_lwup_ai_nh))*1.0e-12 
      HF_lwdn_ai_mo_nh(imo1:imo2) = dim_sum(dim_sum(HF_lwdn_ai_nh))*1.0e-12
      HF_swdn_ai_mo_nh(imo1:imo2) = dim_sum(dim_sum(HF_swdn_ai_nh))*1.0e-12
      HF_lwdn_mo_nh(imo1:imo2) = dim_sum(dim_sum(HF_lwdn_nh))*1.0e-15
      HF_swdn_mo_nh(imo1:imo2) = dim_sum(dim_sum(HF_swdn_nh))*1.0e-15

      HF_lat_ai_mo_Lab(imo1:imo2) = dim_sum(dim_sum(HF_lat_ai_Lab))*1.0e-12 
      HF_surf_ai_mo_Lab(imo1:imo2) = dim_sum(dim_sum(HF_surf_ai_Lab))*1.0e-12
      HF_swabs_ai_mo_Lab(imo1:imo2) = dim_sum(dim_sum(HF_swabs_ai_Lab))*1.0e-12 
      HF_sens_ai_mo_Lab(imo1:imo2) = dim_sum(dim_sum(HF_sens_ai_Lab))*1.0e-12
      HF_lwup_ai_mo_Lab(imo1:imo2) = dim_sum(dim_sum(HF_lwup_ai_Lab))*1.0e-12
      HF_lwdn_ai_mo_Lab(imo1:imo2) = dim_sum(dim_sum(HF_lwdn_ai_Lab))*1.0e-12
      HF_swdn_ai_mo_Lab(imo1:imo2) = dim_sum(dim_sum(HF_swdn_ai_Lab))*1.0e-12
      HF_lwdn_mo_Lab(imo1:imo2) = dim_sum(dim_sum(HF_lwdn_Lab))*1.0e-15
      HF_swdn_mo_Lab(imo1:imo2) = dim_sum(dim_sum(HF_swdn_Lab))*1.0e-15
 
      HF_lat_ai_mo_GIN(imo1:imo2) = dim_sum(dim_sum(HF_lat_ai_GIN))*1.0e-12 
      HF_surf_ai_mo_GIN(imo1:imo2) = dim_sum(dim_sum(HF_surf_ai_GIN))*1.0e-12
      HF_swabs_ai_mo_GIN(imo1:imo2) = dim_sum(dim_sum(HF_swabs_ai_GIN))*1.0e-12 
      HF_sens_ai_mo_GIN(imo1:imo2) = dim_sum(dim_sum(HF_sens_ai_GIN))*1.0e-12
      HF_lwup_ai_mo_GIN(imo1:imo2) = dim_sum(dim_sum(HF_lwup_ai_GIN))*1.0e-12
      HF_lwdn_mo_GIN(imo1:imo2) = dim_sum(dim_sum(HF_lwdn_GIN))*1.0e-15
      HF_swdn_mo_GIN(imo1:imo2) = dim_sum(dim_sum(HF_swdn_GIN))*1.0e-15
      HF_lwdn_ai_mo_GIN(imo1:imo2) = dim_sum(dim_sum(HF_lwdn_ai_GIN))*1.0e-12
      HF_swdn_ai_mo_GIN(imo1:imo2) = dim_sum(dim_sum(HF_swdn_ai_GIN))*1.0e-12
 
      HF_lat_ai_mo_Bar(imo1:imo2) = dim_sum(dim_sum(HF_lat_ai_Bar))*1.0e-12 
      HF_surf_ai_mo_Bar(imo1:imo2) = dim_sum(dim_sum(HF_surf_ai_Bar))*1.0e-12
      HF_swabs_ai_mo_Bar(imo1:imo2) = dim_sum(dim_sum(HF_swabs_ai_Bar))*1.0e-12 
      HF_sens_ai_mo_Bar(imo1:imo2) = dim_sum(dim_sum(HF_sens_ai_Bar))*1.0e-12
      HF_lwup_ai_mo_Bar(imo1:imo2) = dim_sum(dim_sum(HF_lwup_ai_Bar))*1.0e-12
      HF_lwdn_ai_mo_Bar(imo1:imo2) = dim_sum(dim_sum(HF_lwdn_ai_Bar))*1.0e-12
      HF_swdn_ai_mo_Bar(imo1:imo2) = dim_sum(dim_sum(HF_swdn_ai_Bar))*1.0e-12
      HF_lwdn_mo_Bar(imo1:imo2) = dim_sum(dim_sum(HF_lwdn_Bar))*1.0e-15
      HF_swdn_mo_Bar(imo1:imo2) = dim_sum(dim_sum(HF_swdn_Bar))*1.0e-15
 
      HF_lat_ai_mo_ArcOc(imo1:imo2) = dim_sum(dim_sum(HF_lat_ai_ArcOc))*1.0e-12 
      HF_surf_ai_mo_ArcOc(imo1:imo2) = dim_sum(dim_sum(HF_surf_ai_ArcOc))*1.0e-12
      HF_swabs_ai_mo_ArcOc(imo1:imo2) = dim_sum(dim_sum(HF_swabs_ai_ArcOc))*1.0e-12 
      HF_sens_ai_mo_ArcOc(imo1:imo2) = dim_sum(dim_sum(HF_sens_ai_ArcOc))*1.0e-12
      HF_lwup_ai_mo_ArcOc(imo1:imo2) = dim_sum(dim_sum(HF_lwup_ai_ArcOc))*1.0e-12 
      HF_lwdn_ai_mo_ArcOc(imo1:imo2) = dim_sum(dim_sum(HF_lwdn_ai_ArcOc))*1.0e-12
      HF_swdn_ai_mo_ArcOc(imo1:imo2) = dim_sum(dim_sum(HF_swdn_ai_ArcOc))*1.0e-12
      HF_lwdn_mo_ArcOc(imo1:imo2) = dim_sum(dim_sum(HF_lwdn_ArcOc))*1.0e-15
      HF_swdn_mo_ArcOc(imo1:imo2) = dim_sum(dim_sum(HF_swdn_ArcOc))*1.0e-15

      HF_lat_ai_mo_Kara(imo1:imo2) = dim_sum(dim_sum(HF_lat_ai_Kara))*1.0e-12
      HF_surf_ai_mo_Kara(imo1:imo2) = dim_sum(dim_sum(HF_surf_ai_Kara))*1.0e-12
      HF_swabs_ai_mo_Kara(imo1:imo2) = dim_sum(dim_sum(HF_swabs_ai_Kara))*1.0e-12
      HF_sens_ai_mo_Kara(imo1:imo2) = dim_sum(dim_sum(HF_sens_ai_Kara))*1.0e-12
      HF_lwup_ai_mo_Kara(imo1:imo2) = dim_sum(dim_sum(HF_lwup_ai_Kara))*1.0e-12
      HF_lwdn_ai_mo_Kara(imo1:imo2) = dim_sum(dim_sum(HF_lwdn_ai_Kara))*1.0e-12
      HF_swdn_ai_mo_Kara(imo1:imo2) = dim_sum(dim_sum(HF_swdn_ai_Kara))*1.0e-12
      HF_lwdn_mo_Kara(imo1:imo2) = dim_sum(dim_sum(HF_lwdn_Kara))*1.0e-15
      HF_swdn_mo_Kara(imo1:imo2) = dim_sum(dim_sum(HF_swdn_Kara))*1.0e-15

      HF_lat_ai_mo_Laptev(imo1:imo2) = dim_sum(dim_sum(HF_lat_ai_Laptev))*1.0e-12
      HF_surf_ai_mo_Laptev(imo1:imo2) = dim_sum(dim_sum(HF_surf_ai_Laptev))*1.0e-12
      HF_swabs_ai_mo_Laptev(imo1:imo2) = dim_sum(dim_sum(HF_swabs_ai_Laptev))*1.0e-12
      HF_sens_ai_mo_Laptev(imo1:imo2) = dim_sum(dim_sum(HF_sens_ai_Laptev))*1.0e-12
      HF_lwup_ai_mo_Laptev(imo1:imo2) = dim_sum(dim_sum(HF_lwup_ai_Laptev))*1.0e-12
      HF_lwdn_ai_mo_Laptev(imo1:imo2) = dim_sum(dim_sum(HF_lwdn_ai_Laptev))*1.0e-12
      HF_swdn_ai_mo_Laptev(imo1:imo2) = dim_sum(dim_sum(HF_swdn_ai_Laptev))*1.0e-12
      HF_lwdn_mo_Laptev(imo1:imo2) = dim_sum(dim_sum(HF_lwdn_Laptev))*1.0e-15
      HF_swdn_mo_Laptev(imo1:imo2) = dim_sum(dim_sum(HF_swdn_Laptev))*1.0e-15

      HF_lat_ai_mo_Chukchi(imo1:imo2) = dim_sum(dim_sum(HF_lat_ai_Chukchi))*1.0e-12
      HF_surf_ai_mo_Chukchi(imo1:imo2) = dim_sum(dim_sum(HF_surf_ai_Chukchi))*1.0e-12
      HF_swabs_ai_mo_Chukchi(imo1:imo2) = dim_sum(dim_sum(HF_swabs_ai_Chukchi))*1.0e-12
      HF_sens_ai_mo_Chukchi(imo1:imo2) = dim_sum(dim_sum(HF_sens_ai_Chukchi))*1.0e-12
      HF_lwup_ai_mo_Chukchi(imo1:imo2) = dim_sum(dim_sum(HF_lwup_ai_Chukchi))*1.0e-12
      HF_lwdn_ai_mo_Chukchi(imo1:imo2) = dim_sum(dim_sum(HF_lwdn_ai_Chukchi))*1.0e-12
      HF_swdn_ai_mo_Chukchi(imo1:imo2) = dim_sum(dim_sum(HF_swdn_ai_Chukchi))*1.0e-12
      HF_lwdn_mo_Chukchi(imo1:imo2) = dim_sum(dim_sum(HF_lwdn_Chukchi))*1.0e-15
      HF_swdn_mo_Chukchi(imo1:imo2) = dim_sum(dim_sum(HF_swdn_Chukchi))*1.0e-15

      HF_lat_ai_mo_Sib(imo1:imo2) = dim_sum(dim_sum(HF_lat_ai_Sib))*1.0e-12 
      HF_surf_ai_mo_Sib(imo1:imo2) = dim_sum(dim_sum(HF_surf_ai_Sib))*1.0e-12
      HF_swabs_ai_mo_Sib(imo1:imo2) = dim_sum(dim_sum(HF_swabs_ai_Sib))*1.0e-12 
      HF_sens_ai_mo_Sib(imo1:imo2) = dim_sum(dim_sum(HF_sens_ai_Sib))*1.0e-12
      HF_lwup_ai_mo_Sib(imo1:imo2) = dim_sum(dim_sum(HF_lwup_ai_Sib))*1.0e-12 
      HF_lwdn_ai_mo_Sib(imo1:imo2) = dim_sum(dim_sum(HF_lwdn_ai_Sib))*1.0e-12
      HF_swdn_ai_mo_Sib(imo1:imo2) = dim_sum(dim_sum(HF_swdn_ai_Sib))*1.0e-12
      HF_lwdn_mo_Sib(imo1:imo2) = dim_sum(dim_sum(HF_lwdn_Sib))*1.0e-15
      HF_swdn_mo_Sib(imo1:imo2) = dim_sum(dim_sum(HF_swdn_Sib))*1.0e-15

      HF_lat_ai_mo_Beau(imo1:imo2) = dim_sum(dim_sum(HF_lat_ai_Beau))*1.0e-12 
      HF_surf_ai_mo_Beau(imo1:imo2) = dim_sum(dim_sum(HF_surf_ai_Beau))*1.0e-12
      HF_swabs_ai_mo_Beau(imo1:imo2) = dim_sum(dim_sum(HF_swabs_ai_Beau))*1.0e-12 
      HF_sens_ai_mo_Beau(imo1:imo2) = dim_sum(dim_sum(HF_sens_ai_Beau))*1.0e-12
      HF_lwup_ai_mo_Beau(imo1:imo2) = dim_sum(dim_sum(HF_lwup_ai_Beau))*1.0e-12
      HF_lwdn_ai_mo_Beau(imo1:imo2) = dim_sum(dim_sum(HF_lwdn_ai_Beau))*1.0e-12
      HF_swdn_ai_mo_Beau(imo1:imo2) = dim_sum(dim_sum(HF_swdn_ai_Beau))*1.0e-12
      HF_lwdn_mo_Beau(imo1:imo2) = dim_sum(dim_sum(HF_lwdn_Beau))*1.0e-15
      HF_swdn_mo_Beau(imo1:imo2) = dim_sum(dim_sum(HF_swdn_Beau))*1.0e-15
 
      HF_lat_ai_mo_CArc(imo1:imo2) = dim_sum(dim_sum(HF_lat_ai_CArc))*1.0e-12 
      HF_surf_ai_mo_CArc(imo1:imo2) = dim_sum(dim_sum(HF_surf_ai_CArc))*1.0e-12
      HF_swabs_ai_mo_CArc(imo1:imo2) = dim_sum(dim_sum(HF_swabs_ai_CArc))*1.0e-12 
      HF_sens_ai_mo_CArc(imo1:imo2) = dim_sum(dim_sum(HF_sens_ai_CArc))*1.0e-12
      HF_lwup_ai_mo_CArc(imo1:imo2) = dim_sum(dim_sum(HF_lwup_ai_CArc))*1.0e-12 
      HF_lwdn_ai_mo_CArc(imo1:imo2) = dim_sum(dim_sum(HF_lwdn_ai_CArc))*1.0e-12
      HF_swdn_ai_mo_CArc(imo1:imo2) = dim_sum(dim_sum(HF_swdn_ai_CArc))*1.0e-12
      HF_lwdn_mo_CArc(imo1:imo2) = dim_sum(dim_sum(HF_lwdn_CArc))*1.0e-15
      HF_swdn_mo_CArc(imo1:imo2) = dim_sum(dim_sum(HF_swdn_CArc))*1.0e-15

      HF_lat_ai_mo_Bering(imo1:imo2) = dim_sum(dim_sum(HF_lat_ai_Bering))*1.0e-12 
      HF_surf_ai_mo_Bering(imo1:imo2) = dim_sum(dim_sum(HF_surf_ai_Bering))*1.0e-12
      HF_swabs_ai_mo_Bering(imo1:imo2) = dim_sum(dim_sum(HF_swabs_ai_Bering))*1.0e-12 
      HF_sens_ai_mo_Bering(imo1:imo2) = dim_sum(dim_sum(HF_sens_ai_Bering))*1.0e-12
      HF_lwup_ai_mo_Bering(imo1:imo2) = dim_sum(dim_sum(HF_lwup_ai_Bering))*1.0e-12
      HF_lwdn_ai_mo_Bering(imo1:imo2) = dim_sum(dim_sum(HF_lwdn_ai_Bering))*1.0e-12
      HF_swdn_ai_mo_Bering(imo1:imo2) = dim_sum(dim_sum(HF_swdn_ai_Bering))*1.0e-12
      HF_lwdn_mo_Bering(imo1:imo2) = dim_sum(dim_sum(HF_lwdn_Bering))*1.0e-15
      HF_swdn_mo_Bering(imo1:imo2) = dim_sum(dim_sum(HF_swdn_Bering))*1.0e-15

      HF_lat_ai_mo_Okhotsk(imo1:imo2) = dim_sum(dim_sum(HF_lat_ai_Okhotsk))*1.0e-12 
      HF_surf_ai_mo_Okhotsk(imo1:imo2) = dim_sum(dim_sum(HF_surf_ai_Okhotsk))*1.0e-12
      HF_swabs_ai_mo_Okhotsk(imo1:imo2) = dim_sum(dim_sum(HF_swabs_ai_Okhotsk))*1.0e-12 
      HF_sens_ai_mo_Okhotsk(imo1:imo2) = dim_sum(dim_sum(HF_sens_ai_Okhotsk))*1.0e-12
      HF_lwup_ai_mo_Okhotsk(imo1:imo2) = dim_sum(dim_sum(HF_lwup_ai_Okhotsk))*1.0e-12
      HF_lwdn_ai_mo_Okhotsk(imo1:imo2) = dim_sum(dim_sum(HF_lwdn_ai_Okhotsk))*1.0e-12
      HF_swdn_ai_mo_Okhotsk(imo1:imo2) = dim_sum(dim_sum(HF_swdn_ai_Okhotsk))*1.0e-12
      HF_lwdn_mo_Okhotsk(imo1:imo2) = dim_sum(dim_sum(HF_lwdn_Okhotsk))*1.0e-15
      HF_swdn_mo_Okhotsk(imo1:imo2) = dim_sum(dim_sum(HF_swdn_Okhotsk))*1.0e-15

      HF_lat_ai_mo_Hudson(imo1:imo2) = dim_sum(dim_sum(HF_lat_ai_Hudson))*1.0e-12 
      HF_surf_ai_mo_Hudson(imo1:imo2) = dim_sum(dim_sum(HF_surf_ai_Hudson))*1.0e-12
      HF_swabs_ai_mo_Hudson(imo1:imo2) = dim_sum(dim_sum(HF_swabs_ai_Hudson))*1.0e-12 
      HF_sens_ai_mo_Hudson(imo1:imo2) = dim_sum(dim_sum(HF_sens_ai_Hudson))*1.0e-12
      HF_lwup_ai_mo_Hudson(imo1:imo2) = dim_sum(dim_sum(HF_lwup_ai_Hudson))*1.0e-12
      HF_lwdn_ai_mo_Hudson(imo1:imo2) = dim_sum(dim_sum(HF_lwdn_ai_Hudson))*1.0e-12
      HF_swdn_ai_mo_Hudson(imo1:imo2) = dim_sum(dim_sum(HF_swdn_ai_Hudson))*1.0e-12
      HF_lwdn_mo_Hudson(imo1:imo2) = dim_sum(dim_sum(HF_lwdn_Hudson))*1.0e-15
      HF_swdn_mo_Hudson(imo1:imo2) = dim_sum(dim_sum(HF_swdn_Hudson))*1.0e-15

      HF_lat_ai_mo_CAArch(imo1:imo2) = dim_sum(dim_sum(HF_lat_ai_CAArch))*1.0e-12 
      HF_surf_ai_mo_CAArch(imo1:imo2) = dim_sum(dim_sum(HF_surf_ai_CAArch))*1.0e-12
      HF_swabs_ai_mo_CAArch(imo1:imo2) = dim_sum(dim_sum(HF_swabs_ai_CAArch))*1.0e-12
      HF_sens_ai_mo_CAArch(imo1:imo2) = dim_sum(dim_sum(HF_sens_ai_CAArch))*1.0e-12
      HF_lwup_ai_mo_CAArch(imo1:imo2) = dim_sum(dim_sum(HF_lwup_ai_CAArch))*1.0e-12
      HF_lwdn_ai_mo_CAArch(imo1:imo2) = dim_sum(dim_sum(HF_lwdn_ai_CAArch))*1.0e-12
      HF_swdn_ai_mo_CAArch(imo1:imo2) = dim_sum(dim_sum(HF_swdn_ai_CAArch))*1.0e-12
      HF_lwdn_mo_CAArch(imo1:imo2) = dim_sum(dim_sum(HF_lwdn_CAArch))*1.0e-15
      HF_swdn_mo_CAArch(imo1:imo2) = dim_sum(dim_sum(HF_swdn_CAArch))*1.0e-15
;********************************
; southern hemisphere monthly ...
;********************************
      HF_lwdn_mo_sh50_90(imo1:imo2) = dim_sum(dim_sum(HF_lwdn_sh50_90))*1.0e-15
      HF_swdn_mo_sh50_90(imo1:imo2) = dim_sum(dim_sum(HF_swdn_sh50_90))*1.0e-15

      HF_lat_ai_mo_sh(imo1:imo2) = dim_sum(dim_sum(HF_lat_ai_sh))*1.0e-12 
      HF_surf_ai_mo_sh(imo1:imo2) = dim_sum(dim_sum(HF_surf_ai_sh))*1.0e-12
      HF_swabs_ai_mo_sh(imo1:imo2) = dim_sum(dim_sum(HF_swabs_ai_sh))*1.0e-12 
      HF_sens_ai_mo_sh(imo1:imo2) = dim_sum(dim_sum(HF_sens_ai_sh))*1.0e-12
      HF_lwup_ai_mo_sh(imo1:imo2) = dim_sum(dim_sum(HF_lwup_ai_sh))*1.0e-12 
      HF_lwdn_ai_mo_sh(imo1:imo2) = dim_sum(dim_sum(HF_lwdn_ai_sh))*1.0e-12
      HF_swdn_ai_mo_sh(imo1:imo2) = dim_sum(dim_sum(HF_swdn_ai_sh))*1.0e-12
      HF_lwdn_mo_sh(imo1:imo2) = dim_sum(dim_sum(HF_lwdn_sh))*1.0e-15
      HF_swdn_mo_sh(imo1:imo2) = dim_sum(dim_sum(HF_swdn_sh))*1.0e-15

      HF_lat_ai_mo_Wed(imo1:imo2) = dim_sum(dim_sum(HF_lat_ai_Wed))*1.0e-12 
      HF_surf_ai_mo_Wed(imo1:imo2) = dim_sum(dim_sum(HF_surf_ai_Wed))*1.0e-12
      HF_swabs_ai_mo_Wed(imo1:imo2) = dim_sum(dim_sum(HF_swabs_ai_Wed))*1.0e-12 
      HF_sens_ai_mo_Wed(imo1:imo2) = dim_sum(dim_sum(HF_sens_ai_Wed))*1.0e-12
      HF_lwup_ai_mo_Wed(imo1:imo2) = dim_sum(dim_sum(HF_lwup_ai_Wed))*1.0e-12
      HF_lwdn_ai_mo_Wed(imo1:imo2) = dim_sum(dim_sum(HF_lwdn_ai_Wed))*1.0e-12
      HF_swdn_ai_mo_Wed(imo1:imo2) = dim_sum(dim_sum(HF_swdn_ai_Wed))*1.0e-12
      HF_lwdn_mo_Wed(imo1:imo2) = dim_sum(dim_sum(HF_lwdn_Wed))*1.0e-15
      HF_swdn_mo_Wed(imo1:imo2) = dim_sum(dim_sum(HF_swdn_Wed))*1.0e-15

      HF_lat_ai_mo_Ross(imo1:imo2) = dim_sum(dim_sum(HF_lat_ai_Ross))*1.0e-12 
      HF_surf_ai_mo_Ross(imo1:imo2) = dim_sum(dim_sum(HF_surf_ai_Ross))*1.0e-12
      HF_swabs_ai_mo_Ross(imo1:imo2) = dim_sum(dim_sum(HF_swabs_ai_Ross))*1.0e-12 
      HF_sens_ai_mo_Ross(imo1:imo2) = dim_sum(dim_sum(HF_sens_ai_Ross))*1.0e-12
      HF_lwup_ai_mo_Ross(imo1:imo2) = dim_sum(dim_sum(HF_lwup_ai_Ross))*1.0e-12
      HF_lwdn_ai_mo_Ross(imo1:imo2) = dim_sum(dim_sum(HF_lwdn_ai_Ross))*1.0e-12
      HF_swdn_ai_mo_Ross(imo1:imo2) = dim_sum(dim_sum(HF_swdn_ai_Ross))*1.0e-12
      HF_lwdn_mo_Ross(imo1:imo2) = dim_sum(dim_sum(HF_lwdn_Ross))*1.0e-15
      HF_swdn_mo_Ross(imo1:imo2) = dim_sum(dim_sum(HF_swdn_Ross))*1.0e-15

      HF_lat_ai_mo_Ind(imo1:imo2) = dim_sum(dim_sum(HF_lat_ai_Ind))*1.0e-12 
      HF_surf_ai_mo_Ind(imo1:imo2) = dim_sum(dim_sum(HF_surf_ai_Ind))*1.0e-12
      HF_swabs_ai_mo_Ind(imo1:imo2) = dim_sum(dim_sum(HF_swabs_ai_Ind))*1.0e-12 
      HF_sens_ai_mo_Ind(imo1:imo2) = dim_sum(dim_sum(HF_sens_ai_Ind))*1.0e-12
      HF_lwup_ai_mo_Ind(imo1:imo2) = dim_sum(dim_sum(HF_lwup_ai_Ind))*1.0e-12
      HF_lwdn_ai_mo_Ind(imo1:imo2) = dim_sum(dim_sum(HF_lwdn_ai_Ind))*1.0e-12
      HF_swdn_ai_mo_Ind(imo1:imo2) = dim_sum(dim_sum(HF_swdn_ai_Ind))*1.0e-12
      HF_lwdn_mo_Ind(imo1:imo2) = dim_sum(dim_sum(HF_lwdn_Ind))*1.0e-15
      HF_swdn_mo_Ind(imo1:imo2) = dim_sum(dim_sum(HF_swdn_Ind))*1.0e-15

      HF_lat_ai_mo_Pac(imo1:imo2) = dim_sum(dim_sum(HF_lat_ai_Pac))*1.0e-12 
      HF_surf_ai_mo_Pac(imo1:imo2) = dim_sum(dim_sum(HF_surf_ai_Pac))*1.0e-12
      HF_swabs_ai_mo_Pac(imo1:imo2) = dim_sum(dim_sum(HF_swabs_ai_Pac))*1.0e-12 
      HF_sens_ai_mo_Pac(imo1:imo2) = dim_sum(dim_sum(HF_sens_ai_Pac))*1.0e-12
      HF_lwup_ai_mo_Pac(imo1:imo2) = dim_sum(dim_sum(HF_lwup_ai_Pac))*1.0e-12
      HF_lwdn_ai_mo_Pac(imo1:imo2) = dim_sum(dim_sum(HF_lwdn_ai_Pac))*1.0e-12
      HF_swdn_ai_mo_Pac(imo1:imo2) = dim_sum(dim_sum(HF_swdn_ai_Pac))*1.0e-12
      HF_lwdn_mo_Pac(imo1:imo2) = dim_sum(dim_sum(HF_lwdn_Pac))*1.0e-15
      HF_swdn_mo_Pac(imo1:imo2) = dim_sum(dim_sum(HF_swdn_Pac))*1.0e-15

      HF_lat_ai_mo_BAm(imo1:imo2) = dim_sum(dim_sum(HF_lat_ai_BAm))*1.0e-12 
      HF_surf_ai_mo_BAm(imo1:imo2) = dim_sum(dim_sum(HF_surf_ai_BAm))*1.0e-12
      HF_swabs_ai_mo_BAm(imo1:imo2) = dim_sum(dim_sum(HF_swabs_ai_BAm))*1.0e-12 
      HF_sens_ai_mo_BAm(imo1:imo2) = dim_sum(dim_sum(HF_sens_ai_BAm))*1.0e-12
      HF_lwup_ai_mo_BAm(imo1:imo2) = dim_sum(dim_sum(HF_lwup_ai_BAm))*1.0e-12
      HF_lwdn_ai_mo_BAm(imo1:imo2) = dim_sum(dim_sum(HF_lwdn_ai_BAm))*1.0e-12
      HF_swdn_ai_mo_BAm(imo1:imo2) = dim_sum(dim_sum(HF_swdn_ai_BAm))*1.0e-12
      HF_lwdn_mo_BAm(imo1:imo2) = dim_sum(dim_sum(HF_lwdn_BAm))*1.0e-15
      HF_swdn_mo_BAm(imo1:imo2) = dim_sum(dim_sum(HF_swdn_BAm))*1.0e-15
   end do ; nn

   HF_swabs_ai_mo_nh!0 = "time"
   HF_swabs_ai_mo_nh&time = time
   HF_swabs_ai_mo_nh@units = "1.E+12 W"
   HF_swabs_ai_mo_nh@coordinates = "time"
   HF_swabs_ai_mo_nh@missing_value = 1.e+30
   HF_swabs_ai_mo_nh@_FillValue = 1.e+30
   HF_swabs_ai_mo_nh@cell_methods = "time:mean"

   HF_lwdn_mo_nh!0 = "time"
   HF_lwdn_mo_nh&time = time
   HF_lwdn_mo_nh@units = "1.E+15 W"
   HF_lwdn_mo_nh@coordinates = "time"
   HF_lwdn_mo_nh@missing_value = 1.e+30
   HF_lwdn_mo_nh@_FillValue = 1.e+30
   HF_lwdn_mo_nh@cell_methods = "time:mean"

   copy_VarMeta(HF_swabs_ai_mo_nh,HF_sens_ai_mo_nh)
   copy_VarMeta(HF_swabs_ai_mo_nh,HF_lat_ai_mo_nh)
   copy_VarMeta(HF_swabs_ai_mo_nh,HF_surf_ai_mo_nh)
   copy_VarMeta(HF_swabs_ai_mo_nh,HF_lwup_ai_mo_nh)
   copy_VarMeta(HF_swabs_ai_mo_nh,HF_lwdn_ai_mo_nh)
   copy_VarMeta(HF_swabs_ai_mo_nh,HF_swdn_ai_mo_nh)

   copy_VarMeta(HF_lwdn_mo_nh,HF_swdn_mo_nh)
   copy_VarMeta(HF_lwdn_mo_nh,HF_lwdn_mo_nh50_90)
   copy_VarMeta(HF_lwdn_mo_nh,HF_swdn_mo_nh50_90)

   copy_VarMeta(HF_swabs_ai_mo_nh,HF_swabs_ai_mo_Lab)
   copy_VarMeta(HF_lat_ai_mo_nh,HF_lat_ai_mo_Lab)
   copy_VarMeta(HF_surf_ai_mo_nh,HF_surf_ai_mo_Lab)
   copy_VarMeta(HF_sens_ai_mo_nh,HF_sens_ai_mo_Lab)
   copy_VarMeta(HF_lwup_ai_mo_nh,HF_lwup_ai_mo_Lab)
   copy_VarMeta(HF_lwdn_ai_mo_nh,HF_lwdn_ai_mo_Lab)
   copy_VarMeta(HF_swdn_ai_mo_nh,HF_swdn_ai_mo_Lab)
   copy_VarMeta(HF_lwdn_mo_nh,HF_lwdn_mo_Lab)
   copy_VarMeta(HF_lwdn_mo_nh,HF_swdn_mo_Lab)

   copy_VarMeta(HF_swabs_ai_mo_nh,HF_swabs_ai_mo_GIN)
   copy_VarMeta(HF_sens_ai_mo_nh,HF_sens_ai_mo_GIN)
   copy_VarMeta(HF_lat_ai_mo_nh,HF_lat_ai_mo_GIN)
   copy_VarMeta(HF_surf_ai_mo_nh,HF_surf_ai_mo_GIN)
   copy_VarMeta(HF_lwup_ai_mo_nh,HF_lwup_ai_mo_GIN)
   copy_VarMeta(HF_lwdn_ai_mo_nh,HF_lwdn_ai_mo_GIN)
   copy_VarMeta(HF_swdn_ai_mo_nh,HF_swdn_ai_mo_GIN)
   copy_VarMeta(HF_lwdn_mo_nh,HF_lwdn_mo_GIN)
   copy_VarMeta(HF_lwdn_mo_nh,HF_swdn_mo_GIN)

   copy_VarMeta(HF_swabs_ai_mo_nh,HF_swabs_ai_mo_Bar)
   copy_VarMeta(HF_sens_ai_mo_nh,HF_sens_ai_mo_Bar)
   copy_VarMeta(HF_lat_ai_mo_nh,HF_lat_ai_mo_Bar)
   copy_VarMeta(HF_surf_ai_mo_nh,HF_surf_ai_mo_Bar)
   copy_VarMeta(HF_lwup_ai_mo_nh,HF_lwup_ai_mo_Bar)
   copy_VarMeta(HF_lwdn_ai_mo_nh,HF_lwdn_ai_mo_Bar)
   copy_VarMeta(HF_swdn_ai_mo_nh,HF_swdn_ai_mo_Bar)
   copy_VarMeta(HF_lwdn_mo_nh,HF_lwdn_mo_Bar)
   copy_VarMeta(HF_lwdn_mo_nh,HF_swdn_mo_Bar)

   copy_VarMeta(HF_swabs_ai_mo_nh,HF_swabs_ai_mo_ArcOc)
   copy_VarMeta(HF_sens_ai_mo_nh,HF_sens_ai_mo_ArcOc)
   copy_VarMeta(HF_lat_ai_mo_nh,HF_lat_ai_mo_ArcOc)
   copy_VarMeta(HF_surf_ai_mo_nh,HF_surf_ai_mo_ArcOc)
   copy_VarMeta(HF_lwup_ai_mo_nh,HF_lwup_ai_mo_ArcOc)
   copy_VarMeta(HF_lwdn_ai_mo_nh,HF_lwdn_ai_mo_ArcOc)
   copy_VarMeta(HF_swdn_ai_mo_nh,HF_swdn_ai_mo_ArcOc)
   copy_VarMeta(HF_lwdn_mo_nh,HF_lwdn_mo_ArcOc)
   copy_VarMeta(HF_lwdn_mo_nh,HF_swdn_mo_ArcOc)

   copy_VarMeta(HF_swabs_ai_mo_nh,HF_swabs_ai_mo_Kara)
   copy_VarMeta(HF_sens_ai_mo_nh,HF_sens_ai_mo_Kara)
   copy_VarMeta(HF_lat_ai_mo_nh,HF_lat_ai_mo_Kara)
   copy_VarMeta(HF_surf_ai_mo_nh,HF_surf_ai_mo_Kara)
   copy_VarMeta(HF_lwup_ai_mo_nh,HF_lwup_ai_mo_Kara)
   copy_VarMeta(HF_lwdn_ai_mo_nh,HF_lwdn_ai_mo_Kara)
   copy_VarMeta(HF_swdn_ai_mo_nh,HF_swdn_ai_mo_Kara)
   copy_VarMeta(HF_lwdn_mo_nh,HF_lwdn_mo_Kara)
   copy_VarMeta(HF_lwdn_mo_nh,HF_swdn_mo_Kara)

   copy_VarMeta(HF_swabs_ai_mo_nh,HF_swabs_ai_mo_Laptev)
   copy_VarMeta(HF_sens_ai_mo_nh,HF_sens_ai_mo_Laptev)
   copy_VarMeta(HF_lat_ai_mo_nh,HF_lat_ai_mo_Laptev)
   copy_VarMeta(HF_surf_ai_mo_nh,HF_surf_ai_mo_Laptev)
   copy_VarMeta(HF_lwup_ai_mo_nh,HF_lwup_ai_mo_Laptev)
   copy_VarMeta(HF_lwdn_mo_nh,HF_lwdn_mo_Laptev)
   copy_VarMeta(HF_lwdn_mo_nh,HF_swdn_mo_Laptev)
   copy_VarMeta(HF_lwdn_ai_mo_nh,HF_lwdn_ai_mo_Laptev)
   copy_VarMeta(HF_swdn_ai_mo_nh,HF_swdn_ai_mo_Laptev)

   copy_VarMeta(HF_swabs_ai_mo_nh,HF_swabs_ai_mo_Chukchi)
   copy_VarMeta(HF_sens_ai_mo_nh,HF_sens_ai_mo_Chukchi)
   copy_VarMeta(HF_lat_ai_mo_nh,HF_lat_ai_mo_Chukchi)
   copy_VarMeta(HF_surf_ai_mo_nh,HF_surf_ai_mo_Chukchi)
   copy_VarMeta(HF_lwup_ai_mo_nh,HF_lwup_ai_mo_Chukchi)
   copy_VarMeta(HF_lwdn_ai_mo_nh,HF_lwdn_ai_mo_Chukchi)
   copy_VarMeta(HF_swdn_ai_mo_nh,HF_swdn_ai_mo_Chukchi)
   copy_VarMeta(HF_lwdn_mo_nh,HF_lwdn_mo_Chukchi)
   copy_VarMeta(HF_lwdn_mo_nh,HF_swdn_mo_Chukchi)

   copy_VarMeta(HF_swabs_ai_mo_nh,HF_swabs_ai_mo_Sib)
   copy_VarMeta(HF_sens_ai_mo_nh,HF_sens_ai_mo_Sib)
   copy_VarMeta(HF_lat_ai_mo_nh,HF_lat_ai_mo_Sib)
   copy_VarMeta(HF_surf_ai_mo_nh,HF_surf_ai_mo_Sib)
   copy_VarMeta(HF_lwup_ai_mo_nh,HF_lwup_ai_mo_Sib)
   copy_VarMeta(HF_lwdn_ai_mo_nh,HF_lwdn_ai_mo_Sib)
   copy_VarMeta(HF_swdn_ai_mo_nh,HF_swdn_ai_mo_Sib)
   copy_VarMeta(HF_lwdn_mo_nh,HF_lwdn_mo_Sib)
   copy_VarMeta(HF_lwdn_mo_nh,HF_swdn_mo_Sib)

   copy_VarMeta(HF_swabs_ai_mo_nh,HF_swabs_ai_mo_Beau)
   copy_VarMeta(HF_sens_ai_mo_nh,HF_sens_ai_mo_Beau)
   copy_VarMeta(HF_lat_ai_mo_nh,HF_lat_ai_mo_Beau)
   copy_VarMeta(HF_surf_ai_mo_nh,HF_surf_ai_mo_Beau)
   copy_VarMeta(HF_lwup_ai_mo_nh,HF_lwup_ai_mo_Beau)
   copy_VarMeta(HF_lwdn_ai_mo_nh,HF_lwdn_ai_mo_Beau)
   copy_VarMeta(HF_swdn_ai_mo_nh,HF_swdn_ai_mo_Beau)
   copy_VarMeta(HF_lwdn_mo_nh,HF_lwdn_mo_Beau)
   copy_VarMeta(HF_lwdn_mo_nh,HF_swdn_mo_Beau)

   copy_VarMeta(HF_swabs_ai_mo_nh,HF_swabs_ai_mo_CArc)
   copy_VarMeta(HF_sens_ai_mo_nh,HF_sens_ai_mo_CArc)
   copy_VarMeta(HF_lat_ai_mo_nh,HF_lat_ai_mo_CArc)
   copy_VarMeta(HF_surf_ai_mo_nh,HF_surf_ai_mo_CArc)
   copy_VarMeta(HF_lwup_ai_mo_nh,HF_lwup_ai_mo_CArc)
   copy_VarMeta(HF_lwdn_ai_mo_nh,HF_lwdn_ai_mo_CArc)
   copy_VarMeta(HF_swdn_ai_mo_nh,HF_swdn_ai_mo_CArc)
   copy_VarMeta(HF_lwdn_mo_nh,HF_lwdn_mo_CArc)
   copy_VarMeta(HF_lwdn_mo_nh,HF_swdn_mo_CArc)

   copy_VarMeta(HF_swabs_ai_mo_nh,HF_swabs_ai_mo_Bering)
   copy_VarMeta(HF_sens_ai_mo_nh,HF_sens_ai_mo_Bering)
   copy_VarMeta(HF_lat_ai_mo_nh,HF_lat_ai_mo_Bering)
   copy_VarMeta(HF_surf_ai_mo_nh,HF_surf_ai_mo_Bering)
   copy_VarMeta(HF_lwup_ai_mo_nh,HF_lwup_ai_mo_Bering)
   copy_VarMeta(HF_lwdn_ai_mo_nh,HF_lwdn_ai_mo_Bering)
   copy_VarMeta(HF_swdn_ai_mo_nh,HF_swdn_ai_mo_Bering)
   copy_VarMeta(HF_lwdn_mo_nh,HF_lwdn_mo_Bering)
   copy_VarMeta(HF_lwdn_mo_nh,HF_swdn_mo_Bering)

   copy_VarMeta(HF_swabs_ai_mo_nh,HF_swabs_ai_mo_Okhotsk)
   copy_VarMeta(HF_sens_ai_mo_nh,HF_sens_ai_mo_Okhotsk)
   copy_VarMeta(HF_lat_ai_mo_nh,HF_lat_ai_mo_Okhotsk)
   copy_VarMeta(HF_surf_ai_mo_nh,HF_surf_ai_mo_Okhotsk)
   copy_VarMeta(HF_lwup_ai_mo_nh,HF_lwup_ai_mo_Okhotsk)
   copy_VarMeta(HF_lwdn_ai_mo_nh,HF_lwdn_ai_mo_Okhotsk)
   copy_VarMeta(HF_swdn_ai_mo_nh,HF_swdn_ai_mo_Okhotsk)
   copy_VarMeta(HF_lwdn_mo_nh,HF_lwdn_mo_Okhotsk)
   copy_VarMeta(HF_lwdn_mo_nh,HF_swdn_mo_Okhotsk)

   copy_VarMeta(HF_swabs_ai_mo_nh,HF_swabs_ai_mo_Hudson)
   copy_VarMeta(HF_sens_ai_mo_nh,HF_sens_ai_mo_Hudson)
   copy_VarMeta(HF_lat_ai_mo_nh,HF_lat_ai_mo_Hudson)
   copy_VarMeta(HF_surf_ai_mo_nh,HF_surf_ai_mo_Hudson)
   copy_VarMeta(HF_lwup_ai_mo_nh,HF_lwup_ai_mo_Hudson)
   copy_VarMeta(HF_lwdn_ai_mo_nh,HF_lwdn_ai_mo_Hudson)
   copy_VarMeta(HF_swdn_ai_mo_nh,HF_swdn_ai_mo_Hudson)
   copy_VarMeta(HF_lwdn_mo_nh,HF_lwdn_mo_Hudson)
   copy_VarMeta(HF_lwdn_mo_nh,HF_swdn_mo_Hudson)

   copy_VarMeta(HF_swabs_ai_mo_nh,HF_swabs_ai_mo_CAArch)
   copy_VarMeta(HF_sens_ai_mo_nh,HF_sens_ai_mo_CAArch)
   copy_VarMeta(HF_lat_ai_mo_nh,HF_lat_ai_mo_CAArch)
   copy_VarMeta(HF_surf_ai_mo_nh,HF_surf_ai_mo_CAArch)
   copy_VarMeta(HF_lwup_ai_mo_nh,HF_lwup_ai_mo_CAArch)
   copy_VarMeta(HF_lwdn_ai_mo_nh,HF_lwdn_ai_mo_CAArch)
   copy_VarMeta(HF_swdn_ai_mo_nh,HF_swdn_ai_mo_CAArch)
   copy_VarMeta(HF_lwdn_mo_nh,HF_lwdn_mo_CAArch)
   copy_VarMeta(HF_lwdn_mo_nh,HF_swdn_mo_CAArch)

   HF_swabs_ai_mo_sh!0 = "time"
   HF_swabs_ai_mo_sh&time = time
   HF_swabs_ai_mo_sh@units = "1.E+12 W"
   HF_swabs_ai_mo_sh@coordinates = "time"
   HF_swabs_ai_mo_sh@missing_value = 1.e+30
   HF_swabs_ai_mo_sh@_FillValue = 1.e+30
   HF_swabs_ai_mo_sh@cell_methods = "time:mean"

   HF_lwdn_mo_sh!0 = "time"
   HF_lwdn_mo_sh&time = time
   HF_lwdn_mo_sh@units = "1.E+15 W"
   HF_lwdn_mo_sh@coordinates = "time"
   HF_lwdn_mo_sh@missing_value = 1.e+30
   HF_lwdn_mo_sh@_FillValue = 1.e+30
   HF_lwdn_mo_sh@cell_methods = "time:mean"

   copy_VarMeta(HF_swabs_ai_mo_sh,HF_sens_ai_mo_sh)
   copy_VarMeta(HF_swabs_ai_mo_sh,HF_lat_ai_mo_sh)
   copy_VarMeta(HF_swabs_ai_mo_sh,HF_surf_ai_mo_sh)
   copy_VarMeta(HF_swabs_ai_mo_sh,HF_lwup_ai_mo_sh)
   copy_VarMeta(HF_swabs_ai_mo_sh,HF_lwdn_ai_mo_sh)
   copy_VarMeta(HF_swabs_ai_mo_sh,HF_swdn_ai_mo_sh)
   copy_VarMeta(HF_lwdn_mo_sh,HF_swdn_mo_sh)
   copy_VarMeta(HF_lwdn_mo_sh,HF_lwdn_mo_sh50_90)
   copy_VarMeta(HF_lwdn_mo_sh,HF_swdn_mo_sh50_90)

   copy_VarMeta(HF_swabs_ai_mo_sh,HF_swabs_ai_mo_Wed)
   copy_VarMeta(HF_sens_ai_mo_sh,HF_sens_ai_mo_Wed)
   copy_VarMeta(HF_lat_ai_mo_sh,HF_lat_ai_mo_Wed)
   copy_VarMeta(HF_surf_ai_mo_sh,HF_surf_ai_mo_Wed)
   copy_VarMeta(HF_lwup_ai_mo_sh,HF_lwup_ai_mo_Wed)
   copy_VarMeta(HF_lwdn_ai_mo_sh,HF_lwdn_ai_mo_Wed)
   copy_VarMeta(HF_swdn_ai_mo_sh,HF_swdn_ai_mo_Wed)
   copy_VarMeta(HF_lwdn_mo_sh,HF_lwdn_mo_Wed)
   copy_VarMeta(HF_lwdn_mo_sh,HF_swdn_mo_Wed)

   copy_VarMeta(HF_swabs_ai_mo_sh,HF_swabs_ai_mo_Ross)
   copy_VarMeta(HF_sens_ai_mo_sh,HF_sens_ai_mo_Ross)
   copy_VarMeta(HF_lat_ai_mo_sh,HF_lat_ai_mo_Ross)
   copy_VarMeta(HF_surf_ai_mo_sh,HF_surf_ai_mo_Ross)
   copy_VarMeta(HF_lwup_ai_mo_sh,HF_lwup_ai_mo_Ross)
   copy_VarMeta(HF_lwdn_ai_mo_sh,HF_lwdn_ai_mo_Ross)
   copy_VarMeta(HF_swdn_ai_mo_sh,HF_swdn_ai_mo_Ross)
   copy_VarMeta(HF_lwdn_mo_sh,HF_lwdn_mo_Ross)
   copy_VarMeta(HF_lwdn_mo_sh,HF_swdn_mo_Ross)

   copy_VarMeta(HF_swabs_ai_mo_sh,HF_swabs_ai_mo_Ind)
   copy_VarMeta(HF_sens_ai_mo_sh,HF_sens_ai_mo_Ind)
   copy_VarMeta(HF_lat_ai_mo_sh,HF_lat_ai_mo_Ind)
   copy_VarMeta(HF_surf_ai_mo_sh,HF_surf_ai_mo_Ind)
   copy_VarMeta(HF_lwup_ai_mo_sh,HF_lwup_ai_mo_Ind)
   copy_VarMeta(HF_lwdn_ai_mo_sh,HF_lwdn_ai_mo_Ind)
   copy_VarMeta(HF_swdn_ai_mo_sh,HF_swdn_ai_mo_Ind)
   copy_VarMeta(HF_lwdn_mo_sh,HF_lwdn_mo_Ind)
   copy_VarMeta(HF_lwdn_mo_sh,HF_swdn_mo_Ind)

   copy_VarMeta(HF_swabs_ai_mo_sh,HF_swabs_ai_mo_Pac)
   copy_VarMeta(HF_sens_ai_mo_sh,HF_sens_ai_mo_Pac)
   copy_VarMeta(HF_lat_ai_mo_sh,HF_lat_ai_mo_Pac)
   copy_VarMeta(HF_surf_ai_mo_sh,HF_surf_ai_mo_Pac)
   copy_VarMeta(HF_lwup_ai_mo_sh,HF_lwup_ai_mo_Pac)
   copy_VarMeta(HF_lwdn_ai_mo_sh,HF_lwdn_ai_mo_Pac)
   copy_VarMeta(HF_swdn_ai_mo_sh,HF_swdn_ai_mo_Pac)
   copy_VarMeta(HF_lwdn_mo_sh,HF_lwdn_mo_Pac)
   copy_VarMeta(HF_lwdn_mo_sh,HF_swdn_mo_Pac)

   copy_VarMeta(HF_swabs_ai_mo_sh,HF_swabs_ai_mo_BAm)
   copy_VarMeta(HF_sens_ai_mo_sh,HF_sens_ai_mo_BAm)
   copy_VarMeta(HF_lat_ai_mo_sh,HF_lat_ai_mo_BAm)
   copy_VarMeta(HF_surf_ai_mo_sh,HF_surf_ai_mo_BAm)
   copy_VarMeta(HF_lwup_ai_mo_sh,HF_lwup_ai_mo_BAm)
   copy_VarMeta(HF_lwdn_ai_mo_sh,HF_lwdn_ai_mo_BAm)
   copy_VarMeta(HF_swdn_ai_mo_sh,HF_swdn_ai_mo_BAm)
   copy_VarMeta(HF_lwdn_mo_sh,HF_lwdn_mo_BAm)
   copy_VarMeta(HF_lwdn_mo_sh,HF_swdn_mo_BAm)

   fout = addfile(out_dir+"/ice_SHF_MHolland_regions_"+case_names(ii)+"_"+styrs_proc+".nc","c")
   setfileoption(fout,"DefineMode",True)

   fileAtt = True
   fileAtt@creation_date = systemfunc("date")
   fileAtt@program = systemfunc("pwd")+"/"+get_script_name()
   fileattdef(fout,fileAtt)

   dimNames = (/"time"/)
   dimSizes = (/-1/)
   dimUnlim = (/True/)
   filedimdef(fout,dimNames,dimSizes,dimUnlim)

   filevardef(fout,"time",typeof(time),getvardims(time))
   filevarattdef(fout,"time",time)

   filevardef(fout,"HF_swabs_ai_mo_nh",typeof(HF_swabs_ai_mo_nh),getvardims(HF_swabs_ai_mo_nh))
   filevardef(fout,"HF_sens_ai_mo_nh",typeof(HF_sens_ai_mo_nh),getvardims(HF_sens_ai_mo_nh))
   filevardef(fout,"HF_lat_ai_mo_nh",typeof(HF_lat_ai_mo_nh),getvardims(HF_lat_ai_mo_nh))
   filevardef(fout,"HF_surf_ai_mo_nh",typeof(HF_surf_ai_mo_nh),getvardims(HF_surf_ai_mo_nh))
   filevardef(fout,"HF_lwup_ai_mo_nh",typeof(HF_lwup_ai_mo_nh),getvardims(HF_lwup_ai_mo_nh))
   filevardef(fout,"HF_lwdn_ai_mo_nh",typeof(HF_lwdn_ai_mo_nh),getvardims(HF_lwdn_ai_mo_nh))
   filevardef(fout,"HF_swdn_ai_mo_nh",typeof(HF_swdn_ai_mo_nh),getvardims(HF_swdn_ai_mo_nh))
   filevardef(fout,"HF_lwdn_mo_nh",typeof(HF_lwdn_mo_nh),getvardims(HF_lwdn_mo_nh))
   filevardef(fout,"HF_swdn_mo_nh",typeof(HF_swdn_mo_nh),getvardims(HF_swdn_mo_nh))
   filevardef(fout,"HF_lwdn_mo_nh50_90",typeof(HF_lwdn_mo_nh50_90),getvardims(HF_lwdn_mo_nh50_90))
   filevardef(fout,"HF_swdn_mo_nh50_90",typeof(HF_swdn_mo_nh50_90),getvardims(HF_swdn_mo_nh50_90))

   filevardef(fout,"HF_swabs_ai_mo_sh",typeof(HF_swabs_ai_mo_sh),getvardims(HF_swabs_ai_mo_sh))
   filevardef(fout,"HF_sens_ai_mo_sh",typeof(HF_sens_ai_mo_sh),getvardims(HF_sens_ai_mo_sh))
   filevardef(fout,"HF_lat_ai_mo_sh",typeof(HF_lat_ai_mo_sh),getvardims(HF_lat_ai_mo_sh))
   filevardef(fout,"HF_surf_ai_mo_sh",typeof(HF_surf_ai_mo_sh),getvardims(HF_surf_ai_mo_sh))
   filevardef(fout,"HF_lwup_ai_mo_sh",typeof(HF_lwup_ai_mo_sh),getvardims(HF_lwup_ai_mo_sh))
   filevardef(fout,"HF_lwdn_ai_mo_sh",typeof(HF_lwdn_ai_mo_sh),getvardims(HF_lwdn_ai_mo_sh))
   filevardef(fout,"HF_swdn_ai_mo_sh",typeof(HF_swdn_ai_mo_sh),getvardims(HF_swdn_ai_mo_sh))
   filevardef(fout,"HF_lwdn_mo_sh",typeof(HF_lwdn_mo_sh),getvardims(HF_lwdn_mo_sh))
   filevardef(fout,"HF_swdn_mo_sh",typeof(HF_swdn_mo_sh),getvardims(HF_swdn_mo_sh))
   filevardef(fout,"HF_lwdn_mo_sh50_90",typeof(HF_lwdn_mo_sh50_90),getvardims(HF_lwdn_mo_sh50_90))
   filevardef(fout,"HF_swdn_mo_sh50_90",typeof(HF_swdn_mo_sh50_90),getvardims(HF_swdn_mo_sh50_90))

   filevardef(fout,"HF_swabs_ai_mo_Lab",typeof(HF_swabs_ai_mo_Lab),getvardims(HF_swabs_ai_mo_Lab))
   filevardef(fout,"HF_sens_ai_mo_Lab",typeof(HF_sens_ai_mo_Lab),getvardims(HF_sens_ai_mo_Lab))
   filevardef(fout,"HF_lat_ai_mo_Lab",typeof(HF_lat_ai_mo_Lab),getvardims(HF_lat_ai_mo_Lab))
   filevardef(fout,"HF_surf_ai_mo_Lab",typeof(HF_surf_ai_mo_Lab),getvardims(HF_surf_ai_mo_Lab))
   filevardef(fout,"HF_lwup_ai_mo_Lab",typeof(HF_lwup_ai_mo_Lab),getvardims(HF_lwup_ai_mo_Lab))
   filevardef(fout,"HF_lwdn_ai_mo_Lab",typeof(HF_lwdn_ai_mo_Lab),getvardims(HF_lwdn_ai_mo_Lab))
   filevardef(fout,"HF_swdn_ai_mo_Lab",typeof(HF_swdn_ai_mo_Lab),getvardims(HF_swdn_ai_mo_Lab))
   filevardef(fout,"HF_lwdn_mo_Lab",typeof(HF_lwdn_mo_Lab),getvardims(HF_lwdn_mo_Lab))
   filevardef(fout,"HF_swdn_mo_Lab",typeof(HF_swdn_mo_Lab),getvardims(HF_swdn_mo_Lab))

   filevardef(fout,"HF_swabs_ai_mo_GIN",typeof(HF_swabs_ai_mo_GIN),getvardims(HF_swabs_ai_mo_GIN))
   filevardef(fout,"HF_sens_ai_mo_GIN",typeof(HF_sens_ai_mo_GIN),getvardims(HF_sens_ai_mo_GIN))
   filevardef(fout,"HF_lat_ai_mo_GIN",typeof(HF_lat_ai_mo_GIN),getvardims(HF_lat_ai_mo_GIN))
   filevardef(fout,"HF_surf_ai_mo_GIN",typeof(HF_surf_ai_mo_GIN),getvardims(HF_surf_ai_mo_GIN))
   filevardef(fout,"HF_lwup_ai_mo_GIN",typeof(HF_lwup_ai_mo_GIN),getvardims(HF_lwup_ai_mo_GIN))
   filevardef(fout,"HF_lwdn_ai_mo_GIN",typeof(HF_lwdn_ai_mo_GIN),getvardims(HF_lwdn_ai_mo_GIN))
   filevardef(fout,"HF_swdn_ai_mo_GIN",typeof(HF_swdn_ai_mo_GIN),getvardims(HF_swdn_ai_mo_GIN))
   filevardef(fout,"HF_lwdn_mo_GIN",typeof(HF_lwdn_mo_GIN),getvardims(HF_lwdn_mo_GIN))
   filevardef(fout,"HF_swdn_mo_GIN",typeof(HF_swdn_mo_GIN),getvardims(HF_swdn_mo_GIN))

   filevardef(fout,"HF_swabs_ai_mo_Bar",typeof(HF_swabs_ai_mo_Bar),getvardims(HF_swabs_ai_mo_Bar))
   filevardef(fout,"HF_sens_ai_mo_Bar",typeof(HF_sens_ai_mo_Bar),getvardims(HF_sens_ai_mo_Bar))
   filevardef(fout,"HF_lat_ai_mo_Bar",typeof(HF_lat_ai_mo_Bar),getvardims(HF_lat_ai_mo_Bar))
   filevardef(fout,"HF_surf_ai_mo_Bar",typeof(HF_surf_ai_mo_Bar),getvardims(HF_surf_ai_mo_Bar))
   filevardef(fout,"HF_lwup_ai_mo_Bar",typeof(HF_lwup_ai_mo_Bar),getvardims(HF_lwup_ai_mo_Bar))
   filevardef(fout,"HF_lwdn_ai_mo_Bar",typeof(HF_lwdn_ai_mo_Bar),getvardims(HF_lwdn_ai_mo_Bar))
   filevardef(fout,"HF_swdn_ai_mo_Bar",typeof(HF_swdn_ai_mo_Bar),getvardims(HF_swdn_ai_mo_Bar))
   filevardef(fout,"HF_lwdn_mo_Bar",typeof(HF_lwdn_mo_Bar),getvardims(HF_lwdn_mo_Bar))
   filevardef(fout,"HF_swdn_mo_Bar",typeof(HF_swdn_mo_Bar),getvardims(HF_swdn_mo_Bar))

   filevardef(fout,"HF_swabs_ai_mo_ArcOc",typeof(HF_swabs_ai_mo_ArcOc),getvardims(HF_swabs_ai_mo_ArcOc))
   filevardef(fout,"HF_sens_ai_mo_ArcOc",typeof(HF_sens_ai_mo_ArcOc),getvardims(HF_sens_ai_mo_ArcOc))
   filevardef(fout,"HF_lat_ai_mo_ArcOc",typeof(HF_lat_ai_mo_ArcOc),getvardims(HF_lat_ai_mo_ArcOc))
   filevardef(fout,"HF_surf_ai_mo_ArcOc",typeof(HF_surf_ai_mo_ArcOc),getvardims(HF_surf_ai_mo_ArcOc))
   filevardef(fout,"HF_lwup_ai_mo_ArcOc",typeof(HF_lwup_ai_mo_ArcOc),getvardims(HF_lwup_ai_mo_ArcOc))
   filevardef(fout,"HF_lwdn_ai_mo_ArcOc",typeof(HF_lwdn_ai_mo_ArcOc),getvardims(HF_lwdn_ai_mo_ArcOc))
   filevardef(fout,"HF_swdn_ai_mo_ArcOc",typeof(HF_swdn_ai_mo_ArcOc),getvardims(HF_swdn_ai_mo_ArcOc))
   filevardef(fout,"HF_lwdn_mo_ArcOc",typeof(HF_lwdn_mo_ArcOc),getvardims(HF_lwdn_mo_ArcOc))
   filevardef(fout,"HF_swdn_mo_ArcOc",typeof(HF_swdn_mo_ArcOc),getvardims(HF_swdn_mo_ArcOc))

   filevardef(fout,"HF_swabs_ai_mo_Kara",typeof(HF_swabs_ai_mo_Kara),getvardims(HF_swabs_ai_mo_Kara))
   filevardef(fout,"HF_sens_ai_mo_Kara",typeof(HF_sens_ai_mo_Kara),getvardims(HF_sens_ai_mo_Kara))
   filevardef(fout,"HF_lat_ai_mo_Kara",typeof(HF_lat_ai_mo_Kara),getvardims(HF_lat_ai_mo_Kara))
   filevardef(fout,"HF_surf_ai_mo_Kara",typeof(HF_surf_ai_mo_Kara),getvardims(HF_surf_ai_mo_Kara))
   filevardef(fout,"HF_lwup_ai_mo_Kara",typeof(HF_lwup_ai_mo_Kara),getvardims(HF_lwup_ai_mo_Kara))
   filevardef(fout,"HF_lwdn_ai_mo_Kara",typeof(HF_lwdn_ai_mo_Kara),getvardims(HF_lwdn_ai_mo_Kara))
   filevardef(fout,"HF_swdn_ai_mo_Kara",typeof(HF_swdn_ai_mo_Kara),getvardims(HF_swdn_ai_mo_Kara))
   filevardef(fout,"HF_lwdn_mo_Kara",typeof(HF_lwdn_mo_Kara),getvardims(HF_lwdn_mo_Kara))
   filevardef(fout,"HF_swdn_mo_Kara",typeof(HF_swdn_mo_Kara),getvardims(HF_swdn_mo_Kara))

   filevardef(fout,"HF_swabs_ai_mo_Laptev",typeof(HF_swabs_ai_mo_Laptev),getvardims(HF_swabs_ai_mo_Laptev))
   filevardef(fout,"HF_sens_ai_mo_Laptev",typeof(HF_sens_ai_mo_Laptev),getvardims(HF_sens_ai_mo_Laptev))
   filevardef(fout,"HF_lat_ai_mo_Laptev",typeof(HF_lat_ai_mo_Laptev),getvardims(HF_lat_ai_mo_Laptev))
   filevardef(fout,"HF_surf_ai_mo_Laptev",typeof(HF_surf_ai_mo_Laptev),getvardims(HF_surf_ai_mo_Laptev))
   filevardef(fout,"HF_lwup_ai_mo_Laptev",typeof(HF_lwup_ai_mo_Laptev),getvardims(HF_lwup_ai_mo_Laptev))
   filevardef(fout,"HF_lwdn_ai_mo_Laptev",typeof(HF_lwdn_ai_mo_Laptev),getvardims(HF_lwdn_ai_mo_Laptev))
   filevardef(fout,"HF_swdn_ai_mo_Laptev",typeof(HF_swdn_ai_mo_Laptev),getvardims(HF_swdn_ai_mo_Laptev))
   filevardef(fout,"HF_lwdn_mo_Laptev",typeof(HF_lwdn_mo_Laptev),getvardims(HF_lwdn_mo_Laptev))
   filevardef(fout,"HF_swdn_mo_Laptev",typeof(HF_swdn_mo_Laptev),getvardims(HF_swdn_mo_Laptev))

   filevardef(fout,"HF_swabs_ai_mo_Chukchi",typeof(HF_swabs_ai_mo_Chukchi),getvardims(HF_swabs_ai_mo_Chukchi))
   filevardef(fout,"HF_sens_ai_mo_Chukchi",typeof(HF_sens_ai_mo_Chukchi),getvardims(HF_sens_ai_mo_Chukchi))
   filevardef(fout,"HF_lat_ai_mo_Chukchi",typeof(HF_lat_ai_mo_Chukchi),getvardims(HF_lat_ai_mo_Chukchi))
   filevardef(fout,"HF_surf_ai_mo_Chukchi",typeof(HF_surf_ai_mo_Chukchi),getvardims(HF_surf_ai_mo_Chukchi))
   filevardef(fout,"HF_lwup_ai_mo_Chukchi",typeof(HF_lwup_ai_mo_Chukchi),getvardims(HF_lwup_ai_mo_Chukchi))
   filevardef(fout,"HF_lwdn_ai_mo_Chukchi",typeof(HF_lwdn_ai_mo_Chukchi),getvardims(HF_lwdn_ai_mo_Chukchi))
   filevardef(fout,"HF_swdn_ai_mo_Chukchi",typeof(HF_swdn_ai_mo_Chukchi),getvardims(HF_swdn_ai_mo_Chukchi))
   filevardef(fout,"HF_lwdn_mo_Chukchi",typeof(HF_lwdn_mo_Chukchi),getvardims(HF_lwdn_mo_Chukchi))
   filevardef(fout,"HF_swdn_mo_Chukchi",typeof(HF_swdn_mo_Chukchi),getvardims(HF_swdn_mo_Chukchi))

   filevardef(fout,"HF_swabs_ai_mo_Sib",typeof(HF_swabs_ai_mo_Sib),getvardims(HF_swabs_ai_mo_Sib))
   filevardef(fout,"HF_sens_ai_mo_Sib",typeof(HF_sens_ai_mo_Sib),getvardims(HF_sens_ai_mo_Sib))
   filevardef(fout,"HF_lat_ai_mo_Sib",typeof(HF_lat_ai_mo_Sib),getvardims(HF_lat_ai_mo_Sib))
   filevardef(fout,"HF_surf_ai_mo_Sib",typeof(HF_surf_ai_mo_Sib),getvardims(HF_surf_ai_mo_Sib))
   filevardef(fout,"HF_lwup_ai_mo_Sib",typeof(HF_lwup_ai_mo_Sib),getvardims(HF_lwup_ai_mo_Sib))
   filevardef(fout,"HF_lwdn_ai_mo_Sib",typeof(HF_lwdn_ai_mo_Sib),getvardims(HF_lwdn_ai_mo_Sib))
   filevardef(fout,"HF_swdn_ai_mo_Sib",typeof(HF_swdn_ai_mo_Sib),getvardims(HF_swdn_ai_mo_Sib))
   filevardef(fout,"HF_lwdn_mo_Sib",typeof(HF_lwdn_mo_Sib),getvardims(HF_lwdn_mo_Sib))
   filevardef(fout,"HF_swdn_mo_Sib",typeof(HF_swdn_mo_Sib),getvardims(HF_swdn_mo_Sib))

   filevardef(fout,"HF_swabs_ai_mo_Beau",typeof(HF_swabs_ai_mo_Beau),getvardims(HF_swabs_ai_mo_Beau))
   filevardef(fout,"HF_sens_ai_mo_Beau",typeof(HF_sens_ai_mo_Beau),getvardims(HF_sens_ai_mo_Beau))
   filevardef(fout,"HF_lat_ai_mo_Beau",typeof(HF_lat_ai_mo_Beau),getvardims(HF_lat_ai_mo_Beau))
   filevardef(fout,"HF_surf_ai_mo_Beau",typeof(HF_surf_ai_mo_Beau),getvardims(HF_surf_ai_mo_Beau))
   filevardef(fout,"HF_lwup_ai_mo_Beau",typeof(HF_lwup_ai_mo_Beau),getvardims(HF_lwup_ai_mo_Beau))
   filevardef(fout,"HF_lwdn_ai_mo_Beau",typeof(HF_lwdn_ai_mo_Beau),getvardims(HF_lwdn_ai_mo_Beau))
   filevardef(fout,"HF_swdn_ai_mo_Beau",typeof(HF_swdn_ai_mo_Beau),getvardims(HF_swdn_ai_mo_Beau))
   filevardef(fout,"HF_lwdn_mo_Beau",typeof(HF_lwdn_mo_Beau),getvardims(HF_lwdn_mo_Beau))
   filevardef(fout,"HF_swdn_mo_Beau",typeof(HF_swdn_mo_Beau),getvardims(HF_swdn_mo_Beau))

   filevardef(fout,"HF_swabs_ai_mo_CArc",typeof(HF_swabs_ai_mo_CArc),getvardims(HF_swabs_ai_mo_CArc))
   filevardef(fout,"HF_sens_ai_mo_CArc",typeof(HF_sens_ai_mo_CArc),getvardims(HF_sens_ai_mo_CArc))
   filevardef(fout,"HF_lat_ai_mo_CArc",typeof(HF_lat_ai_mo_CArc),getvardims(HF_lat_ai_mo_CArc))
   filevardef(fout,"HF_surf_ai_mo_CArc",typeof(HF_surf_ai_mo_CArc),getvardims(HF_surf_ai_mo_CArc))
   filevardef(fout,"HF_lwup_ai_mo_CArc",typeof(HF_lwup_ai_mo_CArc),getvardims(HF_lwup_ai_mo_CArc))
   filevardef(fout,"HF_lwdn_ai_mo_CArc",typeof(HF_lwdn_ai_mo_CArc),getvardims(HF_lwdn_ai_mo_CArc))
   filevardef(fout,"HF_swdn_ai_mo_CArc",typeof(HF_swdn_ai_mo_CArc),getvardims(HF_swdn_ai_mo_CArc))
   filevardef(fout,"HF_lwdn_mo_CArc",typeof(HF_lwdn_mo_CArc),getvardims(HF_lwdn_mo_CArc))
   filevardef(fout,"HF_swdn_mo_CArc",typeof(HF_swdn_mo_CArc),getvardims(HF_swdn_mo_CArc))

   filevardef(fout,"HF_swabs_ai_mo_Bering",typeof(HF_swabs_ai_mo_Bering),getvardims(HF_swabs_ai_mo_Bering))
   filevardef(fout,"HF_sens_ai_mo_Bering",typeof(HF_sens_ai_mo_Bering),getvardims(HF_sens_ai_mo_Bering))
   filevardef(fout,"HF_lat_ai_mo_Bering",typeof(HF_lat_ai_mo_Bering),getvardims(HF_lat_ai_mo_Bering))
   filevardef(fout,"HF_surf_ai_mo_Bering",typeof(HF_surf_ai_mo_Bering),getvardims(HF_surf_ai_mo_Bering))
   filevardef(fout,"HF_lwup_ai_mo_Bering",typeof(HF_lwup_ai_mo_Bering),getvardims(HF_lwup_ai_mo_Bering))
   filevardef(fout,"HF_lwdn_ai_mo_Bering",typeof(HF_lwdn_ai_mo_Bering),getvardims(HF_lwdn_ai_mo_Bering))
   filevardef(fout,"HF_swdn_ai_mo_Bering",typeof(HF_swdn_ai_mo_Bering),getvardims(HF_swdn_ai_mo_Bering))
   filevardef(fout,"HF_lwdn_mo_Bering",typeof(HF_lwdn_mo_Bering),getvardims(HF_lwdn_mo_Bering))
   filevardef(fout,"HF_swdn_mo_Bering",typeof(HF_swdn_mo_Bering),getvardims(HF_swdn_mo_Bering))

   filevardef(fout,"HF_swabs_ai_mo_Okhotsk",typeof(HF_swabs_ai_mo_Okhotsk),getvardims(HF_swabs_ai_mo_Okhotsk))
   filevardef(fout,"HF_sens_ai_mo_Okhotsk",typeof(HF_sens_ai_mo_Okhotsk),getvardims(HF_sens_ai_mo_Okhotsk))
   filevardef(fout,"HF_lat_ai_mo_Okhotsk",typeof(HF_lat_ai_mo_Okhotsk),getvardims(HF_lat_ai_mo_Okhotsk))
   filevardef(fout,"HF_surf_ai_mo_Okhotsk",typeof(HF_surf_ai_mo_Okhotsk),getvardims(HF_surf_ai_mo_Okhotsk))
   filevardef(fout,"HF_lwup_ai_mo_Okhotsk",typeof(HF_lwup_ai_mo_Okhotsk),getvardims(HF_lwup_ai_mo_Okhotsk))
   filevardef(fout,"HF_lwdn_ai_mo_Okhotsk",typeof(HF_lwdn_ai_mo_Okhotsk),getvardims(HF_lwdn_ai_mo_Okhotsk))
   filevardef(fout,"HF_swdn_ai_mo_Okhotsk",typeof(HF_swdn_ai_mo_Okhotsk),getvardims(HF_swdn_ai_mo_Okhotsk))
   filevardef(fout,"HF_lwdn_mo_Okhotsk",typeof(HF_lwdn_mo_Okhotsk),getvardims(HF_lwdn_mo_Okhotsk))
   filevardef(fout,"HF_swdn_mo_Okhotsk",typeof(HF_swdn_mo_Okhotsk),getvardims(HF_swdn_mo_Okhotsk))

   filevardef(fout,"HF_swabs_ai_mo_Hudson",typeof(HF_swabs_ai_mo_Hudson),getvardims(HF_swabs_ai_mo_Hudson))
   filevardef(fout,"HF_sens_ai_mo_Hudson",typeof(HF_sens_ai_mo_Hudson),getvardims(HF_sens_ai_mo_Hudson))
   filevardef(fout,"HF_lat_ai_mo_Hudson",typeof(HF_lat_ai_mo_Hudson),getvardims(HF_lat_ai_mo_Hudson))
   filevardef(fout,"HF_surf_ai_mo_Hudson",typeof(HF_surf_ai_mo_Hudson),getvardims(HF_surf_ai_mo_Hudson))
   filevardef(fout,"HF_lwup_ai_mo_Hudson",typeof(HF_lwup_ai_mo_Hudson),getvardims(HF_lwup_ai_mo_Hudson))
   filevardef(fout,"HF_lwdn_ai_mo_Hudson",typeof(HF_lwdn_ai_mo_Hudson),getvardims(HF_lwdn_ai_mo_Hudson))
   filevardef(fout,"HF_swdn_ai_mo_Hudson",typeof(HF_swdn_ai_mo_Hudson),getvardims(HF_swdn_ai_mo_Hudson))
   filevardef(fout,"HF_lwdn_mo_Hudson",typeof(HF_lwdn_mo_Hudson),getvardims(HF_lwdn_mo_Hudson))
   filevardef(fout,"HF_swdn_mo_Hudson",typeof(HF_swdn_mo_Hudson),getvardims(HF_swdn_mo_Hudson))

   filevardef(fout,"HF_swabs_ai_mo_CAArch",typeof(HF_swabs_ai_mo_CAArch),getvardims(HF_swabs_ai_mo_CAArch))
   filevardef(fout,"HF_sens_ai_mo_CAArch",typeof(HF_sens_ai_mo_CAArch),getvardims(HF_sens_ai_mo_CAArch))
   filevardef(fout,"HF_lat_ai_mo_CAArch",typeof(HF_lat_ai_mo_CAArch),getvardims(HF_lat_ai_mo_CAArch))
   filevardef(fout,"HF_surf_ai_mo_CAArch",typeof(HF_surf_ai_mo_CAArch),getvardims(HF_surf_ai_mo_CAArch))
   filevardef(fout,"HF_lwup_ai_mo_CAArch",typeof(HF_lwup_ai_mo_CAArch),getvardims(HF_lwup_ai_mo_CAArch))
   filevardef(fout,"HF_lwdn_ai_mo_CAArch",typeof(HF_lwdn_ai_mo_CAArch),getvardims(HF_lwdn_ai_mo_CAArch))
   filevardef(fout,"HF_swdn_ai_mo_CAArch",typeof(HF_swdn_ai_mo_CAArch),getvardims(HF_swdn_ai_mo_CAArch))
   filevardef(fout,"HF_lwdn_mo_CAArch",typeof(HF_lwdn_mo_CAArch),getvardims(HF_lwdn_mo_CAArch))
   filevardef(fout,"HF_swdn_mo_CAArch",typeof(HF_swdn_mo_CAArch),getvardims(HF_swdn_mo_CAArch))

   filevardef(fout,"HF_swabs_ai_mo_Wed",typeof(HF_swabs_ai_mo_Wed),getvardims(HF_swabs_ai_mo_Wed))
   filevardef(fout,"HF_sens_ai_mo_Wed",typeof(HF_sens_ai_mo_Wed),getvardims(HF_sens_ai_mo_Wed))
   filevardef(fout,"HF_lat_ai_mo_Wed",typeof(HF_lat_ai_mo_Wed),getvardims(HF_lat_ai_mo_Wed))
   filevardef(fout,"HF_surf_ai_mo_Wed",typeof(HF_surf_ai_mo_Wed),getvardims(HF_surf_ai_mo_Wed))
   filevardef(fout,"HF_lwup_ai_mo_Wed",typeof(HF_lwup_ai_mo_Wed),getvardims(HF_lwup_ai_mo_Wed))
   filevardef(fout,"HF_lwdn_ai_mo_Wed",typeof(HF_lwdn_ai_mo_Wed),getvardims(HF_lwdn_ai_mo_Wed))
   filevardef(fout,"HF_swdn_ai_mo_Wed",typeof(HF_swdn_ai_mo_Wed),getvardims(HF_swdn_ai_mo_Wed))
   filevardef(fout,"HF_lwdn_mo_Wed",typeof(HF_lwdn_mo_Wed),getvardims(HF_lwdn_mo_Wed))
   filevardef(fout,"HF_swdn_mo_Wed",typeof(HF_swdn_mo_Wed),getvardims(HF_swdn_mo_Wed))

   filevardef(fout,"HF_swabs_ai_mo_Ross",typeof(HF_swabs_ai_mo_Ross),getvardims(HF_swabs_ai_mo_Ross))
   filevardef(fout,"HF_sens_ai_mo_Ross",typeof(HF_sens_ai_mo_Ross),getvardims(HF_sens_ai_mo_Ross))
   filevardef(fout,"HF_lat_ai_mo_Ross",typeof(HF_lat_ai_mo_Ross),getvardims(HF_lat_ai_mo_Ross))
   filevardef(fout,"HF_surf_ai_mo_Ross",typeof(HF_surf_ai_mo_Ross),getvardims(HF_surf_ai_mo_Ross))
   filevardef(fout,"HF_lwup_ai_mo_Ross",typeof(HF_lwup_ai_mo_Ross),getvardims(HF_lwup_ai_mo_Ross))
   filevardef(fout,"HF_lwdn_ai_mo_Ross",typeof(HF_lwdn_ai_mo_Ross),getvardims(HF_lwdn_ai_mo_Ross))
   filevardef(fout,"HF_swdn_ai_mo_Ross",typeof(HF_swdn_ai_mo_Ross),getvardims(HF_swdn_ai_mo_Ross))
   filevardef(fout,"HF_lwdn_mo_Ross",typeof(HF_lwdn_mo_Ross),getvardims(HF_lwdn_mo_Ross))
   filevardef(fout,"HF_swdn_mo_Ross",typeof(HF_swdn_mo_Ross),getvardims(HF_swdn_mo_Ross))

   filevardef(fout,"HF_swabs_ai_mo_Ind",typeof(HF_swabs_ai_mo_Ind),getvardims(HF_swabs_ai_mo_Ind))
   filevardef(fout,"HF_sens_ai_mo_Ind",typeof(HF_sens_ai_mo_Ind),getvardims(HF_sens_ai_mo_Ind))
   filevardef(fout,"HF_lat_ai_mo_Ind",typeof(HF_lat_ai_mo_Ind),getvardims(HF_lat_ai_mo_Ind))
   filevardef(fout,"HF_surf_ai_mo_Ind",typeof(HF_surf_ai_mo_Ind),getvardims(HF_surf_ai_mo_Ind))
   filevardef(fout,"HF_lwup_ai_mo_Ind",typeof(HF_lwup_ai_mo_Ind),getvardims(HF_lwup_ai_mo_Ind))
   filevardef(fout,"HF_lwdn_ai_mo_Ind",typeof(HF_lwdn_ai_mo_Ind),getvardims(HF_lwdn_ai_mo_Ind))
   filevardef(fout,"HF_swdn_ai_mo_Ind",typeof(HF_swdn_ai_mo_Ind),getvardims(HF_swdn_ai_mo_Ind))
   filevardef(fout,"HF_lwdn_mo_Ind",typeof(HF_lwdn_mo_Ind),getvardims(HF_lwdn_mo_Ind))
   filevardef(fout,"HF_swdn_mo_Ind",typeof(HF_swdn_mo_Ind),getvardims(HF_swdn_mo_Ind))

   filevardef(fout,"HF_swabs_ai_mo_Pac",typeof(HF_swabs_ai_mo_Pac),getvardims(HF_swabs_ai_mo_Pac))
   filevardef(fout,"HF_sens_ai_mo_Pac",typeof(HF_sens_ai_mo_Pac),getvardims(HF_sens_ai_mo_Pac))
   filevardef(fout,"HF_lat_ai_mo_Pac",typeof(HF_lat_ai_mo_Pac),getvardims(HF_lat_ai_mo_Pac))
   filevardef(fout,"HF_surf_ai_mo_Pac",typeof(HF_surf_ai_mo_Pac),getvardims(HF_surf_ai_mo_Pac))
   filevardef(fout,"HF_lwup_ai_mo_Pac",typeof(HF_lwup_ai_mo_Pac),getvardims(HF_lwup_ai_mo_Pac))
   filevardef(fout,"HF_lwdn_ai_mo_Pac",typeof(HF_lwdn_ai_mo_Pac),getvardims(HF_lwdn_ai_mo_Pac))
   filevardef(fout,"HF_swdn_ai_mo_Pac",typeof(HF_swdn_ai_mo_Pac),getvardims(HF_swdn_ai_mo_Pac))
   filevardef(fout,"HF_lwdn_mo_Pac",typeof(HF_lwdn_mo_Pac),getvardims(HF_lwdn_mo_Pac))
   filevardef(fout,"HF_swdn_mo_Pac",typeof(HF_swdn_mo_Pac),getvardims(HF_swdn_mo_Pac))

   filevardef(fout,"HF_swabs_ai_mo_BAm",typeof(HF_swabs_ai_mo_BAm),getvardims(HF_swabs_ai_mo_BAm))
   filevardef(fout,"HF_sens_ai_mo_BAm",typeof(HF_sens_ai_mo_BAm),getvardims(HF_sens_ai_mo_BAm))
   filevardef(fout,"HF_lat_ai_mo_BAm",typeof(HF_lat_ai_mo_BAm),getvardims(HF_lat_ai_mo_BAm))
   filevardef(fout,"HF_surf_ai_mo_BAm",typeof(HF_surf_ai_mo_BAm),getvardims(HF_surf_ai_mo_BAm))
   filevardef(fout,"HF_lwup_ai_mo_BAm",typeof(HF_lwup_ai_mo_BAm),getvardims(HF_lwup_ai_mo_BAm))
   filevardef(fout,"HF_lwdn_ai_mo_BAm",typeof(HF_lwdn_ai_mo_BAm),getvardims(HF_lwdn_ai_mo_BAm))
   filevardef(fout,"HF_swdn_ai_mo_BAm",typeof(HF_swdn_ai_mo_BAm),getvardims(HF_swdn_ai_mo_BAm))
   filevardef(fout,"HF_lwdn_mo_BAm",typeof(HF_lwdn_mo_BAm),getvardims(HF_lwdn_mo_BAm))
   filevardef(fout,"HF_swdn_mo_BAm",typeof(HF_swdn_mo_BAm),getvardims(HF_swdn_mo_BAm))

   filevarattdef(fout,"HF_lat_ai_mo_nh",HF_lat_ai_mo_nh)
   filevarattdef(fout,"HF_surf_ai_mo_nh",HF_surf_ai_mo_nh)
   filevarattdef(fout,"HF_swabs_ai_mo_nh",HF_swabs_ai_mo_nh)
   filevarattdef(fout,"HF_sens_ai_mo_nh",HF_sens_ai_mo_nh)
   filevarattdef(fout,"HF_lwup_ai_mo_nh",HF_lwup_ai_mo_nh)
   filevarattdef(fout,"HF_lwdn_ai_mo_nh",HF_lwdn_ai_mo_nh)
   filevarattdef(fout,"HF_swdn_ai_mo_nh",HF_swdn_ai_mo_nh)
   filevarattdef(fout,"HF_lwdn_mo_nh",HF_lwdn_mo_nh)
   filevarattdef(fout,"HF_swdn_mo_nh",HF_swdn_mo_nh)
   filevarattdef(fout,"HF_lwdn_mo_nh50_90",HF_lwdn_mo_nh50_90)
   filevarattdef(fout,"HF_swdn_mo_nh50_90",HF_swdn_mo_nh50_90)

   filevarattdef(fout,"HF_lat_ai_mo_sh",HF_lat_ai_mo_sh)
   filevarattdef(fout,"HF_surf_ai_mo_sh",HF_surf_ai_mo_sh)
   filevarattdef(fout,"HF_swabs_ai_mo_sh",HF_swabs_ai_mo_sh)
   filevarattdef(fout,"HF_sens_ai_mo_sh",HF_sens_ai_mo_sh)
   filevarattdef(fout,"HF_lwup_ai_mo_sh",HF_lwup_ai_mo_sh)
   filevarattdef(fout,"HF_lwdn_ai_mo_sh",HF_lwdn_ai_mo_sh)
   filevarattdef(fout,"HF_swdn_ai_mo_sh",HF_swdn_ai_mo_sh)
   filevarattdef(fout,"HF_lwdn_mo_sh",HF_lwdn_mo_sh)
   filevarattdef(fout,"HF_swdn_mo_sh",HF_swdn_mo_sh)
   filevarattdef(fout,"HF_lwdn_mo_sh50_90",HF_lwdn_mo_sh50_90)
   filevarattdef(fout,"HF_swdn_mo_sh50_90",HF_swdn_mo_sh50_90)

   filevarattdef(fout,"HF_lat_ai_mo_Lab",HF_lat_ai_mo_Lab)
   filevarattdef(fout,"HF_surf_ai_mo_Lab",HF_surf_ai_mo_Lab)
   filevarattdef(fout,"HF_swabs_ai_mo_Lab",HF_swabs_ai_mo_Lab)
   filevarattdef(fout,"HF_sens_ai_mo_Lab",HF_swabs_ai_mo_Lab)
   filevarattdef(fout,"HF_lwup_ai_mo_Lab",HF_lwup_ai_mo_Lab)
   filevarattdef(fout,"HF_lwdn_ai_mo_Lab",HF_lwdn_ai_mo_Lab)
   filevarattdef(fout,"HF_swdn_ai_mo_Lab",HF_swdn_ai_mo_Lab)
   filevarattdef(fout,"HF_lwdn_mo_Lab",HF_lwdn_mo_Lab)
   filevarattdef(fout,"HF_swdn_mo_Lab",HF_swdn_mo_Lab)

   filevarattdef(fout,"HF_lat_ai_mo_GIN",HF_lat_ai_mo_GIN)
   filevarattdef(fout,"HF_surf_ai_mo_Lab",HF_surf_ai_mo_Lab)
   filevarattdef(fout,"HF_swabs_ai_mo_GIN",HF_swabs_ai_mo_GIN)
   filevarattdef(fout,"HF_sens_ai_mo_GIN",HF_sens_ai_mo_GIN)
   filevarattdef(fout,"HF_lwup_ai_mo_GIN",HF_lwup_ai_mo_GIN)
   filevarattdef(fout,"HF_lwdn_ai_mo_GIN",HF_lwdn_ai_mo_GIN)
   filevarattdef(fout,"HF_swdn_ai_mo_GIN",HF_swdn_ai_mo_GIN)
   filevarattdef(fout,"HF_lwdn_mo_GIN",HF_lwdn_mo_GIN)
   filevarattdef(fout,"HF_swdn_mo_GIN",HF_swdn_mo_GIN)

   filevarattdef(fout,"HF_lat_ai_mo_Bar",HF_lat_ai_mo_Bar)
   filevarattdef(fout,"HF_surf_ai_mo_Bar",HF_surf_ai_mo_Bar)
   filevarattdef(fout,"HF_swabs_ai_mo_Bar",HF_swabs_ai_mo_Bar)
   filevarattdef(fout,"HF_sens_ai_mo_Bar",HF_sens_ai_mo_Bar)
   filevarattdef(fout,"HF_lwup_ai_mo_Bar",HF_lwup_ai_mo_Bar)
   filevarattdef(fout,"HF_lwdn_ai_mo_Bar",HF_lwdn_ai_mo_Bar)
   filevarattdef(fout,"HF_swdn_ai_mo_Bar",HF_swdn_ai_mo_Bar)
   filevarattdef(fout,"HF_lwdn_mo_Bar",HF_lwdn_mo_Bar)
   filevarattdef(fout,"HF_swdn_mo_Bar",HF_swdn_mo_Bar)

   filevarattdef(fout,"HF_lat_ai_mo_ArcOc",HF_lat_ai_mo_ArcOc)
   filevarattdef(fout,"HF_surf_ai_mo_ArcOc",HF_surf_ai_mo_ArcOc)
   filevarattdef(fout,"HF_swabs_ai_mo_ArcOc",HF_swabs_ai_mo_ArcOc)
   filevarattdef(fout,"HF_sens_ai_mo_ArcOc",HF_sens_ai_mo_ArcOc)
   filevarattdef(fout,"HF_lwup_ai_mo_ArcOc",HF_lwup_ai_mo_ArcOc)
   filevarattdef(fout,"HF_lwdn_ai_mo_ArcOc",HF_lwdn_ai_mo_ArcOc)
   filevarattdef(fout,"HF_swdn_ai_mo_ArcOc",HF_swdn_ai_mo_ArcOc)
   filevarattdef(fout,"HF_lwdn_mo_ArcOc",HF_lwdn_mo_ArcOc)
   filevarattdef(fout,"HF_swdn_mo_ArcOc",HF_swdn_mo_ArcOc)

   filevarattdef(fout,"HF_lat_ai_mo_Kara",HF_lat_ai_mo_Kara)
   filevarattdef(fout,"HF_surf_ai_mo_Kara",HF_surf_ai_mo_Kara)
   filevarattdef(fout,"HF_swabs_ai_mo_Kara",HF_swabs_ai_mo_Kara)
   filevarattdef(fout,"HF_sens_ai_mo_Kara",HF_sens_ai_mo_Kara)
   filevarattdef(fout,"HF_lwup_ai_mo_Kara",HF_lwup_ai_mo_Kara)
   filevarattdef(fout,"HF_lwdn_ai_mo_Kara",HF_lwdn_ai_mo_Kara)
   filevarattdef(fout,"HF_swdn_ai_mo_Kara",HF_swdn_ai_mo_Kara)
   filevarattdef(fout,"HF_lwdn_mo_Kara",HF_lwdn_mo_Kara)
   filevarattdef(fout,"HF_swdn_mo_Kara",HF_swdn_mo_Kara)

   filevarattdef(fout,"HF_lat_ai_mo_Laptev",HF_lat_ai_mo_Laptev)
   filevarattdef(fout,"HF_surf_ai_mo_Laptev",HF_surf_ai_mo_Laptev)
   filevarattdef(fout,"HF_swabs_ai_mo_Laptev",HF_swabs_ai_mo_Laptev)
   filevarattdef(fout,"HF_sens_ai_mo_Laptev",HF_sens_ai_mo_Laptev)
   filevarattdef(fout,"HF_lwup_ai_mo_Laptev",HF_lwup_ai_mo_Laptev)
   filevarattdef(fout,"HF_lwdn_ai_mo_Laptev",HF_lwdn_ai_mo_Laptev)
   filevarattdef(fout,"HF_swdn_ai_mo_Laptev",HF_swdn_ai_mo_Laptev)
   filevarattdef(fout,"HF_lwdn_mo_Laptev",HF_lwdn_mo_Laptev)
   filevarattdef(fout,"HF_swdn_mo_Laptev",HF_swdn_mo_Laptev)

   filevarattdef(fout,"HF_lat_ai_mo_Chukchi",HF_lat_ai_mo_Chukchi)
   filevarattdef(fout,"HF_surf_ai_mo_Chukchi",HF_surf_ai_mo_Chukchi)
   filevarattdef(fout,"HF_swabs_ai_mo_Chukchi",HF_swabs_ai_mo_Chukchi)
   filevarattdef(fout,"HF_sens_ai_mo_Chukchi",HF_sens_ai_mo_Chukchi)
   filevarattdef(fout,"HF_lwup_ai_mo_Chukchi",HF_lwup_ai_mo_Chukchi)
   filevarattdef(fout,"HF_lwdn_ai_mo_Chukchi",HF_lwdn_ai_mo_Chukchi)
   filevarattdef(fout,"HF_swdn_ai_mo_Chukchi",HF_swdn_ai_mo_Chukchi)
   filevarattdef(fout,"HF_lwdn_mo_Chukchi",HF_lwdn_mo_Chukchi)
   filevarattdef(fout,"HF_swdn_mo_Chukchi",HF_swdn_mo_Chukchi)

   filevarattdef(fout,"HF_lat_ai_mo_Sib",HF_lat_ai_mo_Sib)
   filevarattdef(fout,"HF_surf_ai_mo_Sib",HF_surf_ai_mo_Sib)
   filevarattdef(fout,"HF_swabs_ai_mo_Sib",HF_swabs_ai_mo_Sib)
   filevarattdef(fout,"HF_sens_ai_mo_Sib",HF_sens_ai_mo_Sib)
   filevarattdef(fout,"HF_lwup_ai_mo_Sib",HF_lwup_ai_mo_Sib)
   filevarattdef(fout,"HF_lwdn_ai_mo_Sib",HF_lwdn_ai_mo_Sib)
   filevarattdef(fout,"HF_swdn_ai_mo_Sib",HF_swdn_ai_mo_Sib)
   filevarattdef(fout,"HF_lwdn_mo_Sib",HF_lwdn_mo_Sib)
   filevarattdef(fout,"HF_swdn_mo_Sib",HF_swdn_mo_Sib)

   filevarattdef(fout,"HF_lat_ai_mo_Beau",HF_lat_ai_mo_Beau)
   filevarattdef(fout,"HF_surf_ai_mo_Beau",HF_surf_ai_mo_Beau)
   filevarattdef(fout,"HF_swabs_ai_mo_Beau",HF_swabs_ai_mo_Beau)
   filevarattdef(fout,"HF_sens_ai_mo_Beau",HF_sens_ai_mo_Beau)
   filevarattdef(fout,"HF_lwup_ai_mo_Beau",HF_lwup_ai_mo_Beau)
   filevarattdef(fout,"HF_lwdn_ai_mo_Beau",HF_lwdn_ai_mo_Beau)
   filevarattdef(fout,"HF_swdn_ai_mo_Beau",HF_swdn_ai_mo_Beau)
   filevarattdef(fout,"HF_lwdn_mo_Beau",HF_lwdn_mo_Beau)
   filevarattdef(fout,"HF_swdn_mo_Beau",HF_swdn_mo_Beau)

   filevarattdef(fout,"HF_lat_ai_mo_CArc",HF_lat_ai_mo_CArc)
   filevarattdef(fout,"HF_surf_ai_mo_CArc",HF_surf_ai_mo_CArc)
   filevarattdef(fout,"HF_swabs_ai_mo_CArc",HF_swabs_ai_mo_CArc)
   filevarattdef(fout,"HF_sens_ai_mo_CArc",HF_sens_ai_mo_CArc)
   filevarattdef(fout,"HF_lwup_ai_mo_CArc",HF_lwup_ai_mo_CArc)
   filevarattdef(fout,"HF_lwdn_ai_mo_CArc",HF_lwdn_ai_mo_CArc)
   filevarattdef(fout,"HF_swdn_ai_mo_CArc",HF_swdn_ai_mo_CArc)
   filevarattdef(fout,"HF_lwdn_mo_CArc",HF_lwdn_mo_CArc)
   filevarattdef(fout,"HF_swdn_mo_CArc",HF_swdn_mo_CArc)

   filevarattdef(fout,"HF_lat_ai_mo_Bering",HF_lat_ai_mo_Bering)
   filevarattdef(fout,"HF_surf_ai_mo_Bering",HF_surf_ai_mo_Bering)
   filevarattdef(fout,"HF_swabs_ai_mo_Bering",HF_swabs_ai_mo_Bering)
   filevarattdef(fout,"HF_sens_ai_mo_Bering",HF_sens_ai_mo_Bering)
   filevarattdef(fout,"HF_lwup_ai_mo_Bering",HF_lwup_ai_mo_Bering)
   filevarattdef(fout,"HF_lwdn_ai_mo_Bering",HF_lwdn_ai_mo_Bering)
   filevarattdef(fout,"HF_swdn_ai_mo_Bering",HF_swdn_ai_mo_Bering)
   filevarattdef(fout,"HF_lwdn_mo_Bering",HF_lwdn_mo_Bering)
   filevarattdef(fout,"HF_swdn_mo_Bering",HF_swdn_mo_Bering)

   filevarattdef(fout,"HF_lat_ai_mo_Okhotsk",HF_lat_ai_mo_Okhotsk)
   filevarattdef(fout,"HF_surf_ai_mo_Okhotsk",HF_surf_ai_mo_Okhotsk)
   filevarattdef(fout,"HF_swabs_ai_mo_Okhotsk",HF_swabs_ai_mo_Okhotsk)
   filevarattdef(fout,"HF_sens_ai_mo_Okhotsk",HF_sens_ai_mo_Okhotsk)
   filevarattdef(fout,"HF_lwup_ai_mo_Okhotsk",HF_lwup_ai_mo_Okhotsk)
   filevarattdef(fout,"HF_lwdn_ai_mo_Okhotsk",HF_lwdn_ai_mo_Okhotsk)
   filevarattdef(fout,"HF_swdn_ai_mo_Okhotsk",HF_swdn_ai_mo_Okhotsk)
   filevarattdef(fout,"HF_lwdn_mo_Okhotsk",HF_lwdn_mo_Okhotsk)
   filevarattdef(fout,"HF_swdn_mo_Okhotsk",HF_swdn_mo_Okhotsk)

   filevarattdef(fout,"HF_surf_ai_mo_Hudson",HF_surf_ai_mo_Hudson)
   filevarattdef(fout,"HF_lat_ai_mo_Hudson",HF_lat_ai_mo_Hudson)
   filevarattdef(fout,"HF_swabs_ai_mo_Hudson",HF_swabs_ai_mo_Hudson)
   filevarattdef(fout,"HF_sens_ai_mo_Hudson",HF_swabs_ai_mo_Hudson)
   filevarattdef(fout,"HF_lwup_ai_mo_Hudson",HF_lwup_ai_mo_Hudson)
   filevarattdef(fout,"HF_lwdn_ai_mo_Hudson",HF_lwdn_ai_mo_Hudson)
   filevarattdef(fout,"HF_swdn_ai_mo_Hudson",HF_swdn_ai_mo_Hudson)
   filevarattdef(fout,"HF_lwdn_mo_Hudson",HF_lwdn_mo_Hudson)
   filevarattdef(fout,"HF_swdn_mo_Hudson",HF_swdn_mo_Hudson)

   filevarattdef(fout,"HF_surf_ai_mo_CAArch",HF_surf_ai_mo_CAArch)
   filevarattdef(fout,"HF_lat_ai_mo_CAArch",HF_lat_ai_mo_CAArch)
   filevarattdef(fout,"HF_swabs_ai_mo_CAArch",HF_swabs_ai_mo_CAArch)
   filevarattdef(fout,"HF_sens_ai_mo_CAArch",HF_sens_ai_mo_CAArch)
   filevarattdef(fout,"HF_lwup_ai_mo_CAArch",HF_lwup_ai_mo_CAArch)
   filevarattdef(fout,"HF_lwdn_ai_mo_CAArch",HF_lwdn_ai_mo_CAArch)
   filevarattdef(fout,"HF_swdn_ai_mo_CAArch",HF_swdn_ai_mo_CAArch)
   filevarattdef(fout,"HF_lwdn_mo_CAArch",HF_lwdn_mo_CAArch)
   filevarattdef(fout,"HF_swdn_mo_CAArch",HF_swdn_mo_CAArch)

   filevarattdef(fout,"HF_lat_ai_mo_Wed",HF_lat_ai_mo_Wed)
   filevarattdef(fout,"HF_surf_ai_mo_Wed",HF_surf_ai_mo_Wed)
   filevarattdef(fout,"HF_swabs_ai_mo_Wed",HF_swabs_ai_mo_Wed)
   filevarattdef(fout,"HF_sens_ai_mo_Wed",HF_sens_ai_mo_Wed)
   filevarattdef(fout,"HF_lwup_ai_mo_Wed",HF_lwup_ai_mo_Wed)
   filevarattdef(fout,"HF_lwdn_ai_mo_Wed",HF_lwdn_ai_mo_Wed)
   filevarattdef(fout,"HF_swdn_ai_mo_Wed",HF_swdn_ai_mo_Wed)
   filevarattdef(fout,"HF_lwdn_mo_Wed",HF_lwdn_mo_Wed)
   filevarattdef(fout,"HF_swdn_mo_Wed",HF_swdn_mo_Wed)

   filevarattdef(fout,"HF_lat_ai_mo_Ross",HF_lat_ai_mo_Ross)
   filevarattdef(fout,"HF_surf_ai_mo_Ross",HF_surf_ai_mo_Ross)
   filevarattdef(fout,"HF_swabs_ai_mo_Ross",HF_swabs_ai_mo_Ross)
   filevarattdef(fout,"HF_sens_ai_mo_Ross",HF_sens_ai_mo_Ross)
   filevarattdef(fout,"HF_lwup_ai_mo_Ross",HF_lwup_ai_mo_Ross)
   filevarattdef(fout,"HF_lwdn_ai_mo_Ross",HF_lwdn_ai_mo_Ross)
   filevarattdef(fout,"HF_swdn_ai_mo_Ross",HF_swdn_ai_mo_Ross)
   filevarattdef(fout,"HF_lwdn_mo_Ross",HF_lwdn_mo_Ross)
   filevarattdef(fout,"HF_swdn_mo_Ross",HF_swdn_mo_Ross)

   filevarattdef(fout,"HF_lat_ai_mo_Ind",HF_lat_ai_mo_Ind)
   filevarattdef(fout,"HF_surf_ai_mo_Ind",HF_surf_ai_mo_Ind)
   filevarattdef(fout,"HF_swabs_ai_mo_Ind",HF_swabs_ai_mo_Ind)
   filevarattdef(fout,"HF_sens_ai_mo_Ind",HF_sens_ai_mo_Ind)
   filevarattdef(fout,"HF_lwup_ai_mo_Ind",HF_lwup_ai_mo_Ind)
   filevarattdef(fout,"HF_lwdn_ai_mo_Ind",HF_lwdn_ai_mo_Ind)
   filevarattdef(fout,"HF_swdn_ai_mo_Ind",HF_swdn_ai_mo_Ind)
   filevarattdef(fout,"HF_lwdn_mo_Ind",HF_lwdn_mo_Ind)
   filevarattdef(fout,"HF_swdn_mo_Ind",HF_swdn_mo_Ind)

   filevarattdef(fout,"HF_lat_ai_mo_Pac",HF_lat_ai_mo_Pac)
   filevarattdef(fout,"HF_surf_ai_mo_Pac",HF_surf_ai_mo_Pac)
   filevarattdef(fout,"HF_swabs_ai_mo_Pac",HF_swabs_ai_mo_Pac)
   filevarattdef(fout,"HF_sens_ai_mo_Pac",HF_sens_ai_mo_Pac)
   filevarattdef(fout,"HF_lwup_ai_mo_Pac",HF_lwup_ai_mo_Pac)
   filevarattdef(fout,"HF_lwdn_ai_mo_Pac",HF_lwdn_ai_mo_Pac)
   filevarattdef(fout,"HF_swdn_ai_mo_Pac",HF_swdn_ai_mo_Pac)
   filevarattdef(fout,"HF_lwdn_mo_Pac",HF_lwdn_mo_Pac)
   filevarattdef(fout,"HF_swdn_mo_Pac",HF_swdn_mo_Pac)

   filevarattdef(fout,"HF_lat_ai_mo_BAm",HF_lat_ai_mo_BAm)
   filevarattdef(fout,"HF_surf_ai_mo_BAm",HF_surf_ai_mo_BAm)
   filevarattdef(fout,"HF_swabs_ai_mo_BAm",HF_swabs_ai_mo_BAm)
   filevarattdef(fout,"HF_sens_ai_mo_BAm",HF_sens_ai_mo_BAm)
   filevarattdef(fout,"HF_lwup_ai_mo_BAm",HF_lwup_ai_mo_BAm)
   filevarattdef(fout,"HF_lwdn_ai_mo_BAm",HF_lwdn_ai_mo_BAm)
   filevarattdef(fout,"HF_swdn_ai_mo_BAm",HF_swdn_ai_mo_BAm)
   filevarattdef(fout,"HF_lwdn_mo_BAm",HF_lwdn_mo_BAm)
   filevarattdef(fout,"HF_swdn_mo_BAm",HF_swdn_mo_BAm)

   fout->time = time
   fout->HF_lat_ai_mo_nh = HF_lat_ai_mo_nh
   fout->HF_surf_ai_mo_nh = HF_surf_ai_mo_nh
   fout->HF_swabs_ai_mo_nh = HF_swabs_ai_mo_nh
   fout->HF_sens_ai_mo_nh = HF_sens_ai_mo_nh
   fout->HF_lwup_ai_mo_nh = HF_lwup_ai_mo_nh
   fout->HF_lwdn_ai_mo_nh = HF_lwdn_ai_mo_nh
   fout->HF_swdn_ai_mo_nh = HF_swdn_ai_mo_nh
   fout->HF_lwdn_mo_nh = HF_lwdn_mo_nh
   fout->HF_swdn_mo_nh = HF_swdn_mo_nh
   fout->HF_lwdn_mo_nh50_90 = HF_lwdn_mo_nh50_90
   fout->HF_swdn_mo_nh50_90 = HF_swdn_mo_nh50_90

   fout->HF_surf_ai_mo_sh = HF_surf_ai_mo_sh
   fout->HF_lat_ai_mo_sh = HF_lat_ai_mo_sh
   fout->HF_swabs_ai_mo_sh = HF_swabs_ai_mo_sh
   fout->HF_sens_ai_mo_sh = HF_sens_ai_mo_sh
   fout->HF_lwup_ai_mo_sh = HF_lwup_ai_mo_sh
   fout->HF_lwdn_ai_mo_sh = HF_lwdn_ai_mo_sh
   fout->HF_swdn_ai_mo_sh = HF_swdn_ai_mo_sh
   fout->HF_lwdn_mo_sh = HF_lwdn_mo_sh
   fout->HF_swdn_mo_sh = HF_swdn_mo_sh
   fout->HF_lwdn_mo_sh50_90 = HF_lwdn_mo_sh50_90
   fout->HF_swdn_mo_sh50_90 = HF_swdn_mo_sh50_90

   fout->HF_lat_ai_mo_Lab = HF_lat_ai_mo_Lab
   fout->HF_surf_ai_mo_Lab = HF_surf_ai_mo_Lab
   fout->HF_swabs_ai_mo_Lab = HF_swabs_ai_mo_Lab
   fout->HF_sens_ai_mo_Lab = HF_sens_ai_mo_Lab
   fout->HF_lwup_ai_mo_Lab = HF_lwup_ai_mo_Lab
   fout->HF_lwdn_ai_mo_Lab = HF_lwdn_ai_mo_Lab
   fout->HF_swdn_ai_mo_Lab = HF_swdn_ai_mo_Lab
   fout->HF_lwdn_mo_Lab = HF_lwdn_mo_Lab
   fout->HF_swdn_mo_Lab = HF_swdn_mo_Lab

   fout->HF_lat_ai_mo_GIN = HF_lat_ai_mo_GIN
   fout->HF_surf_ai_mo_GIN = HF_surf_ai_mo_GIN
   fout->HF_swabs_ai_mo_GIN = HF_swabs_ai_mo_GIN
   fout->HF_sens_ai_mo_GIN = HF_sens_ai_mo_GIN
   fout->HF_lwup_ai_mo_GIN = HF_lwup_ai_mo_GIN
   fout->HF_lwdn_ai_mo_GIN = HF_lwdn_ai_mo_GIN
   fout->HF_swdn_ai_mo_GIN = HF_swdn_ai_mo_GIN
   fout->HF_lwdn_mo_GIN = HF_lwdn_mo_GIN
   fout->HF_swdn_mo_GIN = HF_swdn_mo_GIN

   fout->HF_lat_ai_mo_Bar = HF_lat_ai_mo_Bar
   fout->HF_surf_ai_mo_Bar = HF_surf_ai_mo_Bar
   fout->HF_swabs_ai_mo_Bar = HF_swabs_ai_mo_Bar
   fout->HF_sens_ai_mo_Bar = HF_sens_ai_mo_Bar
   fout->HF_lwup_ai_mo_Bar = HF_lwup_ai_mo_Bar
   fout->HF_lwdn_ai_mo_Bar = HF_lwdn_ai_mo_Bar
   fout->HF_swdn_ai_mo_Bar = HF_swdn_ai_mo_Bar
   fout->HF_lwdn_mo_Bar = HF_lwdn_mo_Bar
   fout->HF_swdn_mo_Bar = HF_swdn_mo_Bar

   fout->HF_lat_ai_mo_ArcOc = HF_lat_ai_mo_ArcOc
   fout->HF_surf_ai_mo_ArcOc = HF_surf_ai_mo_ArcOc
   fout->HF_swabs_ai_mo_ArcOc = HF_swabs_ai_mo_ArcOc
   fout->HF_sens_ai_mo_ArcOc = HF_sens_ai_mo_ArcOc
   fout->HF_lwup_ai_mo_ArcOc = HF_lwup_ai_mo_ArcOc
   fout->HF_lwdn_ai_mo_ArcOc = HF_lwdn_ai_mo_ArcOc
   fout->HF_swdn_ai_mo_ArcOc = HF_swdn_ai_mo_ArcOc
   fout->HF_lwdn_mo_ArcOc = HF_lwdn_mo_ArcOc
   fout->HF_swdn_mo_ArcOc = HF_swdn_mo_ArcOc

   fout->HF_lat_ai_mo_Kara = HF_lat_ai_mo_Kara
   fout->HF_surf_ai_mo_Kara = HF_surf_ai_mo_Kara
   fout->HF_swabs_ai_mo_Kara = HF_swabs_ai_mo_Kara
   fout->HF_sens_ai_mo_Kara = HF_sens_ai_mo_Kara
   fout->HF_lwup_ai_mo_Kara = HF_lwup_ai_mo_Kara
   fout->HF_lwdn_ai_mo_Kara = HF_lwdn_ai_mo_Kara
   fout->HF_swdn_ai_mo_Kara = HF_swdn_ai_mo_Kara
   fout->HF_lwdn_mo_Kara = HF_lwdn_mo_Kara
   fout->HF_swdn_mo_Kara = HF_swdn_mo_Kara

   fout->HF_lat_ai_mo_Laptev = HF_lat_ai_mo_Laptev
   fout->HF_surf_ai_mo_Laptev = HF_surf_ai_mo_Laptev
   fout->HF_swabs_ai_mo_Laptev = HF_swabs_ai_mo_Laptev
   fout->HF_sens_ai_mo_Laptev = HF_sens_ai_mo_Laptev
   fout->HF_lwup_ai_mo_Laptev = HF_lwup_ai_mo_Laptev
   fout->HF_lwdn_ai_mo_Laptev = HF_lwdn_ai_mo_Laptev
   fout->HF_swdn_ai_mo_Laptev = HF_swdn_ai_mo_Laptev
   fout->HF_lwdn_mo_Laptev = HF_lwdn_mo_Laptev
   fout->HF_swdn_mo_Laptev = HF_swdn_mo_Laptev

   fout->HF_lat_ai_mo_Chukchi = HF_lat_ai_mo_Chukchi
   fout->HF_surf_ai_mo_Chukchi = HF_surf_ai_mo_Chukchi
   fout->HF_swabs_ai_mo_Chukchi = HF_swabs_ai_mo_Chukchi
   fout->HF_sens_ai_mo_Chukchi = HF_sens_ai_mo_Chukchi
   fout->HF_lwup_ai_mo_Chukchi = HF_lwup_ai_mo_Chukchi
   fout->HF_lwdn_ai_mo_Chukchi = HF_lwdn_ai_mo_Chukchi
   fout->HF_swdn_ai_mo_Chukchi = HF_swdn_ai_mo_Chukchi
   fout->HF_lwdn_mo_Chukchi = HF_lwdn_mo_Chukchi
   fout->HF_swdn_mo_Chukchi = HF_swdn_mo_Chukchi

   fout->HF_lat_ai_mo_Sib = HF_lat_ai_mo_Sib
   fout->HF_surf_ai_mo_Sib = HF_surf_ai_mo_Sib
   fout->HF_swabs_ai_mo_Sib = HF_swabs_ai_mo_Sib
   fout->HF_sens_ai_mo_Sib = HF_sens_ai_mo_Sib
   fout->HF_lwup_ai_mo_Sib = HF_lwup_ai_mo_Sib
   fout->HF_lwdn_ai_mo_Sib = HF_lwdn_ai_mo_Sib
   fout->HF_swdn_ai_mo_Sib = HF_swdn_ai_mo_Sib
   fout->HF_lwdn_mo_Sib = HF_lwdn_mo_Sib
   fout->HF_swdn_mo_Sib = HF_swdn_mo_Sib

   fout->HF_lat_ai_mo_Beau = HF_lat_ai_mo_Beau
   fout->HF_surf_ai_mo_Beau = HF_surf_ai_mo_Beau
   fout->HF_swabs_ai_mo_Beau = HF_swabs_ai_mo_Beau
   fout->HF_sens_ai_mo_Beau = HF_sens_ai_mo_Beau
   fout->HF_lwup_ai_mo_Beau = HF_lwup_ai_mo_Beau
   fout->HF_lwdn_ai_mo_Beau = HF_lwdn_ai_mo_Beau
   fout->HF_swdn_ai_mo_Beau = HF_swdn_ai_mo_Beau
   fout->HF_lwdn_mo_Beau = HF_lwdn_mo_Beau
   fout->HF_swdn_mo_Beau = HF_swdn_mo_Beau

   fout->HF_lat_ai_mo_CArc = HF_lat_ai_mo_CArc
   fout->HF_surf_ai_mo_CArc = HF_surf_ai_mo_CArc
   fout->HF_swabs_ai_mo_CArc = HF_swabs_ai_mo_CArc
   fout->HF_sens_ai_mo_CArc = HF_sens_ai_mo_CArc
   fout->HF_lwup_ai_mo_CArc = HF_lwup_ai_mo_CArc
   fout->HF_lwdn_ai_mo_CArc = HF_lwdn_ai_mo_CArc
   fout->HF_swdn_ai_mo_CArc = HF_swdn_ai_mo_CArc
   fout->HF_lwdn_mo_CArc = HF_lwdn_mo_CArc
   fout->HF_swdn_mo_CArc = HF_swdn_mo_CArc

   fout->HF_lat_ai_mo_Bering = HF_lat_ai_mo_Bering
   fout->HF_surf_ai_mo_Bering = HF_surf_ai_mo_Bering
   fout->HF_swabs_ai_mo_Bering = HF_swabs_ai_mo_Bering
   fout->HF_sens_ai_mo_Bering = HF_sens_ai_mo_Bering
   fout->HF_lwup_ai_mo_Bering = HF_lwup_ai_mo_Bering
   fout->HF_lwdn_ai_mo_Bering = HF_lwdn_ai_mo_Bering
   fout->HF_swdn_ai_mo_Bering = HF_swdn_ai_mo_Bering
   fout->HF_lwdn_mo_Bering = HF_lwdn_mo_Bering
   fout->HF_swdn_mo_Bering = HF_swdn_mo_Bering

   fout->HF_lat_ai_mo_Okhotsk = HF_lat_ai_mo_Okhotsk
   fout->HF_surf_ai_mo_Okhotsk = HF_surf_ai_mo_Okhotsk
   fout->HF_swabs_ai_mo_Okhotsk = HF_swabs_ai_mo_Okhotsk
   fout->HF_sens_ai_mo_Okhotsk = HF_sens_ai_mo_Okhotsk
   fout->HF_lwup_ai_mo_Okhotsk = HF_lwup_ai_mo_Okhotsk
   fout->HF_lwdn_ai_mo_Okhotsk = HF_lwdn_ai_mo_Okhotsk
   fout->HF_swdn_ai_mo_Okhotsk = HF_swdn_ai_mo_Okhotsk
   fout->HF_lwdn_mo_Okhotsk = HF_lwdn_mo_Okhotsk
   fout->HF_swdn_mo_Okhotsk = HF_swdn_mo_Okhotsk

   fout->HF_lat_ai_mo_Hudson = HF_lat_ai_mo_Hudson
   fout->HF_surf_ai_mo_Hudson = HF_surf_ai_mo_Hudson
   fout->HF_swabs_ai_mo_Hudson = HF_swabs_ai_mo_Hudson
   fout->HF_sens_ai_mo_Hudson = HF_sens_ai_mo_Hudson
   fout->HF_lwup_ai_mo_Hudson = HF_lwup_ai_mo_Hudson
   fout->HF_lwdn_ai_mo_Hudson = HF_lwdn_ai_mo_Hudson
   fout->HF_swdn_ai_mo_Hudson = HF_swdn_ai_mo_Hudson
   fout->HF_lwdn_mo_Hudson = HF_lwdn_mo_Hudson
   fout->HF_swdn_mo_Hudson = HF_swdn_mo_Hudson

   fout->HF_lat_ai_mo_CAArch = HF_lat_ai_mo_CAArch
   fout->HF_surf_ai_mo_CAArch = HF_surf_ai_mo_CAArch
   fout->HF_swabs_ai_mo_CAArch = HF_swabs_ai_mo_CAArch
   fout->HF_sens_ai_mo_CAArch = HF_sens_ai_mo_CAArch
   fout->HF_lwup_ai_mo_CAArch = HF_lwup_ai_mo_CAArch
   fout->HF_lwdn_ai_mo_CAArch = HF_lwdn_ai_mo_CAArch
   fout->HF_swdn_ai_mo_CAArch = HF_swdn_ai_mo_CAArch
   fout->HF_lwdn_mo_CAArch = HF_lwdn_mo_CAArch
   fout->HF_swdn_mo_CAArch = HF_swdn_mo_CAArch

   fout->HF_lat_ai_mo_Wed = HF_lat_ai_mo_Wed
   fout->HF_surf_ai_mo_Wed = HF_surf_ai_mo_Wed
   fout->HF_swabs_ai_mo_Wed = HF_swabs_ai_mo_Wed
   fout->HF_sens_ai_mo_Wed = HF_sens_ai_mo_Wed
   fout->HF_lwup_ai_mo_Wed = HF_lwup_ai_mo_Wed
   fout->HF_lwdn_ai_mo_Wed = HF_lwdn_ai_mo_Wed
   fout->HF_swdn_ai_mo_Wed = HF_swdn_ai_mo_Wed
   fout->HF_lwdn_mo_Wed = HF_lwdn_mo_Wed
   fout->HF_swdn_mo_Wed = HF_swdn_mo_Wed

   fout->HF_lat_ai_mo_Ross = HF_lat_ai_mo_Ross
   fout->HF_surf_ai_mo_Ross = HF_surf_ai_mo_Ross
   fout->HF_swabs_ai_mo_Ross = HF_swabs_ai_mo_Ross
   fout->HF_sens_ai_mo_Ross = HF_sens_ai_mo_Ross
   fout->HF_lwup_ai_mo_Ross = HF_lwup_ai_mo_Ross
   fout->HF_lwdn_ai_mo_Ross = HF_lwdn_ai_mo_Ross
   fout->HF_swdn_ai_mo_Ross = HF_swdn_ai_mo_Ross
   fout->HF_lwdn_mo_Ross = HF_lwdn_mo_Ross
   fout->HF_swdn_mo_Ross = HF_swdn_mo_Ross

   fout->HF_lat_ai_mo_Ind = HF_lat_ai_mo_Ind
   fout->HF_surf_ai_mo_Ind = HF_surf_ai_mo_Ind
   fout->HF_swabs_ai_mo_Ind = HF_swabs_ai_mo_Ind
   fout->HF_sens_ai_mo_Ind = HF_sens_ai_mo_Ind
   fout->HF_lwup_ai_mo_Ind = HF_lwup_ai_mo_Ind
   fout->HF_lwdn_ai_mo_Ind = HF_lwdn_ai_mo_Ind
   fout->HF_swdn_ai_mo_Ind = HF_swdn_ai_mo_Ind
   fout->HF_lwdn_mo_Ind = HF_lwdn_mo_Ind
   fout->HF_swdn_mo_Ind = HF_swdn_mo_Ind

   fout->HF_lat_ai_mo_Pac = HF_lat_ai_mo_Pac
   fout->HF_surf_ai_mo_Pac = HF_surf_ai_mo_Pac
   fout->HF_swabs_ai_mo_Pac = HF_swabs_ai_mo_Pac
   fout->HF_sens_ai_mo_Pac = HF_sens_ai_mo_Pac
   fout->HF_lwup_ai_mo_Pac = HF_lwup_ai_mo_Pac
   fout->HF_lwdn_ai_mo_Pac = HF_lwdn_ai_mo_Pac
   fout->HF_swdn_ai_mo_Pac = HF_swdn_ai_mo_Pac
   fout->HF_lwdn_mo_Pac = HF_lwdn_mo_Pac
   fout->HF_swdn_mo_Pac = HF_swdn_mo_Pac

   fout->HF_lat_ai_mo_BAm = HF_lat_ai_mo_BAm
   fout->HF_surf_ai_mo_BAm = HF_surf_ai_mo_BAm
   fout->HF_swabs_ai_mo_BAm = HF_swabs_ai_mo_BAm
   fout->HF_sens_ai_mo_BAm = HF_sens_ai_mo_BAm
   fout->HF_lwup_ai_mo_BAm = HF_lwup_ai_mo_BAm
   fout->HF_lwdn_ai_mo_BAm = HF_lwdn_ai_mo_BAm
   fout->HF_swdn_ai_mo_BAm = HF_swdn_ai_mo_BAm
   fout->HF_lwdn_mo_BAm = HF_lwdn_mo_BAm
   fout->HF_swdn_mo_BAm = HF_swdn_mo_BAm

end do 						; end do ii
end
