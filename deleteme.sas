/*********************************************
* Roy Pardee
* Group Health Research Institute
* (206) 287-2078
* pardee.r@ghc.org
*
* //groups/data/CTRHS/Crn/voc/enrollment/programs/deleteme.sas
*
* purpose
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
libname col "//ghrisas/SASUser/pardre1" ;

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

%do_freqs(nom = enroll_freqs, byvar = year) ;
