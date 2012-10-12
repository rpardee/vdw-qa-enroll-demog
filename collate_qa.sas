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

* %include "\\home\pardre1\SAS\Scripts\remoteactivate.sas" ;

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
%macro do_results() ;

  %stack_datasets(inlib = raw, nom = tier_one_results, outlib = work) ;

  proc sort data = tier_one_results(drop = detail_dset num_bad) ;
    by qa_macro description site ;
  run ;

  proc transpose data = tier_one_results out = col.tier_one_results(drop = _:) ;
    var result ;
    by qa_macro description ;
    id site ;
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

    create table col.&nom as
    select r.site, r.var_name, r.&byvar, r.value, r.count / total as pct format = percent8.2
    from  &nom as r INNER JOIN
          tots as t
    on    r.site = t.site AND
          r.&byvar = t.&byvar AND
          r.var_name = t.var_name
    ;
  quit ;
%mend do_freqs ;

%macro regen() ;
  %do_results ;
  %do_freqs(nom = enroll_freqs, byvar = enr_end) ;
  %do_freqs(nom = demog_freqs, byvar = gender) ;
%mend regen ;

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

options orientation = landscape ;

** Put this line before opening any ODS destinations. ;
options orientation = landscape ;
ods graphics / height = 6in width = 10in ;

%**let out_folder = \\home\pardre1\ ;
%let out_folder = \\groups\data\CTRHS\Crn\voc\enrollment\reports_presentations\output\ ;

ods html path = "&out_folder" (URL=NONE)
         body   = "enroll_demog_qa.html"
         (title = "Enrollment + Demographics QA Output")
          ;

* ods rtf file = "&out_folder.enroll_demog_qa.rtf" device = sasemf ;

  ods graphics / height = 6in width = 10in ;

  proc sort data = col.enroll_freqs out = gnu ;
    by var_name value site enr_end ;
    * where var_name in ('outside_utilization', 'plan_hmo', 'drugcov') and value in ('Y') ;
    where enr_end gt '01jan1970'd AND value not in ('U', 'N') ;
  run ;

/*   proc freq data = gnu ;
    tables site / missing ;
    format site $s. ;
  run ;
 */
  data gnu ;
    set gnu ;
    label
      enr_end = "Period end"
      pct = "Percent of *records* (not people)"
      var_name = "Variable"
    ;
  run ;

  proc sgpanel data = gnu ;
    panelby var_name value ; * / layout = lattice ;
    loess x = enr_end y = pct / group = site ; * lineattrs = (thickness = .1 CM) ;
    rowaxis grid ;
    format enr_end year4. site $s. ;
  run ;
  proc sgplot data = gnu ;
    ** scatter x = adate y = source_count / group = source ;
    ** loess x = adate y = source_count / group = source ;
    loess x = enr_end y = pct / group = site ; * lineattrs = (thickness = .1 CM) ;
    yaxis grid ;
    format enr_end year4. site $s. ;
    by var_name value ;
  run ;


run ;

ods _all_ close ;


