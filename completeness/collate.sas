/*********************************************
* Roy Pardee
* Group Health Research Institute
* (206) 287-2078
* pardee.r@ghc.org
*
* //groups/data/CTRHS/Crn/voc/enrollment/programs/completeness/collate.sas
*
* Mashes submitted data together for reporting.
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

libname sub "\\groups\data\CTRHS\Crn\voc\enrollment\programs\completeness\submitted" ;
libname col "\\groups\data\CTRHS\Crn\voc\enrollment\programs\completeness\combined" ;

proc format cntlout = sites ;
  value $s (default = 22)
    /* 'HPRF' = 'HealthPartners' */
    /* 'LCF'  = 'Lovelace' */
    /* "FAL"  = "Fallon Community Health Plan" */
    /* "LHS"  = "Lovelace Health Systems" */
    'HPHC' = 'Harvard'
    'HPI'  = 'HealthPartners'
    'MCRF' = 'Marshfield'
    'SWH'  = 'Baylor Scott & White'
    'HFHS' = 'Henry Ford'
    'GHS'  = 'Geisinger'
    'GHC'  = 'Group Health'
    'PAMF' = 'Palo Alto'
    'EIRH' = 'Essentia'
    'KPCO' = 'KP Colorado'
    'KPNW' = 'KP Northwest'
    'KPGA' = 'KP Georgia'
    "KPNC" = "KP Northern California"
    "KPSC" = "KP Southern California"
    "KPH"  = "KP Hawaii"
    "FA"   = "Fallon Community HP"
    "KPMA" = "KP Mid-Atlantic"
  ;
quit ;

%macro collate ;

  %stack_datasets(inlib = sub, nom = emr_rates                , outlib = col) ;
  %stack_datasets(inlib = sub, nom = lab_rates                , outlib = col) ;
  %stack_datasets(inlib = sub, nom = tumor_rates              , outlib = col) ;
  %stack_datasets(inlib = sub, nom = rx_rates                 , outlib = col) ;
  %stack_datasets(inlib = sub, nom = ute_in_rates_by_enctype  , outlib = col) ;
  %stack_datasets(inlib = sub, nom = ute_out_rates_by_enctype , outlib = col) ;

  proc sql number ;
    * describe table dictionary.tables ;
    create table col.submitting_sites as
    select put(prxchange("s/(.*)_RX_RATES\s*$/$1/i", -1, memname), $s.) as site label = "Site"
        , datepart(crdate) as date_submitted format = mmddyy10. label = "QA Submission Date"
    from dictionary.tables
    where libname = 'SUB' and memname like '%_RX_RATES'
    ;

  quit ;
%mend collate ;

%collate ;
* The SGPANEL call on tumor data was causing a segfault on PC sas.  Unix SAS does not seem to have the problem. ;
%include '\\home\pardre1\SAS\Scripts\sasunxlogon.sas' ;
%include "&GHRIDW_ROOT/remote/RemoteStartUnix.sas" ;
rsubmit ;
* This dattrmap feature was apparently introduced in 9.3--not available on totoro right now. Sad face. ;
data line_colors ;
  input
    @1    id         $char2.
    @5    value       $char24.
    @31   linecolor   $char8.
  ;
datalines ;
lc  Suspected Incomplete      CX4FA3E7
lc  Not Suspected Incomplete  CXFFD472
lc  Not Implmented            CXB4BDEA
lc  Unknown                   CXFF0000
run ;

proc format cntlout = sites ;
  value $s (default = 22)
    /* 'HPRF' = 'HealthPartners' */
    /* 'LCF'  = 'Lovelace' */
    /* "FAL"  = "Fallon Community Health Plan" */
    /* "LHS"  = "Lovelace Health Systems" */
    'HPHC' = 'Harvard'
    'HPI'  = 'HealthPartners'
    'MCRF' = 'Marshfield'
    'SWH'  = 'Baylor Scott & White'
    'HFHS' = 'Henry Ford'
    'GHS'  = 'Geisinger'
    'GHC'  = 'Group Health'
    'PAMF' = 'Palo Alto'
    'EIRH' = 'Essentia'
    'KPCO' = 'KP Colorado'
    'KPNW' = 'KP Northwest'
    'KPGA' = 'KP Georgia'
    "KPNC" = "KP Northern California"
    "KPSC" = "KP Southern California"
    "KPH"  = "KP Hawaii"
    "FA"   = "Fallon Community HP"
    "KPMA" = "KP Mid-Atlantic"
  ;
quit ;

libname col "~/sdrc/data/enroll_complete" ;

