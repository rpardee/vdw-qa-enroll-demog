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
* https://www.hcsrn.org/share/page/site/VDW/wiki-page?title=Enroll-Demog-Lang%20QA%20for%20HCSRN%202016%20Annual%20Meeting
*
*********************************************/

/*

  TODO:
    - integrate dec -> jan enrollee count * insurance type

*/

/********************************************
*         UPDATE LOG
*********************************************
* Paul Hitz
* Essentia Institute of Rural Health
* (218) 786-1008
* pjh19401 (search string)
* Added checks for the Languages table.
*********************************************/

* ======================= begin edit section ======================= ;
* ======================= begin edit section ======================= ;
* ======================= begin edit section ======================= ;

* If roy forgets to comment this out, please do so.  Thanks/sorry! ;
* %include "h:/SAS/Scripts/remoteactivate.sas" ;

options
  linesize  = 150
  msglevel  = i
  formchar  = '|-++++++++++=|-/|<>*'
  /* dsoptions = note2err */
  nosqlremerge
  nocenter
  noovp
  mprint
  mlogic
;

%macro set_opt ;
  %if &sysver = 9.4 %then %do ;
    options extendobscounter = no ;
  %end ;

%mend set_opt ;

%set_opt ;

* Undefine all libnames, just in case I rely on GHC-specific nonstandard ones downstream. ;
libname _all_ clear ;

* Please edit this to point to your local standard vars file. ;
%include "&GHRIDW_ROOT/Sasdata/CRN_VDW/lib/StdVars.sas" ;

* Please edit this so it points to the location where you unzipped the files/folders. ;
%let root = //groups/data/CTRHS/Crn/voc/enrollment/programs/ghc_qa ;

* Some sites are having trouble w/the calls to SGPlot--if you want to try to get the graphs please set this var to false. ;
* If you do and get errors, please keep it set to true. ;
%let skip_graphs = true ;
%let skip_graphs = false ;

* Please set start_year to your earliest date of enrollment data. ;
%let start_year = 1988 ;
%let end_year = %sysfunc(intnx(year, "&sysdate9"d, -1, end), year4.) ;

* For the completeness graphs, what is the minimum monthly enrolled N we require ;
* before we are willing to plot the point? ;
%let min_n = 200 ;

/*

  If your VDW files are not in an rdbms you can ignore the rest of this edit
  section. If they are & you want to possibly save a ton of processing time,
  please read on.

  The bulk of the work of this program is done in a SQL join between VDW
  enrollment, a substantive VDW file (like rx or tumor), and a small utility
  dataset of the months between &start_year and &end_year.

  If you have the wherewithal to create this utility dataset on the db server
  where the rest of your VDW tables live, then SAS will (probably) pass the
  join work off tothe db to complete, which is orders of magnitude faster than
  having SAS pull your tables into temp datasets & do the join on the SAS
  side. At Group Health (we use Teradata) making this change turned a job that
  ran in about 14 hours into one that runs in 15 *minutes*.

  TO DO SO, create a libname pointing at a db on the same server as VDW, to
  which you have CREATE TABLE permissions.  You can see what I used at GH
  commented-out, below.  I *believe* the 'connection = global' bit is necessary
  to get the join pushed to the db, and that it works for rdbms' other than
  Teradata, but am not positive.  I'd love to hear your experience if anybody
  tries this out.
*/

libname mylib teradata
  user              = "&username@LDAP"
  password          = "&password"
  server            = "&td_prod"
  schema            = "%sysget(username)"
  multi_datasrc_opt = in_clause
  connection        = global
;

%let tmplib = mylib ;
* %let tmplib = work ;

* ======================== end edit section ======================== ;
* ======================== end edit section ======================== ;
* ======================== end edit section ======================== ;

%include vdw_macs ;

* Test program--replaces real enroll/demog with deformed versions. ;
* %include "//groups/data/CTRHS/Crn/voc/enrollment/test_tier1_qa.sas" ;

%include "&root./qa_formats.sas" ;
%include "&root./vdw_lang_qa.sas" ;
%include "&root./simple_data_rates_generic.sas" ;
%include "&root./graph_data_rates.sas" ;

libname to_stay "&root./DO_NOT_SEND" ;
libname to_go   "&root./to_send" ;

proc sql ;
  create table results
   ( description  char(80) label = "Description"
   , qa_macro     char(30) label = "Name of the macro that does this check"
   , detail_dset  char(40) label = "Look for further details in this dataset"
   , num_bad      numeric  label = "For record-based checks, how many records offend the spec?" format = comma14.0
   , percent_bad  numeric  label = "For record-based checks, bad records are what % of total?"  format = 8.2
   , result       char(8)  label = "Result"
   )
  ;
quit ;

