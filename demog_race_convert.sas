/*********************************************
* Roy Pardee
* Group Health Research Institute
* (206) 287-2078
* pardee.r@ghc.org
*
* \\groups\data\CTRHS\Crn\voc\enrollment\programs\demog_race_convert
*
* Demonstrates a simple way to convert from the v2 (naaccr) race coding to the v3.
*
*********************************************/

%include "\\home\pardre1\SAS\Scripts\remoteactivate.sas" ;

options linesize = 150 nocenter msglevel = i NOOVP formchar='|-++++++++++=|-/|<>*' dsoptions="note2err" NOSQLREMERGE ;

%include "\\groups\data\CTRHS\Crn\S D R C\VDW\Macros\StdVars.sas" ;

proc format;
  value $Race
    '01'                            = 'WH'
    '02'                            = 'BA'
    '03'                            = 'IN'
    '04', '05', '06', '08', '09',
    '10', '11', '12', '13', '14',
    '96'                            = 'AS'
    '07', '20', '21', '22', '25',
    '26', '27', '28', '30', '31',
    '32', '97'                      = 'HP'
    Other                           = 'UN'
  ;

  value $prior
    'HP' = 1
    'IN' = 2
    'AS' = 3
    'BA' = 4
    'WH' = 5
    'MU' = 6
    'UN' = 7
  ;
run;

data norm_race ;
  set &_vdw_demographic (obs = 2000 where = (race2 not in ('88', '99'))) ;
  array r race: ;
  do i = 1 to 5 ;
    race    = put(r{i}, $race.) ;
    sortby  = put(race, $prior.) ;
    output ;
  end ;
run ;

proc sort data = norm_race ;
  by mrn sortby ;
run ;

proc transpose data = norm_race out = s.demog_v3_race_compatible(drop = _:) prefix = race ;
  var race ;
  by mrn hispanic gender birth_date ;
run ;
