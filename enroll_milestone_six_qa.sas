/*********************************************
* Roy Pardee
* Group Health Research Institute
* (206) 287-2078
* pardee.r@ghc.org
*
* \\groups\data\CTRHS\Crn\voc\enrollment\programs\enroll_milestone_six_qa.sas
*
* Produces a report demonstrating that the VDW Version 3 changes from milestone six have
* in fact taken place.
*
* Milestone 6 is documented at:
* https://appliedresearch.cancer.gov/crnportal/data-resources/vdw/version-3/workplans/milestone-6
*
* Please return your sites results to pardee.r@ghc.org.
*********************************************/

** ====================== BEGIN EDIT SECTION ======================= ;
** Please comment-out or remove this line if Roy forgets to.  Thanks/sorry! ;
%**include "\\home\pardre1\SAS\Scripts\remoteactivate.sas" ;

options linesize = 150 nocenter msglevel = i NOOVP formchar='|-++++++++++=|-/|<>*' dsoptions="note2err" ; ** nosqlremerge ;

** Experimenting... ;
libname _all_ clear ;

** Please replace with a reference to your local StdVars file. ;
%include "\\groups\data\CTRHS\Crn\voc\enrollment\programs\StdVars.sas" ;

** A folder spec where HTML output can be written--please make sure you leave a trailing folder separator ;
** character (e.g., a backslash) here--ODS is very picayune about that... ;
%let out_folder = \\ctrhs-sas\SASUser\pardre1\vdw\voc_enroll ;

** ======================= END EDIT SECTION ======================== ;
libname ot "&out_folder" ;

/*

  Enrollment changes in milestone 6:
    new vars:

      plan_hmo
      plan_pos
      plan_ppo
      plan_indemnity

      ins_StateSubsidized
      ins_SelfFunded
      ins_HighDeductible
      ins_Medicare_A
      ins_Medicare_B
      ins_Medicare_C
      ins_Medicare_D

      All these are y/n/u--no more blank allowed.

  Goals:
    check for existence of new vars--failure notice if not.
    generate stats on extent-in-time of each new flag.
    graph counts over time maybe?


    no high deduct unless commercial or privatepay.
    no part d prior to 01jan2006

*/

data new_vars ;
  input
    @1    var_name $char25.
  ;
datalines ;
plan_hmo
plan_pos
plan_ppo
plan_indemnity
ins_statesubsidized
ins_selffunded
ins_highdeductible
ins_medicare_a
ins_medicare_b
ins_medicare_c
ins_medicare_d
;
run ;

proc format ;
  value $flg
    'Y' = 'Yes'
    'N' = 'No'
    'U' = 'Unknown'
    other = 'FAIL: Out of spec value!'
  ;
quit ;

%macro find_new_vars ;
  %global num_new_vars v1 v2 v3 v4 v5 v6 v7 v8 v9 v10 v11 new_vars new_vars_nosep ;
  title2 "Checking for existence of new vars." ;
  proc sql ;
    ** describe table dictionary.columns ;
    create table existing_vars as
    select lowcase(name) as var_name, type, label
    from dictionary.columns
    where lowcase(compress(libname || '.' || memname)) = "%lowcase(&_vdw_enroll_m6)" AND
          lowcase(name) in (select var_name from new_vars)
    ;

    select "PASS: Variable exists" as msg, var_name, type, label
    from existing_vars
    where var_name in (select var_name from new_vars)
    ;

    reset noprint ;

    select var_name
    into :v1 - :v11
    from existing_vars
    where var_name in (select var_name from new_vars)
    ;

    select var_name
    into :new_vars separated by ', '
    from existing_vars
    where var_name in (select var_name from new_vars)
    ;

    select var_name
    into :new_vars_nosep separated by ' '
    from existing_vars
    where var_name in (select var_name from new_vars)
    ;

    %let num_new_vars = &sqlobs ;

    reset print ;

    select "FAIL: Variable does not exist!" as msg, var_name
    from new_vars
    where var_name not in (select var_name from existing_vars)
    ;

  quit ;
  %if &sqlobs > 0 %then %do i = 1 %to 10 ;
    %put FAIL: ONE OR MORE MILESTONE 6 VARIABLES MISSING FROM &_vdw_enroll_m6!!!  See output file for details. ;
  %end ;
%mend find_new_vars ;

%macro time_summary(var = , dset = gnu) ;
  proc sql ;
    title "Extent in time of values of &var" ;
    select &var
      , min(enr_start) as earliest_start format = mmddyy10.
      , max(enr_start) as latest_start   format = mmddyy10.
      , min(enr_end) as earliest_end format = mmddyy10.
      , max(enr_end) as latest_end   format = mmddyy10.
      , count(distinct mrn) as num_people format = comma14.0
      , count(*) as num_recs format = comma14.0
    from &dset
    group by &var
    order by 6 desc
    ;
  quit ;
%mend time_summary ;

