/*********************************************
* Roy Pardee
* KP Washington Health Research Institute
* (206) 287-2078
* roy.e.pardee@kp.org
*
* C:\Users/pardre1/Documents/vdw/voc_enroll/site_edits_template.sas
*
* Rather than have a special edit section in the main sas program this job
* expects all site-environment-setting to happen in a separate sas program
* called site_edits.sas.  This file is a *template* for that one.
* The idea is to put that file outside of git version control, so it doesnt
* get stomped when the package gets updated.  That way you can grab down
* updates from github and not have to re-do the edits here.
* So--two steps:
*   1. make a copy of this file in this same directory, called site_edits.sas
*   2. edit that so it e.g., points to your stdvars, sets parameters as you
*      like them, etc.
*********************************************/

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

* Undefine all libnames, just in case I rely on GHC-specific nonstandard ones downstream. ;
libname _all_ clear ;

* Please edit this to point to your local standard vars file. ;
%include "&GHRIDW_ROOT/Sasdata/CRN_VDW/lib/StdVars.sas" ;

* Please edit this so it points to the location where you unzipped the files/folders. ;
%let root = //groups/data/CTRHS/Crn/voc/enrollment/programs/ghc_qa ;

* Some sites are having trouble w/the calls to SGPlot--if you want to try to get the graphs please set this var to false. ;
* If you do and get errors, please keep it set to true. ;
%let skip_graphs = false ;
%let skip_graphs = true ;

* Please set start_year to your earliest date of enrollment data. ;
%let start_year = 1988 ;
%let end_year = 2018 ;
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
  user              = "&username@LDAP"
  password          = "&password"
  server            = "&td_prod"
  schema            = "%sysget(username)"
  multi_datasrc_opt = in_clause
  connection        = global
  tpt               = yes
  fastload          = yes
;

* %let tmplib = mylib ;
%let tmplib = work ;