%macro check_vars ;
  proc contents noprint data = &_vdw_demographic  out = dvars(keep = name type length label) ;
  run ;
  proc contents noprint data = &_vdw_enroll       out = evars(keep = name type length label) ;
  run ;
  * Added pjh19401 ;
  proc contents noprint data = &_vdw_language     out = lvars(keep = name type length label) ;
  run ;

  data observed_vars ;
  * pjh19401    set evars (in = e) dvars ;
    set
      lvars (in = l)
      evars (in = e)
      dvars ;
    name = lowcase(name) ;
    if e then dset = 'enroll' ;
  else
    if l then dset = 'lang';
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

    select count(*)
    into :num_demlang
    from to_go.&_siteabbr._noteworthy_vars
    where lowcase(dset) = 'demog' and lowcase(name) = 'primary_language'
    ;

    %if &num_demlang > 0 %then %do ;
      insert into results(description, qa_macro, detail_dset, result)
      values ("Primary_language has been removed from demog.", '%check_vars', "to_go.noteworthy_vars","fail")
      ;
    %end ;
    %else %do ;
      insert into results(description, qa_macro, detail_dset, result)
      values ("Primary_language has been removed from demog.", '%check_vars', "to_go.noteworthy_vars","pass")
      ;
    %end ;
    select count(*)
    into :num_outute
    from to_go.&_siteabbr._noteworthy_vars
    where lowcase(dset) = 'enroll' and lowcase(name) = 'outside_utilization'
    ;

    %if &num_outute > 0 %then %do ;
      insert into results(description, qa_macro, detail_dset, result)
      values ("Outside_utilization has been removed from enrollment.", '%check_vars', "to_go.noteworthy_vars","fail")
      ;
    %end ;
    %else %do ;
      insert into results(description, qa_macro, detail_dset, result)
      values ("Outside_utilization has been removed from enrollment.", '%check_vars', "to_go.noteworthy_vars","pass")
      ;
    %end ;
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

/* This macro comes from: http://blogs.sas.com/content/sasdummy/2013/06/12/correlations-matrix-heatmap-with-sas/ */
/* Prepare the correlations coeff matrix: Pearson's r method */
%macro prepCorrData(in=,wtvar = wt, out=);
  /* Run corr matrix for input data, all numeric vars */
  proc corr data=&in. noprint
    pearson
    outp=work._tmpCorr
    vardef=df
  ;
    weight &wtvar ;
  run;

  /* prep data for heat map */
  data &out.;
    keep x y r;
    set work._tmpCorr(where=(_TYPE_="CORR"));
    array v{*} _numeric_;
    x = put(_NAME_, $flgnm.);
    do i = dim(v) to 1 by -1;
      y = put(vname(v(i)), $flgnm.);
      r = v(i);
      /* creates a lower triangular matrix */
      if (i<_n_) then
        r=.;
      output;
    end;
  run;

  proc datasets lib=work nolist nowarn;
    delete _tmpcorr;
  quit;
%mend prepCorrData ;

