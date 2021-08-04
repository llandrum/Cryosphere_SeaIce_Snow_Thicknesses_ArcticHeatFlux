; Modified to calculate areas for different thickness categories
; June 2020
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
;  case_numbers = ispan(2,3,1)
  case_numbers = ispan(1,40,1)
  case_numbers(35:) = ispan(101,105,1)
  scnumbers = sprinti("%0.3i",case_numbers)

  hist_case = LE_20thC_case+scnumbers(0)
;  c20thC_case = LE_20thC_case+ scnumbers(1:)
  c20thC_case = LE_20thC_case+ scnumbers
  rcp85_case = LE_rcp_case+scnumbers

  case_names = c20thC_case
  ncase = dimsizes(case_names)

  case = "b.e11.B1850C5CN.f09_g16.005"
  tseries_dir = "/glade/collections/cdg/data/cesmLE/CESM-CAM5-BGC-LE/ice/proc/tseries/monthly/"
  out_dir = "/glade/p/cesm/pcwg/landrum/LE/ice/pre_process/monthly/aicen00x"

  yr1 = new(ncase,integer)
  yr1 = 1920							; start and end yrs for time series
  yr1(0) = 1850
;  yr1(33:) = 2006
  yr2 = yr1
  yr2 = 2005
;  yr2(33:) = 2100
  yr1_proc = 1920                                                  ; start and end yrs for pre-processed time series
  yr2_proc = 2005

  nyears = yr2_proc - yr1_proc + 1

  offset = (yr1_proc - yr1)*12

  styrs = sprinti("%0.4i",yr1) + "01-"+sprinti("%0.4i",yr2)+"12"
  styrs_proc = sprinti("%0.4i",yr1_proc) + "-"+sprinti("%0.4i",yr2_proc)

  faicen001_nh = tseries_dir+"aicen001/"+case_names+".cice.h.aicen001_nh."+styrs+".nc"
  faicen002_nh = tseries_dir+"aicen002/"+case_names+".cice.h.aicen002_nh."+styrs+".nc"
  faicen003_nh = tseries_dir+"aicen003/"+case_names+".cice.h.aicen003_nh."+styrs+".nc"
  faicen004_nh = tseries_dir+"aicen004/"+case_names+".cice.h.aicen004_nh."+styrs+".nc"
  faicen005_nh = tseries_dir+"aicen005/"+case_names+".cice.h.aicen005_nh."+styrs+".nc"

  faicen001_sh = tseries_dir+"aicen001/"+case_names+".cice.h.aicen001_sh."+styrs+".nc"
  faicen002_sh = tseries_dir+"aicen002/"+case_names+".cice.h.aicen002_sh."+styrs+".nc"
  faicen003_sh = tseries_dir+"aicen003/"+case_names+".cice.h.aicen003_sh."+styrs+".nc"
  faicen004_sh = tseries_dir+"aicen004/"+case_names+".cice.h.aicen004_sh."+styrs+".nc"
  faicen005_sh = tseries_dir+"aicen005/"+case_names+".cice.h.aicen005_sh."+styrs+".nc"

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

  vai001_mo_nh = new((/nyears*12/),float)
  vai002_mo_nh = new((/nyears*12/),float)
  vai003_mo_nh = new((/nyears*12/),float)
  vai004_mo_nh = new((/nyears*12/),float)
  vai005_mo_nh = new((/nyears*12/),float)
  vai001_mo_sh = new((/nyears*12/),float)
  vai002_mo_sh = new((/nyears*12/),float)
  vai003_mo_sh = new((/nyears*12/),float)
  vai004_mo_sh = new((/nyears*12/),float)
  vai005_mo_sh = new((/nyears*12/),float)

;*****************************
; regional arrays: Arctic
;*****************************
  vai001_mo_Lab = new((/nyears*12/),float)
  vai001_mo_GIN = new((/nyears*12/),float)
  vai001_mo_Bar = new((/nyears*12/),float)
  vai001_mo_ArcOc = new((/nyears*12/),float)

  vai002_mo_Lab = new((/nyears*12/),float)
  vai002_mo_GIN = new((/nyears*12/),float)
  vai002_mo_Bar = new((/nyears*12/),float)
  vai002_mo_ArcOc = new((/nyears*12/),float)

  vai003_mo_Lab = new((/nyears*12/),float)
  vai003_mo_GIN = new((/nyears*12/),float)
  vai003_mo_Bar = new((/nyears*12/),float)
  vai003_mo_ArcOc = new((/nyears*12/),float)

  vai004_mo_Lab = new((/nyears*12/),float)
  vai004_mo_GIN = new((/nyears*12/),float)
  vai004_mo_Bar = new((/nyears*12/),float)
  vai004_mo_ArcOc = new((/nyears*12/),float)

  vai005_mo_Lab = new((/nyears*12/),float)
  vai005_mo_GIN = new((/nyears*12/),float)
  vai005_mo_Bar = new((/nyears*12/),float)
  vai005_mo_ArcOc = new((/nyears*12/),float)

  vai001_mo_Kara = new((/nyears*12/),float)
  vai001_mo_Laptev = new((/nyears*12/),float)
  vai001_mo_Chukchi = new((/nyears*12/),float)

  vai002_mo_Kara = new((/nyears*12/),float)
  vai002_mo_Laptev = new((/nyears*12/),float)
  vai002_mo_Chukchi = new((/nyears*12/),float)

  vai003_mo_Kara = new((/nyears*12/),float)
  vai003_mo_Laptev = new((/nyears*12/),float)
  vai003_mo_Chukchi = new((/nyears*12/),float)

  vai004_mo_Kara = new((/nyears*12/),float)
  vai004_mo_Laptev = new((/nyears*12/),float)
  vai004_mo_Chukchi = new((/nyears*12/),float)

  vai005_mo_Kara = new((/nyears*12/),float)
  vai005_mo_Laptev = new((/nyears*12/),float)
  vai005_mo_Chukchi = new((/nyears*12/),float)

  vai001_mo_Sib = new((/nyears*12/),float)
  vai001_mo_Beau = new((/nyears*12/),float)
  vai001_mo_CArc = new((/nyears*12/),float)
  vai001_mo_Bering = new((/nyears*12/),float)
  vai001_mo_Okhotsk = new((/nyears*12/),float)
  vai001_mo_Hudson = new((/nyears*12/),float)
  vai001_mo_CAArch = new((/nyears*12/),float)

  vai002_mo_Sib = new((/nyears*12/),float)
  vai002_mo_Beau = new((/nyears*12/),float)
  vai002_mo_CArc = new((/nyears*12/),float)
  vai002_mo_Bering = new((/nyears*12/),float)
  vai002_mo_Okhotsk = new((/nyears*12/),float)
  vai002_mo_Hudson = new((/nyears*12/),float)
  vai002_mo_CAArch = new((/nyears*12/),float)

  vai003_mo_Sib = new((/nyears*12/),float)
  vai003_mo_Beau = new((/nyears*12/),float)
  vai003_mo_CArc = new((/nyears*12/),float)
  vai003_mo_Bering = new((/nyears*12/),float)
  vai003_mo_Okhotsk = new((/nyears*12/),float)
  vai003_mo_Hudson = new((/nyears*12/),float)
  vai003_mo_CAArch = new((/nyears*12/),float)

  vai004_mo_Sib = new((/nyears*12/),float)
  vai004_mo_Beau = new((/nyears*12/),float)
  vai004_mo_CArc = new((/nyears*12/),float)
  vai004_mo_Bering = new((/nyears*12/),float)
  vai004_mo_Okhotsk = new((/nyears*12/),float)
  vai004_mo_Hudson = new((/nyears*12/),float)
  vai004_mo_CAArch = new((/nyears*12/),float)

  vai005_mo_Sib = new((/nyears*12/),float)
  vai005_mo_Beau = new((/nyears*12/),float)
  vai005_mo_CArc = new((/nyears*12/),float)
  vai005_mo_Bering = new((/nyears*12/),float)
  vai005_mo_Okhotsk = new((/nyears*12/),float)
  vai005_mo_Hudson = new((/nyears*12/),float)
  vai005_mo_CAArch = new((/nyears*12/),float)
;*****************************
; regional arrays: Antarctic
;*****************************
  vai001_mo_Wed = new((/nyears*12/),float)
  vai001_mo_Ross = new((/nyears*12/),float)
  vai001_mo_Ind = new((/nyears*12/),float)
  vai001_mo_Pac = new((/nyears*12/),float)
  vai001_mo_BAm = new((/nyears*12/),float)

  vai002_mo_Wed = new((/nyears*12/),float)
  vai002_mo_Ross = new((/nyears*12/),float)
  vai002_mo_Ind = new((/nyears*12/),float)
  vai002_mo_Pac = new((/nyears*12/),float)
  vai002_mo_BAm = new((/nyears*12/),float)

  vai003_mo_Wed = new((/nyears*12/),float)
  vai003_mo_Ross = new((/nyears*12/),float)
  vai003_mo_Ind = new((/nyears*12/),float)
  vai003_mo_Pac = new((/nyears*12/),float)
  vai003_mo_BAm = new((/nyears*12/),float)

  vai004_mo_Wed = new((/nyears*12/),float)
  vai004_mo_Ross = new((/nyears*12/),float)
  vai004_mo_Ind = new((/nyears*12/),float)
  vai004_mo_Pac = new((/nyears*12/),float)
  vai004_mo_BAm = new((/nyears*12/),float)

  vai005_mo_Wed = new((/nyears*12/),float)
  vai005_mo_Ross = new((/nyears*12/),float)
  vai005_mo_Ind = new((/nyears*12/),float)
  vai005_mo_Pac = new((/nyears*12/),float)
  vai005_mo_BAm = new((/nyears*12/),float)

;  time = new((/nyears*12/),float)

