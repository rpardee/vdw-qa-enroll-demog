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

%mend collate ;

%macro plot(inset = col.rx_rates, incvar = incomplete_outpt_rx, tit = %str(Outpatient Pharmacy)) ;

  proc sort data = &inset out = gnu ;
    by site first_day &incvar ;
    where n gt 200 and rate gt 0 ;
  run ;

  ods graphics / imagename = "&incvar" ;

  title1 "&tit" ;

  proc sgpanel data = gnu ;
    panelby site / novarname columns = 3 rows = 3 /* uniscale = column */ ;
    /* options I tried to get out of the segfault when doing tumor: smooth = .2  interpolation = linear */
    loess x = first_day y = rate / group = &incvar lineattrs = (pattern = solid) ;
    format site $s. ;
    rowaxis grid label = "Records per Enrollee" ;
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

%collate ;

options orientation = landscape ;
ods graphics / height = 6in width = 10in ;

%let out_folder = \\groups\data\ctrhs\crn\voc\enrollment\reports_presentations\capture_rate_output\ ;

ods html path = "&out_folder" (URL=NONE)
         body   = "collate.html"
         (title = "Data Capture Rates by HCSRN Site")
         style = magnify
          ;

ods rtf file = "&out_folder.collate.rtf" device = sasemf ;

  footnote1 " " ;


  %plot(inset = col.rx_rates   , incvar = incomplete_outpt_rx, tit = %str(Outpatient Pharmacy)) ;
  %plot(inset = col.lab_rates  , incvar = incomplete_lab     , tit = %str(Lab Results)        ) ;
  %plot(inset = col.emr_rates  , incvar = incomplete_emr     , tit = %str(EMR Data)           ) ;
  %plot(inset = col.ute_in_rates_by_enctype (where = (extra = 'IP'))  , incvar = incomplete_inpt_enc     , tit = %str(Inpatient Stays)) ;
  %plot(inset = col.ute_out_rates_by_enctype (where = (extra = 'AV'))  , incvar = incomplete_outpt_enc     , tit = %str(Ambulatory Visits)) ;



  %nonpanel_plot(inset = col.tumor_rates, incvar = incomplete_tumor, tit = %str(Tumor)) ;


run ;

ods _all_ close ;

