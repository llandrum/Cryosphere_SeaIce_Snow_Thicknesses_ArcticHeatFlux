; modified for use with calculated fcondtop_ais and for NH only.
; LLandrum
; Oct 2020
;
; modified to calculate average or total of user-named variable
; for Arctic regions.
; LLandrum
; August 2020
;
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
  var_name = "fcondtop_daily2monthly_ai"				; choices are fcondtop_mean_ai (calculated from monthly means, aice weighted), 
							; fcondtop_nthick_ai (calculated from monthly means from ice thickness categories, aice weighted)
  							; or fcondtop_daily2monthly_nthick_ai (calculated from daily hi, hs, aice and atm TS, aice weighted)
    							; or these same variables not aice-weighted (fcondtop_mean, fcondtop_thick, fcondtop_daily2monthly_nthick)
  var_type = "daily2monthly"				; choices are monthly or daily2monthly

  regional_type = "avg"					; choices are "avg" or "total"
  var_out_name = var_name+"_"+regional_type
  if (regional_type.eq."avg") then
     var_units = "W/m2"                                 ; make sure this matches for avg or total
  else
     var_units = "W"					; make sure this matches for avg or total
  end if

  LE_20thC_case = "b.e11.B20TRC5CNBDRD.f09_g16."
  LE_rcp_case = "b.e11.BRCP85C5CNBDRD.f09_g16."
;  case_numbers = ispan(1,40,1)
;  case_numbers(35:) = ispan(101,105,1)
  case_numbers = ispan(1,33,1)
;  case_numbers = ispan(34,35,1)
;  case_numbers = ispan(101,105,1)
  scnumbers = sprinti("%0.3i",case_numbers)

  hist_case = LE_20thC_case+scnumbers(0)
  c20thC_case = LE_20thC_case+ scnumbers
  rcp85_case = LE_rcp_case+scnumbers

;  case_names = c20thC_case
  case_names = rcp85_case
  ncase = dimsizes(case_names)

  data_dir = "/glade/p/cesm/pcwg/landrum/LE/ice/fcondtop_ai/calcs/"
  tseries_dir = data_dir+var_type+"/"
  out_dir = data_dir+"pre_process/"+var_name+"/"

  yr1 = new(ncase,integer)
;  yr1 = 1920							; start and end yrs for time series
;  yr1(0) = 1850
;  yr1(33:) = 2006
;  yr1 = 2006
  yr1 = 2081
  yr2 = yr1
;  yr2 = 2005
;  yr2 = 2080
  yr2 = 2100
;  yr2(33:) = 2100
;  yr1_proc = 1920                                                  ; start and end yrs for pre-processed time series
;  yr2_proc = 2005
;  yr1_proc = 2006
;  yr2_proc = 2080
  yr1_proc = 2081
  yr2_proc = 2100
  nyears = yr2_proc - yr1_proc + 1

  offset = (yr1_proc - yr1)*12

  styrs = sprinti("%0.4i",yr1) + "01-"+sprinti("%0.4i",yr2)+"12"
  styrs_proc = sprinti("%0.4i",yr1_proc) + "-"+sprinti("%0.4i",yr2_proc)

  if (var_type.eq."monthly") then
     fvar_nh = tseries_dir+case_names+".fcondtop_ai_calcs_nh."+styrs+".nc"
  else
     fvar_nh = tseries_dir+case_names+".daily2monthly_fcondtop_ai_nh."+styrs+".nc"
  end if

  if (.not.(isfilepresent(out_dir))) then
     system("mkdir "+out_dir)
  end if
;--------------------------------------------------------------------
; set names for output variables
;--------------------------------------------------------------------

   var_out_name = var_name+"_"+regional_type

   out_var_mo_nh = var_out_name+"_mo_nh"
   out_var_mo_nh50_90 = var_out_name+"_mo_nh50_90"

   out_var_mo_sh = var_out_name+"_mo_sh"
   out_var_mo_sh50_90 = var_out_name+"_mo_sh50_90"

   out_var_mo_Lab = var_out_name+"_mo_Lab"
   out_var_mo_GIN = var_out_name+"_mo_GIN"
   out_var_mo_Bar = var_out_name+"_mo_Bar"
   out_var_mo_ArcOc = var_out_name+"_mo_ArcOc"
   out_var_mo_Kara = var_out_name+"_mo_Kara"
   out_var_mo_Laptev = var_out_name+"_mo_Laptev"
   out_var_mo_Chukchi = var_out_name+"_mo_Chukchi"
   out_var_mo_Sib = var_out_name+"_mo_Sib"
   out_var_mo_Beau = var_out_name+"_mo_Beau"
   out_var_mo_CArc = var_out_name+"_mo_CArc"
   out_var_mo_Bering = var_out_name+"_mo_Bering"
   out_var_mo_Okhotsk = var_out_name+"_mo_Okhotsk"
   out_var_mo_Hudson = var_out_name+"_mo_Hudson"
   out_var_mo_CAArch = var_out_name+"_mo_CAArch"

