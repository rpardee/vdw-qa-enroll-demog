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
;

libname raw "\\groups\data\CTRHS\Crn\voc\enrollment\programs\qa_results\raw" ;
libname col "\\groups\data\CTRHS\Crn\voc\enrollment\programs\qa_results" ;

/* %include "//ghrisas/Warehouse/Sasdata/CRN_VDW/lib/StdVars.sas" ;
%include vdw_macs ;
 */

proc format ;
  value $s
    'HPHC' = 'Harvard'
    'HPRF' = 'HealthPartners'
    'MCRF' = 'Marshfield'
    'SWH'  = 'Scott & White'
    'HFHS' = 'Henry Ford'
    'GHS'  = 'Geisinger'
    'LCF'  = 'Lovelace'
    'GHC'  = 'Group Health'
    'PAMF' = 'Palo Alto'
    'EIRH' = 'Essentia'
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

  proc transpose data = tier_one_results out = col.tier_one_results(drop = _:) ;
    var result ;
    by qa_macro table description ;
    id site ;
    idlabel sitename ;
  run ;
%mend do_results ;

%macro do_freqs(nom, byvar = enr_end) ;

  %stack_datasets(inlib = raw, nom = &nom, outlib = work) ;

  proc sql ;
    create table tots as
    select  site, &byvar, var_name, sum(count) as total, count(*) as num_recs
    from    &nom
    group by site, &byvar, var_name
    ;

    create table nom as
    select r.site, r.var_name, r.&byvar, r.value, r.count / total as pct format = percent8.2
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
    select site, var_name, &byvar, value, pct
    from nom
    UNION ALL
    select site, var_name, &byvar, 'Y' as value, 0 as pct
    from supplement
    order by var_name, value, site, &byvar
    ;

  quit ;

  /*
    variables can take any of several values.
    for any combos of site|var_name|enr_end where value = Y that dont occur in the dset, add them in with count and pct of 0
  */

%mend do_freqs ;

%macro regen() ;
  %do_results ;
  %do_freqs(nom = enroll_freqs, byvar = enr_end) ;
  %do_freqs(nom = demog_freqs, byvar = gender) ;

  proc sql ;
    delete from col.enroll_freqs
    where var_name = 'enrollment_basis' and value = 'Y'
    ;
    delete from col.demog_freqs
    where var_name in ('primary_language', 'race1', 'race2', 'race3', 'race4', 'race5') and value = 'Y'
    ;
  quit ;

%mend regen ;

%macro report() ;
  proc sort data = col.enroll_freqs out = gnu ;
    by var_name value site enr_end ;
    * where var_name in ('outside_utilization', 'plan_hmo', 'drugcov') and value in ('Y') ;
    where enr_end gt '01jan1970'd AND value not in ('U', 'N') ;
  run ;

  data gnu ;
    length site $ 20 ;
    set gnu ;
    site = put(site, $s.) ;
    label
      enr_end = "Period end"
      pct = "Percent of *records* (not people)"
      var_name = "Variable"
    ;
  run ;

/*
  proc sgpanel data = gnu ;
    panelby var_name value ;
    loess x = enr_end y = pct / group = site ;
    rowaxis grid ;
    format enr_end year4. site $s. ;
  run ;
*/
  proc sgplot data = gnu ;
    series x = enr_end y = pct / group = site lineattrs = (thickness = .1 CM) ;
    yaxis grid ;
    format enr_end year4. ;
    by var_name value ;
  run ;

%mend report ;

%macro report_demog() ;
  proc sort data = col.demog_freqs out = gnu ;
    by var_name gender value site ;
    where value not in ('unk', 'und', 'UN') ;
    * where var_name in ('hispanic') ; * AND value not in ('U', 'N') ;
  run ;

  data nonlang lang ;
    set gnu ;
    pct2 = 100 * coalesce(pct, 0) ;
    if var_name = 'primary_language' then do ;
      if value = 'unk' then value = 'und' ;
      if value not in ('und', 'eng', 'spa') then lang_type = 'uncommon' ;
      else lang_type = 'common' ;
      if pct > 0 then output lang ;
    end ;
    else output nonlang ;
  run ;

  title2 "Demographics Descriptives" ;

  proc sgpanel data = nonlang ;
    panelby gender ;
    * vbar site / response = pct2 group = gender stat = sum ;
    vbar site / response = pct2 group = value stat = sum ;
    by var_name ;
  run ;

  title3 "Common Values for Language" ;
  proc sgpanel data = lang ;
    panelby gender ;
    * vbar site / response = pct2 group = gender stat = sum ;
    vbar site / response = pct2 group = value stat = sum ;
    where lang_type = 'common' ;
  run ;

  title3 "Uncommon Values for Language" ;
  proc sgpanel data = lang ;
    panelby gender ;
    * vbar site / response = pct2 group = gender stat = sum ;
    vbar site / response = pct2 group = value stat = sum ;
    where lang_type = 'uncommon' ;
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

  title1 "Enrollment/Demographics QA Report" ;
  proc sql number ;
    * describe table dictionary.tables ;
    title2 "Sites sumitting QA Results" ;
    select put(prxchange("s/(.*)_TIER_ONE_RESULTS\s*$/$1/i", -1, memname), $s.) as site label = "Site"
        , datepart(crdate) as date_submitted format = mmddyy10. label = "Submission Date"
    from dictionary.tables
    where libname = 'RAW' and memname like '%_TIER_ONE_RESULTS'
    ;
    title2 "Tier One (objective) checks" ;
    select * from col.tier_one_results (drop = qa_macro) ;
  quit ;

  %report ;

  %report_demog ;

ods _all_ close ;


