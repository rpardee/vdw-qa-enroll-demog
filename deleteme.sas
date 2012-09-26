/*********************************************
* Roy Pardee
* Group Health Research Institute
* (206) 287-2078
* pardee.r@ghc.org
*
* /C/Documents and Settings/pardre1/My Documents/vdw/voc_enroll/deleteme.sas
*
* purpose
*********************************************/

* %include "\\home\pardre1\SAS\Scripts\remoteactivate.sas" ;

options
  linesize  = 150
  msglevel  = i
  formchar  = '|-++++++++++=|-/|<>*'
  dsoptions = note2err
  nocenter
  noovp
  nosqlremerge
;

data flags ;
  length cat $ 4 ;
  input
    @1    ins_medicare_a $char1.
    @3    ins_medicare_b $char1.
    @5    ins_medicare_c $char1.
    @7    ins_medicare_d $char1.
  ;
  * Mash them together ;
  cat = cats(ins_medicare_a, ins_medicare_b, ins_medicare_c, ins_medicare_d) ;
  * Strain out anything thats not a 'Y'es ;
  * comp = compress(cat ,'Y', 'k') ;
  * Length of result should be the number of Ys right? ;
  * lenny = length(compress(comp)) ;
  num_set = countc(cat, 'Y') ;
datalines ;
Y Y N N
Y N N N
N N Y N
N N N N
run ;

proc print ;
run ;

endsas ;

data s.test ;
  length cat $ 4 ;
  set vdw.enroll2(obs = 20) ;
  if _n_ = 2 then ins_medicare_c = 'Y' ;
  cat = cats(ins_medicare_a, ins_medicare_b, ins_medicare_c, ins_medicare_d) ;
  comp = compress(cat ,'Y', 'k') ;
  lenny = length(compress(comp)) ;

  keep ins_medicare_: cat comp lenny
  ;

run ;
