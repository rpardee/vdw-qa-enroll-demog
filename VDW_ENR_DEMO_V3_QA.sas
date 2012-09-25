/*
************************************************************************************************

	Program Name:   VDW_ENR_DEMO_V3_QA.SAS
	PURPOSE: Creates a file of counts and statitics on the enrollment and
		demographic information in the VDW.
----------------------------------------------------------
  VDW Input Files:
----------------------------------------------------------
  _vdw_Tumor
  _vdw_Enroll        x
  _vdw_Demographic   x
  _vdw_Rx
  _vdw_EverNdc
  _vdw_Utilization
  _vdw_Death
  _vdw_CauseOfDeath
  _vdw_Dx
  _vdw_Px
  _vdw_ProviderSpecialty
  _vdw_Vitalsigns
  _vdw_Census
  _vdw_Lab
  _vdw_lab_notes

This code is currently pointing to the V3 VDW Milestone Macro Variables.
&_vdw_enroll
&_vdw_demographic
It is presumed that these are pointing to V3 datasets
-----------------------------------------------------------
  Local Files:
-----------------------------------------------------------
  VDW_MACS.sas     --the standard set of VDW macros.
  STD_VARS.sas     --the site-specific naming convention crosswalk
----------------------------------------------------------
  Output:
----------------------------------------------------------

----------------------------------------------------------
  Modification & Contact Info:
----------------------------------------------------------
	DATE: 08/19/2008 Paul Hitz	hitz.paul@marshfieldclinic.org
			create descriptive statistics for ENROLLMENT & DEMOGRAPHICS
			VDW files as well as pass/warning/fail checks
	UPDATE: 07/08/2011 Lucas Ovans		Lucas.J.Ovans@HealthPartners.com
			V2 to V3 upgrade
			Addition of grp, gvmt, plan counts
			Dual membership count
----------------------------------------------------------
Date Program Created: MM/DD/YYYY
DD/MM/YYYY Initials - Reason for Modification
*/

*************************************************************************************************;
** 		=========================== BEGIN EDIT SECTION ============================= 		    ;
**		Please update the following Std vars, macros and pathways to proper local directories	;
*************************************************************************************************;
options errors = 0 linesize = 150 nocenter msglevel = i NOOVP formchar='|-++++++++++=|-/|<>*'
		dsoptions="note2err" ;
%put SAS session began at: %sysfunc(datetime(),datetime20.);**Testing;

**STANDARD VARS																					;
** 		Please include local copy of StdVars.sas 												;
** %include '<<>>';
%include '\\researchdm\VDW\Programmers\Programs\StdVars.sas';

**INTERNAL OUTPUT DATASETS																		;
** 	Directory for local output when remains on site since it may included MRNs					;
*				*			let outshare = \\server\folder\subfolder\; *<==WINDOWS EXAMPLE*		;
**			let outshare = //server/folder/subfolder/; *<==UNIX EXAMPLE*						;
**			let outshare = [server.folder.subfolder]; 	*<==VMS EXAMPLE*						;
**			Do not include quotation marks and include slash or backslash at the end			;
%LET OUT_LOC = \\researchdm\vdw_data\Programming\enrollment\qA\july2011\local\ ;
**%LET OUT_LOC = \\ctrhs-sas\SASUser\pardre1\vdw\voc_enroll\qa\stays ;
	**%LET OUT_LOC=<<>>;
	LIBNAME LIBKEEP "&OUT_LOC";

**EXTERNAL OUTPUT DATASETS																		;
%LET OUT_SEND = \\researchdm\vdw_data\Programming\enrollment\qA\july2011\external\ ;
**%LET OUT_SEND = \\ctrhs-sas\SASUser\pardre1\vdw\voc_enroll\qa\goes ;
	libname libsend "&OUT_SEND";

*************************************************************************************************;
** 		=========================== END EDIT SECTION ============================= 		        ;
**		Please update the above Std vars, load macros and pathways to proper local directories	;
*************************************************************************************************;
**STANDARD MACROS																				;
%include vdw_macs;*Be sure std macros load;
%let round_to = 0.0001 ;

