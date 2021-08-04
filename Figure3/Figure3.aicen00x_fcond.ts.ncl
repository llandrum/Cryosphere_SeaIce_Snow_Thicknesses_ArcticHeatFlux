; Plots ensemble mean vai (ice area) for each of ice
; thickness categories (and total) for user defined month
; and regions for CESM_LE. Variability is shown by polygons
; of min/max ice areas from entire ensemble. 
;
; LLandrum
; June 2020
;===============================================;
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"   
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"   
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/shea_util.ncl"
;load "/glade/u/home/landrum/ncl/asphilli_util.ncl"
; ================================================;
begin
  plot_fcond_ratio = True                       ; True to plot ratio of fcondtop_daily2monthly_mean_ai/fcontop_ai in first plot, second y-axis

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
  nyr = yr2_rcp - yr1_20th + 1
  year = ispan(yr1_20th,yr2_rcp,1)

  base_yr1 = 1950
  base_yr2 = base_yr1 + 9
  percent_yr1 = 2000					; first year to calculate min/max of fcond ratio
  percent_yr2 = 2070

  datadir_ice = "/glade/p/cesm/pcwg/landrum/LE/ice/pre_process/monthly/"
  f20th_ice = datadir_ice+"ice_vol_MHolland_regions_"+LE_20thC_case+scnumbers+"_"+yr1_20th+"-"+yr2_20th+".nc"
  frcp_ice = datadir_ice+"ice_vol_MHolland_regions_"+LE_rcp_case+scnumbers+"_"+yr1_rcp+"-"+yr2_rcp+".nc"
  f20th_aicen00x = datadir_ice+"aicen00x/vaicen00x_MHolland_regions_"+LE_20thC_case+scnumbers+"_"+yr1_20th+"-"+yr2_20th+".nc"
  frcp_aicen00x = datadir_ice+"aicen00x/vaicen00x_MHolland_regions_"+LE_rcp_case+scnumbers+"_"+yr1_rcp+"-"+yr2_rcp+".nc"

  datadir = "/glade/p/cesm/pcwg/landrum/LE/"
  f20th = datadir+"shf/ice/fcondtop/ice_fcondtop_ai_MHolland_regions_"+LE_20thC_case+scnumbers+"_"+yr1_20th+"-"+yr2_20th+".nc"
  f20th_mean = datadir+"ice/fcondtop_ai/calcs/pre_process/fcondtop_mean_ai/ice_fcondtop_mean_ai_MHolland_regions_"+LE_20thC_case+scnumbers+"_"+yr1_20th+"-"+yr2_20th+".nc"
  f20th_nthick = datadir+"ice/fcondtop_ai/calcs/pre_process/fcondtop_nthick_ai/ice_fcondtop_nthick_ai_MHolland_regions_"+LE_20thC_case+scnumbers+"_"+yr1_20th+"-"+yr2_20th+".nc"
  f20th_daily2monthly = datadir+"ice/fcondtop_ai/calcs/pre_process/fcondtop_daily2monthly_ai/ice_fcondtop_daily2monthly_ai_MHolland_regions_"+LE_20thC_case+scnumbers+"_"+yr1_20th+"-"+yr2_20th+".nc"

  frcp = datadir+"shf/ice/fcondtop/ice_fcondtop_ai_MHolland_regions_"+LE_rcp_case+scnumbers+"_"+yr1_rcp+"-"+yr2_rcp+".nc"
  frcp_mean = datadir+"ice/fcondtop_ai/calcs/pre_process/fcondtop_mean_ai/ice_fcondtop_mean_ai_MHolland_regions_"+LE_rcp_case+scnumbers+"_"+yr1_rcp+"-"+yr2_rcp+".nc"
  frcp_nthick = datadir+"ice/fcondtop_ai/calcs/pre_process/fcondtop_nthick_ai/ice_fcondtop_nthick_ai_MHolland_regions_"+LE_rcp_case+scnumbers+"_"+yr1_rcp+"-"+yr2_rcp+".nc"
  frcp_daily2monthly = datadir+"ice/fcondtop_ai/calcs/pre_process/fcondtop_daily2monthly_ai/ice_fcondtop_daily2monthly_ai_MHolland_regions_"+LE_rcp_case+scnumbers+"_"+yr1_rcp+"-"+yr2_rcp+".nc"

  obs_yr1 = 1979
  obs_yr2 = 2014
  obs_clim_yr1 = 2010
  obs_clim_yr2 = 2014
  obs_type = "Nasa_Team"
  obs_datadir = "/glade/p/cesm/pcwg/landrum/SSMI/NH/"
  fobs = obs_datadir+"ice_vol_MHolland_regions_ssmi."+obs_type+"_nh."+obs_yr1+"-"+obs_yr2+".nc"

  VAI_month = 2				; 1-12 month to plot
  imonth = VAI_month - 1
  plot_yr1 = 1950
