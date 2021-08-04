; Maps changes in cice variables for user specified base period
; and time periods thereafter (user also specifies month).
;
; This program assumes netCDF files already exist for monthly
; statistics. If not, go to /glade/u/home/landrum/CESM_CCSM4/Arctic/scripts/
; and run netCDF_aice_stats.ncl to create them.
; LLandrum
; August, 2018
;----------------------------------------------------------------------------------
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/shea_util.ncl"
;load "/home/landrum/ncl/landrum_util.ncl"
load "/glade/u/home/landrum/ncl/landrum_util.ncl"
load "/glade/u/home/landrum/ncl/asphilli_util.ncl"

begin
; ==============================================================
; User defined parameters that specify region of globe to consider
; ==============================================================
  imonth = 1					; month to plot
  var_names = (/"Tsfc","fcondtop_ai","heff"/)
  var_type = (/"T","SHF","heff"/)					; choices are h, heff,aice, SHF, T - these are for scaling mean plots
  units = (/"~S~o~N~C","W m~S~-2~N~","m"/)
  var_name_titles = var_names

  nvar = dimsizes(var_names)
  explicit_colors = True					; True for hi, hs, heff
  mask_low_aice = True						; True to mask out areas of very low SIC during base period
 
  ifcond = ind(var_names.eq."fcondtop_ai")
  iaice = ind(var_names.eq."aice")
  ihs = ind(var_names.eq."hs")
  ihi = ind(var_names.eq."hi")
  iheff = ind(var_names.eq."heff")
  if (.not.ismissing(iheff)) then
     plot_heff = True
     ivar_skip = iheff
     var_name_titles(iheff) = "h~B~eff~N~"
  else
     ivar_skip = nvar
     plot_heff = False
  end if

  ncase = 40

  scale = (/1.,-1.,1./)                   ; for plotting purposes reverse sign for fcondtop
		                            ; plot such that a  positive change indicates increased heat conduction through ice

  plot_mean = False				; True to plot mean vars at base decade, false not to
  overlay_ailow = False				; True to overlay low aice contour from base period
  ai_low = 15.
  overlay_aihigh = True				; True to overlay high aice contour for given decade
  ai_high = 98.
  overlay_hiheff = False                        ; True to overlay ratio of hi/heff contours
  cont_hiheff_min = 0.4				; minimum ratio of hi/heff to contour and shade (e.g. snow contributing 40% or higher to heff)
  overlay_hsheff = True                         ; True to overlay ratio of hs*Kratio/heff contours
  cont_hsheff_min = 0.4                         ; minimum ratio of hs*Kratio/heff to contour and shade (e.g. snow contributing 40% or higher to heff)
  stats_yr1 = 1920
  stats_yr2 = 2100

  base_yr1 = 1950
  plot_yr1 = (/2010,2050/)
  nplot = dimsizes(plot_yr1)

  nyr_stats = 10
  base_yr2 = base_yr1 + nyr_stats - 1
  plot_yr2 = plot_yr1 + nyr_stats - 1  

  datadir = "/glade/p/cesm/pcwg/landrum/LE/ice/"
  month_names = (/"JAN","FEB","MAR","APR","MAY","JUN","JUL","AUG","SEP","OCT","NOV","DEC"/)

  fstats = datadir+var_names+"/LE."+ncase+"sim."+month_names(imonth)+"_monthly_"+var_names+"_nh."+nyr_stats+"yr_stats."+stats_yr1+"-"+stats_yr2+".nc"
  fhi = datadir+"hi/LE."+ncase+"sim."+month_names(imonth)+"_monthly_hi_nh."+nyr_stats+"yr_stats."+stats_yr1+"-"+stats_yr2+".nc"
  fhs = datadir+"hs/LE."+ncase+"sim."+month_names(imonth)+"_monthly_hs_nh."+nyr_stats+"yr_stats."+stats_yr1+"-"+stats_yr2+".nc"

  month_names = (/"JAN","FEB","MAR","APR","MAY","JUN","JUL","AUG","SEP","OCT","NOV","DEC"/)

  psout = "Figure2.cont_"+nplot+"dec_stats_"+nvar+"vars."+month_names(imonth)+".LE_"+ncase+"sim.base_"+base_yr1
