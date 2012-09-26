/*********************************************
* Roy Pardee
* Group Health Research Institute
* (206) 287-2078
* pardee.r@ghc.org
*
* //groups/data/CTRHS/Crn/voc/enrollment/programs/vdw_enroll_demog_qa.sas
*
* Does comprehensive QA checks for the HMORN VDW's Enrollment & Demographics files.
*********************************************/

* ======================= begin edit section ======================= ;
* ======================= begin edit section ======================= ;
* ======================= begin edit section ======================= ;

* If roy forgets to comment this out, please do so.  Thanks/sorry! ;
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

* Please edit this to point to your local standard vars file. ;
%include "\\groups\data\CTRHS\Crn\S D R C\VDW\Macros\StdVars5p.sas" ;

* Please specify a location for "private" datasets that the e/d workgroup does not want to see ;
libname to_stay "\\ghrisas\SASUser\pardre1\vdw\voc_enroll" ;
libname to_go   "\\ghrisas\SASUser\pardre1\vdw\voc_enroll\send" ;

* ======================== end edit section ======================== ;
* ======================== end edit section ======================== ;
* ======================== end edit section ======================== ;

data expected_vars ;
  length name $ 32 ;
  input
    @1   dset      $
    @9   name  $char20.
    @33   type
    @37   recommended_length
  ;
  infile datalines missover ;
datalines ;
demog   gender                  2
demog   birth_date              1   4
demog   hispanic                2
demog   mrn                     2
demog   needs_interpreter       2
demog   primary_language        2
demog   race1                   2
demog   race2                   2
demog   race3                   2
demog   race4                   2
demog   race5                   2
enroll  mrn                     2
enroll  enr_end                 1   4
enroll  enr_start               1   4
enroll  enrollment_basis        2
enroll  drugcov                 2
enroll  ins_commercial          2
enroll  ins_highdeductible      2
enroll  ins_medicaid            2
enroll  ins_medicare            2
enroll  ins_medicare_a          2
enroll  ins_medicare_b          2
enroll  ins_medicare_c          2
enroll  ins_medicare_d          2
enroll  ins_other               2
enroll  ins_privatepay          2
enroll  ins_selffunded          2
enroll  ins_statesubsidized     2
enroll  outside_utilization     2
enroll  pcc                     2
enroll  pcp                     2
enroll  plan_hmo                2
enroll  plan_indemnity          2
enroll  plan_pos                2
enroll  plan_ppo                2
;
run ;

proc sql ;
  create table results
   ( description  char(50) label = "Description"
   , qa_macro     char(30) label = "Name of the macro that does this check"
   , detail_dset  char(30) label = "Look for further details in this dataset"
   , num_bad      numeric  label = "For record-based checks, how many records offend the spec?" format = comma14.0
   , percent_bad  numeric  label = "For record-based checks, bad records are what % of total?"  format = 8.2
   , result       char(8)  label = "Result"
   )
  ;
quit ;

%macro check_vars ;
  proc format ;
    value vtype
      1 = "numeric"
      2 = "char"
    ;
  quit ;

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

%macro enroll_row_by_row ;
  /*
    Combines several checks in a quest for efficiency.
  */
  proc format ;
    value $flg
      "Y"   = "yes"
      "N"   = "no"
      "U"   = "unknown"
      other = "bad"
    ;
    value $eb
      "I"   = "insurance"
      "G"   = "geography"
      "B"   = "both ins + geog"
      "P"   = "patient only"
      other = "bad"
    ;
  quit ;

  proc sql ;
    create table erbr_checks
    (   description char(50)
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

    insert into erbr_checks (description, problem, warn_lim, fail_lim) values ('Start/end agreement', 'enr_end is before or on enr_start', 0, 0) ;
    insert into erbr_checks (description, problem, warn_lim, fail_lim) values ('Future end dates?' 'future enr_end', 1, 3) ;
    insert into erbr_checks (description, problem, warn_lim, fail_lim) values ('Plan type(s) known?', 'no plan flags set', 2, 4) ;
    insert into erbr_checks (description, problem, warn_lim, fail_lim) values ('Insurance type(s) known?', 'no insurance flags set', 2, 4) ;
    insert into erbr_checks (description, problem, warn_lim, fail_lim) values ('Medicare flag agreement', 'medicare part flag set, but not overall flag', 0, 0) ;

    insert into erbr_checks (description, problem, warn_lim, fail_lim) values ('Mcare D before program was established?', 'medicare part d prior to 2006', 1, 2) ;
    insert into erbr_checks (description, problem, warn_lim, fail_lim) values ('High-deduct w/out commercial or private pay?', 'high-deduct w/out commercial or private pay', 1, 2) ;

    insert into erbr_checks (description, problem, warn_lim, fail_lim) values ('Outside ute agrees with drugcov?', 'no drug coverage, but outside ute flag not set', 0, 0) ;

  quit ;

  data to_stay.bad_enroll ;
    length problem $ 40 ;
    set &_vdw_enroll end = alldone ;
    if _n_ = 1 then do ;
      * Define a hash to hold all the MRN values we see, so we can check it against the ones in demog ;
      declare hash mrns() ;
      mrns.definekey('mrn') ;
      mrns.definedone() ;
    end ;

    * Add the current MRN to our list if it is not already there. ;
    mrns.ref() ;

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
    if enr_start ge enr_end then do ;
      problem = "enr_end is before or on enr_start" ;
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
          , case
            when CALCULATED percent_found lt 96 then 'fail'
            when CALCULATED percent_found lt 98 then 'warn'
            else 'pass'
          end as result
    into :num_enroll_mrns, :num_in_demog, :num_bad, :percent_found, :mrn_result
    from enroll_mrns as e LEFT JOIN
          &_vdw_demographic (obs = 20000) as d
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
        values ("MRNs in enrollment foundin demog?", '%enroll_row_by_row', "to_stay.enroll_mrns_not_in_demog",  &num_bad, &percent_found, "&mrn_result")
    ;

    * Whats our denominator on enrollment? ;
    select count(*) as num_enroll_recs into :num_enroll_recs from &_vdw_enroll ;

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
      %put ERROR: IN QA ENROLL_ROW_BY_ROW--found these unexpected checks: &unexpected_problems ;
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
    select description, '%enroll_row_by_row', 'to_stay.bad_enroll', num_bad, percent_bad, result
    from enroll_rbr_checks
    ;
  quit ;

%mend enroll_row_by_row ;

options mprint mlogic ;

%check_vars ;
%enroll_row_by_row ;

data to_go.&_siteabbr._results ;
  set results ;
run ;
