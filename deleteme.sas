/*********************************************
* Roy Pardee
* Group Health Research Institute
* (206) 287-2078
* pardee.r@ghc.org
*
* //groups/data/CTRHS/Crn/voc/enrollment/programs/vdw_enroll_demog_qa.sas
*
* Does comprehensive QA checks for the HMORN VDW's Enrollment & Demographics files.
*
* Please see the workplan found here:
* https://appliedresearch.cancer.gov/crnportal/data-resources/vdw/quality-assurance/qa-programs/2012-qa/enroll-demog-workplan
*
*********************************************/

* ======================= begin edit section ======================= ;
* ======================= begin edit section ======================= ;
* ======================= begin edit section ======================= ;

* If roy forgets to comment this out, please do so.  Thanks/sorry! ;
%include "//home/pardre1/SAS/Scripts/remoteactivate.sas" ;

options
  linesize  = 150
  msglevel  = i
  formchar  = '|-++++++++++=|-/|<>*'
  /* dsoptions = note2err */
  nocenter
  noovp
  /* nosqlremerge */
  mprint
;

* Please edit this to point to your local standard vars file. ;
%include "//groups/data/CTRHS/Crn/S D R C/VDW/Macros/StdVars.sas" ;

* Please edit this so it points to the location where you unzipped the files/folders. ;
%let root = //groups/data/CTRHS/Crn/voc/enrollment/programs/ghc_qa ;

* ======================== end edit section ======================== ;
* ======================== end edit section ======================== ;
* ======================== end edit section ======================== ;

%include vdw_macs ;

* Test program--replaces real enroll/demog with deformed versions. ;
* %include "//groups/data/CTRHS/Crn/voc/enrollment/test_tier1_qa.sas" ;

%include "&root./qa_formats.sas" ;

libname to_stay "&root./DO_NOT_SEND" ;
libname to_go   "&root./to_send" ;

proc sql ;
  create table results
   ( description  char(60) label = "Description"
   , qa_macro     char(30) label = "Name of the macro that does this check"
   , detail_dset  char(30) label = "Look for further details in this dataset"
   , num_bad      numeric  label = "For record-based checks, how many records offend the spec?" format = comma14.0
   , percent_bad  numeric  label = "For record-based checks, bad records are what % of total?"  format = 8.2
   , result       char(8)  label = "Result"
   )
  ;
quit ;

