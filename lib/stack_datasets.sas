/*********************************************
* Roy Pardee
* Group Health Research Institute
* (206) 287-2078
* pardee.r@ghc.org
*
* C:\Documents and Settings\pardre1\Desktop\stack_datasets.sas
*
* Examples code for collating results.
*********************************************/

%macro stack_datasets(inlib =, nom = , outlib = , srcvar = site, outnom = , delete_insets = no) ;
  ** All input datasets live in inlib.
  ** All input dataset names begin with <<site abbreviation>>_ and end with the text passed in the nom parameter. ;
  ** This guy creates a big old UNION query against them all and then executes it to create a dataset named <<nom>> in the outlib library. ;

  ** New param srcvar: name the var in the output dataset that signifies the name of the input dataset. ;
  ** New param outnom: name the output dataset. ;
  ** New param delete_insets: remove the datasets that contributed to the output. ;

  %if &outnom = %then %let outnom = &nom ;

  %removedset(dset = &outlib..&outnom) ;

  %local i rgx ;
  %let rgx = (.*)_&nom.\s*$ ;

  proc sql ;
    ** create table s.drop_me as    select *    from dictionary.tables    ;

    ** Do we have any dsets w/0 vars?  These will cause barfage. ;
    create table __novars as
    select memname label = "THESE DATASETS HAVE 0 VARIABLES AND CANNOT BE USED!!!", memlabel
    from dictionary.tables
    where libname = "%upcase(&inlib)" AND
          nvar = 0 AND
          prxmatch("/&rgx./i", memname) > 0
    ;

    %if &sqlobs > 0 %then %do ;
      %do i = 1 %to 5 ;
        %put WARNING: There are %trim(&sqlobs) datasets in &inlib that have 0 variables.  See the output for a list. ;
      %end ;
      select * from __novars ;
    %end ;

    drop table __novars ;

    reset noprint feedback ;

    select memname as dset
         , 'select *, "' || prxchange("s/&rgx./$1/i", -1, memname) || '" as &srcvar from ' || "&inlib.." || memname as sequel
         ,                  prxchange("s/&rgx./$1/i", -1, memname) as &srcvar
    into   :dset1-:dset100
         , :union_stmt separated by ' UNION ALL CORRESPONDING '
         , :sitelist separated by ', '
    from dictionary.tables
    where libname = "%upcase(&inlib)" AND
          nvar > 0 AND
          prxmatch("/&rgx./i", memname) > 0
    ;

    %let num_inputs = &sqlobs ;

    %if &num_inputs = 0 %then %do ;
      %do i = 1 %to 5 ;
        %put ERROR: No datasets whose names end with "%trim(&nom)" found in input location %sysfunc(pathname(&inlib)) !!! ;
      %end ;
      reset print ;
      select libname, memname, '%' || "%upcase(&nom)" as match_expression, memlabel
      from dictionary.tables
      ;

    %end ;
    %else %do ;
      create table &outlib..&outnom as
      &union_stmt
      ;
      %if &delete_insets = yes %then %do i = 1 %to &num_inputs ;
        drop table &inlib..&&dset&i ;
      %end ;
    %end ;
  quit ;

  * SQL UNION does well w/var lengths--takes max one, which is great. ;
  * Its less great w/formats though--those dont get maxed out. ;
  * Removing them so they dont print truncated & cause confusion. ;
  proc datasets nolist library = &outlib ;
    modify &outnom ;
    attrib _character_ format= ;
  run ;

%mend stack_datasets ;


