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

* Location of your rate datasets--the ones produced by simple_data_rates.sas. ;
libname out "\\ghrisas\SASUser\pardre1\vdw\enroll" ;

* Location where you want the output graphs.  Leave this as-is to put it in the same dir where the dsets are. ;
%let out_folder = %sysfunc(pathname(out)) ;
* ============== BEGIN EDIT SECTION ========================= ;

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
  ods graphics / imagename = "&incvar" ;
  proc sgplot data = &rateset ;
    title2 "Capture of &ylab" ;
    loess x = first_day y = rate / group = &incvar lineattrs = (pattern = solid) ;
    xaxis grid label = "Month" ;
    yaxis grid label = "&ylab per Enrollee (points + loess)" ;
    format n comma9.0 ;
    where &incvar ne 'Unknown' and first_day le intnx('month', "&sysdate9."d, -3) and n > 10 ;
    keylegend / title = "Data Capture" ;
  run ;
%mend graph_capture ;

%macro panel_ute(rateset = out.ute_rates_by_enctype, incvar = incomplete_outpt_enc, cols = 3, rows = 3) ;
  %* A special macro for ute by enctype--does sgpanel rather than sgplot. ;
  ods graphics / imagename = "ute_panel" ;
  proc sgpanel data = &rateset ;
    title2 "Utilization Capture By Encounter Type" ;
    panelby extra / novarname columns = &cols rows = &rows ;
    loess x = first_day y = rate / group = &incvar lineattrs = (pattern = solid) ;
    colaxis grid label = "Month" ;
    rowaxis grid label = "Encounters per Enrollee (points + loess)" ;
    keylegend / title = "Data Capture" ;
    format n comma9.0 extra $enct. ;
    where &incvar ne 'Unknown' and first_day le intnx('month', "&sysdate9."d, -3) and n > 10 ;
%mend panel_ute ;

options orientation = landscape ;

ods html path = "&out_folder" (URL=NONE)
         body   = "vdw_completeness.html"
         (title = "Completeness of Data Capture in VDW for &_SiteName")
         style = magnify
         nogfootnote
          ;

ods rtf file = "&out_folder./vdw_completeness.rtf" device = sasemf style = magnify ;

    ods graphics / height = 6in width = 10in ;
    title1 "Completeness of VDW Data for &_SiteName" ;
    %graph_capture(rateset = out.rx_rates
                  , incvar = incomplete_outpt_rx
                  , ylab = Pharmacy Fills
                  ) ;
    %graph_capture(rateset = out.ute_rates_by_enctype (where = (extra = 'AV'))
                  , incvar = incomplete_outpt_enc
                  , ylab = Outpatient Encounters
                  ) ;
    %graph_capture(rateset = out.ute_rates_by_enctype (where = (extra = 'IP'))
                  , incvar = incomplete_outpt_enc
                  , ylab = Inpatient Encounters
                  ) ;

    %panel_ute(rateset = out.ute_rates_by_enctype (where = (extra in ('AV', 'EM', 'TE')))
                , incvar = incomplete_outpt_enc, rows = 1, cols = 3) ;

    %panel_ute(rateset = out.ute_rates_by_enctype (where = (extra in ('ED', 'IP', 'IS')))
                , incvar = incomplete_outpt_enc, rows = 1, cols = 3) ;

    %panel_ute(rateset = out.ute_rates_by_enctype (where = (extra in ('LO', 'RO', 'OE')))
                , incvar = incomplete_outpt_enc, rows = 1, cols = 3) ;

    %graph_capture(incvar  = incomplete_tumor
                  , rateset  = out.tumor_rates
                  , ylab = Tumor Registry
                  ) ;
    %graph_capture(incvar  = incomplete_lab
                  , rateset  = out.lab_rates
                  , ylab = Lab Results
                  ) ;

    %graph_capture(incvar  = incomplete_emr
                  , rateset  = out.social_rates (where = (extra = 'P'))
                  , ylab = EMR Data (Social History)
                  ) ;

run ;

ods _all_ close ;
