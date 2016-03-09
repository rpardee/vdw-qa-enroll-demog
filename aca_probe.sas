/*********************************************
* Roy Pardee
* Group Health Research Institute
* (206) 287-2078
* pardee.r@ghc.org
*
* C:\Users/pardre1/Documents/vdw/Enrollment/supporting_files/aca_probe.sas
*
* What do the enrollment #s look like across the 1-jan-2014 Affordable Care Act seam?
*********************************************/

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

* Output lib--change this to something that works at your site ;
libname s "//ghrisas/SASUser/pardre1" ;

* Put your stdvars ref here: ;
%include "//ghrisas/Warehouse/Sasdata/CRN_VDW/lib/StdVars_Teradata.sas" ;

%macro probe_diffs(outset = s.combos) ;

/*

  Want to know:

  • The number of entirely new enrollees in January (how many privatepay, Medicaid, commercial, etc.?)  Presumably new privatepay & medicaid people would be ACA enrollees (enrolled b/c of the mandate, whether exchange-mediated or not).
  • The number of enrollees who dropped out in January.  This group would be a combination of ‘ACA losers’ (for want of a better term) and people who switched carriers b/c of pricing or perceived better value elsewhere.
  • The number of people whose coverages changed (e.g., went from privatepay to Medicaid).
  • The number of people whose coverages did not seem to change.

  In order to answer these questions we make a simplifying assumption--that we
  can meaningfully reduce the information in our suite of insurance flags down
  to a single value by imposing the hierarchy expressed in the call to
  whichc() below on line 78. That call says basically, "look through the
  insurance type flags in this order, and set insurance type = the first one
  you find that's set to 'Y'". So if someone has 'Private Pay' and anything
  else (or nothing else) we call them private pay. If someone as medicaid, and
  anything else (or nothing else) we call them medicaid, and so forth.

  The hierarchy chosen is given in the call to whichc, and the corresponding
  format on line 61. I feel decent about favoring private pay and medicaid
  because those are the two types I expect to be affected the most by the ACA.
  The rest are entirely arbitrary. So--no representation that this hierarchy
  is a good one for any particular purpose. We have multiple flags for a
  reason--so we can set as many as needed to properly characterize the
  enrollment.

*/

  %macro get_mo(anchor_date, outset) ;
    proc format ;
      value it
        0 = 'Type Not Specified'
        1 = 'Private Pay'
        2 = 'Medicaid'
        3 = 'Commercial'
        4 = 'Medicare'
        5 = 'Self Funded'
        6 = 'State Subsidized'
        7 = 'High Deductible'
        . = 'Not Enrolled'
      ;
    quit ;


    data &outset ;
      length ins_type 3 ;
      set &_vdw_enroll (keep = mrn enr_: ins_:) ;
      where "&anchor_date"d between enr_start and enr_end ;
      ins_type = whichc('Y', ins_privatepay, ins_medicaid, ins_commercial, ins_medicare, ins_selffunded, ins_statesubsidized, ins_highdeductible) ;
      * Added this in as a diagnostic b/c we wound up w/almost no medicare--use or ignore at your pleasure. ;
      spark = "_______" ;
      if ins_privatepay       = 'Y' then substr(spark, 1, 1) = 'P' ;
      if ins_medicaid         = 'Y' then substr(spark, 2, 1) = 'D' ;
      if ins_commercial       = 'Y' then substr(spark, 3, 1) = 'C' ;
      if ins_medicare         = 'Y' then substr(spark, 4, 1) = 'R' ;
      if ins_selffunded       = 'Y' then substr(spark, 5, 1) = 'S' ;
      if ins_statesubsidized  = 'Y' then substr(spark, 6, 1) = 'B' ;
      if ins_highdeductible   = 'Y' then substr(spark, 7, 1) = 'H' ;
      &outset._combos = spark ;
      label
        &outset._combos = "[P]rivatepay Medicai[D] [C]ommercial Medica[R]e [S]elffunded Statesu[B]sidized [H]ighdeductible"
      ;
      keep mrn ins_type &outset._combos ;
    run ;

    * There should be no dupes here, but JIC. ;
    proc sort nodupkey data = &outset ;
      by mrn ;
    run ;

  %mend get_mo ;

  %get_mo(15-dec-2014, dec_2014) ;
  %get_mo(15-jan-2015, jan_2015) ;

  data &outset ;
    merge
      dec_2014 (rename = (ins_type = type_2014))
      jan_2015 (rename = (ins_type = type_2015))
    ;
    by mrn ;
    label
      type_2014 = "Insurance Type in December 2014"
      type_2015 = "Insurance Type in January 2015"
    ;
  run ;

  proc freq data = &outset ;
    tables type_2014 * type_2015 / missing format = comma9.0 out = s.drop_me ;
    format type_: it. ;
    * where not (type_2013 = 4 or type_2014 = 4) ;
  run ;

  * proc freq data = &outset order = freq ;
  *   tables jan_2014_combos * type_2014 / list missing format = comma9.0 ;
  *   format type_: it. ;
  * run ;

%mend probe_diffs ;

%probe_diffs(outset = aca_diffs) ;

options mprint ;
/*
%aca_denoms(to_date = 30-aug-2014) ;
%plot_denoms ;
 */