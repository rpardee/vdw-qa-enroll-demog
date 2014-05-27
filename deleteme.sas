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


proc sql ;
  create view s.demog as
  select mrn, birth_date, Gender, gh_birth_date_estimated, hispanic, race1, race2, race3, race4, race5, needs_interpreter
  from blah.demog
  using libname blah '\\ghrisas\Warehouse\sasdata\CRN_VDW'
  ;
quit ;

