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
  set &_vdw_enroll (keep = mrn enr_: ins_:) ;
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
 */


/* Prepare the correlations coeff matrix: Pearson's r method */
%macro prepCorrData(in=,wtvar = wt, out=);
  /* Run corr matrix for input data, all numeric vars */
  proc corr data=&in. noprint
    pearson
    outp=work._tmpCorr
    vardef=df
  ;
    weight &wtvar ;
  run;

  /* prep data for heat map */
  data &out.;
    keep x y r;
    set work._tmpCorr(where=(_TYPE_="CORR"));
    array v{*} _numeric_;
    x = _NAME_;
    do i = dim(v) to 1 by -1;
      y = vname(v(i));
      r = v(i);
      /* creates a lower triangular matrix */
      if (i<_n_) then
        r=.;
      output;
    end;
  run;

  proc datasets lib=work nolist nowarn;
    delete _tmpcorr;
  quit;
%mend;



ods path work.mystore(update) sashelp.tmplmst(read);

proc template;
  define statgraph corrHeatmap;
   dynamic _Title;
    begingraph;
      entrytitle _Title;
      rangeattrmap name='map';
      /* select a series of colors that represent a "diverging"  */
      /* range of values: stronger on the ends, weaker in middle */
      /* Get ideas from http://colorbrewer.org                   */
      range -1 - 1 / rangecolormodel=(cx483D8B  cxFFFFFF cxDC143C);
      endrangeattrmap;
      rangeattrvar var=r attrvar=r attrmap='map';
      layout overlay /
        xaxisopts=(display=(line ticks tickvalues))
        yaxisopts=(display=(line ticks tickvalues));
        heatmapparm x = x y = y colorresponse = r /
          xbinaxis=false ybinaxis=false
          name = "heatmap" display=all;
        continuouslegend "heatmap" /
          orient = vertical location = outside title="Pearson Correlation";
      endlayout;
    endgraph;
  end;
run;


 options orientation = landscape ;

ods graphics / height = 6in width = 10in ;

* %let out_folder = //home/pardre1/ ;
%let out_folder = //groups/data/CTRHS/Crn/voc/enrollment/output/ ;

ods html path = "&out_folder" (URL=NONE)
         body   = "deleteme.html"
         (title = "deleteme output")
          ;

  %prepCorrData(in=s.gnu(keep = wt flg_:), out=insflgs);
  proc sgrender data=insflgs template=corrHeatmap;
    dynamic _title="Relationship Between Insurance Flags";
  run;

run ;

ods _all_ close ;


