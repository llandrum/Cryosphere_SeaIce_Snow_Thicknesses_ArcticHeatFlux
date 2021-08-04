;; Plots ensemble mean area-averaged fcondtop_ai related variable timeseries 
; for user defined month and regions for CESM_LE. Variability is shown by polygons
; of min/max areas from entire ensemble. 
;
; LLandrum
; October 2020
;===============================================;
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"   
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"   
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/shea_util.ncl"
;load "/glade/u/home/landrum/ncl/asphilli_util.ncl"
; ================================================;
begin
  avg_vhi = True                                ; True to plot ai, vhi as area average variables (%, m), 
						; false to plot as area totals (m^2, m^3)
                                                ; fcondtop and Tsfc are saved as regional averages
  aice_wgt = True				; True to plot aice-weighted values (_ai), False to plot over ice area only 
						; (no _ai and hs, hi converted from grid-cell average to ice area only)

  LE_20thC_case = "b.e11.B20TRC5CNBDRD.f09_g16."
  LE_rcp_case = "b.e11.BRCP85C5CNBDRD.f09_g16."
  case_numbers = ispan(1,40,1)
  case_numbers(35:) = ispan(101,105,1)
  scnumbers = sprinti("%0.3i",case_numbers)

  ncase = dimsizes(case_numbers)

  yr1_20th = 1920
  yr2_20th = 2005
  yr1_rcp = 2006
  yr2_rcp = 2100

  datadir = "/glade/p/cesm/pcwg/landrum/LE/"
  f20thTsfc = datadir+"shf/ice/Tsfc/ice_Tsfc_MHolland_regions_"+LE_20thC_case+scnumbers+"_"+yr1_20th+"-"+yr2_20th+".nc"
  f20thaice = datadir+"ice/pre_process/monthly/ice_vol_MHolland_regions_"+LE_20thC_case+scnumbers+"_"+yr1_20th+"-"+yr2_20th+".nc"
  f20thfhocn = datadir+"shf/ice/fhocn/ice_fhocn_ai_MHolland_regions_"+LE_20thC_case+scnumbers+"_"+yr1_20th+"-"+yr2_20th+".nc"

  fTsfc = datadir+"shf/ice/Tsfc/ice_Tsfc_MHolland_regions_"+LE_rcp_case+scnumbers+"_"+yr1_rcp+"-"+yr2_rcp+".nc"
  faice = datadir+"ice/pre_process/monthly/ice_vol_MHolland_regions_"+LE_rcp_case+scnumbers+"_"+yr1_rcp+"-"+yr2_rcp+".nc"
  ffhocn = datadir+"shf/ice/fhocn/ice_fhocn_ai_MHolland_regions_"+LE_rcp_case+scnumbers+"_"+yr1_rcp+"-"+yr2_rcp+".nc"

  f20th = datadir+"shf/ice/fcondtop/ice_fcondtop_ai_MHolland_regions_"+LE_20thC_case+scnumbers+"_"+yr1_20th+"-"+yr2_20th+".nc"
  f20th_mean = datadir+"ice/fcondtop_ai/calcs/pre_process/fcondtop_mean_ai/ice_fcondtop_mean_ai_MHolland_regions_"+LE_20thC_case+scnumbers+"_"+yr1_20th+"-"+yr2_20th+".nc"
  f20th_nthick = datadir+"ice/fcondtop_ai/calcs/pre_process/fcondtop_nthick_ai/ice_fcondtop_nthick_ai_MHolland_regions_"+LE_20thC_case+scnumbers+"_"+yr1_20th+"-"+yr2_20th+".nc"
  f20th_daily2monthly = datadir+"ice/fcondtop_ai/calcs/pre_process/fcondtop_daily2monthly_ai/ice_fcondtop_daily2monthly_ai_MHolland_regions_"+LE_20thC_case+scnumbers+"_"+yr1_20th+"-"+yr2_20th+".nc"

  frcp = datadir+"shf/ice/fcondtop/ice_fcondtop_ai_MHolland_regions_"+LE_rcp_case+scnumbers+"_"+yr1_rcp+"-"+yr2_rcp+".nc"
  frcp_mean = datadir+"ice/fcondtop_ai/calcs/pre_process/fcondtop_mean_ai/ice_fcondtop_mean_ai_MHolland_regions_"+LE_rcp_case+scnumbers+"_"+yr1_rcp+"-"+yr2_rcp+".nc"
  frcp_nthick = datadir+"ice/fcondtop_ai/calcs/pre_process/fcondtop_nthick_ai/ice_fcondtop_nthick_ai_MHolland_regions_"+LE_rcp_case+scnumbers+"_"+yr1_rcp+"-"+yr2_rcp+".nc"
  frcp_daily2monthly = datadir+"ice/fcondtop_ai/calcs/pre_process/fcondtop_daily2monthly_ai/ice_fcondtop_daily2monthly_ai_MHolland_regions_"+LE_rcp_case+scnumbers+"_"+yr1_rcp+"-"+yr2_rcp+".nc"

  farea = "/glade/p/cesm/pcwg/landrum/CMIP5/MMLE/ice/cesm/CESM1-CAM5_regional_areavg.nc"

  plot_month = 2				; 1-12 month to plot
  imonth = plot_month - 1
  plot_yr1 = 1950
