; removed SIC, SIT plots...and changed to plot
; d(fcond)/d(netSHF)
;
; March 2021
;
; Contours mean and changes in net surface heat flux for ice,
; ocean, ice+ocean and fcondtop_ai in user-defined region
; for each month (CESM1-CAM5 LE). Also contours proportion of
; total net surface heat flux from ice, ocn, and fcondtop_ai.
;
; LLandrum
; Feb 2021
;===============================================;
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"   
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"   
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/shea_util.ncl"
;load "/glade/u/home/landrum/ncl/asphilli_util.ncl"
; ================================================;
begin
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

  season = "cold"			; annual for entire year, cold for Oct-Nov-Dec-Jan-Feb-Mar, warm for Apr-May-Jun-Jul-Aug-Sep
  remove_mn = False			; True to plot after removing mean
  nyr_mean = 20				; # yrs to use for mean to calculate changes from
  plot_area_avg = True			; True to plot as area average (W/m2), False to plot as area total 
					; NOTE fcondtop are saved as area averages so will need to multiply by area if
					; not plotting as area averages

  pos2atm = True			; True indicates SHF should be plotting as positive indicating heat flux from ocn/ice into atm. 

  ice_var = (/"surf_ai","fcondtop_ai"/)
  ifcond = ind(ice_var.eq."fcondtop_ai")
  isurf = ind(ice_var.eq."surf_ai")
  nice_var = dimsizes(ice_var)

  ocn_var_names = (/"SHF","MELTH_F","swthru_ai","net ocn SHF"/)		; using all three as net ocean SHF needs melt_f and swthru_ai subtracted....
  nnames = dimsizes(ocn_var_names)
  ocn_var = ocn_var_names(:nnames-2)
  nocn_var = dimsizes(ocn_var)
  iSHF = ind(ocn_var.eq."SHF")				; to convert to same units as others
  iMELT = ind(ocn_var.eq."MELTH_F")
  iswthru = ind(ocn_var.eq."swthru_ai")

  datadir = "/glade/p/cesm/pcwg/landrum/LE/shf/"
  f20th_Tsfc = datadir+"ice/Tsfc/ice_Tsfc_MHolland_regions_"+LE_20thC_case+scnumbers+"_"+yr1_20th+"-"+yr2_20th+".nc"
  frcp_Tsfc = datadir+"ice/Tsfc/ice_Tsfc_MHolland_regions_"+LE_rcp_case+scnumbers+"_"+yr1_rcp+"-"+yr2_rcp+".nc"
  f20th_ice_SHF = datadir+"ice/SHF/ice_SHF_MHolland_regions_"+LE_20thC_case+scnumbers+"_"+yr1_20th+"-"+yr2_20th+".nc"
  frcp_ice_SHF = datadir+"ice/SHF/ice_SHF_MHolland_regions_"+LE_rcp_case+scnumbers+"_"+yr1_rcp+"-"+yr2_rcp+".nc"
  f20th_fcond = datadir+"ice/fcondtop/ice_fcondtop_ai_MHolland_regions_"+LE_20thC_case+scnumbers+"_"+yr1_20th+"-"+yr2_20th+".nc"
  frcp_fcond = datadir+"ice/fcondtop/ice_fcondtop_ai_MHolland_regions_"+LE_rcp_case+scnumbers+"_"+yr1_rcp+"-"+yr2_rcp+".nc"

  f20th_ocn = datadir+"ocn/ocn_SHF_MHolland_regions_"+LE_20thC_case+scnumbers+"_"+yr1_20th+"-"+yr2_20th+".nc"
  frcp_ocn = datadir+"ocn/ocn_SHF_MHolland_regions_"+LE_rcp_case+scnumbers+"_"+yr1_rcp+"-"+yr2_rcp+".nc"

  ice_datadir = "/glade/p/cesm/pcwg/landrum/LE/ice/pre_process/monthly/"
  f20th_vai = ice_datadir+"ice_vol_MHolland_regions_"+LE_20thC_case+scnumbers+"_"+yr1_20th+"-"+yr2_20th+".nc"
  frcp_vai = ice_datadir+"ice_vol_MHolland_regions_"+LE_rcp_case+scnumbers+"_"+yr1_rcp+"-"+yr2_rcp+".nc"

  CMIP5_dir = "/glade/p/cesm/pcwg/landrum/CMIP5/MMLE/"
  farea = CMIP5_dir+"ice/cesm/CESM1-CAM5_regional_areavg.nc"

  plot_yr1 = 2000
