/*********************************************
* Roy Pardee
* Group Health Research Institute
* (206) 287-2078
* pardee.r@ghc.org
*
* C:\Users/pardre1/Desktop/deleteme.sas
*
*
*********************************************/

options
  linesize  = 150
  msglevel  = i
  formchar  = '|-++++++++++=|-/|<>*'
  dsoptions = note2err
  nocenter
  noovp
  nosqlremerge
;

data original ;
  length clinic_name $ 20 ;
  do clinic_name = "North", "South", "East", "West" /* , "Dixon", "McCauliff", "Duxbury", "Sorbonne" */ ;
    do year = 2000 to 2014 ;
      num_visits = 400 + ceil(uniform(42) * 300) ;
      if clinic_name = "East" then num_visits = num_visits * 10 ;
      output ;
    end ;
  end ;
  format num_visits comma9.0 ;
run ;

data second_y_axis ;
  set original ;
  if clinic_name = "East" then do ;
    high_count = num_visits ;
    num_visits = . ;
  end ;
  format high_count comma9.0 ;
run ;

* %let out_folder = ~/ ;
%let out_folder = c:/temp ;

ods graphics / height = 6in width = 10in ;

ods html path = "&out_folder" (URL=NONE)
         body   = "keylegend_bug.html"
         (title = "Keylegend bug?")
          ;

  %let lattr = %str(lineattrs = (pattern = solid thickness = 2mm)) ;

  title1 "All Clinics on Same Axis" ;
  proc sgplot data = original ;
    series x = year y = num_visits / group = clinic_name &lattr ;
    xaxis grid type = discrete ;
    yaxis grid ;
  run ;

  title1 "Big Clinic on Second Axis" ;
  proc sgplot data = second_y_axis ;
    series x = year y = num_visits / group = clinic_name &lattr ;
    series x = year y = high_count / group = clinic_name &lattr y2axis ;
    xaxis grid type = discrete ;
    yaxis  grid values = (0 to 1100 by 100) ;
    y2axis grid values = (0 to 8000 by 1000) ;
  run ;

  title1 "Big Clinic on Second Axis (with keylegend--note that clinics are listed twice)" ;
  proc sgplot data = second_y_axis nocycleattrs ;
    series x = year y = num_visits / group = clinic_name &lattr name='visits' ;
    series x = year y = high_count / group = clinic_name &lattr y2axis /* curvelabel <-- seems to cure it! */ ;
    xaxis grid type = discrete ;
    yaxis  grid values = (0 to 1100 by 100) ;
    y2axis grid values = (0 to 8000 by 1000) ;
    keylegend 'visits' / noborder ;
  run ;



run ;

ods _all_ close ;

