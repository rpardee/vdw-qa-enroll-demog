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

* ============== BEGIN EDIT SECTION ========================= ;
* Please comment this include statement out if Roy forgets to--thanks/sorry! ;
%include "h:/SAS/Scripts/remoteactivate.sas" ;
options
  linesize  = 150
  msglevel  = i
  formchar  = '|-++++++++++=|-/|<>*'
  nocenter
  noovp
  nosqlremerge
  options extendobscounter = no ;
  /* dsoptions   = note2err */
  /* sastrace    = ',,,d' */
  /* sastraceloc = saslog */
;

* Please change this to point to your local copy of StdVars.sas ;
%include "&GHRIDW_ROOT/Sasdata/CRN_VDW/lib/StdVars_Teradata.sas" ;

* Please change this to the location where you unzipped this package. ;
%let root = \\groups\data\CTRHS\Crn\voc\enrollment\programs\completeness ;

* Years over which you want rate data ;
%let start_year = 2010 ;
%let end_year   = 2018 ; * <-- best to use last complete year ;

/*

  If your VDW files are not in an rdbms you can ignore the rest of this edit
  section. If they are & you want to possibly save a ton of processing time,
  please read on.

  The bulk of the work of this program is done in a SQL join between VDW
  enrollment, a substantive VDW file (like rx or tumor), and a small utility
  dataset of the months between &start_year and &end_year.

  If you have the wherewithal to create this utility dataset on the db server
  where the rest of your VDW tables live, then SAS will (probably) pass the
  join work off to the db to complete, which is orders of magnitude faster
  than having SAS pull your tables into temp datasets & do the join on the SAS
  side. At Group Health (we use Teradata) making this change turned a job that
  ran in about 14 hours into one that runs in 15 *minutes*.

  TO DO SO, create a libname pointing at a db on the same server as VDW, to
  which you have CREATE TABLE permissions.  You can see what I used at GH
  commented-out, below.  I *believe* the 'connection = global' bit is necessary
  to get the join pushed to the db, and that it works for rdbms' other than
  Teradata, but am not positive.  I'd love to hear your experience if anybody
  tries this out.
*/

%let td_gew = user              = "&nuid@LDAP"
              password          = "&cspassword"
              server            = "&td_prod"
              schema            = "&nuid"
              connection        = global
;

libname mylib teradata
  &td_gew
  multi_datasrc_opt = in_clause
;

* %let tmplib = work ;
%let tmplib = mylib ;

* ============== END EDIT SECTION ========================= ;
* Where you want the output datasets. ;
libname out "&root./to_send" ;

* Bring VDW standard macros into the session. ;
%include vdw_macs ;

