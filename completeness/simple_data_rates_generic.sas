/*********************************************
* Roy Pardee
* Group Health Research Institute
* (206) 287-2078
* pardee.r@ghc.org
*
* //groups/data/CTRHS/Crn/voc/enrollment/programs/simple_data_rates.sas
*
* Computes rates-over-time of various types of utilization by the new/proposed incompleteness flags.
*********************************************/

* ============== BEGIN EDIT SECTION ========================= ;
* Please comment this include statement out if Roy forgets to--thanks/sorry! ;
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

* Please change this to point to your local copy of StdVars.sas ;
%include "&GHRIDW_ROOT/Sasdata/CRN_VDW/lib/StdVars_Teradata.sas" ;

* Where you want the output datasets and output. ;
libname out "\\ghrisas\SASUser\pardre1\vdw\enroll" ;

* Years over which you want rate data ;
%let start_year = 2000 ;
%let end_year   = 2014 ; * <-- best to use last complete year ;

libname td_tmp teradata
  user              = "&clean_username@LDAP"
  password          = "&password"
  server            = "EDW_PROD1"
  schema            = "%sysget(username)"
  multi_datasrc_opt = in_clause
  connection        = global
;


* ============== END EDIT SECTION ========================= ;

proc format ;
  value $inc
    "K" = "Suspected Incomplete"
    "N" = "Not Suspected Incomplete"
    "X" = "Not Implemented"
  other = "Unknown"
  ;
quit ;

%macro gen_months(startyr = 2000, endyr = 2014, outset = months) ;
  %* Utility macro--just spits out a dset of months. ;
  data &outset ;
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
%mend gen_months ;

%macro get_rates(startyr =
              , endyr     =
              , inset     =               /* the substantive dset that holds the type of data whose capture is described in incvar */
              , datevar   =               /* name of the relevant date var (adate, rxdate, etc.) */
              , incvar    =               /* name of the incomplete_* var we are testing. */
              , outset    =               /* what to call the output dataset of rates. */
              , extra_var = %str((1 = 1)) /* additional var to break rates out by--say, enctype for ute. */
              , enrlset   = &_vdw_enroll  /* Whats our source for start/stop periods? */
              , startvar  = enr_start     /* name of the var signifying periodstarts in the enrlset data. */
              , endvar    = enr_end       /* name of the var signifying period ends in the enrlset data. */
              ) ;
  * Creates counts of enrollees by the various completeness flags, plus median age, for every month in the time period indicated. ;
  %gen_months(startyr = &startyr, endyr = &endyr, outset = td_tmp.inflate_months) ;
  proc sql ;
    create table raw as
    select i.first_day length = 4
          , e.mrn
          , e.&incvar
          , &extra_var   as extra length = 3
          , count(r.mrn) as num_events length = 4
      from  td_tmp.inflate_months as i LEFT JOIN
            &enrlset as e
      on    e.&startvar le i.last_day AND
            e.&endvar   ge i.first_day LEFT JOIN
            &inset as r
      on    e.mrn = r.mrn AND
            r.&datevar between i.first_day and i.last_day
      group by 1, 2, 3, 4
      ;
  quit ;

  proc summary nway data = raw ;
    class first_day &incvar extra ;
    var num_events ;
    output out = summarized (drop = _type_ rename = (_freq_ = n))
                sum(num_events)    = num_events
                ;
  run ;

  * Correct Ns for runs where we have a substantive "extra" var. ;
  * There is probably a fancy-pants way of doing this w/in the SUMMARY call above, but I dont ;
  * have time to play with it ;
  proc sql ;
    drop table raw ;
    create table true_ns as
    select first_day, &incvar, sum(n) as n
    from summarized
    group by first_day, &incvar
    ;
    create table &outset as
    select s.*, t.n
    from  summarized (drop = n)  as s INNER JOIN
          true_ns as t
    on    s.first_day = t.first_day AND
          s.&incvar = t.&incvar
    ;
  quit ;

  data &outset ;
    length &incvar $ 30 ;
    set &outset ;
    if n then rate = num_events / n ;
    &incvar = put(&incvar, $inc.) ;
    format
      n num_events comma10.0
      &incvar $30.
    ;
  run ;
%mend get_rates ;

* TESTING--REMOVE THIS ROY!!! ;
* options obs = 20000 ;

/*
%get_rates(startyr  = &start_year
          , endyr   = &end_year
          , inset   = &_vdw_rx
          , datevar = rxdate
          , incvar  = incomplete_outpt_rx
          , outset  = out.rx_rates) ;

%get_rates(startyr  = &start_year
          , endyr   = &end_year
          , inset   = &_vdw_tumor
          , datevar = dxdate
          , incvar  = incomplete_tumor
          , outset  = out.tumor_rates
          ) ;

%get_rates(startyr  = &start_year
          , endyr   = &end_year
          , inset   = &_vdw_utilization
          , datevar = adate
          , incvar  = incomplete_outpt_enc
          , outset  = out.ute_rates_by_enctype
          , extra_var  = coalesce(enctype, 'XX')
          ) ;
*/

%get_rates(startyr  = &start_year
          , endyr   = &end_year
          , inset   = &_vdw_social_hx
          , datevar = contact_date
          , incvar  = incomplete_emr
          , outset  = out.social_rates
          ) ;

* %get_rates(startyr     = &start_year
          , endyr      = &end_year
          , inset      = &_vdw_lab
          , datevar    = lab_dt
          , incvar     = incomplete_lab
          , outset     = out.lab_rates
          ) ;