;  plot_yr2 = 2100
  plot_yr2 = 2070
  nyr = plot_yr2 - plot_yr1 + 1
  year = ispan(plot_yr1,plot_yr2,1)


  region = "ArcOc"
  region_name = "Arctic Ocean"			; plain English for plot titles
  nregion = dimsizes(region)

  month_names = (/"JAN","FEB","MAR","APR","MAY","JUN","JUL","AUG","SEP","OCT","NOV","DEC"/)
  thickness_categories = (/"all","<0.64m","0.65-1.39m","1.4-2.47m","2.48-4.57m",">4.58m"/)
  ice_free_min = 1.					; definition of ice-free minimum (in units of 10^6 km^2)

;     psout = "fcondtop_ai."+month_names(imonth)+"_ts."+region+"."+plot_yr1+"-"+plot_yr2
;     psout = "fcondtop_Tsfc_fhocn."+month_names(imonth)+"_ts."+region+"."+plot_yr1+"-"+plot_yr2
  psout = "Figure1.fcondtop."+month_names(imonth)+"_ts."+region+"."+plot_yr1+"-"+plot_yr2
;     psout = "fcondtop_ai."+month_names(imonth)+"_ts."+region+"."+plot_yr1+"-"+plot_yr2

;  fcond_labels = (/"fcondtop_ai","fr. monthly means","fr. vicen00x","fr. daily hi, hs, atm TS"/)
  fcond_labels = (/"thickness category calc.","monthly, grid-cell mean est.","monthly, sub-gridcell est.","daily grid-cell mean est."/)
; ==============================================================
; parameters for heff calculation
; ==============================================================
   kseaice = 2.0                           ; conductivity of sea ice in W/m/degK
   ksnow = 0.3                             ; conductivity of snow in W/m/degK
   kratio = kseaice/ksnow
   Tbot = -1.8                          ; temperature at the bottom of the ice
