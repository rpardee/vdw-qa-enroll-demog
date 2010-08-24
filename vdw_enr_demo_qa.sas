/*******************************************************************************
*  DATE: 08/19/2008                                                            *
*  AUTHOR: Paul Hitz                                                           *
*          Marshfield Clinic                                                   *
*          hitz.paul@marshfieldclinic.org                                      *
*          (715) 771 - 8871                                                    *
*  PROGRAM: vdw_enr_demo_qa.sas                                                *
*                                                                              *
*  Creates a file of counts and statitics on the enrollment and demo-          *
*  graphic information in the VDW.                                             *
*                                                                              *
*******************************************************************************/

* =========================== BEGIN EDIT SECTION ============================= ;

%include "\\home\pardre1\SAS\Scripts\dw_login.sas" ;

** Your local copy of StdVars.sas ;
%**include "\\groups\data\CTRHS\Crn\S D R C\VDW\Macros\StdVars.sas" ;

** Testing out a new enrollment process. ;
%include "\\groups\data\CTRHS\Crn\voc\enrollment\programs\StdVars.sas" ;

** Destination for the output dataset of denominators.                          ;
%LET send_loc = \\ctrhs-sas\sasuser\pardre1\vdw\voc_enroll\requested ;
libname libsend "&send_loc";
libname libkeep '\\ctrhs-sas\sasuser\pardre1\vdw\voc_enroll';/* Local file, contains MRNs */

options linesize = 150 nocenter msglevel = i NOOVP formchar='|-++++++++++=|-/|<>*' dsoptions="note2err" ;
* ========================= END EDIT SECTION ================================= ;
%include vdw_macs ;
%let round_to = 0.0001 ;

proc printto log="&send_loc.\log.log" new ;
run;

PROC FORMAT;
	value $Race
      '01' = '5 White'
      '02' = '4 Black or African American'
      '03' = '1 American Indian/Alaska Native'
      '04'
      , '05'
      , '06'
      , '08'
      , '09'
      , '10'
      , '11'
      , '12'
      , '13'
      , '14'
      , '96' = '2 Asian'
        '07'
      , '20'
      , '21'
      , '22'
      , '25'
      , '26'
      , '27'
      , '28'
      , '30'
      , '31'
      , '32'
      , '97' = '3 Native Hawaiian or Other Pacific Islander'
        '-1' = '6 More than one race'
      Other = '7 Unknown or Not Reported'
    ;
    value msk
      0 - 4 = '< 5'
      other = [comma15.2]
    ;
    * 0-17, 18-64, 65+ ;
    value agecat
      low -< 18 = '0 to 17'
      18  -< 65 = '18 to 64'
      65 - high = '65+'
    ;
    * For setting priority order to favor values of Y. ;
    value $dc
      'Y'   = 'A'
      'N'   = 'B'
      other = 'C'
    ;
    * For translating back to permissible values of DrugCov ;
    value $cd
      'A' = 'Y'
      'B' = 'N'
      'C' = ' '
    ;
    value $RaceT
      '01' = 'White'
      '02' = 'Black'
      '03' = 'Native'
      '04'
      , '05'
      , '06'
      , '08'
      , '09'
      , '10'
      , '11'
      , '12'
      , '13'
      , '14'
      , '96' = 'Asian'
        '07'
      , '20'
      , '21'
      , '22'
      , '25'
      , '26'
      , '27'
      , '28'
      , '30'
      , '31'
      , '32'
      , '97' = 'Pac Isl' /* Native Hawaiian or Other Pacific Islander */
      Other = 'Unknown' /* Unknown or Not Reported */
    ;
QUIT;

PROC CONTENTS DATA = &_vdw_enroll OUT = libsend.enrl_contents_&_SiteAbbr ;
RUN;

%MACRO qa();
/*Check that all mrns in enrollment are in demographics                       */
/*The enr_not_in_demo data set should have 0 records.                         */
PROC SORT DATA = &_vdw_enroll OUT = mem_enrl;
	BY mrn enr_start enr_end;
PROC SORT DATA = &_vdw_demographic OUT = mem_demo;
	BY mrn;
DATA libkeep.enr_not_in_demo;
	MERGE mem_enrl (IN = a) mem_demo (IN = b);
	BY mrn;
	IF a AND NOT b;
	e_type = 'enr not in demo';
RUN;

/*Check for duplicate mrns in demo file.  The dup_demo_mrn should have 0 recs.*/
DATA libkeep.dup_demo_mrn;
	SET mem_demo;
	BY mrn;
	IF NOT FIRST.mrn;
	e_type = 'dup demo mrn';
RUN;

/*Check that all enrollment end dates are greater than the start dates.       */
/*The start_end_error data set should have 0 records.                         */
DATA libkeep.start_end_error;
	SET mem_enrl;
	BY mrn;
	IF enr_end < enr_start;
	e_type = 'start end error';
RUN;

