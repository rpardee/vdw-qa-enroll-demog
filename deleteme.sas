/*********************************************
* Roy Pardee
* Group Health Research Institute
* (206) 287-2078
* pardee.r@ghc.org
*
* //groups/data/CTRHS/Crn/voc/enrollment/programs/deleteme.sas
*
* PORTAL insurance type counts.
*********************************************/

%include "h:/SAS/Scripts/remoteactivate.sas" ;

options
  linesize  = 150
  pagesize  = 80
  msglevel  = i
  formchar  = '|-++++++++++=|-/|<>*'
  dsoptions = note2err
  nocenter
  noovp
  nosqlremerge
  extendobscounter = no
;

options orientation = landscape ;
* ods graphics / height = 8in width = 10in ;

* %let out_folder = //groups/data/CTRHS/Crn/voc/enrollment/programs/ ;
%let out_folder = %sysfunc(pathname(s)) ;

ods tagsets.rtf file = "&out_folder./deleteme.rtf" device = sasemf ;
ods escapechar = '^' ; * <-- needed to insert html into the output. ;

* footnote link = "https://counter.social" "Hey there handsome" ;
footnote1 link='http://support.sas.com' "SAS";
proc print data = sashelp.class ;
run ;

  ods tagsets.rtf text = "^R/HTML'See <a href=""http://ghri-datawiki.ghc.org/xwiki/bin/view/Main/Hierarchical+Condition+Categories"" target=""_blank"">this datawiki page</a> for further details." ;


ods tagsets.rtf text = "Yo mama so fat!" ;

run ;

ods _all_ close ;