; ==============================================================
; parameters for heff calculation
; ==============================================================
   kseaice = 2.0                           ; conductivity of sea ice in W/m/degK
   ksnow = 0.3                             ; conductivity of snow in W/m/degK
   kratio = kseaice/ksnow
   Tbot = -1.8                          ; temperature at the bottom of the ice
;--------------------------------------------------------------------------------
; read in base data
;--------------------------------------------------------------------------------
  ib = base_yr1 - stats_yr1
  do i=0,nvar-1
     ib = base_yr1 - stats_yr1
     if (i.ne.ivar_skip) then
        f = addfile(fstats(i),"r")
        if (i.eq.0) then
           tlat = f->TLAT
           tlon = f->TLON
           dims = dimsizes(tlat)
           nj = dims(0)
           ni = dims(1)
           mean_var = new((/nplot,nvar,nj,ni/),float)
           base_var = new((/nvar,nj,ni/),float)    
        end if
        base_var(i,:,:) = scale(i)*f->stats(ib,0,:,:)

        do ip=0,nplot-1
           iy = plot_yr1(ip) - stats_yr1
           mean_var(ip,i,:,:) = scale(i)*(/ f->stats(iy,0,:,:) /)
;           std_var(ip,i,:,:) = (/ sqrt(f->stats(iy,1,:,:)) /)
        end do
     end if
  end do

  if (.not.ismissing(ifcond)) then
     var_name_titles(ifcond) = "Conductive Heat Flux"
     base_var(ifcond,:,:) = where(base_var(ifcond,:,:).lt.60.,base_var(ifcond,:,:),base_var@_FillValue)          ;mask out high fcond values near coastlines for plotting purposes
  end if

  if (plot_heff) then
     if (.not.ismissing(ihs)) then
        var_name_titles(ihs) = "kratio*hs"
        base_var(ihs,:,:) = kratio*base_var(ihs,:,:)  
        base_hs = base_var(ihs,:,:)			; do this before masking out low values

        base_var(ihs,:,:) = where(base_var(ihs,:,:).gt.0.01,base_var(ihs,:,:),base_var@_FillValue)          ;for plotting purposes

        mean_var(:,ihs,:,:) = kratio*mean_var(:,ihs,:,:)
        mean_hs = mean_var(:,ihs,:,:)
     else					; need to get hs
        f1 = addfile(fhs,"r")
        base_hs = f1->stats(ib,0,:,:)
        base_hs = kratio*base_hs

        mean_hs = new((/nplot,nj,ni/),float)

        do ip=0,nplot-1
           iy = plot_yr1(ip) - stats_yr1
           mean_hs(ip,:,:) = (/ f1->stats(iy,0,:,:) /)
        end do
        mean_hs = kratio*mean_hs
     end if
     if (.not.ismissing(ihi)) then
        base_hi = base_var(ihi,:,:)
        base_var(ihi,:,:) = where(base_var(ihi,:,:).gt.0.01,base_var(ihi,:,:),base_var@_FillValue)          ;mask out less than 1% aice
        mean_hi = mean_var(:,ihi,:,:)
     else					; need to get hi
        f2 = addfile(fhi,"r")
        base_hi = f2->stats(ib,0,:,:)
        mean_hi = new((/nplot,nj,ni/),float)

        do ip=0,nplot-1
           iy = plot_yr1(ip) - stats_yr1
           mean_hi(ip,:,:) = (/ f2->stats(iy,0,:,:) /)
        end do
     end if

     base_var(iheff,:,:) = base_hi + base_hs  
     base_var(iheff,:,:) = where(base_var(iheff,:,:).gt.0.01,base_var(iheff,:,:),base_var@_FillValue)          ;mask out less than 1% aice
     base_hs = where(base_hs.gt.0.01,base_hs,base_hi@_FillValue)          ;plotting purposes
     base_hi = where(base_hi.gt.0.01,base_hi,base_hi@_FillValue)          ;plotting purposes

     mean_var(:,iheff,:,:) = mean_hi + mean_hs				; remember hs has been converted to kratio*hs

     if ((overlay_hiheff).or.(overlay_hsheff)) then

        base_hiheff = base_hi
        base_hiheff = base_hi/base_var(iheff,:,:)
        base_hsheff = base_hs/base_var(iheff,:,:)
        base_hiheff@lat2d = tlat
        base_hiheff@lon2d = tlon
        base_hiheff@lat2d = tlat 
        base_hiheff@lon2d = tlon 
     end if
  end if

  if (mask_low_aice) then
     if (ismissing(iaice)) then
        aice_dir = "/glade/p/cesm/pcwg/landrum/LE/ice/aice/"
        faice = aice_dir+"LE."+ncase+"sim."+month_names(imonth)+"_monthly_aice_nh."+nyr_stats+"yr_stats."+stats_yr1+"-"+stats_yr2+".nc"
        ib = base_yr1 - stats_yr1
        f = addfile(faice,"r")
        base_aice = f->stats(ib,0,:,:)
     else
        base_aice = base_var(iaice,:,:)
     end if
     do i=0,nvar-1
        base_var(i,:,:) = where(base_aice.gt.1.,base_var(i,:,:),base_var@_FillValue)		;mask out less than 1% aice
     end do
  end if
  if ((overlay_ailow).or.(overlay_aihigh)) then
     if (ismissing(iaice)) then
        aice_dir = "/glade/p/cesm/pcwg/landrum/LE/ice/aice/"
        faice = aice_dir+"LE."+ncase+"sim."+month_names(imonth)+"_monthly_aice_nh."+nyr_stats+"yr_stats."+stats_yr1+"-"+stats_yr2+".nc"
        ib = base_yr1 - stats_yr1
        f = addfile(faice,"r")
        base_aice = f->stats(ib,0,:,:)

        aice = new((/nplot,nj,ni/),float)

        do i=0,nplot-1
           ib = plot_yr1(i) - stats_yr1
           aice(i,:,:) = f->stats(ib,0,:,:)
        end do
     else
        base_aice = base_var(iaice,:,:)
        aice = mean_var(:,iaice,:,:)
     end if
     if (max(base_aice).lt.1.1) then
        base_aice = 100.*base_aice
        aice = 100.*aice
     end if
     base_aice@lat2d = tlat
     base_aice@lon2d = tlon
     aice@lat2d = tlat
     aice@lon2d = tlon
  end if

  base_4d = conform(mean_var,base_var,(/1,2,3/))
  diff_var = mean_var - base_4d

  if (plot_heff) then
        diff_heff = diff_var(:,iheff,:,:)
        diff_heff = where(abs(diff_heff).lt.0.005,diff_heff@_FillValue,diff_heff)          ;mask out less than 1% aice
        if (overlay_hsheff) then
           base_3d_hs = conform(mean_hs,base_hs,(/1,2/))
           diff_hs = mean_hs - base_3d_hs
           diff_hsheff = diff_hs/diff_heff
           diff_hsheff = where(diff_hsheff.lt.0.005,diff_hsheff@_FillValue,diff_hsheff)
           diff_hsheff@lat2d = tlat
           diff_hsheff@lon2d = tlon 
        end if

        if (overlay_hiheff) then
           base_3d_hi = conform(mean_hi,base_hi,(/1,2/))
           diff_hi = mean_hi - base_3d_hi
           diff_hiheff = diff_hi/diff_heff
           diff_hiheff = where(diff_hiheff.lt.0.005,diff_hiheff@_FillValue,diff_hiheff)
           diff_hiheff@lat2d = tlat
           diff_hiheff@lon2d = tlon
        end if
  end if
  base_var@lat2d = tlat
  base_var@lon2d = tlon
  mean_var@lat2d = tlat
  mean_var@lon2d = tlon
  diff_var@lat2d = tlat
  diff_var@lon2d = tlon