;   out_var_mo_Wed = var_out_name+"_mo_Wed"
;   out_var_mo_Ross = var_out_name+"_mo_Ross"
;   out_var_mo_Ind = var_out_name+"_mo_Ind"
;   out_var_mo_Pac = var_out_name+"_mo_Pac"
;   out_var_mo_BAm = var_out_name+"_mo_BAm"

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
;  sh50_90_lat = (/-90.,-50./)
;  Wed_lat = (/-90.,-50./)
;  Wed_long1 = (/300.,360./)
;  Wed_long2 = (/0.,20./)
;  Ross_lat = (/-90.,-50./)
;  Ross_long = (/160.,220./)
;  Ind_lat = (/-90.,-50./)
;  Ind_long = (/20.,90./)
;  Pac_lat = (/-90.,-50./)
;  Pac_long = (/90.,160./)
;  BAm_lat = (/-90.,-50./)
;  BAm_long = (/220.,300./)

  var_mo_nh = new((/nyears*12/),float)
;  var_mo_sh = new((/nyears*12/),float)

  var_mo_nh50_90 = new((/nyears*12/),float)
;  var_mo_sh50_90 = new((/nyears*12/),float)

;*****************************
; regional arrays: Arctic
;*****************************
  var_mo_Lab = new((/nyears*12/),float)
  var_mo_GIN = new((/nyears*12/),float)
  var_mo_Bar = new((/nyears*12/),float)
  var_mo_ArcOc = new((/nyears*12/),float)
  var_mo_Kara = new((/nyears*12/),float)
  var_mo_Laptev = new((/nyears*12/),float)
  var_mo_Chukchi = new((/nyears*12/),float)
  var_mo_Sib = new((/nyears*12/),float)
  var_mo_Beau = new((/nyears*12/),float)
  var_mo_CArc = new((/nyears*12/),float)
  var_mo_Bering = new((/nyears*12/),float)
  var_mo_Okhotsk = new((/nyears*12/),float)
  var_mo_Hudson = new((/nyears*12/),float)
  var_mo_CAArch = new((/nyears*12/),float)
; regional arrays: Antarctic
;*****************************
;  var_mo_Wed = new((/nyears*12/),float)
;  var_mo_Ross = new((/nyears*12/),float)
;  var_mo_Ind = new((/nyears*12/),float)
;  var_mo_Pac = new((/nyears*12/),float)
;  var_mo_BAm = new((/nyears*12/),float)
;  time = new((/nyears*12/),float)

do ii = 0,ncase-1
   print("calculating "+var_name+" area totals for "+case_names(ii))
   f1_nh = addfile(fvar_nh(ii),"r")
;   f1_sh = addfile(fvar_sh(ii),"r")

   do nn = 0, nyears-1

      imo1 = 12*nn
      imo2 = 12*nn+11

      imo1_datain = offset(ii) + 12*nn
      imo2_datain = offset(ii) + 12*nn+11

      tmpvar_nh = f1_nh->$var_name$(imo1_datain:imo2_datain,:,:)
;      tmpvar_sh = f1_sh->$var_name$(imo1_datain:imo2_datain,:,:)

      if ((ii.eq.0).and.(nn .eq. 0)) then
         tarea_nh = f1_nh->tarea
         tlat_nh  = f1_nh->TLAT
         tlon_nh = f1_nh->TLON
         it2 = offset(ii) + (nyears*12) - 1
         time = f1_nh->time(imo1_datain:it2)

;         tarea_sh = f1_sh->tarea
;         tlat_sh  = f1_sh->TLAT
;         tlon_sh = f1_sh->TLON
      end if

      tlat2_nh = conform(tmpvar_nh,tlat_nh,(/1,2/))
      tlon2_nh = conform(tmpvar_nh,tlon_nh,(/1,2/))
      var_nh = tmpvar_nh*conform(tmpvar_nh,tarea_nh,(/1,2/))

