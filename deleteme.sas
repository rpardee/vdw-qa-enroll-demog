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

proc sql noprint ;
  create table ins_counts as
  select case
        when ins_medicaid        in ('Y', 'E') then 'medicaid'
        when ins_medicare        in ('Y', 'E') then 'medicare'
        when ins_commercial      in ('Y', 'E') then 'commercial'
        when ins_selffunded      in ('Y', 'E') then 'commercial'
        when ins_privatepay      in ('Y', 'E') then 'commercial'
        when ins_highdeductible  in ('Y', 'E') then 'commercial'
        when ins_aca             in ('Y', 'E') then 'commercial'
        when ins_statesubsidized in ('Y', 'E') then 'other public'
        when e.mrn is not null                 then 'not categorized!'
        else 'not insured'
      end as ins_type
      , COUNT(*) as n
  from &_vdw_enroll as e RIGHT JOIN
  (select mrn, max(adate) as last_encounter
  from &_vdw_utilization
  where adate between '01-jan-2016'd and '31-dec-2016'd
  group by mrn) as u
  on e.mrn = u.mrn AND
     u.last_encounter between e.enr_start and e.enr_end
  group by CALCULATED ins_type
  ;

quit ;

proc freq data = ins_counts ;
  tables ins_type / missing format = comma9.0 ;
  weight n ;
run ;

