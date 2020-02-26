/*********************************************
* Roy Pardee
* KP Washington Health Research Institute
* (206) 287-2078
* roy.e.pardee@kp.org
*
* C:\Users/pardre1/Documents/vdw/voc_enroll/admin/frolics/gendersex_miniqa.sas
*
* Mini-QA for the gender/sex spec change to demog. See:
* https://www.hcsrn.org/share/page/site/VDW/document-details?nodeRef=workspace://SpacesStore/ef38035c-4e7c-4d02-b7cc-cb9f082eade0
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
  mprint
;

* For detailed database traffic: ;
* options sastrace=',,,d' sastraceloc=saslog no$stsuffix ;


**************** begin edit section ****************************** ;
**************** begin edit section ****************************** ;
**************** begin edit section ****************************** ;

* Where did you unpack the package? ;
%let root = \\groups\data\CTRHS\CHS\pardre1\repos\voc_enroll ;

* Where is your stdvars file? ;
%include "&GHRIDW_ROOT/Sasdata/CRN_VDW/lib/StdVars.sas" ;

***************** end edit section ******************************* ;
***************** end edit section ******************************* ;
***************** end edit section ******************************* ;
%include vdw_macs ;

libname to_stay "&root./local_only" ;
libname to_go   "&root./share" ;

proc printto log = "&root/share/&_siteabbr._gendersex_miniqa.log" new ;
run ;

* Lets start out w/a clean slate. ;
proc datasets nolist library = to_go    KILL ; run ;
proc datasets nolist library = to_stay  KILL ; run ;

* These define the valid values. ;
proc format ;
  value $sexadm
    'F' = 'Female'
    'M' = 'Male'
    'X' = 'Neither Male Nor Female'
    'O' = 'Other'
    'U' = 'Unknown /uncertain / missing'
    other = 'bad'
  ;
  value $sexaab
    'F' = 'Female'
    'M' = 'Male'
    'I' = 'Intersex'
    'O' = 'Other'
    'U' = 'Uncertain, Unknown or Not recorded on birth certificate'
    'C' = 'Choose not to disclose'
    other = 'bad'
  ;
  value $gi
    'FF' = 'Female'
    'MM' = 'Male'
    'FM' = 'Female to Male transgender'
    'MF' = 'Male to Female transgender'
    'GQ' = 'Genderqueer or non-conforming or non-binary or genderfluid'
    'OT' = 'Other'
    'ND' = 'Choose not to disclose'
    'UK' = 'Unknown'
    other = 'bad'
  ;
quit ;

* What are the new vars & their corresponding formats named? ;
data expected_vars ;
  length name $ 32 ;
  input
    @1    dset    $
    @9    name    $char20.
    @33   fmt     $char6.
  ;
  infile datalines missover ;
datalines ;
demog   kpwa_sex_admin          sexadm
demog   kpwa_sex_at_birth       sexaab
demog   kpwa_gender_identity    gi
;
run ;

%macro sex_change ;
  %* Giggle. Does all the checks & spits out results. ;
  %removedset(dset = to_go.results) ;

  proc contents noprint data = &_vdw_demographic  out = dvars(keep = name type length label) ;
  run ;

  proc sql noprint ;

    create table to_go.results
    (   check char(200)
      , result char(10)
    ) ;

    create table expected_vars_found as
    select e.name, cats('$', fmt, '.') as fmt
    from expected_vars as e INNER JOIN
         dvars as d
    on    e.name = lower(d.name)
    ;

    insert into to_go.results (check, result)
    select catx(' ', name, 'exists.') as chk length = 50, 'pass'
    from expected_vars_found
    ;

    create table expected_vars_notfound as
    select e.name
    from expected_vars as e LEFT JOIN
         dvars as d
    on    e.name = lower(d.name)
    where d.name is null
    ;

    insert into to_go.results (check, result)
    select catx(' ', name, ' does not exist.') as chk length = 50, 'fail'
    from expected_vars_notfound
    ;

    select name, fmt
    into :name1-:name99, :fmt1-:fmt99
    from expected_vars_found
    ;
    %let num_vars = &SQLOBS ;
  quit ;

  data to_stay.bad_demog ;
    set &_vdw_demographic (obs = 5000) ;
    %do i = 1 %to &num_vars ;
      if put(&&name&i, &&fmt&i) = 'bad' then do ;
        problem = "bad value in &&name&i" ;
        output to_stay.bad_demog ;
      end ;
    %end ;
  run ;
  proc sql ;
    create table bad_demog_summary as
    select problem, count(*) as num_bad
    from to_stay.bad_demog
    group by problem
    ;

    insert into to_go.results (check, result)
    select catx(' ', problem, 'for', put(num_bad, best.), 'records.') as chk length = 50, 'fail'
    from bad_demog_summary
    ;
  quit ;

  %if &num_vars > 0 %then %do ;
    proc freq data = &_vdw_demographic noprint ;
      %do i = 1 %to &num_vars ;
        tables &&name&i * gender / missing format = comma9.0 out = to_go.&_SiteAbbr._&&name&i._counts outpct ;
      %end ;
    run ;
  %end ;

  proc print data = to_go.results ;
    id check ;
  run ;

%mend sex_change ;

%sex_change ;
