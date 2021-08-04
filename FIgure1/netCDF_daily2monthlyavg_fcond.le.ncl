; Corrected for _ai misunderstanding.
; Notes:
; In order to get calcuated fcondtop_ai, need to first calculate fcondtop
; over the ice area then multiply by aice for fcondtop_ai (which is weighted
; by aice).
; hi, hs are grid cell means - need to divide by aice to get thickness of ice
; and snow over the ice covered areas. Likewise vicen00x (and vsnon00x although
; this variable was not saved in CESM1-CAM5 LENS) are
; volumes (expressed in m) over entire grid cell and also need to be divided
; by aicen00x in order to get the thickness within each category.
; November 2020
;
; Calculates monthly average fcondtop from daily hs, hi, ai and TS. Daily Tsfc 
; was not saved in LENS so using TS. This will introduce errors - although lowest
; errors will be far away from coasts (which have larger errors due to regridding)
; and over high aice.
;
; LLandrum
; October 2020
;----------------------------------------------------------------------------------
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/shea_util.ncl"
;load "/home/landrum/ncl/landrum_util.ncl"
load "/glade/u/home/landrum/ncl/landrum_util.ncl"

begin
; ==============================================================
; parameters
; ==============================================================
   kseaice = 2.0                           ; conductivity of sea ice in W/m/degK
   ksnow = 0.3                             ; conductivity of snow in W/m/degK
   kratio = kseaice/ksnow
   Tbot = -1.8                          ; temperature at the bottom of the ice

   hem = "nh"
;-------------------------------------------------------------------------
; LE files..
;-------------------------------------------------------------------------
   LE_20thC_case = "b.e11.B20TRC5CNBDRD.f09_g16."
   LE_rcp_case = "b.e11.BRCP85C5CNBDRD.f09_g16."
;   case_numbers = ispan(1,40,1)
;   case_numbers(35:) = ispan(101,105,1)
   case_numbers = ispan(1,33,1)
   scnumbers = sprinti("%0.3i",case_numbers)

   c20thC_case = LE_20thC_case+ scnumbers
   rcp85_case = LE_rcp_case+scnumbers

;   case_names = c20thC_case
   case_names = rcp85_case
   ncase = dimsizes(case_names)

   atm_tseries_dir = "/glade/collections/cdg/data/cesmLE/CESM-CAM5-BGC-LE/atm/proc/tseries/"
   ice_tseries_dir = "/glade/collections/cdg/data/cesmLE/CESM-CAM5-BGC-LE/ice/proc/tseries/"
   out_dir = "/glade/p/cesm/pcwg/landrum/LE/ice/fcondtop_ai/calcs/daily2monthly/"

   yr1 = new(ncase,integer)
;   yr1 = 1920
;   yr1 = 2006                                                    ; start and end yrs for time series
   yr1 = 2081
;   yr1(0) = 1850
;   yr1(33:) = 2006
   yr2 = yr1
;   yr2 = 2005
;   yr2 = 2080
   yr2 = 2100
;   yr2(33:) = 2100
;   yr2(5:) = 2100

   dstyrs = sprinti("%0.4i",yr1) + "0101-"+sprinti("%0.4i",yr2)+"1231"
   mstyrs = sprinti("%0.4i",yr1) + "01-"+sprinti("%0.4i",yr2)+"12"

   fai = ice_tseries_dir+"daily/aice_d/"+case_names+".cice.h1.aice_d_"+hem+"."+dstyrs+".nc"
   fhi = ice_tseries_dir+"daily/hi_d/"+case_names+".cice.h1.hi_d_"+hem+"."+dstyrs+".nc"
   fhs = ice_tseries_dir+"daily/hs_d/"+case_names+".cice.h1.hs_d_"+hem+"."+dstyrs+".nc"
   fTS = atm_tseries_dir+"daily/TS/"+case_names+".cam.h1.TS."+dstyrs+".nc"
   ffcondtop_ai = ice_tseries_dir+"monthly/fcondtop_ai/"+case_names+".cice.h.fcondtop_ai_"+hem+"."+mstyrs+".nc"
   faice = ice_tseries_dir+"monthly/aice/"+case_names+".cice.h.aice_"+hem+"."+mstyrs+".nc"

   ndays_per_month = (/31,28,31,30,31,30,31,31,30,31,30,31/)
   month_jday = ndays_per_month
   month_jday = 1
   do i=1,11
      month_jday(i) = month_jday(i-1)+ndays_per_month(i-1)  ; 1-365
   end do
   imonth_jday = month_jday - 1				; 0-364

   fcond_out = out_dir+case_names+".daily2monthly_fcondtop_ai_"+hem+"."+mstyrs+".nc"