%macro enroll_tier_one(inset = &_vdw_enroll, outcorr = to_go.&_siteabbr._flagcorr) ;
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

    insert into erbr_checks (description, problem, warn_lim, fail_lim) values ('Valid values: enrollment_basis', 'enrollment_basis has a bad value', 0, 0) ;
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
    insert into erbr_checks (description, problem, warn_lim, fail_lim) values ('Valid values: plan_hmo', 'plan_hmo has a bad value', 2, 5) ;
    insert into erbr_checks (description, problem, warn_lim, fail_lim) values ('Valid values: plan_pos', 'plan_pos has a bad value', 2, 5) ;
    insert into erbr_checks (description, problem, warn_lim, fail_lim) values ('Valid values: plan_ppo', 'plan_ppo has a bad value', 2, 5) ;
    insert into erbr_checks (description, problem, warn_lim, fail_lim) values ('Valid values: plan_indemnity', 'plan_indemnity has a bad value', 2, 5) ;

    insert into erbr_checks (description, problem, warn_lim, fail_lim) values ('Valid values: incomplete_outpt_rx', 'incomplete_outpt_rx has a bad value', 2, 5) ;
    insert into erbr_checks (description, problem, warn_lim, fail_lim) values ('Valid values: incomplete_outpt_enc', 'incomplete_outpt_enc has a bad value', 2, 5) ;
    insert into erbr_checks (description, problem, warn_lim, fail_lim) values ('Valid values: incomplete_inpt_enc', 'incomplete_inpt_enc has a bad value', 2, 5) ;
    insert into erbr_checks (description, problem, warn_lim, fail_lim) values ('Valid values: incomplete_emr', 'incomplete_emr has a bad value', 2, 5) ;
    insert into erbr_checks (description, problem, warn_lim, fail_lim) values ('Valid values: incomplete_lab', 'incomplete_lab has a bad value', 2, 5) ;
    insert into erbr_checks (description, problem, warn_lim, fail_lim) values ('Valid values: incomplete_tumor', 'incomplete_tumor has a bad value', 2, 5) ;

    insert into erbr_checks (description, problem, warn_lim, fail_lim) values ('Start/end agreement', 'enr_end is before enr_start', 0, 0) ;
    insert into erbr_checks (description, problem, warn_lim, fail_lim) values ('Future end dates?' 'future enr_end', 1, 3) ;
    insert into erbr_checks (description, problem, warn_lim, fail_lim) values ('Plan type(s) known?', 'no plan flags set', 2, 4) ;
    insert into erbr_checks (description, problem, warn_lim, fail_lim) values ('Insurance type(s) known?', 'no insurance flags set', 2, 4) ;
    insert into erbr_checks (description, problem, warn_lim, fail_lim) values ('Medicare flag agreement', 'medicare part flag set, but not overall flag', 0, 0) ;

    insert into erbr_checks (description, problem, warn_lim, fail_lim) values ('Mcare D before program was established?', 'medicare part d prior to 2006', 1, 2) ;
    insert into erbr_checks (description, problem, warn_lim, fail_lim) values ('High-deduct w/out commercial or private pay?', 'high-deduct w/out commercial or private pay', 1, 2) ;

    insert into erbr_checks (description, problem, warn_lim, fail_lim) values ('Medicare Part D agrees with drugcov?', 'ins_medicare_d = Y, but drugcov = N', 0, 0) ;

  quit ;

  data
    to_stay.bad_enroll (drop = rid flg_: wt)
    periods (keep = mrn enr_start enr_end rid)
    tmpcorr (keep = mrn enr_start enr_end wt flg_:)
  ;
    length
      flg_commercial
      flg_highdeductible
      flg_medicaid
      flg_medicare
      flg_medicare_a
      flg_medicare_b
      flg_medicare_c
      flg_medicare_d
      flg_other
      flg_privatepay
      flg_selffunded
      flg_statesubsidized
      flg_hmo
      flg_pos
      flg_ppo
      flg_indemnity
      3
      problem $ 50
      den_var $ 30
      den_val $ 1
      frq 5
    ;
    set &inset end = alldone ;
    if _n_ = 1 then do ;
      * Define a hash to hold all the MRN values we see, so we can check it against the ones in demog ;
      declare hash mrns() ;
      mrns.definekey('mrn') ;
      mrns.definedone() ;
      * And another to hold freqs for the incomplete_* vars to check for bad combos of values. ;
      declare hash denvals() ;
      denvals.definekey('den_var', 'den_val') ;
      denvals.definedata('den_var', 'den_val', 'frq') ;
      denvals.definedone() ;
      call missing(den_var, den_val, frq) ;
    end ;

    * Add the current MRN to our list if it is not already there. ;
    * mrns.ref() ;
    if mrns.find() ne 0 then do ;
      mrns.add() ;
    end ;

    * Periods gets everything. ;
    rid = _n_ ;
    output periods ;

    * For flag correlation heatmap ;
    array ins ins_commercial ins_highdeductible ins_medicaid ins_medicare ins_medicare_a ins_medicare_b ins_medicare_c ins_medicare_d ins_other ins_privatepay ins_selffunded ins_statesubsidized plan_hmo plan_pos plan_ppo plan_indemnity ;
    array flg flg_commercial flg_highdeductible flg_medicaid flg_medicare flg_medicare_a flg_medicare_b flg_medicare_c flg_medicare_d flg_other flg_privatepay flg_selffunded flg_statesubsidized flg_hmo  flg_pos  flg_ppo  flg_indemnity ;
    do i = 1 to dim(ins) ;
      flg{i} = (ins{i} = 'Y') ;
      wt = intck('month', enr_start, enr_end) + 1 ;
    end ;
    * tmpcorr also gets everything ;
    output tmpcorr ;

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
    ;

    do i = 1 to dim(flags) ;
      if put(flags(i), $flg.) = "bad" then do ;
        problem = catx(' ', lowcase(vname(flags(i))), "has a bad value") ;
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

    array denflgs{*}
      incomplete_outpt_rx
      incomplete_outpt_enc
      incomplete_inpt_enc
      incomplete_emr
      incomplete_tumor
      incomplete_lab
    ;
    do i = 1 to dim(denflgs) ;
      den_var = lowcase(vname(denflgs(i))) ;
      den_val = denflgs(i) ;
      if denvals.find() = 0 then do ;
        frq = frq + 1 ;
        denvals.replace() ;
      end ;
      else do ;
        frq = 1 ;
        denvals.add() ;
      end ;
      if put(denflgs{i}, $incflg.) = "bad" then do ;
        problem = catx(' ', den_var, "has a bad value") ;
        output to_stay.bad_enroll ;
      end ;
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

    if drugcov = 'N' and ins_medicare_d = 'Y' then do ;
      problem = "ins_medicare_d = Y, but drugcov = N" ;
      output to_stay.bad_enroll ;
    end ;
    if alldone then do ;
      rc = mrns.output(dataset:"enroll_mrns") ;
      rc = denvals.output(dataset:"denvals") ;
    end ;
    drop i rc alldone den_var den_val frq ;
  run ;

  %prepCorrData(in=tmpcorr(keep = wt flg_:), out=&outcorr) ;

  %removedset(dset = tmpcorr) ;

  proc sql ;
    * Check denominator vars for bad combos of X and not-X ;
    create table xcounts as
    select den_var
          , sum(case when den_val = 'X' then 1 else 0 end) as num_xs
          , count(*) as num_rows
    from denvals
    group by den_var
    ;
    * describe table results ;
    create table den_res as
    select substr(catx('', den_var, ': if any value = X, then ALL values must = X'), 1, 80) as description length = 80
          , '%enroll_tier_one' as qa_macro
          , 'n/a--sorry' as detail_dset
          , . as num_bad
          , . as percent_bad
        , case when num_xs > 0 and num_rows > num_xs then 'fail' else 'pass' end as result
    from xcounts
    ;
    insert into results (description, qa_macro, detail_dset, num_bad, percent_bad, result)
    select *
    from den_res
    ;

    drop table xcounts ;
    drop table den_res ;

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

    drop table enroll_mrns ;

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
      %put ERROR: IN QA ENROLL_TIER_ONE--found these unexpected checks: &unexpected_problems ;
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

    alter table periods drop rid ;
  quit ;

  * We dont want bad_enroll to be unwieldy--remove all but 50 examples of each problem found. ;
  data to_stay.bad_enroll (label="Records from &_vdw_enroll found wanting (SAMPLE ONLY--50 SAMPLE RECS/PROBLEM!)") ;
    length num_recs 3 ;
    set to_stay.bad_enroll ;
    if _n_ = 1 then do ;
      declare hash seen_probs() ;
      seen_probs.definekey('problem') ;
      seen_probs.definedata('problem', 'num_recs') ;
      seen_probs.definedone() ;
      call missing(num_recs) ;
    end ;
    if seen_probs.find() = 0 then do ;
      num_recs = num_recs + 1 ;
      seen_probs.replace() ;
    end ;
    else do ;
      num_recs = 1 ;
      seen_probs.add() ;
    end ;
    if num_recs le 50 then output ;
    drop num_recs ;
  run ;

  * Now produce descriptives on enrollment lengths. ;
  * Step 1--close up any gaps shorter than 92 days (intention is 3 months). ;
  %collapseperiods(lib     = work
                , dset     = periods
                , daystol  = 92
                , recstart = enr_start
                , recend   = enr_end
                , outset   = periods
                ) ;

  * Step 2--calculate the duration of each period. ;
  data periods ;
    set periods ;
    duration_in_months = (enr_end - enr_start) / 30 ;
    label duration_in_months = 'No. of 30-day months in this period' ;
  run ;

  * Step 3--output stats on the distribution. ;
  proc summary data = periods n min p10 p25 p50 mean p75 p90 max ;
    var duration_in_months ;
    output out = to_go.&_siteabbr._enroll_duration_stats
      n     = duration_n
      min   = duration_min
      p10   = duration_p10
      p25   = duration_p25
      p50   = duration_p50
      mean  = duration_mean
      p75   = duration_p75
      p90   = duration_p90
      max   = duration_max
      std   = duration_std
    ;
  run ;

  %removedset(dset = periods) ;

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
  %removedset(dset = demog_mrns) ;
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

