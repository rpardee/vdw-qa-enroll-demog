/*********************************************
* Roy Pardee
* Group Health Research Institute
* (206) 287-2078
* pardee.r@ghc.org
*
* \\groups\data\CTRHS\Crn\voc\enrollment\programs\fake_v3_demog.sas
*
* <<purpose>>
*********************************************/

%include "\\home\pardre1\SAS\Scripts\remoteactivate.sas" ;

options linesize = 150 nocenter msglevel = i NOOVP formchar='|-++++++++++=|-/|<>*' dsoptions="note2err" NOSQLREMERGE ;


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
  ** set vdw.demog(obs = 200 where = (race2 not in ('88', '99'))) ;
  set vdw.demog ; ** (obs = 2000 where = (race2 not in ('88', '99'))) ;
  array r race: ;
  if hispanic = '' then hispanic = 'U' ;
  needs_interpreter = 'N' ;
  primary_language = 'eng' ;
  do i = 1 to 5 ;
    race    = put(r{i}, $race.) ;
    sortby  = put(race, $prior.) ;
    output ;
  end ;
run ;

proc sort data = norm_race ;
  by mrn sortby ;
run ;

proc transpose data = norm_race out = s.fake_demog3(drop = _:) prefix = race ;
  var race ;
  by mrn hispanic gender birth_date needs_interpreter primary_language ;
run ;