;---------------------------------------------------------------------------------
; read in LE data
;---------------------------------------------------------------------------------
  LE_fcondtop = new((/4,ncase,nyr/),float)						; each ensemble member, Walsh extended and NSIDC ice index
  LE_fcondtop!0 = "fcond_calculation"
  LE_fcondtop!1 = "case"
  LE_fcondtop!2 = "year"
  LE_fcondtop&year = year

  LE_Tsfc = LE_fcondtop(0,:,:)
  LE_fhocn = LE_Tsfc
  LE_vai = LE_Tsfc
  LE_vhi = LE_Tsfc
  LE_vhs = LE_Tsfc

  if (plot_yr1.le.yr2_20th) then
     ii2 = yr2_20th - plot_yr1
     i1 = (plot_yr1 - yr1_20th)*12 + imonth
  else
     i1 = (plot_yr1 - yr1_rcp)*12 + imonth
  end if
  i2 = (plot_yr2 - yr1_rcp + 1)*12 - 1
  do i = 0,ncase-1
     f11 = addfile(f20thTsfc(i),"r")
     f12 = addfile(f20th(i),"r")
     f13 = addfile(f20th_mean(i),"r")
     f14 = addfile(f20th_nthick(i),"r")
     f15 = addfile(f20th_daily2monthly(i),"r")
     f16 = addfile(f20thaice(i),"r")
     f17 = addfile(f20thfhocn(i),"r")

     f1 = addfile(fTsfc(i),"r")
     f2 = addfile(frcp(i),"r")
     f3 = addfile(frcp_mean(i),"r")
     f4 = addfile(frcp_nthick(i),"r")
     f5 = addfile(frcp_daily2monthly(i),"r")
     f6 = addfile(faice(i),"r")
     f7 = addfile(ffhocn(i),"r")

     var1_name = "Tsfc_avg_mo_"+region
     var2_name = "fcondtop_ai_avg_mo_"+region                                     ; from fcondtop_ai output
     var3_name = "fcondtop_mean_ai_avg_mo_"+region                                ; calculated from monthly mean hi, hs, ai, Tsfc
     var4_name = "fcondtop_nthick_ai_avg_mo_"+region                              ; calculated from monthly mean vicen00x, aicen00nx, hs, Tsfc
     var5_name = "fcondtop_daily2monthly_ai_avg_mo_"+region                       ; calculated from daily hi, ai, hs, TS (from atm) then monthly averaged
     var61_name = "vai_mo_"+region
     var62_name = "vhi_mo_"+region
     var63_name = "vhs_mo_"+region
     var7_name = "fhocn_ai_avg_mo_"+region

     if (plot_yr1.le.yr2_20th) then
        LE_Tsfc(i,:ii2) = (/ f11->$var1_name$(i1::12) /)
        LE_fcondtop(0,i,:ii2) = (/ f12->$var2_name$(i1::12) /)
        LE_fcondtop(1,i,:ii2) = (/ f13->$var3_name$(i1::12) /)
        LE_fcondtop(2,i,:ii2) = (/ f14->$var4_name$(i1::12) /)
        LE_fcondtop(3,i,:ii2) = (/ f15->$var5_name$(i1::12) /)
        LE_vai(i,:ii2) = (/ f16->$var61_name$(i1::12) /)
        LE_vhi(i,:ii2) = (/ f16->$var62_name$(i1::12) /)
        LE_vhs(i,:ii2) = (/ f16->$var63_name$(i1::12) /)
        LE_fhocn(i,:ii2) = (/ f17->$var7_name$(i1::12) /)

        LE_Tsfc(i,ii2+1:) = (/ f1->$var1_name$(imonth:i2:12) /)
        LE_fcondtop(0,i,ii2+1:) = (/ f2->$var2_name$(imonth:i2:12) /)
        LE_fcondtop(1,i,ii2+1:) = (/ f3->$var3_name$(imonth:i2:12) /)
        LE_fcondtop(2,i,ii2+1:) = (/ f4->$var4_name$(imonth:i2:12) /)
        LE_fcondtop(3,i,ii2+1:) = (/ f5->$var5_name$(imonth:i2:12) /)
        LE_vai(i,ii2+1:) = (/ f6->$var61_name$(imonth:i2:12) /)
        LE_vhi(i,ii2+1:) = (/ f6->$var62_name$(imonth:i2:12) /)
        LE_vhs(i,ii2+1:) = (/ f6->$var63_name$(imonth:i2:12) /)
        LE_fhocn(i,ii2+1:) = (/ f7->$var7_name$(imonth:i2:12) /)

     else
        LE_Tsfc(i,:) = (/ f1->$var1_name$(i1:i2:12) /)
        LE_fcondtop(0,i,:) = (/ f2->$var2_name$(i1:i2:12) /)
        LE_fcondtop(1,i,:) = (/ f3->$var3_name$(i1:i2:12) /)
        LE_fcondtop(2,i,:) = (/ f4->$var4_name$(i1:i2:12) /)
        LE_fcondtop(3,i,:) = (/ f5->$var5_name$(i1:i2:12) /)
        LE_vai(i,:) = (/ f6->$var61_name$(i1:i2:12) /)
        LE_vhi(i,:) = (/ f6->$var62_name$(i1:i2:12) /)
        LE_vhs(i,:) = (/ f6->$var63_name$(i1:i2:12) /)
        LE_fhocn(i,:) = (/ f7->$var7_name$(i1:i2:12) /)
     end if
   end do
   LE_heff = LE_vhi
   LE_heff = LE_vhi + kratio*(LE_vhs)
   LE_hsheff = kratio*LE_vhs

   LE_fcondtop = -1.*LE_fcondtop				; for plotting purposes so that + values are from ice to atm