%macro make_denoms(outset = to_stay.denoms) ;

  /* This is copied from the make_denoms standard macro--adding in all the enroll vars. */
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
      65  -< 70 = '65to69'
      70  -< 75 = '70to74'
      75 - high = 'ge_75'
    ;
    ** For setting priority order to favor values of Y. ;
    value $dc
      'Y'   = '10'
      'K'   = '20'
      'N'   = '30'
      'E'   = '40'
      'X'   = '50'
      other = '60'
    ;
    ** For translating back to permissible values of DrugCov ;
    value $cd
      '10' = 'Y'
      '20' = 'K'
      '30' = 'N'
      '40' = 'E'
      '50' = 'X'
      '60' = 'U'
    ;
    value $Race
      'WH' = 'White'
      'BA' = 'Black'
      'IN' = 'Native'
      'AS' = 'Asian'
      'HP' = 'Pac Isl'
      'MU' = 'Multiple'
      'OT' = 'Other'
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
    value bin
      0 = 'N'
      1 = 'Y'
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
          , min(put(drugcov             , $dc.))  as drugcov
          , min(put(incomplete_outpt_rx , $dc.))  as incomplete_outpt_rx
          , min(put(incomplete_outpt_enc, $dc.))  as incomplete_outpt_enc
          , min(put(incomplete_inpt_enc , $dc.))  as incomplete_inpt_enc
          , min(put(incomplete_emr      , $dc.))  as incomplete_emr
          , min(put(incomplete_lab      , $dc.))  as incomplete_lab
          , min(put(incomplete_tumor    , $dc.))  as incomplete_tumor
          , min(put(enrollment_basis    , $eb.))  as enrollment_basis
          , min(put(ins_commercial      , $dc.))  as ins_commercial
          , min(put(ins_highdeductible  , $dc.))  as ins_highdeductible
          , min(put(ins_medicaid        , $dc.))  as ins_medicaid
          , min(put(ins_medicare        , $dc.))  as ins_medicare
          , min(put(ins_medicare_a      , $dc.))  as ins_medicare_a
          , min(put(ins_medicare_b      , $dc.))  as ins_medicare_b
          , min(put(ins_medicare_c      , $dc.))  as ins_medicare_c
          , min(put(ins_medicare_d      , $dc.))  as ins_medicare_d
          , min(put(ins_other           , $dc.))  as ins_other
          , min(put(ins_privatepay      , $dc.))  as ins_privatepay
          , min(put(ins_selffunded      , $dc.))  as ins_selffunded
          , min(put(ins_statesubsidized , $dc.))  as ins_statesubsidized
          , min(put(plan_hmo            , $dc.))  as plan_hmo
          , min(put(plan_indemnity      , $dc.))  as plan_indemnity
          , min(put(plan_pos            , $dc.))  as plan_pos
          , min(put(plan_ppo            , $dc.))  as plan_ppo
          , max((prxmatch("/[^ 0]/", pcc) > 0))   as pcc_probably_valid /* Experimental--GH has all-0 invalid values */
          , max((prxmatch("/[^ 0]/", pcp) > 0))   as pcp_probably_valid /* Experimental--GH has all-0 invalid values */
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
        , put(race1, $race.)              as race length = 10
        , put(hispanic            , $cd.) as hispanic
        , put(needs_interpreter   , $cd.) as needs_interpreter
        , put(drugcov             , $cd.) as drugcov
        , put(incomplete_outpt_rx , $cd.) as incomplete_outpt_rx
        , put(incomplete_outpt_enc, $cd.) as incomplete_outpt_enc
        , put(incomplete_inpt_enc , $cd.) as incomplete_inpt_enc
        , put(incomplete_emr      , $cd.) as incomplete_emr
        , put(incomplete_lab      , $cd.) as incomplete_lab
        , put(incomplete_tumor    , $cd.) as incomplete_tumor
        , enrollment_basis
        , put(ins_commercial      , $cd.) AS ins_commercial
        , put(ins_highdeductible  , $cd.) AS ins_highdeductible
        , put(ins_medicaid        , $cd.) AS ins_medicaid
        , put(ins_medicare        , $cd.) AS ins_medicare
        , put(ins_medicare_a      , $cd.) AS ins_medicare_a
        , put(ins_medicare_b      , $cd.) AS ins_medicare_b
        , put(ins_medicare_c      , $cd.) AS ins_medicare_c
        , put(ins_medicare_d      , $cd.) AS ins_medicare_d
        , put(ins_other           , $cd.) AS ins_other
        , put(ins_privatepay      , $cd.) AS ins_privatepay
        , put(ins_selffunded      , $cd.) AS ins_selffunded
        , put(ins_statesubsidized , $cd.) AS ins_statesubsidized
        , put(plan_hmo            , $cd.) AS plan_hmo
        , put(plan_indemnity      , $cd.) AS plan_indemnity
        , put(plan_pos            , $cd.) AS plan_pos
        , put(plan_ppo            , $cd.) AS plan_ppo
        , put(pcp_probably_valid  , bin.) AS pcp_probably_valid
        , put(pcc_probably_valid  , bin.) AS pcc_probably_valid
        , enrolled_proportion
    from gnu as g LEFT JOIN
         &_vdw_demographic as d
    on   g.mrn = d.mrn
    ;

    drop table gnu ;

    %local vlist ;
    %let vlist = year
            , agegroup
            , gender
            , race
            , hispanic
            , needs_interpreter
            , drugcov
            , incomplete_outpt_rx
            , incomplete_outpt_enc
            , incomplete_inpt_enc
            , incomplete_emr
            , incomplete_lab
            , incomplete_tumor
            , enrollment_basis
            , ins_commercial
            , ins_highdeductible
            , ins_medicaid
            , ins_medicare
            , ins_medicare_a
            , ins_medicare_b
            , ins_medicare_c
            , ins_medicare_d
            , ins_other
            , ins_privatepay
            , ins_selffunded
            , ins_statesubsidized
            , plan_hmo
            , plan_indemnity
            , plan_pos
            , plan_ppo
            , pcp_probably_valid
            , pcc_probably_valid
            ;

    create table &outset as
    select &vlist
        , round(sum(enrolled_proportion), &round_to) as prorated_total format = comma20.2 label = "Pro-rated number of people enrolled in [[year]] (accounts for partial enrollments)"
        , count(mrn)               as total          format = comma20.0 label = "Number of people enrolled at least one day in [[year]]"
    from with_demog
    group by &vlist
    order by &vlist
    ;

    drop table with_demog ;

  quit ;

  proc datasets nolist library = to_stay ;
    modify denoms ;
      label
        year                  = "Year of Enrollment"
        agegroup              = "Age Group"
        gender                = "Gender of Enrollee"
        race                  = "Race of Enrollee"
        hispanic              = "Enrollee is Hispanic?"
        needs_interpreter     = "Enrollee Needs an Interpreter?"
        drugcov               = "Drug Coverage"
        incomplete_outpt_rx   = "Is there a known reason why capture of OUTPATIENT RX FILLS should be incomplete?"
        incomplete_outpt_enc  = "Is there a known reason why capture of OUTPATIENT ENCOUNTERS should be incomplete?"
        incomplete_inpt_enc   = "Is there a known reason why capture of INPATIENT ENCOUNTERS should be incomplete?"
        incomplete_emr        = "Is there a known reason why capture of EMR data should be incomplete?"
        incomplete_lab        = "Is there a known reason why capture of LAB RESULTS should be incomplete?"
        incomplete_tumor      = "Is there a known reason why capture of TUMOR DATA should be incomplete?"
        enrollment_basis      = "What is the reason this person is in the enrollment file?"
        ins_commercial        = "Has commercial insurance?"
        ins_highdeductible    = "Has high-deductible insurance?"
        ins_medicaid          = "Has medicaid coverage?"
        ins_medicare          = "Has any type of medicare insurance?"
        ins_medicare_a        = "Has medicare part A insurance?"
        ins_medicare_b        = "Has medicare part B insurance?"
        ins_medicare_c        = "Has medicare part C insurance?"
        ins_medicare_d        = "Has medicare part D insurance?"
        ins_other             = "Has 'other' insurance?"
        ins_privatepay        = "Has private pay insurance?"
        ins_selffunded        = "Has self-funded insurance?"
        ins_statesubsidized   = "Has state-subsizided insurance?"
        plan_hmo              = "Has HMO plan coverage?"
        plan_indemnity        = "Has Indemnity coverage?"
        plan_pos              = "Has Point-of-Service coverage?"
        plan_ppo              = "Has Preferred-Provider-Organization coverage?"
        pcp_probably_valid    = "Has a valid Primary Care Physician assignment?"
        pcc_probably_valid    = "Has a valid Primary Care Clinic assignment?"
      ;
  quit ;

