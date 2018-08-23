/*********************************************
* Roy Pardee
* Group Health Research Institute
* (206) 287-2078
* pardee.r@ghc.org
*
* //groups/data/CTRHS/Crn/voc/enrollment/programs/deleteme.sas
*
* PORTAL insurance type counts.
*********************************************/

%include "h:/SAS/Scripts/remoteactivate.sas" ;

options
  linesize  = 150
  pagesize  = 80
  msglevel  = i
  formchar  = '|-++++++++++=|-/|<>*'
  dsoptions = note2err
  nocenter
  noovp
  nosqlremerge
  extendobscounter = no
;

%include "&GHRIDW_ROOT/Sasdata/CRN_VDW/lib/StdVars.sas" ;

/* data periods ;
  input
    @1    mrn         $char3.
    @7   enr_start   date9.
    @17   enr_end   date9.
  ;
  rid = _n_ ;
  format enr_: mmddyy10. ;
datalines ;
roy   01jan1988 30jun1990
roy   01jul1990 31oct1990
roy   10sep1990 15aug2018
run ;
 */

data periods ;
  set &_vdw_enroll ;
  where mrn in ('2549PS9FBC', '2A27PUKUFX', '2BA3SBSSKK', '2HJXZHXZU7', '2J2SGGTSMP', '2WX2ALXEK5', '2XS1K1Q1YU', '30ZKUKB64S') ;
  rid = _n_ ;
  enr_start = intnx('month', enr_start, -4) ;
  * enr_end = intnx('month', enr_end, 4) ;
  randy = uniform(90) ;
  format enr_: mmddyy10. ;
  keep mrn enr_: rid randy ;
run ;

data s.periods ;
  set periods;
run ;

proc sort data = periods ;
  by randy ;
run ;

proc sql ;
    * Check for overlapping periods. ;
  create table s.overlapping_periods as
  select
        p1.mrn
      , p1.enr_start as start1
      , p1.enr_end   as end1
      , p2.enr_start as start2
      , p2.enr_end   as end2
      , intck('day', p1.enr_start, p2.enr_end) as cand1 /* which of these is correct depends on sort order--take the min below. */
      , intck('day', p2.enr_start, p1.enr_end) as cand2 /* which of these is correct depends on sort order--take the min below. */
      , (p1.enr_start lt p2.enr_end AND
         p1.enr_end   gt p2.enr_start) as overlap
  from  periods as p1 INNER JOIN
        periods as p2
  on    p1.mrn = p2.mrn
  where (p1.rid gt p2.rid)
        AND (p1.enr_start lt p2.enr_end AND p1.enr_end gt p2.enr_start)
  ;

quit ;

data s.overlapping_periods ;
  set s.overlapping_periods ;
  years_overlap = min(cand1, cand2) / 365.25 ;
  drop cand1 cand2 ;
run ;