;---------------------------------------------------------------------------------
; calculate ensemble mean, min, max
;---------------------------------------------------------------------------------
  if (avg_vhi) then
     f3 = addfile(farea,"r")
     avg_name = "area_"+region
     reg_areaavg = (/ f3->$avg_name$ /)
     LE_vai = LE_vai/reg_areaavg
     LE_vhi = LE_vhi/reg_areaavg
     LE_vhs = LE_vhs/reg_areaavg
     LE_heff = LE_heff/reg_areaavg
     LE_hsheff = LE_hsheff/reg_areaavg
     LE_vai = 0.1*LE_vai					; vai_mo is in units x10^12 m2, area avg in units x10^13 m2
         							; vhi_mo is in units x10^13 m3 so ok 
;     LE_vai = 2.*LE_vai						; for plotting purposes
  end if

  LE_mn_fcondtop = dim_avg_n_Wrap(LE_fcondtop,1)
  min_fcondtop = dim_min_n_Wrap(LE_fcondtop,1)
  max_fcondtop = dim_max_n_Wrap(LE_fcondtop,1)

  LE_mn_fhocn = dim_avg_n_Wrap(LE_fhocn,0)
  min_fhocn = dim_min_n_Wrap(LE_fhocn,0)
  max_fhocn = dim_max_n_Wrap(LE_fhocn,0)

  LE_mn_Tsfc = dim_avg_n_Wrap(LE_Tsfc,0)
  min_Tsfc = dim_min_n_Wrap(LE_Tsfc,0)
  max_Tsfc = dim_max_n_Wrap(LE_Tsfc,0)

  LE_mn_vai = dim_avg_n_Wrap(LE_vai,0)
  min_vai = dim_min_n_Wrap(LE_vai,0)
  max_vai = dim_max_n_Wrap(LE_vai,0)

  LE_mn_vhi = dim_avg_n_Wrap(LE_vhi,0)
  min_vhi = dim_min_n_Wrap(LE_vhi,0)
  max_vhi = dim_max_n_Wrap(LE_vhi,0)

  LE_mn_vhs = dim_avg_n_Wrap(LE_vhs,0)
  min_vhs = dim_min_n_Wrap(LE_vhs,0)
  max_vhs = dim_max_n_Wrap(LE_vhs,0)

  LE_mn_heff = dim_avg_n_Wrap(LE_heff,0)
  min_heff = dim_min_n_Wrap(LE_heff,0)
  max_heff = dim_max_n_Wrap(LE_heff,0)

  LE_mn_hsheff = dim_avg_n_Wrap(LE_hsheff,0)
  min_hsheff = dim_min_n_Wrap(LE_hsheff,0)
  max_hsheff = dim_max_n_Wrap(LE_hsheff,0)

  Ryr1 = 2010
  Ryr2 = 2057
  xTsf = LE_mn_Tsfc({Ryr1:Ryr2})
  xfcond = LE_mn_fcondtop(0,{Ryr1:Ryr2})
  xvai = LE_mn_vai({Ryr1:Ryr2})
  xvhi = LE_mn_vhi({Ryr1:Ryr2})
  xvhs = LE_mn_vhs({Ryr1:Ryr2})

  RTsf_fcond = escorc(xTsf,xfcond)
  RTsf_vai = escorc(xTsf,xvai)
  RTsf_vhi = escorc(xTsf,xvhi)
  Rvai_fcond = escorc(xvai,xfcond)
  Rvhi_fcond = escorc(xvhi,xfcond)
  Rvhs_fcond = escorc(xvhs,xfcond)
