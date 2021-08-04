; Modified to calculate series of statistics....and for one month only
; LLandrum
; July 2019
;
; Calculates first 4 moments (mean, variance, skewness, kurtosis) for NH 
; monthly cice variable for each month of the year for an ensemble and 
; over a user-specified time period and saves to netCDF file.
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
; User defined parameters that specify region of globe to consider
; ==============================================================
   imonth = 1                       ; 0-11
   var_name = "aice"

   LE_20thC_case = "b.e11.B20TRC5CNBDRD.f09_g16."
   LE_rcp_case = "b.e11.BRCP85C5CNBDRD.f09_g16."
   case_numbers = ispan(1,40,1)
   case_numbers(35:) = ispan(101,105,1)
;   case_numbers = ispan(1,39,1)					; fcondtop_ai missing 34 in RCP8.5?
;   case_numbers(33) = 35
;   case_numbers(34:) = ispan(101,105,1)
   scnumbers = sprinti("%0.3i",case_numbers)

   c20thC_case = LE_20thC_case+ scnumbers
   rcp85_case = LE_rcp_case+scnumbers

   case1 = LE_20thC_case+scnumbers
   case2 = LE_rcp_case+scnumbers
   case3 = LE_rcp_case+scnumbers

   ncases = dimsizes(case_numbers)

   case1_yr1 = new(ncases,integer)
   case1_yr1 = 1920
   case1_yr1(0) = 1850
   case1_yr2 = case1_yr1
   case1_yr2 = 2005

   case2_yr1 = case1_yr1
   case2_yr1 = 2006
   case2_yr2 = case1_yr1
   case2_yr2 = 2080
   case2_yr2(33:) = 2100
 
   case3_yr1 = case1_yr1
   case3_yr1 = 2081
   case3_yr1(33:) = 2006
   case3_yr2 = case1_yr1
   case3_yr2 = 2100

   syr1_1 = sprinti("%0.4i", case1_yr1)
   syr2_1 = sprinti("%0.4i", case1_yr2)
 
   syr1_2 = sprinti("%0.4i", case2_yr1)
   syr2_2 = sprinti("%0.4i", case2_yr2)
 
   syr1_3 = sprinti("%0.4i", case3_yr1)
   syr2_3 = sprinti("%0.4i", case3_yr2)

   tseries_dir = "/glade/collections/cdg/data/cesmLE/CESM-CAM5-BGC-LE/ice/proc/tseries/monthly/"
   out_dir = "/glade/p/cesm/pcwg/landrum/LE/ice/"+var_name+"/"

   hem = "nh"

   nyr_stats = 10
;   yr1_stats = ispan(1920,2091,1)
   yr1_stats = ispan(1981,2005,1)
;   yr1_stats = (/1920,1980/)
   yr2_stats = yr1_stats+nyr_stats-1
   nstats = dimsizes(yr1_stats)
   sstat_dates = sprinti("%0.4i",yr1_stats) + "-"+sprinti("%0.4i",yr2_stats)

   month_names = (/"JAN","FEB","MAR","APR","MAY","JUN","JUL","AUG","SEP","OCT","NOV","DEC"/)

   fstats = out_dir+"LE."+ncases+"sim."+month_names(imonth)+"_monthly_"+var_name+"_"+hem+"."+nyr_stats+"yr_stats."+yr1_stats+"-"+yr2_stats+".nc"
; ==============================================================

