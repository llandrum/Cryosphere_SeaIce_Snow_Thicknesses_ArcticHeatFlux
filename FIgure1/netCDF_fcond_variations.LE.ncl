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
; Calculates two different fcondtop_ai (top surface conductive heat flux)
; from monthly averages to compare with fcondtop_ai output from CESM-LENS.
; Testing influence of ice thickness distribution vs average ice thickness
; and differences this might make in conductivity calculations.
; (don't have daily output or Tsfc, hs by thickness category so can't
; calculate it directly).
;
; LLandrum
; August 2018
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
;   case_numbers = ispan(1,33,1)
;   case_numbers = ispan(1,40,1)
;   case_numbers(35:) = ispan(101,105,1)
   case_numbers = ispan(2,40,1)
   case_numbers(34:) = ispan(101,105,1)
;   case_numbers = ispan(34,40,1)
;   case_numbers(2:) = ispan(101,105,1)
   scnumbers = sprinti("%0.3i",case_numbers)

   c20thC_case = LE_20thC_case+ scnumbers
   rcp85_case = LE_rcp_case+scnumbers

   case_names = c20thC_case
;   case_names = rcp85_case
   ncase = dimsizes(case_names)

   tseries_dir = "/glade/collections/cdg/data/cesmLE/CESM-CAM5-BGC-LE/ice/proc/tseries/monthly/"
   out_dir = "/glade/p/cesm/pcwg/landrum/LE/ice/fcondtop_ai/calcs/monthly/"

   yr1 = new(ncase,integer)
   yr1 = 1920
;   yr1 = 2006                                                    ; start and end yrs for time series
;   yr1(0) = 1850
;   yr1 = 2081
;   yr1(33:) = 2006
   yr2 = yr1
   yr2 = 2005
;   yr2 = 2080
;   yr2 = 2100
;   yr2(33:) = 2100

   styrs = sprinti("%0.4i",yr1) + "01-"+sprinti("%0.4i",yr2)+"12"

   fai = tseries_dir+"aice/"+case_names+".cice.h.aice_"+hem+"."+styrs+".nc"
   fhi = tseries_dir+"hi/"+case_names+".cice.h.hi_"+hem+"."+styrs+".nc"
   fhs = tseries_dir+"hs/"+case_names+".cice.h.hs_"+hem+"."+styrs+".nc"
   fTsfc = tseries_dir+"Tsfc/"+case_names+".cice.h.Tsfc_"+hem+"."+styrs+".nc"
   ffcondtop_ai = tseries_dir+"fcondtop_ai/"+case_names+".cice.h.fcondtop_ai_"+hem+"."+styrs+".nc"

   nthick = 5
   thick = ispan(1,nthick,1)

   fcond_out = out_dir+case_names+".fcondtop_ai_calcs_"+hem+"."+styrs+".nc"
