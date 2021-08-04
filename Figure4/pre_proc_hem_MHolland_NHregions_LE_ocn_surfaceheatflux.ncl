; modified to calculate regional totals for surface heat flux
; related variables for ocean-atm interface. This includes fswthru_ai from
; ice output, along with SHF, MELTH_F from ocn output. Ice output is used to
; determine regions of lat/lon to pull (looking at high latitudes and will ignore lower
; latitudes).
; Variables are:
;         fswthru_ai			short-wave heatflux through the ice to the ocean
;         fhocn_ai                      heat flux ice to ocean (should be same as MELTH_F - calculating to double check)
;         SHF   			total surface heat flux (including shortwave)
;         MELTH_F                       melt heat flux from the coupler (should be same as fhocn_ai) but really turbulent heat exchange, ice-ocn
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
;  c20thC_case = LE_20thC_case+ scnumbers(1:)
  c20thC_case = LE_20thC_case+ scnumbers
  rcp85_case = LE_rcp_case+scnumbers

;  case_names = c20thC_case
  case_names = rcp85_case
  ncase = dimsizes(case_names)

  ice_tseries_dir = "/glade/collections/cdg/data/cesmLE/CESM-CAM5-BGC-LE/ice/proc/tseries/monthly/"
  ocn_tseries_dir = "/glade/collections/cdg/data/cesmLE/CESM-CAM5-BGC-LE/ocn/proc/tseries/monthly/"
  out_dir = "/glade/p/cesm/pcwg/landrum/LE/shf/ocn/"

  yr1 = new(ncase,integer)
  yr1 = 2081							; start and end yrs for time series
;  yr1(0) = 1850
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

  ffhocn_ai_nh = ice_tseries_dir+"fhocn_ai/"+case_names+".cice.h.fhocn_ai_nh."+styrs+".nc"
  ffswthru_ai_nh = ice_tseries_dir+"fswthru_ai/"+case_names+".cice.h.fswthru_ai_nh."+styrs+".nc"

  ffhocn_ai_sh = ice_tseries_dir+"fhocn_ai/"+case_names+".cice.h.fhocn_ai_sh."+styrs+".nc"
  ffswthru_ai_sh = ice_tseries_dir+"fswthru_ai/"+case_names+".cice.h.fswthru_ai_sh."+styrs+".nc"

  fSHF = ocn_tseries_dir+"SHF/"+case_names+".pop.h.SHF."+styrs+".nc"
  fMELTH_F = ocn_tseries_dir+"MELTH_F/"+case_names+".pop.h.MELTH_F."+styrs+".nc"

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

  HF_hocn_ai_mo_nh = new((/nyears*12/),float)
  HF_swthru_ai_mo_nh = new((/nyears*12/),float)
  HF_SHF_mo_nh = new((/nyears*12/),float)
  HF_MELTH_F_mo_nh = new((/nyears*12/),float)
  HF_SHF_mo_nh50_90 = new((/nyears*12/),float) 			  ; to limit to higher latitude NH
  HF_MELTH_F_mo_nh50_90 = new((/nyears*12/),float)

  HF_hocn_ai_mo_sh = new((/nyears*12/),float)
  HF_swthru_ai_mo_sh = new((/nyears*12/),float)
  HF_SHF_mo_sh = new((/nyears*12/),float)
  HF_MELTH_F_mo_sh = new((/nyears*12/),float)
  HF_SHF_mo_sh50_90 = new((/nyears*12/),float)                     ; to limit to higher latitude NH
  HF_MELTH_F_mo_sh50_90 = new((/nyears*12/),float)

;*****************************
; regional arrays: Arctic
;*****************************
  HF_hocn_ai_mo_Lab = new((/nyears*12/),float)
  HF_swthru_ai_mo_Lab = new((/nyears*12/),float)
  HF_SHF_mo_Lab = new((/nyears*12/),float)
  HF_MELTH_F_mo_Lab = new((/nyears*12/),float)

  HF_hocn_ai_mo_GIN = new((/nyears*12/),float)
  HF_swthru_ai_mo_GIN = new((/nyears*12/),float)
  HF_SHF_mo_GIN = new((/nyears*12/),float)
  HF_MELTH_F_mo_GIN = new((/nyears*12/),float)

  HF_hocn_ai_mo_Bar = new((/nyears*12/),float)
  HF_swthru_ai_mo_Bar = new((/nyears*12/),float)
  HF_SHF_mo_Bar = new((/nyears*12/),float)
  HF_MELTH_F_mo_Bar = new((/nyears*12/),float)

  HF_hocn_ai_mo_ArcOc = new((/nyears*12/),float)
  HF_swthru_ai_mo_ArcOc = new((/nyears*12/),float)
  HF_SHF_mo_ArcOc = new((/nyears*12/),float)
  HF_MELTH_F_mo_ArcOc = new((/nyears*12/),float)

  HF_hocn_ai_mo_Kara = new((/nyears*12/),float)
  HF_swthru_ai_mo_Kara = new((/nyears*12/),float)
  HF_SHF_mo_Kara = new((/nyears*12/),float)
  HF_MELTH_F_mo_Kara = new((/nyears*12/),float)

  HF_hocn_ai_mo_Laptev = new((/nyears*12/),float)
  HF_swthru_ai_mo_Laptev = new((/nyears*12/),float)
  HF_SHF_mo_Laptev = new((/nyears*12/),float)
  HF_MELTH_F_mo_Laptev = new((/nyears*12/),float)

  HF_hocn_ai_mo_Chukchi = new((/nyears*12/),float)
  HF_swthru_ai_mo_Chukchi = new((/nyears*12/),float)
  HF_SHF_mo_Chukchi = new((/nyears*12/),float)
  HF_MELTH_F_mo_Chukchi = new((/nyears*12/),float)

  HF_hocn_ai_mo_Sib = new((/nyears*12/),float)
  HF_swthru_ai_mo_Sib = new((/nyears*12/),float)
  HF_SHF_mo_Sib = new((/nyears*12/),float)
  HF_MELTH_F_mo_Sib = new((/nyears*12/),float)

  HF_hocn_ai_mo_Beau = new((/nyears*12/),float)
  HF_swthru_ai_mo_Beau = new((/nyears*12/),float)
  HF_SHF_mo_Beau = new((/nyears*12/),float)
  HF_MELTH_F_mo_Beau = new((/nyears*12/),float)

  HF_hocn_ai_mo_CArc = new((/nyears*12/),float)
  HF_swthru_ai_mo_CArc = new((/nyears*12/),float)
  HF_SHF_mo_CArc = new((/nyears*12/),float)
  HF_MELTH_F_mo_CArc = new((/nyears*12/),float)

  HF_hocn_ai_mo_Bering = new((/nyears*12/),float)
  HF_swthru_ai_mo_Bering = new((/nyears*12/),float)
  HF_SHF_mo_Bering = new((/nyears*12/),float)
  HF_MELTH_F_mo_Bering = new((/nyears*12/),float)

  HF_hocn_ai_mo_Okhotsk = new((/nyears*12/),float)
  HF_swthru_ai_mo_Okhotsk = new((/nyears*12/),float)
  HF_SHF_mo_Okhotsk = new((/nyears*12/),float)
  HF_MELTH_F_mo_Okhotsk = new((/nyears*12/),float)

  HF_hocn_ai_mo_Hudson = new((/nyears*12/),float)
  HF_swthru_ai_mo_Hudson = new((/nyears*12/),float)
  HF_SHF_mo_Hudson = new((/nyears*12/),float)
  HF_MELTH_F_mo_Hudson = new((/nyears*12/),float)

  HF_hocn_ai_mo_CAArch = new((/nyears*12/),float)
  HF_swthru_ai_mo_CAArch = new((/nyears*12/),float)
  HF_SHF_mo_CAArch = new((/nyears*12/),float)
  HF_MELTH_F_mo_CAArch = new((/nyears*12/),float)
;*****************************
; regional arrays: Antarctic
;*****************************
  HF_hocn_ai_mo_Wed = new((/nyears*12/),float)
  HF_swthru_ai_mo_Wed = new((/nyears*12/),float)
  HF_SHF_mo_Wed = new((/nyears*12/),float)
  HF_MELTH_F_mo_Wed = new((/nyears*12/),float)

  HF_hocn_ai_mo_Ross = new((/nyears*12/),float)
  HF_swthru_ai_mo_Ross = new((/nyears*12/),float)
  HF_SHF_mo_Ross = new((/nyears*12/),float)
  HF_MELTH_F_mo_Ross = new((/nyears*12/),float)

  HF_hocn_ai_mo_Ind = new((/nyears*12/),float)
  HF_swthru_ai_mo_Ind = new((/nyears*12/),float)
  HF_SHF_mo_Ind = new((/nyears*12/),float)
  HF_MELTH_F_mo_Ind = new((/nyears*12/),float)
 
  HF_hocn_ai_mo_Pac = new((/nyears*12/),float)
  HF_swthru_ai_mo_Pac = new((/nyears*12/),float)
  HF_SHF_mo_Pac = new((/nyears*12/),float)
  HF_MELTH_F_mo_Pac = new((/nyears*12/),float)

  HF_hocn_ai_mo_BAm = new((/nyears*12/),float)
  HF_swthru_ai_mo_BAm = new((/nyears*12/),float)
  HF_SHF_mo_BAm = new((/nyears*12/),float)
  HF_MELTH_F_mo_BAm = new((/nyears*12/),float)

;  time = new((/nyears*12/),float)

do ii = 0,ncase-1
   print("calculating area totals for "+case_names(ii))
   f1_nh = addfile(ffhocn_ai_nh(ii),"r")
   f2_nh = addfile(ffswthru_ai_nh(ii),"r")
   f3 = addfile(fSHF(ii),"r")
   f4 = addfile(fMELTH_F(ii),"r")

   f1_sh = addfile(ffhocn_ai_sh(ii),"r")
   f2_sh = addfile(ffswthru_ai_sh(ii),"r")

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

         tlat_ocn = f3->TLAT
         tlon_ocn = f3->TLONG
         dims_ocn = dimsizes(tlat_ocn)
         dims_nh = dimsizes(tlat_nh)
         dims_sh = dimsizes(tlat_sh)

         nj_sh = dims_sh(0)					; SH is first 
         nj_nh = dims_ocn(0) - dims_nh(0)			; NH is last

      end if

      fhocn_ai_nh = f1_nh->fhocn_ai(imo1_datain:imo2_datain,:,:)
      fswthru_ai_nh = f2_nh->fswthru_ai(imo1_datain:imo2_datain,:,:)
      SHF_nh = f3->SHF(imo1_datain:imo2_datain,nj_nh:,:)
      MELTH_F_nh = f4->MELTH_F(imo1_datain:imo2_datain,nj_nh:,:)

      tlat2_nh = conform(fhocn_ai_nh,tlat_nh,(/1,2/))
      tlon2_nh = conform(fhocn_ai_nh,tlon_nh,(/1,2/))
      HF_hocn_ai_nh = fhocn_ai_nh*conform(fhocn_ai_nh,tarea_nh,(/1,2/))
      HF_swthru_ai_nh = fswthru_ai_nh*conform(fswthru_ai_nh,tarea_nh,(/1,2/))
      HF_SHF_nh = SHF_nh*conform(SHF_nh,tarea_nh,(/1,2/))
      HF_MELTH_F_nh = MELTH_F_nh*conform(MELTH_F_nh,tarea_nh,(/1,2/))

      fhocn_ai_sh = f1_sh->fhocn_ai(imo1_datain:imo2_datain,:,:)
      fswthru_ai_sh = f2_sh->fswthru_ai(imo1_datain:imo2_datain,:,:)
      SHF_sh = f3->SHF(imo1_datain:imo2_datain,:nj_sh-1,:)
      MELTH_F_sh = f4->MELTH_F(imo1_datain:imo2_datain,:nj_sh-1,:)

      tlat2_sh = conform(fhocn_ai_sh,tlat_sh,(/1,2/))
      tlon2_sh = conform(fhocn_ai_sh,tlon_sh,(/1,2/))
      HF_hocn_ai_sh = fhocn_ai_sh*conform(fhocn_ai_sh,tarea_sh,(/1,2/))
      HF_swthru_ai_sh = fswthru_ai_sh*conform(fswthru_ai_sh,tarea_sh,(/1,2/))
      HF_SHF_sh = SHF_sh*conform(SHF_sh,tarea_sh,(/1,2/))
      HF_MELTH_F_sh = MELTH_F_sh*conform(MELTH_F_sh,tarea_sh,(/1,2/))