do ii = 0,ncase-1
   print("calculating area totals for "+case_names(ii))
   f1_nh = addfile(faicen001_nh(ii),"r")
   f2_nh = addfile(faicen002_nh(ii),"r")
   f3_nh = addfile(faicen003_nh(ii),"r")
   f4_nh = addfile(faicen004_nh(ii),"r")
   f5_nh = addfile(faicen005_nh(ii),"r")

   f1_sh = addfile(faicen001_sh(ii),"r")
   f2_sh = addfile(faicen002_sh(ii),"r")
   f3_sh = addfile(faicen003_sh(ii),"r")
   f4_sh = addfile(faicen004_sh(ii),"r")
   f5_sh = addfile(faicen005_sh(ii),"r")
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

      aicen001_nh = f1_nh->aicen001(imo1_datain:imo2_datain,:,:)
      aicen002_nh = f2_nh->aicen002(imo1_datain:imo2_datain,:,:)
      aicen003_nh = f3_nh->aicen003(imo1_datain:imo2_datain,:,:)
      aicen004_nh = f4_nh->aicen004(imo1_datain:imo2_datain,:,:)
      aicen005_nh = f5_nh->aicen005(imo1_datain:imo2_datain,:,:)

      tlat2_nh = conform(aicen001_nh,tlat_nh,(/1,2/))
      tlon2_nh = conform(aicen001_nh,tlon_nh,(/1,2/))
      vai001_nh = aicen001_nh*conform(aicen001_nh,tarea_nh,(/1,2/))
      vai002_nh = aicen002_nh*conform(aicen002_nh,tarea_nh,(/1,2/))
      vai003_nh = aicen003_nh*conform(aicen003_nh,tarea_nh,(/1,2/))
      vai004_nh = aicen004_nh*conform(aicen004_nh,tarea_nh,(/1,2/))
      vai005_nh = aicen005_nh*conform(aicen005_nh,tarea_nh,(/1,2/))

      aicen001_sh = f1_sh->aicen001(imo1_datain:imo2_datain,:,:)
      aicen002_sh = f2_sh->aicen002(imo1_datain:imo2_datain,:,:)
      aicen003_sh = f3_sh->aicen003(imo1_datain:imo2_datain,:,:)
      aicen004_sh = f4_sh->aicen004(imo1_datain:imo2_datain,:,:)
      aicen005_sh = f5_sh->aicen005(imo1_datain:imo2_datain,:,:)

      tlat2_sh = conform(aicen001_sh,tlat_sh,(/1,2/))
      tlon2_sh = conform(aicen001_sh,tlon_sh,(/1,2/))
      vai001_sh = aicen001_sh*conform(aicen001_sh,tarea_sh,(/1,2/))
      vai002_sh = aicen002_sh*conform(aicen002_sh,tarea_sh,(/1,2/))
      vai003_sh = aicen003_sh*conform(aicen003_sh,tarea_sh,(/1,2/))
      vai004_sh = aicen004_sh*conform(aicen004_sh,tarea_sh,(/1,2/))
      vai005_sh = aicen005_sh*conform(aicen005_sh,tarea_sh,(/1,2/))

