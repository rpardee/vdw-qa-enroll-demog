/*********************************************
* Roy Pardee
* Group Health Research Institute
* (206) 287-2078
* pardee.r@ghc.org
*
* //groups/data/CTRHS/Crn/voc/enrollment/programs/collate_qa.sas
*
* Collates the comprehensive QA result data & produces a cross-site report.
*********************************************/

%include "h:/SAS/Scripts/remoteactivate.sas" ;

options
  linesize  = 150
  pagesize  = 80
  msglevel  = i
  formchar  = '|-++++++++++=|-/|<>*'
  /* dsoptions = note2err */
  nocenter
  noovp
  nosqlremerge
  extendobscounter = no
;

%include "&GHRIDW_ROOT/Sasdata/CRN_VDW/lib/standard_macros.sas" ;

%let prgs = \\groups.ghc.org\data\CTRHS\Crn\voc\enrollment\programs ;

libname raw "&prgs\submitted_data\raw" ;
libname col "&prgs\submitted_data" ;

* Until I can figure out how to read this off the issue tracker (url below) I ;
* need to keep this shadow copy. Bleah. ;
%let mdb_file = &prgs/submitted_data/issue_memory.accdb ;
libname mem ODBC required="Driver={Microsoft Access Driver (*.mdb, *.accdb)}; DBQ=&mdb_file" ;

