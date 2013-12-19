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
/*
data gnu ;
  length
    flg_basichealth
    flg_commercial
    flg_highdeductible
    flg_medicaid
    flg_medicare
    flg_medicare_a
    flg_medicare_b
    flg_medicare_c
    flg_medicare_d
    flg_other
    flg_privatepay
    flg_selffunded
    flg_statesubsidized 3
  ;
  set &_vdw_enroll (obs = 3000 keep = mrn enr_: ins_:) ;
  array ins ins_basichealth ins_commercial ins_highdeductible ins_medicaid ins_medicare ins_medicare_a ins_medicare_b ins_medicare_c ins_medicare_d ins_other ins_privatepay ins_selffunded ins_statesubsidized ;
  array flg flg_basichealth flg_commercial flg_highdeductible flg_medicaid flg_medicare flg_medicare_a flg_medicare_b flg_medicare_c flg_medicare_d flg_other flg_privatepay flg_selffunded flg_statesubsidized ;
  do i = 1 to dim(ins) ;
    flg{i} = (ins{i} = 'Y') ;
    wt = intck('month', enr_start, enr_end) + 1 ;
  end ;
  keep mrn wt enr_: flg_: ;
run ;

data s.gnu ;
  set gnu ;
run ;

 */options orientation = landscape ;

ods graphics / height = 6in width = 10in ;

* %let out_folder = //home/pardre1/ ;
%let out_folder = //groups/data/CTRHS/Crn/voc/enrollment/output/ ;

ods html path = "&out_folder" (URL=NONE)
         body   = "deleteme.html"
         (title = "deleteme output")
          ;

* ods rtf file = "&out_folder.deleteme.rtf" device = sasemf ;


/* proc corr data = s.gnu noprob nosimple best = 4 ;
  var flg_: ;
  weight wt ;
run ;
 */
proc corr data = s.gnu noprob nosimple plots = matrix ;
  var flg_: ;
  weight wt ;
run ;

run ;

ods _all_ close ;