;  plot_yr2 = 2100
  plot_yr2 = 2070

  region = (/"ArcOc"/)                  ; nh,CArc,Lab,GIN,Bar,ArcOc,Sib,Beau,Bering,Okhotsk,Chukchi,Kara,Laptev
  region_name = "Arctic Ocean"		; longer for plot labels
  nregion = dimsizes(region)

  month_names = (/"JAN","FEB","MAR","APR","MAY","JUN","JUL","AUG","SEP","OCT","NOV","DEC"/)
  thickness_categories = (/"all","<0.64m","0.64 to <1.39m","1.39 to <2.47m","2.47 to <4.57m",">4.57m"/)
  nthick = dimsizes(thickness_categories)

;  fcond_labels = (/"model output","monthly, mean hi,hs est.","monthly, sub-gridcell est.","mean hi, hs est."/)
  fcond_labels = (/"CESM1-CICE","monthly MNthick","monthly 0layer-ITD","MNthick"/)

  psout = "Figure3.aicen00x_fcond."+region+"."+month_names(imonth)+"_ts."+plot_yr1+"-"+plot_yr2
;---------------------------------------------------------------------------------
; read in LE data
;---------------------------------------------------------------------------------
  LE_fcondtop = new((/4,ncase,nyr/),float)                                              ; each ensemble member, Walsh extended and NSIDC ice index
  LE_fcondtop!0 = "fcond_calculation"
  LE_fcondtop!1 = "case"
  LE_fcondtop!2 = "year"
  LE_fcondtop&year = year

  LE_vai = new((/6,ncase,nyr/),float)						; each ensemble member, Walsh extended and NSIDC ice index
  LE_vai!0 = "thickness_category"
  LE_vai!1 = "case"
  LE_vai!2 = "year"
  LE_vai&year = year

  i2 = yr2_20th - yr1_20th
  do i = 0,ncase-1
     f1 = addfile(f20th_ice(i),"r")
     f2 = addfile(frcp_ice(i),"r")
     f3 = addfile(f20th_aicen00x(i),"r")
     f4 = addfile(frcp_aicen00x(i),"r")

     var_name = "vai_mo_"+region
     LE_vai(0,i,:i2) = (/ f1->$var_name$(imonth::12) /)
     LE_vai(0,i,i2+1:) = (/ f2->$var_name$(imonth::12) /)
     do jthick=1,5
        var_name = "vai00"+jthick+"_mo_"+region
        LE_vai(jthick,i,:i2) = (/ f3->$var_name$(imonth::12) /)
        LE_vai(jthick,i,i2+1:) = (/ f4->$var_name$(imonth::12) /)
     end do
     f12 = addfile(f20th(i),"r")
     f13 = addfile(f20th_mean(i),"r")
     f14 = addfile(f20th_nthick(i),"r")
     f15 = addfile(f20th_daily2monthly(i),"r")

     f22 = addfile(frcp(i),"r")
     f23 = addfile(frcp_mean(i),"r")
     f24 = addfile(frcp_nthick(i),"r")
     f25 = addfile(frcp_daily2monthly(i),"r")

     var2_name = "fcondtop_ai_avg_mo_"+region                                     ; from fcondtop_ai output
     var3_name = "fcondtop_mean_ai_avg_mo_"+region                                ; calculated from monthly mean hi, hs, ai, Tsfc
     var4_name = "fcondtop_nthick_ai_avg_mo_"+region                              ; calculated from monthly mean vicen00x, aicen00nx, hs, Tsfc
     var5_name = "fcondtop_daily2monthly_ai_avg_mo_"+region                       ; calculated from daily hi, ai, hs, TS (from atm) then monthly averaged

     LE_fcondtop(0,i,:i2) = (/ f12->$var2_name$(imonth::12) /)
     LE_fcondtop(1,i,:i2) = (/ f13->$var3_name$(imonth::12) /)
     LE_fcondtop(2,i,:i2) = (/ f14->$var4_name$(imonth::12) /)
     LE_fcondtop(3,i,:i2) = (/ f15->$var5_name$(imonth::12) /)

     LE_fcondtop(0,i,i2+1:) = (/ f22->$var2_name$(imonth::12) /)
     LE_fcondtop(1,i,i2+1:) = (/ f23->$var3_name$(imonth::12) /)
     LE_fcondtop(2,i,i2+1:) = (/ f24->$var4_name$(imonth::12) /)
     LE_fcondtop(3,i,i2+1:) = (/ f25->$var5_name$(imonth::12) /)

  end do
 
  LE_fcondtop = -1.*LE_fcondtop                                ; for plotting purposes so that + values are from ice to atm
   