; ==============================================================
; resources for plotting
;-------------------------------------------------------------------------
  wks  = gsn_open_wks("pdf",psout)             ; open a ps file
;  wks  = gsn_open_wks("png",psout)             ; open a ps file
  gsn_define_colormap(wks,"ncl_default")

;  i = NhlNewColor(wks,0.7,0.7,0.7)              ; add gray to colormap
  plot = new(nvar*nplot,graphic)
  plot_var_mean = new(nvar,graphic)
  plot_15per = new(nvar*(nplot+1),graphic)
  plot_95per = new(nvar*(nplot+1),graphic)
  plot_hiheff = new(nvar*(nplot+1),graphic)
  plot_hsheff = new(nvar*(nplot+1),graphic)

;  n_colors_one = 16
  n_colors_one = 60
  n_colors_two = 101

  left_labels = (/"(a)","(b)","(c)","(d)","(e)","(f)"/)

  res                      = True                 ; plot mods desired
  res@gsnDraw              = False
  res@gsnFrame             = False
  res@cnFillOn             = True                 ; turn on color fill
  if (explicit_colors) then
     res@cnLevelSelectionMode = "ExplicitLevels" ; set manual contour levels
;     res@cnFillColors = (/2,3,4,5,6,7,8,9,10,11,12,13,14,15,16/)
     res@cnFillColors = (/2,6,10,14,18,22,26,30,34,38,42,46,50,54,58/)
  end if
  res@lbLabelAutoStride    = True                 ; control labelbar labels
  res@cnLinesOn            = False                ; turn off contour lines
  res@cnLineLabelsOn       = False              ; turn the line labels off

  res@lbLabelBarOn        = False      ; Turn off labelbar
  res@lbTitleOn        = True                  ; turn on title
  res@lbTitleFontHeightF= .015                 ; make title smaller
  res@lbTitlePosition = "Right"
  res@lbTitleDirection = "Across"

  res@cnInfoLabelOn       = False       ; Turn off informational label
  res@trGridType = "TriangularMesh"
  res@gsnStringFontHeightF = 0.03