proc printto log="&OUT_SEND.\ENR_DEMO_QA_log.log" new ; run;
PROC FORMAT;
	value $Race
      	'HP' = 'Native Hawaiian or Other Pacific Islander'
	'IN' = 'American Indian/Alaska Native'
	'AS' = 'Asian'
	'BA' = 'Black or African American'
	'WH' = 'White'
	'MU' = 'More than one race, particular races unknown or not reported'
	'UN' = 'Unknown or Not Reported'
      Other = 'Unknown or Not Reported'
    ;
    value $RaceT
	'HP' = Native Hawaiian or Other Pacific Islander
	'IN' = American Indian/Alaska Native
	'AS' = Asian
	'BA' = Black or African American
	'WH' = White
	'MU' = More than one race, particular races unknown or not reported
	'UN' = Unknown or Not Reported
     Other = Unknown or Not Reported
    ;
    value msk
      0 -< &lowest_count = "< &lowest_count"
      other = [comma15.0]
    ;
    ** 0-17, 18-64, 65+ ;
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
	Length e_type $15;
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
	LENGTH E_TYPE $15;
	RETAIN save_end;
	SET mem_enrl;
	IF FIRST.mrn THEN save_end = enr_start;
	BY mrn;
	IF enr_start < save_end THEN OUTPUT;
	save_end = enr_end;
	e_type = 'enr overlap error';
	Format Save_end MMDDYY.;
RUN;
******************			DEMO CHECKS					 **********************;
/*Check that the values for the gender field in the demographics file contain */
/*valid values.  The gender_error data set should have 0 records.             */
%LET valid_gender = 'M', 'F', 'O', 'U';
DATA libkeep.gender_error;
	LENGTH E_TYPE $15;
	SET mem_demo;
	IF gender NOT IN (&valid_gender);
	e_type = 'gender error';
RUN;

/*Check that the values for the race field in the demographics file contain   */
/*valid values.  The race_error data set should have 0 records.               */

%LET valid_race = 'AS','BA','HP','IN','WH','MU','UN';

DATA libkeep.race_error;
	LENGTH E_TYPE $15;
	SET mem_demo;
	IF race1 NOT IN (&valid_race.,'88')
		OR race2 NOT IN (&valid_race.)
		OR race3 NOT IN (&valid_race.)
		OR race4 NOT IN (&valid_race.)
		OR race5 NOT IN (&valid_race.);
	e_type = 'race error';
RUN;

/*Check that the values for the hispanic field in the demographics file have  */
/*valid values.  The hispanic_error data set should have 0 records.           */
%LET valid_YNU = 'Y', 'N', 'U';
DATA libkeep.hispanic_error;
	LENGTH E_TYPE $15;
	SET mem_demo;
	IF hispanic NOT IN (&valid_YNU);
	e_type = 'hispanic error';
RUN;

/*Check that the values for the drug coverage fields in the enrollment file   */
/*contain valid values.  The drugcov_error data set should have 0 records.    */
DATA libkeep.drugcov_error;
	LENGTH E_TYPE $15;
	SET mem_enrl;
	IF drugcov NOT IN (&valid_YNU);
	e_type = 'drugcov error';
RUN;

/*Check that the values for the insurance flag fields in the enrollment file  */
/*have valid values.  The inscov_error data set should have 0 records.        */
DATA libkeep.inscov_error;
	LENGTH E_TYPE $15;
	SET mem_enrl;
	IF 	   ins_medicaid NOT IN (&valid_YNU)
		OR ins_commercial NOT IN (&valid_YNU)
		OR ins_privatepay NOT IN (&valid_YNU)
		OR ins_StateSubsidized NOT IN (&valid_YNU)
		OR Ins_SelfFunded NOT IN (&valid_YNU)
		OR Ins_HighDeductible NOT IN (&valid_YNU)
		OR ins_medicare NOT IN (&valid_YNU)
		OR ins_medicare_a NOT IN (&valid_YNU)
		OR ins_medicare_b NOT IN (&valid_YNU)
		OR ins_medicare_c NOT IN (&valid_YNU)
		OR ins_medicare_d NOT IN (&valid_YNU)
		OR ins_other NOT IN (&valid_YNU);
	e_type = 'InsCov error';
RUN;

