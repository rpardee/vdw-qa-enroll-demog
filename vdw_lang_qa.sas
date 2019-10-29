
/*********************************************
* Paul Hitz
* Essentia Institute of Rural Health
* 218-786-1008
* phitz@eirh.org
*
* V:\VDW Shared Data\programs\crn.qa.programs\EnrlDemo\20130204\vdw_lang_qa.sas
*
* Does comprehensive QA checks for the HMORN VDW's Language file.
*
* This program is called from vdw_enroll_demog_qa.sas
*
* Persistant files create:
* to_stay.bad_lang ~ records that appear to be out of specification
* to_go.lang_stats ~ counts of records, languages, etc. in file
*
* dependencies:
* vdw_enroll_demog_qa.sas program
* vdw language table
*
*********************************************
* 				UPDATE LOG
*********************************************
*
*********************************************/

%macro lang_tier_one(inset = &_vdw_language) ;


  * create table for language checks;
  proc sql ;
    create table lang_checks
    (   description char(50)
      , problem char(50)
      , warn_lim numeric
      , fail_lim numeric
    ) ;

    insert into lang_checks (description, problem, warn_lim, fail_lim)
    select 'Valid values: ' || trim(name), 'bad value in ' || trim(name), 2, 5
    from expected_vars
    where dset = 'lang' and name not in ('mrn')
    ;
  quit;

  * bring in language table ;
  proc sort data = &inset out = lang_recs;
    by mrn lang_iso lang_usage ;
  run;

  * local table containing circumspect language records;
  data to_stay.bad_lang;
    set lang_recs;
    by mrn lang_iso lang_usage ;

    if put(lang_iso, $lang.) = 'bad' then do ;
      problem = "bad value in lang_iso" ;
      output to_stay.bad_lang ;
    end ;

    if put(lang_usage, $use.) = 'bad' then do ;
      problem = "bad value in lang_usage" ;
      output to_stay.bad_lang ;
    end ;

    if put(lang_primary, $flg.) = 'bad' then do ;
      problem = "bad value in lang_primary" ;
      output to_stay.bad_lang ;
    end ;

    if not first.lang_usage  or not last.lang_usage then do ;
      problem = "dup rec in lang_iso" ;
      output to_stay.bad_lang ;
    end ;

  run;

  * get rid of dups, we already reported on them ;
  proc sort data = lang_recs out = lang_recs_nd nodupkey;
    by mrn lang_iso lang_usage ;

  * mrns with multiple languages ;
  proc sort data = lang_recs out = lang_nd nodupkey;
  	by mrn lang_iso;
  data mult_lang;
    set lang_nd;
    by mrn ;
	if first.mrn then
		lang_cnt = 0;
	if not first.mrn or not last.mrn;
	lang_cnt + 1;
  run;

  * report counts on the language table ;
  proc sql;
	create table to_go.&_siteabbr._lang_stats as
	select
	  a.lr as lang_recs label 'records in lang file'
	  , a1.subj as lang_subj label 'unique mrns in file'
	  , b.subj_eng as lang_eng label 'unique english speakers in file'
	  , b1.subj_ne as lang_ne label 'unique not english speakers in file'
	  , c.subj_mult_lang as lang_mult label 'mrns with > 1 language'
	  , d.subj_mult_use as use_mult label 'mrns with > 1 use'
	  , max(e.xtra_lan) as max_lang label 'max # lang for an mrn'
	  , f.lang_count label 'unique languages in file'
    from
      (select count(*) as lr from lang_recs) a
      , (select count(distinct(mrn)) as subj from lang_recs ) a1
      , (select count(distinct(mrn)) as subj_eng from lang_recs where lang_iso = 'eng') b
      , (select count(distinct(mrn)) as subj_ne from lang_recs where lang_iso ne 'eng') b1
      , (select count(distinct(mrn)) as subj_mult_lang from mult_lang) c
	  , (select count(distinct(mrn)) as subj_mult_use from mult_lang where lang_usage = 'B') d
	  , (select max(lang_cnt) as xtra_lan from mult_lang) e
	  , (select count(distinct(lang_iso)) as lang_count from lang_recs) f
    ;

	select lang_recs into :num_lang_recs from to_go.&_siteabbr._lang_stats ;

	create table bad_lang_summary as
	select problem, count(*) as num_bad, (count(*) / &num_lang_recs) * 100 as percent_bad
	from to_stay.bad_lang
	group by problem
	;

	   select problem
    into :unexpected_problems separated by ', '
    from bad_lang_summary
    where problem not in (select problem from lang_checks)
    ;

	create table lang_rbr_checks as
    select e.*
        , coalesce(num_bad, 0) as num_bad format = comma14.0
        , coalesce(percent_bad, 0) as percent_bad format = 8.2
        , case
            when percent_bad gt fail_lim then 'fail'
            when percent_bad gt warn_lim then 'warning'
            else 'pass'
          end as result
    from  lang_checks as e LEFT JOIN
          bad_lang_summary as b
    on    e.problem = b.problem
    ;

    insert into results (description, qa_macro, detail_dset, num_bad, percent_bad, result)
    select description, '%lang_tier_one', 'to_stay.bad_lang', num_bad, percent_bad, result
    from lang_rbr_checks
    ;

  quit;


%mend lang_tier_one;

* here for ease of testing
%lang_tier_one;

%macro count_items(inds = &syslast);

  %global temp_cnt;

  data _null_;
    call symput('temp_cnt' ,nobs);
    set &inds nobs=nobs;
  run;

%mend count_items;

