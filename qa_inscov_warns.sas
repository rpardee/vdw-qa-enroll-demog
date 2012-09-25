/*********************************************
* Roy Pardee
* Group Health Research Institute
* (206) 287-2078
* pardee.r@ghc.org
*
* C:\Documents and Settings\pardre1\Desktop\deleteme.sas
*
* <<purpose>>
*********************************************/

%include "\\home\pardre1\SAS\Scripts\remoteactivate.sas" ;

options
  linesize = 150
  nocenter
  msglevel = i
  NOOVP
  formchar = '|-++++++++++=|-/|<>*'
  dsoptions="note2err" NOSQLREMERGE
;

libname t '\\ctrhs-sas\SASUser\pardre1\vdw\voc_enroll\qa\stays\' ;

%let num_ins = 13 ;

proc format ;
  value it
    1  = "C"  /* ins_commercial      */
    2  = "B"  /* ins_basichealth     */
    3  = "P"  /* ins_privatepay      */
    4  = "S"  /* ins_statesubsidized */
    5  = "F"  /* ins_selffunded      */
    6  = "H"  /* ins_highdeductible  */
    7  = "I"  /* ins_medicaid        */
    8  = "A"  /* ins_medicare_a      */
    9  = "B"  /* ins_medicare_b      */
    10 = "C"  /* ins_medicare_c      */
    11 = "D"  /* ins_medicare_d      */
    12 = "E"  /* ins_medicare        */
    13 = "O"  /* ins_other           */
  ;
  value ct
    1  = "1"  /* ins_commercial      */
    2  = "0"  /* ins_basichealth     */
    3  = "1"  /* ins_privatepay      */
    4  = "1"  /* ins_statesubsidized */
    5  = "1"  /* ins_selffunded      */
    6  = "1"  /* ins_highdeductible  */
    7  = "1"  /* ins_medicaid        */
    8  = "0"  /* ins_medicare_a      */
    9  = "0"  /* ins_medicare_b      */
    10 = "0"  /* ins_medicare_c      */
    11 = "0"  /* ins_medicare_d      */
    12 = "1"  /* ins_medicare        */
    13 = "1"  /* ins_other           */
  ;
quit ;

data gnu ;
  length pattern $ 13 ;
  ** retain better_count 0 ;
  set t.inscov_warn ;
  pattern = '------------' ;
  ** if ins_basichealth = 'Y' then substr(pattern, 2) = 'B' ;
  array covgs{13} ins_commercial
                  ins_basichealth
                  ins_privatepay
                  ins_statesubsidized
                  ins_selffunded
                  ins_highdeductible
                  ins_medicaid
                  ins_medicare_a
                  ins_medicare_b
                  ins_medicare_c
                  ins_medicare_d
                  ins_medicare
                  ins_other
  ;
  better_count = 0 ;
  do i = 1 to 13 ;
    if covgs{i} = 'Y' then do ;
      substr(pattern, i) = put(i, it.) ;
      better_count + input(put(i, ct.), 1.0) ;
    end ;
    else substr(pattern, i) = '-' ;
  end ;
  label
    pattern = 'Pattern of insurance coverage flags'
  ;
  drop i ;
run ;

proc freq data = gnu order = freq ;
  tables better_count / missing ;
  tables pattern * count / missing format = 10.0 ;
  where better_count lt 1 or better_count gt 3 ;
run ;