%mend make_denoms ;


%macro enroll_tier_one_point_five(inset = to_stay.denoms, outset = to_go.&_siteabbr._enroll_freqs) ;

  %removedset(dset = &outset) ;

  data &outset ;
    length
      year 4
      var_name $ 20
      value $ 20
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
      pcp_probably_valid
      pcc_probably_valid
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
      incomplete_outpt_rx
      incomplete_outpt_enc
      incomplete_inpt_enc
      incomplete_emr
      incomplete_tumor
      incomplete_lab
      plan_hmo
      plan_indemnity
      plan_pos
      plan_ppo
      agegroup
      gender
      race
      hispanic
      needs_interpreter
    ;

  %local this_var ;
  %local i ;
  %let i = 1 ;
  %let this_var = %scan(&vlist, &i) ;

  %do %until(&this_var = ) ;
    proc freq data = &inset order = formatted ;
      tables &this_var * year / missing format = msk. out = gnu plots = none ;
      weight prorated_total ;
      format &this_var ;
    run ;

    * EXPERIMENTAL!   ;
    %if &sysver ge 9.1 and %sysprod(graph) = 1 and &skip_graphs = false %then %do ;

      * Put this line before opening any ODS destinations. ;
      options orientation = landscape ;
      ods graphics / height = 6in width = 10in ;

      proc sgplot data = gnu ;
        loess x = year y = count / group = &this_var lineattrs = (thickness = .1 CM pattern = solid) smooth = .5 ;
        format count comma10.0 ;
        xaxis grid values=(&start_year to &end_year by 1) ;
        yaxis grid ;
      run ;
    %end ;

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
      value $ 20
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
      tables &this_var * gender / missing format = msk. out = gnu plots = none ;
      format &this_var ;
    run ;

    * EXPERIMENTAL!   ;
    %if &sysver ge 9.1 and %sysprod(graph) = 1 and &skip_graphs = false %then %do ;

      * Put this line before opening any ODS destinations. ;
      options orientation = landscape ;
      ods graphics / height = 6in width = 10in ;

      proc sgplot data = gnu ;
        vbar &this_var / response = count group = gender stat = sum ;
        format count comma10.0 ;
        xaxis grid ;
        yaxis grid ;
      run ;
    %end ;

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