;-------------------------------------------------------------
; create masks for Labrador Sea, Bering Sea, Sea of Okhotsk,
; Hudson Bay and Canadian Archipelago here. They are not simply
; rectangles...........
; Only need to do this once (first year of nyears)
;------------------------------------------------------------
      if ((ii.eq.0).and.(nn .eq. 0)) then
         Lab_mask = new(dimsizes(vai001_nh),typeof(vai001_nh),vai001_nh@_FillValue)
         Bering_mask = new(dimsizes(vai001_nh),typeof(vai001_nh),vai001_nh@_FillValue)
         Okhotsk_mask = new(dimsizes(vai001_nh),typeof(vai001_nh),vai001_nh@_FillValue)
         CAArch_mask = new(dimsizes(vai001_nh),typeof(vai001_nh),vai001_nh@_FillValue)
         Hudson_mask = new(dimsizes(vai001_nh),typeof(vai001_nh),vai001_nh@_FillValue)
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

      vai001_Lab = mask(vai001_nh,(Lab_mask .eq. 1.), True)
      vai002_Lab = mask(vai002_nh,(Lab_mask .eq. 1.), True)
      vai003_Lab = mask(vai003_nh,(Lab_mask .eq. 1.), True)
      vai004_Lab = mask(vai004_nh,(Lab_mask .eq. 1.), True)
      vai005_Lab = mask(vai005_nh,(Lab_mask .eq. 1.), True)
 
      vai001_GIN = mask(vai001_nh,(tlat2_nh.ge.GIN_lat(0) .and. tlat2_nh.le.GIN_lat(1) .and.\
                  ((tlon2_nh.ge.GIN_long1(0) .and. tlon2_nh.le.GIN_long1(1)) .or.\
                   (tlon2_nh.ge.GIN_long2(0) .and. tlon2_nh.le.GIN_long2(1)))), True)
      vai002_GIN = mask(vai002_nh,(tlat2_nh.ge.GIN_lat(0) .and. tlat2_nh.le.GIN_lat(1) .and.\
                  ((tlon2_nh.ge.GIN_long1(0) .and. tlon2_nh.le.GIN_long1(1)) .or.\
                   (tlon2_nh.ge.GIN_long2(0) .and. tlon2_nh.le.GIN_long2(1)))), True)
      vai003_GIN = mask(vai003_nh,(tlat2_nh.ge.GIN_lat(0) .and. tlat2_nh.le.GIN_lat(1) .and.\
                  ((tlon2_nh.ge.GIN_long1(0) .and. tlon2_nh.le.GIN_long1(1)) .or.\
                   (tlon2_nh.ge.GIN_long2(0) .and. tlon2_nh.le.GIN_long2(1)))), True)
      vai004_GIN = mask(vai004_nh,(tlat2_nh.ge.GIN_lat(0) .and. tlat2_nh.le.GIN_lat(1) .and.\
                  ((tlon2_nh.ge.GIN_long1(0) .and. tlon2_nh.le.GIN_long1(1)) .or.\
                   (tlon2_nh.ge.GIN_long2(0) .and. tlon2_nh.le.GIN_long2(1)))), True)
      vai005_GIN = mask(vai005_nh,(tlat2_nh.ge.GIN_lat(0) .and. tlat2_nh.le.GIN_lat(1) .and.\
                  ((tlon2_nh.ge.GIN_long1(0) .and. tlon2_nh.le.GIN_long1(1)) .or.\
                   (tlon2_nh.ge.GIN_long2(0) .and. tlon2_nh.le.GIN_long2(1)))), True)
      vai001_Bar = mask(vai001_nh,(tlat2_nh.ge.Bar_lat(0) .and. tlat2_nh.le.Bar_lat(1) .and.\
                  tlon2_nh.ge.Bar_long(0) .and. tlon2_nh.le.Bar_long(1)), True)
      vai002_Bar = mask(vai002_nh,(tlat2_nh.ge.Bar_lat(0) .and. tlat2_nh.le.Bar_lat(1) .and.\
                  tlon2_nh.ge.Bar_long(0) .and. tlon2_nh.le.Bar_long(1)), True)
      vai003_Bar = mask(vai003_nh,(tlat2_nh.ge.Bar_lat(0) .and. tlat2_nh.le.Bar_lat(1) .and.\
                  tlon2_nh.ge.Bar_long(0) .and. tlon2_nh.le.Bar_long(1)), True)
      vai004_Bar = mask(vai004_nh,(tlat2_nh.ge.Bar_lat(0) .and. tlat2_nh.le.Bar_lat(1) .and.\
                  tlon2_nh.ge.Bar_long(0) .and. tlon2_nh.le.Bar_long(1)), True)
      vai005_Bar = mask(vai005_nh,(tlat2_nh.ge.Bar_lat(0) .and. tlat2_nh.le.Bar_lat(1) .and.\
                  tlon2_nh.ge.Bar_long(0) .and. tlon2_nh.le.Bar_long(1)), True)

      vai001_ArcOc = mask(vai001_nh,((tlat2_nh.ge.ArcOc_lat1(0) .and. (tlon2_nh.ge.ArcOc_long1(0) .or.\
                  tlon2_nh.le.ArcOc_long2(1))) .or. (tlat2_nh.ge.ArcOc_lat3(0) .and.\
                   (tlon2_nh.ge.ArcOc_long3(0) .and. tlon2_nh.le.ArcOc_long3(1)))), True)
      vai002_ArcOc = mask(vai002_nh,((tlat2_nh.ge.ArcOc_lat1(0) .and. (tlon2_nh.ge.ArcOc_long1(0) .or.\
                  tlon2_nh.le.ArcOc_long2(1))) .or. (tlat2_nh.ge.ArcOc_lat3(0) .and.\
                   (tlon2_nh.ge.ArcOc_long3(0) .and. tlon2_nh.le.ArcOc_long3(1)))), True)
      vai003_ArcOc = mask(vai003_nh,((tlat2_nh.ge.ArcOc_lat1(0) .and. (tlon2_nh.ge.ArcOc_long1(0) .or.\
                  tlon2_nh.le.ArcOc_long2(1))) .or. (tlat2_nh.ge.ArcOc_lat3(0) .and.\
                   (tlon2_nh.ge.ArcOc_long3(0) .and. tlon2_nh.le.ArcOc_long3(1)))), True)
      vai004_ArcOc = mask(vai004_nh,((tlat2_nh.ge.ArcOc_lat1(0) .and. (tlon2_nh.ge.ArcOc_long1(0) .or.\
                  tlon2_nh.le.ArcOc_long2(1))) .or. (tlat2_nh.ge.ArcOc_lat3(0) .and.\
                   (tlon2_nh.ge.ArcOc_long3(0) .and. tlon2_nh.le.ArcOc_long3(1)))), True)
      vai005_ArcOc = mask(vai005_nh,((tlat2_nh.ge.ArcOc_lat1(0) .and. (tlon2_nh.ge.ArcOc_long1(0) .or.\
                  tlon2_nh.le.ArcOc_long2(1))) .or. (tlat2_nh.ge.ArcOc_lat3(0) .and.\
                   (tlon2_nh.ge.ArcOc_long3(0) .and. tlon2_nh.le.ArcOc_long3(1)))), True)

      vai001_Kara = mask(vai001_nh,(tlat2_nh.ge.Kara_lat(0) .and. tlat2_nh.le.Kara_lat(1) .and.\
                  tlon2_nh.ge.Kara_long(0) .and. tlon2_nh.le.Kara_long(1)), True)
      vai002_Kara = mask(vai002_nh,(tlat2_nh.ge.Kara_lat(0) .and. tlat2_nh.le.Kara_lat(1) .and.\
                  tlon2_nh.ge.Kara_long(0) .and. tlon2_nh.le.Kara_long(1)), True)
      vai003_Kara = mask(vai003_nh,(tlat2_nh.ge.Kara_lat(0) .and. tlat2_nh.le.Kara_lat(1) .and.\
                  tlon2_nh.ge.Kara_long(0) .and. tlon2_nh.le.Kara_long(1)), True)
      vai004_Kara = mask(vai004_nh,(tlat2_nh.ge.Kara_lat(0) .and. tlat2_nh.le.Kara_lat(1) .and.\
                  tlon2_nh.ge.Kara_long(0) .and. tlon2_nh.le.Kara_long(1)), True)
      vai005_Kara = mask(vai005_nh,(tlat2_nh.ge.Kara_lat(0) .and. tlat2_nh.le.Kara_lat(1) .and.\
                  tlon2_nh.ge.Kara_long(0) .and. tlon2_nh.le.Kara_long(1)), True)

      vai001_Laptev = mask(vai001_nh,(tlat2_nh.ge.Laptev_lat(0) .and. tlat2_nh.le.Laptev_lat(1) .and.\
                  tlon2_nh.ge.Laptev_long(0) .and. tlon2_nh.le.Laptev_long(1)), True)
      vai002_Laptev = mask(vai002_nh,(tlat2_nh.ge.Laptev_lat(0) .and. tlat2_nh.le.Laptev_lat(1) .and.\
                  tlon2_nh.ge.Laptev_long(0) .and. tlon2_nh.le.Laptev_long(1)), True)
      vai003_Laptev = mask(vai003_nh,(tlat2_nh.ge.Laptev_lat(0) .and. tlat2_nh.le.Laptev_lat(1) .and.\
                  tlon2_nh.ge.Laptev_long(0) .and. tlon2_nh.le.Laptev_long(1)), True)
      vai004_Laptev = mask(vai004_nh,(tlat2_nh.ge.Laptev_lat(0) .and. tlat2_nh.le.Laptev_lat(1) .and.\
                  tlon2_nh.ge.Laptev_long(0) .and. tlon2_nh.le.Laptev_long(1)), True)
      vai005_Laptev = mask(vai005_nh,(tlat2_nh.ge.Laptev_lat(0) .and. tlat2_nh.le.Laptev_lat(1) .and.\
                  tlon2_nh.ge.Laptev_long(0) .and. tlon2_nh.le.Laptev_long(1)), True)

      vai001_Chukchi = mask(vai001_nh,(tlat2_nh.ge.Chukchi_lat(0) .and. tlat2_nh.le.Chukchi_lat(1) .and.\
                  tlon2_nh.ge.Chukchi_long(0) .and. tlon2_nh.le.Chukchi_long(1)), True)
      vai002_Chukchi = mask(vai002_nh,(tlat2_nh.ge.Chukchi_lat(0) .and. tlat2_nh.le.Chukchi_lat(1) .and.\
                  tlon2_nh.ge.Chukchi_long(0) .and. tlon2_nh.le.Chukchi_long(1)), True)
      vai003_Chukchi = mask(vai003_nh,(tlat2_nh.ge.Chukchi_lat(0) .and. tlat2_nh.le.Chukchi_lat(1) .and.\
                  tlon2_nh.ge.Chukchi_long(0) .and. tlon2_nh.le.Chukchi_long(1)), True)
      vai004_Chukchi = mask(vai004_nh,(tlat2_nh.ge.Chukchi_lat(0) .and. tlat2_nh.le.Chukchi_lat(1) .and.\
                  tlon2_nh.ge.Chukchi_long(0) .and. tlon2_nh.le.Chukchi_long(1)), True)
      vai005_Chukchi = mask(vai005_nh,(tlat2_nh.ge.Chukchi_lat(0) .and. tlat2_nh.le.Chukchi_lat(1) .and.\
                  tlon2_nh.ge.Chukchi_long(0) .and. tlon2_nh.le.Chukchi_long(1)), True)

      vai001_Sib = mask(vai001_nh,(tlat2_nh.ge.Sib_lat(0) .and. tlat2_nh.le.Sib_lat(1) .and.\
                  tlon2_nh.ge.Sib_long(0) .and. tlon2_nh.le.Sib_long(1)), True)
      vai002_Sib = mask(vai002_nh,(tlat2_nh.ge.Sib_lat(0) .and. tlat2_nh.le.Sib_lat(1) .and.\
                  tlon2_nh.ge.Sib_long(0) .and. tlon2_nh.le.Sib_long(1)), True)
      vai003_Sib = mask(vai003_nh,(tlat2_nh.ge.Sib_lat(0) .and. tlat2_nh.le.Sib_lat(1) .and.\
                  tlon2_nh.ge.Sib_long(0) .and. tlon2_nh.le.Sib_long(1)), True)
      vai004_Sib = mask(vai004_nh,(tlat2_nh.ge.Sib_lat(0) .and. tlat2_nh.le.Sib_lat(1) .and.\
                  tlon2_nh.ge.Sib_long(0) .and. tlon2_nh.le.Sib_long(1)), True)
      vai005_Sib = mask(vai005_nh,(tlat2_nh.ge.Sib_lat(0) .and. tlat2_nh.le.Sib_lat(1) .and.\
                  tlon2_nh.ge.Sib_long(0) .and. tlon2_nh.le.Sib_long(1)), True)

      vai001_Beau = mask(vai001_nh,(tlat2_nh.ge.Beau_lat(0) .and. tlat2_nh.le.Beau_lat(1) .and.\
                  tlon2_nh.ge.Beau_long(0) .and. tlon2_nh.le.Beau_long(1)), True)
      vai002_Beau = mask(vai002_nh,(tlat2_nh.ge.Beau_lat(0) .and. tlat2_nh.le.Beau_lat(1) .and.\
                  tlon2_nh.ge.Beau_long(0) .and. tlon2_nh.le.Beau_long(1)), True)
      vai003_Beau = mask(vai003_nh,(tlat2_nh.ge.Beau_lat(0) .and. tlat2_nh.le.Beau_lat(1) .and.\
                  tlon2_nh.ge.Beau_long(0) .and. tlon2_nh.le.Beau_long(1)), True)
      vai004_Beau = mask(vai004_nh,(tlat2_nh.ge.Beau_lat(0) .and. tlat2_nh.le.Beau_lat(1) .and.\
                  tlon2_nh.ge.Beau_long(0) .and. tlon2_nh.le.Beau_long(1)), True)
      vai005_Beau = mask(vai005_nh,(tlat2_nh.ge.Beau_lat(0) .and. tlat2_nh.le.Beau_lat(1) .and.\
                  tlon2_nh.ge.Beau_long(0) .and. tlon2_nh.le.Beau_long(1)), True)

      vai001_CArc = mask(vai001_nh,(tlat2_nh.ge.CArc_lat(0) .and. tlat2_nh.le.CArc_lat(1) .and.\
                  tlon2_nh.ge.CArc_long(0) .and. tlon2_nh.le.CArc_long(1)), True)
      vai002_CArc = mask(vai002_nh,(tlat2_nh.ge.CArc_lat(0) .and. tlat2_nh.le.CArc_lat(1) .and.\
                  tlon2_nh.ge.CArc_long(0) .and. tlon2_nh.le.CArc_long(1)), True)
      vai003_CArc = mask(vai003_nh,(tlat2_nh.ge.CArc_lat(0) .and. tlat2_nh.le.CArc_lat(1) .and.\
                  tlon2_nh.ge.CArc_long(0) .and. tlon2_nh.le.CArc_long(1)), True)
      vai004_CArc = mask(vai004_nh,(tlat2_nh.ge.CArc_lat(0) .and. tlat2_nh.le.CArc_lat(1) .and.\
                  tlon2_nh.ge.CArc_long(0) .and. tlon2_nh.le.CArc_long(1)), True)
      vai005_CArc = mask(vai005_nh,(tlat2_nh.ge.CArc_lat(0) .and. tlat2_nh.le.CArc_lat(1) .and.\
                  tlon2_nh.ge.CArc_long(0) .and. tlon2_nh.le.CArc_long(1)), True)

      vai001_Bering = mask(vai001_nh,(Bering_mask .eq. 1.), True)
      vai002_Bering = mask(vai002_nh,(Bering_mask .eq. 1.), True)
      vai003_Bering = mask(vai001_nh,(Bering_mask .eq. 1.), True)
      vai004_Bering = mask(vai004_nh,(Bering_mask .eq. 1.), True)
      vai005_Bering = mask(vai005_nh,(Bering_mask .eq. 1.), True)

      vai001_Okhotsk = mask(vai001_nh,(Okhotsk_mask .eq. 1.), True)
      vai002_Okhotsk = mask(vai002_nh,(Okhotsk_mask .eq. 1.), True)
      vai003_Okhotsk = mask(vai003_nh,(Okhotsk_mask .eq. 1.), True)
      vai004_Okhotsk = mask(vai004_nh,(Okhotsk_mask .eq. 1.), True)
      vai005_Okhotsk = mask(vai005_nh,(Okhotsk_mask .eq. 1.), True)

      vai001_Hudson = mask(vai001_nh,(Hudson_mask .eq. 1.), True)
      vai002_Hudson = mask(vai002_nh,(Hudson_mask .eq. 1.), True)
      vai003_Hudson = mask(vai003_nh,(Hudson_mask .eq. 1.), True)
      vai004_Hudson = mask(vai004_nh,(Hudson_mask .eq. 1.), True)
      vai005_Hudson = mask(vai005_nh,(Hudson_mask .eq. 1.), True)

      vai001_CAArch = mask(vai001_nh,(CAArch_mask .eq. 1.), True)
      vai002_CAArch = mask(vai002_nh,(CAArch_mask .eq. 1.), True)
      vai003_CAArch = mask(vai003_nh,(CAArch_mask .eq. 1.), True)
      vai004_CAArch = mask(vai004_nh,(CAArch_mask .eq. 1.), True)
      vai005_CAArch = mask(vai005_nh,(CAArch_mask .eq. 1.), True)

      vai001_Wed = mask(vai001_sh,(tlat2_sh.le.Wed_lat(1) .and.((tlon2_sh.ge.Wed_long1(0) \
                  .and. tlon2_sh.le.Wed_long1(1)) .or. (tlon2_sh.ge.Wed_long2(0) \
                  .and. tlon2_sh.le.Wed_long2(1)))), True)
      vai002_Wed = mask(vai002_sh,(tlat2_sh.le.Wed_lat(1) .and.((tlon2_sh.ge.Wed_long1(0) \
                  .and. tlon2_sh.le.Wed_long1(1)) .or. (tlon2_sh.ge.Wed_long2(0) \
                  .and. tlon2_sh.le.Wed_long2(1)))), True)
      vai003_Wed = mask(vai003_sh,(tlat2_sh.le.Wed_lat(1) .and.((tlon2_sh.ge.Wed_long1(0) \
                  .and. tlon2_sh.le.Wed_long1(1)) .or. (tlon2_sh.ge.Wed_long2(0) \
                  .and. tlon2_sh.le.Wed_long2(1)))), True)
      vai004_Wed = mask(vai004_sh,(tlat2_sh.le.Wed_lat(1) .and.((tlon2_sh.ge.Wed_long1(0) \
                  .and. tlon2_sh.le.Wed_long1(1)) .or. (tlon2_sh.ge.Wed_long2(0) \
                  .and. tlon2_sh.le.Wed_long2(1)))), True)
      vai005_Wed = mask(vai005_sh,(tlat2_sh.le.Wed_lat(1) .and.((tlon2_sh.ge.Wed_long1(0) \
                  .and. tlon2_sh.le.Wed_long1(1)) .or. (tlon2_sh.ge.Wed_long2(0) \
                  .and. tlon2_sh.le.Wed_long2(1)))), True)

      vai001_Ross = mask(vai001_sh,(tlat2_sh.le.Ross_lat(1) .and. tlon2_sh.ge.Ross_long(0) \
		   .and. tlon2_sh.le.Ross_long(1)), True)
      vai002_Ross = mask(vai002_sh,(tlat2_sh.le.Ross_lat(1) .and. tlon2_sh.ge.Ross_long(0) \
                   .and. tlon2_sh.le.Ross_long(1)), True)
      vai003_Ross = mask(vai003_sh,(tlat2_sh.le.Ross_lat(1) .and. tlon2_sh.ge.Ross_long(0) \
                   .and. tlon2_sh.le.Ross_long(1)), True)
      vai004_Ross = mask(vai004_sh,(tlat2_sh.le.Ross_lat(1) .and. tlon2_sh.ge.Ross_long(0) \
                   .and. tlon2_sh.le.Ross_long(1)), True)
      vai005_Ross = mask(vai005_sh,(tlat2_sh.le.Ross_lat(1) .and. tlon2_sh.ge.Ross_long(0) \
                   .and. tlon2_sh.le.Ross_long(1)), True)

      vai001_Ind = mask(vai001_sh,(tlat2_sh.le.Ind_lat(1) .and. tlon2_sh.ge.Ind_long(0) \
                   .and. tlon2_sh.le.Ind_long(1)), True)
      vai002_Ind = mask(vai002_sh,(tlat2_sh.le.Ind_lat(1) .and. tlon2_sh.ge.Ind_long(0) \
                   .and. tlon2_sh.le.Ind_long(1)), True)
      vai003_Ind = mask(vai003_sh,(tlat2_sh.le.Ind_lat(1) .and. tlon2_sh.ge.Ind_long(0) \
                   .and. tlon2_sh.le.Ind_long(1)), True)
      vai004_Ind = mask(vai004_sh,(tlat2_sh.le.Ind_lat(1) .and. tlon2_sh.ge.Ind_long(0) \
                   .and. tlon2_sh.le.Ind_long(1)), True)
      vai005_Ind = mask(vai005_sh,(tlat2_sh.le.Ind_lat(1) .and. tlon2_sh.ge.Ind_long(0) \
                   .and. tlon2_sh.le.Ind_long(1)), True)

      vai001_Pac = mask(vai001_sh,(tlat2_sh.le.Pac_lat(1) .and. tlon2_sh.ge.Pac_long(0) \
                   .and. tlon2_sh.le.Pac_long(1)), True)
      vai002_Pac = mask(vai002_sh,(tlat2_sh.le.Pac_lat(1) .and. tlon2_sh.ge.Pac_long(0) \
                   .and. tlon2_sh.le.Pac_long(1)), True)
      vai003_Pac = mask(vai003_sh,(tlat2_sh.le.Pac_lat(1) .and. tlon2_sh.ge.Pac_long(0) \
                   .and. tlon2_sh.le.Pac_long(1)), True)
      vai004_Pac = mask(vai004_sh,(tlat2_sh.le.Pac_lat(1) .and. tlon2_sh.ge.Pac_long(0) \
                   .and. tlon2_sh.le.Pac_long(1)), True)
      vai005_Pac = mask(vai005_sh,(tlat2_sh.le.Pac_lat(1) .and. tlon2_sh.ge.Pac_long(0) \
                   .and. tlon2_sh.le.Pac_long(1)), True)

      vai001_BAm = mask(vai001_sh,(tlat2_sh.le.BAm_lat(1) .and. tlon2_sh.ge.BAm_long(0) \
                   .and. tlon2_sh.le.BAm_long(1)), True)
      vai002_BAm = mask(vai002_sh,(tlat2_sh.le.BAm_lat(1) .and. tlon2_sh.ge.BAm_long(0) \
                   .and. tlon2_sh.le.BAm_long(1)), True)
      vai003_BAm = mask(vai003_sh,(tlat2_sh.le.BAm_lat(1) .and. tlon2_sh.ge.BAm_long(0) \
                   .and. tlon2_sh.le.BAm_long(1)), True)
      vai004_BAm = mask(vai004_sh,(tlat2_sh.le.BAm_lat(1) .and. tlon2_sh.ge.BAm_long(0) \
                   .and. tlon2_sh.le.BAm_long(1)), True)
      vai005_BAm = mask(vai005_sh,(tlat2_sh.le.BAm_lat(1) .and. tlon2_sh.ge.BAm_long(0) \
                   .and. tlon2_sh.le.BAm_long(1)), True)