proc format ;
  value $inc
    "K" = "Suspected Incomplete"
    "N" = "Not Suspected Incomplete"
    "X" = "Not Implemented"
    "M" = "Molina"
    "G" = "GH Medicaid"
  other = "Unknown"
  ;
  value iw
    0 = 'East'
    1 = 'West'
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
              , extrawh   =               /* any extra WHERE you want to add to the main query */
              , datevar   =               /* name of the relevant date var (adate, rxdate, etc.) */
              , incvar    =               /* name of the incomplete_* var we are testing. */
              , outset    =               /* what to call the output dataset of rates. */
              , extra_var = -1            /* name of additional var to break rates out by--say, enctype for ute. */
              , enrlset   = &_vdw_enroll  /* Whats our source for start/stop periods? */
              , startvar  = enr_start     /* name of the var signifying periodstarts in the enrlset data. */
              , endvar    = enr_end       /* name of the var signifying period ends in the enrlset data. */
              ) ;
  * Creates counts of enrollees by the various completeness flags, plus median age, for every month in the time period indicated. ;
  * %removedset(dset = &tmplib..inflate_months) ;
  * %gen_months(startyr = &startyr, endyr = &endyr, outset = &tmplib..inflate_months) ;
  proc sql ;
    connect to teradata as td (&td_gew) ;

    create table summarized as
    select *
    from connection to td
    (


      with enroll as
      (
      select i.first_day
          , i.last_day
          , e.mrn
          , IsWest
          , case when gpdconfidence ge .7 then 'Group Practice' else 'Contracted' end as division
          , d.birth_date
          , extract(year from i.first_day) - EXTRACT(year from d.birth_date) as rough_age
      from o578092.inflate_months as i INNER JOIN
           sb_ghri.enroll as e
      on   i.first_day between e.enr_start and e.enr_end INNER JOIN
           sb_ghri.demog as d
      on   e.mrn = d.mrn
      )


      select first_day, IsWest, division, COUNT(distinct e.mrn) as n_enrollees, SUM(case when l.mrn is null then 0 else 1 end) as n_lab_results
      from enroll as e LEFT JOIN
           sb_ghri.lab_results as l
      on   e.mrn = l.mrn
           AND l.lab_dt between e.first_day and e.last_day
      where rough_age >= 65
      group by 1, 2, 3
      order by 1, 2, 3



    )
    ;

  quit ;


  * %removedset(dset = &tmplib..inflate_months) ;

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

  data &outset ;
    length region $ 30 ;
    set summarized ;
    if n_enrollees then rate = n_lab_results / n_enrollees ;
    * if n_over_65 then rate_over_65 = num_events / n_over_65 ;

    region = put(&incvar, iw.) ;
    format
      n_enrollees n_lab_results comma10.0
      region $30.
    ;
  run ;

  proc sort data = &outset ;
    by first_day division region ;
  run ;

%mend get_rates ;

options mprint ;

  * %removedset(dset = &tmplib..inflate_months) ;
  * %gen_months(startyr = &start_year, endyr = &end_year, outset = &tmplib..inflate_months) ;


%get_rates(startyr   = &start_year
          , endyr      = &end_year
          , inset      = &_vdw_lab
          , datevar    = lab_dt
          , incvar     = iswest
          , extra_var  = case when gpdconfidence ge .7 then 'Group Practice' else 'Contracted' end as division
          , outset     = out.&_siteabbr._lab_rates_ew_old
          ) ;

endsas ;

/*

%get_rates(startyr  = &start_year
          , endyr   = &end_year
          , inset   = &_vdw_tumor
          , datevar = dxdate
          , incvar  = incomplete_tumor
          , outset  = out.&_siteabbr._tumor_rates
          ) ;

%get_rates(startyr  = &start_year
          , endyr   = &end_year
          , inset   = &_vdw_vitalsigns
          , extrawh = %str(AND dsource = 'P')
          , datevar = measure_date
          , incvar  = incomplete_emr
          , outset  = out.&_siteabbr._emr_v_rates
          ) ;
%get_rates(startyr  = &start_year
          , endyr   = &end_year
          , inset   = &_vdw_social_hx
          , extrawh = %str(AND kpwa_source = 'C')
          , datevar = contact_date
          , incvar  = incomplete_emr
          , outset  = out.&_siteabbr._emr_s_rates
          ) ;

%get_rates(startyr  = &start_year
          , endyr   = &end_year
          , inset   = &_vdw_rx
          , datevar = rxdate
          , incvar  = incomplete_outpt_rx
          , outset  = out.&_siteabbr._rx_rates
          ) ;
 */
%get_rates(startyr    = &start_year
          , endyr     = &end_year
          , inset     = &_vdw_utilization
          , datevar   = adate
          , incvar    = incomplete_inpt_enc
          , outset    = out.&_siteabbr._ute_in_rates_by_enctype
          , extra_var = coalesce(enctype, 'XX')
          ) ;

%get_rates(startyr    = &start_year
          , endyr     = &end_year
          , inset     = &_vdw_utilization
          , datevar   = adate
          , incvar    = incomplete_outpt_enc
          , outset    = out.&_siteabbr._ute_out_rates_by_enctype
          , extra_var = coalesce(enctype, 'XX')
          ) ;
