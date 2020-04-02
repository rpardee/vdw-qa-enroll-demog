/*********************************************
* Roy Pardee
* KP Washington Health Research Institute
* (206) 287-2078
* roy.e.pardee@kp.org
*
* //groups/data/CTRHS/Crn/voc/enrollment/programs/admin/collate_gender.sas
*
* Collates and reports on the dsets produced by the interim QA program
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

%let prgs = \\groups\data\CTRHS\Crn\voc\enrollment\programs ;

libname raw "&prgs\qa_results\raw" ;
libname col "&prgs\qa_results" ;

%stack_datasets(inlib = raw, nom = sex_admin_counts, outlib = col) ;
%stack_datasets(inlib = raw, nom = gender_identity_counts, outlib = col) ;
%stack_datasets(inlib = raw, nom = sex_at_birth_counts, outlib = col) ;
%stack_datasets(inlib = raw, nom = results, outlib = col) ;

