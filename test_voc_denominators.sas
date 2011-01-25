/*********************************************
* Roy Pardee
* Group Health Research Institute
* (206) 287-2078
* pardee.r@ghc.org
*
* \\groups\data\CTRHS\Crn\voc\enrollment\programs\test_voc_denominators.sas
*
* Drives the make_denoms macro.
*
*********************************************/

%include "\\home\pardre1\SAS\Scripts\remoteactivate.sas" ;

options linesize = 150 nocenter msglevel = i NOOVP formchar='|-++++++++++=|-/|<>*' dsoptions="note2err" NOSQLREMERGE ;

%let out_folder = \\groups\data\CTRHS\Crn\voc\enrollment\programs\ ;


%include "\\groups\data\CTRHS\Crn\voc\enrollment\programs\StdVars.sas" ;

%include "\\groups\data\ctrhs\crn\voc\enrollment\programs\voc_denominators.sas" ;

** options obs = 1000 mprint ;

%make_denoms(start_year = 2007, end_year = 2007, outset = s.test_denominators) ;