;-------------------------------------------------------------------------
; get ice variable then calculate stats, saving files along the way
;-----------------------------------------------------------------------
   ntot = nyr_stats*ncases

   fgrid = tseries_dir+var_name+"/"+case1(0)+".cice.h."+var_name+"_"+hem+"."+syr1_1(0)+"01-"+syr2_1(0)+"12.nc"             ; to get grid info and limit to nh alone

   f      = addfile (fgrid, "r")         ; get grid info and create variable arrays
   TLAT = f->TLAT
   TLON = f->TLON
   tarea = f->tarea
   ndim = dimsizes(tarea)
   nj = ndim(0)
   ni = ndim(1)

   var = new((/ntot,nj,ni/),float)
   var!0 = "year"
   var!1 = "nj"
   var!2 = "ni"

   stats = new((/1,4,nj,ni/),float)
   stats!0 = "year"
   stats!1 = "moment"
   stats!2 = "nj"
   stats!3 = "ni"
   moment = ispan(1,4,1)
   stats&moment = moment

   statLabel = (/"Mean","Var","Skew","Kurtosis"/)
   statLabel!0 = "moment"
   statLabel&moment = moment

   dimNames = (/"year","moment","nj","ni"/)
   dimSizes = (/1,4,nj,ni/)
   dimUnlim = (/True,False,False,False/)


   do is=0,nstats-1
      stats&year = yr1_stats(is)

      do i=0,ncases-1
         ncase_flag = 1                                                     ; assume one case spans entire decade
         if (yr2_stats(is).le.case1_yr2(i)) then                            ; end yrs for case 1, 3 same
            case_yr1 = case1_yr1
            fdata = tseries_dir+var_name+"/"+case1+".cice.h."+var_name+"_"+hem+"."+syr1_1+"01-"+syr2_1+"12.nc"
         else
            if (yr2_stats(is).le.case2_yr2(i)) then
               if (yr1_stats(is).ge.case2_yr1(0)) then
                  fdata = tseries_dir+var_name+"/"+case2+".cice.h."+var_name+"_"+hem+"."+syr1_2+"01-"+syr2_2+"12.nc"
                  case_yr1 = case2_yr1
               else                                                         ; decade starts in case1 and ends in case2
                  ncase_flag = 2                                            ; one case does not spans entire decade
                  fdata = tseries_dir+var_name+"/"+case1+".cice.h."+var_name+"_"+hem+"."+syr1_1+"01-"+syr2_1+"12.nc"
                  fdata_next = tseries_dir+var_name+"/"+case2+".cice.h."+var_name+"_"+hem+"."+syr1_2+"01-"+syr2_2+"12.nc"
                  case_yr1 = case1_yr1
                  case_yr2 = case1_yr2
                  case_yr1_next = case2_yr1
               end if
            else
               if (yr1_stats(is).ge.case3_yr1(i)) then
                  fdata = tseries_dir+var_name+"/"+case3+".cice.h."+var_name+"_"+hem+"."+syr1_3+"01-"+syr2_3+"12.nc"
                  case_yr1 = case3_yr1
               else                                                           ; decade starts in case1 and ends in case2
                  ncase_flag = 2                                              ; one case does not spans entire decade
                  fdata = tseries_dir+var_name+"/"+case2+".cice.h."+var_name+"_"+hem+"."+syr1_2+"01-"+syr2_2+"12.nc"
                  fdata_next = tseries_dir+var_name+"/"+case3+".cice.h."+var_name+"_"+hem+"."+syr1_3+"01-"+syr2_3+"12.nc"
                  case_yr1 = case2_yr1
                  case_yr2 = case2_yr2
                  case_yr1_next = case3_yr1
               end if
           end if
         end if

         j1 = i*nyr_stats

         f = addfile(fdata(i),"r")

         iLE1 = (yr1_stats(is) - case_yr1(i))*12 
         im1 = iLE1 + imonth

         if (ncase_flag.eq.1) then
            j2 = j1 + nyr_stats - 1
            iLE2 = iLE1 + nyr_stats*12 - 1
            var(j1:j2,:,:) = (/ f->$var_name$(im1:iLE2:12,:,:) /)
         else
            nyr1 = case_yr2(i) - yr1_stats(is) + 1
            j2 = j1 + nyr1 - 1
            iLE2 = iLE1 + nyr1*12 - 1
            var(j1:j2,:,:) = (/ f->$var_name$(im1:iLE2:12,:,:) /)

            f      = addfile (fdata_next(i), "r")
            j2 = j1 + nyr_stats - 1
            j1 = j1 + nyr1
            iLE1 = 0 							; new data file
            im1 = iLE1 + imonth
            iLE2 = (yr2_stats(is) - case_yr1_next(i) + 1)*12 - 1
            var(j1:j2,:,:) = (/ f->$var_name$(im1:iLE2:12,:,:) /)
         end if
      end do

      if (is.eq.0) then
         tmp = f->$var_name$(0,0,0)
         stats@units = tmp@units
         delete(tmp)
      end if

      stats(0,:,:,:) = (/ dim_stat4_n(var,0) /)

      system("/bin/rm -f "+fstats(is))
      setfileoption("nc","Format","NetCDF4")
      fout = addfile(fstats(is),"c")
      setfileoption(fout,"DefineMode",True)

      file_title = "LE ensemble: 4 moments of statistics for "+nyr_stats+" of monthly "+month_names(imonth)+" "+var_name
      fileAtt = True
      fileAtt@creation_date = systemfunc("date")
      fileAtt@program = systemfunc("pwd")+"/"+get_script_name()
      fileAtt@title = file_title
      fileattdef(fout,fileAtt)

      filedimdef(fout,dimNames,dimSizes,dimUnlim)

      filevardef(fout,"TLAT",typeof(TLAT),getvardims(TLAT))
      filevardef(fout,"TLON",typeof(TLON),getvardims(TLON))
      filevardef(fout,"tarea",typeof(tarea),getvardims(tarea))
      filevardef(fout,"stats",typeof(stats),getvardims(stats))
      filevardef(fout,"statLabel",typeof(statLabel),getvardims(statLabel))

      filevarattdef(fout,"TLAT",TLAT)
      filevarattdef(fout,"TLON",TLON)
      filevarattdef(fout,"tarea",tarea)
      filevarattdef(fout,"stats",stats)

      fout->TLAT= (/ TLAT/)
      fout->TLON= (/ TLON/)
      fout->tarea = (/ tarea /)
      fout->stats = (/ stats/)
      fout->statLabel = (/ statLabel /)
   end do 						; end do nstats 
end