;  plot_yr2 = 2100
  plot_yr2 = 2070

  region = "CArc"                  ; nh,CArc,Lab,GIN,Bar,ArcOc,Sib,Beau,Bering,Okhotsk,Chukchi,Kara,Laptev
  month_names = (/"JAN","FEB","MAR","APR","MAY","JUN","JUL","AUG","SEP","OCT","NOV","DEC"/)

  psout = "Figure4.contour.T_netSHF_month_year."+region+"."+season

  if (remove_mn) then
     psout = psout+".mn_rmvd"
  end if
  if (plot_area_avg) then
     psout = psout+".area_avg"
  end if
;---------------------------------------------------------------------------------
; read in LE data
;---------------------------------------------------------------------------------
  LE_Tsfc = new((/ncase,12,nyr/),float)                ; each ensemble member, Walsh extended and NSIDC ice index
  LE_Tsfc!0 = "case"
  LE_Tsfc!1 = "month"
  LE_Tsfc&month = ispan(1,12,1)
  LE_Tsfc!2 = "year"
  LE_Tsfc&year = year

  LE_SHF_ice = new((/nice_var,ncase,12,nyr/),float)
  LE_SHF_ice!0 = "variable"
  LE_SHF_ice!1 = "case"
  LE_SHF_ice!2 = "month"
  LE_SHF_ice&month = ispan(1,12,1)
  LE_SHF_ice!3 = "year"
  LE_SHF_ice&year = year

  LE_SHF_ocn = new((/nocn_var+1,ncase,12,nyr/),float)
  LE_SHF_ocn!0 = "variable"
  LE_SHF_ocn!1 = "case"
  LE_SHF_ocn!2 = "month"
  LE_SHF_ocn&month = ispan(1,12,1)
  LE_SHF_ocn!3 = "year"
  LE_SHF_ocn&year = year

  LE_vai = new((/2,ncase,12,nyr/),float)                ; for ice area and ice volume
  LE_vai!0 = "variable"
  LE_vai!1 = "case"
  LE_vai!2 = "month"
  LE_vai&month = ispan(1,12,1)
  LE_vai!3 = "year"
  LE_vai&year = year

  i2 = yr2_20th - yr1_20th
  do i = 0,ncase-1
     f1 = addfile(f20th_ice_SHF(i),"r")
     f2 = addfile(frcp_ice_SHF(i),"r")

     f3 = addfile(f20th_ocn(i),"r")
     f4 = addfile(frcp_ocn(i),"r")

     f5 = addfile(f20th_fcond(i),"r")
     f6 = addfile(frcp_fcond(i),"r")

     f7 = addfile(f20th_vai(i),"r")
     f8 = addfile(frcp_vai(i),"r")

     f9 = addfile(f20th_Tsfc(i),"r")
     f10 = addfile(frcp_Tsfc(i),"r")

     do iv=0,nice_var-1
        if (iv.eq.ifcond) then
           var_name = ice_var(iv)+"_avg_mo_"+region
           do im=0,11
                 LE_SHF_ice(iv,i,im,:i2) = (/ f5->$var_name$(im::12) /)
                 LE_SHF_ice(iv,i,im,i2+1:) = (/ f6->$var_name$(im::12) /)
           end do
        else
           var_name = "HF_"+ice_var(iv)+"_mo_"+region
           do im=0,11
                 LE_SHF_ice(iv,i,im,:i2) = (/ f1->$var_name$(im::12) /)
                 LE_SHF_ice(iv,i,im,i2+1:) = (/ f2->$var_name$(im::12) /)
           end do
        end if
     end do
     do iv=0,nocn_var-1
        var_name = "HF_"+ocn_var(iv)+"_mo_"+region
        if ((region.eq."nh").and.(ocn_var(iv).eq."SHF")) then
              var_name = "HF_"+ocn_var(iv)+"_mo_"+region+"50_90"                ; limit to high lat NH
        end if
        do im=0,11
              LE_SHF_ocn(iv,i,im,:i2) = (/ f3->$var_name$(im::12) /)
              LE_SHF_ocn(iv,i,im,i2+1:) = (/ f4->$var_name$(im::12) /)
        end do
     end do

     var_name0 = "vai_mo_"+region					; ice area and volume data
     var_name1 = "vhi_mo_"+region
     var_name2 = "Tsfc_avg_mo_"+region
     do im=0,11
        LE_vai(0,i,im,:i2) = (/ f7->$var_name0$(im::12) /)
        LE_vai(0,i,im,i2+1:) = (/ f8->$var_name0$(im::12) /)
        LE_vai(1,i,im,:i2) = (/ f7->$var_name1$(im::12) /)
        LE_vai(1,i,im,i2+1:) = (/ f8->$var_name1$(im::12) /)

        LE_Tsfc(i,im,:i2) = (/ f9->$var_name2$(im::12) /)
        LE_Tsfc(i,im,i2+1:) = (/ f10->$var_name2$(im::12) /)
     end do

  end do
  if (.not.(ismissing(iSHF))) then
     LE_SHF_ocn(iSHF,:,:,:) = 100.*LE_SHF_ocn(iSHF,:,:,:)                                 ; makes all units of W x 1.E+12
  end if

  if (plot_area_avg) then                                ; divide by regional area avg
     f3 = addfile(farea,"r")
     avg_name = "area_"+region
     area_avg = 10.*(f3->$avg_name$)                   ; units are now 1.E+12 m2
     if (ismissing(ifcond)) then
        LE_SHF_ice = LE_SHF_ice/area_avg           ; units are now W/m2 except swdn and lwdn which will be 1.E+3 W/m2
     else
        do ivar=0,nice_var-1
           if (ivar.ne.ifcond) then
              LE_SHF_ice(ivar,:,:,:) = LE_SHF_ice(ivar,:,:,:)/area_avg  ; units are now W/m2 except swdn and lwdn which will be 1.E+3 W/m2
           end if
        end do
     end if
     LE_SHF_ocn = LE_SHF_ocn/area_avg              ; units are now W/m2 except swdn and lwdn which will be 1.E+3 W/m2
     LE_vai(0,:,:,:) = 100.*LE_vai(0,:,:,:)/area_avg                      ; units are now % and m
     LE_vai(1,:,:,:) = 10.*LE_vai(1,:,:,:)/area_avg                      ; double check hi
  else
     if (.not.(ismissing(ind_fcondtop))) then
        f3 = addfile(farea,"r")
        avg_name = "area_"+region
        area_avg = 10.*(f3->$avg_name$)                   ; units are now 1.E+12 m2
        LE_SHF_ice(ifcond,:,:,:) = LE_SHF_ice(ifcond,:,:,:)*area_avg  ; units are now W
        LE_SHF_ice(ifcond,:,:,:) = LE_SHF_ice(ifcond,:,:,:)*1.0e-12      ; units are now 1.E+12 W
     end if
  end if

  SHF = LE_SHF_ocn(iSHF,:,:,:)
  MELTH_F = LE_SHF_ocn(iMELT,:,:,:)
  fswthru = LE_SHF_ocn(iswthru,:,:,:)

  LE_SHF_ocn(nocn_var,:,:,:) = SHF - MELTH_F - fswthru                        ; ocn total
  nocn_var = nocn_var + 1                            ; for plots

  netSHF = LE_SHF_ice(isurf,:,:,:)
  netSHF = LE_SHF_ice(isurf,:,:,:) + LE_SHF_ocn(nocn_var-1,:,:,:)