;      tlat2_sh = conform(tmpvar_sh,tlat_sh,(/1,2/))
;      tlon2_sh = conform(tmpvar_sh,tlon_sh,(/1,2/))
;      var_sh = tmpvar_sh*conform(tmpvar_sh,tarea_sh,(/1,2/))
;-------------------------------------------------------------
; create masks for Labrador Sea, Bering Sea, Sea of Okhotsk,
; Hudson Bay and Canadian Archipelago here. They are not simply
; rectangles...........
; Only need to do this once (first year of nyears)
;------------------------------------------------------------
      if ((ii.eq.0).and.(nn .eq. 0)) then
         Lab_mask = new(dimsizes(var_nh),typeof(var_nh),var_nh@_FillValue)
         Bering_mask = new(dimsizes(var_nh),typeof(var_nh),var_nh@_FillValue)
         Okhotsk_mask = new(dimsizes(var_nh),typeof(var_nh),var_nh@_FillValue)
         CAArch_mask = new(dimsizes(var_nh),typeof(var_nh),var_nh@_FillValue)
         Hudson_mask = new(dimsizes(var_nh),typeof(var_nh),var_nh@_FillValue)
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

         if (regional_type.eq."avg") then					; calculate area-averages
            valid_nh = tmpvar_nh(0,:,:)
            valid_nh = where(.not.(ismissing(tmpvar_nh(0,:,:))),1.,var_nh@_FillValue)
;            valid_sh = tmpvar_sh(0,:,:)
;            valid_sh = where(.not.(ismissing(tmpvar_sh(0,:,:))),1.,var_sh@_FillValue)

            tarea_nh_valid = tarea_nh*valid_nh
;            tarea_sh_valid = tarea_sh*valid_sh

            tlat2d_nh = tlat2_nh(0,:,:)
            tlon2d_nh = tlon2_nh(0,:,:)
;            tlat2d_sh = tlat2_sh(0,:,:)
;            tlon2d_sh = tlon2_sh(0,:,:)

            tarea_nh50_90 = mask(tarea_nh_valid,(tlat2d_nh.ge.nh50_90_lat(0) .and. tlat2d_nh.le.nh50_90_lat(1)),True)
;            tarea_sh50_90 = mask(tarea_sh_valid,(tlat2d_sh.ge.sh50_90_lat(0) .and. tlat2d_sh.le.sh50_90_lat(1)),True)

            tarea_Lab = mask(tarea_nh_valid,(Lab_mask(0,:,:) .eq. 1.), True)

            tarea_GIN = mask(tarea_nh_valid,(tlat2d_nh.ge.GIN_lat(0) .and. tlat2d_nh.le.GIN_lat(1) .and.\
                           ((tlon2d_nh.ge.GIN_long1(0) .and. tlon2d_nh.le.GIN_long1(1)) .or.\
                           (tlon2d_nh.ge.GIN_long2(0) .and. tlon2d_nh.le.GIN_long2(1)))), True)
            tarea_Bar = mask(tarea_nh_valid,(tlat2d_nh.ge.Bar_lat(0) .and. tlat2d_nh.le.Bar_lat(1) .and.\
                           tlon2d_nh.ge.Bar_long(0) .and. tlon2d_nh.le.Bar_long(1)), True)
            tarea_ArcOc = mask(tarea_nh_valid,((tlat2d_nh.ge.ArcOc_lat1(0) .and. (tlon2d_nh.ge.ArcOc_long1(0) .or.\
                              tlon2d_nh.le.ArcOc_long2(1))) .or. (tlat2d_nh.ge.ArcOc_lat3(0) .and.\
                              (tlon2d_nh.ge.ArcOc_long3(0) .and. tlon2d_nh.le.ArcOc_long3(1)))), True)
            tarea_Kara = mask(tarea_nh_valid,(tlat2d_nh.ge.Kara_lat(0) .and. tlat2d_nh.le.Kara_lat(1) .and.\
                             tlon2d_nh.ge.Kara_long(0) .and. tlon2d_nh.le.Kara_long(1)), True)
            tarea_Laptev = mask(tarea_nh_valid,(tlat2d_nh.ge.Laptev_lat(0) .and. tlat2d_nh.le.Laptev_lat(1) .and.\
                              tlon2d_nh.ge.Laptev_long(0) .and. tlon2d_nh.le.Laptev_long(1)), True)
            tarea_Chukchi = mask(tarea_nh_valid,(tlat2d_nh.ge.Chukchi_lat(0) .and. tlat2d_nh.le.Chukchi_lat(1) .and.\
                              tlon2d_nh.ge.Chukchi_long(0) .and. tlon2d_nh.le.Chukchi_long(1)), True)

            tarea_Sib = mask(tarea_nh_valid,(tlat2d_nh.ge.Sib_lat(0) .and. tlat2d_nh.le.Sib_lat(1) .and.\
                              tlon2d_nh.ge.Sib_long(0) .and. tlon2d_nh.le.Sib_long(1)), True)

            tarea_Beau = mask(tarea_nh_valid,(tlat2d_nh.ge.Beau_lat(0) .and. tlat2d_nh.le.Beau_lat(1) .and.\
                              tlon2d_nh.ge.Beau_long(0) .and. tlon2d_nh.le.Beau_long(1)), True)

            tarea_CArc = mask(tarea_nh_valid,(tlat2d_nh.ge.CArc_lat(0) .and. tlat2d_nh.le.CArc_lat(1) .and.\
                              tlon2d_nh.ge.CArc_long(0) .and. tlon2d_nh.le.CArc_long(1)), True)

            tarea_Bering = mask(tarea_nh_valid,(Bering_mask(0,:,:) .eq. 1.), True)
            tarea_Okhotsk = mask(tarea_nh_valid,(Okhotsk_mask(0,:,:) .eq. 1.), True)
            tarea_Hudson = mask(tarea_nh_valid,(Hudson_mask(0,:,:) .eq. 1.), True)
            tarea_CAArch = mask(tarea_nh_valid,(CAArch_mask(0,:,:) .eq. 1.), True)