%macro make_bigass_dset(outset = to_stay.denoms) ;

  /* This is copied from the make_denoms standard macro--adding in all the enroll vars. */

  %local round_to start_year end_year ;

  %let round_to = 0.0001 ;
  %let start_year = 1990 ;
  %let end_year = %sysfunc(year("&sysdate9"d)) ;

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
      65  -< 70 = '65to69'
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
    value $eb
      'I' = 'Insurance'
      'G' = 'Geography'
      'B' = 'Both Ins + Geog'
      'P' = 'Non-member patient'
    ;
    value $non
      ' ', '' = 'missing'
      other = 'not missing'
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
          , min(put(drugcov            , $dc.)) as drugcov
          , min(put(outside_utilization, $dc.)) as outside_utilization
          , min(put(enrollment_basis   , $eb.)) as enrollment_basis
          , min(put(ins_commercial     , $dc.)) AS ins_commercial
          , min(put(ins_highdeductible , $dc.)) AS ins_highdeductible
          , min(put(ins_medicaid       , $dc.)) AS ins_medicaid
          , min(put(ins_medicare       , $dc.)) AS ins_medicare
          , min(put(ins_medicare_a     , $dc.)) AS ins_medicare_a
          , min(put(ins_medicare_b     , $dc.)) AS ins_medicare_b
          , min(put(ins_medicare_c     , $dc.)) AS ins_medicare_c
          , min(put(ins_medicare_d     , $dc.)) AS ins_medicare_d
          , min(put(ins_other          , $dc.)) AS ins_other
          , min(put(ins_privatepay     , $dc.)) AS ins_privatepay
          , min(put(ins_selffunded     , $dc.)) AS ins_selffunded
          , min(put(ins_statesubsidized, $dc.)) AS ins_statesubsidized
          , min(put(plan_hmo           , $dc.)) AS plan_hmo
          , min(put(plan_indemnity     , $dc.)) AS plan_indemnity
          , min(put(plan_pos           , $dc.)) AS plan_pos
          , min(put(plan_ppo           , $dc.)) AS plan_ppo
          , max((prxmatch("/[^ 0]/", pcc) > 0)) as pcc_probably_valid /* Experimental--GH has all-0 invalid values */
          , max((prxmatch("/[^ 0]/", pcp) > 0)) as pcp_probably_valid /* Experimental--GH has all-0 invalid values */
          /* This depends on there being no overlapping periods to work! */
          , sum((min(enr_end, last_day) - max(enr_start, first_day) + 1) / num_days) as enrolled_proportion
    from  &_vdw_enroll as e INNER JOIN
          all_years as y
    on    e.enr_start le y.last_day AND
          e.enr_end   ge y.first_day
    group by mrn, year
    ;

    reset outobs = max warn ;

    create table with_demog as
    select g.mrn
        , year
        , put(%calcage(birth_date, refdate = mdy(1, 1, year)), agecat.) as agegroup label = "Age on 1-jan of [[year]]"
        , gender
        , put(race1, $race.)             as race length = 10
        , put(hispanic           , $cd.) as hispanic
        , put(needs_interpreter  , $cd.) as needs_interpreter
        , put(drugcov            , $cd.) as drugcov
        , put(outside_utilization, $cd.) as outside_utilization
        , enrollment_basis
        , put(ins_commercial     , $cd.) AS ins_commercial
        , put(ins_highdeductible , $cd.) AS ins_highdeductible
        , put(ins_medicaid       , $cd.) AS ins_medicaid
        , put(ins_medicare       , $cd.) AS ins_medicare
        , put(ins_medicare_a     , $cd.) AS ins_medicare_a
        , put(ins_medicare_b     , $cd.) AS ins_medicare_b
        , put(ins_medicare_c     , $cd.) AS ins_medicare_c
        , put(ins_medicare_d     , $cd.) AS ins_medicare_d
        , put(ins_other          , $cd.) AS ins_other
        , put(ins_privatepay     , $cd.) AS ins_privatepay
        , put(ins_selffunded     , $cd.) AS ins_selffunded
        , put(ins_statesubsidized, $cd.) AS ins_statesubsidized
        , put(plan_hmo           , $cd.) AS plan_hmo
        , put(plan_indemnity     , $cd.) AS plan_indemnity
        , put(plan_pos           , $cd.) AS plan_pos
        , put(plan_ppo           , $cd.) AS plan_ppo
        , enrolled_proportion
    from gnu as g LEFT JOIN
         &_vdw_demographic as d
    on   g.mrn = d.mrn
    ;

    %local vlist ;
    %let vlist = year, agegroup, gender, race, hispanic, needs_interpreter, drugcov, outside_utilization, enrollment_basis,
                ins_commercial, ins_highdeductible, ins_medicaid, ins_medicare,
                ins_medicare_a, ins_medicare_b, ins_medicare_c, ins_medicare_d, ins_other,
                ins_privatepay, ins_selffunded, ins_statesubsidized, plan_hmo, plan_indemnity,
                plan_pos, plan_ppo ;

    create table &outset as
    select &vlist
        , round(sum(enrolled_proportion), &round_to) as prorated_total format = comma20.2 label = "Pro-rated number of people enrolled in [[year]] (accounts for partial enrollments)"
        , count(mrn)               as total          format = comma20.0 label = "Number of people enrolled at least one day in [[year]]"
    from with_demog
    group by &vlist
    order by &vlist
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

