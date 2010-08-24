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
%include "\\home\pardre1\SAS\Scripts\remoteactivate.sas" ;

** Your local copy of StdVars.sas ;
%include "\\groups\data\CTRHS\Crn\S D R C\VDW\Macros\StdVars.sas" ;

** Destination for the output dataset of counts. ;
%let outlib = \\ctrhs-sas\sasuser\pardre1\vdw\voc_lab ;

** Most recent complete year of enrollment data. ;
%let last_enroll_year = 2009 ;

options linesize = 150 nocenter msglevel = i NOOVP formchar='|-++++++++++=|-/|<>*' dsoptions="note2err" ;

** ========================= END EDIT SECTION ================================= ;

%let round_to = 0.0001 ;

%include vdw_macs ;

libname outlib  "&outlib" ;

%macro make_denoms(for_year, outset) ;
  proc format ;
    ** 0-17, 18-64, 65+ ;
    value shrtage
      low -< 18 = '0 to 17'
      18  -< 65 = '18 to 64'
      65 - high = '65+'
    ;
    value agecat
      low -< 5 =  '00to04'
      5   -< 10 = '05to09'
      10  -< 15 = '10to14'
      15  -< 20 = '15to19'
      20  -< 30 = '20to29'
      30  -< 40 = '30to39'
      40  -< 50 = '40to49'
      50  -< 60 = '50to59'
      60  -< 65 = '60to64'
      65  -< 70 = '65to70'
      70  -< 75 = '70to74'
      75 - high = 'ge_75'
    ;
    ** For setting priority order to favor values of Y. ;
    value $dc
      'Y'   = 'A'
      'N'   = 'B'
      other = 'C'
    ;
  quit ;

  data all_years ;
    do year = &for_year to &for_year ;
      first_day = mdy(1, 1, year) ;
      last_day  = mdy(12, 31, year) ;
      num_days  = last_day - first_day + 1 ;
      output ;
    end ;
    format first_day last_day mmddyy10. ;
  run ;

  proc print ;
  run ;

  proc sql ;
    /*
      Dig this funky join--its kind of a cartesian product, limited to
      enroll records that overlap the year from all_years.
      enrolled_proportion is the # of days between <<earliest of enr_end and last-day-of-year>>
      and <<latest of enr_start and first-day-of-year>> divided by the number of
      days in the year.

      Nice thing here is we can do calcs on all the years desired in a single
      statement.  I was concerned about perf, but this ran quite quickly--the
      whole program about 4 minutes of wall clock time to do 1998 - 2007 @ GH.

    */
    create table gnu as
    select mrn
          , year
          , coalesce(ins_medicaid, 'N') as ins_medicaid
          /* This depends on there being no overlapping periods to work! */
          , sum((min(enr_end, last_day) - max(enr_start, first_day) + 1) / num_days) as enrolled_proportion
    from  &_vdw_enroll as e INNER JOIN
          all_years as y
    on    e.enr_start le y.last_day AND
          e.enr_end   ge y.first_day
    where ins_medicaid = 'Y'
    group by mrn, year, ins_medicaid
    ;

    ** Check the no-overlaps assumption. ;
    reset outobs = 10 nowarn ;
    create table people_with_overlapping_periods as
    select mrn, year, enrolled_proportion
    from gnu
    where round(enrolled_proportion, &round_to ) > 1.0000
    ;

    %if &SQLOBS > 0 %then %do ;
      reset outobs = max warn ;

      create table outlib.bad_enroll_overlaps(label = "These people have overlapping enrollment periods covering &for_year") as
      select year, enrolled_proportion, e.*
      from &_vdw_enroll as e INNER JOIN
           people_with_overlapping_periods as p
      on    e.mrn = p.mrn AND
            e.enr_start le mdy(12, 31, p.year) AND
            e.enr_end   ge mdy(1, 1, p.year)
      order by e.mrn, e.enr_start, e.enr_end
      ;
      %put  ;
      %put DATA ERROR!!!  ENROLLMENT PERIODS MUST NOT OVERLAP!  SEE OUTLIB.BAD_ENROLL_OVERLAPS FOR SAMPLE RECORDS WITH OVERLAPS! ;
      %put  ;
      %put DATA ERROR!!!  ENROLLMENT PERIODS MUST NOT OVERLAP!  SEE OUTLIB.BAD_ENROLL_OVERLAPS FOR SAMPLE RECORDS WITH OVERLAPS! ;
      %put  ;
      %put DATA ERROR!!!  ENROLLMENT PERIODS MUST NOT OVERLAP!  SEE OUTLIB.BAD_ENROLL_OVERLAPS FOR SAMPLE RECORDS WITH OVERLAPS! ;
      %put  ;
    %end ;

    reset outobs = max warn ;

    create table with_agegroup as
    select g.mrn
        , year
        , put(%calcage(refdate = mdy(1, 1, year)), agecat.) as agegroup label = "Age on 1-jan of &for_year"
        , gender
        , ins_medicaid
        , enrolled_proportion
    from gnu as g LEFT JOIN
         &_vdw_demographic as d
    on   g.mrn = d.mrn
    ;

    create table outlib.&outset as
    select year
        , agegroup
        , gender
        , ins_medicaid
        , round(sum(enrolled_proportion), &round_to) as prorated_total format = comma20.2 label = "Pro-rated number of people enrolled in &for_year (accounts for partial enrollments)"
        , count(mrn)               as total          format = comma20.0 label = "Number of people enrolled at least one day in &for_year"
    from with_agegroup
    group by year, agegroup, gender, ins_medicaid
    order by year, agegroup, gender, ins_medicaid
    ;


    ** Mask nonzero counts < 5 ;
    update outlib.&outset
    set total = .a
    where total between 1 and 4 ;

    update outlib.&outset
    set prorated_total = .a
    where prorated_total > 0 and prorated_total < 5 ;


  quit ;

%mend make_denoms ;

** This report macro is ignorable--just Roy playing around w/how to present the data. ;
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
    ;
  quit ;

  data gnu ;
    set outlib.&_SiteAbbr._cms_mcaid_counts ;
    site = 'GHC' ;
  run ;

  proc tabulate data = gnu format = msk. ;
    class agegroup gender ins_medicaid site ;
    keylabel N = " " sum = " " ;
    var prorated_total ;
    tables site all = "All Sites", gender=" " * agegroup * prorated_total="N"*sum all*prorated_total = " " *sum = "All Ages/Sexes" / misstext = '0' ;
    where ins_medicaid = 'Y' ;
    format gender $gnd. agegroup $agegr. ;
  run ;

  proc tabulate data = outlib.&_SiteAbbr._cms_mcaid_counts format = msk. ;
    class agegroup gender ins_medicaid ;
    keylabel N = " " sum = " " ;
    var prorated_total ;
    tables agegroup all = 'Total', ins_medicaid="On mcaid?" * gender="Gender"*prorated_total*sum all*prorated_total*sum = "Tot" / misstext = '0' ;
    ** freq total ;
  run ;

%mend report ;

** options obs = 1000 ;
options mprint ;

%make_denoms(for_year = &last_enroll_year, outset = &_SiteAbbr._cms_mcaid_counts_FOR_GH) ;