;            tarea_Wed = mask(tarea_sh_valid,(tlat2d_sh.le.Wed_lat(1) .and. ((tlon2d_sh.ge.Wed_long1(0) \
;                           .and. tlon2d_sh.le.Wed_long1(1)) .or. (tlon2d_sh.ge.Wed_long2(0) \
;                           .and. tlon2d_sh.le.Wed_long2(1)))), True)

;            tarea_Ross = mask(tarea_sh_valid,(tlat2d_sh.le.Ross_lat(1) .and. tlon2d_sh.ge.Ross_long(0) \
;                            .and. tlon2d_sh.le.Ross_long(1)), True)

;            tarea_Ind = mask(tarea_sh_valid,(tlat2d_sh.le.Ind_lat(1) .and. tlon2d_sh.ge.Ind_long(0) \
;                           .and. tlon2d_sh.le.Ind_long(1)), True)

;            tarea_Pac = mask(tarea_sh_valid,(tlat2d_sh.le.Pac_lat(1) .and. tlon2d_sh.ge.Pac_long(0) \
;                           .and. tlon2d_sh.le.Pac_long(1)), True)

;            tarea_BAm = mask(tarea_sh_valid,(tlat2d_sh.le.BAm_lat(1) .and. tlon2d_sh.ge.BAm_long(0) \
;                           .and. tlon2d_sh.le.BAm_long(1)), True)

            area_nh = dim_sum(dim_sum(tarea_nh_valid))
            area_Lab = dim_sum(dim_sum(tarea_Lab))
            area_GIN = dim_sum(dim_sum(tarea_GIN))

            area_Bar = dim_sum(dim_sum(tarea_Bar))
            area_ArcOc = dim_sum(dim_sum(tarea_ArcOc))

            area_Kara = dim_sum(dim_sum(tarea_Kara))

            area_Laptev = dim_sum(dim_sum(tarea_Laptev))
            area_Chukchi = dim_sum(dim_sum(tarea_Chukchi))
            area_Sib = dim_sum(dim_sum(tarea_Sib))
            area_Beau = dim_sum(dim_sum(tarea_Beau))
            area_CArc = dim_sum(dim_sum(tarea_CArc))
            area_Bering = dim_sum(dim_sum(tarea_Bering))

            area_Okhotsk = dim_sum(dim_sum(tarea_Okhotsk))
            area_Hudson = dim_sum(dim_sum(tarea_Hudson))
            area_CAArch = dim_sum(dim_sum(tarea_CAArch))

;            area_sh = dim_sum(dim_sum(tarea_sh_valid))
;            area_Wed = dim_sum(dim_sum(tarea_Wed))
;            area_Ross = dim_sum(dim_sum(tarea_Ross))
;            area_Ind = dim_sum(dim_sum(tarea_Ind))
;            area_Pac = dim_sum(dim_sum(tarea_Pac))
;            area_BAm = dim_sum(dim_sum(tarea_BAm))

            area_nh50_90 = dim_sum(dim_sum(tarea_nh50_90))
