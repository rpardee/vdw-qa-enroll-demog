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

%macro graph_unenrolled(inset = out.&_siteabbr._rx_unenrolled, ylab =) ;
  ods graphics / imagename = "unenrolled_event_counts" ;

  title3 "&ylab" ;

  proc sgplot data = &inset ;
    loess x = first_day y = n_unenrolled / lineattrs = (pattern = solid) nolegfit ;
    xaxis grid label = "Month" ;
    yaxis grid min = 0 label = "No. of &ylab for non-enrollees" ;
  run ;
%mend graph_unenrolled ;