%mend make_bigass_dset ;



%macro check_vars ;
  proc contents noprint data = &_vdw_demographic  out = dvars(keep = name type length label) ;
  run ;
  proc contents noprint data = &_vdw_enroll       out = evars(keep = name type length label) ;
  run ;

  data observed_vars ;
    set evars (in = e) dvars ;
    name = lowcase(name) ;
    if e then dset = 'enroll' ;
    else      dset = 'demog' ;
  run ;

  proc sort data = expected_vars ; by dset name ; run ;
  proc sort data = observed_vars ; by dset name ; run ;


  data to_go.&_siteabbr._noteworthy_vars ;
    length outcome $ 8 ;
    merge
      expected_vars (in = e rename = (type = e_type ))
      observed_vars (in = o rename = (type = o_type ))
    ;
    by dset name ;
    if o and not e then outcome = "extra" ;
    if e and not o then outcome = "missing" ;
    if e and o then do ;
      if e_type = o_type then do ;
        ** Expected length is only set for the date vars--if your data is in a SAS dset and ;
        ** you are using more than 4 bytes to hold them, you could save that space & ;
        ** (potentially) speed up i/o on the file. ;
        if recommended_length and length > recommended_length then outcome = "too long" ;
        else delete ; * <-- exactly right--boring! ;
      end ;
      else outcome = "bad type" ;
    end ;
  run ;

  proc sql noprint ;
    select count(*)
    into :num_bad
    from to_go.&_siteabbr._noteworthy_vars
    where outcome in ("missing", "bad type")
    ;
    %if &num_bad > 0 %then %do ;
      insert into results(description, qa_macro, detail_dset, result)
      values ("Are all vars in the spec in the dataset & of proper type?", '%check_vars', "to_go.noteworthy_vars","fail")
      ;
    %end ;
    %else %do ;
      insert into results(description, qa_macro, detail_dset, result)
      values ("Are all vars in the spec in the dataset & of proper type?", '%check_vars', "to_go.noteworthy_vars","pass")
      ;
    %end ;
  quit ;
%mend check_vars ;