/*Check that there are no future dates in the enr_start or enr_end fields.    */
/*As we have already ascertained that enr_end is greater than enr_start only  */
/*the enr_end date needs to be checked. end_date_error data set should have 0 */
/*records.                                                                    */
DATA libkeep.end_date_error;
	SET mem_enrl;
	BY mrn;
	IF enr_end > TODAY();
	e_type = 'end_date_error';
RUN;

/*Check that there an mrn does not have two equal start dates.  The start_date*/
/*_error data set should have 0 records.                                      */
DATA libkeep.start_date_error;
	SET mem_enrl;
	BY mrn enr_start;
	IF NOT FIRST.enr_start;
	e_type = 'start date error';
RUN;

/*Check that there are no overlaps in the coverage.  The enr_overlap_error    */
/*data set should have 0 records.                                             */
DATA libkeep.enr_overlap_error;
	RETAIN save_end;
	SET mem_enrl;
	IF FIRST.mrn THEN save_end = enr_start;
	BY mrn;
	IF enr_start < save_end THEN OUTPUT;
	save_end = enr_end;
	e_type = 'enr overlap error';
RUN;

/*Check that the values for the gender field in the demographics file contain */
/*valid values.  The gender_error data set should have 0 records.             */
%LET valid_gender = 'M', 'F', 'O', 'T', 'U';
DATA libkeep.gender_error;
	SET mem_demo;
	IF gender NOT IN (&valid_gender);
	e_type = 'gender error';
RUN;

/*Check that the values for the race field in the demographics file contain   */
/*valid values.  The race_error data set should have 0 records.               */
%LET valid_race = '01', '02', '03', '04', '05', '06', '07',
				'08', '09', '10', '11', '12', '13', '14',
				'20', '21', '22', '25', '26', '27', '28',
				'30', '31', '32', '96', '97', '98', '99';

DATA libkeep.race_error;
	SET mem_demo;
	IF race1 NOT IN (&valid_race.)
		OR race2 NOT IN (&valid_race.)
		OR race3 NOT IN (&valid_race.)
		OR race4 NOT IN (&valid_race.)
		OR race5 NOT IN (&valid_race.);
	e_type = 'race error';
RUN;

/*Check that the values for the hispanic field in the demographics file have  */
/*valid values.  The hispanic_error data set should have 0 records.           */
%LET valid_ynb = 'Y', 'N', ' ';
DATA libkeep.hispanic_error;
	SET mem_demo;
	IF hispanic NOT IN (&valid_ynb);
	e_type = 'hispanic error';
RUN;

/*Check that the values for the drug coverage fields in the enrollment file   */
/*contain valid values.  The drugcov_error data set should have 0 records.    */
DATA libkeep.drugcov_error;
	SET mem_enrl;
	IF drugcov NOT IN (&valid_ynb);
	e_type = 'drugcov error';
RUN;

/*Check that the values for the insurance flag fields in the enrollment file  */
/*have valid values.  The inscov_error data set should have 0 records.        */
%LET valid_yb = 'Y', ' ';
DATA libkeep.inscov_error;
	SET mem_enrl;
	IF ins_medicare NOT IN (&valid_yb.)
		OR ins_medicaid NOT IN (&valid_yb.)
		OR ins_commercial NOT IN (&valid_yb.)
		OR ins_privatepay NOT IN (&valid_yb.)
		OR ins_other NOT IN (&valid_yb.);
	e_type = 'inscov error';
RUN;

/*Check if there is less than one or more than three ins_ flags set to "Y".   */
DATA libkeep.inscov_warn;
	SET mem_enrl;
	count = 0;
	IF ins_medicare = "Y" THEN count + 1;
	IF ins_medicaid = "Y" THEN count + 1;
	IF ins_commercial = "Y" THEN count + 1;
	IF ins_privatepay = "Y" THEN count + 1;
	IF ins_other = "Y" THEN count + 1;
	IF count < 1 OR count > 3;
	e_type = 'inscov warn';
RUN;

/* This is a summary file telling where the errors exist */
DATA libsend.qa_error_warn_&_SiteAbbr (KEEP = e_type);
	FORMAT e_type $30.;
	SET libkeep.enr_not_in_demo libkeep.dup_demo_mrn libkeep.start_end_error
		libkeep.end_date_error libkeep.start_date_error libkeep.enr_overlap_error
		libkeep.gender_error libkeep.race_error libkeep.hispanic_error
		libkeep.drugcov_error libkeep.inscov_error libkeep.inscov_warn;
	BY e_type;
	IF FIRST.e_type;
RUN;


%MEND qa;


/*Test file macro, creates a test file of file_size/inc records.              */
/*Call macro with tst_file set to the file that you want to create the test   */
/*data set from (enrollment or demographics) and the increment (1000 would be */
/*a test data set of tst_file/1000).  The data set will be created with random*/
/*records, from the original.  Uncomment call below and change inc value.     */
%MACRO tst_data(tst_file, inc);

%IF &tst_file. = enrollment %THEN %DO;
	%LET infile = &_vdw_enroll;
%END;

%IF &tst_file. = demographics %THEN %DO;
	%LET infile = &_vdw_demographic;
%END;

