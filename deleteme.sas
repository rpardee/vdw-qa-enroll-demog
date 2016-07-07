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

libname gh "\\groups\data\CTRHS\Crn\voc\enrollment\programs\ghc_qa\DO_NOT_SEND" ;

proc sql outobs = 20 nowarn ;
  select mrn, enr_start, enr_end, incomplete_emr
  from gh.bad_enroll
  where problem like '%future%'
  ;
quit ;