%macro draw_heatmap(corrset = to_go.&_siteabbr._flagcorr) ;
  %if &sysver ge 9.1 and %sysprod(graph) = 1 and &skip_graphs = false %then %do ;
    ods path(prepend) work.templat(update);
    proc template;
      define statgraph corrHeatmap;
       dynamic _Title;
        begingraph;
          entrytitle _Title;
          rangeattrmap name='map';
          /* select a series of colors that represent a "diverging"  */
          /* range of values: stronger on the ends, weaker in middle */
          /* Get ideas from http://colorbrewer.org                   */
          range -1 - 1 / rangecolormodel=(cx483D8B  cxFFFFFF cxDC143C);
          endrangeattrmap;
          rangeattrvar var=r attrvar=r attrmap='map';
          layout overlay /
            xaxisopts=(display=(line ticks tickvalues))
            yaxisopts=(display=(line ticks tickvalues));
            heatmapparm x = x y = y colorresponse = r /
              xbinaxis=false ybinaxis=false
              name = "heatmap" display=all;
            continuouslegend "heatmap" /
              orient = vertical location = outside title="Pearson Correlation";
          endlayout;
        endgraph;
      end;
    run;
    proc sgrender data=&corrset template=corrHeatmap;
      dynamic _title="Relationship Between Insurance/Plan Flags: &_SiteName";
    run;
  %end ;
