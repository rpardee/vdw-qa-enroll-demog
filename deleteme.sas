/*********************************************
* Roy Pardee
* Group Health Research Institute
* (206) 287-2078
* pardee.r@ghc.org
*
* //groups/data/CTRHS/Crn/voc/enrollment/programs/deleteme.sas
*
* purpose
*********************************************/

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



%include "//ghrisas/Warehouse/Sasdata/CRN_VDW/lib/StdVars.sas" ;

libname s "//ghrisas/SASUser/pardre1" ;
libname ms "\\ghrisas\Warehouse\sasdata\Sentinel_CDM\Tables" ;


proc format ;
  ** For setting priority order to favor values of Y. ;
  value $dc
    'Y'   = 'A'
    'N'   = 'B'
    other = 'C'
  ;
  ** For translating back to permissible values of DrugCov ;
  value $cd
    'A' = 'Y'
    'B' = 'N'
    'C' = 'U'
  ;
quit ;


  * 01-dec-2008 through 30-mar-2009 ;
  data all_years ;
    do i = 0 to 14 ;
      first_day = intnx('month', '01-jan-2008'd, i, 'beg') ;
      last_day = intnx('month', '01-dec-2008'd, i, 'end') ;
      num_days  = last_day - first_day + 1 ;
      mo = first_day ;
      output ;
    end ;
    format first_day last_day mmddyy10. mo monyy7. ;
  run ;

  proc sql noexec ;
    /*
      Dig this funky join--its kind of a cartesian product, limited to
      enroll records that overlap the year from all_years.
      enrolled_proportion is the # of days between <<earliest of enr_end and last-day-of-year>>
      and <<latest of enr_start and first-day-of-year>> divided by the number of
      days in the year.

      Nice thing here is we can do calcs on all the years desired in a single
      statement.  I was concerned about perf, but this ran quite quickly--the
      whole program took about 4 minutes of wall clock time to do 1998 - 2007 @ GH.

    */
    create table s.gnu as
    select  mo
          , drugcov
          , sum((min(enr_end, last_day) - max(enr_start, first_day) + 1) / num_days) as enrolled_proportion
    from  ms.enrollment /* (obs = 2000) */ as e INNER JOIN
          all_years as y
    on    e.enr_start le y.last_day AND
          e.enr_end   ge y.first_day
    group by mo, drugcov
    ;

  quit ;

proc freq data = ms.enrollment noprint ;
  tables enr_end * drugcov / missing format = comma9.0 out = s.ms_gnu ;
  where enr_end between '01-may-2008'd and '30-mar-2009'd ;
run ;


options orientation = landscape ;

* ods graphics / height = 6in width = 10in ;

* %let out_folder = //home/pardre1/ ;
%let out_folder = //groups/data/CTRHS/Crn/voc/enrollment/output/ ;

ods html path = "&out_folder" (URL=NONE)
         body   = "deleteme.html"
         (title = "deleteme output")
          ;

* ods rtf file = "&out_folder.deleteme.rtf" device = sasemf ;

* Put this line before opening any ODS destinations. ;
options orientation = landscape ;

  ods graphics / height = 6in width = 10in ;

  proc sgplot data = s.ms_gnu ;
    * scatter x = adate y = source_count / group = source ;
    * loess x = adate y = source_count / group = source ;
    series x = mo y = enrolled_proportion / group = drugcov lineattrs = (thickness = .1 CM) ;
    * xaxis values = (&earliest to "31dec2010"d by month ) ;
    format enrolled_proportion comma9.0 ;
    * where put(drugcov, $cd.) = 'Y' ;
    xaxis grid values = ('01-may-2008'd to '30-mar-2009'd by month) label = "Month" ;
    yaxis grid label = "Enrolled People" ;
  run ;


run ;

ods _all_ close ;