DATA libkeep.&tst_file._test (DROP = obsleft sampsize);
	sampsize = CEIL(totobs / &inc.);
	obsleft = totobs;
	DO WHILE (sampsize GT 0 AND obsleft GT 0);
		pickit + 1;
		IF RANUNI (0) LT (sampsize / obsleft) THEN
		DO;
			SET &infile. POINT = pickit
								NOBS = totobs;
			OUTPUT;
			sampsize = sampsize - 1;
		END;
		obsleft = obsleft - 1;
	END;
	STOP;
RUN;

%MEND tst_data;



/*%MACRO mem_gap_rm(gap, study_start, study_end);*/
%MACRO mem_gap_rm(gap, gap_file);
%PUT &gap;
/* Remove gaps in coverage of less than &gap.                                 */
PROC SORT DATA = &gap_file OUT = mem_enr;
	BY mrn enr_start enr_end;
DATA libkeep.mem_gap_rm (DROP = enr_start enr_end
				RENAME = (strt_lag = enr_start stop_lag = enr_end));
	LENGTH mrn $8.;
	RETAIN strt_lag	stop_lag;
	FORMAT strt_lag stop_lag MMDDYY10.;
	SET mem_enr;
	BY mrn;
	IF NOT FIRST.mrn THEN
	DO;
		IF enr_start LE stop_lag + &gap. THEN
			enr_start = strt_lag;
		ELSE
			OUTPUT;
	END;
	strt_lag = enr_start;
	stop_lag = enr_end;
	IF LAST.mrn THEN
		OUTPUT;
RUN;
%MEND mem_gap_rm;


%MACRO mem_cal_yr(cy_file);
/*Divide coverage into calendar years                                         */
DATA libkeep.mem_yr;
	SET &cy_file;
	FORMAT end_dt mmddyy10.;
	end_dt = enr_end;
	DO year = year(enr_start) to year(enr_end);
		enr_start = MAX(MDY(1,1,year),enr_start);
		enr_end = MIN(MDY(12,31,year),end_dt);
		OUTPUT;
	END;
RUN;
%MEND mem_cal_yr;

/*Take a file output from mem_cal_yr i.e. and gets 12/31 enrollments*/
%MACRO yr_end_enr(enr_file, strt_yr, end_yr);
DATA libkeep.mem_yr_end;
	SET &enr_file;
	IF year >= &strt_yr AND year <= &end_yr;
	IF DAY(enr_end) = 31 AND MONTH(enr_end) = 12;
RUN;

%MEND yr_end_enr;

/*Annual total enrollment by ins source.  Each mrn is counted only in one category */
%MACRO ins_cat_cnt(ins_file, ins1, ins2, ins3, ins4, rec_sel);

PROC SORT DATA = &ins_file OUT = ins_cat_1;
	BY mrn enr_end;
DATA ins_cat_2;
	SET ins_cat_1;
	BY mrn year;
	IF &rec_sel..year;
DATA ins_cat;
	SET ins_cat_2;
	LENGTH ins_type $15.;
	IF &ins1 = 'Y' THEN ins_type = "&ins1";
	ELSE IF &ins2 = 'Y' THEN ins_type = "&ins2";
		ELSE IF &ins3 = 'Y' THEN ins_type = "&ins3";
			ELSE IF &ins4 = 'Y' THEN ins_type = "&ins4";
				ELSE ins_type = 'ins_other';
RUN;

PROC FREQ DATA = ins_cat;
	TABLES ins_type * year / OUT = libsend.ins_cat_count_&_SiteAbbr;
RUN;
%MEND ins_cat_cnt;


%MACRO mem_per(study_start, study_end, mp_file);
/*Keep periods of interest for study                                          */
DATA libkeep.mem_per (DROP = tst_start tst_end);
	LENGTH
		tst_start
		tst_end			8.;
	FORMAT
		tst_start
		tst_end 		mmddyy10.;
	tst_start = INPUT (&study_start, DATE9.);
	tst_end = INPUT (&study_end, DATE9.);
	SET &mp_file;
	IF enr_start < tst_end and enr_end > tst_start;
RUN;
%MEND mem_per;

/*Member retention */
/*%MACRO mem_ret(study_start, study_end);*/
/*%PUT &study_start &study_end;*/
%MACRO mem_ret(mr_file);