;---------------------------------------------------------------------------------
; calculate ensemble mean, min, max
;---------------------------------------------------------------------------------
  LE_mn_SHF_ice = dim_avg_n_Wrap(LE_SHF_ice,1)
  min_SHF_ice = dim_min_n_Wrap(LE_SHF_ice,1)
  max_SHF_ice = dim_max_n_Wrap(LE_SHF_ice,1)

  LE_mn_SHF_ocn = dim_avg_n_Wrap(LE_SHF_ocn,1)
  min_SHF_ocn = dim_min_n_Wrap(LE_SHF_ocn,1)
  max_SHF_ocn = dim_max_n_Wrap(LE_SHF_ocn,1)

  LE_mn_netSHF = dim_avg_n_Wrap(netSHF,0)

  delta_SHF_ice = LE_mn_SHF_ice
  mnSHF_ice = dim_avg_n(LE_mn_SHF_ice(:,:,:nyr_mean-1),2)
  delta_SHF_ice = LE_mn_SHF_ice - conform(delta_SHF_ice,mnSHF_ice,(/0,1/))
  delete(mnSHF_ice)

  delta_SHF_ocn = LE_mn_SHF_ocn
  mnSHF_ocn = dim_avg_n(LE_mn_SHF_ocn(:,:,:nyr_mean-1),2)
  delta_SHF_ocn = LE_mn_SHF_ocn - conform(delta_SHF_ocn,mnSHF_ocn,(/0,1/))
  delete(mnSHF_ocn)

  delta_netSHF = LE_mn_netSHF
  mnSHF_net = dim_avg_n(LE_mn_netSHF(:,:nyr_mean-1),1)
  delta_netSHF = LE_mn_netSHF - conform(delta_netSHF,mnSHF_net,(/0/))
  delete(mnSHF_net)

  tmp_LE_mn_vai = dim_avg_n_Wrap(LE_vai,1)

  LE_mn_Tsfc = dim_avg_n_Wrap(LE_Tsfc,0)
  delta_Tsfc = LE_mn_Tsfc
  mnTsfc = dim_avg_n(LE_mn_Tsfc(:,:nyr_mean-1),1)
  delta_Tsfc= LE_mn_Tsfc - conform(delta_Tsfc,mnTsfc,(/0/))
  delete(mnTsfc)