;  res@gsnStringFontHeightF = 0.028
;  res@gsnStringFontHeightF = 0.15
  res@cnMonoLineThickness = True
  res@cnMonoLineDashPattern = True

;  res@gsnMaximize           = False         ; enlarge plot
; res@pmTickMarkDisplayMode = "Always"
  res@gsnLeftStringOrthogonalPosF = 0.03

  res@gsnAddCyclic = True

  res@gsnLeftString = ""
  res@gsnRightString = ""

  res@gsnPolar  = "NH"
  res@mpLandFillColor      = "grey"           ; choose color of continents.
  res@mpFillDrawOrder      = "PostDraw"       ; Fill continents later to cover up lines
  res@mpPerimDrawOrder     = "PostDraw"       ; Perimeter gets covered up by land
  res@mpMinLatF = 55.
  res@gsnPolarLabelSpacing = 30.
  ncntrs = 14

;  res@gsnLeftString    =  "Mean"
;  res@gsnRightString    =  base_yr1+"-"+base_yr2

  res15per = True
  res15per@gsnDraw          = False     ; don't draw
  res15per@gsnFrame         = False     ; don't advance frame
  res15per@cnInfoLabelOn    =  False
  res15per@gsnLeftString    =  ""
  res15per@gsnRightString    =  ""
  res15per@tiXAxisString    = ""
  res15per@tiYAxisString    = ""
  res15per@trGridType = "TriangularMesh"
  res15per@cnLineColor = "black"
  res15per@cnLineLabelsOn   = False     ; no line labels
  res15per@cnLevelSelectionMode =  "ExplicitLevels"
  res15per@cnLineThicknessF = 3.0       ; thicker contours

  reshratio = True
  reshratio = res15per
  reshratio@cnLevels = cont_hiheff_min
  reshratio@gsnContourPosLineDashPattern = 2       ; sets negative contours to dash pattern 1
  reshratio@cnLineThicknessF = 2.0       ; thicker contours
;  reshratio@cnLevels         =  (/0.5,0.6,0.7,0.8,0.9,1./)
;  reshratio@cnLevels         =  (/0.2,0.3,0.4,0.5/)
  opt                  = True			; options for shading contours
  opt@gsnShadeFillType = "Pattern"
  opt@gsnShadeHigh      = 17                      ; stippling pattern ...

  res15per@cnLevels         =  ai_low

  res95per = True
  res95per = res15per
  res95per@cnLevels = ai_high