;********************************
; northern hemisphere monthly ...
;********************************

      vai001_mo_nh(imo1:imo2) = dim_sum(dim_sum(vai001_nh))*1.0e-14 
      vai002_mo_nh(imo1:imo2) = dim_sum(dim_sum(vai002_nh))*1.0e-14
      vai003_mo_nh(imo1:imo2) = dim_sum(dim_sum(vai003_nh))*1.0e-14
      vai004_mo_nh(imo1:imo2) = dim_sum(dim_sum(vai004_nh))*1.0e-14
      vai005_mo_nh(imo1:imo2) = dim_sum(dim_sum(vai005_nh))*1.0e-14

      vai001_mo_Lab(imo1:imo2) = dim_sum(dim_sum(vai001_Lab))*1.0e-14 
      vai002_mo_Lab(imo1:imo2) = dim_sum(dim_sum(vai002_Lab))*1.0e-14
      vai003_mo_Lab(imo1:imo2) = dim_sum(dim_sum(vai003_Lab))*1.0e-14
      vai004_mo_Lab(imo1:imo2) = dim_sum(dim_sum(vai004_Lab))*1.0e-14
      vai005_mo_Lab(imo1:imo2) = dim_sum(dim_sum(vai005_Lab))*1.0e-14
 
      vai001_mo_GIN(imo1:imo2) = dim_sum(dim_sum(vai001_GIN))*1.0e-14 
      vai002_mo_Lab(imo1:imo2) = dim_sum(dim_sum(vai002_Lab))*1.0e-14
      vai003_mo_Lab(imo1:imo2) = dim_sum(dim_sum(vai003_Lab))*1.0e-14
      vai004_mo_Lab(imo1:imo2) = dim_sum(dim_sum(vai004_Lab))*1.0e-14
      vai005_mo_Lab(imo1:imo2) = dim_sum(dim_sum(vai005_Lab))*1.0e-14
 
      vai001_mo_Bar(imo1:imo2) = dim_sum(dim_sum(vai001_Bar))*1.0e-14 
      vai002_mo_Bar(imo1:imo2) = dim_sum(dim_sum(vai002_Bar))*1.0e-14
      vai003_mo_Bar(imo1:imo2) = dim_sum(dim_sum(vai003_Bar))*1.0e-14
      vai004_mo_Bar(imo1:imo2) = dim_sum(dim_sum(vai004_Bar))*1.0e-14
      vai005_mo_Bar(imo1:imo2) = dim_sum(dim_sum(vai005_Bar))*1.0e-14
 
      vai001_mo_ArcOc(imo1:imo2) = dim_sum(dim_sum(vai001_ArcOc))*1.0e-14 
      vai002_mo_ArcOc(imo1:imo2) = dim_sum(dim_sum(vai002_ArcOc))*1.0e-14
      vai003_mo_ArcOc(imo1:imo2) = dim_sum(dim_sum(vai003_ArcOc))*1.0e-14
      vai004_mo_ArcOc(imo1:imo2) = dim_sum(dim_sum(vai004_ArcOc))*1.0e-14
      vai005_mo_ArcOc(imo1:imo2) = dim_sum(dim_sum(vai005_ArcOc))*1.0e-14

      vai001_mo_Kara(imo1:imo2) = dim_sum(dim_sum(vai001_Kara))*1.0e-14
      vai002_mo_Kara(imo1:imo2) = dim_sum(dim_sum(vai002_Kara))*1.0e-14
      vai003_mo_Kara(imo1:imo2) = dim_sum(dim_sum(vai003_Kara))*1.0e-14
      vai004_mo_Kara(imo1:imo2) = dim_sum(dim_sum(vai004_Kara))*1.0e-14
      vai005_mo_Kara(imo1:imo2) = dim_sum(dim_sum(vai005_Kara))*1.0e-14

      vai001_mo_Laptev(imo1:imo2) = dim_sum(dim_sum(vai001_Laptev))*1.0e-14
      vai002_mo_Laptev(imo1:imo2) = dim_sum(dim_sum(vai002_Laptev))*1.0e-14
      vai003_mo_Laptev(imo1:imo2) = dim_sum(dim_sum(vai003_Laptev))*1.0e-14
      vai004_mo_Laptev(imo1:imo2) = dim_sum(dim_sum(vai004_Laptev))*1.0e-14
      vai005_mo_Laptev(imo1:imo2) = dim_sum(dim_sum(vai005_Laptev))*1.0e-14

      vai001_mo_Chukchi(imo1:imo2) = dim_sum(dim_sum(vai001_Chukchi))*1.0e-14
      vai002_mo_Chukchi(imo1:imo2) = dim_sum(dim_sum(vai002_Chukchi))*1.0e-14
      vai003_mo_Chukchi(imo1:imo2) = dim_sum(dim_sum(vai003_Chukchi))*1.0e-14
      vai004_mo_Chukchi(imo1:imo2) = dim_sum(dim_sum(vai004_Chukchi))*1.0e-14
      vai005_mo_Chukchi(imo1:imo2) = dim_sum(dim_sum(vai005_Chukchi))*1.0e-14

      vai001_mo_Sib(imo1:imo2) = dim_sum(dim_sum(vai001_Sib))*1.0e-14 
      vai002_mo_Sib(imo1:imo2) = dim_sum(dim_sum(vai002_Sib))*1.0e-14
      vai003_mo_Sib(imo1:imo2) = dim_sum(dim_sum(vai003_Sib))*1.0e-14
      vai004_mo_Sib(imo1:imo2) = dim_sum(dim_sum(vai004_Sib))*1.0e-14
      vai005_mo_Sib(imo1:imo2) = dim_sum(dim_sum(vai005_Sib))*1.0e-14

      vai001_mo_Beau(imo1:imo2) = dim_sum(dim_sum(vai001_Beau))*1.0e-14 
      vai002_mo_Beau(imo1:imo2) = dim_sum(dim_sum(vai002_Beau))*1.0e-14
      vai003_mo_Beau(imo1:imo2) = dim_sum(dim_sum(vai003_Beau))*1.0e-14
      vai004_mo_Beau(imo1:imo2) = dim_sum(dim_sum(vai004_Beau))*1.0e-14
      vai005_mo_Beau(imo1:imo2) = dim_sum(dim_sum(vai005_Beau))*1.0e-14
 
      vai001_mo_CArc(imo1:imo2) = dim_sum(dim_sum(vai001_CArc))*1.0e-14 
      vai002_mo_CArc(imo1:imo2) = dim_sum(dim_sum(vai002_CArc))*1.0e-14
      vai003_mo_CArc(imo1:imo2) = dim_sum(dim_sum(vai003_CArc))*1.0e-14
      vai004_mo_CArc(imo1:imo2) = dim_sum(dim_sum(vai004_CArc))*1.0e-14
      vai005_mo_CArc(imo1:imo2) = dim_sum(dim_sum(vai005_CArc))*1.0e-14

      vai001_mo_Bering(imo1:imo2) = dim_sum(dim_sum(vai001_Bering))*1.0e-14 
      vai002_mo_Bering(imo1:imo2) = dim_sum(dim_sum(vai002_Bering))*1.0e-14
      vai003_mo_Bering(imo1:imo2) = dim_sum(dim_sum(vai003_Bering))*1.0e-14
      vai004_mo_Bering(imo1:imo2) = dim_sum(dim_sum(vai004_Bering))*1.0e-14
      vai005_mo_Bering(imo1:imo2) = dim_sum(dim_sum(vai005_Bering))*1.0e-14

      vai001_mo_Okhotsk(imo1:imo2) = dim_sum(dim_sum(vai001_Okhotsk))*1.0e-14 
      vai002_mo_Okhotsk(imo1:imo2) = dim_sum(dim_sum(vai002_Okhotsk))*1.0e-14
      vai003_mo_Okhotsk(imo1:imo2) = dim_sum(dim_sum(vai003_Okhotsk))*1.0e-14
      vai004_mo_Okhotsk(imo1:imo2) = dim_sum(dim_sum(vai004_Okhotsk))*1.0e-14
      vai005_mo_Okhotsk(imo1:imo2) = dim_sum(dim_sum(vai005_Okhotsk))*1.0e-14

      vai001_mo_Hudson(imo1:imo2) = dim_sum(dim_sum(vai001_Hudson))*1.0e-14 
      vai002_mo_Hudson(imo1:imo2) = dim_sum(dim_sum(vai002_Hudson))*1.0e-14
      vai003_mo_Hudson(imo1:imo2) = dim_sum(dim_sum(vai003_Hudson))*1.0e-14
      vai004_mo_Hudson(imo1:imo2) = dim_sum(dim_sum(vai004_Hudson))*1.0e-14
      vai005_mo_Hudson(imo1:imo2) = dim_sum(dim_sum(vai005_Hudson))*1.0e-14

      vai001_mo_CAArch(imo1:imo2) = dim_sum(dim_sum(vai001_CAArch))*1.0e-14 
      vai002_mo_CAArch(imo1:imo2) = dim_sum(dim_sum(vai002_CAArch))*1.0e-14
      vai003_mo_CAArch(imo1:imo2) = dim_sum(dim_sum(vai003_CAArch))*1.0e-14
      vai004_mo_CAArch(imo1:imo2) = dim_sum(dim_sum(vai004_CAArch))*1.0e-14
      vai005_mo_CAArch(imo1:imo2) = dim_sum(dim_sum(vai005_CAArch))*1.0e-14
