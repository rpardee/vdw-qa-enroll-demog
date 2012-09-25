/*********************************************
* Roy Pardee
* Group Health Research Institute
* (206) 287-2078
* pardee.r@ghc.org
*
* c:\Documents and Settings\pardre1\My Documents\vdw\macros\collate_births.sas
*
* <<purpose>>
*********************************************/

%include "\\home\pardre1\SAS\Scripts\remoteactivate.sas.connected.new" ;

options
  linesize = 150
  nocenter
  msglevel = i
  NOOVP
  formchar = '|-++++++++++=|-/|<>*'
  sastrace = ',,,d'
  sastraceloc = saslog nostsuffix
  dsoptions="note2err" NOSQLREMERGE
;

libname _all_ clear ;
libname sub '\\ctrhs-sas\SASUser\pardre1\vdw\hmorn_births\submitted' ;
libname dat '\\ctrhs-sas\SASUser\pardre1\vdw\hmorn_births' ;

%macro make_kpnw ;
  proc sql ;
    create table sub.kpnw_delivery_counts
    (adate num format = year4.,
     count num format = comma10.0,
     percent num) ;
     insert into sub.kpnw_delivery_counts(adate, count, percent) values ('01jan2008'd, 5282, 28.35) ;
     insert into sub.kpnw_delivery_counts(adate, count, percent) values ('01jan2009'd, 5027, 26.98) ;
     insert into sub.kpnw_delivery_counts(adate, count, percent) values ('01jan2010'd, 4771, 25.61) ;
     insert into sub.kpnw_delivery_counts(adate, count, percent) values ('01jan2011'd, 3553, 19.07) ;
  quit ;
%mend make_kpnw ;

%macro make_hfhs ;
  proc sql ;
    create table sub.hfhs_delivery_counts
    (adate num format = year4.,
     count num format = comma10.0,
     percent num) ;
     insert into sub.hfhs_delivery_counts(adate, count, percent) values ('01jan2009'd, 3589, 36.03) ;
     insert into sub.hfhs_delivery_counts(adate, count, percent) values ('01jan2010'd, 3895, 39.10) ;
     insert into sub.hfhs_delivery_counts(adate, count, percent) values ('01jan2011'd, 2477, 24.87) ;
  quit ;
%mend make_hfhs ;

%macro make_kpco ;
  proc sql ;
    create table sub.kpco_delivery_counts
    (adate num format = year4.,
     count num format = comma10.0,
     percent num) ;
     insert into sub.kpco_delivery_counts(adate, count, percent) values ('01jan2009'd, 5393, 39.92) ;
     insert into sub.kpco_delivery_counts(adate, count, percent) values ('01jan2010'd, 5325, 39.42) ;
     insert into sub.kpco_delivery_counts(adate, count, percent) values ('01jan2011'd, 2791, 20.66) ;
  quit ;
%mend make_kpco ;
/*
%make_hfhs ;
%make_kpco ;
*/

%macro make_ghs ;
  proc sql ;
    create table sub.ghs_delivery_counts
    (adate num format = year4.,
     count num format = comma10.0,
     percent num) ;
     insert into sub.ghs_delivery_counts(adate, count, percent) values ('01jan2010'd, 5975, 100) ;
  quit ;
%mend make_ghs ;

%macro make_kpsc ;
  proc sql ;
    create table sub.kpsc_delivery_counts
    (adate num format = year4.,
     count num format = comma10.0,
     percent num) ;
     insert into sub.kpsc_delivery_counts(adate, count, percent) values ('01jan2009'd, 37048, 37.7528) ;
     insert into sub.kpsc_delivery_counts(adate, count, percent) values ('01jan2010'd, 35863, 36.5453) ;
     insert into sub.kpsc_delivery_counts(adate, count, percent) values ('01jan2011'd, 25222, 25.7019) ;
  quit ;
%mend make_kpsc ;

%make_kpsc ;

%global unie ;

%macro generate_union(dset_suffix) ;
  select "select '" || substr(memname, 1, index(memname, '_') - 1) || "' as site, *, count as cnt from sub." || memname
  into :unie separated by " union all "
  from dictionary.tables
  where libname = 'SUB' AND
        lowcase(memname) like '%' || "&dset_suffix"
  order by memname desc
  ;
%mend generate_union ;

%macro collate ;
  proc sql noprint ;
    %generate_union(dset_suffix = delivery_counts) ;
    create table dat.collated as
    &unie
    ;
  quit ;
  proc datasets nolist library = dat ;
    modify collated ;
    label adate = "Year of birth" ;
  quit ;
%mend collate ;

%collate ;

options orientation = landscape ;

** ods graphics / height = 6in width = 10in ;

%**let out_folder = \\home\pardre1\ ;
%let out_folder = \\groups\data\CTRHS\CHS\pardre1\hmorn\births\ ;
proc format ;
  value $s
    'HPHC' = 'Harvard'
    'HPRF' = 'HealthPartners'
    'MCRF' = 'Marshfield'
    'SWH'  = 'Scott & White'
    'HFHS' = 'Henry Ford'
    'GHS'  = 'Geisinger'
    'LCF'  = 'Lovelace'
  ;
quit ;
ods html path = "&out_folder" (URL=NONE)
         body = "hmorn_birth_counts.html"
         (title = "Birth Counts from VDW")
          ;

ods rtf file = "&out_folder.hmorn_birth_counts.rtf" device = sasemf ;

  title "Numbers of births in the HMORN" ;
  footnote1 "Henry Ford #s are births happening *just* at HF facilities.  All other sites include birth events from claims." ;
  footnote2 "Essentia's utilization data is still being QA'd--please treat this as a provisional estimate." ;
  proc tabulate data = dat.collated ;
    class adate site ;
    var cnt ;
    tables adate all="Site Total", site=" "*cnt=" "*sum=" "*f=comma10.0 all=" "*cnt=" "*sum = "Year Total"*f=comma10.0 ;
    format site $s. ;
  run ;


ods _all_ close ;