;---------------------------------------------------------------------------------
; change for season if necessary
;---------------------------------------------------------------------------------
  if (season.ne."annual")
     delta_netSHF_season = delta_netSHF(3:8,:)			; for warm season
     delta_SHF_ice_season = delta_SHF_ice(:,3:8,:)
     delta_SHF_ocn_season = delta_SHF_ocn(:,3:8,:)

     LE_mn_SHF_ice_season = LE_mn_SHF_ice(:,3:8,:)
     LE_mn_SHF_ocn_season = LE_mn_SHF_ocn(:,3:8,:)
     LE_mn_netSHF_season = LE_mn_netSHF(3:8,:)

     LE_mn_vai = tmp_LE_mn_vai(:,3:8,:)                       ; for warm season

     LE_mn_Tsfc_season = LE_mn_Tsfc(3:8,:)                    ; for warm season
     delta_Tsfc_season = delta_Tsfc(3:8,:)                    ; for warm season

     YAxisLabels = month_names(3:8)

     if (season.eq."cold") then
        delta_netSHF_season(:2,1:) = delta_netSHF(9:,:nyr-2)                 ; OctNovDec
        delta_netSHF_season(3:,:) = delta_netSHF(:2,:)                       ; JanFebMar
        delta_netSHF_season(:2,0) = delta_netSHF@_FillValue                           ; making years for plotting OctNovDec - yr1, JanFebMar - yr2

        LE_mn_netSHF_season(:2,1:) = LE_mn_netSHF(9:,:nyr-2)                 ; OctNovDec
        LE_mn_netSHF_season(3:,:) = LE_mn_netSHF(:2,:)                       ; JanFebMar
        LE_mn_netSHF_season(:2,0) = LE_mn_netSHF@_FillValue                           ; making years for plotting OctNovDec - yr1, JanFebMar - yr2

        delta_SHF_ice_season(:,:2,1:) = delta_SHF_ice(:,9:,:nyr-2)
        delta_SHF_ice_season(:,3:,:) = delta_SHF_ice(:,:2,:)
        delta_SHF_ice_season(:,:2,0) = delta_netSHF@_FillValue                           

        LE_mn_SHF_ice_season(:,:2,1:) = LE_mn_SHF_ice(:,9:,:nyr-2)
        LE_mn_SHF_ice_season(:,3:,:) = LE_mn_SHF_ice(:,:2,:)                       
        LE_mn_SHF_ice_season(:,:2,0) = LE_mn_netSHF@_FillValue

        delta_SHF_ocn_season(:,:2,1:) = delta_SHF_ocn(:,9:,:nyr-2)                 
        delta_SHF_ocn_season(:,3:,:) = delta_SHF_ocn(:,:2,:)                       
        delta_SHF_ocn_season(:,:2,0) = delta_netSHF@_FillValue

        LE_mn_SHF_ocn_season(:,:2,1:) = LE_mn_SHF_ocn(:,9:,:nyr-2)
        LE_mn_SHF_ocn_season(:,3:,:) = LE_mn_SHF_ocn(:,:2,:)                           
        LE_mn_SHF_ocn_season(:,:2,0) = LE_mn_netSHF@_FillValue

        LE_mn_vai(:,:2,1:) = tmp_LE_mn_vai(:,9:,:nyr-2)                 ; OctNovDec
        LE_mn_vai(:,:2,0) = LE_mn_vai@_FillValue                              ; making years for plotting OctNovDec - yr1, JanFebMar - yr2
        LE_mn_vai(:,3:,:) = tmp_LE_mn_vai(:,:2,:)                       ; JanFebMar

        LE_mn_Tsfc_season(:2,1:) = LE_mn_Tsfc(9:,:nyr-2)                 ; OctNovDec
        LE_mn_Tsfc_season(3:,:) = LE_mn_Tsfc(:2,:)                       ; JanFebMar
        LE_mn_Tsfc_season(:2,0) = LE_mn_Tsfc@_FillValue                           ; making years for plotting OctNovDec - yr1, JanFebMar - yr2

        delta_Tsfc_season(:2,1:) = delta_Tsfc(9:,:nyr-2)                 ; OctNovDec
        delta_Tsfc_season(3:,:) = delta_Tsfc(:2,:)                       ; JanFebMar
        delta_Tsfc_season(:2,0) = delta_Tsfc@_FillValue                           ; making years for plotting OctNovDec - yr1, JanFebMar - yr2

        YAxisLabels(:2) = month_names(9:)
        YAxisLabels(3:) = month_names(:2)

        delta_netSHF_season&month = ispan(1,6,1)
        delta_SHF_ice_season&month = ispan(1,6,1)
        delta_SHF_ocn_season&month = ispan(1,6,1)

        LE_mn_netSHF_season&month = ispan(1,6,1)
        LE_mn_SHF_ice_season&month = ispan(1,6,1)
        LE_mn_SHF_ocn_season&month = ispan(1,6,1)

        LE_mn_Tsfc_season&month = ispan(1,6,1)
        delta_Tsfc_season&month = ispan(1,6,1)

        LE_mn_vai&month = ispan(1,6,1)

     end if
  else
     delta_netSHF_season = delta_netSHF
     delta_SHF_ice_season = delta_SHF_ice
     delta_SHF_ocn_season = delta_SHF_ocn
     
     LE_mn_SHF_ice_season = LE_mn_SHF_ice
     LE_mn_SHF_ocn_season = LE_mn_SHF_ocn
     LE_mn_netSHF_season = LE_mn_netSHF

     LE_mn_vai = tmp_LE_mn_vai

     LE_mn_Tsfc_season = LE_mn_Tsfc
     delta_Tsfc_season = delta_Tsfc

     YAxisLabels = month_names
  end if