/*Count the number of years with some coverage don't stop at gaps             */
DATA libkeep.mem_ret1 (KEEP = mrn mem_ret_gaps mem_ret_start mem_ret_frst_end
	mem_ret_end mem_ret_yrs_with mem_ret_frst_yrs_with mem_ret_largest);
	SET &mr_file;
	RETAIN mem_ret_gaps mem_ret_start prev_end mem_ret_frst_end mem_ret_yrs_with
		prev_mrn mem_ret_frst_yrs_with mem_ret_cons_yrs_with mem_frst_flag
		mem_ret_largest;
	FORMAT mem_ret_start mem_ret_frst_end mem_ret_end mmddyy10.;
	BY mrn;
	IF FIRST.mrn THEN DO;
		mem_ret_start = enr_start;
		mem_ret_gaps = 0;
		mem_ret_yrs_with = 0;
		mem_ret_largest = 0;
		mem_ret_cons_yrs_with = 0;
		mem_ret_frst_end = '';
		mem_frst_flag = 'Y';
	END;
	mem_ret_yrs_with + 1;
	mem_ret_cons_yrs_with + 1;
	IF mrn eq prev_mrn and prev_end + 1 ne enr_start THEN DO;
		mem_ret_gaps + 1;
		IF YEAR(prev_end) = YEAR(enr_start) THEN DO;
			mem_ret_yrs_with = mem_ret_yrs_with -1; /*don't count same year again*/
			mem_ret_cons_yrs_with = mem_ret_cons_yrs_with -1; /*don't count same year again*/
		END;
		mem_ret_frst_end = prev_end;
		IF mem_frst_flag = 'Y' THEN
			mem_ret_frst_yrs_with = mem_ret_yrs_with;
		mem_frst_flag = 'N';
		IF mem_ret_cons_yrs_with > mem_ret_largest THEN
			mem_ret_largest = mem_ret_cons_yrs_with;
		mem_ret_cons_yrs_with = 0;
	END;
	prev_mrn = mrn;
	prev_end = enr_end;
	IF LAST.mrn THEN DO;
		mem_ret_end = enr_end;
		IF mem_ret_cons_yrs_with > mem_ret_largest THEN
			mem_ret_largest = mem_ret_cons_yrs_with;
		OUTPUT;
	END;
RUN;

/* Years with any coverage */
DATA libkeep.mem_ret2;
	SET &mr_file;
	RETAIN cont_mrn cont_ret prev_end prev_mrn save_yr yrs_ret;
	BY mrn;
	IF FIRST.mrn THEN DO;
/*		IF enr_start <= &study_start.d THEN DO;*/
			prev_mrn = mrn;
			cont_mrn = mrn;
			save_yr = year;
			prev_end = enr_end;
/*		END;*/
		cont_ret = 0;
		yrs_ret = 0;
	END;
	ELSE DO;
/*		IF mrn = prev_mrn THEN DO;*/
			IF year ne save_yr THEN DO;
				yrs_ret + 1;
				save_yr = year;
			END;
			IF enr_start ne prev_end + 1 THEN
				cont_mrn = ' ';
			IF mrn = cont_mrn THEN
				cont_ret + 1;
			prev_end = enr_end;
/*		END;*/
	END;
	IF LAST.mrn;
	IF mrn = prev_mrn; /*probably always true?????*/
RUN;

PROC FREQ DATA = libkeep.mem_ret2;
	TABLES yrs_ret / NOPRINT OUT = libsend.mrn_ret_freq_&_SiteAbbr;
RUN;

PROC FREQ DATA = libkeep.mem_ret2;
	TABLES cont_ret / NOPRINT OUT = libsend.mrn_ret_cont_freq_&_SiteAbbr;
RUN;
%MEND mem_ret;


%MACRO enr_data();

PROC SORT DATA = &_vdw_enroll OUT = enr1;
	BY mrn enr_start enr_end;
DATA libkeep.enr2 (KEEP = mrn enr_cnt ins_care ins_caid ins_comm ins_priv ins_othr drg_cov
			f_enr_s l_enr_e);
	SET enr1;
	RETAIN enr_cnt ins_care ins_caid ins_comm ins_priv ins_othr drg_cov f_enr_s;
	BY mrn;
	IF FIRST.mrn THEN DO;
		enr_cnt = 0;
		ins_care = 0;
		ins_caid = 0;
		ins_comm = 0;
		ins_priv = 0;
		ins_othr = 0;
		drg_cov = 0;
		f_enr_s = enr_start;
	END;
	enr_cnt + 1;
	IF ins_medicare = 'Y' THEN
		ins_care + 1;
	IF ins_medicaid = 'Y' THEN
		ins_caid + 1;
	IF ins_commercial = 'Y' THEN
		ins_comm + 1;
	IF ins_privatepay = 'Y' THEN
		ins_priv + 1;
	IF ins_other = 'Y' THEN
		ins_othr + 1;
	IF drugcov = 'Y' THEN
		drg_cov + 1;
	IF LAST.mrn THEN DO;
		l_enr_e = enr_end;
		OUTPUT;
	END;
	FORMAT f_enr_s l_enr_e MMDDYY10.;
RUN;

/*Check types of coverage*/
PROC SQL;
	CREATE TABLE
		libsend.enr_cov_&_SiteAbbr AS
	SELECT
		MIN(f_enr_s) AS f_strt FORMAT MMDDYY10.
		, MAX(l_enr_e) AS l_end FORMAT MMDDYY10.
		, COUNT(*) AS mrn_cnt
		, SUM(enr_cnt) AS enr_tot
		, SUM(ins_care) AS care_tot
		, SUM(MIN(1,ins_care)) AS ever_care
		, SUM(ins_caid) AS caid_tot
		, SUM(MIN(1,ins_caid)) AS ever_caid
		, SUM(ins_comm) AS comm_tot
		, SUM(MIN(1,ins_comm)) AS ever_comm
		, SUM(ins_priv) AS priv_tot
		, SUM(MIN(1,ins_priv)) AS ever_priv
		, SUM(ins_othr) AS othr_tot
		, SUM(MIN(1,ins_othr)) AS ever_othr
		, SUM(drg_cov) AS drg_tot
		, SUM(MIN(1,drg_cov)) AS ever_drg
	FROM
		libkeep.enr2
	;
