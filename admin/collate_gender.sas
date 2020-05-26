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
    'E'                 = 'External'
    'K'                 = 'Yes, known to be incomplete'
    'X'                 = 'Not implemented'
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
      'incomplete_emr'      = 'Capture of EMR data known incomplete?'
      'incomplete_inpt_enc' = 'Capture of inpatient encounters known incomplete?'
      'incomplete_lab'      = 'Capture of lab results known incomplete?'
      'incomplete_outpt_enc'= 'Capture of outpatient encounters known incomplete?'
      'incomplete_outpt_rx' = 'Capture of outpatient pharmacy known incomplete?'
      'incomplete_tumor'    = 'Capture of tumor data known incomplete?'
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
      'incomplete_emr'      = 'Meta'
      'incomplete_inpt_enc' = 'Meta'
      'incomplete_lab'      = 'Meta'
      'incomplete_outpt_enc'= 'Meta'
      'incomplete_outpt_rx' = 'Meta'
      'incomplete_tumor'    = 'Meta'
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

%regen ;

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

options orientation = landscape ;
ods graphics / height = 8in width = 10in ;

%let out_folder = \\groups\data\CTRHS\Crn\voc\enrollment\reports_presentations\gendersex ;

ods html5 path = "&out_folder" (URL=NONE)
         body   = "collate_gender.html"
         (title = "collate_gender output")
         style = magnify
         nogfootnote
         device = svg
          ;

ods word file = "&out_folder.collate_gender.docx" ;
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

