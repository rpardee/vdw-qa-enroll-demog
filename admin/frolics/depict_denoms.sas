/*********************************************
* Roy Pardee
* Group Health Research Institute
* (206) 287-2078
* pardee.r@ghc.org
*
* //groups/data/CTRHS/Crn/voc/enrollment/programs/depict_denoms.sas
*
* The QA program leaves behind a denoms dataset--can we use it to depict
* counts of drugcov by age and sex?
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

libname qadns "\\groups\data\CTRHS\Crn\voc\enrollment\programs\ghc_qa\DO_NOT_SEND" ;

proc sql ;
  %let flist = agegroup, year, gender, drugcov ;

  create table blah as
  select &flist, sum(prorated_total) as prorated_total format = comma9.0
  from qadns.denoms
  where gender ne 'U' and agegroup ge '65to69' and year between 2004 and 2014
  group by &flist
  order by &flist
  ;

quit ;

options orientation = landscape ;

* %let out_folder = //groups/data/CTRHS/Crn/voc/enrollment/programs/ ;
%let out_folder = %sysfunc(pathname(s)) ;

ods graphics / height = 10in width = 8in ;

ods html path = "&out_folder" (URL=NONE)
         body   = "depict_denoms.html"
         (title = "depict_denoms output")
         style = magnify
          ;

ods rtf file = "&out_folder./depict_denoms.rtf" device = sasemf ;

  proc sgpanel data = blah ;
    panelby gender agegroup / layout = lattice rows = 3 ;
    loess x = year y = prorated_total / group = drugcov lineattrs = (pattern = solid) ;
    rowaxis grid ;
    colaxis grid integer ;
    format year 4.0 ;
  run ;

  proc freq data = blah ;
    tables gender * year * drugcov / missing format = comma9.0 ;
    weight prorated_total ;
    * by agegroup ;
  run ;

run ;

ods _all_ close ;

