/*********************************************
* Roy Pardee
* Group Health Research Institute
* (206) 287-2078
* pardee.r@ghc.org
*
* //groups/data/CTRHS/Crn/voc/enrollment/programs/simple_data_rates.sas
*
* Computes rates-over-time of various types of utilization by the new/proposed
* incompleteness flags.
*********************************************/
proc format ;
  value $inc
    "K" = "Suspected Incomplete"
    "N" = "Not Suspected Incomplete"
    "X" = "Not Implemented"
    "?" = "no dataset"
  other = "Unknown"
  ;
quit ;

%macro gen_months(startyr = 2000, endyr = 2014, outset = months) ;
  %* Utility macro--just spits out a dset of months. ;
  data __mos ;
    do yr = &startyr to &endyr ;
      do mo = 1 to 12 ;
        first_day = mdy(mo, 1, yr) ;
        last_day = intnx('month', first_day, 0, 'end') ;
        if first_day le "&sysdate"d then  output ;
      end ;
    end ;
    format
      first_day
      last_day mmddyy10.
    ;
  run ;
  data &outset ;
    set __mos ;
  run ;
%mend gen_months ;

%macro get_rates(startyr =
              , endyr     =
              , inset     =               /* the substantive dset that holds the type of data whose capture is described in incvar */
              , extrawh   =               /* any extra WHERE you want to add to the main query */
              , datevar   =               /* name of the relevant date var (adate, rxdate, etc.) */
              , incvar    =               /* name of the incomplete_* var we are testing. */
              , outset    =               /* what to call the output dataset of rates. */
              , extra_var = 'XX'          /* name of additional var to break rates out by--say, enctype for ute. */
              , enrlset   = &_vdw_enroll  /* Whats our source for start/stop periods? */
              , startvar  = enr_start     /* name of the var signifying periodstarts in the enrlset data. */
              , endvar    = enr_end       /* name of the var signifying period ends in the enrlset data. */
              , outunenr  =               /* optional name of a dset to hold an output dset of record counts of events for unenrolled ppl */
              ) ;
  * Creates counts of enrollees by the various completeness flags, plus median age, for every month in the time period indicated. ;

  %removedset(dset = &tmplib..inflate_months) ;
  %gen_months(startyr = &startyr, endyr = &endyr, outset = &tmplib..inflate_months) ;

  * If the inset dataset does not exist, create a null output dset and go home ;
  %if %sysfunc(exist(&inset)) OR %sysfunc(exist(&inset,VIEW)) %then %do ;
    %* nothing ;
  %end ;
  %else %do ;
    data &outset ;
      set &tmplib..inflate_months ;
      &incvar = '?' ;
      extra = -1 ;
      n = 0 ;
      num_events = 0 ;
      rate = . ;
      drop yr mo last_day ;
    run ;
    %do i = 1 %to 10 ;
      %put DIG IT: NO SUCH DATASET AS &INSET--CREATING A NULL OUTPUT DSET!!! ;
    %end ;
    %if %length(&outunenr) > 0 %then %do ;
      data &outunenr ;
        set &tmplib..inflate_months ;
        n_unenrolled = . ;
        n_total = . ;
        proportion_unenrolled = . ;
        drop yr mo last_day ;
      run ;
    %end ;
    %goto finish ;
  %end ;

  proc sql ;
    create table summarized as
    select i.first_day length = 4
          , e.&incvar
          , &extra_var   as extra
          , count(distinct e.mrn) as n
          , sum(case when r.mrn is null then 0 else 1 end) as num_events
    from  &tmplib..inflate_months as i LEFT JOIN
          &enrlset as e
    on    e.&startvar le i.last_day AND
          e.&endvar   ge i.first_day LEFT JOIN
          &inset as r
    on    e.mrn = r.mrn AND
          r.&datevar between i.first_day and i.last_day
    &extrawh
    group by 1, 2, 3
    ;

    %if %length(&outunenr) > 0 %then %do ;
      create table &outunenr as
      select m.first_day
          , sum(case when e.mrn is null then 1 else 0 end) as n_unenrolled format = comma9.0 label = "No. events for people not appearing in enrollment"
          , COUNT(r.mrn) as n_total format = comma9.0 label = "Total number of events in this month"
          , calculated n_unenrolled / calculated n_total as proportion_unenrolled label = "Proportion of events by unenrolled"
      from &inset as r INNER JOIN
           &tmplib..inflate_months as m
      on   r.&datevar between m.first_day and m.last_day LEFT JOIN
           &enrlset as e
      on   r.mrn = e.mrn AND
           r.&datevar between e.&startvar and e.&endvar
      group by m.first_day
      order by 1
      ;
    %end ;
  %if %length(&extra_var) < 3 %then %do ;
    create table &outset as
    select *
    from summarized
    ;
  %end ;
  %else %do ;
    create table true_denoms as
    select i.first_day length = 4
          , e.&incvar
          , count(distinct e.mrn) as n
    from  &tmplib..inflate_months as i LEFT JOIN
          &enrlset as e
    on    e.&startvar le i.last_day AND
          e.&endvar   ge i.first_day
    group by 1, 2
    ;
    create table &outset as
    select s.*, t.n
    from  summarized (drop = n)  as s INNER JOIN
          true_denoms as t
    on    s.first_day = t.first_day AND
          s.&incvar = t.&incvar
    ;
  %end ;
  quit ;

  %removedset(dset = &tmplib..inflate_months) ;

  /*
    THIS DOES NOT WORK PROPERLY.
    Enrollees that have > 1 type of visit in a month get counted several times
    in the denominator, suppressing the rates.
    So really, we should do one pass of nothing but denom counts
    and one pass of nothing but event counts for anything with a substantive
    "extra" var.
    * Correct Ns for runs where we have a substantive "extra" var. ;
    proc sql ;
      create table true_ns as
      select first_day, &incvar, sum(n) as n
      from summarized
      group by first_day, &incvar
      ;
    quit ;
  */


%finish:

  data &outset ;
    length &incvar $ 30 ;
    set &outset ;
    if n then rate = num_events / n ;
    &incvar = put(&incvar, $inc.) ;
    * Censor any lower-than-permitted counts. ;
    if n          and n          le &lowest_count then n          = .a ;
    if num_events and num_events le &lowest_count then num_events = .a ;
    format
      n num_events comma10.0
      &incvar $30.
    ;
  run ;

  proc sort data = &outset ;
    by first_day extra &incvar ;
  run ;

%mend get_rates ;

