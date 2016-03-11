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

* %include "h:/SAS/Scripts/remoteactivate.sas" ;
* Bringing in the contents of remoteactivate.sas so I can specify I want to hit ROC3LW, which has sas v9.4 installed. ;

proc sql noprint ;
   select trim(XPath)
   into :program_file separated by ' '
   from dictionary.extfiles
   where fileref like "#LN00005" ;
   ;
  select trim(reverse(substr(reverse(xpath), index(reverse(xpath), "\"))))
  into :program_folder
  from dictionary.extfiles
  where fileref = '#LN00005'
  ;
quit ;

footnote "Program file: &program_file " ;

** I want this lib set even in my local session. ;
libname s "\\home\pardre1\workingdata" ;

%let ROC3LW=10.1.179.66;
options COMAMID=TCP REMOTE=ROC3LW;

%include '\\home\pardre1\SAS\login.sas';
filename ghridwip "&GHRIDW_ROOT\remote\tcpwinbatch.scr" ;
signon ghridwip ;

** Move the program file macro var over to the remote session. ;
%syslput program_file   = &program_file ;
%syslput username       = &username ;
%syslput password       = &password ;
* %syslput td_goo         = &td_goo ;

rsubmit ;

** Put the filename in the comment field for the SAS process manager. ;
%make_spm_comment(&program_file) ;

***********************;
** Set the typical libnames... ;
** SAS recommends *against* UNCs (!). ;
%let DWROOT = &GHRIDW_ROOT\sasdata\ ;

libname chsid     "&DWROOT.CHSID" ;
libname demogs    "&DWROOT.Consumer Demographics" ;
libname baseline  "&DWROOT.Baseline" ;
libname VDW       "&DWROOT.CRN_VDW" ;

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
  value $orig (default = 22)
    'HPI'  = 'HealthPartners'
    'MCRF' = 'Marshfield'
    'GHS'  = 'Geisinger'
    'GHC'  = 'Group Health'
    'EIRH' = 'Essentia'
    'KPCO' = 'KP Colorado'
    'KPNW' = 'KP Northwest'
    "KPNC" = "KP Northern California"
    "KPH"  = "KP Hawaii"
    "KPMA" = "KP Mid-Atlantic"
    "FA"   = "Fallon Community HP" /* maybe--check */
    'PAMF' = 'Palo Alto' /* maybe--check */
    'HPHC' = 'Harvard'
    'SWH'  = 'Baylor Scott & White'
    'HFHS' = 'Henry Ford'
    'KPGA' = 'KP Georgia'
    "KPSC" = "KP Southern California"
  ;
  value $s (default = 22)
    'HPI'  = 'HealthPartners'
    'MCRF' = 'Marshfield'
    'GHS'  = 'Geisinger'
    'GHC'  = 'Group Health'
    'EIRH' = 'Essentia'
    'KPCO' = 'KP Colorado'
    'KPNW' = 'KP Northwest'
    "KPNC" = "KP Northern California"
    "KPH"  = "KP Hawaii"
    "KPMA" = "KP Mid-Atlantic"
    other  = "gotohell"
  ;

  value $maybe (default = 22)
    "FA"   = "Fallon Community HP" /* maybe--check */
    'PAMF' = 'Palo Alto' /* maybe--check */
  ;
  value $go2hell (default = 22)
    'HPHC' = 'Harvard'
    'SWH'  = 'Baylor Scott & White'
    'HFHS' = 'Henry Ford'
    'KPGA' = 'KP Georgia'
    "KPSC" = "KP Southern California"

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

options extendobscounter = no ;
* %collate ;

data line_colors ;
  input
    @1    id         $char2.
    @5    value       $char24.
    @31   linecolor   $char8.
  ;
  markercolor = linecolor ;
  markersymbol = 'circle' ;
  linepattern = 'solid' ;
datalines ;
lc  Suspected Incomplete      CX4FA3E7
lc  Not Suspected Incomplete  CXFFD472
lc  Not Implemented           CXB4BDEA
lc  Unknown                   CXFF0000
run ;

%macro plot(inset = col.rx_rates, incvar = incomplete_outpt_rx, tit = %str(Outpatient Pharmacy), extr = , rows = 3) ;

  proc sort data = &inset out = gnu ;
    by site first_day &incvar ;
    where n gt 200 /* and rate gt 0 */ ;
  run ;

  ods graphics / imagename = "&incvar" ;

  title1 "&tit" ;

  proc sgpanel data = gnu dattrmap = line_colors ;
    panelby site / novarname columns = 4 rows = &rows ;
    /* options I tried to get out of the segfault when doing tumor: smooth = .2  interpolation = linear */
    loess x = first_day y = rate / group = &incvar attrid = lc ;
    * format site $s. ;
    format site $orig. ;
    rowaxis grid label = "Records per Enrollee" &extr ;
    colaxis grid display = (nolabel) ;
    * where put(site, $s.) ne 'gotohell' ;
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
    * format site $s. ;
    format site $orig. ;
    * where put(site, $s.) ne 'gotohell' ;
  run ;
%mend nonpanel_plot ;

* Calculate per-site & date rates of all outpatient visits ;
proc sql ;
  create table col.summed_outpt_rates as
  select site, first_day, incomplete_outpt_enc
      , sum(num_events) as num_events
      , min(n) as n
      , sum(num_events) / min(n) as rate
  from col.ute_out_rates_by_enctype
  where extra ne 'IP'
  group by site, first_day, incomplete_outpt_enc
  ;
quit ;

options orientation = landscape ;
ods graphics / height = 6in width = 10in ;

%let out_folder = \\groups\data\ctrhs\crn\voc\enrollment\reports_presentations\capture_rate_output\ ;
* %let out_folder = %sysfunc(pathname(col)) ;

ods html path = "&out_folder" (URL=NONE)
         body   = "collate.html"
         (title = "Data Capture Rates by HCSRN Site")
         style = magnify
          ;

  ods rtf file = "&out_folder./incomplete_var_implementations.rtf" device = sasemf style = magnify ;

  footnote1 " " ;

  * title2 "Sites submitting QA Results" ;
  * ods graphics / imagename = "submitting_sites" ;
  * proc sgplot data = col.submitting_sites ;
  *   dot site / response = date_submitted ;
  *   xaxis grid min = '01-aug-2015'd ;
  * run ;

  options mprint ;

  %plot(inset = col.rx_rates   , incvar = incomplete_outpt_rx, tit = %str(Outpatient Pharmacy)        ) ;

  %plot(inset = col.lab_rates  , incvar = incomplete_lab     , tit = %str(Lab Results)                ) ;
  %plot(inset = col.emr_rates  , incvar = incomplete_emr     , tit = %str(EMR Data (Social History))  ) ;
  %plot(inset = col.tumor_rates, incvar = incomplete_tumor   , tit = %str(Tumor)                      , extr = %str(max = 0.0015), rows = 3) ;

  %plot(inset = col.ute_out_rates_by_enctype (where = (extra = 'AV')) , incvar = incomplete_outpt_enc , tit = %str(Ambulatory Visits), extr = %str(max = 2)) ;
  %plot(inset = col.summed_outpt_rates, incvar = incomplete_outpt_enc , tit = %str(All Non-Inpatient Visits)) ;
  * %nonpanel_plot(inset = col.ute_out_rates_by_enctype (where = (extra = 'AV' and site eq 'PAMF')) , incvar = incomplete_outpt_enc     , tit = %str(Ambulatory Visits)) ;
  %plot(inset = col.ute_in_rates_by_enctype  (where = (extra = 'IP')) , incvar = incomplete_inpt_enc  , tit = %str(Inpatient Stays), extr = %str(max = .020)) ;
  * %nonpanel_plot(inset = col.ute_in_rates_by_enctype  (where = (extra = 'IP' and site eq 'PAMF')) , incvar = incomplete_inpt_enc     , tit = %str(Inpatient Stays)) ;

  * %nonpanel_plot(inset = col.tumor_rates, incvar = incomplete_tumor, tit = %str(Tumor)) ;
 /*
 */


run ;

ods _all_ close ;

