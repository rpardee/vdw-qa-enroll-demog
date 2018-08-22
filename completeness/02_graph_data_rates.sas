/*********************************************
* Roy Pardee
* Group Health Research Institute
* (206) 287-2078
* pardee.r@ghc.org
*
* //groups/data/CTRHS/Crn/voc/enrollment/out_ute/vdw_outside_utilization_qa_wp01v02/sas/deleteme.sas
*
* purpose
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

* Please replace this include statement with a reference to your own local StdVars.sas ;
* (This is just to get the _SiteName var into session--not hitting any data in this.) ;
%include "&GHRIDW_ROOT/Sasdata/CRN_VDW/lib/StdVars_Teradata.sas" ;

* Please change this to the location where you unzipped this package. ;
%let root = \\groups\data\CTRHS\Crn\voc\enrollment\programs\completeness ;

* OPTIONAL--the minimum monthly enrollment to require for a data point to show up on plots. ;
* Used to elide points for which the rate figures are unstable/implausible due to low N. ;
%let min_n = 200 ;

%let vers = molina ;
* ============== END EDIT SECTION ========================= ;

libname out "&root./to_send/&vers._version" ;

proc format ;
   value $enct
      'LO' = 'Lab Only'
      'RO' = 'Radiology Only'
      'OE' = 'Other'

      'ED' = 'Emergency Dept'
      'IP' = 'Acute Inpatient Hospital Stay'
      'IS' = 'Non-acute institutional'

      'AV' = 'Ambulatory visit'
      'EM' = 'E-mail'
      'TE' = 'Telephone'
   ;
quit ;

%macro graph_capture(rateset = out.rx_rates, incvar = incomplete_outpt_rx, ylab = "Pharmacy Fills Per Enrollee") ;
  * Sort so legend colors are consistent from plot to plot ;
  proc sort data = &rateset out = gnu ;
    by first_day &incvar ;
  run ;

  ods graphics / imagename = "&incvar" ;
  proc sgplot data = gnu ;
    title2 "Capture of &ylab" ;
    loess x = first_day y = rate / group = &incvar lineattrs = (pattern = solid) ;
    xaxis grid label = "Month" ;
    yaxis grid label = "&ylab per Enrollee (points + loess)" min = 0 ;
    format n comma9.0 ;
    where &incvar ne 'Unknown' and n ge &min_n ;
    keylegend / title = "Data Capture" ;
  run ;
%mend graph_capture ;

%macro panel_ute(rateset = out.ute_rates_by_enctype, incvar = incomplete_outpt_enc, cols = 3, rows = 3) ;
  %* A special macro for ute by enctype--does sgpanel rather than sgplot. ;
  proc sort data = &rateset out = gnu ;
    by first_day &incvar ;
  run ;

  ods graphics / imagename = "ute_panel" ;
  proc sgpanel data = gnu ;
    title2 "Utilization Capture By Encounter Type" ;
    panelby extra / novarname columns = &cols rows = &rows ;
    loess x = first_day y = rate / group = &incvar lineattrs = (pattern = solid) ;
    colaxis grid label = "Month" ;
    rowaxis grid label = "Encounters per Enrollee (points + loess)" min = 0 ;
    keylegend / title = "Data Capture" ;
    format n comma9.0 extra $enct. ;
    where &incvar ne 'Unknown' and n ge &min_n ;
%mend panel_ute ;

options orientation = landscape ;

ods html path = "&root./do_not_send/&vers._version" (URL=NONE)
         body   = "vdw_completeness.html"
         (title = "&vers Completeness of Data Capture in VDW for &_SiteName")
         style = magnify
         nogfootnote
        ;

ods rtf file = "&root./do_not_send/vdw_completeness.rtf" device = sasemf style = magnify ;

    ods graphics / height = 6in width = 10in ;
    title1 "Completeness of VDW Data for &_SiteName" ;
    %graph_capture(rateset = out.&_siteabbr._rx_rates
                  , incvar = incomplete_outpt_rx
                  , ylab = Pharmacy Fills
                  ) ;

    %graph_capture(rateset = out.&_siteabbr._ute_out_rates_by_enctype (where = (extra = 'AV'))
                  , incvar = incomplete_outpt_enc
                  , ylab = Outpatient Encounters
                  ) ;
    %graph_capture(rateset = out.&_siteabbr._ute_in_rates_by_enctype (where = (extra = 'IP'))
                  , incvar = incomplete_inpt_enc
                  , ylab = Inpatient Encounters
                  ) ;

    %panel_ute(rateset = out.&_siteabbr._ute_out_rates_by_enctype (where = (extra in ('AV', 'EM', 'TE')))
                , incvar = incomplete_outpt_enc, rows = 1, cols = 3) ;

    %panel_ute(rateset = out.&_siteabbr._ute_out_rates_by_enctype (where = (extra in ('ED', 'IP', 'IS')))
                , incvar = incomplete_outpt_enc, rows = 1, cols = 3) ;

    %panel_ute(rateset = out.&_siteabbr._ute_out_rates_by_enctype (where = (extra in ('LO', 'RO', 'OE')))
                , incvar = incomplete_outpt_enc, rows = 1, cols = 3) ;

    %graph_capture(incvar  = incomplete_tumor
                  , rateset  = out.&_siteabbr._tumor_rates
                  , ylab = Tumor Registry
                  ) ;
    %graph_capture(incvar  = incomplete_lab
                  , rateset  = out.&_siteabbr._lab_rates
                  , ylab = Lab Results
                  ) ;
    %graph_capture(incvar  = incomplete_emr
                  , rateset  = out.&_siteabbr._emr_s_rates
                  , ylab = EMR Data (Social History)
                  ) ;
    %graph_capture(incvar  = incomplete_emr
                  , rateset  = out.&_siteabbr._emr_v_rates
                  , ylab = EMR Data (Vital Signs)
                  ) ;

run ;

ods _all_ close ;