%let issue_url = %str(https://www.hcsrn.org/share/page/site/VDW/data-lists?list=f3c5ef15-334b-47f4-b6d3-aee37bedc057) ;

* We need this so that lowest_count is defined. ;
%include "&GHRIDW_ROOT/Sasdata/CRN_VDW/lib/StdVars.sas" ;
%include "&prgs\lib\qa_formats.sas" ;

proc format cntlout = sites ;
  value $s (default = 22)
    /* 'HPRF' = 'HealthPartners' */
    /* 'LCF'  = 'Lovelace' */
    /* "FAL"  = "Fallon Community Health Plan" */
    /* "LHS"  = "Lovelace Health Systems" */
    /* 'PAMF' = 'Palo Alto' */
    'HPHC' = 'Harvard'
    'HPI'  = 'HealthPartners'
    'MCRF' = 'Marshfield'
    'BSWH' = 'Baylor Scott & White'
    'HFHS' = 'Henry Ford'
    'GHS'  = 'Geisinger'
    'GHC'  = 'KP Washington'
    'KPWA' = 'KP Washington'
    'SH'   = 'Sutter Health'
    'EIRH' = 'Essentia'
    'KPCO' = 'KP Colorado'
    'KPNW' = 'KP Northwest'
    'KPGA' = 'KP Georgia'
    "KPNC" = "KP Northern California"
    "KPSC" = "KP Southern California"
    "KPHI" = "KP Hawaii"
    "FA"   = "Fallon Community HP"
    "KPMA" = "KP Mid-Atlantic"
    "SLU"  = "St. Louis Univ/AHEAD"
  ;
  value thrs
    . = 'N/A'
    other = [percent6.0]
  ;
  value $race
    'HP' = 'Native Hawaiian or Other Pacific Islander'
    'IN' = 'American Indian/Alaska Native'
    'AS' = 'Asian'
    'BA' = 'Black or African American'
    'WH' = 'White'
    'MU' = 'More than one race, particular races unknown or not reported'
    'OT' = 'Other'
    'UN' = 'Unknown or Not Reported'
    Other = 'bad'
  ;
  value $eb
    "G" = "Geographic Basis"
    "I" = "Insurance Basis"
    "B" = "Both Insurance and Geographic bases"
    "P" = "Non-enrollee Patient"
  ;
  value $gen
    'M' = 'Male'
    'F' = 'Female'
    'O' = 'Other'
    'X' = 'Neither Male nor Female'
    'U' = 'Unknown'
  ;
  value $ta
    '00to', '00to04'    = '3'
    '05to', '05to09'    = '8'
    '10to', '10to14'    = '13'
    '15to', '15to19'    = '18'
    '20to', '20to29'    = '28'
    '30to', '30to39'    = '38'
    '40to', '40to49'    = '48'
    '50to', '50to59'    = '58'
    '60to', '60to64'    = '62'
    '65to', '65to69'    = '68'
    '70to', '70to74'    = '72'
    'ge_7', 'ge_75'     = '76'
  ;
  value shrtage
    low -< 19 = '0 to 19'
    20  -< 64 = '20 to 64'
    65 - high = '65+'
  ;
  value $v
    '00to', '00to04'    = '< 5'
    '05to', '05to09'    = '5 - 9'
    '10to', '10to14'    = '10 - 14'
    '15to', '15to19'    = '15 - 19'
    '20to', '20to29'    = '20 - 29'
    '30to', '30to39'    = '30 - 39'
    '40to', '40to49'    = '40 - 49'
    '50to', '50to59'    = '50 - 59'
    '60to', '60to64'    = '60 - 64'
    '65to', '65to69'    = '65 - 69'
    '70to', '70to74'    = '70 - 74'
    'ge_7', 'ge_75'     = '>= 75'
    'Asia', 'Asian'     = 'Asian'
    'Blac', 'Black'     = 'Black/African American'
    'Unkn', 'Unknown'   = 'Unknown'
    'Whit', 'White'     = 'White'
    'Nati', 'Native'    = 'Native American'
    'Pac' , 'Pac Isl'   = 'Pacific Islander'
    'Both'              = 'Both'
    'Insu', 'Insurance' = 'Insurance'
    'Non-'              = 'Non-member patient'
    'C'                 = 'Choose not to disclose'
    'E'                 = 'External'
    'F'                 = 'Female'
    'FF'                = 'Female'
    'FM'                = 'Female to Male transgender'
    'GQ'                = 'Genderqueer or non-conforming or non-binary or genderfluid'
    'I'                 = 'Intersex'
    'K'                 = 'Yes, known to be incomplete'
    'M'                 = 'Male'
    'MF'                = 'Male to Female transgender'
    'MM'                = 'Male'
    'N'                 = 'No'
    'ND'                = 'Choose not to disclose'
    'O'                 = 'Other'
    'OT'                = 'Other'
    'U'                 = 'Unknown'
    'UN'                = 'Unknown'
    'X'                 = 'Not implemented'
    'Y'                 = 'Yes'
  ;
  value $vars
      'agegroup'            = 'Age of Enrollees'
      'drugcov'             = 'Has at least `some` drug coverage?'
      'enrollment_basis'    = 'Basis for including this person/period in Enrollment'
      'sex_admin'           = 'Administrative Sex'
      'hispanic'            = 'Is Hispanic?'
      'ins_commercial'      = 'Has Commercial Coverage?'
      'ins_highdeductible'  = 'Has coverage in a High Deductible Plan?'
      'ins_medicaid'        = 'Has Medicaid coverage?'
      'ins_medicare'        = 'Has Medicare coverage?'
      'ins_medicare_a'      = 'Has medicare part A coverage?'
      'ins_medicare_b'      = 'Has medicare part B coverage?'
      'ins_medicare_c'      = 'Has medicare part C coverage?'
      'ins_medicare_d'      = 'Has medicare part D coverage?'
      'ins_other'           = 'Has `other` type insurance coverage?'
      'ins_privatepay'      = 'Has Private Pay coverage?'
      'ins_selffunded'      = 'Has Self-Funded coverage?'
      'ins_statesubsidized' = 'Has State-subsidized coverage?'
      'needs_interpreter'   = 'Needs an interpreter?'
      'outside_utilization' = 'Do we know VDW rx/encounter capture is incomplete for this person/period?'
      'pcc_probably_valid'  = 'Valid Primary Care Clinic assigned?'
      'pcp_probably_valid'  = 'Valid Primary Care Physician assigned?'
      'plan_hmo'            = 'Enrolled in an HMO Plan?'
      'plan_indemnity'      = 'Enrolled in an Indemnity plan?'
      'plan_pos'            = 'Enrolled in a Point-Of-Service plan?'
      'plan_ppo'            = 'Enrolled in a Preferred Provider Organization plan?'
      'race'                = 'Race/Ethnicity'
      'incomplete_emr'      = 'Capture of EMR data known incomplete?'
      'incomplete_inpt_enc' = 'Capture of inpatient encounters known incomplete?'
      'incomplete_lab'      = 'Capture of lab results known incomplete?'
      'incomplete_outpt_enc'= 'Capture of outpatient encounters known incomplete?'
      'incomplete_outpt_rx' = 'Capture of outpatient pharmacy known incomplete?'
      'incomplete_tumor'    = 'Capture of tumor data known incomplete?'
      'sexual_orientation1' = 'Sexual Orientation (unknowns elided)'
      'gender_identity'     = 'Gender Identity (unknowns elided)'
      'sex_at_birth'        = 'Sex Assigned At Birth (unknowns elided)'
  ;
  value $varcat
    'agegroup'             = 'Demogs'
    'sex_admin'            = 'Demogs'
    'sex_at_birth'         = 'Demogs'
    'sexual_orientation1'  = 'Demogs'
    'gender_identity'      = 'Demogs'
    'hispanic'             = 'Demogs'
    'race'                 = 'Demogs'
    'needs_interpreter'    = 'Demogs'
    'drugcov'              = 'Benefit'
    'enrollment_basis'     = 'Meta'
    'outside_utilization'  = 'Meta'
    'pcc_probably_valid'   = 'Meta'
    'pcp_probably_valid'   = 'Meta'
    'incomplete_emr'       = 'Meta'
    'incomplete_inpt_enc'  = 'Meta'
    'incomplete_lab'       = 'Meta'
    'incomplete_outpt_enc' = 'Meta'
    'incomplete_outpt_rx'  = 'Meta'
    'incomplete_tumor'     = 'Meta'
    'ins_commercial'       = 'Ins type'
    'ins_highdeductible'   = 'Ins type'
    'ins_medicaid'         = 'Ins type'
    'ins_medicare'         = 'Ins type'
    'ins_medicare_a'       = 'Ins type'
    'ins_medicare_b'       = 'Ins type'
    'ins_medicare_c'       = 'Ins type'
    'ins_medicare_d'       = 'Ins type'
    'ins_other'            = 'Ins type'
    'ins_privatepay'       = 'Ins type'
    'ins_selffunded'       = 'Ins type'
    'ins_statesubsidized'  = 'Ins type'
    'plan_hmo'             = 'Plan type'
    'plan_indemnity'       = 'Plan type'
    'plan_pos'             = 'Plan type'
    'plan_ppo'             = 'Plan type'
    ;
  * from https://communities.sas.com/t5/SAS-Programming/Million-Format/td-p/440121 ;
  picture hicount (round)
    1E03-<1000000='000K' (mult=.001  )
    1E06-<1000000000='000.9M' (mult=.00001)
    1E09-<1000000000000='000.9B' (mult=1E-08)
    1E12-<1000000000000000='000.9T' (mult=1E-11)
  ;
  value $so
    'B' = 'B: Bisexual'
    'T' = 'T: Heterosexual'
    'M' = 'M: Homosexual'
    'A' = 'A: Asexual'
    'P' = 'P: Pansexual'
    'Q' = 'Q: Queer'
    'O' = 'O: Other'
    'D' = 'D: Does not know'
    'N' = 'N: Choose not to disclose'
    'U' = 'U: Not asked/no information'
    other  = 'bad'
  ;
quit ;

data line_colors ;
  input
    @1    id         $char2.
    @5    value       $char24.
    @31   linecolor   $char8.
  ;
  markercolor = linecolor ;
  markersymbol = 'circle' ;
  linepattern = 'solid' ;
datalines ;
lc  Suspected Incomplete      CX4FA3E7
lc  Not Suspected Incomplete  CXFFD472
lc  Not Implemented           CXB4BDEA
lc  Unknown                   CXFF0000
run ;

%macro stack_and_calc(which) ;

  %stack_datasets(inlib = raw, nom = &which._unenrolled, outlib = col) ;
  data col.&which._unenrolled ;
    set col.&which._unenrolled ;
    if n_total then calc_prop_unenrolled = n_unenrolled / n_total ;
  run ;
%mend stack_and_calc ;

%macro reshuffle_capture_rates(inset = capture_rates, lib = s) ;
  %stack_datasets(inlib = &lib, nom = &inset, outlib = &lib) ;

  proc sql noprint ;
    select distinct upcase(site) as site
        , source_dset
        , cats("&lib..", lowcase(site), '_', substr(source_dset, 9)) as destination_dset
        , capture_var
    into :s1-:s999, :sd1-:sd999, :dd1-:dd999, :cv1-:cv999
    from &lib..&inset
    order by site, source_dset
    ;
    %let num_rows = &SQLOBS ;
  quit ;
  data
    %do i = 1 %to &num_rows ;
      &&dd&i (rename = (capture = &&cv&i))
    %end ;
  ;
    set &lib..&inset ;
    %do i = 1 %to &num_rows ;
      if upcase(site) = "&&s&i" and source_dset = "&&sd&i" then output &&dd&i ;
    %end ;
    drop site source_dset n_unenrolled n_total capture_var ;
  run ;
%mend reshuffle_capture_rates ;

%macro reshuffle_unenrl_rates(inset = unenrl_rates, lib = s) ;
  %stack_datasets(inlib = &lib, nom = &inset, outlib = &lib) ;
  proc sql ;
    select distinct upcase(site) as site
        , dset
        , cats("&lib..", lowcase(site), '_', lowcase(dset), '_unenrolled') as destination_dset
    into :s1-:s999, :ds1-:ds999, :dd1-:dd999
    from &lib..&inset
    order by site, dset
    ;
    %let num_rows = &SQLOBS ;
  quit ;
  data
    %do i = 1 %to &num_rows ;
      &&dd&i
    %end ;
  ;
    set &lib..&inset ;
    %do i = 1 %to &num_rows ;
      if upcase(site) = "&&s&i" and dset = "&&ds&i" then output &&dd&i ;
    %end ;
    drop site dset ;
  run ;

%mend reshuffle_unenrl_rates ;

%macro unreshuffle_unenrl_rates(inset = unenrl_rates, lib = s) ;
  proc sql ;
    select distinct upcase(site) as site
        , dset
        , cats("&lib..", lowcase(site), '_', lowcase(dset), '_unenrolled') as destination_dset
    into :s1-:s999, :ds1-:ds999, :dd1-:dd999
    from &lib..&inset
    order by site, dset
    ;
    %let num_rows = &SQLOBS ;

    %do i = 1 %to &num_rows ;
      drop table &&dd&i ;
    %end ;
  ;
  quit ;
%mend unreshuffle_unenrl_rates ;

%macro unreshuffle_capture_rates(inset = capture_rates, lib = s) ;
  proc sql noprint ;
    select distinct upcase(site) as site
        , source_dset
        , cats("&lib..", lowcase(site), '_', substr(source_dset, 9)) as destination_dset
        , capture_var
    into :s1-:s999, :sd1-:sd999, :dd1-:dd999, :cv1-:cv999
    from &lib..&inset
    order by site, source_dset
    ;
    %let num_rows = &SQLOBS ;

    %do i = 1 %to &num_rows ;
      drop table &&dd&i ;
    %end ;
  quit ;

%mend unreshuffle_capture_rates ;

%macro do_results() ;

  %stack_datasets(inlib = raw, nom = lang_stats, outlib = col) ;

  %stack_datasets(inlib = raw, nom = tier_one_results, outlib = work) ;

  %stack_datasets(inlib = raw, nom = flagcorr, outlib = col) ;

  %stack_datasets(inlib = raw, nom = enroll_duration_stats, outlib = col) ;

  %reshuffle_capture_rates(inset = capture_rates, lib = raw) ;

  %stack_datasets(inlib = raw, nom = rx_rates, outlib = col) ;
  %stack_datasets(inlib = raw, nom = emr_s_rates, outlib = col) ;
  %stack_datasets(inlib = raw, nom = emr_v_rates, outlib = col) ;
  %stack_datasets(inlib = raw, nom = lab_rates, outlib = col) ;
  %stack_datasets(inlib = raw, nom = tumor_rates, outlib = col) ;
  %stack_datasets(inlib = raw, nom = ute_in_rates_by_enctype, outlib = col) ;
  %stack_datasets(inlib = raw, nom = ute_out_rates_by_enctype, outlib = col) ;

  %unreshuffle_capture_rates(inset = capture_rates, lib = raw) ;

  %reshuffle_unenrl_rates(inset = unenrl_rates, lib = raw) ;

  %stack_and_calc(which = rx) ;
  %stack_and_calc(which = enc) ;
  %stack_and_calc(which = lab) ;
  %stack_and_calc(which = shx) ;
  %stack_and_calc(which = tum) ;
  %stack_and_calc(which = vsn) ;

  %unreshuffle_unenrl_rates(inset = unenrl_rates, lib = raw) ;

  proc sort data = tier_one_results(drop = detail_dset) ;
    by qa_macro description site ;
  run ;

  data tier_one_results ;
    set tier_one_results ;
    sitename = put(site, $s.) ;
    select(qa_macro) ;
      when ('%demog_tier_one' ) table = "Demographics" ;
      when ('%enroll_tier_one') table = "Enrollments" ;
      when ('%lang_tier_one', '%fake_langs') table = "Language" ;
      otherwise table = 'All' ;
    end ;
    select(description) ;
      when ('Valid values: language') description = 'Valid values: lang_iso' ;
      when ('Valid values: primary')  description = 'Valid values: lang_primary' ;
      when ('Valid values: use')      description = 'Valid values: lang_usage' ;
      when ('Primary_language has been removed from demog.') table = "Demographics" ;
      otherwise ; * <-- do nothing ;
    end ;
    label
      description = "QA Check"
      table = "VDW Table"
    ;
  run ;

  proc sql noexec ;
    * These guys got bit by a bug when running on a unix system--their fails were bogus. ;
    update tier_one_results
    set result = 'pass'
    where description = 'Are all vars in the spec in the dataset & of proper type?' and site in ('KPNC', 'KPMA')
    ;

    reset exec noprint ;

    * I messed up the check--used two different descriptions based on whether you passed or failed. ;
    update tier_one_results
    set description = 'Primary_language has been removed from demog.', table = "Demographics"
    where description = 'Primary_language still appears in demog.'
    ;

    * If lang table not defined, this should be one failure--take out the ones for the individual vars. ;
    select site
    into :nolang separated by '", "'
    from tier_one_results
    where description = '_vdw_language var not defined--treating as not implemented.' and result = 'fail'
    ;

    %if &sqlobs > 0 %then %do ;

      update tier_one_results
      set result = 'n/a'
      where description in ('Valid values: lang_iso', 'Valid values: lang_primary', 'Valid values: lang_usage') AND
      site in ("&nolang")
      ;

    %end ;
    create table gnu as
    select t.*
        , warn_lim label = "Warn Threshold"
        , fail_lim label = "Fail Threshold"
    from tier_one_results as t LEFT JOIN
        col.t1_check_tolerances as c
    on    t.description = c.description
    ;

    create table tier_one_results as select * from gnu ;

  quit ;

  proc sort data = tier_one_results out = col.norm_tier_one_results ;
    by qa_macro table description ;
  run ;


  proc transpose data = col.norm_tier_one_results out = col.tier_one_results(drop = _:) ;
    var result ;
    by qa_macro table description warn_lim fail_lim ;
    id site ;
    idlabel sitename ;
  run ;
%mend do_results ;

%macro do_vars() ;
  %stack_datasets(inlib = raw, nom = noteworthy_vars, outlib = col) ;
  proc sql ;
    **  Had some problems in KPHI and possibly elsewhere--patch that up. ;
    * select * from col.noteworthy_vars
    where name in (select name from expected_vars) and outcome = 'bad type'
    ;

    delete from col.noteworthy_vars
    where name in (select name from expected_vars) and outcome = 'bad type'
    ;
  quit ;
%mend do_vars ;

%macro do_freqs(nom, byvar = year) ;
  /*
    variables can take any of several values.
    for any combos of site|var_name|&byvar where value = Y that dont occur in the dset, add them in with count and pct of 0
  */

  %stack_datasets(inlib = raw, nom = &nom, outlib = work) ;

  %let fmt = ;

  proc sql ;
    * Sum counts over all values of each var to get totals. ;
    create table tots as
    select  site, &byvar, var_name, sum(count) as total, count(*) as num_recs
    from    &nom
    group by site, &byvar, var_name
    ;

    * All sites submitting freqs ;
    create table sites as
    select distinct site
    from &nom
    ;

    * All combos of var names & values ;
    create table class_levels as
    select distinct var_name, &byvar, value
    from &nom
    where var_name IS NOT NULL AND
          &byvar IS NOT NULL AND
          value IS NOT NULL
    ;

    * This is something like a CLASSLEVEL dataset. ;
    create table cartesian_product as
    select site, var_name, &byvar, value
    from sites CROSS JOIN
          class_levels
    ;

    * if we have a true count for this combo of site, var name, byval & value we use it, otherwise give it a 0. ;
    create table supplemented as
    select cp.site
          , cp.var_name
          , cp.&byvar
          , cp.value
          , coalesce(n.count, 0) as count
    from  cartesian_product as cp LEFT JOIN
          &nom as n
    on    cp.site = n.site AND
          cp.var_name = n.var_name AND
          cp.&byvar = n.&byvar AND
          cp.value = n.value
    ;

    create table col.&nom as
    select r.site, r.var_name, r.&byvar &fmt., r.value
          , r.count as total
          , case when t.total is null then 0 else (r.count / t.total) end as pct format = percent8.2
    from  supplemented as r LEFT JOIN
          tots as t
    on    r.site = t.site AND
          r.&byvar = t.&byvar AND
          r.var_name = t.var_name
    order by r.site, r.var_name, r.&byvar, r.value
    ;

  quit ;
%mend do_freqs ;

%macro misc_wrangling() ;
  proc sql ;
    create table col.raw_enrollment_counts as
    select    site, year
            , sum(total) as total_count label = "No. of enrollees" format = comma12.0
            , count(*) as num_recs
    from    col.enroll_freqs
    where var_name = 'drugcov'
    group by site, year
    ;
    create table col.raw_demog_counts as
    select site, sum(total) as total_count label = "No MRNs in Demographics"
    from col.demog_freqs
    where var_name = 'hispanic'
    group by site
    ;
  quit ;
  data col.raw_enrollment_counts ;
    set col.raw_enrollment_counts ;
    site_name = put(site, $s.) ;
  run ;
%mend misc_wrangling ;

%macro pre_fix ;
  * These came through with a numeric for the var extra--FIX THIS!!! ;
  * data raw.hphc_ute_in_rates_by_enctype ;
  *   set raw.hphc_ute_in_rates_by_enctype(drop = extra) ;
  *   extra = '-1' ;
  * run ;
  * data raw.hphc_ute_out_rates_by_enctype ;
  *   set raw.hphc_ute_out_rates_by_enctype(drop = extra) ;
  *   extra = '-1' ;
  * run ;

  data raw.pamf_ute_in_rates_by_enctype ;
    set raw.pamf_ute_in_rates_by_enctype(drop = extra) ;
    extra = '-1' ;
  run ;
  data raw.pamf_ute_out_rates_by_enctype ;
    set raw.pamf_ute_out_rates_by_enctype(drop = extra) ;
    extra = '-1' ;
  run ;
%mend pre_fix ;

%macro regen() ;
  * %pre_fix ;
  %do_results ;
  %do_vars ;
  %do_freqs(nom = enroll_freqs, byvar = year) ;
  %do_freqs(nom = demog_freqs, byvar = sex_admin) ;

  proc sql noexec ;
    delete from col.enroll_freqs
    where var_name = 'enrollment_basis' and value = 'Y'
    ;
    delete from col.demog_freqs
    where var_name in ('primary_language', 'race1', 'race2', 'race3', 'race4', 'race5') and value = 'Y'
    ;
    * There is non-negligible enrollment data pre-2004 (N ~= 5k) but it is dwarfed and weird compared to ;
    * their post-2004 stuff.  Deleting for now--TODO: put an issue in the tracker for these guys to be explained or removed ;
    reset exec ;
    delete from col.enroll_freqs
    where site = 'KPMA' and year < 2004
    ;
  quit ;

  %misc_wrangling ;
%mend regen ;

%macro report() ;
  %* Reports on enroll_freqs. ;
  %local start_year end_year ;
  %let start_year = 1990 ;
  %let end_year = %trim(%eval(%sysfunc(year("&sysdate"d)) -1)) ;
  proc sort data = col.enroll_freqs out = gnu ;
    by var_name value site year ;
    *  Enforcing a minimal number of records, just to keep out e.g., the year in which FALLON had 100% of their 29 (or however many) records with ins_medicare = y. ;
    * where year between 1990 and (%sysfunc(year("&sysdate"d)) -1) AND value not in ('U', 'N') and total ge 1000 ;
    where year between &start_year and &end_year /* AND value not in ('.', ' ') */ and total > 1  ;
  run ;
  * We report age groups separately, so divvy up the data. ;
  data gnu agegroups ;
    length site $ 22 ;
    set gnu ;
    site = put(site, $s.) ;
    vcat = put(var_name, $varcat.) ;
    if value in ('.', ' ') then value = '<missing>' ;

    if var_name in ('pcc_probably_valid', 'pcp_probably_valid') then do ;
      if value = 'Y' then value = 'Probably' ;
      else if value = 'N' then value = 'Probably Not' ;
    end ;
    if var_name = 'sexual_orientation1' then do ;
      if value = 'U' then delete ;
      else value = put(value, $so.) ;
    end ;
    if var_name = 'gender_identity' then do ;
      if value = 'UN' then delete ;
      else value = put(value, $gi.) ;
    end ;
    if var_name = 'sex_at_birth' then do ;
      if value = 'U' then delete ;
      else value = put(value, $sexaab.) ;
    end ;
    if var_name = 'enrollment_basis' and value =: 'Non-' then value = 'Non-member patient' ;
    if var_name = 'sex_at_birth' and value = 'X' then value = 'Neither Male Nor Female' ;
    if var_name = 'agegroup' then output agegroups ;
    else output gnu ;

    label
      vcat     = "Category"
      year     = "Year"
      pct      = "Percent of enrollees"
      var_name = "Variable"
    ;
    format value $v. ;
  run ;

  proc sql ;
    * Convert age values to range descriptions. ;
    create table bubba as
    select site, year, put(input(put(value, $ta.), best.), shrtage.) as value, total, pct
    from agegroups
    ;
    create table agegroups as
    select site, year, value, sum(total) as total, sum(pct) as pct
    from bubba
    group by site, year, value
    ;
  quit ;

  proc sort data = gnu ;
    by vcat var_name value site year ;
  run ;

  * Enrollment count depiction--we need a separate var for the high-volume sites ;
  data ax ;
    length site_name $ 22 ;
    set col.raw_enrollment_counts ;
    where total_count > 0 ;
    total_count = total_count / 1000 ;
    if site in ('KPNC', 'KPSC') then do ;
      high_count = total_count ;
      total_count = . ;
    end ;
    site_name = put(site, $s.) ;
    label
      total_count = "No. Enrollees (in Thousands)"
      high_count = "Larger Sites"
      site_name = "Site"
    ;
    format high_count comma12.0 ;
  run ;

  proc sql ;
    * Censor partial years on the basis of enrollment submit date ;
    create table censored_ax as
    select a.*
    from ax as a INNER JOIN
        col.submitting_sites as s
    on  a.site_name = s.site
    where a.year lt year(s.date_submitted)
    ;

    create table ax as select * from censored_ax ;

    create table total_enrollments as
    select year, sum(total_count) as total_count format = hicount.
    from col.raw_enrollment_counts
    group by year
    ;
  quit ;

  proc sort data = ax ;
    by year site_name ;
  run ;

  data col.drop_me ;
    set ax ;
    * where year between &start_year and &end_year ;
  run ;

  %local th B sz ;
  %let th = .07 CM ;
  %let B = .25 ;
  %let sz = .3 CM ;
  ods graphics / imagename = "enroll_counts" ;
  title2 "Enrollee Counts Over Time (larger sites plotted against right-hand y-axis)" ;
  proc sgplot data = ax nocycleattrs ;
    * loess x = year y = total_count / group = site_name smooth = &B lineattrs = (thickness = &th pattern = solid) ;
    * loess x = year y = high_count  / group = site_name smooth = &B lineattrs = (thickness = &th pattern = solid) y2axis ;

    series x = year y = total_count / group = site_name lineattrs = (thickness = &th pattern = solid) markers MARKERATTRS = (size = &sz) name = 'normalsites' ;
    series x = year y = high_count  / group = site_name lineattrs = (thickness = &th pattern = solid) markers MARKERATTRS = (size = &sz) y2axis ;
    xaxis grid display = (nolabel) ;
    yaxis grid ;
    * keylegend / location = inside position = topleft noborder ;
    * keylegend / noborder across = 4 ;
    keylegend 'normalsites' / noborder ;
    where year between &start_year and &end_year ;
  run ;

  title2 "Enrollee Counts Over Time--all HCSRN Sites Aggregated" ;
  proc sgplot data = total_enrollments nocycleattrs ;
    series x = year y = total_count / lineattrs = (thickness = &th pattern = solid) markers MARKERATTRS = (size = &sz) name = 'normalsites' ;
    xaxis grid display = (nolabel) ;
    yaxis grid display = (nolabel) values = (0 to 18000000 by 3000000) ;
    * keylegend / location = inside position = topleft noborder ;
    * keylegend / noborder across = 4 ;
    where year between &start_year and &end_year ;
  run ;

  title2 "Person/Years Per Organization" ;
  proc sql ;
    create table tpy as
    select site, site_name label = "HMORN Site"
        , sum(total_count) as person_years format = comma12.0 label = "Total no. of person/years"
    from col.raw_enrollment_counts
    group by site, site_name
    ;

    create table tpy2 as
    select t.*
          , d.total_count as demog_count
          , t.person_years/d.total_count as years_per_demog_person label = "Enrollment years per MRN in Demographics"
    from tpy as t INNER JOIN
         col.raw_demog_counts as d
    on   t.site = d.site
    ;

    create table tpy as
    select * from tpy2
    ;

    * select * from tpy ;
    create table py_dur as
    select t.*
          , duration_p25
          , duration_p50
          , duration_p75
    from  tpy as t LEFT JOIN
          col.enroll_duration_stats as e
    on    t.site = e.site
    ;
  quit ;

  data col.py_dur ;
    set py_dur ;
  run ;

  proc print data = tpy label ;
    id site_name ;
    var person_years demog_count years_per_demog_person ;
    sum person_years demog_count ;
    format person_years demog_count comma12.0 years_per_demog_person 5.2 ;
  run ;

  proc sgplot data = tpy ;
    dot site_name / response = person_years categoryorder = respdesc ;
    xaxis grid ;
  run ;

  title2 "Breadth vs Depth: Total Person/Years by Duration of Typical Enrollment Period" ;
  ods graphics / imagename = "py_x_duration" ;
  proc sgplot data = py_dur noautolegend ;
    scatter x = person_years y = duration_p50 / group = site
                                                yerrorlower = duration_p25
                                                yerrorupper = duration_p75
                                                errorbarattrs = (thickness = .7mm)
                                                datalabel = site
                                                datalabelattrs = (size = 4mm)
                                                markerattrs = (symbol = circlefilled size = 3mm)
                                                ;
    xaxis grid type = log label = "Total no. person-years (log scale)"; * values = (&earliest to "31dec2010"d by month ) ;
    yaxis grid label = "Typical Enrollment Duration in months (median + 25th/75th percentiles)" ;
    where duration_p50 ;
  run ;

  title2 "Enrollment Variables (data between &start_year and &end_year only)" ;
  title3 "Enrollee Ages (as of 1-January of each Year)" ;
  ods graphics / imagename = "age_groups" ;
  proc sgpanel data = agegroups ;
    panelby site / novarname uniscale = column columns = 5 rows = 4 ;
    series x = year y = pct / group = value lineattrs = (thickness = &th pattern = solid) ;
    colaxis grid ;
    rowaxis grid ;
    format pct percent8.0 ;
  run ;
  ods graphics / imagename = "enroll_vars" ;
  title3 "Trends over time" ;
  proc sgpanel data = gnu ;
    panelby site / novarname uniscale = column columns = 5 rows = 4 ;
    series x = year y = pct / group = value lineattrs = (thickness = &th pattern = solid) ;
    colaxis grid ;
    rowaxis grid ;
    by vcat var_name ;
    format var_name $vars. pct percent8.0 ;
  run ;

  title3 "Race: Non-White, Non-Unknown" ;
  proc sgpanel data = gnu ;
    panelby site / novarname uniscale = column columns = 5 rows = 4 ;
    series x = year y = pct / group = value lineattrs = (thickness = &th pattern = solid) ;
    colaxis grid ;
    rowaxis grid ;
    by vcat var_name ;
    format var_name $vars. pct percent8.0 ;
    where var_name = 'race' and value not in ('Unknown', 'White') ;
  run ;

  proc sort data = gnu ;
    by site ;
    where var_name = 'sexual_orientation1' ;
  run ;


  ods graphics / imagename = "sexual_orientation" ;
  title3 "Sexual Orientation (unknowns elided)" ;
  proc sgpanel data = gnu ;
    panelby site / novarname uniscale = column columns = 3 rows = 5 ;
    series x = year y = pct / group = value lineattrs = (thickness = &th pattern = solid) ;
    colaxis grid ;
    rowaxis grid ;
    format var_name $vars. pct percent8.0 ;
  run ;

  proc sgplot data = gnu ;
    series x = year y = pct / group = value lineattrs = (thickness = &th pattern = solid) ;
    xaxis grid ; * values = (&earliest to "31dec2010"d by month ) ;
    yaxis grid ;
    format var_name $vars. pct percent8.0 ;
    by site ;
  run ;

%mend report ;

%macro report_demog() ;
  proc sort data = col.demog_freqs out = gnu ;
    by var_name sex_admin value site ;
    where value not in ('unk', 'und') and var_name not in ('race2', 'race3', 'race4', 'race5') ;
    * where var_name in ('hispanic') ; * AND value not in ('U', 'N') ;
  run ;

  data generic lang race ;
    set gnu ;
    pct2 = 100 * coalesce(pct, 0) ;
    select(var_name) ;
      when('primary_language') do ;
        if value = 'unk' then value = 'und' ;
        if value not in ('und', 'eng', 'spa') then lang_type = 'uncommon' ;
        else lang_type = 'common' ;
        if pct > 0 then output lang ;
      end ;
      when('race1') do ;
        if value not in ('WH', 'UN') then race_type = 'uncommon' ;
        else race_type = 'common' ;
        if pct > 0 then output race ;
      end ;
      otherwise output generic ;
    end ;

    label
      pct2 = "Percent of records"
    ;
  run ;

  title2 "Demographics Descriptives" ;
  ods graphics / imagename = "demog_vars" ;
  proc sgpanel data = generic ;
    panelby sex_admin / novarname uniscale = column ;
    * vbar site / response = pct2 group = sex_admin stat = sum ;
    vbar site / response = pct2 group = value stat = sum ;
    by var_name ;
    format sex_admin $gen. ;
  run ;

  title3 "Common Values for Language" ;
  ods graphics / imagename = "common_language" ;
  proc sgpanel data = lang ;
    panelby sex_admin / novarname uniscale = column ;
    * vbar site / response = pct2 group = sex_admin stat = sum ;
    vbar site / response = pct2 group = value stat = sum ;
    format sex_admin $gen. ;
    where lang_type = 'common' ;
  run ;

  title3 "Uncommon Values for Language" ;
  ods graphics / imagename = "uncommon_language" ;
  proc sgpanel data = lang ;
    panelby sex_admin / novarname uniscale = column ;
    * vbar site / response = pct2 group = sex_admin stat = sum ;
    vbar site / response = pct2 group = value stat = sum ;
    format sex_admin $gen. ;
    where lang_type = 'uncommon' ;
  run ;

  title3 "Common Values for Race" ;
  ods graphics / imagename = "common_race" ;
  proc sgpanel data = race ;
    panelby sex_admin / novarname uniscale = column ;
    * vbar site / response = pct2 group = sex_admin stat = sum ;
    vbar site / response = pct2 group = value stat = sum ;
    where race_type = 'common' ;
    format value $race. sex_admin $gen. ;
  run ;

  title3 "Uncommon Values for Race" ;
  ods graphics / imagename = "uncommon_race" ;
  proc sgpanel data = race ;
    panelby sex_admin / novarname uniscale = column ;
    * vbar site / response = pct2 group = sex_admin stat = sum ;
    vbar site / response = pct2 group = value stat = sum ;
    where race_type = 'uncommon' ;
    format value $race. sex_admin $gen. ;
  run ;
%mend report_demog ;

%macro report_correlations(inset = col.flagcorr) ;
  proc sql noprint ;
    select site
      into :allnulls separated by '", "'
    from (
        select site, r,  count(*) as num_vals
        from &inset
        group by site, r)
    group by site
    having count(*) = 1
    ;
  quit ;

  * From https://support.sas.com/techsup/notes/v8/4/739.html ;
  ods path(prepend) work.templat(update);

  proc template;
    define statgraph corrHeatmap;
     dynamic _BYVAL_ ;
      begingraph;
        entrytitle _BYVAL_ ;
        rangeattrmap name='map';
        /* select a series of colors that represent a "diverging"  */
        /* range of values: stronger on the ends, weaker in middle */
        /* Get ideas from http://colorbrewer.org                   */
        range -1 - 1 / rangecolormodel=(cx483D8B  cxFFFFFF cxDC143C);
        endrangeattrmap;
        rangeattrvar var=r attrvar=r attrmap='map';
        layout overlay /
          xaxisopts=(display=(line ticks tickvalues))
          yaxisopts=(display=(line ticks tickvalues));
          heatmapparm x = x y = y colorresponse = r /
            xbinaxis=false ybinaxis=false
            name = "heatmap" display=all;
          continuouslegend "heatmap" /
            orient = vertical location = outside title="Pearson Correlation";
        endlayout;
      endgraph;
    end;
  run;

  options nobyline ;

  title2 "Correlations Between Insurance and Plan Type Flags" ;

  ods graphics / imagename = "ins_plan_corr" ;
  proc sgrender data = &inset template = corrHeatmap ;
    by site ;
    where site not in ("&allnulls", 'HFHS') ; /* hard-coding henry ford b/c when we have them it produces a weird java error. */
    format site $s. ;
  run;

  options byline ;
%mend report_correlations ;

%regen ;
* endsas ;

ods listing close ;

options orientation = landscape ;
ods graphics / height = 6in width = 10in  maxlegendarea = 25 ;

%let out_folder = \\groups\data\CTRHS\Crn\voc\enrollment\reports_presentations\output\ ;

ods html5 path = "&out_folder" (URL=NONE)
         body   = "enroll_demog_qa.html"
         (title = "Enrollment + Demographics QA Output")
         style = magnify
         nogfootnote
         device = svg
         options(svg_mode = "embed")
          ;
ods word file = "&out_folder.enroll_demog_qa.docx" ;

  title1 "Enrollment/Demographics QA Report" ;

%macro overview ;
  proc sql number ;
    * describe table dictionary.tables ;
    create table submitting_sites as
    select put(prxchange("s/(.*)_TIER_ONE_RESULTS\s*$/$1/i", -1, memname), $s.) as site label = "Site"
        , datepart(crdate) as date_submitted format = mmddyy10. label = "QA Submission Date"
    from dictionary.tables
    where libname = 'RAW' and memname like '%_TIER_ONE_RESULTS'
    ;

    * insert into submitting_sites (site) values ("St. Louis U/AHEAD") ;

    alter table submitting_sites add primary key (site) ;

    create table col.submitting_sites as
    select * from submitting_sites
    ;
  quit ;

  title2 "Sites submitting QA Results" ;
  ods graphics / imagename = "submitting_sites" ;
  proc sgplot data = submitting_sites ;
    dot site / response = date_submitted ;
    xaxis grid min='01-jul-2022'd ;
  run ;

  proc sql number ;
    * The full table is way too wide for the rtf output--cut it out of there. ;
    ods word exclude all ;

    title2 "Tier One (objective) checks--overall" ;
    select * from col.tier_one_results (drop = qa_macro) ;

    reset nonumber ;
    ods word ;

    * We decided in I want to say 2020 not to fuss over fails w/percents that round to zero. ;
    create table nn as
    select *
    from col.norm_tier_one_results
    where result not in ('pass') AND (round(percent_bad, .01) > 0 OR percent_bad is null)
    ;

    /* Fetch cached status (if previously known) from the mem access db */
    create table significant_nonpasses as
    select n.*
          , case
              when n.result = 'fail' and r.issue_status is null then 'NOT YET LOGGED'
              else r.issue_status
            end as issue_status
    from  nn as n LEFT JOIN
          mem.remembered_nonpasses as r
    on    n.site = r.site AND
          n.description = r.description
    ;

    title2 "Tier One--checks that tripped any failures or warnings" ;
    footnote1 "See the VDW Issue Tracker for current status on all issues" ;
    footnote2 "https://www.hcsrn.org/share/page/site/VDW/data-lists?list=f3c5ef15-334b-47f4-b6d3-aee37bedc057" ;
    select description
          , warn_lim / 100 format = thrs. label = "Warn Threshold"
          , fail_lim / 100 format = thrs. label = "Fail Threshold"
          , sum(case when result = 'fail' then 1 else 0 end) as num_fails label = "Fails"
          , sum(case when result in ('warn', 'warning') then 1 else 0 end) as num_warns label = "Warnings"
          , sum(case when result = 'pass' then 1 else 0 end) as num_passes label = "Passes"
          , sum(case when result = 'pass' then 1 else 0 end) / count(*) as pct_passes label = "Percent of Sites Passing" format = percent6.0
    from significant_nonpasses
    group by description, warn_lim, fail_lim
    order by 7
    ;
  quit ;

  title2 "Tier One--Non-Passes By Implementing Site" ;
  proc report data = significant_nonpasses ;
    column sitename table description result num_bad percent_bad issue_status ;
    define sitename / group 'Site' ;
    define table / 'Table' ;
    define description / 'Check' ;
    define result / 'Result' ;
    define num_bad / 'No. recs offending' ;
    define percent_bad / 'Pct. recs offending' ;
    define issue_status / 'Issue Status (if logged)' ;

    compute issue_status ;
      call define(_col_, "URLP", "&issue_url") ;
    endcomp ;
    where result ne 'pass' ;
  quit ;
  footnote "Program file: &program_file " ;
%mend overview ;

%macro plot_data_rates(inset = col.rx_rates, incvar = incomplete_outpt_rx, tit = %str(Outpatient Pharmacy), extr = , rows = 4) ;

  proc sort data = &inset out = gnu ;
    by site first_day &incvar ;
    where n gt 200 /* and rate gt 0 */ and first_day ge '01-jan-1986'd ;
  run ;

  ods graphics / imagename = "&incvar" ;

  title2 "&tit" ;

  proc sgpanel data = gnu dattrmap = line_colors ;
    panelby site / novarname columns = 4 rows = &rows ;
    /* options I tried to get out of the segfault when doing tumor: smooth = .2  interpolation = linear */
    loess x = first_day y = rate / group = &incvar attrid = lc ;
    * format site $s. ;
    format site $s. ;
    rowaxis grid label = "Records per Enrollee" &extr ;
    colaxis grid display = (nolabel) ;
    * where put(site, $s.) ne 'gotohell' ;
  run ;
%mend plot_data_rates ;

%macro plot_unenrolled_rates(inset = col.lab_unenrolled, tit = , rows = 3, tot_crit = ) ;
  proc sort data = &inset out = gnu ;
    by site first_day ;
    %if %length(&tot_crit) > 2 %then %do ;
      where n_total > &tot_crit ;
    %end ;
  run ;

  title2 "Proportion of &tit records for people not enrolled at the time." ;
  proc sgpanel data = gnu ;
    panelby site / novarname columns = 4 rows = &rows ;
    loess x = first_day y = calc_prop_unenrolled / nolegfit ;
    format site $s. calc_prop_unenrolled percent6.1 ;
    rowaxis grid display = (nolabel) ;
    colaxis grid display = (nolabel) ;
  run ;
%mend plot_unenrolled_rates ;

  %overview ;

  %report ;

  %report_correlations ;

  %report_demog ;

  title2 "Language Statistics" ;
  proc sql ;
    select site format = $s.
          , lang_recs   format = comma12.0 label = "Total # Records In File"
          , lang_subj   format = comma12.0 label = "Unique MRNs In File"
          , lang_eng    format = comma12.0 label = "Unique English Speakers In File"
          , lang_ne     format = comma12.0 label = "Unique Non-English Speakers In File"
          , lang_mult   format = comma12.0 label = "MRNs With > 1 Language"
          , use_mult    format = comma12.0 label = "MRNs With > 1 Use"
          , max_lang    format = comma12.0 label = "Max # Langs For An MRN"
          , lang_count  format = comma12.0 label = "# Unique Languages In File"
    from col.lang_stats
    where lang_recs > 1
    ;
    create table vars as
    select put(site, $s.) as Site, dset, outcome, name as variable, put(o_type, vtype.) as type, coalesce(label, '[no label]') as label
    from col.noteworthy_vars
    order by 1, 2, 3, 4
    ;
  quit ;

  %plot_data_rates(inset = col.rx_rates   , incvar = incomplete_outpt_rx, tit = %str(Outpatient Pharmacy)        ) ;
  %plot_data_rates(inset = col.lab_rates  , incvar = incomplete_lab     , tit = %str(Lab Results)                ) ;
  %plot_data_rates(inset = col.tumor_rates, incvar = incomplete_tumor   , tit = %str(Tumor)                      , extr = %str(max = 0.0015), rows = 4) ;
  %plot_data_rates(inset = col.emr_s_rates, incvar = incomplete_emr     , tit = %str(EMR Data (Social History))  ) ;
  %plot_data_rates(inset = col.emr_v_rates, incvar = incomplete_emr     , tit = %str(EMR Data (Vital Signs))  , extr = %str(max = 1.6)) ;

  %plot_data_rates(inset = col.ute_out_rates_by_enctype (where = (extra = 'AV')) , incvar = incomplete_outpt_enc , tit = %str(Ambulatory Visits), extr = %str(max = 2), rows = 5) ;
  %plot_data_rates(inset = col.ute_in_rates_by_enctype  (where = (extra = 'IP')) , incvar = incomplete_inpt_enc  , tit = %str(Inpatient Stays), extr = %str(max = .020), rows = 5) ;

  %let unrows = 4 ;

  %plot_unenrolled_rates(inset = col.enc_unenrolled, tit = %str(Encounters), rows  = 5, tot_crit = 1000) ;
  %plot_unenrolled_rates(inset = col.lab_unenrolled, tit = %str(Lab Results), rows = &unrows, tot_crit = 1000) ;
  %plot_unenrolled_rates(inset = col.rx_unenrolled, tit = %str(Rx Fills), rows  = &unrows, tot_crit = 1000) ;
  %plot_unenrolled_rates(inset = col.shx_unenrolled, tit = %str(Social History), rows  = &unrows, tot_crit  = 2000) ;
  %plot_unenrolled_rates(inset = col.vsn_unenrolled (where = (site not in ('BSWH', 'HPHC'))), tit = %str(Vital Signs), rows  = &unrows, tot_crit = 1000) ;
  %plot_unenrolled_rates(inset = col.tum_unenrolled (where = (site not in ('BSWH', 'HPHC', 'PAMF'))), tit = %str(Tumors), rows = 4, tot_crit = 5) ;

  title2 "Noteworthy Variables" ;
  proc report nowd data=vars ;
    define site / group ;
    define dset / group ;
    define label / width = 100 ;
  run;

/*
*/

ods _all_ close ;