;---------------------------------------------------------------------------------
; calculate ensemble mean, min, max
;---------------------------------------------------------------------------------

  LE_mn_vai = dim_avg_n_Wrap(LE_vai,1)
  min_vai = dim_min_n_Wrap(LE_vai,1)
  max_vai = dim_max_n_Wrap(LE_vai,1)

  LE_mn_fcondtop = dim_avg_n_Wrap(LE_fcondtop,1)
  min_fcondtop = dim_min_n_Wrap(LE_fcondtop,1)
  max_fcondtop = dim_max_n_Wrap(LE_fcondtop,1)
  LE_std_fcondtop = dim_stddev_n_Wrap(LE_fcondtop,1)			; for student-T test
;---------------------------------------------------------------------------------
; plot
;---------------------------------------------------------------------------------
  wks  = gsn_open_wks("pdf",psout)
;  wks  = gsn_open_wks("png",psout)

  gsn_define_colormap(wks,"posneg_1")
  colors = (/5,8,10,15,17,3/)

  plot = new(nregion,graphic)
  poly_vai = new(6,graphic)
  poly_fcond = new(2,graphic)
  poly_delta_fcond = new(2,graphic)

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
  res@trYMinF = 0.
  res@trYMaxF = 40.

  res@xyMonoDashPattern = True
  res@xyLineColors = colors

  res@xyLineThicknessF = 5.
  res@tiYAxisString    = "W m~S~-2~N~"
  res@tfPolyDrawOrder    = "Predraw"               ; put line on top 

  res@gsnRightString    = ""
  res@gsnCenterString = ""

  fcond_data = LE_mn_fcondtop(:1,:)
  fcond_data(1,:) = LE_mn_fcondtop(3,:)                                         ; subsetting for plotting

  resR = True
  resR = res
  delete(resR@xyLineColors)
  resR@tiYAxisString    = "ratio"
  resR@xyLineColors = colors(4)
  resR@trYMinF = 0.
  resR@trYMaxF = 1.

  res@gsnLeftString    ="(a) Mean conductive heat fluxes"
  res@tiXAxisString = ""
  iyr1 = percent_yr1 - yr1_20th
  iyr2 = percent_yr2 - yr1_20th
  if (plot_fcond_ratio) then
     resP = True
     resP@gsLineColor = "black"
     resP@tfPolyDrawOrder = "PostDraw"
     resP@gsLineThicknessF = 2.0                       ; thickness of lines

     fcondratio = fcond_data(0,:)
     fcondratio = fcond_data(1,:)/fcond_data(0,:)
     print("Min/max for fcondratio ("+percent_yr1+"-"+percent_yr2+"): ")
     printMinMax(fcondratio(iyr1:iyr2),0)
     plot0  = gsn_csm_xy2(wks,LE_mn_fcondtop&year,fcond_data,fcondratio,res,resR)  ; Create filled XY plot.
     poly = gsn_add_polyline(wks,plot0@xy2,(/plot_yr1,plot_yr2/),(/0.75,0.75/),resP)
  else
     plot0  = gsn_csm_xy(wks,LE_mn_fcondtop&year,fcond_data,res)  ; Create filled XY plot.
  end if
  delta_fcond_data = fcond_data
  ib1 = base_yr1 - yr1_20th
  ib2 = base_yr2 - yr1_20th
  base_fcond_data = dim_avg_n(fcond_data(:,ib1:ib2),1)
  delta_fcond_data = fcond_data - conform(fcond_data,base_fcond_data,0)
  delta_fcondratio = delta_fcond_data(0,:)
  delta_fcondratio = delta_fcond_data(1,:)/delta_fcond_data(0,:)

