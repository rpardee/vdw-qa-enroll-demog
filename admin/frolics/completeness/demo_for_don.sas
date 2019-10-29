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

options
  linesize  = 150
  msglevel  = i
  formchar  = '|-++++++++++=|-/|<>*'
  dsoptions = note2err
  nocenter
  noovp
  nosqlremerge
;

proc format cntlout = sites ;
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
    "FA"   = "Fallon Community HP"
    'PAMF' = 'Palo Alto'
    'HPHC' = 'Harvard'
    'SWH'  = 'Baylor Scott & White'
    'HFHS' = 'Henry Ford'
    'KPGA' = 'KP Georgia'
    "KPSC" = "KP Southern California"
  ;
quit ;

data gnu ;
  input
    @1    site                $char4.
    @7    first_day           mmddyy10.
    @19   incomplete_outpt_rx $char24.
    @45   extra               2.0
    @49   rate                12.10
  ;
  format first_day mmddyy10. ;
datalines ;
GHC   09/01/2014  Not Suspected Incomplete  -1  0.9216495728
GHC   01/01/2014  Suspected Incomplete      -1  0.8532110092
GHC   05/01/2014  Suspected Incomplete      -1  0
GHC   07/01/2014  Not Suspected Incomplete  -1  0.9261239821
GHC   05/01/2014  Not Suspected Incomplete  -1  0.9205899175
GHC   09/01/2014  Suspected Incomplete      -1  0.6060606061
GHC   07/01/2014  Suspected Incomplete      -1  0
GHC   11/01/2014  Not Suspected Incomplete  -1  0.8739361862
GHC   10/01/2014  Not Suspected Incomplete  -1  0.9645124093
GHC   12/01/2014  Suspected Incomplete      -1  0.3225806452
GHC   03/01/2014  Suspected Incomplete      -1  9
GHC   02/01/2014  Suspected Incomplete      -1  0
GHC   01/01/2014  Not Suspected Incomplete  -1  0.9703798334
GHC   12/01/2014  Not Suspected Incomplete  -1  0.9857413122
GHC   06/01/2014  Not Suspected Incomplete  -1  0.9074525412
GHC   06/01/2014  Suspected Incomplete      -1  0.3333333333
GHC   08/01/2014  Suspected Incomplete      -1  0.6620689655
GHC   10/01/2014  Suspected Incomplete      -1  0.5714285714
GHC   02/01/2014  Not Suspected Incomplete  -1  0.8639262195
GHC   08/01/2014  Not Suspected Incomplete  -1  0.8904341293
GHC   11/01/2014  Suspected Incomplete      -1  0.2777777778
GHC   03/01/2014  Not Suspected Incomplete  -1  0.9372514252
GHC   04/01/2014  Not Suspected Incomplete  -1  0.9263418476
KPNW  01/01/2014  Suspected Incomplete      -1  0.3175200803
KPNW  01/01/2014  Not Suspected Incomplete  -1  0.9412865965
KPNW  02/01/2014  Suspected Incomplete      -1  0.3005689001
KPNW  02/01/2014  Not Suspected Incomplete  -1  0.8181840841
KPNW  03/01/2014  Suspected Incomplete      -1  0.2919518527
KPNW  03/01/2014  Not Suspected Incomplete  -1  0.9029912202
KPNW  04/01/2014  Suspected Incomplete      -1  0.2685070562
KPNW  04/01/2014  Not Suspected Incomplete  -1  0.9034010838
KPNW  05/01/2014  Suspected Incomplete      -1  0.271685761
KPNW  05/01/2014  Not Suspected Incomplete  -1  0.8995571559
KPNW  06/01/2014  Suspected Incomplete      -1  0.2653155228
KPNW  06/01/2014  Not Suspected Incomplete  -1  0.8870601154
KPNW  07/01/2014  Suspected Incomplete      -1  0.2382666838
KPNW  07/01/2014  Not Suspected Incomplete  -1  0.8438602328
KPNW  08/01/2014  Suspected Incomplete      -1  0.1734613361
KPNW  08/01/2014  Not Suspected Incomplete  -1  0.7872576063
KPNW  09/01/2014  Suspected Incomplete      -1  0.1761524594
KPNW  09/01/2014  Not Suspected Incomplete  -1  0.8401298693
KPNW  10/01/2014  Suspected Incomplete      -1  0.1641959622
KPNW  10/01/2014  Not Suspected Incomplete  -1  0.8680591425
KPNW  11/01/2014  Suspected Incomplete      -1  0.1398093509
KPNW  11/01/2014  Not Suspected Incomplete  -1  0.7781389462
KPNW  12/01/2014  Suspected Incomplete      -1  0.146713032
KPNW  12/01/2014  Not Suspected Incomplete  -1  0.9204403589
run ;

* See the help topic for 'dattrmap'--needed to do this to keep the line/dot colors consistent accross calls to SGPlot.;
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
  run ;

  ods graphics / imagename = "&incvar" ;

  title1 "&tit" ;

  proc sgpanel data = gnu dattrmap = line_colors ;
    panelby site / novarname columns = 4 rows = &rows ;
    loess x = first_day y = rate / group = &incvar attrid = lc ;
    format site $s. ;
    rowaxis grid label = "Records per Enrollee" &extr ;
    colaxis grid display = (nolabel) ;
  run ;
%mend plot ;


options orientation = landscape ;
ods graphics / height = 6in width = 10in ;

%let out_folder = c:\temp\ ;

ods html path = "&out_folder" (URL=NONE)
         body   = "collate.html"
         (title = "Data Capture Rates by HCSRN Site")
         style = magnify
          ;

  ods rtf file = "&out_folder./incomplete_var_implementations.rtf" device = sasemf style = magnify ;

  footnote1 " " ;

  options mprint ;

  %plot(inset = gnu, incvar = incomplete_outpt_rx, tit = %str(Outpatient Pharmacy) ) ;

run ;

ods _all_ close ;