;*********************************
; second plot
;*********************************
  res@cnLineColor      = "Blue"                   ; color of second contours
  res@cnLineThicknessF = 2.                       ; line thickness

  if (plot_mean) then
     do i=0,nvar-1
        res@lbTitleString    = units(i)
        res@gsnCenterString    =  var_name_titles(i)
        if (var_type(i).eq."aice")
           ai_cntrs=(/1,5,10,15,20,30,40,50, 60, 70, 80,90,95, 99/) ; aice
        else
           if (var_type(i).eq."h")
              ai_cntrs=(/0.05,0.1,0.25,0.5,0.75,1.0,1.5,2.0,2.5,3.0,3.5,4.0,4.5,5.0/) ; hi
           else
              if (var_type(i).eq."heff")
                 ai_cntrs=2.*(/0.05,0.1,0.25,0.5,0.75,1.0,1.5,2.0,2.5,3.0,3.5,4.0,4.5,5.0/) ; hi
              else
                 if (var_type(i).eq."SHF") then
                    ai_cntrs=2.*(/0.1,0.5,1.,2.,3.,4.0,5.,6.,7.,8.,9.,10.,11.,12./) ; fcondtop_ai
                 else
                    res@lbLabelBarOn        = True      ; Turn off labelbar
                    ai_cntrs = fspan(-42.,-3.,14)
                 end if
              end if
           end if
        end if
;        ai_cntrs=2.*(/0.05,0.1,0.25,0.5,0.75,1.0,1.5,2.0,2.5,3.0,3.5,4.0,4.5,5.0/) ; hi,kratio*hs,heff
        if (explicit_colors) then
           res@cnLevels = ai_cntrs
        end if
        plot_var_mean(i) = gsn_csm_contour_map_polar(wks,base_var(i,:,:),res)
        if (overlay_ailow) then
           plot_15per(i) = gsn_csm_contour(wks,base_aice,res15per)
           overlay(plot_var_mean(i), plot_15per(i))
        end if
        if (overlay_aihigh) then
           plot_95per(i) = gsn_csm_contour(wks,base_aice,res95per)
           overlay(plot_var_mean(i), plot_95per(i))
        end if
        if (var_type(i).eq."heff") then
           if (overlay_hiheff) then
              reshratio@cnLevels = cont_hiheff_min
              opt@gsnShadeHigh      = 3                      ; stripe pattern ...
              plot_hiheff(i) = gsn_csm_contour(wks,base_hiheff,reshratio)
              plot_hiheff(i) = gsn_contour_shade(plot_hiheff(i),-999,cont_hiheff_min,opt)   ; Shade contours above cont_hratio_min
              overlay(plot_var_mean(i), plot_hiheff(i))
           end if
           if (overlay_hsheff) then
              reshratio@cnLevels = cont_hsheff_min
              opt@gsnShadeHigh      = 17                      ; stippling pattern ...
              plot_hsheff(i) = gsn_csm_contour(wks,base_hsheff,reshratio)
              plot_hsheff(i) = gsn_contour_shade(plot_hsheff(i),-999,cont_hsheff_min,opt)   ; Shade contours above cont_hratio_min
              overlay(plot_var_mean(i), plot_hsheff(i))
           end if
        end if

     end do
  end if

  res@lbLabelBarOn        = False      ; Turn off labelbar

  pres = True
  pres@gsnFrame = False
  pres@txFontHeightF = 0.015
  pres@txString = "CESM1-CAM5 LE ~C~"+month_names(imonth)+" ("+base_yr1+"-"+base_yr2+")"
  pres@gsnMaximize     = True                 ; fill up the page
  pres@gsnPanelLabelBar  = False
  pres@lbTitleFontHeightF = 0.018
  pres@lbTitlePosition = "Right"
  pres@lbTitleDirection = "Across"
  pres@gsnPanelMainFont = "helvetica"
  if (plot_mean) then
     pres@gsnPanelLabelBar  = True
     pres@gsnPanelTop = 0.9
     pres@gsnPanelBottom   = 0.6
     gsn_panel(wks,plot_var_mean,(/1,nvar/),pres)
  end if

  res@lbLabelBarOn        = False      ; Turn off labelbar

  if (explicit_colors) then
     delete(res@cnLevels)
     delete(res@cnFillColors)

     res@cnFillColors = ispan(2,255,11)
;     res@cnFillColors = (/2, 2, 2, 2, 2, 2, 2, 2,6,10,14,18,22,26,30,34,38,42,46,50,54,58/)
     delta_cntrs=(/-5.5,-5.,-4.5,-4.,-3.5,-3.,-2.5,-2,-1.5,-1.,-0.5,0.,1.,2.,3.,4.,5.,6.,7.,8.,9.,10.,11./) ; hi
     res@cnLevels = delta_cntrs