;            area_sh50_90 = dim_sum(dim_sum(tarea_sh50_90))

         end if

      end if

      var_nh50_90 = mask(var_nh,(tlat2_nh.ge.nh50_90_lat(0) .and. tlat2_nh.le.nh50_90_lat(1)),True)
      var_Lab = mask(var_nh,(Lab_mask .eq. 1.), True)
 
      var_GIN = mask(var_nh,(tlat2_nh.ge.GIN_lat(0) .and. tlat2_nh.le.GIN_lat(1) .and.\
                  ((tlon2_nh.ge.GIN_long1(0) .and. tlon2_nh.le.GIN_long1(1)) .or.\
                   (tlon2_nh.ge.GIN_long2(0) .and. tlon2_nh.le.GIN_long2(1)))), True)

      var_Bar = mask(var_nh,(tlat2_nh.ge.Bar_lat(0) .and. tlat2_nh.le.Bar_lat(1) .and.\
                  tlon2_nh.ge.Bar_long(0) .and. tlon2_nh.le.Bar_long(1)), True)

      var_ArcOc = mask(var_nh,((tlat2_nh.ge.ArcOc_lat1(0) .and. (tlon2_nh.ge.ArcOc_long1(0) .or.\
                  tlon2_nh.le.ArcOc_long2(1))) .or. (tlat2_nh.ge.ArcOc_lat3(0) .and.\
                   (tlon2_nh.ge.ArcOc_long3(0) .and. tlon2_nh.le.ArcOc_long3(1)))), True)

      var_Kara = mask(var_nh,(tlat2_nh.ge.Kara_lat(0) .and. tlat2_nh.le.Kara_lat(1) .and.\
                  tlon2_nh.ge.Kara_long(0) .and. tlon2_nh.le.Kara_long(1)), True)

      var_Laptev = mask(var_nh,(tlat2_nh.ge.Laptev_lat(0) .and. tlat2_nh.le.Laptev_lat(1) .and.\
                  tlon2_nh.ge.Laptev_long(0) .and. tlon2_nh.le.Laptev_long(1)), True)

      var_Chukchi = mask(var_nh,(tlat2_nh.ge.Chukchi_lat(0) .and. tlat2_nh.le.Chukchi_lat(1) .and.\
                  tlon2_nh.ge.Chukchi_long(0) .and. tlon2_nh.le.Chukchi_long(1)), True)

      var_Sib = mask(var_nh,(tlat2_nh.ge.Sib_lat(0) .and. tlat2_nh.le.Sib_lat(1) .and.\
                  tlon2_nh.ge.Sib_long(0) .and. tlon2_nh.le.Sib_long(1)), True)

      var_Beau = mask(var_nh,(tlat2_nh.ge.Beau_lat(0) .and. tlat2_nh.le.Beau_lat(1) .and.\
                  tlon2_nh.ge.Beau_long(0) .and. tlon2_nh.le.Beau_long(1)), True)

      var_CArc = mask(var_nh,(tlat2_nh.ge.CArc_lat(0) .and. tlat2_nh.le.CArc_lat(1) .and.\
                  tlon2_nh.ge.CArc_long(0) .and. tlon2_nh.le.CArc_long(1)), True)

      var_Bering = mask(var_nh,(Bering_mask .eq. 1.), True)
      var_Okhotsk = mask(var_nh,(Okhotsk_mask .eq. 1.), True)
      var_Hudson = mask(var_nh,(Hudson_mask .eq. 1.), True)
      var_CAArch = mask(var_nh,(CAArch_mask .eq. 1.), True)

;      var_sh50_90 = mask(var_sh,(tlat2_sh.ge.sh50_90_lat(0) .and. tlat2_sh.le.sh50_90_lat(1)),True)

;      var_Wed = mask(var_sh,(tlat2_sh.le.Wed_lat(1) .and.((tlon2_sh.ge.Wed_long1(0) \
;                  .and. tlon2_sh.le.Wed_long1(1)) .or. (tlon2_sh.ge.Wed_long2(0) \
;                  .and. tlon2_sh.le.Wed_long2(1)))), True)

;      var_Ross = mask(var_sh,(tlat2_sh.le.Ross_lat(1) .and. tlon2_sh.ge.Ross_long(0) \
;		   .and. tlon2_sh.le.Ross_long(1)), True)

;      var_Ind = mask(var_sh,(tlat2_sh.le.Ind_lat(1) .and. tlon2_sh.ge.Ind_long(0) \
;                   .and. tlon2_sh.le.Ind_long(1)), True)

;      var_Pac = mask(var_sh,(tlat2_sh.le.Pac_lat(1) .and. tlon2_sh.ge.Pac_long(0) \
;                   .and. tlon2_sh.le.Pac_long(1)), True)

;      var_BAm = mask(var_sh,(tlat2_sh.le.BAm_lat(1) .and. tlon2_sh.ge.BAm_long(0) \
;                   .and. tlon2_sh.le.BAm_long(1)), True)