;---------------------------------------------------------------------------------
; change sign such that + is from ocean/ice to atmosphere
; and positive changes indicate increased heat flux to atm.
;---------------------------------------------------------------------------------
  if (pos2atm) then
     delta_netSHF_season = -1.*delta_netSHF_season
     delta_SHF_ice_season = -1.*delta_SHF_ice_season
     delta_SHF_ocn_season = -1.*delta_SHF_ocn_season

     LE_mn_SHF_ice_season = -1.*LE_mn_SHF_ice_season
     LE_mn_SHF_ocn_season = -1.*LE_mn_SHF_ocn_season
     LE_mn_netSHF_season = -1.*LE_mn_netSHF_season
  end if
;---------------------------------------------------------------------------------
; plot
;---------------------------------------------------------------------------------
  wks  = gsn_open_wks("pdf",psout)

;  gsn_define_colormap(wks,"BlWhRe")

  plot_50per = new(2,graphic)
  plot_70per = new(2,graphic)
  plot_90per = new(5,graphic)
  plot_98per = new(5,graphic)

  res = True				; res for stats plot
  res@gsnDraw = False
  res@gsnFrame = False
  res@cnFillOn            = True          ; turn on color
  res@cnInfoLabelOn   = False
  res@cnLinesOn            = False                ; turn off contour lines
  res@cnLineLabelsOn       = False              ; turn the line labels off

