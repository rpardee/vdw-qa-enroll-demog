/*********************************************
* Roy Pardee
* Center For Health Studies
* (206) 287-2078
* pardee.r@ghc.org
*
* voc_enroll_contents.sas
*
* Reconciles the contents of a sites enroll file against the currnent spec, warning
* of any missing variables & inviting the SDM to expound on any extra ones.
*
* The strong suspicion is that some large proportion of VDW sites have already implemented
* extra vars touching on expected "completeness of the automated data record".  The
* enroll/demog VOC subcommittee would like to have a quick overview of those (and other)
* vars to see if we can quickly harmonize definitions and expand the spec.
*
*********************************************/

* ======================== BEGIN EDIT SECTION ================================ ;

* PLEASE COMMENT OUT THE FOLLOWING LINE IF ROY FORGETS TO (SORRY!) ;
%*include "\\home\pardre1\SAS\Scripts\dw_login.sas" ;

* Your local copy of StdVars.sas ;
%include "\\groups\data\CTRHS\Crn\S D R C\VDW\Macros\StdVars.sas" ;

options linesize = 150 nocenter msglevel = i NOOVP formchar='|-++++++++++=|-/|<>*' dsoptions="note2err" ;

* Where to put the html output: ;
%let outpath = \\home\pardre1\ ;

* ========================= END EDIT SECTION ================================= ;

libname enr "&_EnrollLib" ;

data spec_vars ;
  input
    @1 name $char14.
    @17 type $char4.
    @23 length
  ;
datalines ;
mrn             char  .
enr_start       num   8
enr_end         num   8
ins_medicare    char  1
ins_medicaid    char  1
ins_commercial  char  1
ins_privatepay  char  1
ins_other       char  1
drugcov         char  1
;
run ;

/*

extra vars @ gh:

  ins_basichealth char  1
  mainnet         char  2
  primrydr        char  6
  location        char  3
  prmcrcln        char  3

*/

* proc print ;
run ;

%macro report_vars ;

  proc sql ;

    describe table dictionary.columns ;

    create table vars_here as
    select memname, name, type, length, label, format, sortedby
    from dictionary.columns
    where libname = 'ENR' AND
          memname = %upcase("&_EnrollData") AND
          memtype in ('DATA', 'VIEW')
    ;

    create table missing_vars as
    select *
    from spec_vars
    where upcase(name) not in (select upcase(name) from vars_here)
    ;

    %if &sqlobs > 0 %then %do ;
      title1 "WARNING!  These variables from the spec seem to be missing from &_EnrollLib./&_EnrollData.!!!" ;
      select *
      from missing_vars
      ;
      %put WARNING: You seem to be missing variables!  See .lst file for details! ;
      %put WARNING: You seem to be missing variables!  See .lst file for details! ;
      %put WARNING: You seem to be missing variables!  See .lst file for details! ;
      %put WARNING: You seem to be missing variables!  See .lst file for details! ;
      %put WARNING: You seem to be missing variables!  See .lst file for details! ;
      %put WARNING: You seem to be missing variables!  See .lst file for details! ;
      %put WARNING: You seem to be missing variables!  See .lst file for details! ;
      %put WARNING: You seem to be missing variables!  See .lst file for details! ;
    %end ;

    title1 "Extra variables at &_SiteName.:" ;
    select *
    from vars_here
    where upcase(name) not in (select upcase(name) from spec_vars)
    ;

  quit ;
%mend report_vars ;


ods html path = "&outpath" (URL=NONE)
         body = "voc_enroll_contents.html"
         (title = "voc_enroll_contents output")
          ;

  %report_vars ;
run ;
ods html close ;

