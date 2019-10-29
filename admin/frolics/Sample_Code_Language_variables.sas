/*
  Sample code given by Wei Tao of KP Northern California (Wei.X.Tao@kp.org).
*/

************************************************************************* ;
********Sample Code 1: ************************************************** ;
************************************************************************* ;
* TASK1: CREATE SOURCE_DOBSEX VARIABLE WHICH INDICATES IF                 ;
*         DOB & SEX COME FROM CLARITY PATIENT and DB2 PATIENT TABLE       ;
* TASK2: CREATE PRIMARY_LANGUAGE AND NEEDS_INTERPRETER                    ;
* 	FROM PATIENT TABLES and PAT_ENC TABLE                                 ;
************************************************************************* ;
* SOURCE DATA                       			   		                          ;
* DATA1: FROM HCCLNC.PATIENT          			   	   	                      ;
* DATA2: FROM PAT.VPATIENT           			   	   	                        ;
* DATA3: FROM PAT_ENC          			   		   	                            ;
*                                                                         ;
* LOGIC:                                     				 		                  ;
*     1. FOR DOB, GENDER variables,                                    	  ;
*     	   if any MRN in HCCLNC.PATIENT then get it              	        ;
*   	    else get it from PAT.VPATIENT                                   ;
*                                                                      	  ;
*     2. For primary_lanuage:                                          	  ;
*	 a. In PAT.VPATIENT table,                                     	        ;
*  	     If PREFRD_LANG1_SPOKN is missing         		                    ;
*   		then use second one PREFRD_LANG2_SPOKN  	                        ;
*                                                                	        ;
*  	 b. If value is not missing from HCCLNC.PATIENT then get it    	      ;
*     	    else get it from PAT.VPATIENT                              	  ;
*                                                                      	  ;
*  	 c. Using ISO-639-2 table to map the lanugage to ISO Code	            ;
*			                                 		                                ;
*     3. For needs_interpreter:                                        	  ;
* 	 a. If value is not missing from HCCLNC.PATIENT then get it    	      ;
*           else get it from PAT.VPATIENT                              	  ;
*                                                                      	  ;
* 	b. Used value from HCCLNC.PATIENT and PAT.VPATIENT as base,    	      ;
*     	   if needs_interpreter = 'Y' in PAT_ENC table                	  ;
* 		and 							                                                  ;
*		newer than PATIENT tables                           	                ;
*     	 	then use the one from PAT_ENC table to replace. 	  						;
************************************************************************* ;
************************************************************************* ;

data _null_;
call symput('Update',put(today(),date9.));
run;
%put the Update is &Update.;


/* SUNFIRE VERSION*/
	libname out "&sun./tmsuser/w409008/VDW/DEMO/V3/Temp";
	libname Source "&sun./tmsuser/w409008/VDW/DEMO/V3/Source";

TITLE2 "WXT Update Sumdata2_ID.sas at &Update.;";
footnote1 "PROGRAM=&pgm";
run;

OPTIONS MSTORED  SASMSTORE=CATALOGS
        NOCENTER MACROGEN SOURCE2 NOFMTERR
        FMTSEARCH=(BAD.BADMRN LIBRARY.FORMATS);

proc format;
value $missmrn
 '00000000'='00000000'
 '        '='blank   '
 other     ='other'
 ;
value DOBSEX
 1='PATDEM '
 2='CLARITY'
 ;
run;

*******************************************************************;
* LOADING SOURCE DATA                       			   ;
* DATA1: FROM HCCLNC.PATIENT          			   	   ;
* DATA2: FROM PAT.VPATIENT           			   	   ;
* DATA3: FROM PAT_ENC          			   		   ;
*******************************************************************;

/**********************************************************************
**Loading SOURCE DATA 1 					     **
**Loading primary language and Interpreter values from PATIENT table **
***********************************************************************/
*LOADING DATA1: from HCCLNC.PATIENT table;
proc sql;
  CONNECT TO TERADATA AS TERA
    (user=&hcuser  pw=&hcpass tdpid=tdpn);
  create table source.PATID as
  SELECT *
  FROM CONNECTION TO TERA
  ( select
  	 a.PAT_MRN_ID
  	 , a.SEX
  	 , a.BIRTH_DATE
  	 , a.reg_date
  	 , b.name
  	 , b.ABBR
  	 , a.INTRPTR_NEEDED_YN as needs_interpreter
     from HCCLNC.PATIENT a
     	  left join ZC_LANGUAGE b
     	  on a.language_c=b.language_c
     	  );