%macro freqs(dset = &_vdw_enroll_m6) ;

  %if %index(&new_vars_nosep, ins_medicare_a) > 0 AND
      %index(&new_vars_nosep, ins_medicare_b) > 0 AND
      %index(&new_vars_nosep, ins_medicare_c) > 0 AND
      %index(&new_vars_nosep, ins_medicare_d) > 0 %then %do ;
    %let do_medicare = 1 ;
  %end ;
  %else %do ;
    %let do_medicare = 0 ;
  %end ;

  %if %index(&new_vars_nosep, plan_hmo) > 0 AND
      %index(&new_vars_nosep, plan_pos) > 0 AND
      %index(&new_vars_nosep, plan_ppo) > 0 AND
      %index(&new_vars_nosep, plan_indemnity) > 0 %then %do ;
    %let do_plan = 1 ;
  %end ;
  %else %do ;
    %let do_plan = 0 ;
  %end ;


  data gnu ;
    set &dset ;

    %if &do_medicare = 1 %then %do ;
      mcare_summary = '----' ;
      if ins_medicare_a = 'Y' then substr(mcare_summary, 1, 1) = 'A' ;
      if ins_medicare_b = 'Y' then substr(mcare_summary, 2, 1) = 'B' ;
      if ins_medicare_c = 'Y' then substr(mcare_summary, 3, 1) = 'C' ;
      if ins_medicare_d = 'Y' then substr(mcare_summary, 4, 1) = 'D' ;
      label
        mcare_summary = 'Medicare Parts applicable to the period'
      ;
    %end ;

    %if &do_plan = 1 %then %do ;
      plan_summary = '----' ;
      if plan_hmo = 'Y' then substr(plan_summary, 1, 1) = 'H' ;
      if plan_pos = 'Y' then substr(plan_summary, 2, 1) = 'S' ;
      if plan_ppo = 'Y' then substr(plan_summary, 3, 1) = 'P' ;
      if plan_indemnity = 'Y' then substr(plan_summary, 4, 1) = 'I' ;

      label
        plan_summary = 'Plan types in effect during the period ([H]MO, PO[S], [P]PO, [I]ndemnity)'
      ;
    %end ;

    format &new_vars_nosep $flg. ;
  run ;

  %if &do_medicare = 1 %then %do ;
    %time_summary(var = mcare_summary) ;
  %end ;

  %if &do_plan = 1 %then %do ;
    %time_summary(var = plan_summary) ;
  %end ;

  %do i = 1 %to &num_new_vars ;
    %let this_one = &&v&i ;
    %time_summary(var = &this_one) ;
  %end ;

%mend freqs ;

%macro substantive_checks ;

  ** no high deduct unless commercial or privatepay. ;
  %if %index(&new_vars_nosep, ins_highdeductible) > 0 %then %do ;
    title2 "Commercial + Private Pay variations of High Deductible" ;
    proc freq data = &_vdw_enroll_m6 ;
      tables ins_commercial * ins_privatepay / out = insfreqs ;
      where ins_highdeductible = 'Y' ;
    run ;
    title2 " " ;

    proc sql noprint ;
      select count(*) as x into :x from insfreqs ;

      %if &x = 0 %then %do i = 1 %to 5 ;
        %put WARNING: YOU HAVE NO ENROLLMENT IN HIGH DEDUCTIBLE PLANS.  IS THAT ACCURATE? ;
      %end ;
      %else %do ;
        select round(sum(percent), 1) as pct into :cpp_sum
        from insfreqs
        where ins_commercial = 'Y' OR ins_privatepay = 'Y'
        ;

        %if &cpp_sum < 98 %then %do i = 1 %to 5 ;
          %put FAIL: MORE THAN 2% OF THE RECORDS WITH INS_HIGHDEDUCTIBLE = Y DO NOT ALSO HAVE INS_COMMERCIAL OR INS_PRIVATEPAY SET. ;
        %end ;
        %else %do i = 1 %to 5 ;
          %put PASS: INS_HIGHDEDUCTIBLE MATCHED TO COMMERCIAL OR PRIVATE PAY INSURANCE &cpp_sum PERCENT OF THE TIME. ;
        %end ;

      %end ;
    quit ;

  %end ;
  %else %do i = 1 %to 5 ;
    %put VDW: INS_HIGHDEDUCTIBLE VAR NOT FOUND--SKIPPING SUBSTANTIVE CHECK!!! ;
  %end ;


  ** No medicare part D prior to 01-jan-2006. ;
  %if %index(&new_vars_nosep, ins_highdeductible) > 0 %then %do ;
    proc sql ;
      %let d_start = 01jan2006 ;

      create table ot.too_early_medicare_d as
      select *
      from &_vdw_enroll_m6
      where ins_medicare_d = 'Y' and ((enr_end lt "&d_start"d) or intnx('day', "&d_start"d, -1) between enr_start and enr_end)
      ;

      %if &sqlobs > 50 %then %do i = 1 %to 5 ;
        %put FAIL: YOU HAVE &SQLOBS RECORDS FOR PERIODS PRIOR TO &D_START WITH INS_MEDICARE SET TO Y.  Please see dset too_early_medicare_d in &out_folder for the records in question. ;
      %end ;

    quit ;
  %end ;
  %else %do i = 1 %to 5 ;
    %put VDW: INS_MEDICARE_D VAR NOT FOUND--SKIPPING SUBSTANTIVE CHECK!!! ;
  %end ;
%mend ;

%macro enroll_m6_qa ;
  %if %symexist(_vdw_enroll_m6) %then %do ;
    %put PASS: Macro variable _vdw_enroll_m6 found! ;
    %find_new_vars ;
    %freqs ;
    %substantive_checks ;
  %end ;
  %else %do ;
    proc sql ;
      select "FAIL: ENROLLMENT MILESTONE six MACRO VAR (_vdw_enroll_m6) NOT DEFINED!!!" as fail_message
      from new_vars
      ;
    quit ;
    %do i = 1 %to 10 ;
      %put FAIL: ENROLLMENT MILESTONE six MACRO VAR (_vdw_enroll_m6) NOT DEFINED!!! ;
    %end ;
  %end ;
%mend enroll_m6_qa ;

options mprint mlogic ;

ods html path = "&out_folder" (URL=NONE)
         body = "enroll_milestone_six_qa_&_SiteAbbr..html"
         (title = "Enroll m6 &_SiteAbbr output")
          ;
  title1 "Enrollment Milestone six QA output for &_SiteName" ;

  %enroll_m6_qa ;

run ;

ods html close ;