;-------------------------------------------------------------------------
; info for regridding
;-----------------------------------------------------------------------
  ocn_grid = "gx1v6"
  atm_grid = "fv0.9x1.25"
  method = "bilinear"                                   ; this is default

  grid_in = atm_grid
  grid_out = ocn_grid

  ocn_grid_file = "/glade/p/cesm/omwg/grids/"+ocn_grid+"_grid.nc"
  ocn_grid_data = addfile(ocn_grid_file,"r")
  tlat_all = ocn_grid_data->TLAT
  tlon_all = ocn_grid_data->TLONG
  dims = dimsizes(tlat_all)
  nj_all = dims(0)
  delete(dims)

  Opt = True
  Opt@InterpMethod = method
  Opt@DstFileName = grid_in+"2"+grid_out+".regrid_data_file.nc"
  Opt@ForceOverwrite = True
;  Opt@SrcMask2D = where(ismissing(var2_mean(0,0,:,:),0,1))          ; not sure if I need this?
  Opt@DstGridLat = tlat_all
  Opt@DstGridLon = tlon_all

  mname = "CESM1-LE"
  Opt@DstTitle = mname+" atm grid"

;-------------------------------------------------------------------------------------------------------
; get ice variables, calculate daily fcondtops and average to monthly data, saving files along the way
;-------------------------------------------------------------------------------------------------------
   do i=0,ncase-1
      print("Calculating fcond for "+case_names(i))
      Opt@SrcInputFileName  = fTS(i)                                        ; optional, but good idea

      f0 = addfile(fTS(i),"r")
      f1 = addfile(fai(i), "r")
      f2 = addfile(fhi(i), "r")
      f3 = addfile(fhs(i), "r")

      f4 = addfile(ffcondtop_ai(i), "r")
      fcondtop_ai = f4->fcondtop_ai
      time = f4->time
      nt = dimsizes(time)

      f01 = addfile(faice(i),"r")				; monthly aice
      aice_m = f01->aice
      if (max(aice_m).gt.10.) then
         aice_m = aice_m/100.                    ; from percent to 0-1
      end if
      tmpaice_m = aice_m
      tmpaice_m = where(aice_m.eq.0.,aice_m@_FillValue,aice_m)
      fcondtop = fcondtop_ai
      fcondtop = fcondtop_ai/tmpaice_m
 
      fcondtop_daily2monthly = fcondtop_ai                      ; metadata
      fcondtop_daily2monthly_ai = fcondtop_ai 			; metadata
      if (i.eq.0) then
         TLAT = f1->TLAT
         TLON = f1->TLON
         tarea = f1->tarea
         ndim = dimsizes(tarea)
         nj = ndim(0)
         ni = ndim(1)

         lat = f0->lat
         lon = f0->lon
         Opt@SrcGridLat = lat
         Opt@SrcGridLon = lon
      end if

      nyr = yr2(i) - yr1(i) + 1
      do iy=0,nyr-1
         i1 = iy*365
         i2 = i1 + 364

         aice = f1->aice_d(i1:i2,:,:)
         if (max(aice).gt.10.) then
            aice = aice/100.			; from percent to 0-1
         end if
         hi = f2->hi_d(i1:i2,:,:)
         hs = f3->hs_d(i1:i2,:,:)
         TS = f0->TS(i1:i2,:,:)
         TS = TS - 273.15                                                    ; TS is in Kelvin

         TS_regrid = ESMF_regrid(TS,Opt)
         if (hem.eq."nh") then
            ts_hem = TS_regrid(:,nj_all-nj:,:)
         else
            ts_hem = TS_regrid(:,:nj-1,:)
         end if
         tmpaice = aice
         tmpaice = where(aice.eq.0.,aice@_FillValue,aice)
         hi_ice = hi/tmpaice                  ; go from grid-cell average to just ice covered area...
         hs_ice = hs/tmpaice

         heff = hi_ice + kratio*(hs_ice)

         delta_T = ts_hem
         delta_T = ts_hem - Tbot                             ; positive down (into ice), negative up (into atm)

         tmpheff = heff
         tmpheff = where(heff.eq.0.,heff@_FillValue,heff) 
         fcondtop_daily = (/ (kseaice/tmpheff)*delta_T /)
         fcondtop_daily_ai = (/ (kseaice/tmpheff)*delta_T*aice /)
         delete(tmpheff)

         do im=0,11
            id1 = imonth_jday(im)
            id2 = id1 + ndays_per_month(im) - 1
            fcondtop_daily2monthly(iy*12+im,:,:) = dim_avg_n(fcondtop_daily(id1:id2,:,:),0)
            fcondtop_daily2monthly_ai(iy*12+im,:,:) = dim_avg_n(fcondtop_daily_ai(id1:id2,:,:),0)
         end do							; end im
      end do							; end iy
 
      delta_fcondtop_daily2monthly = fcondtop
      delta_fcondtop_daily2monthly = fcondtop - fcondtop_daily2monthly
      fcondtop_daily2monthly@long_name = "top surface conductive heat flux calculated from daily aice_d, hi_d, hs_d and TS (from atm)"
      delta_fcondtop_daily2monthly@long_name = "model output fcondtop - fcondtop_daily2monthly"

      fcondtop_daily2monthly_ai@long_name = "top surface conductive heat flux calculated from daily aice_d, hi_d, hs_d and TS (from atm)"
      delta_fcondtop_daily2monthly_ai = fcondtop_ai
      delta_fcondtop_daily2monthly_ai = fcondtop_ai - fcondtop_daily2monthly_ai
      delta_fcondtop_daily2monthly_ai@long_name = "model output fcondtop - fcondtop_daily2monthly"

      fcondtop_daily2monthly_ai@comment= "weighted by (daily) ice area"
      delta_fcondtop_daily2monthly_ai@comment= "weighted by (daily) ice area"

      delete(aice_m)
      delete(tmpaice_m)
      delete(fcondtop_ai)
      delete(fcondtop)
