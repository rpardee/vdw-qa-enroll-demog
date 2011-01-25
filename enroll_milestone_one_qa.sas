/*********************************************
* Roy Pardee
* Group Health Research Institute
* (206) 287-2078
* pardee.r@ghc.org
*
* \\groups\data\CTRHS\Crn\voc\enrollment\programs\enroll_milestone_one_qa.sas
*
* Produces a report demonstrating that the VDW Version 3 changes from milestone one have
* in fact taken place.
*
* Milestone 1 is documented at:
* https://appliedresearch.cancer.gov/crnportal/data-resources/vdw/version-3/workplans/milestone-1
*
* Please return your sites results to pardee.r@ghc.org.
*********************************************/

** ====================== BEGIN EDIT SECTION ======================= ;
** Please comment-out or remove this line if Roy forgets to.  Thanks/sorry! ;
%include "\\home\pardre1\SAS\Scripts\remoteactivate.sas" ;

options linesize = 150 nocenter msglevel = i NOOVP formchar='|-++++++++++=|-/|<>*' dsoptions="note2err" ; ** nosqlremerge ;

** Experimenting... ;
libname _all_ clear ;

** Please replace with a reference to your local StdVars file. ;
%include "\\groups\data\CTRHS\Crn\S D R C\VDW\Macros\StdVars.sas" ;

** Using this program to exercise my v2-compatible view--should be lots of fails... ;
%**let _vdw_enroll_m1 = __vdw.enroll2_vw ;

** A folder spec where HTML output can be written--please make sure you leave a trailing folder separator ;
** character (e.g., a backslash) here--ODS is very picayune about that... ;
%let out_folder = \\ctrhs-sas\SASUser\pardre1\vdw\voc_enroll ;

** ======================= END EDIT SECTION ======================== ;
** libname ot "&out_folder" ;
/*

  Enrollment changes in milestone 1:
    new vars:
      enrollment_basis
      outside_utilization
      pcp
      pcc

    changed flag vars:
      Ins_Medicare
      Ins_Medicaid
      Ins_Commercial
      Ins_PrivatePay
      Ins_Other
      DrugCov

      All these are y/n/u--no more blank allowed.

    also changed:
      enr_end--for periods ongoing at the time of the update, should be last day of month prior to update.



  Goals:
    check for existence of new vars--failure notice if not.
    do top 20 values of PCC/PCP (over all time)
      - warn if top val accounts for > X% of values?
    freqs on the flag vars
      - fail if nulls/empty strings


*/

data new_vars ;
  input
    @1    var_name $char25.
  ;
datalines ;
enrollment_basis
outside_utilization
pcp
pcc
;
run ;

data changed_flag_vars ;
  input
    @1    var_name $char25.
  ;
datalines ;
ins_medicare
ins_medicaid
ins_commercial
ins_privatepay
ins_other
drugcov
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
  %global num_new_vars v1 v2 v3 v4 v5 new_vars ;
  title2 "Checking for existence of new vars." ;
  proc sql ;
    ** describe table dictionary.columns ;
    create table existing_vars as
    select lowcase(name) as var_name, type, label
    from dictionary.columns
    where lowcase(compress(libname || '.' || memname)) = "%lowcase(&_vdw_enroll_m1)" AND
          lowcase(name) in (select var_name from new_vars)
    ;

    select "PASS: Variable exists" as msg, var_name, type, label
    from existing_vars
    where var_name in (select var_name from new_vars)
    ;

    reset noprint ;

    select var_name
    into :v1 - :v5
    from existing_vars
    where var_name in (select var_name from new_vars)
    ;

    select var_name
    into :new_vars separated by ', '
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
    %put FAIL: ONE OR MORE MILESTONE 1 VARIABLES MISSING FROM &_vdw_enroll_m1!!!  See output file for details. ;
  %end ;
%mend find_new_vars ;

%macro freqs(dset = &_vdw_enroll_m1, n = 20) ;
  /*
    Why am I doing this with SQL?

    Because for PCP/PCC, I need to limit to the top N values, and I dont know how to make FREQ do that (please let me know if there is a good way!).

    I did try doing a FREQ w/an output dset on the TABLES statement--one TABLES statement per var, and it looked to me like FREQ scanned the table once per statement.

    I also tried SUMMARY with a CLASS statement, and that appeared to eat null values, which I need to detect on the flag variables.

  */
  proc sql noprint ;

    select var_name into :flg1 - :flg6 from changed_flag_vars ;

    select var_name into :flag_vars separated by ', ' from changed_flag_vars ;

    %if &num_new_vars > 0 %then %do ;
      %let vlist = &new_vars, &flag_vars ;
    %end ;
    %else %do ;
      %let vlist = &flag_vars ;
    %end ;

    create table one_pass as
    select &vlist, count(*) as frq
    from &dset
    group by &vlist
    ;

    select sum(frq) into :denom from one_pass ;

    reset print outobs = &n nowarn number ;

    title2 "New Variables in V3" ;
    %do i = 1 %to &num_new_vars ;
      %let this_one = &&v&i ;
      select &this_one, sum(frq) as freq format = comma15.0, (sum(frq)/&denom) as pct format = percent8.2
      from one_pass
      group by &this_one
      order by 2 desc
      ;
    %end ;

    title2 "Flag Variables" ;
    %do i = 1 %to 6 ;
      %let this_one = &&flg&i ;
      select &this_one format = $flg., sum(frq) as freq format = comma15.0, (sum(frq)/&denom) as pct format = percent8.2
      from one_pass
      group by &this_one
      order by 2 desc
      ;
    %end ;
  quit ;

%mend freqs ;

%macro check_enr_end ;
  ** intnx('MONTH', "&sysdate"d, -1, 'E') ;

  proc sql outobs = 10 nowarn number ;
    create table latest_ends as
    select enr_end, count(*) as frq format = comma13.0
    from &_vdw_enroll_m1
    group by enr_end
    order by enr_end desc
    ;

    select "FAIL: enr_end is in the future!" as msg, enr_end, frq
    from latest_ends
    where enr_end gt intnx('MONTH', "&sysdate"d, -1, 'E')
    ;

    title2 "Most recent enr_end values" ;
    select 'PASS: No enr_ends > ' || put(intnx('MONTH', "&sysdate"d, -1, 'E'), mmddyy10.)  as msg, * from latest_ends
    order by enr_end desc
    ;
  quit ;
%mend check_enr_end ;

%macro enroll_m1_qa ;
  %if %symexist(_vdw_enroll_m1) %then %do ;
    %put PASS: Macro variable _vdw_enroll_m1 found! ;
    %find_new_vars ;
    %freqs ;
    %check_enr_end ;
  %end ;
  %else %do ;
    proc sql ;
      select "FAIL: ENROLLMENT MILESTONE ONE MACRO VAR (_vdw_enroll_m1) NOT DEFINED!!!" as fail_message
      from new_vars
      ;
    quit ;
    %do i = 1 %to 10 ;
      %put FAIL: ENROLLMENT MILESTONE ONE MACRO VAR (_vdw_enroll_m1) NOT DEFINED!!! ;
    %end ;
  %end ;
%mend enroll_m1_qa ;

** options mlogic ;

ods html path = "&out_folder" (URL=NONE)
         body = "enroll_milestone_one_qa_&_SiteAbbr..html"
         (title = "Enroll M1 &_SiteAbbr output")
          ;
  title1 "Enrollment Milestone One QA output for &_SiteName" ;

  %enroll_m1_qa ;

run ;

ods html close ;