QUIT;

%MACRO avg_cov(cov_type, cov_label);

/*%LET cov_type = Drug;*/
/*%LET cov_label = drg;*/
DATA libsend.enr_&cov_type._cov_&_SiteAbbr  (KEEP = c_type avg_x avg_evr avg_typ total_cov ever_cov);
	SET libsend.enr_cov_&_SiteAbbr ;
	c_type = "&cov_type.";
	total_cov = &cov_label._tot; /*Total number of coverages for this type*/
	ever_cov = ever_&cov_label.; /*Number of mrn ever covered for this type*/
	avg_x = &cov_label._tot / mrn_cnt; /*enrollment time per total*/
	avg_evr = ever_&cov_label. / mrn_cnt; /*ever enrolled per total*/
	avg_typ = &cov_label._tot / ever_&cov_label.; /*times enrolled per ever enrolled*/
RUN;

%MEND avg_cov;

%avg_cov(cov_type = Medicare, cov_label = care);
%avg_cov(cov_type = Medicaid, cov_label = caid);
%avg_cov(cov_type = Commericial, cov_label = comm);
%avg_cov(cov_type = Private, cov_label = priv);
%avg_cov(cov_type = Other, cov_label = othr);
%avg_cov(cov_type = Drug, cov_label = drg);

%MEND enr_data;

/* Coverage counts a ins_type at any given point (or span) */
%MACRO cov_at(covtype ,start_time, end_time ,covlabel);

PROC SQL;
	CREATE TABLE libkeep.enr_mrn_cov AS
	SELECT DISTINCT
		mrn
	FROM
		enr1
	WHERE
		&covtype = 'Y'
		AND enr_start <= &end_time
		AND enr_end > &start_time
	;
QUIT;

PROC SQL;
	CREATE TABLE libsend.enr_&covlabel._&_SiteAbbr  AS
	SELECT
		"&covtype." AS ins_type
		, COUNT(*) AS cov_count
	FROM
		libkeep.enr_mrn_cov
	;
QUIT;

%MEND cov_at;

/*Macro to compute age at each start_date and find those above or below the  */
/*set limits.                                                                */
%MACRO enr_age(
	in_file = mem_gap_rm
	, in_lib = libkeep.
	, low_age = 0
	, up_age = 120
	, label = enr
);

PROC SQL;
	CREATE TABLE &label._1 AS
	SELECT
		i.mrn
		, i.enr_start
		, FLOOR((INTCK('MONTH',d.birth_date,i.enr_start) -
			(DAY(i.enr_start) < DAY(d.birth_date))) / 12)
		  AS age
	FROM
		&in_lib.&in_file i
		, &_vdw_demographic d
	WHERE
		i.mrn = d.mrn
	;
QUIT;

DATA libkeep.&label._2;
	SET &label._1;
	IF age < &low_age OR age > &up_age;
RUN;

PROC SQL;
	CREATE TABLE &label._3 AS
	SELECT
   		COUNT(*) AS err_rec_count
		, "a" AS label_type
	FROM
		libkeep.&label._2
	;
QUIT;

PROC SQL;
	CREATE TABLE &label._4 AS
	SELECT
   		COUNT(DISTINCT mrn) AS mrn_w_err_count
		, "a" AS label_type
	FROM
		libkeep.&label._2
	;
QUIT;

PROC SQL;
	CREATE TABLE &label._5 AS
	SELECT
   		COUNT(*) AS of_record_count
		, "a" AS label_type
	FROM
		&label._1
	;
QUIT;

PROC SQL;
	CREATE TABLE &label._6 AS
	SELECT
   		COUNT(DISTINCT mrn) AS of_mrn_count
		, "a" AS label_type
	FROM
		&label._1
	;
QUIT;

DATA libsend.&label._age_error_summary_&_SiteAbbr (DROP = label_type);
	MERGE &label._3 &label._5 &label._4 &label._6;
	BY label_type;
RUN;

%PUT &low_age &up_age;
%MEND enr_age;

%MACRO race_dist(dem_file);
DATA race_dist1;
	FORMAT race $Race.;
	SET &dem_file;
	IF race2 NE 99 THEN race = '-1';
	ELSE race = race1;
RUN;

PROC FREQ DATA = race_dist1;
	TABLES race / OUT = libsend.race_distribution_&_SiteAbbr;
RUN;

DATA race_dist2;
	FORMAT race $Race.;
	SET &dem_file;
	IF race2 NE 99 THEN race = '-1';
	ELSE race = race1;
	IF race NE '7 Unknown or Not Reported';
RUN;

PROC FREQ DATA = race_dist2;
	TABLES race / OUT = libsend.known_race_distribution_&_SiteAbbr;