quit;


proc sql;
  create table PATID1 as
  SELECT a.*
  	, b.ISO_6392 as primary_language
  FROM source.PATID as a
     left join source.ISO6392 as b
     	  on strip(upcase(a.name))=strip(upcase(b.Eng_Lang))
    ;
quit;

DATA allpat;
     SET  PATID1 (RENAME=(SEX=PAT_SEX));
     FORMAT BIRTH_DA DATE9.;
     BIRTH_DA=datepart(BIRTH_DATE);
     IF BIRTH_DA NE .;
     KEEP MRN BIRTH_DA PAT_SEX reg_date primary_language needs_interpreter name;
RUN;

/*************************************************************
**Loading SOURCE DATA 2 		   	            **
**Loading Interpreter value from VPATIENT table **************
*************************************************************/
PROC SQL ;
  CONNECT TO DB2 (SSID=DSN2) ;
  CREATE TABLE source.PATDEM AS
    SELECT *
    FROM CONNECTION TO DB2
      (SELECT *
	FROM PAT.VPATIENT
      ) ;
quit;

proc freq data = source.PATDEM;
table INTRPTR_REQ_CODE PREFRD_LANG1_SPOKN;
run;

*to using second option if first one is missing;
data patdem;
set source.PATDEM;
if PREFRD_LANG1_SPOKN ='' and PREFRD_LANG2_SPOKN ne ''
	then PREFRD_LANG1_SPOKN = PREFRD_LANG2_SPOKN;
run;

proc sql;
create table patdema as
select a.*
	, b.ISO_6392 as primary_language
from PATDEM as a
  left join source.ISO6392 as b
  on strip(a.PREFRD_LANG1_SPOKN)=strip(upcase(b.Eng_Lang));
quit;

DATA PATDEM1;
  SET patdema(KEEP=MRN BIRTH_DATE PAT_SEX LAST_VERF_DATE
  		INTRPTR_REQ_CODE PREFRD_LANG1_SPOKN primary_language
	RENAME=(LAST_VERF_DATE=REG_DATE
		BIRTH_DATE=BIRTH_DA
		INTRPTR_REQ_CODE=needs_interpreter));
  IF BIRTH_DA NE .;
  RUN;

/*************************************************************
**Loading SOURCE DATA 3 		   	            **
**Loading Interpreter value from PAT_ENC table ***************
*************************************************************/

proc sql;
  CONNECT TO TERADATA AS TERA
    (user=&hcuser  pw=&hcpass tdpid=tdpn);
  create table source.PAT_ENC as
  SELECT *
  FROM CONNECTION TO TERA
  (  SELECT a.PAT_MRN_ID
  	,b.PAT_ID
  	,b.interpreter_need_yn as needs_interpreter
  	,b.CONTACT_DATE
  	FROM HCCLNC.PATIENT a
       inner join HCCLNC.PAT_ENC b
     	  on a.pat_id=b.pat_id
     	 where b.interpreter_need_yn = 'Y'
     	  );
quit;

*******************************************************************;
*Merged PATIENT tables ALLPAT and PATDEM together 		   ;
*set the order to select data from ALLPAT first			   ;
*******************************************************************;
DATA PAT2;
     SET ALLPAT(IN=AA) PATDEM1(IN=BB);
     length SOURCE_DOBSEX $12;
     IF AA THEN ORDER=1;
     IF BB THEN ORDER=2;
     SOURCE_DOBSEX=PUT(ORDER,dobsex.);
     LABEL  SOURCE_DOBSEX='SOURCE OF DOB & SEX (CLARITY or PATDEM)';
RUN;

PROC FREQ DATA=PAT2;
TABLES SOURCE_DOBSEX*ORDER/MISSING;
RUN;

************************************************************************;
*LOGIC to get the Language and interpreter from two PATIENT tables      ;
*   If first source is missing						;
*   Then use the second non-missing one 				;
************************************************************************;
*working on primary_language
proc sort data = PAT2;
by MRN descending primary_language;
run;

data PAT2a;
set PAT2;
retain plang;
BY mrn;
if first.mrn then do;
	plang =primary_language;
