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

%include "\\home\pardre1\SAS\Scripts\remoteactivate.sas" ;

options
  linesize  = 150
  msglevel  = i
  formchar  = '|-++++++++++=|-/|<>*'
  dsoptions = note2err
  nocenter
  noovp
  nosqlremerge
;

libname s "\\groups\data\CTRHS\Crn\voc\enrollment\programs\qa_results" ;
%removedset(dset = s.t1_check_tolerances) ;

%macro ap(dset) ;
  proc append base = s.t1_check_tolerances data = &dset ;
  run ;
%mend ap ;

%ap(s.erbr_checks) ;
%ap(s.demog_checks) ;
%ap(s.lang_checks) ;
