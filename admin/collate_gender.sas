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
  mprint
  mlogic
;

%let prgs = \\groups\data\CTRHS\Crn\voc\enrollment\programs ;

libname raw "&prgs\submitted_data\raw" ;
libname col "&prgs\submitted_data" ;

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
    "KPH"  = "KP Hawaii"
    "FA"   = "Fallon Community HP"
    "KPMA" = "KP Mid-Atlantic"
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
    'O' = 'Other Gender'
    'U' = 'Unknown Gender'
  ;
  value $sexadm
    'F'   = 'Female'
    'M'   = 'Male'
    'X'   = 'Neither Male Nor Female'
    'O'   = 'Other'
    'U'   = 'Unknown /uncertain / missing'
    other = 'bad'
  ;
  value $sexaab
    'F'   = 'Female'
    'M'   = 'Male'
    'I'   = 'Intersex'
    'O'   = 'Other'
    'U'   = 'Uncertain, Unknown or Not recorded on birth certificate'
    'C'   = 'Choose not to disclose'
    other = 'bad'
  ;
  value $gi
    'FF'  = 'Female'
    'MM'  = 'Male'
    'FM'  = 'F to M'
    'MF'  = 'M to F'
    'GQ'  = 'Genderqueer'
    'OT'  = 'Other'
    'ND'  = 'Undisclosed'
    'UN'  = 'Unknown'
    other = 'bad'
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

quit ;

%macro msk(dset) ;
  proc sql ;
    update &dset
    set count = .a, percent = .a, pct_row = .a, pct_col = .a
    where count le 10
    ;
  quit ;
%mend msk ;

%macro regen ;

  %stack_datasets(inlib = raw, nom = sex_admin_counts, outlib = col) ;
  %stack_datasets(inlib = raw, nom = gender_identity_counts, outlib = col) ;
  %stack_datasets(inlib = raw, nom = sex_at_birth_counts, outlib = col) ;
  %stack_datasets(inlib = raw, nom = gender_results, outlib = col) ;

  %msk(dset = col.sex_admin_counts) ;
  %msk(dset = col.gender_identity_counts) ;
  %msk(dset = col.sex_at_birth_counts) ;

  data res ;
    set col.gender_results ;
    sitename = put(site, $s.) ;
  run ;

  proc sort data = res ;
    by check site ;
  run ;

  proc transpose data = res out = tposed (drop = _:) ;
    var result ;
    id site ;
    idlabel sitename ;
    by check ;
  run ;

  data col.gender_results ;
    set tposed ;
  run ;

%mend regen ;

* %regen ;

  proc sql number ;
    * describe table dictionary.tables ;
    create table submitting_sites as
    select put(prxchange("s/(.*)_SEX_ADMIN_COUNTS\s*$/$1/i", -1, memname), $s.) as site label = "Site" length = 40
        , datepart(crdate) as date_submitted format = mmddyy10. label = "QA Submission Date"
    from dictionary.tables
    where libname = 'RAW' and memname like '%_SEX_ADMIN_COUNTS'
    ;

    create table not_yet_submitted as
    select label as site length = 40
    from sites
    where fmtname = 'S' and label not in (select site from submitting_sites)
    ;
    insert into submitting_sites(site)
    select site
    from not_yet_submitted
    ;

    create table col.gs_submitting_sites as
    select * from submitting_sites
    ;
  quit ;

%macro show_interesting_pcts(dset = , var = , fmt = , panopts = %str(columns = 3 rows = 5)) ;

  proc freq data = &dset order = freq noprint ;
    tables &var * site / missing format = comma9.0 out = gi_freqs outpct ;
    weight count ;
  run ;

  proc sgpanel data = gi_freqs ;
    panelby site / novarname &panopts uniscale = column ;
    vbar &var / response = pct_col ;
    rowaxis grid ;
    colaxis display = (nolabel) ;
    format site $s. &var &fmt ;
    where &var not in ('UN', 'U') ;
    attrib pct_col label = "Percent of Records in DEMOGRAPHICS" ;
  run ;

  proc sgpanel data = gi_freqs ;
    panelby site / novarname &panopts ;
    vbar &var / response = pct_col ;
    rowaxis grid ;
    colaxis display = (nolabel) ;
    format site $s. &var &fmt ;
    where &var not in ('UN', 'U') ;
    attrib pct_col label = "Percent of Records in DEMOGRAPHICS" ;
  run ;
%mend show_interesting_pcts ;


options orientation = landscape ;
ods graphics / height = 8in width = 10in ;

%let out_folder = \\groups\data\CTRHS\Crn\voc\enrollment\reports_presentations\gendersex ;

ods listing close ;
ods html5 path = "&out_folder" (URL=NONE)
         body   = "collate_gender.html"
         (title = "collate_gender output")
         style = magnify
         nogfootnote
         device = svg
          ;