/*Check that the values for the plan flag fields in the enrollment file  */
/*have valid values.  The PlanTp_error data set should have 0 records.        */
DATA libkeep.plantp_error;
	LENGTH E_TYPE $15;
	SET mem_enrl;
		IF plan_hmo NOT IN (&valid_YNU)
			OR plan_pos NOT IN (&valid_YNU)
			OR plan_ppo NOT IN (&valid_YNU)
			OR plan_indemnity NOT IN (&valid_YNU);
	e_type = 'PlanTp error';
RUN;
/*Check if there is less than one or more than three ins_ flags set to "Y".   */
* This is warning to allow site further local investigation. This does not directly indicate error;
DATA libkeep.inscov_warn;
	LENGTH E_type $15 COUNT 3;
	SET mem_enrl;
	count = 0;
	IF ins_medicaid = "Y" THEN count + 1;
	IF ins_commercial = "Y" THEN count + 1;
	IF ins_privatepay = "Y" THEN count + 1;
	IF ins_StateSubsidized = "Y" THEN count + 1;
	IF Ins_SelfFunded = "Y" THEN count + 1;
	IF Ins_HighDeductible = "Y" THEN count + 1;
	IF ins_medicare = "Y" THEN count + 1;
	IF ins_medicare_a = "Y" THEN count + 1;
	IF ins_medicare_b = "Y" THEN count + 1;
	IF ins_medicare_c = "Y" THEN count + 1;
	IF ins_medicare_d = "Y" THEN count + 1;
	IF ins_other = "Y" THEN count + 1;
		IF count < 1 OR count > 3;
	e_type = 'inscov warn';
RUN;
/*Check if there is less than one or more than three plan_ flags set to "Y".   */
* This is warning to allow site further local investigation. This does not directly indicate error;
DATA libkeep.PlanTp_warn;
	LENGTH E_type $15 COUNT 3;
	SET mem_enrl;
	count = 0;
	IF plan_hmo = "Y" THEN count + 1;
	IF plan_pos = "Y" THEN count + 1;
	IF plan_ppo = "Y" THEN count + 1;
	IF plan_indemnity = "Y" THEN count + 1;
		IF count < 1 OR count > 2;
	e_type = 'PlanTp warn';
RUN;


/* This is a summary file telling where the errors may exist */
DATA libsend.qa_error_warn_&_SiteAbbr (KEEP = e_type);
	FORMAT e_type $30.;
	SET libkeep.enr_not_in_demo libkeep.dup_demo_mrn libkeep.start_end_error
		libkeep.end_date_error libkeep.start_date_error libkeep.enr_overlap_error
		libkeep.gender_error libkeep.race_error libkeep.hispanic_error
		libkeep.drugcov_error libkeep.inscov_error libkeep.plantp_error
		/**Do we really collect warnings?*/ libkeep.inscov_warn libkeep.PlanTp_warn;
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
	** LENGTH mrn $8.;
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
*Divide coverage into calendar years;
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


%MACRO yr_end_enr(enr_file, strt_yr, end_yr);
*Take a file output from mem_cal_yr i.e. and gets 12/31 enrollments;;
DATA libkeep.mem_yr_end;
	SET &enr_file;
	IF year >= &strt_yr AND year <= &end_yr;
	IF DAY(enr_end) = 31 AND MONTH(enr_end) = 12;
RUN;

%MEND yr_end_enr;

%MACRO cat_cnt(in_file,out_file, cat1, cat2, cat3, cat4, rec_sel);
*Annual total enrollment by ins source.  Each mrn is counted only in one category;
DATA cat_1;
	SET &in_file;
	LENGTH cat_type $20.;
	IF &cat1 = 'Y' THEN cat_type = upcase("&cat1");
	ELSE IF &cat2 = 'Y' THEN cat_type = upcase("&cat2");
		ELSE IF &cat3 = 'Y' THEN cat_type = upcase("&cat3");
			ELSE IF &cat4 = 'Y' THEN cat_type = upcase("&cat4");
				ELSE cat_type = 'Misc Category';
RUN;
PROC SORT DATA = cat_1;
	BY mrn enr_end;
DATA cat_2;
	SET cat_1;
	BY mrn year;
	IF &rec_sel..year;

PROC FREQ DATA = cat_2;
	TABLES cat_type * year / OUT = libsend.&out_file._count_&_SiteAbbr;