;  res@vpWidthF    = 0.5      ; Make plots wider than
;  res@vpHeightF   = 0.2      ; they are high.

  res@vpWidthF    = 0.4      ; Make plots wider than
  res@vpHeightF   = 0.19      ; they are high.

  res@tiXAxisString = " "
  res@trXMinF = plot_yr1
  res@trXMaxF = plot_yr2

  res@tiYAxisString    = "month"
  res@tmYLMode        = "Explicit"	
  res@tmYLValues      = delta_netSHF_season&month
  res@tmYLLabels      = YAxisLabels

  res@lbLabelBarOn        = True
  res@lbTitleOn        =  True                ; turn on title
  res@lbTitlePosition  = "Right"              ; title position
  res@lbTitleFontHeightF= .015                ; make title smaller
  res@lbTitleDirection = "Across"             ; title direction

  res@gsnLeftString    = " "
  res@gsnRightString = " "
;  res@gsnRightString    =  region
  res@cnFillPalette  = "cmocean_amp"

  res_T = True
  res_T = res
  res_T@lbTitleString = "~S~o~N~C"

  if (plot_area_avg) then
     res@lbTitleString    = "W m~S~-2"                ; title string
  else
     res@lbTitleString    = "W (x10~S~12~N~)"                ; title string
  end if

  res90per = True
  res90per@gsnDraw          = False     ; don't draw
  res90per@gsnFrame         = False     ; don't advance frame
  res90per@cnLevelSelectionMode =  "ExplicitLevels"
  res90per@cnInfoLabelOn    =  False
  res90per@gsnLeftString    =  ""
  res90per@gsnRightString    =  ""
  res90per@cnLevels         =  (/90./)
  res90per@tiXAxisString    = ""
  res90per@tiYAxisString    = ""
  res90per@cnLineThicknessF = 3.0       ; thicker contours
  res90per@cnLineLabelsOn   = False     ; no line labels
  res90per@cnLineColor = "white"

  res98per = True
  res98per = res90per
  res98per@cnLevels         =  (/98./)
  res98per@cnLineThicknessF = 1.0       ; thicker contours
  res98per@cnLineDashPattern = 1

  res_T@gsnLeftString    = "(a) Tsfc "
  plot_T  = gsn_csm_contour(wks,delta_Tsfc_season,res_T)
  plot_90per(0) = gsn_csm_contour(wks,LE_mn_vai(0,:,:),res90per)
  overlay(plot_T, plot_90per(0))
  plot_98per(0) = gsn_csm_contour(wks,LE_mn_vai(0,:,:),res98per)
  overlay(plot_T, plot_98per(0))

  denom = delta_netSHF_season
  res@gsnLeftString    = "(b) Net surface heat flux (positive = from ocn/ice to atm)"
  plot_SHF  = gsn_csm_contour(wks,denom,res)
  plot_90per(1) = gsn_csm_contour(wks,LE_mn_vai(0,:,:),res90per)
  overlay(plot_SHF, plot_90per(1))
  plot_98per(1) = gsn_csm_contour(wks,LE_mn_vai(0,:,:),res98per)
  overlay(plot_SHF, plot_98per(1))

  res@cnFillPalette  = "cmocean_balance"

  ncntrs = 30