* ods word file = "&out_folder.collate_gender.docx" ;

  title1 "Gender/Sex Mini-QA" ;
  title2 "Sites submitting Results" ;
  ods graphics / imagename = "submitting_sites" ;
  proc sgplot data = submitting_sites ;
    dot site / response = date_submitted markerattrs= (size = 5mm symbol = circlefilled) ;
    xaxis grid max='04-mar-2021'd ;
  run ;

  proc print label  data = col.gender_results ;
    id check ;
  run ;

  proc sql noprint ;
    create table sex_agreement as
    select site, sum(percent) as percent_agrees
    from col.sex_admin_counts
    where sex_admin = gender
    group by site
    ;
  quit ;

  title2 "Agreement between the old GENDER var and the new SEX_ADMIN var" ;
  proc sgplot data = sex_agreement ;
    hbar site / response = percent_agrees ;
    format site $s. ;
    xaxis grid label = "Percent Agreement" ;
    yaxis display = (nolabel) ;
  run ;

  title2 "Gender Identity" ;
  %show_interesting_pcts(dset = col.gender_identity_counts, var = gender_identity, fmt = $gi.) ;

  title2 "Administrative Sex" ;
  %show_interesting_pcts(dset = col.sex_admin_counts, var = sex_admin, fmt = $sexadm., panopts = %str(columns = 4 rows = 4)) ;

  title2 "Sex Assigned At Birth" ;
  %show_interesting_pcts(dset = col.sex_at_birth_counts, var = sex_at_birth, fmt = $sexaab.) ;

run ;

ods _all_ close ;






%macro overview ;
  proc sql number ;
    * describe table dictionary.tables ;
    create table submitting_sites as
    select put(prxchange("s/(.*)_TIER_ONE_RESULTS\s*$/$1/i", -1, memname), $s.) as site label = "Site"
        , datepart(crdate) as date_submitted format = mmddyy10. label = "QA Submission Date"
    from dictionary.tables
    where libname = 'RAW' and memname like '%_TIER_ONE_RESULTS'
    ;

    create table col.submitting_sites as
    select * from submitting_sites
    ;
  quit ;

  title2 "Sites submitting QA Results" ;
  ods graphics / imagename = "submitting_sites" ;
  proc sgplot data = submitting_sites ;
    dot site / response = date_submitted ;
    xaxis grid ; * min='04-mar-2017'd ;
  run ;

  proc sql number ;
    * The full table is way too wide for the rtf output--cut it out of there. ;
    ods tagsets.rtf exclude all ;

    title2 "Tier One (objective) checks--overall" ;
    select * from col.tier_one_results (drop = qa_macro) ;

    reset nonumber ;
    ods tagsets.rtf ;

    create table nn as
    select *
    from col.norm_tier_one_results
    where result not in ('pass') AND (round(percent_bad, .01) > 0 OR percent_bad is null)
    ;

    /* Fetch cached status (if previously known) from the mem access db */
    create table nonnegligible_nonpasses as
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
    select description
          , warn_lim / 100 format = thrs. label = "Warn Threshold"
          , fail_lim / 100 format = thrs. label = "Fail Threshold"
          , sum(case when result = 'fail' then 1 else 0 end) as num_fails label = "Fails"
          , sum(case when result in ('warn', 'warning') then 1 else 0 end) as num_warns label = "Warnings"
          , sum(case when result = 'pass' then 1 else 0 end) as num_passes label = "Passes"
          , sum(case when result = 'pass' then 1 else 0 end) / count(*) as pct_passes label = "Percent of Sites Passing" format = percent6.0
    from col.norm_tier_one_results
    where description in (select description from nonnegligible_nonpasses)
    group by description, warn_lim, fail_lim
    order by 7
    ;
  quit ;
  ods tagsets.rtf text = "See the VDW Issue Tracker for current status on all issues" ;
  ods tagsets.rtf text = "https://www.hcsrn.org/share/page/site/VDW/data-lists?list=f3c5ef15-334b-47f4-b6d3-aee37bedc057" ;

  title2 "Tier One--Non-Passes By Implementing Site" ;
  * proc report data = col.norm_tier_one_results ;
  *   column sitename table, result ;
  *   define sitename / group 'Site' ;
  *   define table  / '' across ; *format = $tb. ;
  *   define result / '' across order = freq descending ; * format = $res. ;
  *   where table ne 'All' ;
  * quit ;

  * ods tagsets.rtf exclude all ;

  proc report data = nonnegligible_nonpasses ;
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
  ods tagsets.rtf text = "See the VDW Issue Tracker for current status on all issues" ;
  ods tagsets.rtf text = "https://www.hcsrn.org/share/page/site/VDW/data-lists?list=f3c5ef15-334b-47f4-b6d3-aee37bedc057" ;

  ods tagsets.rtf ;

%mend overview ;

