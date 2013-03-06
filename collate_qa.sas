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
    'HPHC' = 'Harvard'
    'HPRF' = 'HealthPartners'
    'MCRF' = 'Marshfield'
    'SWH'  = 'Scott & White'
    'HFHS' = 'Henry Ford'
    'GHS'  = 'Geisinger'
/*     'LCF'  = 'Lovelace' */
    'GHC'  = 'Group Health'
    'PAMF' = 'Palo Alto'
    'EIRH' = 'Essentia'
    'KPCO' = 'KP Colorado'
    'KPNW' = 'KP Northwest'
    'KPGA' = 'KP Georgia'
    "KPNC" = "KP Northern California"
    "KPSC" = "KP Southern California"
    "KPH"  = "KP Hawai'i"
    "FAL"  = "Fallon Community Health Plan"
    "LHS"  = "Lovelace Health Systems"
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
quit ;


%macro do_results() ;

  %stack_datasets(inlib = raw, nom = tier_one_results, outlib = work) ;

  proc sort data = tier_one_results(drop = detail_dset num_bad) ;
    by qa_macro description site ;
  run ;

  data tier_one_results ;
    set tier_one_results ;
    sitename = put(site, $s.) ;
    select(qa_macro) ;
      when ('%demog_tier_one') table = "Demographics" ;
      when ('%enroll_tier_one') table = "Enrollments" ;
      otherwise table = 'Both' ;
    end ;
    label
      description = "QA Check"
      table = "VDW Table"
    ;
  run ;

  proc sql ;
    * These guys got bit by a bug when running on a unix system--their fails were bogus. ;
    update tier_one_results
    set result = 'pass'
    where description = 'Are all vars in the spec in the dataset & of proper type?' and site in ('KPNC', 'KPMA')
    ;
  quit ;

  data col.norm_tier_one_results ;
    set tier_one_results ;
  run ;

  proc transpose data = tier_one_results out = col.tier_one_results(drop = _:) ;
    var result ;
    by qa_macro table description ;
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
            , sum(total) as total_count label = "No. of enrollment records ending on this date." format = comma12.0
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

  proc sql ;
    delete from col.enroll_freqs
    where var_name = 'enrollment_basis' and value = 'Y'
    ;
    delete from col.demog_freqs
    where var_name in ('primary_language', 'race1', 'race2', 'race3', 'race4', 'race5') and value = 'Y'
    ;
  quit ;

  %misc_wrangling ;

%mend regen ;

%macro report() ;
  proc sort data = col.enroll_freqs out = gnu ;
    by var_name value site year ;
    * where var_name in ('outside_utilization', 'plan_hmo', 'drugcov') and value in ('Y') ;
    *  Enforcing a minimal number of records, just to keep out e.g., the year in which FALLON had 100% of their 29 (or however many) records with ins_medicare = y. ;
    where year between 1990 and %sysfunc(year("&sysdate"d)) AND value not in ('U', 'N') and total ge 1000 ;
  run ;

  data gnu enrollment_basis ;
    length site $ 20 ;
    set gnu ;
    site = put(site, $s.) ;
    if var_name = 'enrollment_basis' then output enrollment_basis ;
    else output gnu ;
    label
      year = "Period end"
      pct = "Percent of *records* (not people)"
      var_name = "Variable"
    ;
  run ;

  title2 "Enrollment Variables (data between 1990 and 2012 only)" ;

  proc sgplot data = gnu ;
    series x = year y = pct / group = site lineattrs = (thickness = .1 CM) ;
    * loess x = year y = pct / group = site lineattrs = (thickness = .1 CM) ;
    yaxis grid ;
    by var_name value ;
  run ;

  title3 "Enrollment Basis" ;

  proc sgpanel data = enrollment_basis ;
    panelby value / columns = 2 rows = 2 novarname ;
    loess x = year y = pct / group = site smooth = .2 ;
    format value $eb. ;
    * where year between '01jan1990'd and "&sysdate"d ;
  run ;

  title3 "Raw record counts." ;
  proc sgpanel data = col.raw_enrollment_counts ;
    panelby site / columns = 2 rows = 2 uniscale = column novarname ;
    loess x = year y = total_count / smooth = .2 ;
    format site $s. ;
    where site ne 'KPNC' and year between '01jan1990'd and "&sysdate"d ;
  run ;
  proc sgpanel data = col.raw_enrollment_counts ;
    panelby site / columns = 2 uniscale = column novarname ;
    loess x = year y = total_count / smooth = .2 ;
    format site $s. ;
    where site eq 'KPNC' and year between '01jan1990'd and "&sysdate"d ;
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
    panelby gender / novarname ;
    * vbar site / response = pct2 group = gender stat = sum ;
    vbar site / response = pct2 group = value stat = sum ;
    by var_name ;
    format gender $gen. ;
  run ;

  title3 "Common Values for Language" ;
  proc sgpanel data = lang ;
    panelby gender / novarname ;
    * vbar site / response = pct2 group = gender stat = sum ;
    vbar site / response = pct2 group = value stat = sum ;
    format gender $gen. ;
    where lang_type = 'common' ;
  run ;

  title3 "Uncommon Values for Language" ;
  proc sgpanel data = lang ;
    panelby gender / novarname ;
    * vbar site / response = pct2 group = gender stat = sum ;
    vbar site / response = pct2 group = value stat = sum ;
    format gender $gen. ;
    where lang_type = 'uncommon' ;
  run ;

  title3 "Common Values for Race" ;
  proc sgpanel data = race ;
    panelby gender / novarname ;
    * vbar site / response = pct2 group = gender stat = sum ;
    vbar site / response = pct2 group = value stat = sum ;
    where race_type = 'common' ;
    format value $race. gender $gen. ;
  run ;

  title3 "Uncommon Values for Race" ;
  proc sgpanel data = race ;
    panelby gender / novarname ;
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
    select description
          , sum(case when result = 'fail' then 1 else 0 end) as num_fails label = "Fails"
          , sum(case when result in ('warn', 'warning') then 1 else 0 end) as num_warns label = "Warnings"
          , sum(case when result = 'pass' then 1 else 0 end) as num_passes label = "Passes"
    from col.norm_tier_one_results
    where description in (select description from col.norm_tier_one_results where result in ('fail', 'warn', 'warning'))
    group by description
    order by 4
    ;
  quit ;

  %report ;

  %report_demog ;

  proc sql ;
    title2 "Noteworthy Variables" ;
    create table vars as
    select put(site, $s.) as Site, dset, outcome, name as variable, put(o_type, vtype.) as type, coalesce(label, '[no label]') as label
    from col.noteworthy_vars
    order by 1, 2, 3, 4
    ;
  quit ;

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
