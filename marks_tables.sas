/*********************************************
* Roy Pardee
* Center For Health Studies
* (206) 287-2078
* pardee.r@ghc.org
*
* \\groups\data\CTRHS\Crn\voc\enrollment\programs\marks_tables.sas
*
* <<purpose>>
*********************************************/

* ======================== BEGIN EDIT SECTION ================================ ;

* PLEASE COMMENT OUT THE FOLLOWING LINE IF ROY FORGETS TO (SORRY!) ;
%include "\\home\pardre1\SAS\Scripts\dw_login.sas" ;

* Your local copy of StdVars.sas ;
%include "\\groups\data\CTRHS\Crn\S D R C\VDW\Macros\StdVars.sas" ;

* Destination for the output dataset of denominators. ;
%let outlib = \\ctrhs-sas\sasuser\pardre1\vdw ;

options linesize = 150 nocenter msglevel = i NOOVP formchar='|-++++++++++=|-/|<>*' dsoptions="note2err" ;

* ========================= END EDIT SECTION ================================= ;

%let round_to = 0.0001 ;

%include vdw_macs ;

libname outlib  "&outlib" ;

  proc format ;
    value msk
      0 - 4 = '< 5'
      other = [comma15.2]
    ;
    * 0-17, 18-64, 65+ ;
    value agecat
      low -< 18 = '0 to 17'
      18  -< 65 = '18 to 64'
      65 - high = '65+'
    ;
    * For setting priority order to favor values of Y. ;
    value $dc
      'Y'   = 'A'
      'N'   = 'B'
      other = 'C'
    ;
    * For translating back to permissible values of DrugCov ;
    value $cd
      'A' = 'Y'
      'B' = 'N'
      'C' = ' '
    ;
    value $Race
      '01' = 'White'
      '02' = 'Black'
      '03' = 'Native'
      '04'
      , '05'
      , '06'
      , '08'
      , '09'
      , '10'
      , '11'
      , '12'
      , '13'
      , '14'
      , '96' = 'Asian'
        '07'
      , '20'
      , '21'
      , '22'
      , '25'
      , '26'
      , '27'
      , '28'
      , '30'
      , '31'
      , '32'
      , '97' = 'Pac Isl' /* Native Hawaiian or Other Pacific Islander */
      Other = 'Unknown' /* Unknown or Not Reported */
    ;
  quit ;

%macro make_denoms(start_year, end_year, outset) ;
  data all_years ;
    do year = &start_year to &end_year ;
      first_day = mdy(1, 1, year) ;
      last_day  = mdy(12, 31, year) ;
      * Being extra anal-retentive here--we are probably going to hit a leap year or two. ;
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
          , min(put(drugcov, $dc.)) as drugcov
          /* This depends on there being no overlapping periods to work! */
          , sum((min(enr_end, last_day) - max(enr_start, first_day) + 1) / num_days) as enrolled_proportion
    from  &_vdw_enroll as e INNER JOIN
          all_years as y
    on    e.enr_start le y.last_day AND
          e.enr_end   ge y.first_day
    group by mrn, year
    ;

    create table with_agegroup as
    select g.mrn
        , year
        , put(%calcage(refdate = mdy(1, 1, year)), agecat.) as agegroup label = "Age on 1-jan of [[year]]"
        , gender
        , case when race2 is null or race2 = '99' then put(race1, $race.) else 'Multiple' end as race length = 10
        , put(drugcov, $cd.) as drugcov
        , enrolled_proportion
    from gnu as g LEFT JOIN
         &_vdw_demographic as d
    on   g.mrn = d.mrn
    ;

    create table &outset as
    select year
        , agegroup
        , drugcov label = "Drug coverage status (set to 'Y' if drugcov was 'Y' even once in [[year]])"
        , race
        , gender
        , round(sum(enrolled_proportion), &round_to) as prorated_total format = comma20.2 label = "Pro-rated number of people enrolled in [[year]] (accounts for partial enrollments)"
        , count(mrn)               as total          format = comma20.0 label = "Number of people enrolled at least one day in [[year]]"
    from with_agegroup
    group by year, agegroup, drugcov, race, gender
    order by year, agegroup, drugcov, race, gender
    ;

  quit ;

%mend make_denoms ;

%macro report_enrollment(inset = outlib.base_denominators) ;

  proc tabulate data = &inset format = comma15.2 ;
    class year agegroup drugcov gender race ;
    var prorated_total ;
    table                     (agegroup all = "Total")   , year=" "*prorated_total=" "* (sum="N"*f=msk. colPCTsum="%") ;
    table gender = "Gender" * (agegroup all = "Subtotal"), year=" "*prorated_total=" "* (sum="N"*f=msk. colPCTsum="%") ;
    table race = "Race"     * (agegroup all = "Subtotal"), year=" "*prorated_total=" "* (sum="N"*f=msk. colPCTsum="%") ;
  run ;

%mend report_enrollment ;

%macro make_output ;
  %make_denoms(start_year = 1998, end_year = 2007, outset = outlib.base_denominators) ;
  proc sql ;
    * If I have gender * age, and race * age, I can do plain age from either of those (and likewise a total). ;
    create table outlib.race_counts as
    select year, agegroup, race
          , case when sum(prorated_total) between .01 and 4 then .a else sum(prorated_total) end as prorated_total format = comma20.2
          , case when sum(total)          between 1   and 4 then .a else sum(total)          end as total          format = comma20.0
    from outlib.base_denominators
    group by year, agegroup, race
    ;
    create table outlib.gender_counts as
    select year, agegroup, gender
          , case when sum(prorated_total) between .01 and 4 then .a else sum(prorated_total) end as prorated_total format = comma20.2
          , case when sum(total)          between 1   and 4 then .a else sum(total)          end as total          format = comma20.0
    from outlib.base_denominators
    group by year, agegroup, gender
    ;
  quit ;
%mend make_output ;

%make_output ;

ods html path = "\\groups\data\CTRHS\Crn\voc\enrollment\programs\" (URL=NONE)
         body = "marks_tables.html"
         (title = "marks_tables output")
          ;

  %report_enrollment ;

run ;
ods html close ;