RUN;
%MEND race_dist;

/*Insurance frequencies                                                      */
%MACRO ins_freq(in_lib = libkeep., in_file = mem_gap_rm);

PROC FREQ DATA = &in_lib.&in_file;
	TABLES ins_commercial * ins_medicaid * ins_medicare * ins_privatepay
		/ OUT = libsend.ins_frequencies_&_SiteAbbr;
RUN;
%MEND ins_freq;

%macro make_denoms(start_year, end_year, outset) ;
  data all_years ;
    do year = &start_year to &end_year ;
      first_day = mdy(1, 1, year) ;
      last_day  = mdy(12, 31, year) ;
      * Being extra anal-retentive here--we are probably going to hit a leap year or two. ;
      num_days  = last_day - first_day + 1 ;
      output ;
    end ;
    format first_day last_day mmddyy10. ;
  run ;

  proc print ;
  run ;

  proc sql ;
    /*
      Dig this funky join--its kind of a cartesian product, limited to
      enroll records that overlap the year from all_years.
      enrolled_proportion is the # of days between <<earliest of enr_end and last-day-of-year>>
      and <<latest of enr_start and first-day-of-year>> divided by the number of
      days in the year.

      Nice thing here is we can do calcs on all the years desired in a single
      statement.  I was concerned about perf, but this ran quite quickly--the
      whole program about 4 minutes of wall clock time to do 1998 - 2007 @ GH.

    */
    create table gnu as
    select mrn
          , year
          , min(put(drugcov, $dc.)) as drugcov
          /* This depends on there being no overlapping periods to work! */
          , sum((min(enr_end, last_day) - max(enr_start, first_day) + 1) / num_days) as enrolled_proportion
    from  &_vdw_enroll as e INNER JOIN
          all_years as y
    on    e.enr_start le y.last_day AND
          e.enr_end   ge y.first_day
    group by mrn, year
    ;

    create table with_agegroup as
    select g.mrn
        , year
        , put(%calcage(refdate = mdy(1, 1, year)), agecat.) as agegroup label = "Age on 1-jan of [[year]]"
        , gender
        , case when race2 is null or race2 in ('88', '99') then put(race1, $RaceT.) else 'Multiple' end as race length = 10
        , put(drugcov, $cd.) as drugcov
        , enrolled_proportion
    from gnu as g LEFT JOIN
         &_vdw_demographic as d
    on   g.mrn = d.mrn
    ;

    create table &outset as
    select year
        , agegroup
        , drugcov label = "Drug coverage status (set to 'Y' if drugcov was 'Y' even once in [[year]])"
        , race
        , gender
        , round(sum(enrolled_proportion), &round_to) as prorated_total format = comma20.2 label = "Pro-rated number of people enrolled in [[year]] (accounts for partial enrollments)"
        , count(mrn)               as total          format = comma20.0 label = "Number of people enrolled at least one day in [[year]]"
    from with_agegroup
    group by year, agegroup, drugcov, race, gender
    order by year, agegroup, drugcov, race, gender
    ;

  quit ;

%mend make_denoms ;

%macro report_enrollment(inset = libkeep.base_denominators) ;

  proc tabulate data = &inset format = comma15.2 ;
    class year agegroup drugcov gender race ;
    var prorated_total ;
    table                     (agegroup all = "Total")   , year=" "*prorated_total=" "* (sum="N"*f=msk. colPCTsum="%") ;
    table gender = "Gender" * (agegroup all = "Subtotal"), year=" "*prorated_total=" "* (sum="N"*f=msk. colPCTsum="%") ;
    table race = "Race"     * (agegroup all = "Subtotal"), year=" "*prorated_total=" "* (sum="N"*f=msk. colPCTsum="%") ;
  run ;

%mend report_enrollment ;

%macro make_count_tables ;
  %make_denoms(start_year = 1998, end_year = 2007, outset = libkeep.base_denominators) ;
  proc sql ;
    * If I have gender * age, and race * age, I can do plain age from either of those (and likewise a total). ;
    create table libsend.race_counts_&_SiteAbbr as
    select year, agegroup, race
          , case when sum(prorated_total) between .01 and 4 then .a else sum(prorated_total) end as prorated_total format = comma20.2
          , case when sum(total)          between 1   and 4 then .a else sum(total)          end as total          format = comma20.0
    from libkeep.base_denominators
    group by year, agegroup, race
    ;
    create table libsend.gender_counts_&_SiteAbbr as
    select year, agegroup, gender
          , case when sum(prorated_total) between .01 and 4 then .a else sum(prorated_total) end as prorated_total format = comma20.2
          , case when sum(total)          between 1   and 4 then .a else sum(total)          end as total          format = comma20.0
    from libkeep.base_denominators
    group by year, agegroup, gender
    ;
  quit ;
%mend make_count_tables ;



/*@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@*/
/*@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@*/
/*@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@*/
/*Macro calls                                                                 */
/*@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@*/

/*%qa checks various aspects of the VDW (see below) it writes errors to a     */
/*dataset for each error and writes a summary data set "qa_error_warn"        */
%qa();