;-------------------------------------------------------------------------
; save netCDF with calculated fcondtop_ais....
;-----------------------------------------------------------------------

      system("/bin/rm -f "+fcond_out(i))
;      setfileoption("nc","Format","NetCDF4")
      fout = addfile(fcond_out(i),"c")
      setfileoption(fout,"DefineMode",True)

      file_title = case_names(i)
      fileAtt = True
      fileAtt@creation_date = systemfunc("date")
      fileAtt@program = systemfunc("pwd")+"/"+get_script_name()
      fileAtt@title = file_title
      fileattdef(fout,fileAtt)

      dimNames = (/"time","nj","ni"/)
      dimSizes = (/-1,nj,ni/)
      dimUnlim = (/True,False,False/)

      filedimdef(fout,dimNames,dimSizes,dimUnlim)

      filevardef(fout,"time",typeof(time),getvardims(time))
      filevarattdef(fout,"time",time)

      filevardef(fout,"TLAT",typeof(TLAT),getvardims(TLAT))
      filevardef(fout,"TLON",typeof(TLON),getvardims(TLON))
      filevardef(fout,"tarea",typeof(tarea),getvardims(tarea))
      filevardef(fout,"fcondtop_daily2monthly",typeof(fcondtop_daily2monthly),getvardims(fcondtop_daily2monthly))
      filevardef(fout,"delta_fcondtop_daily2monthly",typeof(delta_fcondtop_daily2monthly),getvardims(delta_fcondtop_daily2monthly))
      filevardef(fout,"fcondtop_daily2monthly_ai",typeof(fcondtop_daily2monthly_ai),getvardims(fcondtop_daily2monthly_ai))
      filevardef(fout,"delta_fcondtop_daily2monthly_ai",typeof(delta_fcondtop_daily2monthly_ai),getvardims(delta_fcondtop_daily2monthly_ai))

      filevarattdef(fout,"TLAT",TLAT)
      filevarattdef(fout,"TLON",TLON)
      filevarattdef(fout,"tarea",tarea)
      filevarattdef(fout,"fcondtop_daily2monthly",fcondtop_daily2monthly)
      filevarattdef(fout,"delta_fcondtop_daily2monthly",delta_fcondtop_daily2monthly)
      filevarattdef(fout,"fcondtop_daily2monthly_ai",fcondtop_daily2monthly_ai)
      filevarattdef(fout,"delta_fcondtop_daily2monthly_ai",delta_fcondtop_daily2monthly_ai)

      fout->time = time
      fout->TLAT= (/ TLAT/)
      fout->TLON= (/ TLON/)
      fout->tarea = (/ tarea /)
      fout->fcondtop_daily2monthly = (/ fcondtop_daily2monthly /)
      fout->delta_fcondtop_daily2monthly = (/ delta_fcondtop_daily2monthly /)
      fout->fcondtop_daily2monthly_ai = (/ fcondtop_daily2monthly_ai /) 
      fout->delta_fcondtop_daily2monthly_ai = (/ delta_fcondtop_daily2monthly_ai /) 

      delete(time)
      delete(fcondtop_daily2monthly)
      delete(delta_fcondtop_daily2monthly)
      delete(fcondtop_daily2monthly_ai)
      delete(delta_fcondtop_daily2monthly_ai)

   end do 						; end do ncase
end