;  tmp = f1->$fcondtop_mo_nh$(0)
;  LE_mn_fcondtop@units = tmp@units
;  min_fcondtop@units = tmp@units
;  max_fcondtop@units = tmp@units
;  delete(tmp)

  T1 = dim_avg_n(LE_mn_Tsfc(:51),0)
  T2 = LE_mn_Tsfc(nyr-1)

  heff1 = dim_avg_n(LE_mn_heff(:51),0)
  heff2 = LE_mn_heff(nyr-1)

  kseaice = 2.0                           ; conductivity of sea ice in W/m/degK
  ksnow = 0.3                             ; conductivity of snow in W/m/degK
  kratio = kseaice/ksnow
  Tbot = -1.8                          ; temperature at the bottom of the ice

  Tdiff1 = Tbot - T1
  Tdiff2 = Tbot - T2

  fcond11 = kseaice*Tdiff1/heff1
  fcond21 = kseaice*Tdiff2/heff1
  fcond12 = kseaice*Tdiff1/heff2
  fcond22 = kseaice*Tdiff2/heff2

;---------------------------------------------------------------------------------
; plot
;---------------------------------------------------------------------------------
  wks  = gsn_open_wks("pdf",psout)
;  wks  = gsn_open_wks("png",psout)

  gsn_define_colormap(wks,"posneg_1")
  colors = (/5,8,10,15,17,3/)
  ncolors = dimsizes(colors)

  poly = new(2,graphic)
  poly1 = new(2,graphic)
  poly2 = new(5,graphic)

  res = True				; res for stats plot
  res@gsnDraw = False
  res@gsnFrame = False

;  res@vpWidthF    = 0.5      ; Make plots wider than
;  res@vpHeightF   = 0.2      ; they are high.

  res@vpWidthF    = 0.4      ; Make plots wider than
  res@vpHeightF   = 0.19      ; they are high.

  res@tiXAxisString = ""
  res@trXMinF = plot_yr1
  res@trXMaxF = plot_yr2

;  res@trYMinF = -40.
;  res@trYMaxF = 0.
  res@trYMinF = 0.
  res@trYMaxF = 40.

  res@xyMonoDashPattern = True
  res@xyLineColors = colors

  res@xyLineThicknessF = 5.
  res@tiYAxisString    = "W m~S~-2~N~"
  res@tfPolyDrawOrder    = "Predraw"               ; put line on top 

  res@gsnLeftString = ""
  res@gsnRightString = ""
  res@gsnCenterString = ""
  fcond_data = LE_mn_fcondtop(:1,:)
  fcond_data(1,:) = LE_mn_fcondtop(3,:)						; subsetting for plotting

  resR = True
  resR = res
  delete(resR@xyLineColors)
  resR@tiYAxisString    = "ratio"
  resR@xyLineColors = colors(4)
  resR@trYMinF = 0.
  resR@trYMaxF = 1.

  res@tiXAxisString = ""

  resP = True
  resP@gsLineColor = "black"
  resP@tfPolyDrawOrder = "PostDraw"
  resP@gsLineThicknessF = 2.0                       ; thickness of lines

  res@tiXAxisString = ""
  res@trYMinF = -40.
  res@trYMaxF = 0.

;  res@tiYAxisString    = "W m~S~-2~N~, ~S~o~N~C"

  resR@tiYAxisString    = "~S~o~N~C"
  resR@xyLineColors = colors(2)
  resR@trYMinF = -45.
  resR@trYMaxF = -5.

  data = new((/5,nyr/),float)
  data!1 = "year"
  data&year = year
  data(0,:) = (/ LE_mn_fcondtop(0,:) /)
  data(1,:) = (/ -1.*LE_mn_fhocn /)
  data(2,:) = (/ LE_mn_Tsfc /)				; add fcondtop_ai at beginning for plotting purposes

  res@trYMinF = -1.
  res@trYMaxF = 45.

  res@gsnLeftString    = "(a) heat fluxes, Tsfc"

;  res@tiXAxisString = "year"
  plot1  = gsn_csm_xy2(wks,data&year,data(:1,:),data(2:,:),res,resR)  ; Create filled XY plot.

  delete(res@xyLineColors)

  res@tiYAxisString    = "m, fraction"
  res@trYMinF = 0.
  res@trYMaxF = 8.

  data(0,:) = (/ LE_mn_vai /)
  data(1,:) = (/ LE_mn_vhi /)
  data(2,:) = (/ LE_mn_vhs /)
  data(3,:) = (/ LE_mn_heff /)
  data(4,:) = (/ LE_mn_hsheff /)