RUN;
%MEND cat_cnt;
%MACRO ins_dual(input,rec_sel);
*Annual total enrollment for Medicare, Medicaid and Dual coverage.  Each mrn is counted  only once annually;
Proc SQL;
	CREATE TABLE INS_DUAL_1 AS
	SELECT
		CASE
			WHEN Ins_Medicare='Y' AND Ins_Medicaid='Y' THEN 'Dual Coverage'
			WHEN Ins_Medicare='Y' THEN 'Medicare'
			WHEN Ins_Medicaid='Y' THEN 'Medicaid'
			ELSE 'Email Lucas'/*Should never happen*/
		END AS VAR1
		,t.*
	FROM &input  t
	WHERE Ins_Medicare='Y' OR Ins_Medicaid='Y';
quit;
*Ensure only one coverage per person per year??;
PROC SORT DATA = ins_dual_1;
	BY mrn enr_end;
DATA ins_dual_2;
	SET ins_dual_1;
	BY mrn year;
	IF &rec_sel..year;

PROC FREQ DATA = ins_dual_2;
	TABLES VAR1 * year / OUT = libsend.ins_dual_count_&_SiteAbbr;
RUN;
%MEND ins_dual;

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
		mem_ret_frst_end = 0;
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
	TABLES yrs_ret / NOPRINT OUT = libsend.mrn_ret_freq_&_SiteAbbr.;
RUN;

PROC FREQ DATA = libkeep.mem_ret2;
	TABLES cont_ret / NOPRINT OUT = libsend.mrn_ret_cont_freq_&_SiteAbbr.;
RUN;
%MEND mem_ret;

%MACRO enr_data();

PROC SORT DATA = &_vdw_enroll OUT = enr1;
	BY mrn enr_start enr_end;
DATA libkeep.enr2 (KEEP = mrn enr_cnt ins_caid ins_comm ins_priv ins_StSub ins_Self
			ins_HiD ins_care ins_careA ins_careB ins_careC ins_careD ins_othr
			pln_h pln_po pln_pp pln_i drg_cov f_enr_s l_enr_e);
	SET enr1;
	RETAIN enr_cnt ins_caid ins_comm ins_priv ins_StSub ins_Self ins_HiD
			ins_care ins_careA ins_careB ins_careC ins_careD ins_othr
			pln_h pln_po pln_pp pln_i drg_cov f_enr_s;
	BY mrn;
	*Why not array??;
	IF FIRST.mrn THEN DO;
		enr_cnt = 0;
		ins_caid = 0;
		ins_comm = 0;
		ins_priv = 0;
		ins_StSub = 0;
		ins_Self = 0;
		ins_HiD = 0;
		ins_othr = 0;
		ins_care = 0;
		ins_care = 0;
		ins_careA = 0;
		ins_careB = 0;
		ins_careC = 0;
		ins_careD = 0;
		drg_cov = 0;
		pln_h= 0;
		pln_po= 0;
		pln_pp= 0;
		pln_i= 0;
		f_enr_s = enr_start;
	END;
	enr_cnt + 1;
	IF ins_medicaid = 'Y' THEN ins_caid + 1;
	IF ins_commercial = 'Y' THEN ins_comm + 1;
	IF ins_privatepay = 'Y' THEN ins_priv + 1;
	IF ins_StateSubsidized = 'Y' THEN	ins_StSub + 1;
	IF Ins_SelfFunded = 'Y' THEN	ins_Self + 1;
	IF Ins_HighDeductible = 'Y' THEN	ins_HiD + 1;
	IF ins_other = 'Y' THEN	ins_othr + 1;
	IF ins_medicare = 'Y' THEN ins_care + 1;
	IF ins_medicare_A = 'Y' THEN ins_careA + 1;
	IF ins_medicare_B = 'Y' THEN ins_careB + 1;
	IF ins_medicare_C = 'Y' THEN ins_careC + 1;
	IF ins_medicare_D = 'Y' THEN ins_careD + 1;
	IF plan_hmo = 'Y' THEN pln_h + 1;
	IF plan_pos = 'Y' THEN pln_po + 1;
	IF plan_ppo = 'Y' THEN pln_pp + 1;
	IF plan_indemnity = 'Y' THEN pln_i + 1;
	IF drugcov = 'Y' THEN drg_cov + 1;

	IF LAST.mrn THEN DO;
		l_enr_e = enr_end;
		OUTPUT;
	END;
	FORMAT f_enr_s l_enr_e MMDDYY10.;
