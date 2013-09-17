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

%include "\\home\pardre1\SAS\Scripts\remoteactivate.sas" ;

options
  linesize  = 150
  msglevel  = i
  formchar  = '|-++++++++++=|-/|<>*'
  dsoptions = note2err
  nocenter
  noovp
  nosqlremerge
  mprint
;

libname raw "\\groups\data\CTRHS\Crn\voc\enrollment\programs\qa_results\raw" ;
libname col "\\groups\data\CTRHS\Crn\voc\enrollment\programs\qa_results" ;

* We need this so that lowest_count is defined. ;
%include "//ghrisas/Warehouse/Sasdata/CRN_VDW/lib/StdVars.sas" ;
%include "\\groups\data\CTRHS\Crn\voc\enrollment\programs\staging\qa_formats.sas" ;

/* %include "//ghrisas/Warehouse/Sasdata/CRN_VDW/lib/StdVars.sas" ;
%include vdw_macs ;
 */

proc format cntlout = sites ;
  value $s
    /* 'HPRF' = 'HealthPartners' */
    /* 'LCF'  = 'Lovelace' */
    /* "FAL"  = "Fallon Community Health Plan" */
    /* "LHS"  = "Lovelace Health Systems" */
    'HPHC' = 'Harvard'
    'HPI'  = 'HealthPartners'
    'MCRF' = 'Marshfield'
    'SWH'  = 'Scott & White'
    'HFHS' = 'Henry Ford'
    'GHS'  = 'Geisinger'
    'GHC'  = 'Group Health'
    'PAMF' = 'Palo Alto'
    'EIRH' = 'Essentia'
    'KPCO' = 'KP Colorado'
    'KPNW' = 'KP Northwest'
    'KPGA' = 'KP Georgia'
    "KPNC" = "KP Northern California"
    "KPSC" = "KP Southern California"
    "KPH"  = "KP Hawaii"
    "FA"  = "Fallon Community HP"
    "KPMA" = "KP Mid-Atlantic"
  ;
  value $race
    'HP' = 'Native Hawaiian or Other Pacific Islander'
    'IN' = 'American Indian/Alaska Native'
    'AS' = 'Asian'
    'BA' = 'Black or African American'
    'WH' = 'White'
    'MU' = 'More than one race, particular races unknown or not reported'
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
    'O' = 'Other Gender'
    'U' = 'Unknown Gender'
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
    'M'                 = 'Male'
    'F'                 = 'Female'
    'O'                 = 'Other'
    'Y'                 = 'Yes'
    'N'                 = 'No'
    'U'                 = 'Unknown'
  ;
  value $vars
      'agegroup'            = 'Age of Enrollees'
      'drugcov'             = 'Has at least "some" drug coverage?'
      'enrollment_basis'    = 'Basis for including this person/period in Enrollment'
      'gender'              = 'Gender'
      'hispanic'            = 'Is Hispanic?'
      'ins_commercial'      = 'Has Commercial Coverage?'
      'ins_highdeductible'  = 'Has coverage in a High Deductible Plan?'
      'ins_medicaid'        = 'Has Medicaid coverage?'
      'ins_medicare'        = 'Has Medicare coverage?'
      'ins_medicare_a'      = 'Has medicare part A coverage?'
      'ins_medicare_b'      = 'Has medicare part B coverage?'
      'ins_medicare_c'      = 'Has medicare part C coverage?'
      'ins_medicare_d'      = 'Has medicare part D coverage?'
      'ins_other'           = 'Has "other" type insurance coverage?'
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
  ;
  value $varcat
      'agegroup'            = 'Demogs'
      'gender'              = 'Demogs'
      'hispanic'            = 'Demogs'
      'race'                = 'Demogs'
      'needs_interpreter'   = 'Demogs'
      'drugcov'             = 'Benefit'
      'enrollment_basis'    = 'Meta'
      'outside_utilization' = 'Meta'
      'pcc_probably_valid'  = 'Meta'
      'pcp_probably_valid'  = 'Meta'
      'ins_commercial'      = 'Ins type'
      'ins_highdeductible'  = 'Ins type'
      'ins_medicaid'        = 'Ins type'
      'ins_medicare'        = 'Ins type'
      'ins_medicare_a'      = 'Ins type'
      'ins_medicare_b'      = 'Ins type'
      'ins_medicare_c'      = 'Ins type'
      'ins_medicare_d'      = 'Ins type'
      'ins_other'           = 'Ins type'
      'ins_privatepay'      = 'Ins type'
      'ins_selffunded'      = 'Ins type'
      'ins_statesubsidized' = 'Ins type'
      'plan_hmo'            = 'Plan type'
      'plan_indemnity'      = 'Plan type'
      'plan_pos'            = 'Plan type'
      'plan_ppo'            = 'Plan type'
  ;
quit ;