;********************************
; northern hemisphere monthly ...
;********************************
      if (regional_type.eq."avg") then
         var_mo_nh@units = var_units
         var_mo_nh50_90@units = var_units

         var_mo_nh50_90(imo1:imo2) = dim_sum(dim_sum(var_nh50_90))/area_nh50_90
         var_mo_nh(imo1:imo2) = dim_sum(dim_sum(var_nh))/area_nh
         var_mo_Lab(imo1:imo2) = dim_sum(dim_sum(var_Lab))/area_Lab
         var_mo_GIN(imo1:imo2) = dim_sum(dim_sum(var_GIN))/area_GIN
         var_mo_Bar(imo1:imo2) = dim_sum(dim_sum(var_Bar))/area_Bar
         var_mo_ArcOc(imo1:imo2) = dim_sum(dim_sum(var_ArcOc))/area_ArcOc
         var_mo_Kara(imo1:imo2) = dim_sum(dim_sum(var_Kara))/area_Kara
         var_mo_Laptev(imo1:imo2) = dim_sum(dim_sum(var_Laptev))/area_Laptev
         var_mo_Chukchi(imo1:imo2) = dim_sum(dim_sum(var_Chukchi))/area_Chukchi
         var_mo_Sib(imo1:imo2) = dim_sum(dim_sum(var_Sib))/area_Sib
         var_mo_Beau(imo1:imo2) = dim_sum(dim_sum(var_Beau))/area_Beau
         var_mo_CArc(imo1:imo2) = dim_sum(dim_sum(var_CArc))/area_CArc
         var_mo_Bering(imo1:imo2) = dim_sum(dim_sum(var_Bering))/area_Bering
         var_mo_Okhotsk(imo1:imo2) = dim_sum(dim_sum(var_Okhotsk))/area_Okhotsk
         var_mo_Hudson(imo1:imo2) = dim_sum(dim_sum(var_Hudson))/area_Hudson
         var_mo_CAArch(imo1:imo2) = dim_sum(dim_sum(var_CAArch))/area_CAArch
;********************************
; southern hemisphere monthly ...
;********************************
;         var_mo_sh50_90(imo1:imo2) = dim_sum(dim_sum(var_sh50_90))/area_sh50_90
;         var_mo_sh(imo1:imo2) = dim_sum(dim_sum(var_sh))/area_sh
;         var_mo_Wed(imo1:imo2) = dim_sum(dim_sum(var_Wed))/area_Wed
;         var_mo_Ross(imo1:imo2) = dim_sum(dim_sum(var_Ross))/area_Ross
;         var_mo_Ind(imo1:imo2) = dim_sum(dim_sum(var_Ind))/area_Ind
;         var_mo_Pac(imo1:imo2) = dim_sum(dim_sum(var_Pac))/area_Pac
;         var_mo_BAm(imo1:imo2) = dim_sum(dim_sum(var_BAm))/area_BAm
      else					; total
         var_mo_nh50_90(imo1:imo2) = dim_sum(dim_sum(var_nh50_90))*1.0e-15
         var_mo_nh(imo1:imo2) = dim_sum(dim_sum(var_nh))*1.0e-12 
         var_mo_Lab(imo1:imo2) = dim_sum(dim_sum(var_Lab))*1.0e-12 
         var_mo_GIN(imo1:imo2) = dim_sum(dim_sum(var_GIN))*1.0e-12 
         var_mo_Bar(imo1:imo2) = dim_sum(dim_sum(var_Bar))*1.0e-12 
         var_mo_ArcOc(imo1:imo2) = dim_sum(dim_sum(var_ArcOc))*1.0e-12 
         var_mo_Kara(imo1:imo2) = dim_sum(dim_sum(var_Kara))*1.0e-12
         var_mo_Laptev(imo1:imo2) = dim_sum(dim_sum(var_Laptev))*1.0e-12
         var_mo_Chukchi(imo1:imo2) = dim_sum(dim_sum(var_Chukchi))*1.0e-12
         var_mo_Sib(imo1:imo2) = dim_sum(dim_sum(var_Sib))*1.0e-12 
         var_mo_Beau(imo1:imo2) = dim_sum(dim_sum(var_Beau))*1.0e-12 
         var_mo_CArc(imo1:imo2) = dim_sum(dim_sum(var_CArc))*1.0e-12 
         var_mo_Bering(imo1:imo2) = dim_sum(dim_sum(var_Bering))*1.0e-12 
         var_mo_Okhotsk(imo1:imo2) = dim_sum(dim_sum(var_Okhotsk))*1.0e-12 
         var_mo_Hudson(imo1:imo2) = dim_sum(dim_sum(var_Hudson))*1.0e-12 
         var_mo_CAArch(imo1:imo2) = dim_sum(dim_sum(var_CAArch))*1.0e-12
