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

* %include "\\home\pardre1\SAS\Scripts\remoteactivate.sas" ;

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


proc format ;
  value $v
    '00to' = '> 5'
    '05to' = '5 - 9'
    '10to' = '10 - 14'
    '15to' = '15 - 19'
    '20to' = '20 - 29'
    '30to' = '30 - 39'
    '40to' = '40 - 49'
    '50to' = '50 - 59'
    '60to' = '60 - 64'
    '65to' = '65 - 69'
    '70to' = '70 - 79'
    'ge_7' = '>= 70'
    'Asia' = 'Asian'
    'Blac' = 'Black/African American'
    'Unkn' = 'Unknown'
    'Whit' = 'White'
    'Nati' = 'Native American'
    'Pac'  = 'Pacific Islander'
    'Both' = 'Both'
    'Insu' = 'Insurance'
    'M'    = 'Male'
    'F'    = 'Female'
    'Y'    = 'Yes'
    'N'    = 'No'
    'U'    = 'Unknown'
  ;
quit ;


proc freq data = s.enroll_freqs ;
  tables var_name * value / list missing format = comma9.0 ;
  format value $v. ;
  weight total ;

run ;