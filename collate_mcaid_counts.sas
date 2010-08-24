/*********************************************
* Roy Pardee
* Center For Health Studies
* (206) 287-2078
* pardee.r@ghc.org
*
* cms_mcaid_counts.sas
*
* Does a quick count of medicaid enrollees in the year indicated
* in the edit var last_enroll_year by age and gender.
*
* Adapted from voc_denominators.sas
*
*********************************************/

** ======================== BEGIN EDIT SECTION ================================ ;

** PLEASE COMMENT OUT THE FOLLOWING LINE IF ROY FORGETS TO (SORRY!) ;
%**include "\\home\pardre1\SAS\Scripts\remoteactivate.sas" ;

** Your local copy of StdVars.sas ;
%include "\\groups\data\CTRHS\Crn\S D R C\VDW\Macros\StdVars.sas" ;

** Destination for the output dataset of counts. ;
%let outlib = \\ctrhs-sas\sasuser\pardre1\vdw\voc_lab ;

** Most recent complete year of enrollment data. ;
%let last_enroll_year = 2009 ;

options linesize = 150 nocenter msglevel = i NOOVP formchar='|-++++++++++=|-/|<>*' dsoptions="note2err" ;

** ========================= END EDIT SECTION ================================= ;

libname sub '\\groups\data\CTRHS\Crn\voc\enrollment\data\submitted' ;
libname dat '\\groups\data\CTRHS\Crn\voc\enrollment\data' ;

%macro make_nonmcaid_site_data(site) ;
  proc sql ;
    create table sub.&site._cms_mcaid_counts_for_gh as
    select year
          , agegroup
          , Gender
          , ins_medicaid
          , 0 as prorated_total
          , 0 as total
    from sub.ghc_cms_mcaid_counts_for_gh
    ;
  quit ;
%mend ;

%**make_nonmcaid_site_data(HPHC) ;
%**make_nonmcaid_site_data(KPGA) ;

%global unie ;

%macro generate_union(dset_suffix) ;
  select "select '" || substr(memname, 1, index(memname, '_') - 1) || "' as site, * from sub." || memname
  into :unie separated by " union all "
  from dictionary.tables
  where libname = 'SUB' AND
        lowcase(memname) like '%' || "&dset_suffix"
  order by memname desc
  ;
%mend generate_union ;

options mprint ;

%macro collate_data ;
  proc sql feedback ;
    %generate_union(dset_suffix = _cms_mcaid_counts_for_gh) ;

    %put &unie ;

    create table dat.cms_mcaid_counts as &unie ;

    ** * Henry Ford has a bunch of plain missings in gender--fix those up. ;
    ** * TODO: Need recommendation to check demog contents against enroll? ;
    ** update d.gender_counts
    ** set gender = 'U'
    ** where gender IS NULL
    ** ;

  quit ;
%mend collate_data ;

%macro report ;
  proc format ;
    value msk
      .a = 'Masked'
      other = [comma14.0]
    ;
    value $gnd
      'F' = 'Female'
      'M' = 'Male'
      'U' = 'Unknown'
    ;
    value $agegr
      '00to04' = '<= 4'
      '05to09' = '5 to 9'
      '10to14' = '10 to 14'
      '15to19' = '15 to 19'
      '20to29' = '20 to 29'
      '30to39' = '30 to 39'
      '40to49' = '40 to 49'
      '50to59' = '50 to 59'
      '60to64' = '60 to 64'
      '65to70' = '65 to 70'
      '70to74' = '70 to 74'
      'ge_75'  = '>= 75'
      '', missing      = 'Unknown'
    ;
  quit ;

  data gnu ;
    set dat.cms_mcaid_counts ;
    ** site = 'GHC' ;
  run ;

  title1 "Counts of 2009 Medicaid Enrollees by HMORN Site" ;
  footnote1 "Fallon (FA) data is actually from 2008." ;
  footnote2 "Geisinger reports having 'fewer than 1000' medicaid enrollees in 2009." ;
  proc tabulate data = gnu format = msk. missing ;
    class agegroup gender ins_medicaid site ;
    keylabel N = " " sum = " " ;
    var prorated_total ;
    tables site all = "All Sites", gender=" " * agegroup * prorated_total=" "*sum all*prorated_total = " " *sum = "All Ages/Sexes" / misstext = '0' ;
    tables agegroup all = "All Ages", gender=" " * site * prorated_total=" "*sum all*prorated_total = " " *sum = "All Sites/Sexes" / misstext = '0' ;
    where ins_medicaid = 'Y' and prorated_total > 0.4 ;
    format gender $gnd. agegroup $agegr. ;
  run ;

/*
  proc tabulate data = outlib.&_SiteAbbr._cms_mcaid_counts format = msk. ;
    class agegroup gender ins_medicaid ;
    keylabel N = " " sum = " " ;
    var prorated_total ;
    tables agegroup all = 'Total', ins_medicaid="On mcaid?" * gender="Gender"*prorated_total*sum all*prorated_total*sum = "Tot" / misstext = '0' ;
    ** freq total ;
  run ;
*/
%mend report ;

%collate_data ;

ods html path = "\\groups\data\CTRHS\Crn\voc\enrollment\programs\" (URL=NONE)
         body = "collate_mcaid_counts.html"
         (title = "collate_mcaid_counts output")
          ;

ods rtf file = "\\groups\data\CTRHS\Crn\voc\enrollment\programs\collate_mcaid_counts.rtf" ;

  %report ;
  run ;

ods rtf close ;
ods html close ;