RUN;

/*Check types of coverage*/
PROC SQL;
	CREATE TABLE
		libsend.enr_cov_&_SiteAbbr. AS
	SELECT
		MIN(f_enr_s) AS f_strt FORMAT MMDDYY10.
		, MAX(l_enr_e) AS l_end FORMAT MMDDYY10.
		, COUNT(*) AS mrn_cnt
		, SUM(enr_cnt) AS enr_tot
		, SUM(ins_caid) AS caid_tot
		, SUM(MIN(1,ins_caid)) AS ever_caid
		, SUM(ins_comm) AS comm_tot
		, SUM(MIN(1,ins_comm)) AS ever_comm
		, SUM(ins_priv) AS priv_tot
		, SUM(MIN(1,ins_priv)) AS ever_priv
		, SUM(ins_StSub) AS StSub_tot
		, SUM(MIN(1,ins_StSub)) AS ever_StSub
		, SUM(ins_Self) AS Self_tot
		, SUM(MIN(1,ins_Self)) AS ever_Self
		, SUM(ins_HiD) AS HiD_tot
		, SUM(MIN(1,ins_HiD)) AS ever_HiD
		, SUM(ins_othr) AS othr_tot
		, SUM(MIN(1,ins_othr)) AS ever_othr
		, SUM(ins_care) AS care_tot
		, SUM(MIN(1,ins_care)) AS ever_care
		, SUM(ins_careA) AS careA_tot
		, SUM(MIN(1,ins_careA)) AS ever_careA
		, SUM(ins_careB) AS careB_tot
		, SUM(MIN(1,ins_careB)) AS ever_careB
		, SUM(ins_careC) AS careC_tot
		, SUM(MIN(1,ins_careC)) AS ever_careC
		, SUM(ins_careD) AS careD_tot
		, SUM(MIN(1,ins_careD)) AS ever_careD
		, SUM(pln_h) AS hmo_tot
		, SUM(MIN(1,pln_h)) AS ever_hmo
		, SUM(pln_po) AS pos_tot
		, SUM(MIN(1,pln_po)) AS ever_pos
		, SUM(pln_pp) AS ppo_tot
		, SUM(MIN(1,pln_pp)) AS ever_ppo
		, SUM(pln_i) AS ind_tot
		, SUM(MIN(1,pln_i)) AS ever_ind
		, SUM(drg_cov) AS drg_tot
		, SUM(MIN(1,drg_cov)) AS ever_drg
	FROM
		libkeep.enr2
	;
QUIT;

	%MACRO avg_cov(cov_type, cov_label);*nested macro;

	/*%LET cov_type = Drug;*/
	/*%LET cov_label = drg;*/
	DATA libkeep.enr_&cov_type._cov_&_SiteAbbr.  (KEEP = c_type avg_x avg_evr avg_typ total_cov ever_cov);
	  length c_type $ 15 ;
		SET libsend.enr_cov_&_SiteAbbr. ;

		c_type    = "&cov_type."                        ;
		total_cov = &cov_label._tot                     ; /*Total number of coverages for this type*/
		ever_cov  = ever_&cov_label.                    ; /*Number of mrn ever covered for this type*/
    if mrn_cnt ge 0 then do ;
  		avg_x     = &cov_label._tot  / mrn_cnt          ; /*enrollment time per total*/
  		avg_evr   = ever_&cov_label. / mrn_cnt          ; /*ever enrolled per total*/
    end ;
    if ever_&cov_label. > 0 then do ;
		  avg_typ   = &cov_label._tot  / ever_&cov_label. ; /*times enrolled per ever enrolled*/
		end ;
	RUN;

	proc append base=libsend.ENR_COV_SUMMARY_&_SiteAbbr. data=libkeep.enr_&cov_type._cov_&_SiteAbbr.;
	RUN;

	%MEND avg_cov;

** Just in case there is a prior version of this dset laying about. ;
%RemoveDset(dset = libsend.ENR_COV_SUMMARY_&_SiteAbbr.) ;