;-------------------------------------------------------------------------
; get ice variable then calculate stats, saving files along the way
;-----------------------------------------------------------------------
   do i=0,ncase-1
      print("Calculating fcond for "+case_names(i))
      f1 = addfile(fai(i), "r")
      if (i.eq.0) then
         TLAT = f1->TLAT
         TLON = f1->TLON
         tarea = f1->tarea
         ndim = dimsizes(tarea)
         nj = ndim(0)
         ni = ndim(1)
      end if
      time = f1->time
      nt = dimsizes(time)
      aice = f1->aice
      if (max(aice).gt.10.) then
         aice = aice/100.			; from percent to 0-1
      end if
      f2 = addfile(fhi(i), "r")
      hi = f2->hi
      f3 = addfile(fhs(i), "r")         
      hs = f3->hs
      f4 = addfile(fTsfc(i), "r")         
      Tsfc = f4->Tsfc

      tmpaice = aice
      tmpaice = where(aice.eq.0.,aice@_FillValue,aice)
      hi_ice = hi/tmpaice                  ; go from grid-cell average to just ice covered area...
      hs_ice = hs/tmpaice

      heff = hi_ice + kratio*(hs_ice)

      aicen00x = new((/nthick,nt,nj,ni/),float)
      vicen00x = new((/nthick,nt,nj,ni/),float)
      vicen00x_ice = new((/nthick,nt,nj,ni/),float)
      heff00x = new((/nthick,nt,nj,ni/),float)

      faicen00x = tseries_dir+"aicen00"+thick+"/"+case_names(i)+".cice.h.aicen00"+thick+"_"+hem+"."+styrs(i)+".nc"
      fvicen00x = tseries_dir+"vicen00"+thick+"/"+case_names(i)+".cice.h.vicen00"+thick+"_"+hem+"."+styrs(i)+".nc"

      do inh = 0,nthick-1
         ai_name = "aicen00"+thick(inh)
         vi_name = "vicen00"+thick(inh)

         f5 =  addfile(faicen00x(inh),"r")
         aicen00x(inh,:,:,:) = f5->$ai_name$ 

         f6 =  addfile(fvicen00x(inh),"r")
         vicen00x(inh,:,:,:) = f6->$vi_name$
      end do
      if (max(aicen00x).gt.10.) then
         aicen00x = aicen00x/100.                       ; from percent to 0-1
      end if

      tmpaicen00x = aicen00x
      tmpaicen00x = where(aicen00x.eq.0.,aicen00x@_FillValue,aicen00x)
      vicen00x_ice = vicen00x/tmpaicen00x                       ; mean thickness in given category - no longer grid cell mean
      delete(tmpaicen00x)

      hs4d = conform(vicen00x_ice,hs_ice,(/1,2,3/))
      heff00x = vicen00x_ice + kratio*(hs4d)
      delete(hs4d)

      f7 = addfile(ffcondtop_ai(i), "r")
      fcondtop_ai = f7->fcondtop_ai
      fcondtop = fcondtop_ai
      fcondtop = fcondtop_ai/tmpaice					; now fcondtop just over ice covered area

      fcondtop_mean = fcondtop					; metadata
      fcondtop_nthick = fcondtop					; metadata

      delta_T = Tsfc
      delta_T = Tsfc - Tbot				; positive down (into ice), negative up (into atm)

      tmpheff = heff
      tmpheff = where(heff.eq.0.,heff@_FillValue,heff) 
      fcondtop_mean = (/ (kseaice/tmpheff)*delta_T /)
      delete(tmpheff)

      tmpai_heff = aicen00x
      tmpai_heff = (/ where(heff00x.eq.0.,0.,(aicen00x/heff00x)) /)
      sum_aiheff00x = dim_sum_n(tmpai_heff,0)

      fcondtop_nthick = (/ (kseaice/tmpaice)*sum_aiheff00x*delta_T /)
      delete(tmpaice)
      delete(tmpai_heff)
      delete(delta_T)
 
      delta_fcondtop_mean = fcondtop
      delta_fcondtop_mean = fcondtop - fcondtop_mean
      delta_fcondtop_nthick = fcondtop
      delta_fcondtop_nthick = fcondtop - fcondtop_nthick
      delta_fcondtop_2method = fcondtop_nthick
      delta_fcondtop_2method = fcondtop_nthick - fcondtop_mean

      delta_fcondtop_mean@long_name = "model output (fcondtop_ai/aice) - fcondtop_mean"
      delta_fcondtop_nthick@long_name = "model output (fcondtop_ai/aice) - fcondtop_nthick"
      delta_fcondtop_2method@long_name = "fcondtop_nthick - fcondtop_mean"

      fcondtop_mean@long_name = "top surface conductive heat flux calculated from monthly means and average hi"
      fcondtop_nthick@long_name = "top surface conductive heat flux calculated from monthly means and hi from each thickness category"

      fcondtop_mean_ai = fcondtop_mean
      fcondtop_mean_ai = fcondtop_mean*aice
      fcondtop_mean_ai@comment= "weighted by ice area"
      fcondtop_nthick_ai = fcondtop_nthick
      fcondtop_nthick_ai = fcondtop_nthick*aice
      fcondtop_nthick_ai@comment= "weighted by ice area"

      delta_fcondtop_mean_ai = fcondtop_ai
      delta_fcondtop_mean_ai = fcondtop_ai - fcondtop_mean_ai
      delta_fcondtop_nthick_ai = fcondtop_ai
      delta_fcondtop_nthick_ai = fcondtop_ai - fcondtop_nthick_ai
      delta_fcondtop_2method_ai = fcondtop_nthick_ai
      delta_fcondtop_2method_ai = fcondtop_nthick_ai - fcondtop_mean_ai

      delta_fcondtop_mean_ai@long_name = "model output fcondtop_ai - fcondtop_mean_ai"
      delta_fcondtop_nthick_ai@long_name = "model output fcondtop_ai - fcondtop_nthick_ai"
      delta_fcondtop_2method_ai@long_name = "fcondtop_nthick_ai - fcondtop_mean_ai"

      delete(fcondtop_ai)
      delete(fcondtop)
      delete(aice)
      delete(Tsfc)
      delete(hs)
      delete(hs_ice)
      delete(hi)
      delete(hi_ice)
      delete(heff)
      delete(aicen00x)
      delete(vicen00x)
      delete(vicen00x_ice)
      delete(heff00x)
      delete(sum_aiheff00x)

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
      filevardef(fout,"fcondtop_mean",typeof(fcondtop_mean),getvardims(fcondtop_mean))
      filevardef(fout,"fcondtop_nthick",typeof(fcondtop_nthick),getvardims(fcondtop_nthick))
      filevardef(fout,"delta_fcondtop_mean",typeof(delta_fcondtop_mean),getvardims(delta_fcondtop_mean))
      filevardef(fout,"delta_fcondtop_nthick",typeof(delta_fcondtop_nthick),getvardims(delta_fcondtop_nthick))
      filevardef(fout,"delta_fcondtop_2method",typeof(delta_fcondtop_2method),getvardims(delta_fcondtop_2method))
      filevardef(fout,"fcondtop_mean_ai",typeof(fcondtop_mean_ai),getvardims(fcondtop_mean_ai))
      filevardef(fout,"fcondtop_nthick_ai",typeof(fcondtop_nthick_ai),getvardims(fcondtop_nthick_ai))
      filevardef(fout,"delta_fcondtop_mean_ai",typeof(delta_fcondtop_mean_ai),getvardims(delta_fcondtop_mean_ai))
      filevardef(fout,"delta_fcondtop_nthick_ai",typeof(delta_fcondtop_nthick_ai),getvardims(delta_fcondtop_nthick_ai))
      filevardef(fout,"delta_fcondtop_2method_ai",typeof(delta_fcondtop_2method_ai),getvardims(delta_fcondtop_2method_ai))

      filevarattdef(fout,"TLAT",TLAT)
      filevarattdef(fout,"TLON",TLON)
      filevarattdef(fout,"tarea",tarea)
      filevarattdef(fout,"fcondtop_mean",fcondtop_mean)
      filevarattdef(fout,"fcondtop_nthick",fcondtop_nthick)
      filevarattdef(fout,"delta_fcondtop_mean",delta_fcondtop_mean)
      filevarattdef(fout,"delta_fcondtop_nthick",delta_fcondtop_nthick)
      filevarattdef(fout,"delta_fcondtop_2method",delta_fcondtop_2method)
      filevarattdef(fout,"fcondtop_mean_ai",fcondtop_mean_ai)
      filevarattdef(fout,"fcondtop_nthick_ai",fcondtop_nthick_ai)
      filevarattdef(fout,"delta_fcondtop_mean_ai",delta_fcondtop_mean_ai)
      filevarattdef(fout,"delta_fcondtop_nthick_ai",delta_fcondtop_nthick_ai)
      filevarattdef(fout,"delta_fcondtop_2method_ai",delta_fcondtop_2method_ai)

      fout->time = time
      fout->TLAT= (/ TLAT/)
      fout->TLON= (/ TLON/)
      fout->tarea = (/ tarea /)
      fout->fcondtop_mean = (/ fcondtop_mean/)
      fout->fcondtop_nthick = (/ fcondtop_nthick/)
      fout->delta_fcondtop_mean = (/ delta_fcondtop_mean/)
      fout->delta_fcondtop_nthick = (/ delta_fcondtop_nthick/)
      fout->delta_fcondtop_2method = (/ delta_fcondtop_2method/)
      fout->fcondtop_mean_ai = (/ fcondtop_mean_ai/)
      fout->fcondtop_nthick_ai = (/ fcondtop_nthick_ai/)
      fout->delta_fcondtop_mean_ai = (/ delta_fcondtop_mean_ai/)
      fout->delta_fcondtop_nthick_ai = (/ delta_fcondtop_nthick_ai/)
      fout->delta_fcondtop_2method_ai = (/ delta_fcondtop_2method_ai/)

      delete(time)
      delete(fcondtop_mean)
      delete(fcondtop_nthick)
      delete(delta_fcondtop_mean)
      delete(delta_fcondtop_nthick)
      delete(delta_fcondtop_2method)
      delete(fcondtop_mean_ai)
      delete(fcondtop_nthick_ai)
      delete(delta_fcondtop_mean_ai)
      delete(delta_fcondtop_nthick_ai)
      delete(delta_fcondtop_2method_ai)

   end do 						; end do ncase
end