;-------------------------------------------------------------
; create masks for Labrador Sea, Bering Sea, Sea of Okhotsk,
; Hudson Bay and Canadian Archipelago here. They are not simply
; rectangles...........
; Only need to do this once (first year of nyears)
;------------------------------------------------------------
      if ((ii.eq.0).and.(nn .eq. 0)) then
         Lab_mask = new(dimsizes(HF_hocn_ai_nh),typeof(HF_hocn_ai_nh),HF_hocn_ai_nh@_FillValue)
         Bering_mask = new(dimsizes(HF_hocn_ai_nh),typeof(HF_hocn_ai_nh),HF_hocn_ai_nh@_FillValue)
         Okhotsk_mask = new(dimsizes(HF_hocn_ai_nh),typeof(HF_hocn_ai_nh),HF_hocn_ai_nh@_FillValue)
         CAArch_mask = new(dimsizes(HF_hocn_ai_nh),typeof(HF_hocn_ai_nh),HF_hocn_ai_nh@_FillValue)
         Hudson_mask = new(dimsizes(HF_hocn_ai_nh),typeof(HF_hocn_ai_nh),HF_hocn_ai_nh@_FillValue)
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

      HF_SHF_nh50_90 = mask(HF_SHF_nh,(tlat2_nh.ge.nh50_90_lat(0) .and. tlat2_nh.le.nh50_90_lat(1)),True)
      HF_MELTH_F_nh50_90 = mask(HF_MELTH_F_nh,(tlat2_nh.ge.nh50_90_lat(0) .and. tlat2_nh.le.nh50_90_lat(1)),True)

      HF_swthru_ai_Lab = mask(HF_swthru_ai_nh,(Lab_mask .eq. 1.), True)
      HF_hocn_ai_Lab = mask(HF_hocn_ai_nh,(Lab_mask .eq. 1.), True)
      HF_SHF_Lab = mask(HF_SHF_nh,(Lab_mask .eq. 1.), True)
      HF_MELTH_F_Lab = mask(HF_MELTH_F_nh,(Lab_mask .eq. 1.), True)
 
      HF_swthru_ai_GIN = mask(HF_swthru_ai_nh,(tlat2_nh.ge.GIN_lat(0) .and. tlat2_nh.le.GIN_lat(1) .and.\
                  ((tlon2_nh.ge.GIN_long1(0) .and. tlon2_nh.le.GIN_long1(1)) .or.\
		   (tlon2_nh.ge.GIN_long2(0) .and. tlon2_nh.le.GIN_long2(1)))), True)
      HF_hocn_ai_GIN = mask(HF_hocn_ai_nh,(tlat2_nh.ge.GIN_lat(0) .and. tlat2_nh.le.GIN_lat(1) .and.\
                  ((tlon2_nh.ge.GIN_long1(0) .and. tlon2_nh.le.GIN_long1(1)) .or.\
                   (tlon2_nh.ge.GIN_long2(0) .and. tlon2_nh.le.GIN_long2(1)))), True)
      HF_SHF_GIN = mask(HF_SHF_nh,(tlat2_nh.ge.GIN_lat(0) .and. tlat2_nh.le.GIN_lat(1) .and.\
                  ((tlon2_nh.ge.GIN_long1(0) .and. tlon2_nh.le.GIN_long1(1)) .or.\
                   (tlon2_nh.ge.GIN_long2(0) .and. tlon2_nh.le.GIN_long2(1)))), True)
      HF_MELTH_F_GIN = mask(HF_MELTH_F_nh,(tlat2_nh.ge.GIN_lat(0) .and. tlat2_nh.le.GIN_lat(1) .and.\
                  ((tlon2_nh.ge.GIN_long1(0) .and. tlon2_nh.le.GIN_long1(1)) .or.\
                   (tlon2_nh.ge.GIN_long2(0) .and. tlon2_nh.le.GIN_long2(1)))), True)

      HF_swthru_ai_Bar = mask(HF_swthru_ai_nh,(tlat2_nh.ge.Bar_lat(0) .and. tlat2_nh.le.Bar_lat(1) .and.\
                  tlon2_nh.ge.Bar_long(0) .and. tlon2_nh.le.Bar_long(1)), True)
      HF_hocn_ai_Bar = mask(HF_hocn_ai_nh,(tlat2_nh.ge.Bar_lat(0) .and. tlat2_nh.le.Bar_lat(1) .and.\
                  tlon2_nh.ge.Bar_long(0) .and. tlon2_nh.le.Bar_long(1)), True)
      HF_SHF_Bar = mask(HF_SHF_nh,(tlat2_nh.ge.Bar_lat(0) .and. tlat2_nh.le.Bar_lat(1) .and.\
                  tlon2_nh.ge.Bar_long(0) .and. tlon2_nh.le.Bar_long(1)), True)
      HF_MELTH_F_Bar = mask(HF_MELTH_F_nh,(tlat2_nh.ge.Bar_lat(0) .and. tlat2_nh.le.Bar_lat(1) .and.\
                  tlon2_nh.ge.Bar_long(0) .and. tlon2_nh.le.Bar_long(1)), True)

      HF_swthru_ai_ArcOc = mask(HF_swthru_ai_nh,((tlat2_nh.ge.ArcOc_lat1(0) .and. (tlon2_nh.ge.ArcOc_long1(0) .or.\
                  tlon2_nh.le.ArcOc_long2(1))) .or. (tlat2_nh.ge.ArcOc_lat3(0) .and.\
                   (tlon2_nh.ge.ArcOc_long3(0) .and. tlon2_nh.le.ArcOc_long3(1)))), True)
      HF_hocn_ai_ArcOc = mask(HF_hocn_ai_nh,((tlat2_nh.ge.ArcOc_lat1(0) .and. (tlon2_nh.ge.ArcOc_long1(0) .or.\
                  tlon2_nh.le.ArcOc_long2(1))) .or. (tlat2_nh.ge.ArcOc_lat3(0) .and.\
                   (tlon2_nh.ge.ArcOc_long3(0) .and. tlon2_nh.le.ArcOc_long3(1)))), True)
      HF_SHF_ArcOc = mask(HF_SHF_nh,((tlat2_nh.ge.ArcOc_lat1(0) .and. (tlon2_nh.ge.ArcOc_long1(0) .or.\
                  tlon2_nh.le.ArcOc_long2(1))) .or. (tlat2_nh.ge.ArcOc_lat3(0) .and.\
                   (tlon2_nh.ge.ArcOc_long3(0) .and. tlon2_nh.le.ArcOc_long3(1)))), True)
      HF_MELTH_F_ArcOc = mask(HF_MELTH_F_nh,((tlat2_nh.ge.ArcOc_lat1(0) .and. (tlon2_nh.ge.ArcOc_long1(0) .or.\
                  tlon2_nh.le.ArcOc_long2(1))) .or. (tlat2_nh.ge.ArcOc_lat3(0) .and.\
                   (tlon2_nh.ge.ArcOc_long3(0) .and. tlon2_nh.le.ArcOc_long3(1)))), True)

      HF_swthru_ai_Kara = mask(HF_swthru_ai_nh,(tlat2_nh.ge.Kara_lat(0) .and. tlat2_nh.le.Kara_lat(1) .and.\
                  tlon2_nh.ge.Kara_long(0) .and. tlon2_nh.le.Kara_long(1)), True)
      HF_hocn_ai_Kara = mask(HF_hocn_ai_nh,(tlat2_nh.ge.Kara_lat(0) .and. tlat2_nh.le.Kara_lat(1) .and.\
                  tlon2_nh.ge.Kara_long(0) .and. tlon2_nh.le.Kara_long(1)), True)
      HF_SHF_Kara = mask(HF_SHF_nh,(tlat2_nh.ge.Kara_lat(0) .and. tlat2_nh.le.Kara_lat(1) .and.\
                  tlon2_nh.ge.Kara_long(0) .and. tlon2_nh.le.Kara_long(1)), True)
      HF_MELTH_F_Kara = mask(HF_MELTH_F_nh,(tlat2_nh.ge.Kara_lat(0) .and. tlat2_nh.le.Kara_lat(1) .and.\
                  tlon2_nh.ge.Kara_long(0) .and. tlon2_nh.le.Kara_long(1)), True)

      HF_swthru_ai_Laptev = mask(HF_swthru_ai_nh,(tlat2_nh.ge.Laptev_lat(0) .and. tlat2_nh.le.Laptev_lat(1) .and.\
                  tlon2_nh.ge.Laptev_long(0) .and. tlon2_nh.le.Laptev_long(1)), True)
      HF_hocn_ai_Laptev = mask(HF_hocn_ai_nh,(tlat2_nh.ge.Laptev_lat(0) .and. tlat2_nh.le.Laptev_lat(1) .and.\
                  tlon2_nh.ge.Laptev_long(0) .and. tlon2_nh.le.Laptev_long(1)), True)
      HF_SHF_Laptev = mask(HF_SHF_nh,(tlat2_nh.ge.Laptev_lat(0) .and. tlat2_nh.le.Laptev_lat(1) .and.\
                  tlon2_nh.ge.Laptev_long(0) .and. tlon2_nh.le.Laptev_long(1)), True)
      HF_MELTH_F_Laptev = mask(HF_MELTH_F_nh,(tlat2_nh.ge.Laptev_lat(0) .and. tlat2_nh.le.Laptev_lat(1) .and.\
                  tlon2_nh.ge.Laptev_long(0) .and. tlon2_nh.le.Laptev_long(1)), True)

      HF_swthru_ai_Chukchi = mask(HF_swthru_ai_nh,(tlat2_nh.ge.Chukchi_lat(0) .and. tlat2_nh.le.Chukchi_lat(1) .and.\
                  tlon2_nh.ge.Chukchi_long(0) .and. tlon2_nh.le.Chukchi_long(1)), True)
      HF_hocn_ai_Chukchi = mask(HF_hocn_ai_nh,(tlat2_nh.ge.Chukchi_lat(0) .and. tlat2_nh.le.Chukchi_lat(1) .and.\
                  tlon2_nh.ge.Chukchi_long(0) .and. tlon2_nh.le.Chukchi_long(1)), True)
      HF_SHF_Chukchi = mask(HF_SHF_nh,(tlat2_nh.ge.Chukchi_lat(0) .and. tlat2_nh.le.Chukchi_lat(1) .and.\
                  tlon2_nh.ge.Chukchi_long(0) .and. tlon2_nh.le.Chukchi_long(1)), True)
      HF_MELTH_F_Chukchi = mask(HF_MELTH_F_nh,(tlat2_nh.ge.Chukchi_lat(0) .and. tlat2_nh.le.Chukchi_lat(1) .and.\
                  tlon2_nh.ge.Chukchi_long(0) .and. tlon2_nh.le.Chukchi_long(1)), True)

      HF_swthru_ai_Sib = mask(HF_swthru_ai_nh,(tlat2_nh.ge.Sib_lat(0) .and. tlat2_nh.le.Sib_lat(1) .and.\
                  tlon2_nh.ge.Sib_long(0) .and. tlon2_nh.le.Sib_long(1)), True)
      HF_hocn_ai_Sib = mask(HF_hocn_ai_nh,(tlat2_nh.ge.Sib_lat(0) .and. tlat2_nh.le.Sib_lat(1) .and.\
                  tlon2_nh.ge.Sib_long(0) .and. tlon2_nh.le.Sib_long(1)), True)
      HF_SHF_Sib = mask(HF_SHF_nh,(tlat2_nh.ge.Sib_lat(0) .and. tlat2_nh.le.Sib_lat(1) .and.\
                  tlon2_nh.ge.Sib_long(0) .and. tlon2_nh.le.Sib_long(1)), True)
      HF_MELTH_F_Sib = mask(HF_MELTH_F_nh,(tlat2_nh.ge.Sib_lat(0) .and. tlat2_nh.le.Sib_lat(1) .and.\
                  tlon2_nh.ge.Sib_long(0) .and. tlon2_nh.le.Sib_long(1)), True)

      HF_swthru_ai_Beau = mask(HF_swthru_ai_nh,(tlat2_nh.ge.Beau_lat(0) .and. tlat2_nh.le.Beau_lat(1) .and.\
                  tlon2_nh.ge.Beau_long(0) .and. tlon2_nh.le.Beau_long(1)), True)
      HF_hocn_ai_Beau = mask(HF_hocn_ai_nh,(tlat2_nh.ge.Beau_lat(0) .and. tlat2_nh.le.Beau_lat(1) .and.\
                  tlon2_nh.ge.Beau_long(0) .and. tlon2_nh.le.Beau_long(1)), True)
      HF_SHF_Beau = mask(HF_SHF_nh,(tlat2_nh.ge.Beau_lat(0) .and. tlat2_nh.le.Beau_lat(1) .and.\
                  tlon2_nh.ge.Beau_long(0) .and. tlon2_nh.le.Beau_long(1)), True)
      HF_MELTH_F_Beau = mask(HF_MELTH_F_nh,(tlat2_nh.ge.Beau_lat(0) .and. tlat2_nh.le.Beau_lat(1) .and.\
                  tlon2_nh.ge.Beau_long(0) .and. tlon2_nh.le.Beau_long(1)), True)

      HF_swthru_ai_CArc = mask(HF_swthru_ai_nh,(tlat2_nh.ge.CArc_lat(0) .and. tlat2_nh.le.CArc_lat(1) .and.\
                  tlon2_nh.ge.CArc_long(0) .and. tlon2_nh.le.CArc_long(1)), True)
      HF_hocn_ai_CArc = mask(HF_hocn_ai_nh,(tlat2_nh.ge.CArc_lat(0) .and. tlat2_nh.le.CArc_lat(1) .and.\
                  tlon2_nh.ge.CArc_long(0) .and. tlon2_nh.le.CArc_long(1)), True)
      HF_SHF_CArc = mask(HF_SHF_nh,(tlat2_nh.ge.CArc_lat(0) .and. tlat2_nh.le.CArc_lat(1) .and.\
                  tlon2_nh.ge.CArc_long(0) .and. tlon2_nh.le.CArc_long(1)), True)
      HF_MELTH_F_CArc = mask(HF_MELTH_F_nh,(tlat2_nh.ge.CArc_lat(0) .and. tlat2_nh.le.CArc_lat(1) .and.\
                  tlon2_nh.ge.CArc_long(0) .and. tlon2_nh.le.CArc_long(1)), True)

      HF_swthru_ai_Bering = mask(HF_swthru_ai_nh,(Bering_mask .eq. 1.), True)
      HF_hocn_ai_Bering = mask(HF_hocn_ai_nh,(Bering_mask .eq. 1.), True)
      HF_SHF_Bering = mask(HF_SHF_nh,(Bering_mask .eq. 1.), True)
      HF_MELTH_F_Bering = mask(HF_MELTH_F_nh,(Bering_mask .eq. 1.), True)

      HF_swthru_ai_Okhotsk = mask(HF_swthru_ai_nh,(Okhotsk_mask .eq. 1.), True)
      HF_hocn_ai_Okhotsk = mask(HF_hocn_ai_nh,(Okhotsk_mask .eq. 1.), True)
      HF_SHF_Okhotsk = mask(HF_SHF_nh,(Okhotsk_mask .eq. 1.), True)
      HF_MELTH_F_Okhotsk = mask(HF_MELTH_F_nh,(Okhotsk_mask .eq. 1.), True)

      HF_swthru_ai_Hudson = mask(HF_swthru_ai_nh,(Hudson_mask .eq. 1.), True)
      HF_hocn_ai_Hudson = mask(HF_hocn_ai_nh,(Hudson_mask .eq. 1.), True)
      HF_SHF_Hudson = mask(HF_SHF_nh,(Hudson_mask .eq. 1.), True)
      HF_MELTH_F_Hudson = mask(HF_MELTH_F_nh,(Hudson_mask .eq. 1.), True)

      HF_swthru_ai_CAArch = mask(HF_swthru_ai_nh,(CAArch_mask .eq. 1.), True)
      HF_hocn_ai_CAArch = mask(HF_hocn_ai_nh,(CAArch_mask .eq. 1.), True)
      HF_SHF_CAArch = mask(HF_SHF_nh,(CAArch_mask .eq. 1.), True)
      HF_MELTH_F_CAArch = mask(HF_MELTH_F_nh,(CAArch_mask .eq. 1.), True)

      HF_SHF_sh50_90 = mask(HF_SHF_sh,(tlat2_sh.ge.sh50_90_lat(0) .and. tlat2_sh.le.sh50_90_lat(1)),True)
      HF_MELTH_F_sh50_90 = mask(HF_MELTH_F_sh,(tlat2_sh.ge.sh50_90_lat(0) .and. tlat2_sh.le.sh50_90_lat(1)),True)

      HF_swthru_ai_Wed = mask(HF_swthru_ai_sh,(tlat2_sh.le.Wed_lat(1) .and. ((tlon2_sh.ge.Wed_long1(0) \
                  .and. tlon2_sh.le.Wed_long1(1)) .or. (tlon2_sh.ge.Wed_long2(0) \
                   .and. tlon2_sh.le.Wed_long2(1)))), True)
      HF_hocn_ai_Wed = mask(HF_hocn_ai_sh,(tlat2_sh.le.Wed_lat(1) .and.((tlon2_sh.ge.Wed_long1(0) \
                  .and. tlon2_sh.le.Wed_long1(1)) .or. (tlon2_sh.ge.Wed_long2(0) \
                  .and. tlon2_sh.le.Wed_long2(1)))), True)
      HF_SHF_Wed = mask(HF_SHF_sh,(tlat2_sh.le.Wed_lat(1) .and. ((tlon2_sh.ge.Wed_long1(0) \
                  .and. tlon2_sh.le.Wed_long1(1)) .or. (tlon2_sh.ge.Wed_long2(0) \
                  .and. tlon2_sh.le.Wed_long2(1)))), True)
      HF_MELTH_F_Wed = mask(HF_MELTH_F_sh,(tlat2_sh.le.Wed_lat(1) .and. ((tlon2_sh.ge.Wed_long1(0) \
                  .and. tlon2_sh.le.Wed_long1(1)) .or. (tlon2_sh.ge.Wed_long2(0) \
                  .and. tlon2_sh.le.Wed_long2(1)))), True)

      HF_swthru_ai_Ross = mask(HF_swthru_ai_sh,(tlat2_sh.le.Ross_lat(1) .and. tlon2_sh.ge.Ross_long(0) \
		   .and. tlon2_sh.le.Ross_long(1)), True)
      HF_hocn_ai_Ross = mask(HF_hocn_ai_sh,(tlat2_sh.le.Ross_lat(1) .and. tlon2_sh.ge.Ross_long(0) \
		   .and. tlon2_sh.le.Ross_long(1)), True)
      HF_SHF_Ross = mask(HF_SHF_sh,(tlat2_sh.le.Ross_lat(1) .and. tlon2_sh.ge.Ross_long(0) \
                   .and. tlon2_sh.le.Ross_long(1)), True)
      HF_MELTH_F_Ross = mask(HF_MELTH_F_sh,(tlat2_sh.le.Ross_lat(1) .and. tlon2_sh.ge.Ross_long(0) \
                   .and. tlon2_sh.le.Ross_long(1)), True)

      HF_swthru_ai_Ind = mask(HF_swthru_ai_sh,(tlat2_sh.le.Ind_lat(1) .and. tlon2_sh.ge.Ind_long(0) \
                   .and. tlon2_sh.le.Ind_long(1)), True)
      HF_hocn_ai_Ind = mask(HF_hocn_ai_sh,(tlat2_sh.le.Ind_lat(1) .and. tlon2_sh.ge.Ind_long(0) \
                   .and. tlon2_sh.le.Ind_long(1)), True)
      HF_SHF_Ind = mask(HF_SHF_sh,(tlat2_sh.le.Ind_lat(1) .and. tlon2_sh.ge.Ind_long(0) \
                   .and. tlon2_sh.le.Ind_long(1)), True)
      HF_MELTH_F_Ind = mask(HF_MELTH_F_sh,(tlat2_sh.le.Ind_lat(1) .and. tlon2_sh.ge.Ind_long(0) \
                   .and. tlon2_sh.le.Ind_long(1)), True)

      HF_swthru_ai_Pac = mask(HF_swthru_ai_sh,(tlat2_sh.le.Pac_lat(1) .and. tlon2_sh.ge.Pac_long(0) \
                   .and. tlon2_sh.le.Pac_long(1)), True)
      HF_hocn_ai_Pac = mask(HF_hocn_ai_sh,(tlat2_sh.le.Pac_lat(1) .and. tlon2_sh.ge.Pac_long(0) \
                   .and. tlon2_sh.le.Pac_long(1)), True)
      HF_SHF_Pac = mask(HF_SHF_sh,(tlat2_sh.le.Pac_lat(1) .and. tlon2_sh.ge.Pac_long(0) \
                   .and. tlon2_sh.le.Pac_long(1)), True)
      HF_MELTH_F_Pac = mask(HF_MELTH_F_sh,(tlat2_sh.le.Pac_lat(1) .and. tlon2_sh.ge.Pac_long(0) \
                   .and. tlon2_sh.le.Pac_long(1)), True)

      HF_swthru_ai_BAm = mask(HF_swthru_ai_sh,(tlat2_sh.le.BAm_lat(1) .and. tlon2_sh.ge.BAm_long(0) \
                   .and. tlon2_sh.le.BAm_long(1)), True)
      HF_hocn_ai_BAm = mask(HF_hocn_ai_sh,(tlat2_sh.le.BAm_lat(1) .and. tlon2_sh.ge.BAm_long(0) \
                   .and. tlon2_sh.le.BAm_long(1)), True)
      HF_SHF_BAm = mask(HF_SHF_sh,(tlat2_sh.le.BAm_lat(1) .and. tlon2_sh.ge.BAm_long(0) \
                   .and. tlon2_sh.le.BAm_long(1)), True)
      HF_MELTH_F_BAm = mask(HF_MELTH_F_sh,(tlat2_sh.le.BAm_lat(1) .and. tlon2_sh.ge.BAm_long(0) \
                   .and. tlon2_sh.le.BAm_long(1)), True)