end;
else do;
	if primary_language = '' then do;
		primary_language=plang;
	end;
end;
drop plang;
run;

*working on needs_interpreter;
proc sort data = PAT2a;
by MRN descending needs_interpreter;
run;

data PAT2b;
set PAT2a;
retain ninter;
BY mrn;
if first.mrn then do;
	ninter=needs_interpreter;
end;
else do;
	if needs_interpreter = '' then do;
		needs_interpreter=ninter;
	end;
end;
drop ninter;
run;

*******************************************************************;
*Extract MRN from ALLPAT if there is 				   ;
*else select MRN from PATDEM					   ;
*******************************************************************;
PROC SORT DATA=pat2b;
     BY MRN ORDER;
run;

DATA PAT3;
     SET pat2b;
     BY MRN ORDER;
     IF FIRST.MRN;
     DROP ORDER;
     RUN;

PROC SORT DATA=PAT3;
     BY MRN;
     RUN;

************************************************************************;
*add PAT_ENC needs_interpreter = 'Y' and newer than one in PATIENT table;
*To get the recently record where needs_interpreter = 'Y'		;
************************************************************************;
proc sort data = source.PAT_ENC;
by PAT_MRN_ID descending Contact_date;
run;

data pat_enc;
set source.PAT_ENC;
by PAT_MRN_ID descending Contact_date;
if first.PAT_MRN_ID;
MRN=SUBSTR(PAT_MRN_ID,5,8);
run;

proc sort data =pat_enc;
by mrn descending CONTACT_DATE;
run;

data pat_enc1(rename = (CONTACT_DATE=REG_DATE));
set pat_enc;
by mrn descending CONTACT_DATE;
if first.mrn;
keep MRN needs_interpreter CONTACT_DATE;
run;

data temp;
set PAT3 (in=a keep = MRN needs_interpreter REG_DATE)
    pat_enc1 (in=b keep = MRN needs_interpreter REG_DATE);
if a then Source ='PATIENT';
if b then Source = 'PAT_ENC';
run;

title "Freq of temp";
proc freq data = temp;
table needs_interpreter*Source/MISSING list;
run;

proc sort data = temp;
by MRN descending REG_DATE;
run;

data temp1;
set temp;
by MRN descending REG_DATE;
if first.MRN;
run;

title "Freq of temp1 - after merged!";
proc freq data = temp1;
table needs_interpreter*Source/MISSING list;
run;

*******************************************************************;
*Merged new language/interpreter back to main table PAT3	   ;
*******************************************************************;
data PAT3a;
set PAT3;
drop needs_interpreter REG_DATE;
run;

proc sql;
create table PAT4 as
select a.*,b.needs_interpreter, b.REG_DATE from PAT3a as a
inner join temp1 as b
on a.MRN = b.MRN;
quit;

proc freq data = PAT4;
table needs_interpreter;
run;
;
DATA out.ID;
     SET PAT4(KEEP=BIRTH_DA MRN PAT_SEX SOURCE_DOBSEX
     		primary_language needs_interpreter
              WHERE=(MRN NOT IN ('00000000',' ')));
       if primary_language='' then primary_language = 'unk';
      if needs_interpreter='' then needs_interpreter = 'U';
      RUN;

PROC CONTENTS DATA=out.ID;
RUN;


PROC MEANS DATA=out.ID;
      RUN;

title "PATDEM1 data sample";
proc print  data =PATDEM1 (obs=10);
run;
*******************************************************************;
*************** END OF PROGRAM 			    ***************;
*******************************************************************;






************************************************************************;
********Sample Code 2: *************************************************;
********Assigned code fo language 'TONGAN'	************************;
********it will based on race, which could be **************************;
********either the African ethnic group (tog) **************************;
********or the Pacific Island Kingdom of Tonga (ton).*******************;
************************************************************************;

***After Merged with RACE table, Below code is taking care the 'TONGAN'*;
***NOTE: In the mapping table, this language intially mapped to 'nnn;  *;

if primary_language = 'nnn' then do;
   if RACE2 ne '' then primary_language='unk';
   else if substr(RACE1,1,2) in ('AS','HP') then primary_language = 'ton';
   else if substr(RACE1,1,2) in ('BA') then primary_language = 'tog';
   else primary_language='unk';
end;
*******************************************************************;
*************** END OF PROGRAM 			    ***************;
*******************************************************************;