;********************************
; southern hemisphere monthly ...
;********************************
;         var_mo_sh50_90(imo1:imo2) = dim_sum(dim_sum(var_sh50_90))*1.0e-15
;         var_mo_sh(imo1:imo2) = dim_sum(dim_sum(var_sh))*1.0e-12 
;         var_mo_Wed(imo1:imo2) = dim_sum(dim_sum(var_Wed))*1.0e-12 
;         var_mo_Ross(imo1:imo2) = dim_sum(dim_sum(var_Ross))*1.0e-12 
;         var_mo_Ind(imo1:imo2) = dim_sum(dim_sum(var_Ind))*1.0e-12 
;         var_mo_Pac(imo1:imo2) = dim_sum(dim_sum(var_Pac))*1.0e-12 
;         var_mo_BAm(imo1:imo2) = dim_sum(dim_sum(var_BAm))*1.0e-12

          var_mo_nh@units = "1.E+12 "+var_units
          var_mo_nh50_90@units = "1.E+15 "+var_units
      end if
   end do ; nn
   var_mo_nh!0 = "time"
   var_mo_nh&time = time
   var_mo_nh@coordinates = "time"
   var_mo_nh@missing_value = 1.e+30
   var_mo_nh@_FillValue = 1.e+30
   var_mo_nh@cell_methods = "time:mean"

   var_mo_nh50_90!0 = "time"
   var_mo_nh50_90&time = time
   var_mo_nh50_90@coordinates = "time"
   var_mo_nh50_90@missing_value = 1.e+30
   var_mo_nh50_90@_FillValue = 1.e+30
   var_mo_nh50_90@cell_methods = "time:mean"

   copy_VarMeta(var_mo_nh,var_mo_Lab)
   copy_VarMeta(var_mo_nh,var_mo_GIN)
   copy_VarMeta(var_mo_nh,var_mo_Bar)
   copy_VarMeta(var_mo_nh,var_mo_ArcOc)
   copy_VarMeta(var_mo_nh,var_mo_Kara)
   copy_VarMeta(var_mo_nh,var_mo_Laptev)
   copy_VarMeta(var_mo_nh,var_mo_Chukchi)
   copy_VarMeta(var_mo_nh,var_mo_Sib)
   copy_VarMeta(var_mo_nh,var_mo_Beau)
   copy_VarMeta(var_mo_nh,var_mo_CArc)
   copy_VarMeta(var_mo_nh,var_mo_Bering)
   copy_VarMeta(var_mo_nh,var_mo_Okhotsk)
   copy_VarMeta(var_mo_nh,var_mo_Hudson)
   copy_VarMeta(var_mo_nh,var_mo_CAArch)

;   var_mo_sh!0 = "time"
;   var_mo_sh&time = time
;   var_mo_sh@units = "1.E+12 "+var_units
;   var_mo_sh@coordinates = "time"
;   var_mo_sh@missing_value = 1.e+30
;   var_mo_sh@_FillValue = 1.e+30
;   var_mo_sh@cell_methods = "time:mean"

;   var_mo_sh50_90!0 = "time"
;   var_mo_sh50_90&time = time
;   var_mo_sh50_90@units = "1.E+15 "+var_units
;   var_mo_sh50_90@coordinates = "time"
;   var_mo_sh50_90@missing_value = 1.e+30
;   var_mo_sh50_90@_FillValue = 1.e+30
;   var_mo_sh50_90@cell_methods = "time:mean"

;   copy_VarMeta(var_mo_sh,var_mo_Wed)
;   copy_VarMeta(var_mo_sh,var_mo_Ross)
;   copy_VarMeta(var_mo_sh,var_mo_Ind)
;   copy_VarMeta(var_mo_sh,var_mo_Pac)
;   copy_VarMeta(var_mo_sh,var_mo_BAm)

   fout = addfile(out_dir+"ice_"+var_name+"_MHolland_regions_"+case_names(ii)+"_"+styrs_proc+".nc","c")
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

   filevardef(fout,out_var_mo_nh,typeof(var_mo_nh),getvardims(var_mo_nh))
   filevardef(fout,out_var_mo_nh50_90,typeof(var_mo_nh50_90),getvardims(var_mo_nh50_90))

;   filevardef(fout,out_var_mo_sh,typeof(var_mo_sh),getvardims(var_mo_sh))
;   filevardef(fout,out_var_mo_sh50_90,typeof(var_mo_sh50_90),getvardims(var_mo_sh50_90))

   filevardef(fout,out_var_mo_Lab,typeof(var_mo_Lab),getvardims(var_mo_Lab))
   filevardef(fout,out_var_mo_GIN,typeof(var_mo_GIN),getvardims(var_mo_GIN))
   filevardef(fout,out_var_mo_Bar,typeof(var_mo_Bar),getvardims(var_mo_Bar))
   filevardef(fout,out_var_mo_ArcOc,typeof(var_mo_ArcOc),getvardims(var_mo_ArcOc))
   filevardef(fout,out_var_mo_Kara,typeof(var_mo_Kara),getvardims(var_mo_Kara))
   filevardef(fout,out_var_mo_Laptev,typeof(var_mo_Laptev),getvardims(var_mo_Laptev))
   filevardef(fout,out_var_mo_Chukchi,typeof(var_mo_Chukchi),getvardims(var_mo_Chukchi))
   filevardef(fout,out_var_mo_Sib,typeof(var_mo_Sib),getvardims(var_mo_Sib))
   filevardef(fout,out_var_mo_Beau,typeof(var_mo_Beau),getvardims(var_mo_Beau))
   filevardef(fout,out_var_mo_CArc,typeof(var_mo_CArc),getvardims(var_mo_CArc))
   filevardef(fout,out_var_mo_Bering,typeof(var_mo_Bering),getvardims(var_mo_Bering))
   filevardef(fout,out_var_mo_Okhotsk,typeof(var_mo_Okhotsk),getvardims(var_mo_Okhotsk))
   filevardef(fout,out_var_mo_Hudson,typeof(var_mo_Hudson),getvardims(var_mo_Hudson))
   filevardef(fout,out_var_mo_CAArch,typeof(var_mo_CAArch),getvardims(var_mo_CAArch))