/*%tst_data macro creates a test file from enrollment or demographics of      */
/*total#rec/"inc"  random records.                                            */
%tst_data(tst_file = enrollment, inc = 1000);
/*%tst_data(tst_file = demographics, inc = 100);*/

/*%mem_gap_rm removes any gaps in any file "gap_file" that contains enr_start */
/*and enr_end date field and remove coverage gaps of "gap" days or less length*/
%mem_gap_rm(gap = 91, gap_file = &_vdw_enroll);

/*%mem_cal_yr divides takes any file that contains enr_start and enr_end date */
/*fields and divides coverage into calendar years.                            */
%mem_cal_yr(cy_file = libkeep.mem_gap_rm);
/*%mem_cal_yr(cy_file = &_vdw_enroll);*/

/*%yr_end_enr takes a file with enr_end and year, where year is equal to      */
/*enr_end year and puts out all of the enrollments that end on 12/31.         */
/*OUTPUT: libkeep.mem_yr_end */
%yr_end_enr(enr_file = libkeep.mem_yr, strt_yr = 2000, end_yr = 2007);

/*%ins_cat_cnt takes an enrollment type file and counts insurance types on a  */
/*hierarchical basis per year, with ins1 being selected first and on down.  If*/
/*there are multiple records per year rec_sel will be used to select the first*/
/*or last record per mrn, per year.                                           */
/*OUTPUT: libsend.ins_cat_count, libsend.enr_yr_count                         */
%ins_cat_cnt(ins_file = libkeep.mem_yr_end, ins1 = ins_medicaid,
	ins2 = ins_medicare, ins3 = ins_privatepay, ins4 = ins_commercial,
	rec_sel = FIRST);

/*%mem_study_yr();*/

/*%mem_per takes study_start date and study_end date and any file with        */
/*enr_start date and enr_end date.  It keeps any record that has an enr_start */
/*that is less than study_end and an enr_end greater that study_start.        */
%mem_per(study_start = "01JAN1900", study_end = "13DEC2100", mp_file = &_vdw_enroll);

/*%mem_ret takes a file with an mrn, year, enr_start and enr_end date fields  */
/*& creates two datasets.  The first dataset contains start of first coverage */
/*period, number of gaps, a count calendar years with some coverage, the      */
/*largest consecutive coverage period, when first coverage ends, when the last*/
/*coverage ends.  The second counts years with coverage and number of years   */
/*from the first enr_start of continuous coverage.  It then counts how many   */
/*mrns there are with x years of retention and how many mrns with x years of  */
/*continuous retention.                                                       */
%mem_ret(libkeep.mem_yr);

/*%enr_data takes the enrollment file and reports number of several coverages */
/*in any period as well as number of mrns that ever had the given coverage:   */
/*enrollments, medicare, medicaid, commercial, private, other and drug        */
/*coverage.  It also tells when the first enrollment starts and when the last */
/*enrollment ends; for each mrn.  A second file enr_cov, is created that      */
/*counts total coverages, first ever start and last ever end date in aggregate*/
/*for the total enrollment file.                                              */

/*%avg_cov(cov_type, cov_label): (within %enr_data)                           */
/*Takes the enr_cov file from %enr_data and reports coverage information.     */
/*	c_type - coverage type                                                    */
/*	total_cov -  the total number of coverages for this type                  */
/*	ever_cov -  number of mrns ever covered for this type                     */
/*	avg_x - average coverage for each mrn in enrollemt file                   */
/*	avg_ever -  % of total mrns ever covered by this type                     */
/*	avg_type - average coverages for those mrns ever covered by this type.    */
%enr_data();

/*%cov_at takes one of the insurance types: ins_medicare, ins_medicaid,       */
/*ins_commercial, ins_commercial, drug_cov; and a time span and returns the   */
/*of unique MRNs that have some coverage during the period.                   */
%cov_at(
	covtype = ins_medicare
	, start_time = mdy(3,13,2008)
	, end_time = mdy(3,13,2008)
	, covlabel = mcare3_13_08
);
%cov_at(
	covtype = ins_medicaid
	, start_time = mdy(2,15,2009)
	, end_time = mdy(2,28,2009)
	, covlabel = mcaid090215To28
);
%cov_at(
	covtype = ins_medicaid
	, start_time = mdy(1,01,2009)
	, end_time = mdy(2,28,2009)
	, covlabel = mcaid_check
);

/*Going to use Roy's program for this*/
/*%race_dist(dem_file = &_vdw_demographic);*/

/* %enr_age takes the a file with mrn and start_date (usually an enrollment   */
/*file) and computes the age at each start_date.  It then writes all records  */
/*with an age of less than low_age or more than up_age to a file.  It creates */
/*a summary file with counts of records with ages under the lower limit, over */
/*the upper limit and with unique mrns over or under the limits.              */
/* */
%enr_age();

/*Below is an example if you don't want to use the defaults.  You can leave    */
/*in_lib blank to use a work file at the input.                                */
/*%enr_age(*/
/*	in_file = enr1*/
/*	, in_lib =*/
/*	, low_age = 1*/
/*	, up_age = 105*/
/*	, label = age_ch1*/
/*);*/

