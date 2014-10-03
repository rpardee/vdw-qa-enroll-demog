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

options orientation = landscape ;

libname col "\\groups\data\CTRHS\Crn\voc\enrollment\programs\qa_results" ;


proc template;
  define statgraph corrHeatmap;
   dynamic _BYVAL_ ;
    begingraph;
      entrytitle _BYVAL_ ;
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

%let out_folder = %sysfunc(pathname(s)) ;
ods graphics / imagename = "flagcorr" ;
ods html path = "&out_folder" (URL=NONE)
         body   = "deleteme.html"
         (title = "deleteme output")
          ;
option nobyline ;

proc sgrender data=col.flagcorr template=corrHeatmap ;
  by site ;
  where site ne 'PAMF' ;
run;

ods _all_ close ;
