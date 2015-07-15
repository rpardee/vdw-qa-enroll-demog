/*********************************************
* Roy Pardee
* Group Health Research Institute
* (206) 287-2078
* pardee.r@ghc.org
*
* //groups/data/CTRHS/Crn/voc/enrollment/out_ute/vdw_outside_utilization_qa_wp01v02/sas/collate_for_r.sas
*
* Collates the various dsets created in simple_data_rates into a single
* dset we can read into R to do a nice ggplot for data insider.
*********************************************/

%include "h:/SAS/Scripts/remoteactivate.sas" ;

options
  linesize  = 150
  msglevel  = i
  formchar  = '|-++++++++++=|-/|<>*'
  dsoptions = note2err
  nocenter
  noovp
  nosqlremerge
;

/*

  dsets are:
    scr.rx_rates
    scr.tumor_rates
    scr.lab_rates
    scr.ute_rates_by_enctype
    scr.vital_rates

*/

libname scr "//ghrisas/SASUser/pardre1" ;

%macro appnd(outset = scr.collated_rates) ;
  %removedset(dset = &outset) ;

  data rx_rates (rename = (incomplete_outpt_rx = capture_status)) ;
    length tit $ 25 ;
    set scr.rx_rates ;
    tit = "Outpatient Pharmacy" ;
    drop extra ;
  run ;

  proc append base = &outset data = rx_rates ;

  data tumor_rates (rename = (incomplete_tumor = capture_status)) ;
    length tit $ 25 ;
    set scr.tumor_rates ;
    tit = "Tumor Registry" ;
    drop extra ;
  run ;

  proc append base = &outset data = tumor_rates ;

  data lab_rates (rename = (incomplete_lab = capture_status)) ;
    length tit $ 25 ;
    set scr.lab_rates ;
    tit = "Lab Results" ;
    drop extra ;
  run ;

  proc append base = &outset data = lab_rates ;

  data emr_rates (rename = (incomplete_emr = capture_status)) ;
    length tit $ 25 ;
    set scr.vital_rates (where = (extra = 'P')) ;
    tit = "EMR Data (Vital Signs)" ;
    drop extra ;
  run ;

  proc append base = &outset data = emr_rates ;

  data ute_rates (rename = (incomplete_outpt_enc = capture_status)) ;
    length tit $ 25 ;
    set scr.ute_rates_by_enctype ;
    if extra = 'IP' then tit = "Inpatient Encounters" ;
    else if extra = 'AV' then tit = "Outpatient Encounters" ;
    else delete ;

    drop extra ;
  run ;

  proc append base = &outset data = ute_rates ;

  * proc append base = &outset data = scr.ute_rates_by_enctype ;
  run ;
%mend appnd ;

%appnd ;

proc freq data = s.collated_rates order = freq ;
  tables tit / missing format = comma9.0 ;
run ;