;     delete(res@cnLevelSelectionMode)
  else
     ncntrs = 28
     color_start              = 2			; Tsfc, fcond
     color_end                = 254
     res@gsnSpreadColors     = True              ; use full colormap
     res@gsnSpreadColorStart  = color_start
     res@gsnSpreadColorEnd    = color_end-1
     res@cnLevelSelectionMode = "ManualLevels"     ; set manual contour levels

     minXY   = -10.
     maxXY   = 10.
     mnmxint = nice_mnmxintvl( minXY, maxXY, ncntrs, False)
;     print("Contouring for hi, kratio*hi, heff from "+mnmxint(0)+" to "+ mnmxint(1)+" by "+mnmxint(2))

     res@cnMinLevelValF       = mnmxint(0)
     res@cnMaxLevelValF       = mnmxint(1)
     res@cnLevelSpacingF      = mnmxint(2)
  end if

  do i=0,nplot-1
;     res@gsnLeftString =  "("+plot_yr1(i)+"-"+plot_yr2(i)+")"
     res@gsnCenterString    =  ""
     res@gsnRightString    =  ""

     do j=0,nvar-1
        if (i.eq.0) then
           res@gsnCenterString    =  left_labels(3*i+j)+" "+var_name_titles(j) + " ("+units(j)+")"
        else
           res@gsnCenterString =  left_labels(3*i+j)
        end if

        plot(nvar*i+j) = gsn_csm_contour_map_polar(wks,diff_var(i,j,:,:),res)
        if (overlay_ailow) then
           plot_15per(nvar*(i+1)+j) = gsn_csm_contour(wks,aice(i,:,:),res15per)
           overlay(plot(nvar*i+j),plot_15per(nvar*(i+1)+j))
        end if
        if (overlay_aihigh) then
           plot_95per(nvar*(i+1)+j) = gsn_csm_contour(wks,aice(i,:,:),res95per)
           overlay(plot(nvar*i+j),plot_95per(nvar*(i+1)+j))
        end if
        if (var_type(j).eq."heff") then
           if (overlay_hiheff) then
              reshratio@cnLevels = cont_hiheff_min
              opt@gsnShadeHigh      = 3                      ; stripe pattern ...
              plot_hiheff(nvar*(i+1)+j) = gsn_csm_contour(wks,diff_hiheff(i,:,:),reshratio)
              plot_hiheff(nvar*(i+1)+j) = gsn_contour_shade(plot_hiheff(nvar*(i+1)+j),-999,cont_hiheff_min, opt)   ; Shade contours above cont_hiheff_min
              overlay(plot(nvar*i+j), plot_hiheff(nvar*(i+1)+j))
           end if
           if (overlay_hsheff) then
              reshratio@cnLevels = cont_hsheff_min
              opt@gsnShadeHigh      = 17                      ; stippling pattern ...
              plot_hsheff(nvar*(i+1)+j) = gsn_csm_contour(wks,diff_hsheff(i,:,:),reshratio)
              plot_hsheff(nvar*(i+1)+j) = gsn_contour_shade(plot_hsheff(nvar*(i+1)+j),-999,cont_hsheff_min, opt)   ; Shade contours above cont_hiheff_min
              overlay(plot(nvar*i+j), plot_hsheff(nvar*(i+1)+j))
           end if
        end if
        res@gsnLeftString = ""
     end do
  end do

   if (plot_mean) then
      pres@gsnPanelTop = pres@gsnPanelBottom - 0.06
      pres@gsnPanelBottom   = 0.1
   else 
      pres@gsnPanelTop = 0.9
   end if

   pres@gsnPanelBottom   = 0.56
   pres@txString = month_names(imonth)+"~C~("+plot_yr1(0)+"-"+plot_yr2(0)+") - ("+base_yr1+"-"+base_yr2+")"
   pres@gsnPanelLabelBar  = False                                        ; just for hs, hi, heff
   gsn_panel(wks,plot(:nvar-1),(/1,nvar/),pres)

   pres@gsnPanelTop = pres@gsnPanelBottom - 0.06
   pres@gsnPanelBottom   = 0.1

   pres@txString = "("+plot_yr1(1)+"-"+plot_yr2(1)+") - ("+base_yr1+"-"+base_yr2+")"
   pres@gsnPanelLabelBar  = True                                        ; just for hs, hi, heff
   gsn_panel(wks,plot(nvar:),(/1,nvar/),pres)
 
   frame(wks)

end