;  delete(resR@xyLineColors)
;  resR@xyLineColors = colors(2:)
  res@xyLineColors = colors

  res@tiXAxisString = "year"
;  plot2  = gsn_csm_xy(wks,data&year,data,res)
  res@gsnLeftString    = "(b) SIC, sea ice and snow thicknesses"
;  plot2  = gsn_csm_xy(wks,data&year,data(:2,:),res)
  delete(res@xyLineColors)
  res@xyLineColors = colors(1:)
;  res@tiYAxisString    = "m, fraction"
  res@tiYAxisString    = "m"
  resR@tiYAxisString    = "%"
  resR@xyLineColors = colors(0)
  resR@trYMinF = 0.
  resR@trYMaxF = 110.
  plot2  = gsn_csm_xy2(wks,data&year,data(1:2,:),100.*data(0,:),res,resR)  ; Create filled XY plot.


  res@tiXAxisString = "year"
  delete(res@xyLineColors)
  colors2 = colors
  colors2(:ncolors-4) = colors(3:)
  res@xyLineColors = colors2
  res@gsnLeftString    = "(c) effective thicknesses"
  res@tiYAxisString    = "m"
  res@tiXAxisString = "year"
  plot3  = gsn_csm_xy(wks,data&year,data(3:,:),res)

  res@gsnLeftString = ""
  res@gsnRightString = ""

  pres                   = True                        ; poly res
  pres@gsFillOpacityF = 0.25

  xp = new(2*nyr,integer)
  yp = new(2*nyr,float)

  xp(:nyr-1) = year
  xp(nyr:) = year(::-1)

  pres@gsFillColor       = colors(0)

  max_data = data
  min_data = data

  max_data(0,:) = (/ max_fcondtop(0,:) /)
  max_data(1,:) = (/ -1.*max_fhocn /)
  max_data(2,:) = (/ max_Tsfc /)

  min_data(0,:) = (/ min_fcondtop(0,:) /)
  min_data(1,:) = (/ -1.*min_fhocn /)
  min_data(2,:) = (/ min_Tsfc /)

  do i=0,2
     pres@gsFillColor       = colors(i)
     yp(:nyr-1) = max_data(i,:)
     yp(nyr:) = min_data(i,::-1)
     if (i.lt.2) then
        poly1(i) = gsn_add_polygon(wks,plot1,xp,yp,pres)
     else
        poly1xy2 = gsn_add_polygon(wks,plot1@xy2,xp,yp,pres)
     end if
  end do

  max_data(0,:) = (/ max_vai /)
  max_data(1,:) = (/ max_vhi /)
  max_data(2,:) = (/ max_vhs /)
  max_data(3,:) = (/ max_heff /)
  max_data(4,:) = (/ max_hsheff /)

  min_data(0,:) = (/ min_vai /)
  min_data(1,:) = (/ min_vhi /)
  min_data(2,:) = (/ min_vhs /)
  min_data(3,:) = (/ min_heff /)
  min_data(4,:) = (/ min_hsheff /)

  do i=0,4
     pres@gsFillColor       = colors(i)
     yp(:nyr-1) = max_data(i,:)
     yp(nyr:) = min_data(i,::-1)
;     poly2(i) = gsn_add_polygon(wks,plot2,xp,yp,pres)
     if (i.ge.3) then
        poly2(i) = gsn_add_polygon(wks,plot3,xp,yp,pres)
     else
        poly2(i) = gsn_add_polygon(wks,plot2,xp,yp,pres)
     end if
  end do
;------------------------------------------------------------------------------------------
; now create a map showing the region and draw
;------------------------------------------------------------------------------------------
   resM                      = True            ; resources for map
   resM@mpOutlineOn = True
   resM@mpFillOn = True
   resM@gsnDraw              = False        ; don't draw yet
   resM@gsnFrame             = False        ; don't advance frame yet
   resM@mpLandFillColor      = "grey"
   resM@mpFillDrawOrder = "PreDraw"
   resM@mpGridAndLimbDrawOrder = "PreDraw"