;********************************
; northern hemisphere monthly ...
;********************************
      HF_SHF_mo_nh50_90(imo1:imo2) = dim_sum(dim_sum(HF_SHF_nh50_90))*1.0e-14
      HF_MELTH_F_mo_nh50_90(imo1:imo2) = dim_sum(dim_sum(HF_MELTH_F_nh50_90))*1.0e-12

      HF_hocn_ai_mo_nh(imo1:imo2) = dim_sum(dim_sum(HF_hocn_ai_nh))*1.0e-12 
      HF_swthru_ai_mo_nh(imo1:imo2) = dim_sum(dim_sum(HF_swthru_ai_nh))*1.0e-12
      HF_SHF_mo_nh(imo1:imo2) = dim_sum(dim_sum(HF_SHF_nh))*1.0e-14
      HF_MELTH_F_mo_nh(imo1:imo2) = dim_sum(dim_sum(HF_MELTH_F_nh))*1.0e-12

      HF_hocn_ai_mo_Lab(imo1:imo2) = dim_sum(dim_sum(HF_hocn_ai_Lab))*1.0e-12 
      HF_swthru_ai_mo_Lab(imo1:imo2) = dim_sum(dim_sum(HF_swthru_ai_Lab))*1.0e-12
      HF_SHF_mo_Lab(imo1:imo2) = dim_sum(dim_sum(HF_SHF_Lab))*1.0e-14
      HF_MELTH_F_mo_Lab(imo1:imo2) = dim_sum(dim_sum(HF_MELTH_F_Lab))*1.0e-12
 
      HF_hocn_ai_mo_GIN(imo1:imo2) = dim_sum(dim_sum(HF_hocn_ai_GIN))*1.0e-12 
      HF_swthru_ai_mo_GIN(imo1:imo2) = dim_sum(dim_sum(HF_swthru_ai_GIN))*1.0e-12
      HF_SHF_mo_GIN(imo1:imo2) = dim_sum(dim_sum(HF_SHF_GIN))*1.0e-14
      HF_MELTH_F_mo_GIN(imo1:imo2) = dim_sum(dim_sum(HF_MELTH_F_GIN))*1.0e-12
 
      HF_hocn_ai_mo_Bar(imo1:imo2) = dim_sum(dim_sum(HF_hocn_ai_Bar))*1.0e-12 
      HF_swthru_ai_mo_Bar(imo1:imo2) = dim_sum(dim_sum(HF_swthru_ai_Bar))*1.0e-12
      HF_SHF_mo_Bar(imo1:imo2) = dim_sum(dim_sum(HF_SHF_Bar))*1.0e-14
      HF_MELTH_F_mo_Bar(imo1:imo2) = dim_sum(dim_sum(HF_MELTH_F_Bar))*1.0e-12
 
      HF_hocn_ai_mo_ArcOc(imo1:imo2) = dim_sum(dim_sum(HF_hocn_ai_ArcOc))*1.0e-12 
      HF_swthru_ai_mo_ArcOc(imo1:imo2) = dim_sum(dim_sum(HF_swthru_ai_ArcOc))*1.0e-12
      HF_SHF_mo_ArcOc(imo1:imo2) = dim_sum(dim_sum(HF_SHF_ArcOc))*1.0e-14
      HF_MELTH_F_mo_ArcOc(imo1:imo2) = dim_sum(dim_sum(HF_MELTH_F_ArcOc))*1.0e-12

      HF_hocn_ai_mo_Kara(imo1:imo2) = dim_sum(dim_sum(HF_hocn_ai_Kara))*1.0e-12
      HF_swthru_ai_mo_Kara(imo1:imo2) = dim_sum(dim_sum(HF_swthru_ai_Kara))*1.0e-12
      HF_SHF_mo_Kara(imo1:imo2) = dim_sum(dim_sum(HF_SHF_Kara))*1.0e-14
      HF_MELTH_F_mo_Kara(imo1:imo2) = dim_sum(dim_sum(HF_MELTH_F_Kara))*1.0e-12

      HF_hocn_ai_mo_Laptev(imo1:imo2) = dim_sum(dim_sum(HF_hocn_ai_Laptev))*1.0e-12
      HF_swthru_ai_mo_Laptev(imo1:imo2) = dim_sum(dim_sum(HF_swthru_ai_Laptev))*1.0e-12
      HF_SHF_mo_Laptev(imo1:imo2) = dim_sum(dim_sum(HF_SHF_Laptev))*1.0e-14
      HF_MELTH_F_mo_Laptev(imo1:imo2) = dim_sum(dim_sum(HF_MELTH_F_Laptev))*1.0e-12

      HF_hocn_ai_mo_Chukchi(imo1:imo2) = dim_sum(dim_sum(HF_hocn_ai_Chukchi))*1.0e-12
      HF_swthru_ai_mo_Chukchi(imo1:imo2) = dim_sum(dim_sum(HF_swthru_ai_Chukchi))*1.0e-12
      HF_SHF_mo_Chukchi(imo1:imo2) = dim_sum(dim_sum(HF_SHF_Chukchi))*1.0e-14
      HF_MELTH_F_mo_Chukchi(imo1:imo2) = dim_sum(dim_sum(HF_MELTH_F_Chukchi))*1.0e-12

      HF_hocn_ai_mo_Sib(imo1:imo2) = dim_sum(dim_sum(HF_hocn_ai_Sib))*1.0e-12 
      HF_swthru_ai_mo_Sib(imo1:imo2) = dim_sum(dim_sum(HF_swthru_ai_Sib))*1.0e-12
      HF_SHF_mo_Sib(imo1:imo2) = dim_sum(dim_sum(HF_SHF_Sib))*1.0e-14
      HF_MELTH_F_mo_Sib(imo1:imo2) = dim_sum(dim_sum(HF_MELTH_F_Sib))*1.0e-12

      HF_hocn_ai_mo_Beau(imo1:imo2) = dim_sum(dim_sum(HF_hocn_ai_Beau))*1.0e-12 
      HF_swthru_ai_mo_Beau(imo1:imo2) = dim_sum(dim_sum(HF_swthru_ai_Beau))*1.0e-12
      HF_SHF_mo_Beau(imo1:imo2) = dim_sum(dim_sum(HF_SHF_Beau))*1.0e-14
      HF_MELTH_F_mo_Beau(imo1:imo2) = dim_sum(dim_sum(HF_MELTH_F_Beau))*1.0e-12
 
      HF_hocn_ai_mo_CArc(imo1:imo2) = dim_sum(dim_sum(HF_hocn_ai_CArc))*1.0e-12 
      HF_swthru_ai_mo_CArc(imo1:imo2) = dim_sum(dim_sum(HF_swthru_ai_CArc))*1.0e-12
      HF_SHF_mo_CArc(imo1:imo2) = dim_sum(dim_sum(HF_SHF_CArc))*1.0e-14
      HF_MELTH_F_mo_CArc(imo1:imo2) = dim_sum(dim_sum(HF_MELTH_F_CArc))*1.0e-12

      HF_hocn_ai_mo_Bering(imo1:imo2) = dim_sum(dim_sum(HF_hocn_ai_Bering))*1.0e-12 
      HF_swthru_ai_mo_Bering(imo1:imo2) = dim_sum(dim_sum(HF_swthru_ai_Bering))*1.0e-12
      HF_SHF_mo_Bering(imo1:imo2) = dim_sum(dim_sum(HF_SHF_Bering))*1.0e-14
      HF_MELTH_F_mo_Bering(imo1:imo2) = dim_sum(dim_sum(HF_MELTH_F_Bering))*1.0e-12

      HF_hocn_ai_mo_Okhotsk(imo1:imo2) = dim_sum(dim_sum(HF_hocn_ai_Okhotsk))*1.0e-12 
      HF_swthru_ai_mo_Okhotsk(imo1:imo2) = dim_sum(dim_sum(HF_swthru_ai_Okhotsk))*1.0e-12
      HF_SHF_mo_Okhotsk(imo1:imo2) = dim_sum(dim_sum(HF_SHF_Okhotsk))*1.0e-14
      HF_MELTH_F_mo_Okhotsk(imo1:imo2) = dim_sum(dim_sum(HF_MELTH_F_Okhotsk))*1.0e-12

      HF_hocn_ai_mo_Hudson(imo1:imo2) = dim_sum(dim_sum(HF_hocn_ai_Hudson))*1.0e-12 
      HF_swthru_ai_mo_Hudson(imo1:imo2) = dim_sum(dim_sum(HF_swthru_ai_Hudson))*1.0e-12
      HF_SHF_mo_Hudson(imo1:imo2) = dim_sum(dim_sum(HF_SHF_Hudson))*1.0e-14
      HF_MELTH_F_mo_Hudson(imo1:imo2) = dim_sum(dim_sum(HF_MELTH_F_Hudson))*1.0e-12

      HF_hocn_ai_mo_CAArch(imo1:imo2) = dim_sum(dim_sum(HF_hocn_ai_CAArch))*1.0e-12
      HF_swthru_ai_mo_CAArch(imo1:imo2) = dim_sum(dim_sum(HF_swthru_ai_CAArch))*1.0e-12
      HF_SHF_mo_CAArch(imo1:imo2) = dim_sum(dim_sum(HF_SHF_CAArch))*1.0e-14
      HF_MELTH_F_mo_CAArch(imo1:imo2) = dim_sum(dim_sum(HF_MELTH_F_CAArch))*1.0e-12