%macro enroll_tier_one(inset = &_vdw_enroll) ;
  /*
    Combines several checks in a quest for efficiency.
  */
  proc sql ;
    create table erbr_checks
    (   description char(60)
      , problem char(50)
      , warn_lim numeric
      , fail_lim numeric
    ) ;

    insert into erbr_checks (description, problem, warn_lim, fail_lim) values ('Valid values: enrollment_basis', 'enrollment_basis has a bad value', 2, 5) ;
    insert into erbr_checks (description, problem, warn_lim, fail_lim) values ('Valid values: drugcov', 'drugcov has a bad value', 2, 5) ;
    insert into erbr_checks (description, problem, warn_lim, fail_lim) values ('Valid values: ins_commercial', 'ins_commercial has a bad value', 2, 5) ;
    insert into erbr_checks (description, problem, warn_lim, fail_lim) values ('Valid values: ins_highdeductible', 'ins_highdeductible has a bad value', 2, 5) ;
    insert into erbr_checks (description, problem, warn_lim, fail_lim) values ('Valid values: ins_medicaid', 'ins_medicaid has a bad value', 2, 5) ;
    insert into erbr_checks (description, problem, warn_lim, fail_lim) values ('Valid values: ins_medicare', 'ins_medicare has a bad value', 2, 5) ;
    insert into erbr_checks (description, problem, warn_lim, fail_lim) values ('Valid values: ins_medicare_a', 'ins_medicare_a has a bad value', 2, 5) ;
    insert into erbr_checks (description, problem, warn_lim, fail_lim) values ('Valid values: ins_medicare_b', 'ins_medicare_b has a bad value', 2, 5) ;
    insert into erbr_checks (description, problem, warn_lim, fail_lim) values ('Valid values: ins_medicare_c', 'ins_medicare_c has a bad value', 2, 5) ;
    insert into erbr_checks (description, problem, warn_lim, fail_lim) values ('Valid values: ins_medicare_d', 'ins_medicare_d has a bad value', 2, 5) ;
    insert into erbr_checks (description, problem, warn_lim, fail_lim) values ('Valid values: ins_other', 'ins_other has a bad value', 2, 5) ;
    insert into erbr_checks (description, problem, warn_lim, fail_lim) values ('Valid values: ins_privatepay', 'ins_privatepay has a bad value', 2, 5) ;
    insert into erbr_checks (description, problem, warn_lim, fail_lim) values ('Valid values: ins_selffunded', 'ins_selffunded has a bad value', 2, 5) ;
    insert into erbr_checks (description, problem, warn_lim, fail_lim) values ('Valid values: ins_statesubsidized', 'ins_statesubsidized has a bad value', 2, 5) ;
    insert into erbr_checks (description, problem, warn_lim, fail_lim) values ('Valid values: outside_utilization', 'outside_utilization has a bad value', 2, 5) ;

    insert into erbr_checks (description, problem, warn_lim, fail_lim) values ('Start/end agreement', 'enr_end is before enr_start', 0, 0) ;
    insert into erbr_checks (description, problem, warn_lim, fail_lim) values ('Future end dates?' 'future enr_end', 1, 3) ;
    insert into erbr_checks (description, problem, warn_lim, fail_lim) values ('Plan type(s) known?', 'no plan flags set', 2, 4) ;
    insert into erbr_checks (description, problem, warn_lim, fail_lim) values ('Insurance type(s) known?', 'no insurance flags set', 2, 4) ;
    insert into erbr_checks (description, problem, warn_lim, fail_lim) values ('Medicare flag agreement', 'medicare part flag set, but not overall flag', 0, 0) ;

    insert into erbr_checks (description, problem, warn_lim, fail_lim) values ('Mcare D before program was established?', 'medicare part d prior to 2006', 1, 2) ;
    insert into erbr_checks (description, problem, warn_lim, fail_lim) values ('High-deduct w/out commercial or private pay?', 'high-deduct w/out commercial or private pay', 1, 2) ;

    insert into erbr_checks (description, problem, warn_lim, fail_lim) values ('Outside ute agrees with drugcov?', 'no drug coverage, but outside ute flag not set', 0, 0) ;

  quit ;

  data to_stay.bad_enroll (drop = rid) periods (keep = mrn enr_start enr_end rid) ;
    length problem $ 50 ;
    set &inset end = alldone ;
    if _n_ = 1 then do ;
      * Define a hash to hold all the MRN values we see, so we can check it against the ones in demog ;
      declare hash mrns() ;
      mrns.definekey('mrn') ;
      mrns.definedone() ;
    end ;

    * Add the current MRN to our list if it is not already there. ;
    * mrns.ref() ;
    if mrns.find() ne 0 then do ;
      mrns.add() ;
    end ;

    * Periods gets everything. ;
    rid = _n_ ;
    output periods ;

    array flags{*}
      ins_commercial
      ins_highdeductible
      ins_medicaid
      ins_medicare
      ins_medicare_a
      ins_medicare_b
      ins_medicare_c
      ins_medicare_d
      ins_other
      ins_privatepay
      ins_selffunded
      ins_statesubsidized
      plan_hmo
      plan_indemnity
      plan_pos
      plan_ppo
      drugcov
      outside_utilization
    ;
    do i = 1 to dim(flags) ;
      if put(flags(i), $flg.) = "bad" then do ;
        problem = lowcase(vname(flags(i))) || " has a bad value" ;
        output to_stay.bad_enroll ;
      end ;
    end ;
    if put(enrollment_basis, $eb.) = "bad" then do ;
      problem = "enrollment_basis has a bad value" ;
      output to_stay.bad_enroll ;
    end ;
    if enr_start gt enr_end then do ;
      problem = "enr_end is before enr_start" ;
      output to_stay.bad_enroll ;
    end ;
    if enr_end gt "&sysdate"d then do ;
      problem = "future enr_end" ;
      output to_stay.bad_enroll ;
    end ;

    num_plans = countc(cats(plan_hmo, plan_indemnity, plan_pos, plan_ppo), 'Y') ;
    num_ins   = countc(cats(ins_commercial, ins_highdeductible
                       , ins_medicaid, ins_medicare, ins_medicare_a
                       , ins_medicare_b, ins_medicare_c, ins_medicare_d, ins_other
                       , ins_privatepay, ins_selffunded, ins_statesubsidized), 'Y') ;
    * We only expect these vars to be known for insurance-basis recs ;
    if enrollment_basis in ('I', 'B') then do ;
      if num_plans = 0 then do ;
        problem = "no plan flags set" ;
        output to_stay.bad_enroll ;
      end ;
      if num_ins = 0 then do ;
        problem = "no insurance flags set" ;
        output to_stay.bad_enroll ;
      end ;
    end ;

    if countc(cats(ins_medicare_a, ins_medicare_b, ins_medicare_c, ins_medicare_d), "Y") > 0 and ins_medicare ne 'Y' then do ;
      problem = "medicare part flag set, but not overall flag" ;
      output to_stay.bad_enroll ;
    end ;
    * Medicare part D did not begin until 2006. ;
    if ins_medicare_d = "Y" and enr_start lt '01jan2006'd then do ;
      problem = "medicare part d prior to 2006" ;
      output to_stay.bad_enroll ;
    end ;

    if ins_highdeductible = 'Y' and countc(cats(ins_commercial, ins_privatepay), 'Y') = 0 then do ;
      problem = "high-deduct w/out commercial or private pay" ;
      output to_stay.bad_enroll ;
    end ;

    if drugcov = 'N' and outside_utilization = 'N' then do ;
      problem = "no drug coverage, but outside ute flag not set" ;
      output to_stay.bad_enroll ;
    end ;
    if alldone then do ;
      rc = mrns.output(dataset:"enroll_mrns") ;
    end ;
    drop i rc alldone ;
  run ;

  proc sql ;
    reset noprint ;
    * Check MRNs from enroll against demog. ;
    select  count(e.mrn) as num_enroll_mrns
          , count(d.mrn) as num_in_demog
          , (count(e.mrn) - count(d.mrn)) as num_bad
          , (count(d.mrn) / count(e.mrn) * 100) as percent_found
          , 100 - CALCULATED percent_found as percent_bad
          , case
            when CALCULATED percent_found lt 96 then 'fail'
            when CALCULATED percent_found lt 98 then 'warning'
            else 'pass'
          end as result
    into :num_enroll_mrns, :num_in_demog, :num_bad, :percent_found, :percent_bad, :mrn_result
    from enroll_mrns as e LEFT JOIN
          &_vdw_demographic as d
    on      e.mrn = d.mrn
    ;

    %if &mrn_result ne pass %then %do ;
      create table to_stay.enroll_mrns_not_in_demog as
      select e.mrn
      from enroll_mrns as e LEFT JOIN
            &_vdw_demographic as d
      on    e.mrn = d.mrn
      where d.mrn IS NULL
      ;
    %end ;

    insert into results (description, qa_macro, detail_dset, num_bad, percent_bad, result)
        values ("MRNs in enrollment found in demog?", '%enroll_tier_one', "to_stay.enroll_mrns_not_in_demog",  &num_bad, &percent_bad, "&mrn_result")
    ;

    * Whats our denominator on enrollment? ;
    select count(*) as num_enroll_recs into :num_enroll_recs from &inset ;

    create table bad_enroll_summary as
    select   problem, count(*) as num_bad, (count(*) / &num_enroll_recs) * 100 as percent_bad
    from to_stay.bad_enroll
    group by problem
    ;

    * meta-QA!!! ;
    * I wish I could check to make sure all the checks were implemented... ;
    select problem
    into :unexpected_problems separated by ', '
    from bad_enroll_summary
    where problem not in (select problem from erbr_checks)
    ;

    %if &sqlobs > 0 %then %do i = 1 %to 10 ;
      %put ERROR: IN QA ENROLL_TIEr_OnE--found these unexpected checks: &unexpected_problems ;
    %end ;

    create table enroll_rbr_checks as
    select e.*
        , coalesce(num_bad, 0) as num_bad format = comma14.0
        , coalesce(percent_bad, 0) as percent_bad format = 8.2
        , case
            when percent_bad gt fail_lim then 'fail'
            when percent_bad gt warn_lim then 'warning'
            else 'pass'
          end as result
    from  erbr_checks as e LEFT JOIN
          bad_enroll_summary as b
    on    e.problem = b.problem
    ;

    insert into results (description, qa_macro, detail_dset, num_bad, percent_bad, result)
    select description, '%enroll_tier_one', 'to_stay.bad_enroll', num_bad, percent_bad, result
    from enroll_rbr_checks
    ;

    * Check for overlapping periods. ;
    create table to_stay.overlapping_periods as
    select
          p1.mrn
        , p1.enr_start as start1
        , p1.enr_end   as end1
        , p2.enr_start as start2
        , p2.enr_end   as end2
        , (p1.enr_start lt p2.enr_end AND
          p1.enr_end   gt p2.enr_start) as overlap
    from  periods as p1 INNER JOIN
          periods as p2
    on    p1.mrn = p2.mrn
    where (p1.rid > p2.rid)
          AND (p1.enr_start le p2.enr_end AND p1.enr_end  ge p2.enr_start)
    ;
    %if &sqlobs > 0 %then %do ;
      insert into results (description, qa_macro, detail_dset, num_bad, percent_bad, result)
      values ('Do enrollment periods overlap?', '%enroll_tier_one', 'to_stay.overlapping_periods',  &sqlobs, %sysevalf(&sqlobs / &num_enroll_recs), 'fail')
      ;
    %end ;
    %else %do ;
      insert into results (description, qa_macro, detail_dset, num_bad, percent_bad, result)
      values ('Do enrollment periods overlap?', '%enroll_tier_one', 'to_stay.overlapping_periods', 0, 0, 'pass')
      ;
    %end ;
  quit ;

