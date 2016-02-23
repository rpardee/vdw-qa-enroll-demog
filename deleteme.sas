/*********************************************
* Roy Pardee
* Group Health Research Institute
* (206) 287-2078
* pardee.r@ghc.org
*
* //groups/data/CTRHS/Crn/voc/enrollment/programs/deleteme.sas
*
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

libname col "\\groups\data\CTRHS\Crn\voc\enrollment\programs\qa_results" ;

options orientation = landscape ;

* %let out_folder = //groups/data/CTRHS/Crn/voc/enrollment/programs/ ;
%let out_folder = %sysfunc(pathname(s)) ;

ods html path = "&out_folder" (URL=NONE)
         body   = "deleteme.html"
         (title = "deleteme output")
         style = magnify
          ;

* ods rtf file = "&out_folder.deleteme.rtf" device = sasemf ;

* Put this line before opening any ODS destinations. ;
options orientation = landscape ;

  ods graphics / height = 6in width = 10in ;

  proc sgplot data = col.py_dur ;
    scatter x = person_years y = duration_p50 / yerrorlower = duration_p25
                                                yerrorupper = duration_p75
                                                errorbarattrs = (color = lightyellow thickness = .7mm)
                                                datalabel = site
                                                datalabelattrs = (size = 2.5mm)
                                                markerattrs = (symbol = circlefilled size = 3mm)
                                                ;
    xaxis grid ; * values = (&earliest to "31dec2010"d by month ) ;
    yaxis grid label = "Typical Enrollment Duration (median + 25th/75th percentiles)" ;
  run ;


run ;

ods _all_ close ;