%avg_cov(cov_type = Medicaid        , cov_label = caid);
%avg_cov(cov_type = Commericial     , cov_label = comm);
%avg_cov(cov_type = Private         , cov_label = priv);
%avg_cov(cov_type = StateSubsidized , cov_label = StSub);
%avg_cov(cov_type = SelfFunded      , cov_label = Self);
%avg_cov(cov_type = HighDeductible  , cov_label = HiD);
%avg_cov(cov_type = Medicare        , cov_label = care);
%avg_cov(cov_type = MedicareA       , cov_label = careA);
%avg_cov(cov_type = MedicareB       , cov_label = careB);
%avg_cov(cov_type = MedicareC       , cov_label = careC);
%avg_cov(cov_type = MedicareD       , cov_label = careD);
%avg_cov(cov_type = Other           , cov_label = othr);
%avg_cov(cov_type = HMO             , cov_label = hmo);
%avg_cov(cov_type = POS             , cov_label = pos);
%avg_cov(cov_type = PPO             , cov_label = ppo);
%avg_cov(cov_type = Indemnity       , cov_label = ind);
%avg_cov(cov_type = Drug            , cov_label = drg);

%MEND enr_data;

/* Coverage counts a cat_type at any given point (or span) */
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
	CREATE TABLE libsend.enr_&covlabel._&_SiteAbbr.  AS
	SELECT
		"&covtype." AS cat_type
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

DATA libsend.&label._age_error_summary_&_SiteAbbr. (DROP = label_type);
	MERGE &label._3 &label._5 &label._4 &label._6;
	BY label_type;
RUN;

%PUT &low_age &up_age;
%MEND enr_age;

%MACRO race_dist(dem_file);*Currently not used in qa;
DATA race_dist1;
	FORMAT race $Race.;
	SET &dem_file;
	IF race2 NE 'UN' THEN race = '-1';
	ELSE race = race1;
RUN;

PROC FREQ DATA = race_dist1;
	TABLES race / OUT = libsend.race_distribution_&_SiteAbbr;
RUN;

DATA race_dist2;
	FORMAT race $Race.;
	SET &dem_file;
	IF race2 NE 'UN' THEN race = '-1';
	ELSE race = race1;
	IF lowcase(compress(race)) NE 'unknown or not reported';
RUN;

PROC FREQ DATA = race_dist2;
	TABLES race / OUT = libsend.known_race_distribution_&_SiteAbbr.;
RUN;
%MEND race_dist;

/*Insurance frequencies                                                      */
%MACRO ins_freq(in_lib = libkeep., in_file = mem_gap_rm);

PROC FREQ DATA = &in_lib.&in_file;
	TABLES ins_commercial * ins_medicaid * ins_medicare * ins_privatepay
		/ OUT = libsend.ins_frequencies_&_SiteAbbr.;
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
        /*, put(%calcage(refdate = mdy(1, 1, year)), agecat.) as agegroup label = "Age on 1-jan of [[year]]"*/
		, put(%calcage(refdate = mdy(1, 1, year),BDtVar =BIRTH_DATE), agecat.) as agegroup label = "Age on 1-jan of [[year]]"
        , gender
		,race1,race2,race3,race4,race5
        , case when race2 eq 'UN' then put(race1, $RaceT.) else 'Multiple' end as race length = 25
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
    create table libsend.race_counts_&_SiteAbbr. as
    select year, agegroup, race
          , case when sum(prorated_total) between .01 and 4 then .a else sum(prorated_total) end as prorated_total format = comma20.2
          , case when sum(total)          between 1   and 4 then .a else sum(total)          end as total          format = comma20.0
    from libkeep.base_denominators
    group by year, agegroup, race
    ;
    create table libsend.gender_counts_&_SiteAbbr. as
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
%yr_end_enr(enr_file = libkeep.mem_yr, strt_yr = 2000, end_yr = 2009);

**	Observe number of dual coverages with respect to distinct Medicare & Medicaid coverages;
%ins_dual(input=libkeep.mem_yr_end, rec_sel=FIRST);
/*%cat_cnt takes an enrollment type file and counts insurance types on a  */
/*hierarchical basis per year, with ins1 being selected first and on down.  If*/
/*there are multiple records per year rec_sel will be used to select the first*/
/*or last record per mrn, per year.                                           */
/*OUTPUT: libsend.&output_count                         */
**%ins_cat_cnt(ins_file = libkeep.mem_yr_end, ins1 = ins_medicaid,
	ins2 = ins_medicare, ins3 = ins_privatepay, ins4 = ins_commercial,
	rec_sel = FIRST);
