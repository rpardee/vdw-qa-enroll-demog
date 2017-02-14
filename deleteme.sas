/*********************************************
* Roy Pardee
* Group Health Research Institute
* (206) 287-2078
* pardee.r@ghc.org
*
* //groups/data/CTRHS/Crn/voc/enrollment/programs/deleteme.sas
*
* purpose
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
  extendobscounter = no ;
;

libname ts "\\groups\data\CTRHS\Crn\voc\enrollment\programs\ghc_qa\to_send" ;

options orientation = landscape ;
ods graphics / height = 8in width = 10in ;

* %let out_folder = //groups/data/CTRHS/Crn/voc/enrollment/programs/ ;
%let out_folder = %sysfunc(pathname(s)) ;

ods html path = "&out_folder" (URL=NONE)
         body   = "deleteme.html"
         (title = "deleteme output")
         style = magnify
         nogfootnote
          ;

* ods rtf file = "&out_folder.deleteme.rtf" device = sasemf ;

    proc sgplot data = ts.ghc_rx_unenrolled ;
      loess x = first_day y = n_unenrolled / lineattrs = (pattern = solid) nolegfit ;
      xaxis grid label = "Month" ;
      yaxis grid min = 0 label = "No. rx fills for unenrolled people" ;
    run ;


run ;

ods _all_ close ;
