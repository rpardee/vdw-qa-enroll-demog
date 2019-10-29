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
* libname mylib teradata
  user              = "&clean_username@LDAP"
  password          = "&password"
  server            = "EDW_PROD1"
  schema            = "%sysget(username)"
  multi_datasrc_opt = in_clause
  connection        = global
;
* Please change this to the location where you unzipped this package. ;
%let root = \\groups\data\CTRHS\Crn\voc\enrollment\programs\completeness ;


* OPTIONAL--the minimum monthly enrollment to require for a data point to show up on plots. ;
* Used to elide points for which the rate figures are unstable/implausible due to low N. ;
%let min_n = 200 ;
* ============== END EDIT SECTION ========================= ;

libname out "&root./to_send" ;

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
  value $inc
    "K" = "Suspected Incomplete"
    "N" = "Not Suspected Incomplete"
    "X" = "Not Implemented"
    "M" = "Molina"
  other = "Unknown"
  ;
  value $rg
    'East' = ' East'
    'West' = 'West'
  ;

quit ;

%macro graph_capture(rateset = out.rx_rates, incvar = incomplete_outpt_rx, nvar = n, nevar = num_events, ylab = "Pharmacy Fills Per Enrollee") ;
  * Sort so legend colors are consistent from plot to plot ;
  proc sort data = &rateset out = gnu ;
    by first_day &incvar ;
  run ;

  data gnu ;
    set gnu ;
    rate = &nevar / &nvar ;
    grp = put(&incvar, $inc.) ;
  run ;

  ods graphics / imagename = "&incvar" ;
  proc sgplot data = gnu ;
    title2 "Capture of &ylab" ;
    loess x = first_day y = rate / group = grp lineattrs = (pattern = solid) ;
    xaxis grid label = "Month" ;
    yaxis grid label = "&ylab per Enrollee (points + loess)" ;
    format &nvar comma9.0 ;
    where &incvar ne 'Unknown' and &nvar ge &min_n and first_day lt '01-jan-2016'd ;
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
    rowaxis grid label = "Encounters per Enrollee (points + loess)" ;
    keylegend / title = "Data Capture" ;
    format n comma9.0 extra $enct. ;
    where &incvar ne 'Unknown' and n ge &min_n ;
%mend panel_ute ;

options orientation = landscape ;

ods html path = "&root./ew_output" (URL=NONE)
         body   = "vdw_completeness.html"
         (title = "Completeness of Data Capture in VDW for &_SiteName")
         /* style = magnify */
         nogfootnote
        ;

ods rtf file = "&root./ew_output/vdw_completeness.rtf" device = sasemf style = magnify ;

  ods graphics / height = 9in width = 10in ;
  title1 "Rates of VDW Lab Results Data by Division and Region" ;
  proc sgpanel data = out.kpwa_lab_rates_ew ;
    panelby region division / novarname layout = lattice sort = descending ;
    loess x = first_day y = rate / nolegfit ;
    bubble x = first_day y = rate size = n_enrollees / colorresponse = n_enrollees transparency = .7 ;
    rowaxis grid label = "Results/Enrollee" ;
    colaxis grid label = "Time" ;
    where region in ('East', 'West') ;
    * format region $rg. ;
  run ;

  ods graphics / height = 8in width = 10in ;
  proc sgpanel data = out.kpwa_lab_rates_ew ;
    panelby region / novarname sort = descending ;
    loess x = first_day y = rate / group = division nolegfit lineattrs = (pattern=solid) ;
    bubble x = first_day y = rate size = n_enrollees / group = division transparency = .8 ;
    rowaxis grid label = "Results/Enrollee" ;
    colaxis grid label = "Time" ;
    where region in ('East', 'West') ;
    attrib division label = "Division" ;
  run ;

  proc sgpanel data = out.kpwa_lab_rates_ew ;
    panelby division / novarname sort = descending ;
    loess x = first_day y = rate / group = region nolegfit lineattrs = (pattern=solid) ;
    bubble x = first_day y = rate size = n_enrollees / group = region transparency = .8 ;
    rowaxis grid label = "Results/Enrollee" ;
    colaxis grid label = "Time" ;
    where region in ('East', 'West') ;
    attrib division label = "Division" ;
  run ;

  title2 "Over-65s Only" ;
  ods graphics / height = 8in width = 10in ;
  proc sgpanel data = out.kpwa_lab_rates_ew_old ;
    panelby region / novarname sort = descending ;
    loess x = first_day y = rate / group = division nolegfit lineattrs = (pattern=solid) ;
    bubble x = first_day y = rate size = n_enrollees / group = division transparency = .8 colorresponse = n_enrollees ;
    rowaxis grid label = "Results/Enrollee" ;
    colaxis grid label = "Time" ;
    where region in ('East', 'West') ;
    attrib division label = "Division" ;
  run ;

run ;

ods _all_ close ;
