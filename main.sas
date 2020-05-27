/*********************************************
* Roy Pardee
* Group Health Research Institute
* (206) 287-2078
* pardee.r@ghc.org
*
* //groups/data/CTRHS/Crn/voc/enrollment/programs/vdw_enroll_demog_qa.sas
*
* Does comprehensive QA checks for the HMORN VDW's Enrollment & Demographics files.
*
* Please see the workplan found here:
* https://www.hcsrn.org/share/page/site/VDW/wiki-page?title=Enroll-Demog-Lang%20QA%20for%20HCSRN%202016%20Annual%20Meeting
*
*********************************************/

* If roy forgets to comment this out, please do so.  Thanks/sorry! ;
* %include "h:/SAS/Scripts/remoteactivate.sas" ;

options
  linesize  = 150
  msglevel  = i
  formchar  = '|-++++++++++=|-/|<>*'
  /* dsoptions = note2err */
  nosqlremerge
  nocenter
  noovp
  mprint
  mlogic
  options extendobscounter = no ;
;

**************** begin edit section ****************************** ;
**************** begin edit section ****************************** ;
**************** begin edit section ****************************** ;

* This is a new comment to show Hsienlin about git!!! ;

* Undefine all libnames, just in case I rely on GHC-specific nonstandard ones downstream. ;
libname _all_ clear ;

* Please edit this to point to your local standard vars file. ;
%include "&GHRIDW_ROOT/Sasdata/CRN_VDW/lib/StdVars.sas" ;

* Please edit this so it points to the location where you unzipped the files/folders. ;
%let root = \\groups\data\CTRHS\Crn\voc\enrollment\programs ;

* Some sites are having trouble w/the calls to SGPlot--if you want to try to get the graphs please set this var to false. ;
* If you do and get errors, please keep it set to true. ;
%let skip_graphs = true ;
%let skip_graphs = false ;

* Please set start_year to your earliest date of enrollment data. ;
%let start_year = 1988 ;
* Please set end_year to the last complete year of data. ;
%let end_year = 2019 ;
%let end_year = %sysfunc(intnx(year, "&sysdate9"d, -1, end), year4.) ;

* Optional--set to a number of records or the string false to limit the number of records offending ;
* quality checks that get written to the DO_NOT_SEND folder. ;
%let limit_bad_output = 50 ;
%let limit_bad_output = false ;

* For the completeness graphs, what is the minimum monthly enrolled N we require ;
* before we are willing to plot the point? ;
%let min_n = 200 ;

/*

  If your VDW files are not in an rdbms you can ignore the rest of this edit
  section. If they are & you want to possibly save a ton of processing time,
  please read on.

  The bulk of the work of this program is done in a SQL join between VDW
  enrollment, a substantive VDW file (like rx or tumor), and a small utility
  dataset of the months between &start_year and &end_year.

  If you have the wherewithal to create this utility dataset on the db server
  where the rest of your VDW tables live, then SAS will (probably) pass the
  join work off to the db to complete, which is orders of magnitude faster than
  having SAS pull your tables into temp datasets & do the join on the SAS
  side. At Group Health (we use Teradata) making this change turned a job that
  ran in about 14 hours into one that runs in 15 *minutes*.

  TO DO SO, create a libname pointing at a db on the same server as VDW, to
  which you have CREATE TABLE permissions.  You can see what I used at GH
  commented-out, below.  I *believe* the 'connection = global' bit is necessary
  to get the join pushed to the db, and that it works for rdbms' other than
  Teradata, but am not positive.  I'd love to hear your experience if anybody
  tries this out.
*/

* libname mylib teradata
  user              = "&nuid@LDAP"
  password          = "&cspassword"
  server            = "&td_prod"
  schema            = "&nuid"
  multi_datasrc_opt = in_clause
  connection        = global
  tpt               = yes
  fastload          = yes
;

%let tmplib = work ;
* %let tmplib = mylib ;

****************** end edit section ****************************** ;
****************** end edit section ****************************** ;
****************** end edit section ****************************** ;

* Acceding to the CESR convention of spitting log out to sendable folder. ;
proc printto log = "&root/share/&_siteabbr._vdw_enroll_demog_qa.log" new ;
run ;

%include vdw_macs ;

%include "&root./lib/stack_datasets.sas" ;
%include "&root./lib/qa_formats.sas" ;
%include "&root./lib/vdw_lang_qa.sas" ;
%include "&root./lib/simple_data_rates_generic.sas" ;
%include "&root./lib/graph_data_rates.sas" ;

%include "&root./lib/vdw_enroll_demog_qa.sas" ;