; -------------------------------------------------
; now calculate probability using student T-test...
;--------------------------------------------------
  fcond_std_data = LE_std_fcondtop(:1,:)
  fcond_std_data(1,:) = LE_std_fcondtop(3,:)                                         ; subsetting for plotting

  corr = escorc(LE_fcondtop(0,:,:),LE_fcondtop(1,:,:))

  denom = sqrt((fcond_std_data(0,:)^2 + fcond_std_data(1,:)^2)/ncase)

  df = new(nyr,float)
  df = ncase-1
  p05 = new(nyr,float)
  p05 = 0.5
  studentT = (delta_fcond_data(0,:) - delta_fcond_data(1,:))/denom
  prob = (1.-betainc(df/(df+studentT^2),df/2.,p05))*100.
  ip95 = min(ind(prob(1:).gt.95.)) + 1				; first year (1920) is off so skip....
;-------------------------------------------------
  print("Min/max for delta_fcondratio ("+percent_yr1+"-"+percent_yr2+"): ")     
  printMinMax(delta_fcondratio(iyr1:iyr2),0)     

  res@gsnLeftString    ="(b) Changes in conductive heat fluxes"
  res@trYMaxF = 16.
  res@xyLineThicknessF = 2.
  plot0b  = gsn_csm_xy(wks,fcond_data&year,delta_fcond_data,res)  ; Create filled XY plot.

  data2 = delta_fcond_data
  data2(:,:ip95) = data2@_FillValue
  res@xyLineThicknessF = 5.
  plot0b2  = gsn_csm_xy(wks,fcond_data&year,data2,res)  ; Create filled XY plot.
  overlay(plot0b,plot0b2)

  res@trYMaxF = 8.

  res@tiYAxisString    = "10~S~6~N~ km~S~2~N~"
  res@gsnLeftString    =  "(c) Sea ice areas by thickness category"
  res@tiXAxisString = "year"
  plot1  = gsn_csm_xy(wks,LE_mn_vai&year,LE_mn_vai,res)  ; Create filled XY plot.

  res@gsnLeftString = ""
  res@gsnRightString = ""

  pres                   = True                        ; poly res
  pres@gsFillOpacityF = 0.25

  xp = new(2*nyr,integer)
  yp = new(2*nyr,float)

  xp(:nyr-1) = year
  xp(nyr:) = year(::-1)

  max_delta_fcondtop = max_fcondtop(:1,:)
  max_delta_fcondtop(1,:) = max_fcondtop(3,:)
  max_delta_fcondtop = max_delta_fcondtop - conform(max_delta_fcondtop,base_fcond_data,0)

  min_delta_fcondtop = min_fcondtop(:1,:)
  min_delta_fcondtop(1,:) = min_fcondtop(3,:)
  min_delta_fcondtop = min_delta_fcondtop - conform(min_delta_fcondtop,base_fcond_data,0)

  pres@gsFillColor       = colors(0)
  yp(:nyr-1) = max_fcondtop(0,:)
  yp(nyr:) = min_fcondtop(0,::-1)
  poly_fcond(0) = gsn_add_polygon(wks,plot0,xp,yp,pres)

  yp(:nyr-1) = max_delta_fcondtop(0,:)
  yp(nyr:) = min_delta_fcondtop(0,::-1)
  poly_delta_fcond(0) = gsn_add_polygon(wks,plot0b,xp,yp,pres)

  pres@gsFillColor       = colors(1)
  yp(:nyr-1) = max_fcondtop(3,:)
  yp(nyr:) = min_fcondtop(3,::-1)
  poly_fcond(1) = gsn_add_polygon(wks,plot0,xp,yp,pres)

  yp(:nyr-1) = max_delta_fcondtop(1,:)
  yp(nyr:) = min_delta_fcondtop(1,::-1)
  poly_delta_fcond(1) = gsn_add_polygon(wks,plot0b,xp,yp,pres)

  do i=0,4
     pres@gsFillColor       = colors(i)
     yp(:nyr-1) = max_vai(i,:)
     yp(nyr:) = min_vai(i,::-1)
     poly_vai(i) = gsn_add_polygon(wks,plot1,xp,yp,pres)
  end do

  lgres                    = True
  lgres@lgMonoDashIndex    = True
  lgres@lgDashIndex        = 0
  lgres@lgLineColors       = colors
  lgres@lgLineThicknessF = 3.
  lgres@lgItemType         = "Lines"        ; show lines only (default)
  lgres@lgLabelFontHeightF = .08            ; legend label font thickness
  lgres@lgPerimOn = False
  lgres@lgPerimThicknessF  = 2.0            ; thicken the box perimeter

  colors2 = colors
  colors2(2) = colors(4)
  lgres@lgLineColors       = colors2
  labels = fcond_labels(:2)
  labels(1) = fcond_labels(3)
  labels(2) = "MNthick/CESM1-CICE"
  nitems = dimsizes(labels)                 ; number of legend items
  lgres@lgLabelFontHeightF = .08            ; legend label font thickness
  lgres@vpWidthF           = 0.28           ; width of legend (NDC)
  lgres@vpHeightF          = 0.08           ; height of legend (NDC)