%mend enroll_tier_one ;

%macro demog_tier_one(inset = &_vdw_demographic) ;
  /*
    Checks
      - duplicated MRNs
      - valid values for:
          gender
          birth_date--NOT CURRENTLY CHECKED!
          hispanic
          needs_interpreter
          primary_language
          race1
          race2
          race3
          race4
          race5
   */

  proc sql ;
    create table demog_checks
    (   description char(50)
      , problem char(50)
      , warn_lim numeric
      , fail_lim numeric
    ) ;

    insert into demog_checks (description, problem, warn_lim, fail_lim)
    select 'Valid values: ' || trim(name), 'bad value in ' || trim(name), 2, 5
    from expected_vars
    where dset = 'demog' and name not in ('mrn', 'birth_date')
    ;

    * insert into demog_checks (description, problem, warn_lim, fail_lim) values ('Duplicated MRNs?', 'MRNs are not unique', 0, 0) ;

  quit ;

  data to_stay.bad_demog (drop = cnt) ;
    set &inset end = alldone ;
    if _n_ = 1 then do ;
      * While we are looping through demog, lets check for duped MRNs. ;
      declare hash mrns() ;
      mrns.definekey('mrn') ;
      mrns.definedata('mrn') ;
      mrns.definedata('cnt') ;
      mrns.definedone() ;
    end ;

    if mrns.find() = 0 then do ;
      cnt = cnt + 1 ;
      mrns.replace() ;
    end ;
    else do ;
      cnt = 1 ;
      mrns.add() ;
    end ;

    array flags hispanic needs_interpreter ;
    do i = 1 to dim(flags) ;
      if put(flags{i}, $flg.) = 'bad' then do ;
        problem = "bad value in " || lowcase(vname(flags{i})) ;
        output to_stay.bad_demog ;
      end ;
    end ;

    array race race1 - race5 ;
    do i = 1 to dim(race) ;
      if put(race{i}, $race.) = 'bad' then do ;
        problem = "bad value in " || lowcase(vname(race{i})) ;
        output to_stay.bad_demog ;
      end ;
    end ;

    if put(gender, $gend.) = 'bad' then do ;
      problem = "bad value in gender" ;
      output to_stay.bad_demog ;
    end ;

    if put(primary_language, $lang.) = 'bad' then do ;
      problem = "bad value in primary_language" ;
      output to_stay.bad_demog ;
    end ;

    if alldone then do ;
      mrns.output(dataset: 'demog_mrns') ;
    end ;

    drop i ;
  run ;

  data to_stay.duplicated_demog_mrns ;
    retain num_dupes 0 ;
    set demog_mrns end = alldone ;
    if cnt > 1 then do ;
      num_dupes + cnt ;
      output ;
    end ;
    if alldone then do ;
      call symput('num_dupes', put(num_dupes, best.)) ;
      call symput('percent_dupes', put((num_dupes / _n_) * 100, best.)) ;
    end ;
    drop num_dupes ;
  run ;

  proc sql ;
    reset noprint ;

    %if &num_dupes > 0 %then %do ;
      insert into results (description, qa_macro, detail_dset, num_bad, percent_bad, result)
      values ("Duplicated MRNs in demog?", '%demog_tier_one', "to_stay.duplicated_demog_mrns",  &num_dupes, &percent_dupes, "fail")
      ;
    %end ;
    %else %do ;
      insert into results (description, qa_macro, detail_dset, num_bad, percent_bad, result)
      values ("Duplicated MRNs in demog?", '%demog_tier_one', "to_stay.duplicated_demog_mrns",  &num_dupes, &percent_dupes, "pass")
      ;
    %end ;

    * Whats our denominator on demog? ;
    select count(*) as num_demog_recs into :num_demog_recs from &inset ;

    create table bad_demog_summary as
    select   problem, count(*) as num_bad, (count(*) / &num_demog_recs) * 100 as percent_bad
    from to_stay.bad_demog
    group by problem
    ;

    * meta-QA!!! ;
    * I wish I could check to make sure all the checks were implemented... ;
    select problem
    into :unexpected_problems separated by ', '
    from bad_demog_summary
    where problem not in (select problem from demog_checks)
    ;

    %if &sqlobs > 0 %then %do i = 1 %to 10 ;
      %put ERROR: IN QA DEMOG_TIER_ONE--found these unexpected checks: &unexpected_problems ;
    %end ;

    create table demog_rbr_checks as
    select e.*
        , coalesce(num_bad, 0) as num_bad format = comma14.0
        , coalesce(percent_bad, 0) as percent_bad format = 8.2
        , case
            when percent_bad gt fail_lim then 'fail'
            when percent_bad gt warn_lim then 'warning'
            else 'pass'
          end as result
    from  demog_checks as e LEFT JOIN
          bad_demog_summary as b
    on    e.problem = b.problem
    ;

    insert into results (description, qa_macro, detail_dset, num_bad, percent_bad, result)
    select description, '%demog_tier_one', 'to_stay.bad_demog', num_bad, percent_bad, result
    from demog_rbr_checks
    ;


  quit ;

