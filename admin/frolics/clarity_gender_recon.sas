/*********************************************
* Roy Pardee
* KP Washington Health Research Institute
* (206) 287-2078
* roy.e.pardee@kp.org
*
* //groups/data/CTRHS/Crn/voc/enrollment/programs/clarity_gender_recon.sas
*
* Does a few quick Clarity queries to spit out the various
* descriptive phrases available & in use at sites.
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

* PLEASE EDIT THIS TO POINT TO YOUR LOCAL CLARITY DATABASE ;
libname clarity ODBC required = &clarity_odbc ;

proc sql ;
  title1 "Sex Assigned At Birth" ;
  select substr(z.NAME, 1, 35) as sex_aab length = 50, case when count(p.sex_asgn_at_birth_c) > 0 then 'yes' else 'no' end as in_use label = "In use?"
  from  clarity.Patient_4 as p RIGHT JOIN
        clarity.zc_sex_asgn_at_birth as z
  on    p.SEX_ASGN_AT_BIRTH_C = z.SEX_ASGN_AT_BIRTH_C
  group by z.name
  ;
  title1 "Gender Identity" ;
  select substr(z.name, 1, 35) as gender_identity length = 50, case when count(p.GENDER_IDENTITY_C) > 0 then 'yes' else 'no' end as in_use label = "In use?"
  from  clarity.Patient_4 as p RIGHT JOIN
        clarity.zc_gender_identity as z
  on    p.GENDER_IDENTITY_C = z.GENDER_IDENTITY_C
  group by z.name
  ;
  title1 "Sexual Orientation" ;
  select substr(z.name, 1, 35) as sexual_orientation length = 50, case when count(p.sexual_orientatn_c) > 0 then 'yes' else 'no' end as in_use label = "In use?"
  from clarity.pat_sexual_orientation as p RIGHT JOIN
        clarity.zc_sexual_orientation as z
  on p.sexual_orientatn_c = z.SEXUAL_ORIENTATION_C
  group by z.name ;

quit ;