;   resM@gsnSpreadColors     = True
   resM@mpMinLatF            = 60
   resM@gsnPolar             = "NH"               ; choose hemisphere
   resM@vpWidthF           = 0.1
   resM@vpHeightF          = 0.1
;   resM@vpXF = 0.69
;   resM@vpYF = 0.725
   resM@vpXF = 0.58
   resM@vpYF = 0.6

   resP = True
   resP@gsFillOpacityF = 0.65
   resP@gsFillColor = "navy"
   resP@tfPolyDrawOrder = "PostDraw"

   map = gsn_csm_map_polar(wks,resM)
   ArcOc_lat = (/90., 80., 80., 68., 68., 90. /)
   ArcOc_long = (/-117., -117., 100., 100., 243., 243./)
   gsn_polygon(wks,map,ArcOc_long,ArcOc_lat,resP)

   res_lat = True
   res_lat@gsLineThicknessF = 3.
   draw(map)
   gsn_polyline(wks,map,(/0.,180.,360./),(/70.,70.,70./),res_lat)
;------------------------------------------------------------------------------------------


  lgres                    = True
  lgres@lgMonoDashIndex    = True
  lgres@lgDashIndex        = 0
  lgres@lgLineColors       = colors
  lgres@lgLineThicknessF = 3.
  lgres@lgItemType         = "Lines"        ; show lines only (default)
  lgres@lgPerimThicknessF  = 2.0            ; thicken the box perimeter
  lgres@lgPerimOn = False

;  labels = fcond_labels
  colors3 = colors
  colors3(2) = colors(4)
  lgres@lgLineColors       = colors3
  labels = fcond_labels(:2)
  labels(1) = fcond_labels(3)
  labels(2) = "cond:mean/cond:thickness cat."
  nitems = dimsizes(labels)                 ; number of legend items
;  lgres@lgLabelFontHeightF = .08            ; legend label font thickness
;  lgres@vpWidthF           = 0.3           ; width of legend (NDC)
  lgres@vpHeightF          = 0.05           ; height of legend (NDC)
  lgres@lgLabelFontHeightF = 0.06            ; legend label font thickness
  lgres@vpWidthF           = 0.18           ; width of legend (NDC)

  pres = True
  pres@gsnFrame = False
;  pres@gsnMaximize = True
;  pres@gsnPaperOrientation = "landscape"
  pres@gsnPanelBottom   = 0.1

;  pres@gsnPanelMainFont = "helvetica-bold"
  pres@gsnPanelMainFont = "helvetica"
  pres@gsnPanelMainFontHeightF = 0.016
  pres@gsnPanelMainString = month_names(imonth)+" "+region_name
;  gsn_panel(wks,(/plot1,plot2/),(/2,1/),pres)
  gsn_panel(wks,(/plot1,plot2,plot3/),(/3,1/),pres)

  lgres@lgLabelFontHeightF = .06            ; legend label font thickness
;  lgres@vpHeightF          = 0.10           ; height of legend (NDC)

  delete(labels)
  lgres@lgLineColors       = colors

  labels = (/"Conductive Heat Flux","Ocean-Ice Heat Flux","Tsfc"/)
;  gsn_legend_ndc(wks,3,labels,0.19,0.9,lgres)
  gsn_legend_ndc(wks,3,labels,0.3,0.91,lgres)

  delete(labels)
  lgres@lgLabelFontHeightF = .04            ; legend label font thickness
  lgres@vpHeightF          = 0.06           ; height of legend (NDC)
;  labels = (/"SIC (fraction)","hi","hs","h_eff","kratio*hs"/)
  labels = (/"SIC","SIT","hs"/)
  gsn_legend_ndc(wks,3,labels,0.3,0.6,lgres)
;  gsn_legend_ndc(wks,5,labels,0.52,0.47,lgres)
;  gsn_legend_ndc(wks,5,labels,0.6,0.7,lgres)

  delete(labels)
  lgres@vpHeightF          = 0.07           ; height of legend (NDC)
;  lgres@vpHeightF          = 0.13           ; height of legend (NDC)
  labels = (/"h_eff","kratio*hs"/)
  lgres@lgLineColors       = colors2
  gsn_legend_ndc(wks,2,labels,0.52,0.35,lgres)

  frame(wks)
end

