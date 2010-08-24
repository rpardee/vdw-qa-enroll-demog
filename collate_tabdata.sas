/*********************************************
* Roy Pardee
* Center For Health Studies
* (206) 287-2078
* pardee.r@ghc.org
*
* \\groups\data\CTRHS\Crn\voc\enrollment\programs\collate_tabdata.sas
*
* <<purpose>>
*********************************************/

/* This is managed in the login script so that it doesnt
   actually try to login when the machine is not connected
   to the network */
%include "\\home\pardre1\SAS\Scripts\dw_login.sas" ;

options linesize = 150 nocenter msglevel = i NOOVP formchar='|-++++++++++=|-/|<>*' dsoptions="note2err" ;

libname _all_ clear ;

libname sub '\\groups\data\CTRHS\Crn\voc\enrollment\data\submitted' ;
libname d '\\groups\data\CTRHS\Crn\voc\enrollment\data' ;


%global unie ;

%macro generate_union(dset_prefix) ;
  select "select '" || reverse(substr(reverse(memname), 1, index(reverse(memname), '_') - 1)) || "' as site, * from sub." || memname
  into :unie separated by " union all "
  from dictionary.tables
  where libname = 'SUB' AND
        lowcase(memname) like "&dset_prefix" || '%'
  ;
%mend generate_union ;

options mprint ;

%macro collate_data ;
  proc sql feedback ;
    %generate_union(dset_prefix = gender_counts_) ;
    create table d.gender_counts as
    &unie ;
    %generate_union(dset_prefix = race_counts_) ;
    create table d.race_counts as
    &unie ;

    * Henry Ford has a bunch of plain missings in gender--fix those up. ;
    * TODO: Need recommendation to check demog contents against enroll? ;
    update d.gender_counts
    set gender = 'U'
    where gender IS NULL
    ;

  quit ;
%mend collate_data ;

%collate_data ;

proc sql ;
  create table site_mask as
  select distinct site, uniform(0) as randy
  from (select site from d.race_counts UNION select site from d.gender_counts)
  order by 2
  ;

  select site
  into :site_list separated by ', '
  from site_mask
  ;

  create table races as
  select distinct race
  from d.race_counts
  ;

  create table years as
  select distinct year
  from d.race_counts ;

  create table ages as
  select distinct agegroup
  from d.race_counts
  ;

  create table sites_races as
  select site, race, year, agegroup
  from site_mask CROSS JOIN
        races CROSS JOIN
        years CROSS JOIN
        ages
  ;
quit ;

* 07 	 4,141.02 ;
/*
data site_mask ;
  set site_mask ;
  start = site ;
  end = site ;
  label = put(_n_, z2.) ;
  FmtName = '$SiteMsk' ;
  drop randy ;
run ;

proc format cntlin = site_mask ;
quit ;

Freezing the format now.

*/

proc format ;
  value msk
    0 - 4 = '< 5'
    other = [comma15.2]
  ;
  value $rac
    'Unknown' = 'Unknown'
    other = 'Known'
  ;

  value $ag
    '.' = 'Unknown'
  ;

  value $SiteMsk
    "FA"    = "09"
    "GH"    = "07"
    "HFHS"  = "02"
    "HP"    = "03"
    "HPHC"  = "11"
    "KPCO"  = "01"
    "KPGA"  = "06"
    "KPH"   = "04"
    "KPNW"  = "05"
    "KPSC"  = "10"
    "MCRF"  = "08"
    "KPNC"  = "12"
  ;
quit ;;

%let use_var = total ;

%macro make_report(mask_sites = 0) ;
  title1 "Contributing sites: &site_list" ;
  title2 "Proportion of Race known for people enrolled at least one day in 2007" ;
  proc tabulate data = d.race_counts format = comma15.2 order = formatted ;
    class year agegroup race site ;
    var &use_var ;
    table site = " ", race = "Race"*&use_var=" "* (rowPCTsum="%") ;
    %if &mask_sites = 1 %then format site $SiteMsk. ;
    format race $rac. ;
    where year = 2007 ;
  quit ;

  title2 "Race Percentages for people enrolled at least one day in 2007 (including Unknown)" ;
  proc tabulate data = d.race_counts format = comma15.2 order = formatted ;
    class year agegroup race site ;
    var &use_var ;
    table site = " ", race = "Race"*&use_var=" "* (rowPCTsum="%") ;
    %if &mask_sites = 1 %then format site $SiteMsk. ;
    where year = 2007 ;
  quit ;

  title2 "Race Percentages for people enrolled at least one day in 2007 (NOT including Unknown)" ;
  proc tabulate data = d.race_counts format = comma15.2 order = formatted ;
    class year agegroup race site ;
    var &use_var ;
    table site = " ", race = "Race"*&use_var=" "* (rowPCTsum="%") ;
    %if &mask_sites = 1 %then format site $SiteMsk. ;
    * format race $rac. ;
    where year = 2007 AND race <> 'Unknown' ;
  quit ;

  proc tabulate data = d.race_counts format = comma15.2 order = formatted classdata = sites_races ;
    class year agegroup race site ;
    var &use_var ;
    * table site all = "Total", year=" "*&use_var=" "* (sum="N"*f=msk. colPCTsum="%") ;
  title2 "Race by Site Counts/Percentages for All Years" ;
    table (race = "Race" all = "All Races") * (site all = "All Sites"), year=" "*&use_var=" "* (sum="N"*f=msk. colPCTsum="%") ;
  title2 "Age Group by Site Counts/Percentages for All Years" ;
    table (agegroup = "Age Group" all = "All Ages") * (site all = "All Sites"), year=" "*&use_var=" "* (sum="N"*f=msk. colPCTsum="%") ;
    %if &mask_sites = 1 %then format site $SiteMsk. ;
    format agegroup $ag. ;
  quit ;

  title2 "Gender by Site Counts/Percentages for All Years" ;
  proc tabulate data = d.gender_counts format = comma15.2 order = formatted ;
    class year agegroup gender site ;
    var &use_var ;
    table (gender = "Gender" all = "All Genders") * (site all = "All Sites"), year=" "*&use_var=" "* (sum="N"*f=msk. colPCTsum="%") ;
    %if &mask_sites = 1 %then format site $SiteMsk. ;
  quit ;

%mend make_report ;


ods html path = "\\groups\data\CTRHS\Crn\voc\enrollment\programs\" (URL=NONE)
         body = "collate_tabdata.html"
         (title = "Enrollee Race/Age/Gender Counts by Site and Year")
          ;

  %make_report(mask_sites = 1) ;


run ;
ods html close ;