;********************************
; southern hemisphere monthly ...
;********************************
      HF_SHF_mo_sh50_90(imo1:imo2) = dim_sum(dim_sum(HF_SHF_sh50_90))*1.0e-14
      HF_MELTH_F_mo_sh50_90(imo1:imo2) = dim_sum(dim_sum(HF_MELTH_F_sh50_90))*1.0e-12

      HF_hocn_ai_mo_sh(imo1:imo2) = dim_sum(dim_sum(HF_hocn_ai_sh))*1.0e-12 
      HF_swthru_ai_mo_sh(imo1:imo2) = dim_sum(dim_sum(HF_swthru_ai_sh))*1.0e-12
      HF_SHF_mo_sh(imo1:imo2) = dim_sum(dim_sum(HF_SHF_sh))*1.0e-14
      HF_MELTH_F_mo_sh(imo1:imo2) = dim_sum(dim_sum(HF_MELTH_F_sh))*1.0e-12

      HF_hocn_ai_mo_Wed(imo1:imo2) = dim_sum(dim_sum(HF_hocn_ai_Wed))*1.0e-12 
      HF_swthru_ai_mo_Wed(imo1:imo2) = dim_sum(dim_sum(HF_swthru_ai_Wed))*1.0e-12
      HF_SHF_mo_Wed(imo1:imo2) = dim_sum(dim_sum(HF_SHF_Wed))*1.0e-14
      HF_MELTH_F_mo_Wed(imo1:imo2) = dim_sum(dim_sum(HF_MELTH_F_Wed))*1.0e-12

      HF_hocn_ai_mo_Ross(imo1:imo2) = dim_sum(dim_sum(HF_hocn_ai_Ross))*1.0e-12 
      HF_swthru_ai_mo_Ross(imo1:imo2) = dim_sum(dim_sum(HF_swthru_ai_Ross))*1.0e-12
      HF_SHF_mo_Ross(imo1:imo2) = dim_sum(dim_sum(HF_SHF_Ross))*1.0e-14
      HF_MELTH_F_mo_Ross(imo1:imo2) = dim_sum(dim_sum(HF_MELTH_F_Ross))*1.0e-12

      HF_hocn_ai_mo_Ind(imo1:imo2) = dim_sum(dim_sum(HF_hocn_ai_Ind))*1.0e-12 
      HF_swthru_ai_mo_Ind(imo1:imo2) = dim_sum(dim_sum(HF_swthru_ai_Ind))*1.0e-12
      HF_SHF_mo_Ind(imo1:imo2) = dim_sum(dim_sum(HF_SHF_Ind))*1.0e-14
      HF_MELTH_F_mo_Ind(imo1:imo2) = dim_sum(dim_sum(HF_MELTH_F_Ind))*1.0e-12

      HF_hocn_ai_mo_Pac(imo1:imo2) = dim_sum(dim_sum(HF_hocn_ai_Pac))*1.0e-12 
      HF_swthru_ai_mo_Pac(imo1:imo2) = dim_sum(dim_sum(HF_swthru_ai_Pac))*1.0e-12
      HF_SHF_mo_Pac(imo1:imo2) = dim_sum(dim_sum(HF_SHF_Pac))*1.0e-14
      HF_MELTH_F_mo_Pac(imo1:imo2) = dim_sum(dim_sum(HF_MELTH_F_Pac))*1.0e-12

      HF_hocn_ai_mo_BAm(imo1:imo2) = dim_sum(dim_sum(HF_hocn_ai_BAm))*1.0e-12 
      HF_swthru_ai_mo_BAm(imo1:imo2) = dim_sum(dim_sum(HF_swthru_ai_BAm))*1.0e-12
      HF_SHF_mo_BAm(imo1:imo2) = dim_sum(dim_sum(HF_SHF_BAm))*1.0e-14
      HF_MELTH_F_mo_BAm(imo1:imo2) = dim_sum(dim_sum(HF_MELTH_F_BAm))*1.0e-12
   end do ; nn

   HF_hocn_ai_mo_nh!0 = "time"
   HF_hocn_ai_mo_nh&time = time
   HF_hocn_ai_mo_nh@units = "1.E+12 W"
   HF_hocn_ai_mo_nh@coordinates = "time"
   HF_hocn_ai_mo_nh@missing_value = 1.e+30
   HF_hocn_ai_mo_nh@_FillValue = 1.e+30
   HF_hocn_ai_mo_nh@cell_methods = "time:mean"

   HF_SHF_mo_nh!0 = "time"
   HF_SHF_mo_nh&time = time
   HF_SHF_mo_nh@units = "1.E+14 W"
   HF_SHF_mo_nh@coordinates = "time"
   HF_SHF_mo_nh@missing_value = 1.e+30
   HF_SHF_mo_nh@_FillValue = 1.e+30
   HF_SHF_mo_nh@cell_methods = "time:mean"

   copy_VarMeta(HF_hocn_ai_mo_nh,HF_swthru_ai_mo_nh)
   copy_VarMeta(HF_hocn_ai_mo_nh,HF_MELTH_F_mo_nh)
   copy_VarMeta(HF_hocn_ai_mo_nh,HF_MELTH_F_mo_nh50_90)

   copy_VarMeta(HF_SHF_mo_nh,HF_SHF_mo_nh50_90)

   copy_VarMeta(HF_hocn_ai_mo_nh,HF_hocn_ai_mo_Lab)
   copy_VarMeta(HF_swthru_ai_mo_nh,HF_swthru_ai_mo_Lab)
   copy_VarMeta(HF_SHF_mo_nh,HF_SHF_mo_Lab)
   copy_VarMeta(HF_hocn_ai_mo_nh,HF_MELTH_F_mo_Lab)

   copy_VarMeta(HF_hocn_ai_mo_nh,HF_hocn_ai_mo_GIN)
   copy_VarMeta(HF_swthru_ai_mo_nh,HF_swthru_ai_mo_GIN)
   copy_VarMeta(HF_SHF_mo_nh,HF_SHF_mo_GIN)
   copy_VarMeta(HF_hocn_ai_mo_nh,HF_MELTH_F_mo_GIN)

   copy_VarMeta(HF_hocn_ai_mo_nh,HF_hocn_ai_mo_Bar)
   copy_VarMeta(HF_swthru_ai_mo_nh,HF_swthru_ai_mo_Bar)
   copy_VarMeta(HF_SHF_mo_nh,HF_SHF_mo_Bar)
   copy_VarMeta(HF_hocn_ai_mo_nh,HF_MELTH_F_mo_Bar)

   copy_VarMeta(HF_hocn_ai_mo_nh,HF_hocn_ai_mo_ArcOc)
   copy_VarMeta(HF_swthru_ai_mo_nh,HF_swthru_ai_mo_ArcOc)
   copy_VarMeta(HF_SHF_mo_nh,HF_SHF_mo_ArcOc)
   copy_VarMeta(HF_hocn_ai_mo_nh,HF_MELTH_F_mo_ArcOc)

   copy_VarMeta(HF_hocn_ai_mo_nh,HF_hocn_ai_mo_Kara)
   copy_VarMeta(HF_swthru_ai_mo_nh,HF_swthru_ai_mo_Kara)
   copy_VarMeta(HF_SHF_mo_nh,HF_SHF_mo_Kara)
   copy_VarMeta(HF_hocn_ai_mo_nh,HF_MELTH_F_mo_Kara)

   copy_VarMeta(HF_hocn_ai_mo_nh,HF_hocn_ai_mo_Laptev)
   copy_VarMeta(HF_swthru_ai_mo_nh,HF_swthru_ai_mo_Laptev)
   copy_VarMeta(HF_SHF_mo_nh,HF_SHF_mo_Laptev)
   copy_VarMeta(HF_hocn_ai_mo_nh,HF_MELTH_F_mo_Laptev)

   copy_VarMeta(HF_hocn_ai_mo_nh,HF_hocn_ai_mo_Chukchi)
   copy_VarMeta(HF_swthru_ai_mo_nh,HF_swthru_ai_mo_Chukchi)
   copy_VarMeta(HF_SHF_mo_nh,HF_SHF_mo_Chukchi)
   copy_VarMeta(HF_hocn_ai_mo_nh,HF_MELTH_F_mo_Chukchi)

   copy_VarMeta(HF_hocn_ai_mo_nh,HF_hocn_ai_mo_Sib)
   copy_VarMeta(HF_swthru_ai_mo_nh,HF_swthru_ai_mo_Sib)
   copy_VarMeta(HF_SHF_mo_nh,HF_SHF_mo_Sib)
   copy_VarMeta(HF_hocn_ai_mo_nh,HF_MELTH_F_mo_Sib)

   copy_VarMeta(HF_hocn_ai_mo_nh,HF_hocn_ai_mo_Beau)
   copy_VarMeta(HF_swthru_ai_mo_nh,HF_swthru_ai_mo_Beau)
   copy_VarMeta(HF_SHF_mo_nh,HF_SHF_mo_Beau)
   copy_VarMeta(HF_hocn_ai_mo_nh,HF_MELTH_F_mo_Beau)

   copy_VarMeta(HF_hocn_ai_mo_nh,HF_hocn_ai_mo_CArc)
   copy_VarMeta(HF_swthru_ai_mo_nh,HF_swthru_ai_mo_CArc)
   copy_VarMeta(HF_SHF_mo_nh,HF_SHF_mo_CArc)
   copy_VarMeta(HF_hocn_ai_mo_nh,HF_MELTH_F_mo_CArc)

   copy_VarMeta(HF_hocn_ai_mo_nh,HF_hocn_ai_mo_Bering)
   copy_VarMeta(HF_swthru_ai_mo_nh,HF_swthru_ai_mo_Bering)
   copy_VarMeta(HF_SHF_mo_nh,HF_SHF_mo_Bering)
   copy_VarMeta(HF_hocn_ai_mo_nh,HF_MELTH_F_mo_Bering)

   copy_VarMeta(HF_hocn_ai_mo_nh,HF_hocn_ai_mo_Okhotsk)
   copy_VarMeta(HF_swthru_ai_mo_nh,HF_swthru_ai_mo_Okhotsk)
   copy_VarMeta(HF_SHF_mo_nh,HF_SHF_mo_Okhotsk)
   copy_VarMeta(HF_hocn_ai_mo_nh,HF_MELTH_F_mo_Okhotsk)

   copy_VarMeta(HF_hocn_ai_mo_nh,HF_hocn_ai_mo_Hudson)
   copy_VarMeta(HF_swthru_ai_mo_nh,HF_swthru_ai_mo_Hudson)
   copy_VarMeta(HF_SHF_mo_nh,HF_SHF_mo_Hudson)
   copy_VarMeta(HF_hocn_ai_mo_nh,HF_MELTH_F_mo_Hudson)

   copy_VarMeta(HF_hocn_ai_mo_nh,HF_hocn_ai_mo_CAArch)
   copy_VarMeta(HF_swthru_ai_mo_nh,HF_swthru_ai_mo_CAArch)
   copy_VarMeta(HF_SHF_mo_nh,HF_SHF_mo_CAArch)
   copy_VarMeta(HF_hocn_ai_mo_nh,HF_MELTH_F_mo_CAArch)

   HF_hocn_ai_mo_sh!0 = "time"
   HF_hocn_ai_mo_sh&time = time
   HF_hocn_ai_mo_sh@units = "1.E+12 W"
   HF_hocn_ai_mo_sh@coordinates = "time"
   HF_hocn_ai_mo_sh@missing_value = 1.e+30
   HF_hocn_ai_mo_sh@_FillValue = 1.e+30
   HF_hocn_ai_mo_sh@cell_methods = "time:mean"

   HF_SHF_mo_sh!0 = "time"
   HF_SHF_mo_sh&time = time
   HF_SHF_mo_sh@units = "1.E+14 W"
   HF_SHF_mo_sh@coordinates = "time"
   HF_SHF_mo_sh@missing_value = 1.e+30
   HF_SHF_mo_sh@_FillValue = 1.e+30
   HF_SHF_mo_sh@cell_methods = "time:mean"

   copy_VarMeta(HF_hocn_ai_mo_sh,HF_swthru_ai_mo_sh)
   copy_VarMeta(HF_hocn_ai_mo_sh,HF_MELTH_F_mo_sh)
   copy_VarMeta(HF_SHF_mo_sh,HF_SHF_mo_sh50_90)
   copy_VarMeta(HF_hocn_ai_mo_sh,HF_MELTH_F_mo_sh50_90)

   copy_VarMeta(HF_hocn_ai_mo_sh,HF_hocn_ai_mo_Wed)
   copy_VarMeta(HF_swthru_ai_mo_sh,HF_swthru_ai_mo_Wed)
   copy_VarMeta(HF_SHF_mo_sh,HF_SHF_mo_Wed)
   copy_VarMeta(HF_hocn_ai_mo_sh,HF_MELTH_F_mo_Wed)

   copy_VarMeta(HF_hocn_ai_mo_sh,HF_hocn_ai_mo_Ross)
   copy_VarMeta(HF_swthru_ai_mo_sh,HF_swthru_ai_mo_Ross)
   copy_VarMeta(HF_SHF_mo_sh,HF_SHF_mo_Ross)
   copy_VarMeta(HF_hocn_ai_mo_sh,HF_MELTH_F_mo_Ross)

   copy_VarMeta(HF_hocn_ai_mo_sh,HF_hocn_ai_mo_Ind)
   copy_VarMeta(HF_swthru_ai_mo_sh,HF_swthru_ai_mo_Ind)
   copy_VarMeta(HF_SHF_mo_sh,HF_SHF_mo_Ind)
   copy_VarMeta(HF_hocn_ai_mo_sh,HF_MELTH_F_mo_Ind)

   copy_VarMeta(HF_hocn_ai_mo_sh,HF_hocn_ai_mo_Pac)
   copy_VarMeta(HF_swthru_ai_mo_sh,HF_swthru_ai_mo_Pac)
   copy_VarMeta(HF_SHF_mo_sh,HF_SHF_mo_Pac)
   copy_VarMeta(HF_hocn_ai_mo_sh,HF_MELTH_F_mo_Pac)

   copy_VarMeta(HF_hocn_ai_mo_sh,HF_hocn_ai_mo_BAm)
   copy_VarMeta(HF_swthru_ai_mo_sh,HF_swthru_ai_mo_BAm)
   copy_VarMeta(HF_SHF_mo_sh,HF_SHF_mo_BAm)
   copy_VarMeta(HF_hocn_ai_mo_sh,HF_MELTH_F_mo_BAm)

   fout = addfile(out_dir+"/ocn_SHF_MHolland_regions_"+case_names(ii)+"_"+styrs_proc+".nc","c")
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

   filevardef(fout,"HF_hocn_ai_mo_nh",typeof(HF_hocn_ai_mo_nh),getvardims(HF_hocn_ai_mo_nh))
   filevardef(fout,"HF_swthru_ai_mo_nh",typeof(HF_swthru_ai_mo_nh),getvardims(HF_swthru_ai_mo_nh))
   filevardef(fout,"HF_SHF_mo_nh",typeof(HF_SHF_mo_nh),getvardims(HF_SHF_mo_nh))
   filevardef(fout,"HF_MELTH_F_mo_nh",typeof(HF_MELTH_F_mo_nh),getvardims(HF_MELTH_F_mo_nh))
   filevardef(fout,"HF_SHF_mo_nh50_90",typeof(HF_SHF_mo_nh50_90),getvardims(HF_SHF_mo_nh50_90))
   filevardef(fout,"HF_MELTH_F_mo_nh50_90",typeof(HF_MELTH_F_mo_nh50_90),getvardims(HF_MELTH_F_mo_nh50_90))

   filevardef(fout,"HF_hocn_ai_mo_sh",typeof(HF_hocn_ai_mo_sh),getvardims(HF_hocn_ai_mo_sh))
   filevardef(fout,"HF_swthru_ai_mo_sh",typeof(HF_swthru_ai_mo_sh),getvardims(HF_swthru_ai_mo_sh))
   filevardef(fout,"HF_SHF_mo_sh",typeof(HF_SHF_mo_sh),getvardims(HF_SHF_mo_sh))
   filevardef(fout,"HF_MELTH_F_mo_sh",typeof(HF_MELTH_F_mo_sh),getvardims(HF_MELTH_F_mo_sh))
   filevardef(fout,"HF_SHF_mo_sh50_90",typeof(HF_SHF_mo_sh50_90),getvardims(HF_SHF_mo_sh50_90))
   filevardef(fout,"HF_MELTH_F_mo_sh50_90",typeof(HF_MELTH_F_mo_sh50_90),getvardims(HF_MELTH_F_mo_sh50_90))

   filevardef(fout,"HF_hocn_ai_mo_Lab",typeof(HF_hocn_ai_mo_Lab),getvardims(HF_hocn_ai_mo_Lab))
   filevardef(fout,"HF_swthru_ai_mo_Lab",typeof(HF_swthru_ai_mo_Lab),getvardims(HF_swthru_ai_mo_Lab))
   filevardef(fout,"HF_SHF_mo_Lab",typeof(HF_SHF_mo_Lab),getvardims(HF_SHF_mo_Lab))
   filevardef(fout,"HF_MELTH_F_mo_Lab",typeof(HF_MELTH_F_mo_Lab),getvardims(HF_MELTH_F_mo_Lab))

   filevardef(fout,"HF_hocn_ai_mo_GIN",typeof(HF_hocn_ai_mo_GIN),getvardims(HF_hocn_ai_mo_GIN))
   filevardef(fout,"HF_swthru_ai_mo_GIN",typeof(HF_swthru_ai_mo_GIN),getvardims(HF_swthru_ai_mo_GIN))
   filevardef(fout,"HF_SHF_mo_GIN",typeof(HF_SHF_mo_GIN),getvardims(HF_SHF_mo_GIN))
   filevardef(fout,"HF_MELTH_F_mo_GIN",typeof(HF_MELTH_F_mo_GIN),getvardims(HF_MELTH_F_mo_GIN))

   filevardef(fout,"HF_hocn_ai_mo_Bar",typeof(HF_hocn_ai_mo_Bar),getvardims(HF_hocn_ai_mo_Bar))
   filevardef(fout,"HF_swthru_ai_mo_Bar",typeof(HF_swthru_ai_mo_Bar),getvardims(HF_swthru_ai_mo_Bar))
   filevardef(fout,"HF_SHF_mo_Bar",typeof(HF_SHF_mo_Bar),getvardims(HF_SHF_mo_Bar))
   filevardef(fout,"HF_MELTH_F_mo_Bar",typeof(HF_MELTH_F_mo_Bar),getvardims(HF_MELTH_F_mo_Bar))

   filevardef(fout,"HF_hocn_ai_mo_ArcOc",typeof(HF_hocn_ai_mo_ArcOc),getvardims(HF_hocn_ai_mo_ArcOc))
   filevardef(fout,"HF_swthru_ai_mo_ArcOc",typeof(HF_swthru_ai_mo_ArcOc),getvardims(HF_swthru_ai_mo_ArcOc))
   filevardef(fout,"HF_SHF_mo_ArcOc",typeof(HF_SHF_mo_ArcOc),getvardims(HF_SHF_mo_ArcOc))
   filevardef(fout,"HF_MELTH_F_mo_ArcOc",typeof(HF_MELTH_F_mo_ArcOc),getvardims(HF_MELTH_F_mo_ArcOc))

   filevardef(fout,"HF_hocn_ai_mo_Kara",typeof(HF_hocn_ai_mo_Kara),getvardims(HF_hocn_ai_mo_Kara))
   filevardef(fout,"HF_swthru_ai_mo_Kara",typeof(HF_swthru_ai_mo_Kara),getvardims(HF_swthru_ai_mo_Kara))
   filevardef(fout,"HF_SHF_mo_Kara",typeof(HF_SHF_mo_Kara),getvardims(HF_SHF_mo_Kara))
   filevardef(fout,"HF_MELTH_F_mo_Kara",typeof(HF_MELTH_F_mo_Kara),getvardims(HF_MELTH_F_mo_Kara))

   filevardef(fout,"HF_hocn_ai_mo_Laptev",typeof(HF_hocn_ai_mo_Laptev),getvardims(HF_hocn_ai_mo_Laptev))
   filevardef(fout,"HF_swthru_ai_mo_Laptev",typeof(HF_swthru_ai_mo_Laptev),getvardims(HF_swthru_ai_mo_Laptev))
   filevardef(fout,"HF_SHF_mo_Laptev",typeof(HF_SHF_mo_Laptev),getvardims(HF_SHF_mo_Laptev))
   filevardef(fout,"HF_MELTH_F_mo_Laptev",typeof(HF_MELTH_F_mo_Laptev),getvardims(HF_MELTH_F_mo_Laptev))

   filevardef(fout,"HF_hocn_ai_mo_Chukchi",typeof(HF_hocn_ai_mo_Chukchi),getvardims(HF_hocn_ai_mo_Chukchi))
   filevardef(fout,"HF_swthru_ai_mo_Chukchi",typeof(HF_swthru_ai_mo_Chukchi),getvardims(HF_swthru_ai_mo_Chukchi))
   filevardef(fout,"HF_SHF_mo_Chukchi",typeof(HF_SHF_mo_Chukchi),getvardims(HF_SHF_mo_Chukchi))
   filevardef(fout,"HF_MELTH_F_mo_Chukchi",typeof(HF_MELTH_F_mo_Chukchi),getvardims(HF_MELTH_F_mo_Chukchi))

   filevardef(fout,"HF_hocn_ai_mo_Sib",typeof(HF_hocn_ai_mo_Sib),getvardims(HF_hocn_ai_mo_Sib))
   filevardef(fout,"HF_swthru_ai_mo_Sib",typeof(HF_swthru_ai_mo_Sib),getvardims(HF_swthru_ai_mo_Sib))
   filevardef(fout,"HF_SHF_mo_Sib",typeof(HF_SHF_mo_Sib),getvardims(HF_SHF_mo_Sib))
   filevardef(fout,"HF_MELTH_F_mo_Sib",typeof(HF_MELTH_F_mo_Sib),getvardims(HF_MELTH_F_mo_Sib))

   filevardef(fout,"HF_hocn_ai_mo_Beau",typeof(HF_hocn_ai_mo_Beau),getvardims(HF_hocn_ai_mo_Beau))
   filevardef(fout,"HF_swthru_ai_mo_Beau",typeof(HF_swthru_ai_mo_Beau),getvardims(HF_swthru_ai_mo_Beau))
   filevardef(fout,"HF_SHF_mo_Beau",typeof(HF_SHF_mo_Beau),getvardims(HF_SHF_mo_Beau))
   filevardef(fout,"HF_MELTH_F_mo_Beau",typeof(HF_MELTH_F_mo_Beau),getvardims(HF_MELTH_F_mo_Beau))

   filevardef(fout,"HF_hocn_ai_mo_CArc",typeof(HF_hocn_ai_mo_CArc),getvardims(HF_hocn_ai_mo_CArc))
   filevardef(fout,"HF_swthru_ai_mo_CArc",typeof(HF_swthru_ai_mo_CArc),getvardims(HF_swthru_ai_mo_CArc))
   filevardef(fout,"HF_SHF_mo_CArc",typeof(HF_SHF_mo_CArc),getvardims(HF_SHF_mo_CArc))
   filevardef(fout,"HF_MELTH_F_mo_CArc",typeof(HF_MELTH_F_mo_CArc),getvardims(HF_MELTH_F_mo_CArc))

   filevardef(fout,"HF_hocn_ai_mo_Bering",typeof(HF_hocn_ai_mo_Bering),getvardims(HF_hocn_ai_mo_Bering))
   filevardef(fout,"HF_swthru_ai_mo_Bering",typeof(HF_swthru_ai_mo_Bering),getvardims(HF_swthru_ai_mo_Bering))
   filevardef(fout,"HF_SHF_mo_Bering",typeof(HF_SHF_mo_Bering),getvardims(HF_SHF_mo_Bering))
   filevardef(fout,"HF_MELTH_F_mo_Bering",typeof(HF_MELTH_F_mo_Bering),getvardims(HF_MELTH_F_mo_Bering))

   filevardef(fout,"HF_hocn_ai_mo_Okhotsk",typeof(HF_hocn_ai_mo_Okhotsk),getvardims(HF_hocn_ai_mo_Okhotsk))
   filevardef(fout,"HF_swthru_ai_mo_Okhotsk",typeof(HF_swthru_ai_mo_Okhotsk),getvardims(HF_swthru_ai_mo_Okhotsk))
   filevardef(fout,"HF_SHF_mo_Okhotsk",typeof(HF_SHF_mo_Okhotsk),getvardims(HF_SHF_mo_Okhotsk))
   filevardef(fout,"HF_MELTH_F_mo_Okhotsk",typeof(HF_MELTH_F_mo_Okhotsk),getvardims(HF_MELTH_F_mo_Okhotsk))

   filevardef(fout,"HF_hocn_ai_mo_Hudson",typeof(HF_hocn_ai_mo_Hudson),getvardims(HF_hocn_ai_mo_Hudson))
   filevardef(fout,"HF_swthru_ai_mo_Hudson",typeof(HF_swthru_ai_mo_Hudson),getvardims(HF_swthru_ai_mo_Hudson))
   filevardef(fout,"HF_SHF_mo_Hudson",typeof(HF_SHF_mo_Hudson),getvardims(HF_SHF_mo_Hudson))
   filevardef(fout,"HF_MELTH_F_mo_Hudson",typeof(HF_MELTH_F_mo_Hudson),getvardims(HF_MELTH_F_mo_Hudson))

   filevardef(fout,"HF_hocn_ai_mo_CAArch",typeof(HF_hocn_ai_mo_CAArch),getvardims(HF_hocn_ai_mo_CAArch))
   filevardef(fout,"HF_swthru_ai_mo_CAArch",typeof(HF_swthru_ai_mo_CAArch),getvardims(HF_swthru_ai_mo_CAArch))
   filevardef(fout,"HF_SHF_mo_CAArch",typeof(HF_SHF_mo_CAArch),getvardims(HF_SHF_mo_CAArch))
   filevardef(fout,"HF_MELTH_F_mo_CAArch",typeof(HF_MELTH_F_mo_CAArch),getvardims(HF_MELTH_F_mo_CAArch))

   filevardef(fout,"HF_hocn_ai_mo_Wed",typeof(HF_hocn_ai_mo_Wed),getvardims(HF_hocn_ai_mo_Wed))
   filevardef(fout,"HF_swthru_ai_mo_Wed",typeof(HF_swthru_ai_mo_Wed),getvardims(HF_swthru_ai_mo_Wed))
   filevardef(fout,"HF_SHF_mo_Wed",typeof(HF_SHF_mo_Wed),getvardims(HF_SHF_mo_Wed))
   filevardef(fout,"HF_MELTH_F_mo_Wed",typeof(HF_MELTH_F_mo_Wed),getvardims(HF_MELTH_F_mo_Wed))

   filevardef(fout,"HF_hocn_ai_mo_Ross",typeof(HF_hocn_ai_mo_Ross),getvardims(HF_hocn_ai_mo_Ross))
   filevardef(fout,"HF_swthru_ai_mo_Ross",typeof(HF_swthru_ai_mo_Ross),getvardims(HF_swthru_ai_mo_Ross))
   filevardef(fout,"HF_SHF_mo_Ross",typeof(HF_SHF_mo_Ross),getvardims(HF_SHF_mo_Ross))
   filevardef(fout,"HF_MELTH_F_mo_Ross",typeof(HF_MELTH_F_mo_Ross),getvardims(HF_MELTH_F_mo_Ross))

   filevardef(fout,"HF_hocn_ai_mo_Ind",typeof(HF_hocn_ai_mo_Ind),getvardims(HF_hocn_ai_mo_Ind))
   filevardef(fout,"HF_swthru_ai_mo_Ind",typeof(HF_swthru_ai_mo_Ind),getvardims(HF_swthru_ai_mo_Ind))
   filevardef(fout,"HF_SHF_mo_Ind",typeof(HF_SHF_mo_Ind),getvardims(HF_SHF_mo_Ind))
   filevardef(fout,"HF_MELTH_F_mo_Ind",typeof(HF_MELTH_F_mo_Ind),getvardims(HF_MELTH_F_mo_Ind))

   filevardef(fout,"HF_hocn_ai_mo_Pac",typeof(HF_hocn_ai_mo_Pac),getvardims(HF_hocn_ai_mo_Pac))
   filevardef(fout,"HF_swthru_ai_mo_Pac",typeof(HF_swthru_ai_mo_Pac),getvardims(HF_swthru_ai_mo_Pac))
   filevardef(fout,"HF_SHF_mo_Pac",typeof(HF_SHF_mo_Pac),getvardims(HF_SHF_mo_Pac))
   filevardef(fout,"HF_MELTH_F_mo_Pac",typeof(HF_MELTH_F_mo_Pac),getvardims(HF_MELTH_F_mo_Pac))

   filevardef(fout,"HF_hocn_ai_mo_BAm",typeof(HF_hocn_ai_mo_BAm),getvardims(HF_hocn_ai_mo_BAm))
   filevardef(fout,"HF_swthru_ai_mo_BAm",typeof(HF_swthru_ai_mo_BAm),getvardims(HF_swthru_ai_mo_BAm))
   filevardef(fout,"HF_SHF_mo_BAm",typeof(HF_SHF_mo_BAm),getvardims(HF_SHF_mo_BAm))
   filevardef(fout,"HF_MELTH_F_mo_BAm",typeof(HF_MELTH_F_mo_BAm),getvardims(HF_MELTH_F_mo_BAm))

   filevarattdef(fout,"HF_hocn_ai_mo_nh",HF_hocn_ai_mo_nh)
   filevarattdef(fout,"HF_swthru_ai_mo_nh",HF_swthru_ai_mo_nh)
   filevarattdef(fout,"HF_SHF_mo_nh",HF_SHF_mo_nh)
   filevarattdef(fout,"HF_MELTH_F_mo_nh",HF_MELTH_F_mo_nh)
   filevarattdef(fout,"HF_SHF_mo_nh50_90",HF_SHF_mo_nh50_90)
   filevarattdef(fout,"HF_MELTH_F_mo_nh50_90",HF_MELTH_F_mo_nh50_90)

   filevarattdef(fout,"HF_hocn_ai_mo_sh",HF_hocn_ai_mo_sh)
   filevarattdef(fout,"HF_swthru_ai_mo_sh",HF_swthru_ai_mo_sh)
   filevarattdef(fout,"HF_SHF_mo_sh",HF_SHF_mo_sh)
   filevarattdef(fout,"HF_MELTH_F_mo_sh",HF_MELTH_F_mo_sh)
   filevarattdef(fout,"HF_SHF_mo_sh50_90",HF_SHF_mo_sh50_90)
   filevarattdef(fout,"HF_MELTH_F_mo_sh50_90",HF_MELTH_F_mo_sh50_90)

   filevarattdef(fout,"HF_hocn_ai_mo_Lab",HF_hocn_ai_mo_Lab)
   filevarattdef(fout,"HF_swthru_ai_mo_Lab",HF_hocn_ai_mo_Lab)
   filevarattdef(fout,"HF_SHF_mo_Lab",HF_SHF_mo_Lab)
   filevarattdef(fout,"HF_MELTH_F_mo_Lab",HF_MELTH_F_mo_Lab)

   filevarattdef(fout,"HF_hocn_ai_mo_GIN",HF_hocn_ai_mo_GIN)
   filevarattdef(fout,"HF_swthru_ai_mo_GIN",HF_swthru_ai_mo_GIN)
   filevarattdef(fout,"HF_SHF_mo_GIN",HF_SHF_mo_GIN)
   filevarattdef(fout,"HF_MELTH_F_mo_GIN",HF_MELTH_F_mo_GIN)

   filevarattdef(fout,"HF_hocn_ai_mo_Bar",HF_hocn_ai_mo_Bar)
   filevarattdef(fout,"HF_swthru_ai_mo_Bar",HF_swthru_ai_mo_Bar)
   filevarattdef(fout,"HF_SHF_mo_Bar",HF_SHF_mo_Bar)
   filevarattdef(fout,"HF_MELTH_F_mo_Bar",HF_MELTH_F_mo_Bar)

   filevarattdef(fout,"HF_hocn_ai_mo_ArcOc",HF_hocn_ai_mo_ArcOc)
   filevarattdef(fout,"HF_swthru_ai_mo_ArcOc",HF_swthru_ai_mo_ArcOc)
   filevarattdef(fout,"HF_SHF_mo_ArcOc",HF_SHF_mo_ArcOc)
   filevarattdef(fout,"HF_MELTH_F_mo_ArcOc",HF_MELTH_F_mo_ArcOc)

   filevarattdef(fout,"HF_hocn_ai_mo_Kara",HF_hocn_ai_mo_Kara)
   filevarattdef(fout,"HF_swthru_ai_mo_Kara",HF_swthru_ai_mo_Kara)
   filevarattdef(fout,"HF_SHF_mo_Kara",HF_SHF_mo_Kara)
   filevarattdef(fout,"HF_MELTH_F_mo_Kara",HF_MELTH_F_mo_Kara)

   filevarattdef(fout,"HF_hocn_ai_mo_Laptev",HF_hocn_ai_mo_Laptev)
   filevarattdef(fout,"HF_swthru_ai_mo_Laptev",HF_swthru_ai_mo_Laptev)
   filevarattdef(fout,"HF_SHF_mo_Laptev",HF_SHF_mo_Laptev)
   filevarattdef(fout,"HF_MELTH_F_mo_Laptev",HF_MELTH_F_mo_Laptev)

   filevarattdef(fout,"HF_hocn_ai_mo_Chukchi",HF_hocn_ai_mo_Chukchi)
   filevarattdef(fout,"HF_swthru_ai_mo_Chukchi",HF_swthru_ai_mo_Chukchi)
   filevarattdef(fout,"HF_SHF_mo_Chukchi",HF_SHF_mo_Chukchi)
   filevarattdef(fout,"HF_MELTH_F_mo_Chukchi",HF_MELTH_F_mo_Chukchi)

   filevarattdef(fout,"HF_hocn_ai_mo_Sib",HF_hocn_ai_mo_Sib)
   filevarattdef(fout,"HF_swthru_ai_mo_Sib",HF_swthru_ai_mo_Sib)
   filevarattdef(fout,"HF_SHF_mo_Sib",HF_SHF_mo_Sib)
   filevarattdef(fout,"HF_MELTH_F_mo_Sib",HF_MELTH_F_mo_Sib)

   filevarattdef(fout,"HF_hocn_ai_mo_Beau",HF_hocn_ai_mo_Beau)
   filevarattdef(fout,"HF_swthru_ai_mo_Beau",HF_swthru_ai_mo_Beau)
   filevarattdef(fout,"HF_SHF_mo_Beau",HF_SHF_mo_Beau)
   filevarattdef(fout,"HF_MELTH_F_mo_Beau",HF_MELTH_F_mo_Beau)

   filevarattdef(fout,"HF_hocn_ai_mo_CArc",HF_hocn_ai_mo_CArc)
   filevarattdef(fout,"HF_swthru_ai_mo_CArc",HF_swthru_ai_mo_CArc)
   filevarattdef(fout,"HF_SHF_mo_CArc",HF_SHF_mo_CArc)
   filevarattdef(fout,"HF_MELTH_F_mo_CArc",HF_MELTH_F_mo_CArc)

   filevarattdef(fout,"HF_hocn_ai_mo_Bering",HF_hocn_ai_mo_Bering)
   filevarattdef(fout,"HF_swthru_ai_mo_Bering",HF_swthru_ai_mo_Bering)
   filevarattdef(fout,"HF_SHF_mo_Bering",HF_SHF_mo_Bering)
   filevarattdef(fout,"HF_MELTH_F_mo_Bering",HF_MELTH_F_mo_Bering)

   filevarattdef(fout,"HF_hocn_ai_mo_Okhotsk",HF_hocn_ai_mo_Okhotsk)
   filevarattdef(fout,"HF_swthru_ai_mo_Okhotsk",HF_swthru_ai_mo_Okhotsk)
   filevarattdef(fout,"HF_SHF_mo_Okhotsk",HF_SHF_mo_Okhotsk)
   filevarattdef(fout,"HF_MELTH_F_mo_Okhotsk",HF_MELTH_F_mo_Okhotsk)

   filevarattdef(fout,"HF_hocn_ai_mo_Hudson",HF_hocn_ai_mo_Hudson)
   filevarattdef(fout,"HF_swthru_ai_mo_Hudson",HF_hocn_ai_mo_Hudson)
   filevarattdef(fout,"HF_SHF_mo_Hudson",HF_SHF_mo_Hudson)
   filevarattdef(fout,"HF_MELTH_F_mo_Hudson",HF_MELTH_F_mo_Hudson)

   filevarattdef(fout,"HF_hocn_ai_mo_CAArch",HF_hocn_ai_mo_CAArch)
   filevarattdef(fout,"HF_swthru_ai_mo_CAArch",HF_swthru_ai_mo_CAArch)
   filevarattdef(fout,"HF_SHF_mo_CAArch",HF_SHF_mo_CAArch)
   filevarattdef(fout,"HF_MELTH_F_mo_CAArch",HF_MELTH_F_mo_CAArch)

   filevarattdef(fout,"HF_hocn_ai_mo_Wed",HF_hocn_ai_mo_Wed)
   filevarattdef(fout,"HF_swthru_ai_mo_Wed",HF_swthru_ai_mo_Wed)
   filevarattdef(fout,"HF_SHF_mo_Wed",HF_SHF_mo_Wed)
   filevarattdef(fout,"HF_MELTH_F_mo_Wed",HF_MELTH_F_mo_Wed)

   filevarattdef(fout,"HF_hocn_ai_mo_Ross",HF_hocn_ai_mo_Ross)
   filevarattdef(fout,"HF_swthru_ai_mo_Ross",HF_swthru_ai_mo_Ross)
   filevarattdef(fout,"HF_SHF_mo_Ross",HF_SHF_mo_Ross)
   filevarattdef(fout,"HF_MELTH_F_mo_Ross",HF_MELTH_F_mo_Ross)

   filevarattdef(fout,"HF_hocn_ai_mo_Ind",HF_hocn_ai_mo_Ind)
   filevarattdef(fout,"HF_swthru_ai_mo_Ind",HF_swthru_ai_mo_Ind)
   filevarattdef(fout,"HF_SHF_mo_Ind",HF_SHF_mo_Ind)
   filevarattdef(fout,"HF_MELTH_F_mo_Ind",HF_MELTH_F_mo_Ind)

   filevarattdef(fout,"HF_hocn_ai_mo_Pac",HF_hocn_ai_mo_Pac)
   filevarattdef(fout,"HF_swthru_ai_mo_Pac",HF_swthru_ai_mo_Pac)
   filevarattdef(fout,"HF_SHF_mo_Pac",HF_SHF_mo_Pac)
   filevarattdef(fout,"HF_MELTH_F_mo_Pac",HF_MELTH_F_mo_Pac)

   filevarattdef(fout,"HF_hocn_ai_mo_BAm",HF_hocn_ai_mo_BAm)
   filevarattdef(fout,"HF_swthru_ai_mo_BAm",HF_swthru_ai_mo_BAm)
   filevarattdef(fout,"HF_SHF_mo_BAm",HF_SHF_mo_BAm)
   filevarattdef(fout,"HF_MELTH_F_mo_BAm",HF_MELTH_F_mo_BAm)

   fout->time = time
   fout->HF_hocn_ai_mo_nh = HF_hocn_ai_mo_nh
   fout->HF_swthru_ai_mo_nh = HF_swthru_ai_mo_nh
   fout->HF_SHF_mo_nh = HF_SHF_mo_nh
   fout->HF_MELTH_F_mo_nh = HF_MELTH_F_mo_nh
   fout->HF_SHF_mo_nh50_90 = HF_SHF_mo_nh50_90
   fout->HF_MELTH_F_mo_nh50_90 = HF_MELTH_F_mo_nh50_90

   fout->HF_hocn_ai_mo_sh = HF_hocn_ai_mo_sh
   fout->HF_swthru_ai_mo_sh = HF_swthru_ai_mo_sh
   fout->HF_SHF_mo_sh = HF_SHF_mo_sh
   fout->HF_MELTH_F_mo_sh = HF_MELTH_F_mo_sh
   fout->HF_SHF_mo_sh50_90 = HF_SHF_mo_sh50_90
   fout->HF_MELTH_F_mo_sh50_90 = HF_MELTH_F_mo_sh50_90

   fout->HF_hocn_ai_mo_Lab = HF_hocn_ai_mo_Lab
   fout->HF_swthru_ai_mo_Lab = HF_swthru_ai_mo_Lab
   fout->HF_SHF_mo_Lab = HF_SHF_mo_Lab
   fout->HF_MELTH_F_mo_Lab = HF_MELTH_F_mo_Lab

   fout->HF_hocn_ai_mo_GIN = HF_hocn_ai_mo_GIN
   fout->HF_swthru_ai_mo_GIN = HF_swthru_ai_mo_GIN
   fout->HF_SHF_mo_GIN = HF_SHF_mo_GIN
   fout->HF_MELTH_F_mo_GIN = HF_MELTH_F_mo_GIN

   fout->HF_hocn_ai_mo_Bar = HF_hocn_ai_mo_Bar
   fout->HF_swthru_ai_mo_Bar = HF_swthru_ai_mo_Bar
   fout->HF_SHF_mo_Bar = HF_SHF_mo_Bar
   fout->HF_MELTH_F_mo_Bar = HF_MELTH_F_mo_Bar

   fout->HF_hocn_ai_mo_ArcOc = HF_hocn_ai_mo_ArcOc
   fout->HF_swthru_ai_mo_ArcOc = HF_swthru_ai_mo_ArcOc
   fout->HF_SHF_mo_ArcOc = HF_SHF_mo_ArcOc
   fout->HF_MELTH_F_mo_ArcOc = HF_MELTH_F_mo_ArcOc

   fout->HF_hocn_ai_mo_Kara = HF_hocn_ai_mo_Kara
   fout->HF_swthru_ai_mo_Kara = HF_swthru_ai_mo_Kara
   fout->HF_SHF_mo_Kara = HF_SHF_mo_Kara
   fout->HF_MELTH_F_mo_Kara = HF_MELTH_F_mo_Kara

   fout->HF_hocn_ai_mo_Laptev = HF_hocn_ai_mo_Laptev
   fout->HF_swthru_ai_mo_Laptev = HF_swthru_ai_mo_Laptev
   fout->HF_SHF_mo_Laptev = HF_SHF_mo_Laptev
   fout->HF_MELTH_F_mo_Laptev = HF_MELTH_F_mo_Laptev

   fout->HF_hocn_ai_mo_Chukchi = HF_hocn_ai_mo_Chukchi
   fout->HF_swthru_ai_mo_Chukchi = HF_swthru_ai_mo_Chukchi
   fout->HF_SHF_mo_Chukchi = HF_SHF_mo_Chukchi
   fout->HF_MELTH_F_mo_Chukchi = HF_MELTH_F_mo_Chukchi

   fout->HF_hocn_ai_mo_Sib = HF_hocn_ai_mo_Sib
   fout->HF_swthru_ai_mo_Sib = HF_swthru_ai_mo_Sib
   fout->HF_SHF_mo_Sib = HF_SHF_mo_Sib
   fout->HF_MELTH_F_mo_Sib = HF_MELTH_F_mo_Sib

   fout->HF_hocn_ai_mo_Beau = HF_hocn_ai_mo_Beau
   fout->HF_swthru_ai_mo_Beau = HF_swthru_ai_mo_Beau
   fout->HF_SHF_mo_Beau = HF_SHF_mo_Beau
   fout->HF_MELTH_F_mo_Beau = HF_MELTH_F_mo_Beau

   fout->HF_hocn_ai_mo_CArc = HF_hocn_ai_mo_CArc
   fout->HF_swthru_ai_mo_CArc = HF_swthru_ai_mo_CArc
   fout->HF_SHF_mo_CArc = HF_SHF_mo_CArc
   fout->HF_MELTH_F_mo_CArc = HF_MELTH_F_mo_CArc

   fout->HF_hocn_ai_mo_Bering = HF_hocn_ai_mo_Bering
   fout->HF_swthru_ai_mo_Bering = HF_swthru_ai_mo_Bering
   fout->HF_SHF_mo_Bering = HF_SHF_mo_Bering
   fout->HF_MELTH_F_mo_Bering = HF_MELTH_F_mo_Bering

   fout->HF_hocn_ai_mo_Okhotsk = HF_hocn_ai_mo_Okhotsk
   fout->HF_swthru_ai_mo_Okhotsk = HF_swthru_ai_mo_Okhotsk
   fout->HF_SHF_mo_Okhotsk = HF_SHF_mo_Okhotsk
   fout->HF_MELTH_F_mo_Okhotsk = HF_MELTH_F_mo_Okhotsk

   fout->HF_hocn_ai_mo_Hudson = HF_hocn_ai_mo_Hudson
   fout->HF_swthru_ai_mo_Hudson = HF_swthru_ai_mo_Hudson
   fout->HF_SHF_mo_Hudson = HF_SHF_mo_Hudson
   fout->HF_MELTH_F_mo_Hudson = HF_MELTH_F_mo_Hudson

   fout->HF_hocn_ai_mo_CAArch = HF_hocn_ai_mo_CAArch
   fout->HF_swthru_ai_mo_CAArch = HF_swthru_ai_mo_CAArch
   fout->HF_SHF_mo_CAArch = HF_SHF_mo_CAArch
   fout->HF_MELTH_F_mo_CAArch = HF_MELTH_F_mo_CAArch

   fout->HF_hocn_ai_mo_Wed = HF_hocn_ai_mo_Wed
   fout->HF_swthru_ai_mo_Wed = HF_swthru_ai_mo_Wed
   fout->HF_SHF_mo_Wed = HF_SHF_mo_Wed
   fout->HF_MELTH_F_mo_Wed = HF_MELTH_F_mo_Wed

   fout->HF_hocn_ai_mo_Ross = HF_hocn_ai_mo_Ross
   fout->HF_swthru_ai_mo_Ross = HF_swthru_ai_mo_Ross
   fout->HF_SHF_mo_Ross = HF_SHF_mo_Ross
   fout->HF_MELTH_F_mo_Ross = HF_MELTH_F_mo_Ross

   fout->HF_hocn_ai_mo_Ind = HF_hocn_ai_mo_Ind
   fout->HF_swthru_ai_mo_Ind = HF_swthru_ai_mo_Ind
   fout->HF_SHF_mo_Ind = HF_SHF_mo_Ind
   fout->HF_MELTH_F_mo_Ind = HF_MELTH_F_mo_Ind

   fout->HF_hocn_ai_mo_Pac = HF_hocn_ai_mo_Pac
   fout->HF_swthru_ai_mo_Pac = HF_swthru_ai_mo_Pac
   fout->HF_SHF_mo_Pac = HF_SHF_mo_Pac
   fout->HF_MELTH_F_mo_Pac = HF_MELTH_F_mo_Pac

   fout->HF_hocn_ai_mo_BAm = HF_hocn_ai_mo_BAm
   fout->HF_swthru_ai_mo_BAm = HF_swthru_ai_mo_BAm
   fout->HF_SHF_mo_BAm = HF_SHF_mo_BAm
   fout->HF_MELTH_F_mo_BAm = HF_MELTH_F_mo_BAm

end do 						; end do ii
end
