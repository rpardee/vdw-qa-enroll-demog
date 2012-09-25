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


%include "\\groups\data\CTRHS\Crn\voc\enrollment\programs\StdVars.sas" ;

%**include "\\groups\data\ctrhs\crn\voc\enrollment\programs\voc_denominators.sas" ;
%include "\\groups\data\CTRHS\Crn\S D R C\VDW\Macros\standard_macros.sas" ;

** options obs = 1000 mprint ;

%make_denoms(start_year = 2007, end_year = 2010, outset = s.test_denominators) ;