%mend draw_heatmap ;

%macro do_all_rates ;

  %get_rates(startyr  = &start_year
            , endyr   = &end_year
            , inset   = &_vdw_tumor
            , datevar = dxdate
            , incvar  = incomplete_tumor
            , outset  = to_go.&_siteabbr._tumor_rates
            , outunenr = to_go.&_siteabbr._tum_unenrolled
            ) ;

  %get_rates(startyr    = &start_year
            , endyr     = &end_year
            , inset     = &_vdw_utilization
            , datevar   = adate
            , incvar    = incomplete_inpt_enc
            , outset    = to_go.&_siteabbr._ute_in_rates_by_enctype
            , extra_var = coalesce(enctype, 'XX')
            ) ;

  %get_rates(startyr     = &start_year
            , endyr      = &end_year
            , inset      = &_vdw_lab
            , datevar    = lab_dt
            , incvar     = incomplete_lab
            , outset     = to_go.&_siteabbr._lab_rates
            , outunenr = to_go.&_siteabbr._lab_unenrolled
            ) ;

  %get_rates(startyr    = &start_year
            , endyr     = &end_year
            , inset     = &_vdw_utilization
            , datevar   = adate
            , incvar    = incomplete_outpt_enc
            , outset    = to_go.&_siteabbr._ute_out_rates_by_enctype
            , extra_var = coalesce(enctype, 'XX')
            , outunenr = to_go.&_siteabbr._enc_unenrolled
            ) ;
  %get_rates(startyr  = &start_year
            , endyr   = &end_year
            , inset   = &_vdw_vitalsigns
            /* , extrawh = %str(AND dsource = 'P') */
            , datevar = measure_date
            , incvar  = incomplete_emr
            , outset  = to_go.&_siteabbr._emr_v_rates
            , outunenr = to_go.&_siteabbr._vsn_unenrolled
            ) ;

  %get_rates(startyr  = &start_year
            , endyr   = &end_year
            , inset   = &_vdw_social_hx
            /* , extrawh = %str(AND gh_source = 'C') */
            , datevar = contact_date
            , incvar  = incomplete_emr
            , outset  = to_go.&_siteabbr._emr_s_rates
            , outunenr = to_go.&_siteabbr._shx_unenrolled
            ) ;

  %get_rates(startyr  = &start_year
            , endyr   = &end_year
            , inset   = &_vdw_rx
            , datevar = rxdate
            , incvar  = incomplete_outpt_rx
            , outset  = to_go.&_siteabbr._rx_rates
            , outunenr = to_go.&_siteabbr._rx_unenrolled
            ) ;