%mend demog_tier_one ;

%macro enroll_tier_one_point_five(inset = to_stay.denoms, outset = to_go.&_siteabbr._enroll_freqs) ;

  %removedset(dset = &outset) ;

  data &outset ;
    length
      year 4
      var_name $ 20
      value $ 4
      count 8
      percent 8
    ;
    call missing(year, var_name, value, count, percent) ;
    if count ;
  run ;

  %local vlist ;
  %let vlist =
      enrollment_basis
      drugcov
      ins_commercial
      ins_highdeductible
      ins_medicaid
      ins_medicare
      ins_medicare_a
      ins_medicare_b
      ins_medicare_c
      ins_medicare_d
      ins_other
      ins_privatepay
      ins_selffunded
      ins_statesubsidized
      outside_utilization
      plan_hmo
      plan_indemnity
      plan_pos
      plan_ppo
    ;

  %local this_var ;
  %local i ;
  %let i = 1 ;
  %let this_var = %scan(&vlist, &i) ;

  %do %until(&this_var = ) ;
    proc freq data = &inset order = formatted ;
      tables &this_var * year / missing format = msk. out = gnu ;
      weight prorated_total ;
      format &this_var ;
    run ;
    proc sql ;
      insert into &outset (year, var_name, value, count, percent)
      select year, "&this_var", &this_var, count, percent
      from gnu
      ;
      drop table gnu ;
    quit ;
    %let i = %eval(&i + 1) ;
    %let this_var = %scan(&vlist, &i) ;
  %end ;

  proc sql ;
    update &outset
    set count = .a, percent = .a
    where count between 1 and &lowest_count
    ;
  quit ;