%macro do_results() ;

  %stack_datasets(inlib = raw, nom = lang_stats, outlib = col) ;

  %stack_datasets(inlib = raw, nom = tier_one_results, outlib = work) ;

  proc sort data = tier_one_results(drop = detail_dset num_bad) ;
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

  %stack_datasets(inlib = raw, nom = &nom, outlib = work) ;

  %let fmt = ;

  proc sql ;
    create table tots as
    select  site, &byvar, var_name, sum(count) as total, count(*) as num_recs
    from    &nom
    group by site, &byvar, var_name
    ;

    create table nom as
    select r.site, r.var_name, r.&byvar &fmt., r.value, t.total, r.count / t.total as pct format = percent8.2
    from  &nom as r INNER JOIN
          tots as t
    on    r.site = t.site AND
          r.&byvar = t.&byvar AND
          r.var_name = t.var_name
    ;

    create table combos as
    select distinct site, var_name, &byvar, 'Y' as value
    from &nom
    ;

    create table supplement as
    select c.*
    from  combos as c LEFT JOIN
          nom as t
    on    c.site = t.site AND
          c.var_name = t.var_name AND
          c.&byvar = t.&byvar AND
          c.value = t.value
    where t.site IS NULL
    ;

    create table col.&nom as
    select site, var_name, &byvar &fmt., value, total, pct
    from nom
    UNION ALL
    select site, var_name, &byvar &fmt., 'Y' as value, 0 as total, 0 as pct
    from supplement
    order by var_name, value, site, &byvar
    ;

  quit ;

  /*
    variables can take any of several values.
    for any combos of site|var_name|year where value = Y that dont occur in the dset, add them in with count and pct of 0
  */

%mend do_freqs ;

%macro misc_wrangling() ;
  proc sql ;
    create table col.raw_enrollment_counts as
    select    site, year
            , max(total) as total_count label = "No. of enrollees" format = comma12.0
            , count(*) as num_recs
    from    col.enroll_freqs
    where var_name = 'outside_utilization'
    group by site, year
    ;
    create table col.raw_gender_counts as
    select site, gender, sum(total) as total_count, count(*) as num_recs
    from col.demog_freqs
    where var_name = 'hispanic'
    group by site, gender
    ;
  quit ;

%mend misc_wrangling ;


%macro regen() ;
  %do_results ;
  %do_vars ;
  %do_freqs(nom = enroll_freqs, byvar = year) ;
  %do_freqs(nom = demog_freqs, byvar = gender) ;

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
  proc sort data = col.enroll_freqs out = gnu ;
    by var_name value site year ;
    *  Enforcing a minimal number of records, just to keep out e.g., the year in which FALLON had 100% of their 29 (or however many) records with ins_medicare = y. ;
    * where year between 1990 and (%sysfunc(year("&sysdate"d)) -1) AND value not in ('U', 'N') and total ge 1000 ;
    where year between 1990 and (%sysfunc(year("&sysdate"d)) -1) /* AND value not in ('.', ' ') */ and total ge 1000 ;
  run ;

  data gnu agegroups ;
    length site $ 20 ;
    set gnu ;
    site = put(site, $s.) ;
    vcat = put(var_name, $varcat.) ;
    if value in ('.', ' ') then value = '<missing>' ;

    if var_name in ('pcc_probably_valid', 'pcp_probably_valid') then do ;
      if value = 'Y' then value = 'Probably' ;
      else if value = 'N' then value = 'Probably Not' ;
    end ;
    if var_name = 'enrollment_basis' and value =: 'Non-' then value = 'Non-member patient' ;
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

  title2 "Enrollment Variables (data between 1990 and 2012 only)" ;
  data ax ;
    length site_name $ 20 ;
    set col.raw_enrollment_counts ;
    if site in ('KPNC', 'KPSC') then do ;
      high_count = total_count - 100 ;
      total_count = . ;
    end ;
    site_name = put(site, $s.) ;
    label
      high_count = "No. of enrollees (larger sites)"
    ;
    format high_count comma12.0 ;
  run ;

  proc sort data = ax ;
    by site_name year ;
  run ;

  data col.drop_me ;
    set ax ;
    where year between 1990 and (year("&sysdate9."d) -1) ;
  run ;
  * proc sql ;
  *   insert into ax (year, site, high_count) values (2010, 'NSCH', 3600000) ;
  * quit ;

  %local th ;
  %let th = .06 CM ;

  title3 "Raw record counts." ;
  proc sgplot data = ax ;
    loess x = year y = total_count / group = site_name /* lineattrs = (thickness = &th pattern = solid) */ ;
    * series x = year y = high_count  / group = site_name lineattrs = (/* thickness = &th */ pattern = solid) MARKERATTRS = (size = .3cm) y2axis ;
    loess x = year y = high_count  / group = site_name  y2axis ;
    xaxis grid ;
    yaxis grid ;
    where year between 1990 and (year("&sysdate9."d) -1) ;
  run ;

  data s.ax ;
    set ax ;
  run ;

  title3 "Enrollee Ages (as of 1-January of each Year)" ;
  proc sgpanel data = agegroups ;
    panelby site / novarname uniscale = column columns = 4 rows = 4 ;
    series x = year y = pct / group = value lineattrs = (thickness = &th pattern = solid) ;
    * where year between 1990 and (year("&sysdate9."d) -1) ;
    colaxis grid ;
    rowaxis grid ;
    format pct percent8.0 ;
  run ;
  title3 "Trends over time" ;
  proc sgpanel data = gnu ;
    panelby site / novarname uniscale = column columns = 4 rows = 4 ;
    series x = year y = pct / group = value lineattrs = (thickness = &th pattern = solid) ;
    colaxis grid ;
    rowaxis grid ;
    by vcat var_name ;
    format var_name $vars. pct percent8.0 ;
  run ;

