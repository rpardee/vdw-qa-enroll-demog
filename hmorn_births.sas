/*********************************************
* Roy Pardee
* Group Health Research Institute
* (206) 287-2078
* pardee.r@ghc.org
*
* c:\Documents and Settings\pardre1\My Documents\vdw\macros\hmorn_births.sas
*
* Counts the number of annual births in utilization data.
*
*********************************************/

** ======================== BEGIN EDIT SECTION ================================ ;

** PLEASE COMMENT OUT THE FOLLOWING LINE IF ROY FORGETS TO (SORRY!) ;
%**include "\\home\pardre1\SAS\Scripts\remoteactivate.sas.connected.new" ;

** Your local copy of StdVars.sas ;
%include "\\groups\data\CTRHS\Crn\S D R C\VDW\Macros\StdVars.sas" ;

** Destination for the output.  Please be sure to include a
** trailing path separator (e.g., forward/backward-slash as
** appropriate to your platform). ;
%let outloc = \\ctrhs-sas\sasuser\pardre1\vdw\hmorn_births\ ;

** Please specify the beginning of the period marking the last 2 years of full utilization data ;
** So if your last complete year of ute data is 2010, you would specify 01jan2008. ;
%let start_date = 01jan2009 ;

options linesize = 150 nocenter msglevel = i NOOVP formchar='|-++++++++++=|-/|<>*' ; ** dsoptions="note2err" ;

**options obs = 10000 ;
** ========================= END EDIT SECTION ================================= ;

libname out "&outloc" ;

%include vdw_macs ;

%** Obtain the list of pregnancy-related codes from the FTP server ;
filename preg_ftp  FTP     "pregnancy_codes.xpt"
                   HOST  = "vdw.hmoresearchnetwork.org"
                   CD    = "/vdwcode"
                   PASS  = "%2hilario36"
                   USER  = "VDWReader"
                   DEBUG
                   ;
libname preg_ftp xport ;

proc copy in = preg_ftp out = work ;
run ;

libname preg_ftp clear ;

%let delivery = 'D' ;

%** Pull the events. ;
proc sql ;
  create table dx as
  select d.mrn, adate
  from  &_vdw_dx as d INNER JOIN
        preg_dx as p
  on    d.dx = p.dx
  where d.adate ge "&start_date"d and
        p.sigs = &delivery
  ;

  create table px as
  select p.mrn, adate
  from  &_vdw_px as p INNER JOIN
        preg_px as pp
  on    p.px = pp.px AND
        p.px_codetype = pp.px_ct
  where p.adate ge "&start_date"d and
        pp.sigs = &delivery
  ;

  create table delivery_events as
  select *, 'dx' as source from dx
  UNION ALL
  select *, 'px' as source from px
  ;

  drop table dx ;
  drop table px ;

quit ;

** Limit events to women of at least minimal child-birthing age, to guard ;
** against babies getting e.g. "normal live birth" event codes. ;
proc sql ;
  create table de2 as
  select de.mrn, adate
  from delivery_events as de INNER JOIN
       &_vdw_demographic as d
  on   de.mrn = d.mrn
  where gender in ('F', 'f') and %calcage(BDtVar = birth_date, RefDate = adate) ge 12
  ;

  drop table delivery_events ;

quit ;

proc sort nodupkey data = de2 ;
  by mrn adate ;
run ;

** Reduce to single deliveries per pregnancy. This is far from perfect, but should ;
** serve for quick-n-dirty. ;
data deliveries ;
  retain _last_adate ;
  set de2 ;
  by mrn ;
  if not first.mrn then do ;
    if (adate - _last_adate) le 260 then delete ;
  end ;
  _last_adate = adate ;
run ;

ods html path = "&outloc" (URL=NONE)
         body = "&_SiteAbbr._hmorn_births.html"
         (title = "&_SiteAbbr Births output for Josie Briggs")
          ;

title1 "Number of births at or paid for by &_SiteName since &start_date.." ;
proc freq data = deliveries ;
  tables adate / missing out = out.&_SiteAbbr._delivery_counts ;
  format adate year4. ;
run ;

proc sql ;
  ** Mask any too-low counts. ;
  update out.&_SiteAbbr._delivery_counts
  set count = .a, percent = .a
  where count lt &lowest_count
  ;
  title1 "Here are the procedure codes used to signify deliveries." ;
  select * from preg_px
  where  sigs = &delivery
  ;
  title1 "Here are the diagnosis codes used to signify deliveries." ;
  select * from preg_dx
  where  sigs = &delivery
  ;
quit ;

ods _all_ close ;