%mend enroll_tier_one_point_five ;

%macro demog_tier_one_point_five(outset = to_go.&_siteabbr._demog_freqs) ;

  %removedset(dset = &outset) ;

  data &outset ;
    length
      gender $ 1
      var_name $ 20
      value $ 4
      count 8
      percent 8
    ;
    call missing(gender, var_name, value, count, percent) ;
    if count ;
  run ;

  %local vlist ;
  %let vlist =
      hispanic
      needs_interpreter
      primary_language
      race1
      race2
      race3
      race4
      race5
    ;

  %local this_var ;
  %local i ;
  %let i = 1 ;
  %let this_var = %scan(&vlist, &i) ;

  %do %until(&this_var = ) ;
    proc freq data = &_vdw_demographic order = formatted ;
      tables &this_var * gender / missing format = msk. out = gnu ;
      format &this_var ;
    run ;
    proc sql ;
      insert into &outset (gender, var_name, value, count, percent)
      select gender, "&this_var", &this_var, count, percent
      from gnu
      ;
      drop table gnu ;
    quit ;
    %let i = %eval(&i + 1) ;
    %let this_var = %scan(&vlist, &i) ;
  %end ;

  proc sql ;
    update &outset
    set count = .a, percent = .a
    where count between 1 and &lowest_count
    ;
  quit ;

%mend demog_tier_one_point_five ;

options obs = 2000 ;
%make_bigass_dset ;
* %enroll_tier_one_point_five(inset = s.bigass) ;

/*
%check_vars ;
%enroll_tier_one ;
%demog_tier_one ;
data to_go.&_siteabbr._tier_one_results ;
  set results ;
run ;
*/

ods html path   = "%sysfunc(pathname(to_go))" (URL=NONE)
         body   = "&_siteabbr._vdw_enroll_demog_qa.html"
         (title = "&_SiteName.: QA for Enroll/Demographics - Tier 1 & 1.5")
          ;

  title1 "&_SiteName.: QA for Enroll/Demographics" ;
  title2 "Tier One Checks" ;
  * proc sql number ;
  *   select * from to_go.&_siteabbr._tier_one_results ;
  * quit ;

  title2 "Tier 1.5 Checks" ;
  * %enroll_tier_one_point_five(outset = to_go.&_siteabbr._enroll_freqs) ;
  * %demog_tier_one_point_five(outset = to_go.&_siteabbr._demog_freqs) ;

run ;

ods _all_ close ;
