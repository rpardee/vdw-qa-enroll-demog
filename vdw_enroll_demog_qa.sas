/*********************************************
* Roy Pardee
* Group Health Research Institute
* (206) 287-2078
* pardee.r@ghc.org
*
* //groups/data/CTRHS/Crn/voc/enrollment/programs/vdw_enroll_demog_qa.sas
*
* Does comprehensive QA checks for the HMORN VDW's Enrollment & Demographics files.
*********************************************/

* ======================= begin edit section ======================= ;
* ======================= begin edit section ======================= ;
* ======================= begin edit section ======================= ;

* If roy forgets to comment this out, please do so.  Thanks/sorry! ;
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
%include "\\groups\data\CTRHS\Crn\S D R C\VDW\Macros\StdVars.sas" ;

libname to_stay "\\ghrisas\SASUser\pardre1\vdw\voc_enroll" ;
libname to_go   "\\ghrisas\SASUser\pardre1\vdw\voc_enroll\send" ;

* ======================== end edit section ======================== ;
* ======================== end edit section ======================== ;
* ======================== end edit section ======================== ;

data expected_vars ;
  input
    @1   dset      $
    @9   name  $char20.
    @33   type
    @37   recommended_length
  ;
  infile datalines missover ;
datalines ;
demog   gender                  2
demog   birth_date              1   4
demog   hispanic                2
demog   mrn                     2
demog   needs_interpreter       2
demog   primary_language        2
demog   race1                   2
demog   race2                   2
demog   race3                   2
demog   race4                   2
demog   race5                   2
enroll  mrn                     2
enroll  enr_end                 1   4
enroll  enr_start               1   4
enroll  enrollment_basis        2
enroll  drugcov                 2
enroll  ins_commercial          2
enroll  ins_highdeductible      2
enroll  ins_medicaid            2
enroll  ins_medicare            2
enroll  ins_medicare_a          2
enroll  ins_medicare_b          2
enroll  ins_medicare_c          2
enroll  ins_medicare_d          2
enroll  ins_other               2
enroll  ins_privatepay          2
enroll  ins_selffunded          2
enroll  ins_statesubsidized     2
enroll  outside_utilization     2
enroll  pcc                     2
enroll  pcp                     2
enroll  plan_hmo                2
enroll  plan_indemnity          2
enroll  plan_pos                2
enroll  plan_ppo                2
;
run ;

* proc print ;
proc format ;
  value vtype
    1 = "numeric"
    2 = "char"
  ;
quit ;

proc contents noprint data = &_vdw_demographic  out = dvars(keep = name type length label) ;
run ;
proc contents noprint data = &_vdw_enroll       out = evars(keep = name type length label) ;
run ;

data observed_vars ;
  set evars dvars ;
  name = lowcase(name) ;
run ;

proc sql ;
  create table missing_vars as
  select    e.*
  from    expected_vars as e    LEFT JOIN
          observed_vars as o
  on      e.dset = o.dset AND
          e.name = o.name
  ;
quit ;