;  ncntrs = 19
  minXY   = -1.
  maxXY   = 1.
  mnmxint = nice_mnmxintvl( minXY, maxXY, ncntrs, False)
  res@cnLevelSelectionMode = "ManualLevels"     ; set manual contour levels
  res@cnMinLevelValF       = mnmxint(0)
  res@cnMaxLevelValF       = mnmxint(1)
  res@cnLevelSpacingF      = mnmxint(2)

  res@lbTitleString    = " "

  plot_var = delta_SHF_ice_season(ifcond,:,:)
  plot_ratio = plot_var
  plot_ratio = (/ plot_var/denom /)
  res@gsnLeftString    = "(c) d(Fcond)/d(netSHF)"
  plot_R = gsn_csm_contour(wks,plot_ratio,res)
  plot_90per(2) = gsn_csm_contour(wks,LE_mn_vai(0,:,:),res90per)
  overlay(plot_R, plot_90per(2))
  plot_98per(2) = gsn_csm_contour(wks,LE_mn_vai(0,:,:),res98per)
  overlay(plot_R, plot_98per(2))

  yr1_mean = yr1_20th
  yr2_mean = yr1_20th + nyr_mean - 1

  pres = True
  pres@gsnFrame = False
  pres@gsnPanelMainFont = "helvetica"
  pres@gsnPanelMainFontHeightF = 0.016

;  pres@gsnPanelTop = 0.9
;  pres@gsnPanelBottom   = 0.65
  pres@gsnPanelLabelBar  = False

  if (season.eq."cold") then
     pres@gsnPanelMainString = "Oct-Mar ~C~changes from "+yr1_mean+"-"+yr2_mean
  else
     pres@gsnPanelMainString = "Apr-Sep ~C~changes from "+yr1_mean+"-"+yr2_mean
  end if
;  gsn_panel(wks,plot_T,(/1,1/),pres)
  gsn_panel(wks,(/plot_T,plot_SHF,plot_R/),(/3,1/),pres)

  pres@gsnPanelMainString = " "

;  pres@gsnPanelTop = 0.6
;  pres@gsnPanelBottom   = 0.35
;  pres@gsnPanelMainString = "Net Surface Heat Flux ~C~ ~Z85~ (positive = from ocn/ice to atm)"
;  gsn_panel(wks,plot_SHF,(/1,1/),pres)

;  pres@gsnPanelTop = 0.3
;  pres@gsnPanelBottom   = 0.05
;  pres@gsnPanelMainString = "d(Fcond)/d(netSHF)"
;  gsn_panel(wks,plot_R,(/1,1/),pres)

  frame(wks)
end