**v2 check--for comparison of v2 and for nostagia;
%cat_cnt(in_file = libkeep.mem_yr_end, out_file=ins_cat, cat1 = ins_medicaid,
	cat2 = ins_medicare, cat3 = ins_privatepay, cat4 = ins_commercial, rec_sel = FIRST);
	**V3 Ins Type Test 1:
** Preference given in following order:  INS_MEDICARE, INS_MEDICAID, INS_STATESUBSIDIZED, INS_OTHER;
%cat_cnt(in_file = libkeep.mem_yr_end, out_file=ins_cat_gvmt, cat1 = ins_medicaid,
	cat2 = ins_medicare, cat3 = INS_STATESUBSIDIZED, cat4 = INS_OTHER, rec_sel = FIRST);
	**V3 Ins Type Test 2:
** Preference given in following order:  INS_HIGHDEDUCTIBLE, INS_SELFFUNDED, INS_PRIVATEPAY, INS_COMMERCIAL;
%cat_cnt(in_file = libkeep.mem_yr_end, out_file= ins_cat_grp, cat1 = INS_HIGHDEDUCTIBLE,
	cat2 = INS_SELFFUNDED, cat3 = INS_PRIVATEPAY, cat4 = INS_COMMERCIAL, rec_sel = FIRST);
	** V3 plan type test 3;