%mend do_all_rates ;

/*
*/

%check_vars ;
%demog_tier_one ;
%lang_tier_one; *pjh19401;
%enroll_tier_one ;
%make_denoms ;

data to_stay.demog_checks ;
  set demog_checks ;
run ;

data to_stay.erbr_checks ;
  set erbr_checks ;
run ;
data to_go.&_siteabbr._tier_one_results ;
  set results ;
run ;

%do_all_rates ;

options orientation = landscape ;
ods graphics / height = 6in width = 10in ;

ods html path   = "%sysfunc(pathname(to_go))" (URL=NONE)
         gpath  = "%sysfunc(pathname(to_stay))"
         body   = "&_siteabbr._vdw_enroll_demog_qa.html"
         (title = "&_SiteName.: QA for Enroll/Demographics - Tier 1 & 1.5")
         style  = magnify
         nogfootnote
          ;


ods rtf file = "%sysfunc(pathname(to_stay))/&_siteabbr._vdw_enroll_demog_qa.rtf"
        device = sasemf
        style = magnify
        ;

  title1 "&_SiteName.: QA for Enroll/Demographics" ;
  title2 "Tier One Checks" ;
  proc sql number ;
    select * from to_go.&_siteabbr._tier_one_results ;
  quit ;

  title2 "Tier 1.5 Checks" ;
  %enroll_tier_one_point_five(outset = to_go.&_siteabbr._enroll_freqs) ;
  %demog_tier_one_point_five(outset = to_go.&_siteabbr._demog_freqs) ;
  %draw_heatmap ;

  title2 "Completeness of VDW Data for &_SiteName" ;
  %graph_capture(rateset = to_go.&_siteabbr._rx_rates
                , incvar = incomplete_outpt_rx
                , ylab = Pharmacy Fills
                ) ;

  %graph_capture(rateset = to_go.&_siteabbr._ute_out_rates_by_enctype (where = (extra = 'AV'))
                , incvar = incomplete_outpt_enc
                , ylab = Outpatient Encounters
                ) ;
  %graph_capture(rateset = to_go.&_siteabbr._ute_in_rates_by_enctype (where = (extra = 'IP'))
                , incvar = incomplete_inpt_enc
                , ylab = Inpatient Encounters
                ) ;

  %panel_ute(rateset = to_go.&_siteabbr._ute_out_rates_by_enctype (where = (extra in ('AV', 'EM', 'TE')))
              , incvar = incomplete_outpt_enc, rows = 1, cols = 3) ;

  %panel_ute(rateset = to_go.&_siteabbr._ute_out_rates_by_enctype (where = (extra in ('ED', 'IP', 'IS')))
              , incvar = incomplete_outpt_enc, rows = 1, cols = 3) ;

  %panel_ute(rateset = to_go.&_siteabbr._ute_out_rates_by_enctype (where = (extra in ('LO', 'RO', 'OE')))
              , incvar = incomplete_outpt_enc, rows = 1, cols = 3) ;

  %graph_capture(incvar  = incomplete_tumor
                , rateset  = to_go.&_siteabbr._tumor_rates
                , ylab = Tumor Registry
                ) ;
  %graph_capture(incvar  = incomplete_lab
                , rateset  = to_go.&_siteabbr._lab_rates
                , ylab = Lab Results
                ) ;
  %graph_capture(incvar  = incomplete_emr
                , rateset  = to_go.&_siteabbr._emr_s_rates
                , ylab = EMR Data (Social History)
                ) ;
  %graph_capture(incvar  = incomplete_emr
                , rateset  = to_go.&_siteabbr._emr_v_rates
                , ylab = EMR Data (Vital Signs)
                ) ;

  title2 "Counts of Data Events for people not appearing in the Enrollment Table" ;

  %graph_unenrolled(inset = to_go.&_siteabbr._rx_unenrolled , ylab = %str(Pharmacy fills)) ;
  %graph_unenrolled(inset = to_go.&_siteabbr._enc_unenrolled, ylab = %str(Encounters)) ;
  %graph_unenrolled(inset = to_go.&_siteabbr._lab_unenrolled, ylab = %str(Lab Results)) ;
  %graph_unenrolled(inset = to_go.&_siteabbr._tum_unenrolled, ylab = %str(Tumors)) ;
  %graph_unenrolled(inset = to_go.&_siteabbr._vsn_unenrolled, ylab = %str(Vital Signs)) ;
  %graph_unenrolled(inset = to_go.&_siteabbr._shx_unenrolled, ylab = %str(Social History)) ;

run ;

ods _all_ close ;