/*%ins_freq gets the comparative frequencies of the four insurance types.  You*/
/*can give parameters of in_lib and in_file.  If left blank libkeep and       */
/*mem_gap_rm file are the defaults.                                           */
%ins_freq();

/*Files to be sent to mcrf 20090401                                           */
PROC TRANSPOSE DATA = libsend.ins_cat_count_&_SiteAbbr OUT = ic_count  (DROP = _LABEL_ _NAME_)	PREFIX = cnt_;
	BY ins_type;
	VAR count;
	ID year;
RUN;


PROC TRANSPOSE DATA = libsend.ins_cat_count_&_SiteAbbr OUT = ic_percent  (DROP = _LABEL_ _NAME_)	PREFIX = pcnt_;
	BY ins_type;
	VAR percent;
	ID year;
RUN;

DATA libsend.ins_tp_cnt_&_SiteAbbr;
	FORMAT cnt_2000 8. pcnt_2000 4.1 cnt_2001 8. pcnt_2001 4.1 cnt_2002 8.
		pcnt_2002 4.1 cnt_2003 8. pcnt_2003 4.1 cnt_2004 8. pcnt_2004 4.1
		cnt_2005 8. pcnt_2005 4.1 cnt_2006 8. pcnt_2006 4.1 cnt_2007 8.
		pcnt_2007 4.1;
	MERGE ic_count ic_percent;
	BY ins_type;
	IF cnt_2000 < 6 THEN cnt_2000 = 0;
	IF cnt_2001 < 6 THEN cnt_2001 = 0;
	IF cnt_2002 < 6 THEN cnt_2002 = 0;
	IF cnt_2003 < 6 THEN cnt_2003 = 0;
	IF cnt_2004 < 6 THEN cnt_2004 = 0;
	IF cnt_2005 < 6 THEN cnt_2005 = 0;
	IF cnt_2006 < 6 THEN cnt_2006 = 0;
	IF cnt_2007 < 6 THEN cnt_2007 = 0;
RUN;

DATA qa_error_warn (KEEP = e_type);
	FORMAT e_type $30.;
	SET libkeep.enr_not_in_demo libkeep.dup_demo_mrn libkeep.start_end_error
		libkeep.end_date_error libkeep.start_date_error libkeep.enr_overlap_error
		libkeep.gender_error libkeep.race_error libkeep.hispanic_error
		libkeep.drugcov_error libkeep.inscov_error libkeep.inscov_warn;
RUN;

PROC SQL;
	CREATE TABLE libsend.qa_e_w_count_&_SiteAbbr AS
	SELECT
		e_type
		, COUNT(*) AS count
	FROM
		qa_error_warn
	GROUP BY
		e_type
	;
QUIT;

OPTIONS ORIENTATION=landscape linesize=max pagesize=max;
ODS HTML FILE = "&send_loc.\error_warn_counts_&_SiteAbbr..xls"(URL = none) Style = MINIMAL rs = none;

PROC PRINT DATA = libsend.enr_age_error_summary_&_SiteAbbr n noobs;
	TITLE "Count of enrollments w/ age errors";
	TITLE2 '%enr_age output';
RUN;

PROC PRINT DATA = libsend.enr_cov_&_SiteAbbr n noobs;
	TITLE "Count of various enrollments ";
	TITLE2 '%enr_data output';
RUN;

PROC PRINT DATA = libsend.enrl_contents_&_SiteAbbr n noobs;
	TITLE "Enrollment contents";
	TITLE2 'proc contents output';
RUN;

PROC PRINT DATA = libsend.ins_cat_count_&_SiteAbbr n noobs;
	TITLE "Hierarchical Ins Cat Counts by Year";
	TITLE2 '%ins_cat_cnt output';
RUN;

PROC PRINT DATA = libsend.ins_tp_cnt_&_SiteAbbr n noobs;
	TITLE "Hierarchical Ins Cat Counts by Year transposed";
RUN;

PROC PRINT DATA = libsend.ins_frequencies_&_SiteAbbr n noobs;
	TITLE "Insurance Frequencies";
RUN;

PROC PRINT DATA = libsend.mrn_ret_cont_freq_&_SiteAbbr n noobs;
	TITLE "Hierarchical Ins Cat Counts by Year";
	TITLE2 '%mem_ret output';
RUN;

PROC PRINT DATA = libsend.qa_e_w_count_&_SiteAbbr n noobs;
	TITLE "Errors and Warnings with counts";
	TITLE2 '%qa output';
RUN;

ODS HTML CLOSE;

%make_count_tables ;

ODS HTML FILE = "&send_loc.\gender_race_counts_&_SiteAbbr..xls"(URL = none) Style = MINIMAL rs = none;
 TITLE 'Gender Race Counts';
 TITLE2 ' ';
  %report_enrollment ;

ODS HTML CLOSE;

OPTIONS orientation=portrait linesize=139 pagesize=78;

/*End print to log*/
proc printto;
run;
