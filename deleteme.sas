/*********************************************
* Roy Pardee
* Group Health Research Institute
* (206) 287-2078
* pardee.r@ghc.org
*
* //groups/data/CTRHS/Crn/voc/enrollment/programs/deleteme.sas
*
* Count medicare A-only people with and without drug coverage.
*********************************************/

%include "h:/SAS/Scripts/remoteactivate.sas" ;

options
  linesize  = 150
  msglevel  = i
  formchar  = '|-++++++++++=|-/|<>*'
  dsoptions = note2err
  nocenter
  noovp
  nosqlremerge
;

%include "&GHRIDW_ROOT/Sasdata/CRN_VDW/lib/StdVars_Teradata.sas" ;

* options obs = 10000 ;

data gnu ;
  set &_vdw_enroll (keep = mrn enr_: ins_medicare: drugcov) ;
  where enr_start le '31-dec-2002'd and enr_end ge '01-dec-1999'd  ;
  mcare = '____' ;
  if ins_medicare_a = 'Y' then substr(mcare, 1, 1) = 'A' ;
  if ins_medicare_b = 'Y' then substr(mcare, 2, 1) = 'B' ;
  if ins_medicare_c = 'Y' then substr(mcare, 3, 1) = 'C' ;
  if ins_medicare_d = 'Y' then substr(mcare, 4, 1) = 'D' ;

run ;

data yrs ;
  do yr = 1999 to 2002 ;
    do mo = 1 to 12 ;
      dat = mdy(mo, 15, yr) ;
      output ;
    end ;
  end ;
  format dat mmddyy10. ;
run ;

proc sql ;
  create table s.counts as
  select dat, mcare, drugcov, count(distinct mrn) as num_ppl
  from  gnu INNER JOIN
        yrs
  on    yrs.dat between gnu.enr_start and gnu.enr_end
  group by dat, mcare, drugcov
  ;
quit ;


options orientation = landscape ;

%let out_folder = %sysfunc(pathname(s)) ;

ods graphics / height = 8in width = 10in ;

ods html path = "&out_folder" (URL=NONE)
         body   = "deleteme.html"
         (title = "deleteme output")
         style = magnify
          ;

  proc sgpanel data = s.counts ;
    panelby mcare ;
    loess x = dat y = num_ppl / group = drugcov ;
    where drugcov ne 'U' and mcare like '%A%' ;
    rowaxis grid ;
    colaxis grid ;
    format num_ppl comma9.0 ;
  run ;

  proc sort data = s.counts out = gnu ;
    by mcare ;
  run ;

  proc sgplot data = gnu ;
    loess x = dat y = num_ppl / group = drugcov ;
    where drugcov ne 'U' and mcare like '%A%' ;
    xaxis grid ;
    yaxis grid ;
    format num_ppl comma9.0 ;
    by mcare ;
  run ;

run ;

ods _all_ close ;