;********************************
; southern hemisphere monthly ...
;********************************

      vai001_mo_sh(imo1:imo2) = dim_sum(dim_sum(vai001_sh))*1.0e-14 
      vai002_mo_sh(imo1:imo2) = dim_sum(dim_sum(vai002_sh))*1.0e-14
      vai003_mo_sh(imo1:imo2) = dim_sum(dim_sum(vai003_sh))*1.0e-14
      vai004_mo_sh(imo1:imo2) = dim_sum(dim_sum(vai004_sh))*1.0e-14
      vai005_mo_sh(imo1:imo2) = dim_sum(dim_sum(vai005_sh))*1.0e-14

      vai001_mo_Wed(imo1:imo2) = dim_sum(dim_sum(vai001_Wed))*1.0e-14 
      vai002_mo_Wed(imo1:imo2) = dim_sum(dim_sum(vai002_Wed))*1.0e-14
      vai003_mo_Wed(imo1:imo2) = dim_sum(dim_sum(vai003_Wed))*1.0e-14
      vai004_mo_Wed(imo1:imo2) = dim_sum(dim_sum(vai004_Wed))*1.0e-14
      vai005_mo_Wed(imo1:imo2) = dim_sum(dim_sum(vai005_Wed))*1.0e-14

      vai001_mo_Ross(imo1:imo2) = dim_sum(dim_sum(vai001_Ross))*1.0e-14 
      vai002_mo_Ross(imo1:imo2) = dim_sum(dim_sum(vai002_Ross))*1.0e-14
      vai003_mo_Ross(imo1:imo2) = dim_sum(dim_sum(vai003_Ross))*1.0e-14
      vai004_mo_Ross(imo1:imo2) = dim_sum(dim_sum(vai004_Ross))*1.0e-14
      vai005_mo_Ross(imo1:imo2) = dim_sum(dim_sum(vai005_Ross))*1.0e-14

      vai001_mo_Ind(imo1:imo2) = dim_sum(dim_sum(vai001_Ind))*1.0e-14 
      vai002_mo_Ind(imo1:imo2) = dim_sum(dim_sum(vai002_Ind))*1.0e-14
      vai003_mo_Ind(imo1:imo2) = dim_sum(dim_sum(vai003_Ind))*1.0e-14
      vai004_mo_Ind(imo1:imo2) = dim_sum(dim_sum(vai004_Ind))*1.0e-14
      vai005_mo_Ind(imo1:imo2) = dim_sum(dim_sum(vai005_Ind))*1.0e-14

      vai001_mo_Pac(imo1:imo2) = dim_sum(dim_sum(vai001_Pac))*1.0e-14 
      vai002_mo_Pac(imo1:imo2) = dim_sum(dim_sum(vai002_Pac))*1.0e-14
      vai003_mo_Pac(imo1:imo2) = dim_sum(dim_sum(vai003_Pac))*1.0e-14
      vai004_mo_Pac(imo1:imo2) = dim_sum(dim_sum(vai004_Pac))*1.0e-14
      vai005_mo_Pac(imo1:imo2) = dim_sum(dim_sum(vai005_Pac))*1.0e-14

      vai001_mo_BAm(imo1:imo2) = dim_sum(dim_sum(vai001_BAm))*1.0e-14 
      vai002_mo_BAm(imo1:imo2) = dim_sum(dim_sum(vai002_BAm))*1.0e-14
      vai003_mo_BAm(imo1:imo2) = dim_sum(dim_sum(vai003_BAm))*1.0e-14
      vai004_mo_BAm(imo1:imo2) = dim_sum(dim_sum(vai004_BAm))*1.0e-14
      vai005_mo_BAm(imo1:imo2) = dim_sum(dim_sum(vai005_BAm))*1.0e-14

   end do ; nn

   vai001_mo_nh!0 = "time"
   vai001_mo_nh&time = time
   vai001_mo_nh@units = "1.E+12 m2"
   vai001_mo_nh@coordinates = "time"
   vai001_mo_nh@missing_value = 1.e+30
   vai001_mo_nh@_FillValue = 1.e+30
   vai001_mo_nh@cell_methods = "time:mean"

   copy_VarMeta(vai001_mo_nh,vai002_mo_nh)
   copy_VarMeta(vai001_mo_nh,vai003_mo_nh)
   copy_VarMeta(vai001_mo_nh,vai004_mo_nh)
   copy_VarMeta(vai001_mo_nh,vai005_mo_nh)

   copy_VarMeta(vai001_mo_nh,vai001_mo_Lab)
   copy_VarMeta(vai001_mo_nh,vai002_mo_Lab)
   copy_VarMeta(vai001_mo_nh,vai003_mo_Lab)
   copy_VarMeta(vai001_mo_nh,vai004_mo_Lab)
   copy_VarMeta(vai001_mo_nh,vai005_mo_Lab)

   copy_VarMeta(vai001_mo_nh,vai001_mo_GIN)
   copy_VarMeta(vai001_mo_nh,vai002_mo_GIN)
   copy_VarMeta(vai001_mo_nh,vai003_mo_GIN)
   copy_VarMeta(vai001_mo_nh,vai004_mo_GIN)
   copy_VarMeta(vai001_mo_nh,vai005_mo_GIN)

   copy_VarMeta(vai001_mo_nh,vai001_mo_Bar)
   copy_VarMeta(vai001_mo_nh,vai002_mo_Bar)
   copy_VarMeta(vai001_mo_nh,vai003_mo_Bar)
   copy_VarMeta(vai001_mo_nh,vai004_mo_Bar)
   copy_VarMeta(vai001_mo_nh,vai005_mo_Bar)

   copy_VarMeta(vai001_mo_nh,vai001_mo_ArcOc)
   copy_VarMeta(vai001_mo_nh,vai002_mo_ArcOc)
   copy_VarMeta(vai001_mo_nh,vai003_mo_ArcOc)
   copy_VarMeta(vai001_mo_nh,vai004_mo_ArcOc)
   copy_VarMeta(vai001_mo_nh,vai005_mo_ArcOc)

   copy_VarMeta(vai001_mo_nh,vai001_mo_Kara)
   copy_VarMeta(vai001_mo_nh,vai002_mo_Kara)
   copy_VarMeta(vai001_mo_nh,vai003_mo_Kara)
   copy_VarMeta(vai001_mo_nh,vai004_mo_Kara)
   copy_VarMeta(vai001_mo_nh,vai005_mo_Kara)

   copy_VarMeta(vai001_mo_nh,vai001_mo_Laptev)
   copy_VarMeta(vai001_mo_nh,vai002_mo_Laptev)
   copy_VarMeta(vai001_mo_nh,vai003_mo_Laptev)
   copy_VarMeta(vai001_mo_nh,vai004_mo_Laptev)
   copy_VarMeta(vai001_mo_nh,vai005_mo_Laptev)

   copy_VarMeta(vai001_mo_nh,vai001_mo_Chukchi)
   copy_VarMeta(vai001_mo_nh,vai002_mo_Chukchi)
   copy_VarMeta(vai001_mo_nh,vai003_mo_Chukchi)
   copy_VarMeta(vai001_mo_nh,vai004_mo_Chukchi)
   copy_VarMeta(vai001_mo_nh,vai005_mo_Chukchi)

   copy_VarMeta(vai001_mo_nh,vai001_mo_Sib)
   copy_VarMeta(vai001_mo_nh,vai002_mo_Sib)
   copy_VarMeta(vai001_mo_nh,vai003_mo_Sib)
   copy_VarMeta(vai001_mo_nh,vai004_mo_Sib)
   copy_VarMeta(vai001_mo_nh,vai005_mo_Sib)

   copy_VarMeta(vai001_mo_nh,vai001_mo_Beau)
   copy_VarMeta(vai001_mo_nh,vai002_mo_Beau)
   copy_VarMeta(vai001_mo_nh,vai003_mo_Beau)
   copy_VarMeta(vai001_mo_nh,vai004_mo_Beau)
   copy_VarMeta(vai001_mo_nh,vai005_mo_Beau)

   copy_VarMeta(vai001_mo_nh,vai001_mo_CArc)
   copy_VarMeta(vai001_mo_nh,vai002_mo_CArc)
   copy_VarMeta(vai001_mo_nh,vai003_mo_CArc)
   copy_VarMeta(vai001_mo_nh,vai004_mo_CArc)
   copy_VarMeta(vai001_mo_nh,vai005_mo_CArc)

   copy_VarMeta(vai001_mo_nh,vai001_mo_Bering)
   copy_VarMeta(vai001_mo_nh,vai002_mo_Bering)
   copy_VarMeta(vai001_mo_nh,vai003_mo_Bering)
   copy_VarMeta(vai001_mo_nh,vai004_mo_Bering)
   copy_VarMeta(vai001_mo_nh,vai005_mo_Bering)

   copy_VarMeta(vai001_mo_nh,vai001_mo_Okhotsk)
   copy_VarMeta(vai001_mo_nh,vai002_mo_Okhotsk)
   copy_VarMeta(vai001_mo_nh,vai003_mo_Okhotsk)
   copy_VarMeta(vai001_mo_nh,vai004_mo_Okhotsk)
   copy_VarMeta(vai001_mo_nh,vai005_mo_Okhotsk)

   copy_VarMeta(vai001_mo_nh,vai001_mo_Hudson)
   copy_VarMeta(vai001_mo_nh,vai002_mo_Hudson)
   copy_VarMeta(vai001_mo_nh,vai003_mo_Hudson)
   copy_VarMeta(vai001_mo_nh,vai004_mo_Hudson)
   copy_VarMeta(vai001_mo_nh,vai005_mo_Hudson)

   copy_VarMeta(vai001_mo_nh,vai001_mo_CAArch)
   copy_VarMeta(vai001_mo_nh,vai002_mo_CAArch)
   copy_VarMeta(vai001_mo_nh,vai003_mo_CAArch)
   copy_VarMeta(vai001_mo_nh,vai004_mo_CAArch)
   copy_VarMeta(vai001_mo_nh,vai005_mo_CAArch)

   vai001_mo_sh!0 = "time"
   vai001_mo_sh&time = time
   vai001_mo_sh@units = "1.E+12 m2"
   vai001_mo_sh@coordinates = "time"
   vai001_mo_sh@missing_value = 1.e+30
   vai001_mo_sh@_FillValue = 1.e+30
   vai001_mo_sh@cell_methods = "time:mean"

   copy_VarMeta(vai001_mo_sh,vai002_mo_sh)
   copy_VarMeta(vai001_mo_sh,vai003_mo_sh)
   copy_VarMeta(vai001_mo_sh,vai004_mo_sh)
   copy_VarMeta(vai001_mo_sh,vai005_mo_sh)

   copy_VarMeta(vai001_mo_sh,vai001_mo_Wed)
   copy_VarMeta(vai001_mo_sh,vai002_mo_Wed)
   copy_VarMeta(vai001_mo_sh,vai003_mo_Wed)
   copy_VarMeta(vai001_mo_sh,vai004_mo_Wed)
   copy_VarMeta(vai001_mo_sh,vai005_mo_Wed)

   copy_VarMeta(vai001_mo_sh,vai001_mo_Ross)
   copy_VarMeta(vai001_mo_sh,vai002_mo_Ross)
   copy_VarMeta(vai001_mo_sh,vai003_mo_Ross)
   copy_VarMeta(vai001_mo_sh,vai004_mo_Ross)
   copy_VarMeta(vai001_mo_sh,vai005_mo_Ross)

   copy_VarMeta(vai001_mo_sh,vai001_mo_Ind)
   copy_VarMeta(vai001_mo_sh,vai002_mo_Ind)
   copy_VarMeta(vai001_mo_sh,vai003_mo_Ind)
   copy_VarMeta(vai001_mo_sh,vai004_mo_Ind)
   copy_VarMeta(vai001_mo_sh,vai005_mo_Ind)

   copy_VarMeta(vai001_mo_sh,vai001_mo_Pac)
   copy_VarMeta(vai001_mo_sh,vai002_mo_Pac)
   copy_VarMeta(vai001_mo_sh,vai003_mo_Pac)
   copy_VarMeta(vai001_mo_sh,vai004_mo_Pac)
   copy_VarMeta(vai001_mo_sh,vai005_mo_Pac)

   copy_VarMeta(vai001_mo_sh,vai001_mo_BAm)
   copy_VarMeta(vai001_mo_sh,vai002_mo_BAm)
   copy_VarMeta(vai001_mo_sh,vai003_mo_BAm)
   copy_VarMeta(vai001_mo_sh,vai004_mo_BAm)
   copy_VarMeta(vai001_mo_sh,vai005_mo_BAm)

   fout = addfile(out_dir+"/vaicen00x_MHolland_regions_"+case_names(ii)+"_"+styrs_proc+".nc","c")
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

   filevardef(fout,"vai001_mo_nh",typeof(vai001_mo_nh),getvardims(vai001_mo_nh))
   filevardef(fout,"vai002_mo_nh",typeof(vai002_mo_nh),getvardims(vai002_mo_nh))
   filevardef(fout,"vai003_mo_nh",typeof(vai003_mo_nh),getvardims(vai003_mo_nh))
   filevardef(fout,"vai004_mo_nh",typeof(vai004_mo_nh),getvardims(vai004_mo_nh))
   filevardef(fout,"vai005_mo_nh",typeof(vai005_mo_nh),getvardims(vai005_mo_nh))

   filevardef(fout,"vai001_mo_sh",typeof(vai001_mo_sh),getvardims(vai001_mo_sh))
   filevardef(fout,"vai002_mo_sh",typeof(vai002_mo_sh),getvardims(vai002_mo_sh))
   filevardef(fout,"vai003_mo_sh",typeof(vai003_mo_sh),getvardims(vai003_mo_sh))
   filevardef(fout,"vai004_mo_sh",typeof(vai004_mo_sh),getvardims(vai004_mo_sh))
   filevardef(fout,"vai005_mo_sh",typeof(vai005_mo_sh),getvardims(vai005_mo_sh))

   filevardef(fout,"vai001_mo_Lab",typeof(vai001_mo_Lab),getvardims(vai001_mo_Lab))
   filevardef(fout,"vai002_mo_Lab",typeof(vai002_mo_Lab),getvardims(vai002_mo_Lab))
   filevardef(fout,"vai003_mo_Lab",typeof(vai003_mo_Lab),getvardims(vai003_mo_Lab))
   filevardef(fout,"vai004_mo_Lab",typeof(vai004_mo_Lab),getvardims(vai004_mo_Lab))
   filevardef(fout,"vai005_mo_Lab",typeof(vai005_mo_Lab),getvardims(vai005_mo_Lab))

   filevardef(fout,"vai001_mo_GIN",typeof(vai001_mo_GIN),getvardims(vai001_mo_GIN))
   filevardef(fout,"vai002_mo_GIN",typeof(vai002_mo_GIN),getvardims(vai002_mo_GIN))
   filevardef(fout,"vai003_mo_GIN",typeof(vai003_mo_GIN),getvardims(vai003_mo_GIN))
   filevardef(fout,"vai004_mo_GIN",typeof(vai004_mo_GIN),getvardims(vai004_mo_GIN))
   filevardef(fout,"vai005_mo_GIN",typeof(vai005_mo_GIN),getvardims(vai005_mo_GIN))

   filevardef(fout,"vai001_mo_Bar",typeof(vai001_mo_Bar),getvardims(vai001_mo_Bar))
   filevardef(fout,"vai002_mo_Bar",typeof(vai002_mo_Bar),getvardims(vai002_mo_Bar))
   filevardef(fout,"vai003_mo_Bar",typeof(vai003_mo_Bar),getvardims(vai003_mo_Bar))
   filevardef(fout,"vai004_mo_Bar",typeof(vai004_mo_Bar),getvardims(vai004_mo_Bar))
   filevardef(fout,"vai005_mo_Bar",typeof(vai005_mo_Bar),getvardims(vai005_mo_Bar))

   filevardef(fout,"vai001_mo_ArcOc",typeof(vai001_mo_ArcOc),getvardims(vai001_mo_ArcOc))
   filevardef(fout,"vai002_mo_ArcOc",typeof(vai002_mo_ArcOc),getvardims(vai002_mo_ArcOc))
   filevardef(fout,"vai003_mo_ArcOc",typeof(vai003_mo_ArcOc),getvardims(vai003_mo_ArcOc))
   filevardef(fout,"vai004_mo_ArcOc",typeof(vai004_mo_ArcOc),getvardims(vai004_mo_ArcOc))
   filevardef(fout,"vai005_mo_ArcOc",typeof(vai005_mo_ArcOc),getvardims(vai005_mo_ArcOc))

   filevardef(fout,"vai001_mo_Kara",typeof(vai001_mo_Kara),getvardims(vai001_mo_Kara))
   filevardef(fout,"vai002_mo_Kara",typeof(vai002_mo_Kara),getvardims(vai002_mo_Kara))
   filevardef(fout,"vai003_mo_Kara",typeof(vai003_mo_Kara),getvardims(vai003_mo_Kara))
   filevardef(fout,"vai004_mo_Kara",typeof(vai004_mo_Kara),getvardims(vai004_mo_Kara))
   filevardef(fout,"vai005_mo_Kara",typeof(vai005_mo_Kara),getvardims(vai005_mo_Kara))

   filevardef(fout,"vai001_mo_Laptev",typeof(vai001_mo_Laptev),getvardims(vai001_mo_Laptev))
   filevardef(fout,"vai002_mo_Laptev",typeof(vai002_mo_Laptev),getvardims(vai002_mo_Laptev))
   filevardef(fout,"vai003_mo_Laptev",typeof(vai003_mo_Laptev),getvardims(vai003_mo_Laptev))
   filevardef(fout,"vai004_mo_Laptev",typeof(vai004_mo_Laptev),getvardims(vai004_mo_Laptev))
   filevardef(fout,"vai005_mo_Laptev",typeof(vai005_mo_Laptev),getvardims(vai005_mo_Laptev))

   filevardef(fout,"vai001_mo_Chukchi",typeof(vai001_mo_Chukchi),getvardims(vai001_mo_Chukchi))
   filevardef(fout,"vai002_mo_Chukchi",typeof(vai002_mo_Chukchi),getvardims(vai002_mo_Chukchi))
   filevardef(fout,"vai003_mo_Chukchi",typeof(vai003_mo_Chukchi),getvardims(vai003_mo_Chukchi))
   filevardef(fout,"vai004_mo_Chukchi",typeof(vai004_mo_Chukchi),getvardims(vai004_mo_Chukchi))
   filevardef(fout,"vai005_mo_Chukchi",typeof(vai005_mo_Chukchi),getvardims(vai005_mo_Chukchi))

   filevardef(fout,"vai001_mo_Sib",typeof(vai001_mo_Sib),getvardims(vai001_mo_Sib))
   filevardef(fout,"vai002_mo_Sib",typeof(vai002_mo_Sib),getvardims(vai002_mo_Sib))
   filevardef(fout,"vai003_mo_Sib",typeof(vai003_mo_Sib),getvardims(vai003_mo_Sib))
   filevardef(fout,"vai004_mo_Sib",typeof(vai004_mo_Sib),getvardims(vai004_mo_Sib))
   filevardef(fout,"vai005_mo_Sib",typeof(vai005_mo_Sib),getvardims(vai005_mo_Sib))

   filevardef(fout,"vai001_mo_Beau",typeof(vai001_mo_Beau),getvardims(vai001_mo_Beau))
   filevardef(fout,"vai002_mo_Beau",typeof(vai002_mo_Beau),getvardims(vai002_mo_Beau))
   filevardef(fout,"vai003_mo_Beau",typeof(vai003_mo_Beau),getvardims(vai003_mo_Beau))
   filevardef(fout,"vai004_mo_Beau",typeof(vai004_mo_Beau),getvardims(vai004_mo_Beau))
   filevardef(fout,"vai005_mo_Beau",typeof(vai005_mo_Beau),getvardims(vai005_mo_Beau))

   filevardef(fout,"vai001_mo_CArc",typeof(vai001_mo_CArc),getvardims(vai001_mo_CArc))
   filevardef(fout,"vai002_mo_CArc",typeof(vai002_mo_CArc),getvardims(vai002_mo_CArc))
   filevardef(fout,"vai003_mo_CArc",typeof(vai003_mo_CArc),getvardims(vai003_mo_CArc))
   filevardef(fout,"vai004_mo_CArc",typeof(vai004_mo_CArc),getvardims(vai004_mo_CArc))
   filevardef(fout,"vai005_mo_CArc",typeof(vai005_mo_CArc),getvardims(vai005_mo_CArc))

   filevardef(fout,"vai001_mo_Bering",typeof(vai001_mo_Bering),getvardims(vai001_mo_Bering))
   filevardef(fout,"vai002_mo_Bering",typeof(vai002_mo_Bering),getvardims(vai002_mo_Bering))
   filevardef(fout,"vai003_mo_Bering",typeof(vai003_mo_Bering),getvardims(vai003_mo_Bering))
   filevardef(fout,"vai004_mo_Bering",typeof(vai004_mo_Bering),getvardims(vai004_mo_Bering))
   filevardef(fout,"vai005_mo_Bering",typeof(vai005_mo_Bering),getvardims(vai005_mo_Bering))

   filevardef(fout,"vai001_mo_Okhotsk",typeof(vai001_mo_Okhotsk),getvardims(vai001_mo_Okhotsk))
   filevardef(fout,"vai002_mo_Okhotsk",typeof(vai002_mo_Okhotsk),getvardims(vai002_mo_Okhotsk))
   filevardef(fout,"vai003_mo_Okhotsk",typeof(vai003_mo_Okhotsk),getvardims(vai003_mo_Okhotsk))
   filevardef(fout,"vai004_mo_Okhotsk",typeof(vai004_mo_Okhotsk),getvardims(vai004_mo_Okhotsk))
   filevardef(fout,"vai005_mo_Okhotsk",typeof(vai005_mo_Okhotsk),getvardims(vai005_mo_Okhotsk))

   filevardef(fout,"vai001_mo_Hudson",typeof(vai001_mo_Hudson),getvardims(vai001_mo_Hudson))
   filevardef(fout,"vai002_mo_Hudson",typeof(vai002_mo_Hudson),getvardims(vai002_mo_Hudson))
   filevardef(fout,"vai003_mo_Hudson",typeof(vai003_mo_Hudson),getvardims(vai003_mo_Hudson))
   filevardef(fout,"vai004_mo_Hudson",typeof(vai004_mo_Hudson),getvardims(vai004_mo_Hudson))
   filevardef(fout,"vai005_mo_Hudson",typeof(vai005_mo_Hudson),getvardims(vai005_mo_Hudson))

   filevardef(fout,"vai001_mo_CAArch",typeof(vai001_mo_CAArch),getvardims(vai001_mo_CAArch))
   filevardef(fout,"vai002_mo_CAArch",typeof(vai002_mo_CAArch),getvardims(vai002_mo_CAArch))
   filevardef(fout,"vai003_mo_CAArch",typeof(vai003_mo_CAArch),getvardims(vai003_mo_CAArch))
   filevardef(fout,"vai004_mo_CAArch",typeof(vai004_mo_CAArch),getvardims(vai004_mo_CAArch))
   filevardef(fout,"vai005_mo_CAArch",typeof(vai005_mo_CAArch),getvardims(vai005_mo_CAArch))

   filevardef(fout,"vai001_mo_Wed",typeof(vai001_mo_Wed),getvardims(vai001_mo_Wed))
   filevardef(fout,"vai002_mo_Wed",typeof(vai002_mo_Wed),getvardims(vai002_mo_Wed))
   filevardef(fout,"vai003_mo_Wed",typeof(vai003_mo_Wed),getvardims(vai003_mo_Wed))
   filevardef(fout,"vai004_mo_Wed",typeof(vai004_mo_Wed),getvardims(vai004_mo_Wed))
   filevardef(fout,"vai005_mo_Wed",typeof(vai005_mo_Wed),getvardims(vai005_mo_Wed))

   filevardef(fout,"vai001_mo_Ross",typeof(vai001_mo_Ross),getvardims(vai001_mo_Ross))
   filevardef(fout,"vai002_mo_Ross",typeof(vai002_mo_Ross),getvardims(vai002_mo_Ross))
   filevardef(fout,"vai003_mo_Ross",typeof(vai003_mo_Ross),getvardims(vai003_mo_Ross))
   filevardef(fout,"vai004_mo_Ross",typeof(vai004_mo_Ross),getvardims(vai004_mo_Ross))
   filevardef(fout,"vai005_mo_Ross",typeof(vai005_mo_Ross),getvardims(vai005_mo_Ross))

   filevardef(fout,"vai001_mo_Ind",typeof(vai001_mo_Ind),getvardims(vai001_mo_Ind))
   filevardef(fout,"vai002_mo_Ind",typeof(vai002_mo_Ind),getvardims(vai002_mo_Ind))
   filevardef(fout,"vai003_mo_Ind",typeof(vai003_mo_Ind),getvardims(vai003_mo_Ind))
   filevardef(fout,"vai004_mo_Ind",typeof(vai004_mo_Ind),getvardims(vai004_mo_Ind))
   filevardef(fout,"vai005_mo_Ind",typeof(vai005_mo_Ind),getvardims(vai005_mo_Ind))

   filevardef(fout,"vai001_mo_Pac",typeof(vai001_mo_Pac),getvardims(vai001_mo_Pac))
   filevardef(fout,"vai002_mo_Pac",typeof(vai002_mo_Pac),getvardims(vai002_mo_Pac))
   filevardef(fout,"vai003_mo_Pac",typeof(vai003_mo_Pac),getvardims(vai003_mo_Pac))
   filevardef(fout,"vai004_mo_Pac",typeof(vai004_mo_Pac),getvardims(vai004_mo_Pac))
   filevardef(fout,"vai005_mo_Pac",typeof(vai005_mo_Pac),getvardims(vai005_mo_Pac))

   filevardef(fout,"vai001_mo_BAm",typeof(vai001_mo_BAm),getvardims(vai001_mo_BAm))
   filevardef(fout,"vai002_mo_BAm",typeof(vai002_mo_BAm),getvardims(vai002_mo_BAm))
   filevardef(fout,"vai003_mo_BAm",typeof(vai003_mo_BAm),getvardims(vai003_mo_BAm))
   filevardef(fout,"vai004_mo_BAm",typeof(vai004_mo_BAm),getvardims(vai004_mo_BAm))
   filevardef(fout,"vai005_mo_BAm",typeof(vai005_mo_BAm),getvardims(vai005_mo_BAm))

   filevarattdef(fout,"vai001_mo_nh",vai001_mo_nh)
   filevarattdef(fout,"vai002_mo_nh",vai002_mo_nh)
   filevarattdef(fout,"vai003_mo_nh",vai003_mo_nh)
   filevarattdef(fout,"vai004_mo_nh",vai004_mo_nh)
   filevarattdef(fout,"vai005_mo_nh",vai005_mo_nh)
   filevarattdef(fout,"vai001_mo_sh",vai001_mo_sh)
   filevarattdef(fout,"vai002_mo_sh",vai002_mo_sh)
   filevarattdef(fout,"vai003_mo_sh",vai003_mo_sh)
   filevarattdef(fout,"vai004_mo_sh",vai004_mo_sh)
   filevarattdef(fout,"vai005_mo_sh",vai005_mo_sh)

   filevarattdef(fout,"vai001_mo_Lab",vai001_mo_Lab)
   filevarattdef(fout,"vai002_mo_Lab",vai002_mo_Lab)
   filevarattdef(fout,"vai003_mo_Lab",vai003_mo_Lab)
   filevarattdef(fout,"vai004_mo_Lab",vai004_mo_Lab)
   filevarattdef(fout,"vai005_mo_Lab",vai005_mo_Lab)

   filevarattdef(fout,"vai001_mo_GIN",vai001_mo_GIN)
   filevarattdef(fout,"vai002_mo_GIN",vai002_mo_GIN)
   filevarattdef(fout,"vai003_mo_GIN",vai003_mo_GIN)
   filevarattdef(fout,"vai004_mo_GIN",vai004_mo_GIN)
   filevarattdef(fout,"vai005_mo_GIN",vai005_mo_GIN)

   filevarattdef(fout,"vai001_mo_Bar",vai001_mo_Bar)
   filevarattdef(fout,"vai002_mo_Bar",vai002_mo_Bar)
   filevarattdef(fout,"vai003_mo_Bar",vai003_mo_Bar)
   filevarattdef(fout,"vai004_mo_Bar",vai004_mo_Bar)
   filevarattdef(fout,"vai005_mo_Bar",vai005_mo_Bar)

   filevarattdef(fout,"vai001_mo_ArcOc",vai001_mo_ArcOc)
   filevarattdef(fout,"vai002_mo_ArcOc",vai002_mo_ArcOc)
   filevarattdef(fout,"vai003_mo_ArcOc",vai003_mo_ArcOc)
   filevarattdef(fout,"vai004_mo_ArcOc",vai004_mo_ArcOc)
   filevarattdef(fout,"vai005_mo_ArcOc",vai005_mo_ArcOc)

   filevarattdef(fout,"vai001_mo_Kara",vai001_mo_Kara)
   filevarattdef(fout,"vai002_mo_Kara",vai002_mo_Kara)
   filevarattdef(fout,"vai003_mo_Kara",vai003_mo_Kara)
   filevarattdef(fout,"vai004_mo_Kara",vai004_mo_Kara)
   filevarattdef(fout,"vai005_mo_Kara",vai005_mo_Kara)

   filevarattdef(fout,"vai001_mo_Laptev",vai001_mo_Laptev)
   filevarattdef(fout,"vai002_mo_Laptev",vai002_mo_Laptev)
   filevarattdef(fout,"vai003_mo_Laptev",vai003_mo_Laptev)
   filevarattdef(fout,"vai004_mo_Laptev",vai004_mo_Laptev)
   filevarattdef(fout,"vai005_mo_Laptev",vai005_mo_Laptev)

   filevarattdef(fout,"vai001_mo_Chukchi",vai001_mo_Chukchi)
   filevarattdef(fout,"vai002_mo_Chukchi",vai002_mo_Chukchi)
   filevarattdef(fout,"vai003_mo_Chukchi",vai003_mo_Chukchi)
   filevarattdef(fout,"vai004_mo_Chukchi",vai004_mo_Chukchi)
   filevarattdef(fout,"vai005_mo_Chukchi",vai005_mo_Chukchi)

   filevarattdef(fout,"vai001_mo_Sib",vai001_mo_Sib)
   filevarattdef(fout,"vai002_mo_Sib",vai002_mo_Sib)
   filevarattdef(fout,"vai003_mo_Sib",vai003_mo_Sib)
   filevarattdef(fout,"vai004_mo_Sib",vai004_mo_Sib)
   filevarattdef(fout,"vai005_mo_Sib",vai005_mo_Sib)

   filevarattdef(fout,"vai001_mo_Beau",vai001_mo_Beau)
   filevarattdef(fout,"vai002_mo_Beau",vai002_mo_Beau)
   filevarattdef(fout,"vai003_mo_Beau",vai003_mo_Beau)
   filevarattdef(fout,"vai004_mo_Beau",vai004_mo_Beau)
   filevarattdef(fout,"vai005_mo_Beau",vai005_mo_Beau)

   filevarattdef(fout,"vai001_mo_CArc",vai001_mo_CArc)
   filevarattdef(fout,"vai002_mo_CArc",vai002_mo_CArc)
   filevarattdef(fout,"vai003_mo_CArc",vai003_mo_CArc)
   filevarattdef(fout,"vai004_mo_CArc",vai004_mo_CArc)
   filevarattdef(fout,"vai005_mo_CArc",vai005_mo_CArc)

   filevarattdef(fout,"vai001_mo_Bering",vai001_mo_Bering)
   filevarattdef(fout,"vai002_mo_Bering",vai002_mo_Bering)
   filevarattdef(fout,"vai003_mo_Bering",vai003_mo_Bering)
   filevarattdef(fout,"vai004_mo_Bering",vai004_mo_Bering)
   filevarattdef(fout,"vai005_mo_Bering",vai005_mo_Bering)

   filevarattdef(fout,"vai001_mo_Okhotsk",vai001_mo_Okhotsk)
   filevarattdef(fout,"vai002_mo_Okhotsk",vai002_mo_Okhotsk)
   filevarattdef(fout,"vai003_mo_Okhotsk",vai003_mo_Okhotsk)
   filevarattdef(fout,"vai004_mo_Okhotsk",vai004_mo_Okhotsk)
   filevarattdef(fout,"vai005_mo_Okhotsk",vai005_mo_Okhotsk)

   filevarattdef(fout,"vai001_mo_Hudson",vai001_mo_Hudson)
   filevarattdef(fout,"vai002_mo_Hudson",vai002_mo_Hudson)
   filevarattdef(fout,"vai003_mo_Hudson",vai003_mo_Hudson)
   filevarattdef(fout,"vai004_mo_Hudson",vai004_mo_Hudson)
   filevarattdef(fout,"vai005_mo_Hudson",vai005_mo_Hudson)

   filevarattdef(fout,"vai001_mo_CAArch",vai001_mo_CAArch)
   filevarattdef(fout,"vai002_mo_CAArch",vai002_mo_CAArch)
   filevarattdef(fout,"vai003_mo_CAArch",vai003_mo_CAArch)
   filevarattdef(fout,"vai004_mo_CAArch",vai004_mo_CAArch)
   filevarattdef(fout,"vai005_mo_CAArch",vai005_mo_CAArch)

   filevarattdef(fout,"vai001_mo_Wed",vai001_mo_Wed)
   filevarattdef(fout,"vai002_mo_Wed",vai002_mo_Wed)
   filevarattdef(fout,"vai003_mo_Wed",vai003_mo_Wed)
   filevarattdef(fout,"vai004_mo_Wed",vai004_mo_Wed)
   filevarattdef(fout,"vai005_mo_Wed",vai005_mo_Wed)

   filevarattdef(fout,"vai001_mo_Ross",vai001_mo_Ross)
   filevarattdef(fout,"vai002_mo_Ross",vai002_mo_Ross)
   filevarattdef(fout,"vai003_mo_Ross",vai003_mo_Ross)
   filevarattdef(fout,"vai004_mo_Ross",vai004_mo_Ross)
   filevarattdef(fout,"vai005_mo_Ross",vai005_mo_Ross)

   filevarattdef(fout,"vai001_mo_Ind",vai001_mo_Ind)
   filevarattdef(fout,"vai002_mo_Ind",vai002_mo_Ind)
   filevarattdef(fout,"vai003_mo_Ind",vai003_mo_Ind)
   filevarattdef(fout,"vai004_mo_Ind",vai004_mo_Ind)
   filevarattdef(fout,"vai005_mo_Ind",vai005_mo_Ind)

   filevarattdef(fout,"vai001_mo_Pac",vai001_mo_Pac)
   filevarattdef(fout,"vai002_mo_Pac",vai002_mo_Pac)
   filevarattdef(fout,"vai003_mo_Pac",vai003_mo_Pac)
   filevarattdef(fout,"vai004_mo_Pac",vai004_mo_Pac)
   filevarattdef(fout,"vai001_mo_Pac",vai001_mo_Pac)

   filevarattdef(fout,"vai001_mo_BAm",vai001_mo_BAm)
   filevarattdef(fout,"vai002_mo_BAm",vai002_mo_BAm)
   filevarattdef(fout,"vai003_mo_BAm",vai003_mo_BAm)
   filevarattdef(fout,"vai004_mo_BAm",vai004_mo_BAm)
   filevarattdef(fout,"vai005_mo_BAm",vai005_mo_BAm)

   fout->time = time
   fout->vai001_mo_nh = vai001_mo_nh
   fout->vai002_mo_nh = vai002_mo_nh
   fout->vai003_mo_nh = vai003_mo_nh
   fout->vai004_mo_nh = vai004_mo_nh
   fout->vai005_mo_nh = vai005_mo_nh

   fout->vai001_mo_sh = vai001_mo_sh
   fout->vai002_mo_sh = vai002_mo_sh
   fout->vai003_mo_sh = vai003_mo_sh
   fout->vai004_mo_sh = vai004_mo_sh
   fout->vai005_mo_sh = vai005_mo_sh

   fout->vai001_mo_Lab = vai001_mo_Lab
   fout->vai002_mo_Lab = vai002_mo_Lab
   fout->vai003_mo_Lab = vai003_mo_Lab
   fout->vai004_mo_Lab = vai004_mo_Lab
   fout->vai005_mo_Lab = vai005_mo_Lab

   fout->vai001_mo_GIN = vai001_mo_GIN
   fout->vai002_mo_GIN = vai002_mo_GIN
   fout->vai003_mo_GIN = vai003_mo_GIN
   fout->vai004_mo_GIN = vai004_mo_GIN
   fout->vai005_mo_GIN = vai005_mo_GIN
 
   fout->vai001_mo_Bar = vai001_mo_Bar
   fout->vai002_mo_Bar = vai002_mo_Bar
   fout->vai003_mo_Bar = vai003_mo_Bar
   fout->vai004_mo_Bar = vai004_mo_Bar
   fout->vai005_mo_Bar = vai005_mo_Bar

   fout->vai001_mo_ArcOc = vai001_mo_ArcOc
   fout->vai002_mo_ArcOc = vai002_mo_ArcOc
   fout->vai003_mo_ArcOc = vai003_mo_ArcOc
   fout->vai004_mo_ArcOc = vai004_mo_ArcOc
   fout->vai005_mo_ArcOc = vai005_mo_ArcOc

   fout->vai001_mo_Kara = vai001_mo_Kara
   fout->vai002_mo_Kara = vai002_mo_Kara
   fout->vai003_mo_Kara = vai003_mo_Kara
   fout->vai004_mo_Kara = vai004_mo_Kara
   fout->vai005_mo_Kara = vai005_mo_Kara

   fout->vai001_mo_Laptev = vai001_mo_Laptev
   fout->vai002_mo_Laptev = vai002_mo_Laptev
   fout->vai003_mo_Laptev = vai003_mo_Laptev
   fout->vai004_mo_Laptev = vai004_mo_Laptev
   fout->vai005_mo_Laptev = vai005_mo_Laptev

   fout->vai001_mo_Chukchi = vai001_mo_Chukchi
   fout->vai002_mo_Chukchi = vai002_mo_Chukchi
   fout->vai003_mo_Chukchi = vai003_mo_Chukchi
   fout->vai004_mo_Chukchi = vai004_mo_Chukchi
   fout->vai005_mo_Chukchi = vai005_mo_Chukchi

   fout->vai001_mo_Sib = vai001_mo_Sib
   fout->vai002_mo_Sib = vai002_mo_Sib
   fout->vai003_mo_Sib = vai003_mo_Sib
   fout->vai004_mo_Sib = vai004_mo_Sib
   fout->vai005_mo_Sib = vai005_mo_Sib

   fout->vai001_mo_Beau = vai001_mo_Beau
   fout->vai002_mo_Beau = vai002_mo_Beau
   fout->vai003_mo_Beau = vai003_mo_Beau
   fout->vai004_mo_Beau = vai004_mo_Beau
   fout->vai005_mo_Beau = vai005_mo_Beau

   fout->vai001_mo_CArc = vai001_mo_CArc
   fout->vai002_mo_CArc = vai002_mo_CArc
   fout->vai003_mo_CArc = vai003_mo_CArc
   fout->vai004_mo_CArc = vai004_mo_CArc
   fout->vai005_mo_CArc = vai005_mo_CArc

   fout->vai001_mo_Bering = vai001_mo_Bering
   fout->vai002_mo_Bering = vai002_mo_Bering
   fout->vai003_mo_Bering = vai003_mo_Bering
   fout->vai004_mo_Bering = vai004_mo_Bering
   fout->vai005_mo_Bering = vai005_mo_Bering

   fout->vai001_mo_Okhotsk = vai001_mo_Okhotsk
   fout->vai002_mo_Okhotsk = vai002_mo_Okhotsk
   fout->vai003_mo_Okhotsk = vai003_mo_Okhotsk
   fout->vai004_mo_Okhotsk = vai004_mo_Okhotsk
   fout->vai005_mo_Okhotsk = vai005_mo_Okhotsk
 
   fout->vai001_mo_Hudson = vai001_mo_Hudson
   fout->vai002_mo_Hudson = vai002_mo_Hudson
   fout->vai003_mo_Hudson = vai003_mo_Hudson
   fout->vai004_mo_Hudson = vai004_mo_Hudson
   fout->vai005_mo_Hudson = vai005_mo_Hudson

   fout->vai001_mo_CAArch = vai001_mo_CAArch
   fout->vai002_mo_CAArch = vai002_mo_CAArch
   fout->vai003_mo_CAArch = vai003_mo_CAArch
   fout->vai004_mo_CAArch = vai004_mo_CAArch
   fout->vai005_mo_CAArch = vai005_mo_CAArch

   fout->vai001_mo_Wed = vai001_mo_Wed
   fout->vai002_mo_Wed = vai002_mo_Wed
   fout->vai003_mo_Wed = vai003_mo_Wed
   fout->vai004_mo_Wed = vai004_mo_Wed
   fout->vai005_mo_Wed = vai005_mo_Wed

   fout->vai001_mo_Ross = vai001_mo_Ross
   fout->vai002_mo_Ross = vai002_mo_Ross
   fout->vai003_mo_Ross = vai003_mo_Ross
   fout->vai004_mo_Ross = vai004_mo_Ross
   fout->vai005_mo_Ross = vai005_mo_Ross

   fout->vai001_mo_Ind = vai001_mo_Ind
   fout->vai002_mo_Ind = vai002_mo_Ind
   fout->vai003_mo_Ind = vai003_mo_Ind
   fout->vai004_mo_Ind = vai004_mo_Ind
   fout->vai005_mo_Ind = vai005_mo_Ind

   fout->vai001_mo_Pac = vai001_mo_Pac
   fout->vai002_mo_Pac = vai002_mo_Pac
   fout->vai003_mo_Pac = vai003_mo_Pac
   fout->vai004_mo_Pac = vai004_mo_Pac
   fout->vai005_mo_Pac = vai005_mo_Pac

   fout->vai001_mo_BAm = vai001_mo_BAm
   fout->vai002_mo_BAm = vai002_mo_BAm
   fout->vai003_mo_BAm = vai003_mo_BAm
   fout->vai004_mo_BAm = vai004_mo_BAm
   fout->vai005_mo_BAm = vai005_mo_BAm

end do 						; end do ii
end