;  gsn_legend_ndc(wks,nitems,labels,0.53,0.73,lgres)

  delete(lgres@lgLineColors)
  lgres@lgLineColors       = colors2(2)
  gsn_legend_ndc(wks,1,labels(2),0.4,0.78,lgres)

  delete(lgres@lgLineColors)
  lgres@lgLineColors       = colors2
  lgres@lgLabelFontHeightF = .04            ; legend label font thickness
  lgres@vpHeightF          = 0.05           ; height of legend (NDC)
  lgres@vpWidthF           = 0.25           ; width of legend (NDC)
  gsn_legend_ndc(wks,2,labels(:1),0.29,0.61,lgres)

  delete(labels)
  lgres@lgLineColors       = colors
  labels = thickness_categories
  nitems = dimsizes(labels)                 ; number of legend items
  lgres@vpWidthF           = 0.18           ; width of legend (NDC)
  lgres@vpHeightF          = 0.12           ; height of legend (NDC)
  ilegend = ispan(0,nthick-1,1)
  lgres@lgItemOrder  = ilegend(::-1)

  pres = True
  pres@gsnFrame = False
  pres@gsnPanelMainFont = "helvetica"
;  pres@gsnPanelMainFontHeightF = 0.016
  pres@gsnPanelMainString = month_names(imonth)
  pres@gsnPanelBottom   = 0.1
  gsn_panel(wks,(/plot0,plot0b,plot1/),(/3,1/),pres)
;  gsn_legend_ndc(wks,nitems,labels,0.23,0.45,lgres)
  gsn_legend_ndc(wks,nitems,labels,0.3,0.33,lgres)
  frame(wks)
end