%mend report ;

%macro report_demog() ;
  proc sort data = col.demog_freqs out = gnu ;
    by var_name gender value site ;
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

  proc sgpanel data = generic ;
    panelby gender / novarname uniscale = column ;
    * vbar site / response = pct2 group = gender stat = sum ;
    vbar site / response = pct2 group = value stat = sum ;
    by var_name ;
    format gender $gen. ;
  run ;

  title3 "Common Values for Language" ;
  proc sgpanel data = lang ;
    panelby gender / novarname uniscale = column ;
    * vbar site / response = pct2 group = gender stat = sum ;
    vbar site / response = pct2 group = value stat = sum ;
    format gender $gen. ;
    where lang_type = 'common' ;
  run ;

  title3 "Uncommon Values for Language" ;
  proc sgpanel data = lang ;
    panelby gender / novarname uniscale = column ;
    * vbar site / response = pct2 group = gender stat = sum ;
    vbar site / response = pct2 group = value stat = sum ;
    format gender $gen. ;
    where lang_type = 'uncommon' ;
  run ;

  title3 "Common Values for Race" ;
  proc sgpanel data = race ;
    panelby gender / novarname uniscale = column ;
    * vbar site / response = pct2 group = gender stat = sum ;
    vbar site / response = pct2 group = value stat = sum ;
    where race_type = 'common' ;
    format value $race. gender $gen. ;
  run ;

  title3 "Uncommon Values for Race" ;
  proc sgpanel data = race ;
    panelby gender / novarname uniscale = column ;
    * vbar site / response = pct2 group = gender stat = sum ;
    vbar site / response = pct2 group = value stat = sum ;
    where race_type = 'uncommon' ;
    format value $race. gender $gen. ;
  run ;

%mend report_demog ;

%regen ;

options orientation = landscape ;
ods graphics / height = 6in width = 10in ;

%let out_folder = \\groups\data\CTRHS\Crn\voc\enrollment\reports_presentations\output\ ;

ods html path = "&out_folder" (URL=NONE)
         body   = "enroll_demog_qa.html"
         (title = "Enrollment + Demographics QA Output")
          ;

ods rtf file = "&out_folder.enroll_demog_qa.rtf" device = sasemf style = magnify ;

  footnote1 " " ;

  title1 "Enrollment/Demographics QA Report" ;
  proc sql number ;
    * describe table dictionary.tables ;
    create table submitting_sites as
    select put(prxchange("s/(.*)_TIER_ONE_RESULTS\s*$/$1/i", -1, memname), $s.) as site label = "Site"
        , datepart(crdate) as date_submitted format = mmddyy10. label = "Submission Date"
    from dictionary.tables
    where libname = 'RAW' and memname like '%_TIER_ONE_RESULTS'
    ;
    title2 "Sites submitting QA Results" ;
    select * from submitting_sites ;
    title2 "Sites that have not yet submitted QA Results" ;

    * select * from sites ;

    select label as site label = "Site"
    from sites
    where FMTNAME = 'S' AND label not in (select site from submitting_sites )
    order by label
    ;

    title2 "Tier One (objective) checks--overall" ;
    select * from col.tier_one_results (drop = qa_macro) ;

    reset nonumber ;

    title2 "Tier One--checks that tripped any failures or warnings" ;
    select description, warn_lim, fail_lim
          , sum(case when result = 'fail' then 1 else 0 end) as num_fails label = "Fails"
          , sum(case when result in ('warn', 'warning') then 1 else 0 end) as num_warns label = "Warnings"
          , sum(case when result = 'pass' then 1 else 0 end) as num_passes label = "Passes"
    from col.norm_tier_one_results
    where description in (select description from col.norm_tier_one_results where result in ('fail', 'warn', 'warning'))
    group by description, warn_lim, fail_lim
    order by 6
    ;
  quit ;

  %report ;

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

  title2 "Noteworthy Variables" ;
  proc report nowd data=vars ;
    define site / group ;
    define dset / group ;
    define label / width = 100 ;
  run;






 ods _all_ close ;

proc format ;
  value tob
    1 = "current user"
    2 = "never"
    3 = "quit/former user"
    4 = "passive"
    5 = "environmental exposure"
    6 = "not asked"
    7 = "conflicting"
  ;
quit ;
"somatheing"

