%macro make_denoms(start_year, end_year, outset) ;
  %local round_to ;
  %let round_to = 0.0001 ;

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
    ** For translating back to permissible values of DrugCov ;
    value $cd
      'A' = 'Y'
      'B' = 'N'
      'C' = 'U'
    ;
    value $Race
      'WH' = 'White'
      'BA' = 'Black'
      'IN' = 'Native'
      'AS' = 'Asian'
      'HP' = 'Pac Isl'
      'MU' = 'Multiple'
      Other = 'Unknown'
    ;
  quit ;

  data all_years ;
    do year = &start_year to &end_year ;
      first_day = mdy(1, 1, year) ;
      last_day  = mdy(12, 31, year) ;
      ** Being extra anal-retentive here--we are probably going to hit a leap year or two. ;
      num_days  = last_day - first_day + 1 ;
      output ;
    end ;
    format first_day last_day mmddyy10. ;
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
      whole program took about 4 minutes of wall clock time to do 1998 - 2007 @ GH.

    */
    create table gnu as
    select mrn
          , year
          , min(put(drugcov, $dc.)) as drugcov
          , min(put(outside_utilization, $dc.)) as outside_utilization
          /* This depends on there being no overlapping periods to work! */
          , sum((min(enr_end, last_day) - max(enr_start, first_day) + 1) / num_days) as enrolled_proportion
    from  &_vdw_enroll as e INNER JOIN
          all_years as y
    on    e.enr_start le y.last_day AND
          e.enr_end   ge y.first_day
    group by mrn, year
    ;

    reset outobs = max warn ;

    create table with_agegroup as
    select g.mrn
        , year
        , put(%calcage(refdate = mdy(1, 1, year)), agecat.) as agegroup label = "Age on 1-jan of [[year]]"
        , gender
        , put(race1, $race.) as race length = 10
        , put(drugcov, $cd.) as drugcov
        , put(outside_utilization, $cd.) as outside_utilization
        , enrolled_proportion
    from gnu as g LEFT JOIN
         &_vdw_demographic as d
    on   g.mrn = d.mrn
    ;

    create table &outset as
    select year
        , agegroup
        , drugcov label = "Drug coverage status (set to 'Y' if drugcov was 'Y' even once in [[year]])"
        , outside_utilization label = "Was there reason to suspect incomplete capture of ute or rx? (set to 'Y' if outside_ute was 'Y' even once in [[year]])"
        , race
        , gender
        , round(sum(enrolled_proportion), &round_to) as prorated_total format = comma20.2 label = "Pro-rated number of people enrolled in [[year]] (accounts for partial enrollments)"
        , count(mrn)               as total          format = comma20.0 label = "Number of people enrolled at least one day in [[year]]"
    from with_agegroup
    group by year, agegroup, drugcov, outside_utilization, race, gender
    order by year, agegroup, drugcov, outside_utilization, race, gender
    ;

    /*
    ** Create a dset of (masked) counts by race for submission to GH for collation. ;
    create table race_counts_&_SiteAbbr as
    select year, agegroup, race
          , case when sum(prorated_total) between .01 and 4 then .a else sum(prorated_total) end as prorated_total format = comma20.2
          , case when sum(total)          between 1   and 4 then .a else sum(total)          end as total          format = comma20.0
    from &outset
    group by year, agegroup, race
    ;
    */

  quit ;

%mend make_denoms ;