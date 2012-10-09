/*********************************************
* Roy Pardee
* Group Health Research Institute
* (206) 287-2078
* pardee.r@ghc.org
*
* //groups/data/CTRHS/Crn/voc/enrollment/test_tier1_qa.sas
*
* Creates screwed-up versions of enroll & demog and sets the
* standard vars for those files = to the messed up files, so
* I can be sure that a bad file would in fact trigger the QA
* checks.
*********************************************/

* %include "\\home\pardre1\SAS\Scripts\remoteactivate.sas" ;

* libname vdw "\\ghrisas\Warehouse\sasdata\crn_vdw" ;

%let size = 10000 ;

data s.bad_demog ;
  retain _mrn 'zzzzzzzzzz' ;
  set &_vdw_demographic (obs = &size) ;

  if floor(uniform(0) * (&size / 100)) = 0 then do ;
    hispanic = ' ' ;
  end ;

  if floor(uniform(0) * (&size / 100)) = 0 then do ;
    gender = '?' ;
  end ;

  if floor(uniform(0) * (&size / 100)) = 0 then do ;
    primary_language = 'zzz' ;
  end ;

  if floor(uniform(0) * (&size / 100)) = 0 then do ;
    mrn = _mrn ;
  end ;

  array rac(*) race1 - race5 ;
  do i = 1 to dim(rac) ;
    if floor(uniform(0) * (&size / 100)) = 0 then do ;
      rac(i) = '03' ;
    end ;
  end ;

  _mrn = mrn ;

  drop i needs_interpreter _mrn ;
run ;

proc sql outobs = %eval(&size * 10) nowarn ;
  create table s.bad_enroll as
  select    e.*
  from    &_vdw_enroll as e    INNER JOIN
          s.bad_demog as d
  on      e.mrn = d.mrn
  ;

  reset outobs = &size nowarn ;

  create table not_in_demog as
  select    e.*
  from    vdw.enroll2 as e    LEFT JOIN
          s.bad_demog as d
  on      e.mrn = d.mrn
  where   d.mrn IS NULL
  ;

quit ;

data s.bad_enroll ;
  set
    s.bad_enroll
    not_in_demog
  ;

  if floor(uniform(0) * (&size / 100)) = 0 then do ;
    * swap start and end ;
    _st = enr_start ;
    enr_start = enr_end ;
    enr_end = _st ;
  end ;
  if floor(uniform(0) * (&size / 100)) = 0 then do ;
    * future end ;
    enr_end = '25dec2032'd ;
  end ;

  if floor(uniform(0) * (&size / 100)) = 0 then do ;
    * medicare part/flag agreement ;
    ins_medicare_c = 'Y' ;
    ins_medicare = 'U' ;
  end ;

  if floor(uniform(0) * (&size / 100)) = 0 then do ;
    * medicare part d before 2006 ;
    enr_start = '30jun2004'd ; * <-- this will likely also cause some overlapping periods. ;
    ins_medicare_d = 'Y' ;
  end ;

  if floor(uniform(0) * (&size / 100)) = 0 then do ;
    * high deduct w/out commercial or private pay ;
    ins_highdeductible = 'Y' ;
    ins_commercial = 'N' ;
    ins_privatepay = 'N' ;
  end ;

  if floor(uniform(0) * (&size / 100)) = 0 then do ;
    * outside ute and drugcov ;
    outside_utilization = 'N' ;
    drugcov = 'N' ;
  end ;

  if floor(uniform(0) * (&size / 100)) = 0 then do ;
    * enrollment basis valid value ;
    enrollment_basis = 'q' ;
  end ;

  array flgs ins_: outside_utilization drugcov ;
  do i = 1 to dim(flgs) ;
    if floor(uniform(0) * (&size / 100)) = 0 then do ;
      flgs(i) = 'q' ;
    end ;
  end ;

  drop _: ;
run ;

%let _vdw_demographic = s.bad_demog ;
%let _vdw_enroll = s.bad_enroll ;