** Preference given in following order:  PLAN_INDEMNITY, PLAN_POS, PLAN_PPO, PLAN_HMO 	;
%cat_cnt(in_file = libkeep.mem_yr_end, out_file=plan_cat, cat1 = PLAN_INDEMNITY,
	cat2 = PLAN_POS, cat3 = PLAN_PPO, cat4 = PLAN_HMO,	rec_sel = FIRST);


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
%mem_ret(mr_file=libkeep.mem_yr);

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
	, start_time = mdy(6,11,2009)
	, end_time = mdy(6,15,2009)
	, covlabel = mcare09jun11to15
);
%cov_at(
	covtype = ins_medicaid
	, start_time = mdy(2,15,2009)
	, end_time = mdy(2,28,2009)
	, covlabel = mcaid09feb15To28
);
%cov_at(
	covtype = ins_medicaid
	, start_time = mdy(1,01,2008)
	, end_time = mdy(2,28,2008)
	, covlabel = mcaid_08Jan01ToFeb28
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
PROC TRANSPOSE DATA = libsend.ins_cat_count_&_SiteAbbr. OUT = ic_count  (DROP = _LABEL_ _NAME_)	PREFIX = cnt_;
	BY cat_type;
	VAR count;
	ID year;
RUN;

PROC TRANSPOSE DATA = libsend.ins_cat_count_&_SiteAbbr. OUT = ic_percent  (DROP = _LABEL_ _NAME_)	PREFIX = pcnt_;
	BY cat_type;
	VAR percent;
	ID year;
RUN;

DATA libsend.ins_tp_cnt_&_SiteAbbr.;
	FORMAT cnt_2000 8. pcnt_2000 4.1 cnt_2001 8. pcnt_2001 4.1 cnt_2002 8.
		pcnt_2002 4.1 cnt_2003 8. pcnt_2003 4.1 cnt_2004 8. pcnt_2004 4.1
		cnt_2005 8. pcnt_2005 4.1 cnt_2006 8. pcnt_2006 4.1 cnt_2007 8.
		pcnt_2007 4.1 cnt_2008 8. pcnt_2008 4.1 cnt_2009 8. pcnt_2009 4.1 ;
		*cnt_2010 8. pcnt_2010 4.1;
	MERGE ic_count ic_percent;
	BY cat_type;
	IF cnt_2000 < 6 THEN cnt_2000 = 0;
	IF cnt_2001 < 6 THEN cnt_2001 = 0;
	IF cnt_2002 < 6 THEN cnt_2002 = 0;
	IF cnt_2003 < 6 THEN cnt_2003 = 0;
	IF cnt_2004 < 6 THEN cnt_2004 = 0;
	IF cnt_2005 < 6 THEN cnt_2005 = 0;
	IF cnt_2006 < 6 THEN cnt_2006 = 0;
	IF cnt_2007 < 6 THEN cnt_2007 = 0;
	IF cnt_2008 < 6 THEN cnt_2008 = 0;
	IF cnt_2009 < 6 THEN cnt_2009 = 0;
	*IF cnt_2010 < 6 THEN cnt_2010 = 0;
RUN;

DATA qa_error_warn (KEEP = e_type);
	FORMAT e_type $30.;
	SET libkeep.enr_not_in_demo libkeep.dup_demo_mrn libkeep.start_end_error
		libkeep.end_date_error libkeep.start_date_error libkeep.enr_overlap_error
		libkeep.gender_error libkeep.race_error libkeep.hispanic_error
		libkeep.drugcov_error libkeep.inscov_error libkeep.inscov_warn
		libkeep.plantp_warn;
RUN;

PROC SQL;
	CREATE TABLE libsend.qa_e_w_count_&_SiteAbbr. AS
	SELECT e_type , COUNT(*) AS count
	FROM qa_error_warn
	GROUP BY e_type;
QUIT;

OPTIONS ORIENTATION=landscape linesize=max pagesize=max;
ODS HTML FILE = "&OUT_SEND.\error_warn_counts_&_SiteAbbr..xls"(URL = none) Style = MINIMAL rs = none;

PROC PRINT DATA = libsend.enr_age_error_summary_&_SiteAbbr. n noobs;
	TITLE "Count of enrollments w/ age errors";
	TITLE2 '%enr_age output';
RUN;
PROC PRINT DATA = libsend.enr_cov_&_SiteAbbr. n noobs;
	TITLE "Count of various enrollments ";
	TITLE2 '%enr_data output';
RUN;
PROC PRINT DATA = libsend.enrl_contents_&_SiteAbbr. n noobs;
	TITLE "Enrollment contents";
	TITLE2 'proc contents output';
RUN;
PROC PRINT DATA = libsend.ins_dual_count_&_SiteAbbr. n noobs;
	TITLE "Dual Coverage by Year";
	TITLE2 '%ins_dual_cnt output';
RUN;
PROC PRINT DATA = libsend.ins_cat_count_&_SiteAbbr. n noobs;
	TITLE "Hierarchical Ins Category Counts by Year";
	TITLE2 '%cat_cnt output';
RUN;
PROC PRINT DATA = libsend.ins_tp_cnt_&_SiteAbbr. n noobs;
	TITLE "Hierarchical Ins Cat Counts by Year transposed";
RUN;
PROC PRINT DATA = libsend.ins_cat_grp_count_&_SiteAbbr. n noobs;
	TITLE "Hierarchical Group Insurance Category Counts by Year";
	TITLE2 '%cat_cnt output';
RUN;
PROC PRINT DATA = libsend.ins_Cat_gvmt_count_&_SiteAbbr. n noobs;
	TITLE "Hierarchical Government Insurance Category Counts by Year";
	TITLE2 '%cat_cnt output';
RUN;
PROC PRINT DATA = libsend.Plan_Cat_count_&_SiteAbbr. n noobs;
	TITLE "Hierarchical Plan Type Category Counts by Year";
	TITLE2 '%cat_cnt output';
RUN;
PROC PRINT DATA = libsend.ins_frequencies_&_SiteAbbr. n noobs;
	TITLE "Insurance Frequencies";
RUN;
PROC PRINT DATA = libsend.mrn_ret_cont_freq_&_SiteAbbr. n noobs;
	TITLE "Hierarchical Ins Cat Counts by Year";
	TITLE2 '%mem_ret output';
RUN;
PROC PRINT DATA = libsend.qa_e_w_count_&_SiteAbbr. n noobs;
	TITLE "Errors and Warnings with counts";
	TITLE2 '%qa output';
RUN;
ODS HTML CLOSE;

%make_count_tables ;

ODS HTML FILE = "&OUT_SEND.\gender_race_counts_&_SiteAbbr..xls"(URL = none) Style = MINIMAL rs = none;
 TITLE 'Gender Race Counts';
 TITLE2 ' ';
  %report_enrollment ;

ODS HTML CLOSE;

OPTIONS orientation=portrait linesize=139 pagesize=78;

%put SAS session ended at: %sysfunc(datetime(),datetime20.);*testing;

/*End print to log*/
proc printto;run;
