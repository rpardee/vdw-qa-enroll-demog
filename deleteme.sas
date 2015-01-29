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

* Please edit this to point to your local standard vars file. ;
%include "//ghrisas/Warehouse/Sasdata/CRN_VDW/lib/StdVars.sas" ;
/*
options obs = 2000 ;
*/
libname tst "\\ghrisas\SASUser\pardre1\vdw\enroll" ;
%let _vdw_enroll = tst.enroll3_vw ;

proc freq data = &_vdw_enroll order = freq ;
  tables incomplete_outpt_rx / missing format = comma9.0 ;
run ;