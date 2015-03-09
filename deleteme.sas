/*********************************************
* Roy Pardee
* Group Health Research Institute
* (206) 287-2078
* pardee.r@ghc.org
*
* //groups/data/CTRHS/Crn/voc/enrollment/programs/deleteme.sas
*
* purpose
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

%include "//ghrisas/Warehouse/Sasdata/CRN_VDW/lib/StdVars.sas" ;
%include vdw_macs ;

data grist ;
  set &_vdw_enroll (keep = mrn enr_start enr_end) ;
run ;

%collapseperiods(lib     = work
        , dset           = grist
        , daystol        = 90
        , recstart       = enr_start
        , recend         = enr_end
        , personid       = mrn
        ) ;

data grist ;
  set grist ;
  duration_in_months = intck('month', enr_start, enr_end) + ((enr_end - enr_start) > 15) ;
run ;
proc freq data = grist noprint ;
  tables duration_in_months / missing format = comma9.0 out = s.duration_freqs ;
run ;
proc summary data = grist n min p10 p25 p50 mean p75 p90 max ;
  var duration_in_months ;
  output out = s.drop_me
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