;   filevardef(fout,out_var_mo_Wed,typeof(var_mo_Wed),getvardims(var_mo_Wed))
;   filevardef(fout,out_var_mo_Ross,typeof(var_mo_Ross),getvardims(var_mo_Ross))
;   filevardef(fout,out_var_mo_Ind,typeof(var_mo_Ind),getvardims(var_mo_Ind))
;   filevardef(fout,out_var_mo_Pac,typeof(var_mo_Pac),getvardims(var_mo_Pac))
;   filevardef(fout,out_var_mo_BAm,typeof(var_mo_BAm),getvardims(var_mo_BAm))

   filevarattdef(fout,out_var_mo_nh,var_mo_nh)
   filevarattdef(fout,out_var_mo_nh50_90,var_mo_nh50_90)

;   filevarattdef(fout,out_var_mo_sh,var_mo_sh)
;   filevarattdef(fout,out_var_mo_sh50_90,var_mo_sh50_90)

   filevarattdef(fout,out_var_mo_Lab,var_mo_Lab)
   filevarattdef(fout,out_var_mo_GIN,var_mo_GIN)
   filevarattdef(fout,out_var_mo_Bar,var_mo_Bar)
   filevarattdef(fout,out_var_mo_ArcOc,var_mo_ArcOc)
   filevarattdef(fout,out_var_mo_Kara,var_mo_Kara)
   filevarattdef(fout,out_var_mo_Laptev,var_mo_Laptev)
   filevarattdef(fout,out_var_mo_Chukchi,var_mo_Chukchi)
   filevarattdef(fout,out_var_mo_Sib,var_mo_Sib)
   filevarattdef(fout,out_var_mo_Beau,var_mo_Beau)
   filevarattdef(fout,out_var_mo_CArc,var_mo_CArc)
   filevarattdef(fout,out_var_mo_Bering,var_mo_Bering)
   filevarattdef(fout,out_var_mo_Okhotsk,var_mo_Okhotsk)
   filevarattdef(fout,out_var_mo_Hudson,var_mo_Hudson)
   filevarattdef(fout,out_var_mo_CAArch,var_mo_CAArch)

;   filevarattdef(fout,out_var_mo_Wed,var_mo_Wed)
;   filevarattdef(fout,out_var_mo_Ross,var_mo_Ross)
;   filevarattdef(fout,out_var_mo_Ind,var_mo_Ind)
;   filevarattdef(fout,out_var_mo_Pac,var_mo_Pac)
;   filevarattdef(fout,out_var_mo_BAm,var_mo_BAm)

   fout->time = time
   fout->$out_var_mo_nh$ = var_mo_nh
   fout->$out_var_mo_nh50_90$ = var_mo_nh50_90

;   fout->$out_var_mo_sh$ = var_mo_sh
;   fout->$out_var_mo_sh50_90$ = var_mo_sh50_90

   fout->$out_var_mo_Lab$ = var_mo_Lab
   fout->$out_var_mo_GIN$ = var_mo_GIN
   fout->$out_var_mo_Bar$ = var_mo_Bar
   fout->$out_var_mo_ArcOc$ = var_mo_ArcOc
   fout->$out_var_mo_Kara$ = var_mo_Kara
   fout->$out_var_mo_Laptev$ = var_mo_Laptev
   fout->$out_var_mo_Chukchi$ = var_mo_Chukchi
   fout->$out_var_mo_Sib$ = var_mo_Sib
   fout->$out_var_mo_Beau$ = var_mo_Beau
   fout->$out_var_mo_CArc$ = var_mo_CArc
   fout->$out_var_mo_Bering$ = var_mo_Bering
   fout->$out_var_mo_Okhotsk$ = var_mo_Okhotsk
   fout->$out_var_mo_Hudson$ = var_mo_Hudson
   fout->$out_var_mo_CAArch$ = var_mo_CAArch

;   fout->$out_var_mo_Wed$ = var_mo_Wed
;   fout->$out_var_mo_Ross$ = var_mo_Ross
;   fout->$out_var_mo_Ind$ = var_mo_Ind
;   fout->$out_var_mo_Pac$ = var_mo_Pac
;   fout->$out_var_mo_BAm$ = var_mo_BAm

end do 						; end do ii
end