proc upload data = col.emr_rates                out = col.emr_rates ;
proc upload data = col.lab_rates                out = col.lab_rates ;
proc upload data = col.tumor_rates              out = col.tumor_rates ;
proc upload data = col.rx_rates                 out = col.rx_rates ;
proc upload data = col.ute_in_rates_by_enctype  out = col.ute_in_rates_by_enctype ;
proc upload data = col.ute_out_rates_by_enctype out = col.ute_out_rates_by_enctype ;
proc upload data = col.submitting_sites         out = col.submitting_sites ;
run ;

%macro plot(inset = col.rx_rates, incvar = incomplete_outpt_rx, tit = %str(Outpatient Pharmacy), extr = ) ;

  proc sort data = &inset out = gnu ;
    by site first_day &incvar ;
    where n gt 200 and rate gt 0 ;
  run ;

  ods graphics / imagename = "&incvar" ;

  title1 "&tit" ;

  proc sgpanel data = gnu /* dattrmap = line_colors */ ;
    panelby site / novarname columns = 4 rows = 4 ;
    /* options I tried to get out of the segfault when doing tumor: smooth = .2  interpolation = linear */
    loess x = first_day y = rate / group = &incvar lineattrs=(pattern = solid) /* attrid = lc */ ;
    format site $s. ;
    rowaxis grid label = "Records per Enrollee" &extr ;
    colaxis grid display = (nolabel) ;
  run ;
%mend plot ;

%macro nonpanel_plot(inset = , incvar = , tit = ) ;
  proc sort data = &inset out = gnu ;
    by site first_day &incvar ;
    where n gt 200 and rate gt 0 ;
  run ;

  ods graphics / imagename = "&incvar" ;

  title1 "&tit" ;

  proc sgplot data = gnu uniform = all ;
    loess x = first_day y = rate / group = &incvar lineattrs = (pattern = solid) ;
    xaxis grid display = (nolabel) ; * values = (&earliest to "31dec2010"d by month ) ;
    yaxis grid label = "Records per Enrollee" ;
    by site ;
    format site $s. ;
  run ;
%mend nonpanel_plot ;

options orientation = landscape ;
ods graphics / height = 6in width = 10in ;

%let out_folder = \\groups\data\ctrhs\crn\voc\enrollment\reports_presentations\capture_rate_output\ ;
%let out_folder = %sysfunc(pathname(col)) ;

ods html path = "&out_folder" (URL=NONE)
         body   = "collate.html"
         (title = "Data Capture Rates by HCSRN Site")
         style = magnify
          ;

  ods rtf file = "&out_folder./incomplete_var_implementations.rtf" device = sasemf style = magnify ;

  footnote1 " " ;

  title2 "Sites submitting QA Results" ;
  ods graphics / imagename = "submitting_sites" ;
  proc sgplot data = col.submitting_sites ;
    dot site / response = date_submitted ;
    xaxis grid min = '01-aug-2015'd ;
  run ;

  options mprint ;

  %plot(inset = col.rx_rates   , incvar = incomplete_outpt_rx, tit = %str(Outpatient Pharmacy)        ) ;

  %plot(inset = col.lab_rates  , incvar = incomplete_lab     , tit = %str(Lab Results)                ) ;
  %plot(inset = col.emr_rates  , incvar = incomplete_emr     , tit = %str(EMR Data (Social History))  ) ;
  %plot(inset = col.tumor_rates, incvar = incomplete_tumor   , tit = %str(Tumor)                      ) ;
  %plot(inset = col.ute_out_rates_by_enctype (where = (extra = 'AV')) , incvar = incomplete_outpt_enc , tit = %str(Ambulatory Visits), extr = %str(max = 2)) ;
  * %nonpanel_plot(inset = col.ute_out_rates_by_enctype (where = (extra = 'AV' and site eq 'PAMF')) , incvar = incomplete_outpt_enc     , tit = %str(Ambulatory Visits)) ;
  %plot(inset = col.ute_in_rates_by_enctype  (where = (extra = 'IP')) , incvar = incomplete_inpt_enc  , tit = %str(Inpatient Stays), extr = %str(max = .020)) ;
  * %nonpanel_plot(inset = col.ute_in_rates_by_enctype  (where = (extra = 'IP' and site eq 'PAMF')) , incvar = incomplete_inpt_enc     , tit = %str(Inpatient Stays)) ;

  * %nonpanel_plot(inset = col.tumor_rates, incvar = incomplete_tumor, tit = %str(Tumor)) ;
 /*
 */


run ;

ods _all_ close ;

** log off unix ;
endrsubmit ;
signoff sasunix.spawner ;

