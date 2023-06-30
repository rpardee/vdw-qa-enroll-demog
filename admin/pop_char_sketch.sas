/*********************************************
* Roy Pardee
* KP Washington Health Research Institute
* (206) 287-2078
* roy.e.pardee@kp.org
*
* C:\Users/O578092/Documents/vdw/voc_enroll/admin/frolics/pop_char_sketch.sas
*
* HCSRN Population Characteristics Sketch
*********************************************/

%include "h:/SAS/Scripts/remoteactivate.sas" ;

options
  linesize  = 150
  pagesize  = 80
  msglevel  = i
  formchar  = '|-++++++++++=|-/|<>*'
  dsoptions = note2err
  nocenter
  noovp
  nosqlremerge
  extendobscounter = no
;

* For detailed database traffic: ;
* options sastrace=',,,d' sastraceloc=saslog no$stsuffix ;

ods listing close ;

/*

lets see how close I can get to the stats in

"\\groups.ghc.org\data\CTRHS\Crn\voc\enrollment\reports_presentations\HCSRN Descriptives - Formatted Summary Table 2018.pptx"

*/

proc format cntlout = sites ;
  value $s (default = 22)
    /* 'HPRF' = 'HealthPartners' */
    /* 'LCF'  = 'Lovelace' */
    /* "FAL"  = "Fallon Community Health Plan" */
    /* "LHS"  = "Lovelace Health Systems" */
    /* 'PAMF' = 'Palo Alto' */
    'HPHC' = 'Harvard'
    'HPI'  = 'HealthPartners'
    'MCRF' = 'Marshfield'
    'BSWH' = 'Baylor Scott & White'
    'HFHS' = 'Henry Ford'
    'GHS'  = 'Geisinger'
    'GHC'  = 'KP Washington'
    'KPWA' = 'KP Washington'
    'SH'   = 'Sutter Health'
    'EIRH' = 'Essentia'
    'KPCO' = 'KP Colorado'
    'KPNW' = 'KP Northwest'
    'KPGA' = 'KP Georgia'
    "KPNC" = "KP Northern California"
    "KPSC" = "KP Southern California"
    "KPHI" = "KP Hawaii"
    "FA"   = "Fallon Community HP"
    "KPMA" = "KP Mid-Atlantic"
    "SLU"  = "St. Louis Univ/AHEAD"
  ;
  value thrs
    . = 'N/A'
    other = [percent6.0]
  ;
  value $race
    'HP' = 'Native Hawaiian or Other Pacific Islander'
    'IN' = 'American Indian/Alaska Native'
    'AS' = 'Asian'
    'BA' = 'Black or African American'
    'WH' = 'White'
    'MU' = 'More than one race, particular races unknown or not reported'
    'OT' = 'Other'
    'UN' = 'Unknown or Not Reported'
    Other = 'bad'
  ;
  value $eb
    "G" = "Geographic Basis"
    "I" = "Insurance Basis"
    "B" = "Both Insurance and Geographic bases"
    "P" = "Non-enrollee Patient"
  ;
  value $gen
    'M' = 'Male'
    'F' = 'Female'
    'O' = 'Other'
    'X' = 'Neither Male nor Female'
    'U' = 'Unknown'
  ;
  value $ta
    '00to', '00to04'    = '3'
    '05to', '05to09'    = '8'
    '10to', '10to14'    = '13'
    '15to', '15to19'    = '18'
    '20to', '20to29'    = '28'
    '30to', '30to39'    = '38'
    '40to', '40to49'    = '48'
    '50to', '50to59'    = '58'
    '60to', '60to64'    = '62'
    '65to', '65to69'    = '68'
    '70to', '70to74'    = '72'
    'ge_7', 'ge_75'     = '76'
  ;
  value shrtage
    low -< 19 = '0 to 19'
    20  -< 64 = '20 to 64'
    65 - high = '65+'
  ;
  value $v
    '00to', '00to04'    = '    < 5'
    '05to', '05to09'    = '05 - 09'
    '10to', '10to14'    = '10 - 14'
    '15to', '15to19'    = '15 - 19'
    '20to', '20to29'    = '20 - 29'
    '30to', '30to39'    = '30 - 39'
    '40to', '40to49'    = '40 - 49'
    '50to', '50to59'    = '50 - 59'
    '60to', '60to64'    = '60 - 64'
    '65to', '65to69'    = '65 - 69'
    '70to', '70to74'    = '70 - 74'
    'ge_7', 'ge_75'     = '>= 75'
    'Asia', 'Asian'     = 'Asian'
    'Blac', 'Black'     = 'Black/African American'
    'Unkn', 'Unknown'   = 'Unknown'
    'Whit', 'White'     = 'White'
    'Nati', 'Native'    = 'Native American'
    'Pac' , 'Pac Isl'   = 'Pacific Islander'
    'Both'              = 'Both'
    'Insu', 'Insurance' = 'Insurance'
    'Non-'              = 'Non-member patient'
    'C'                 = 'Choose not to disclose'
    'E'                 = 'External'
    'F'                 = 'Female'
    'FF'                = 'Female'
    'FM'                = 'Female to Male transgender'
    'GQ'                = 'Genderqueer or non-conforming or non-binary or genderfluid'
    'I'                 = 'Intersex'
    'K'                 = 'Yes, known to be incomplete'
    'M'                 = 'Male'
    'MF'                = 'Male to Female transgender'
    'MM'                = 'Male'
    'N'                 = 'No'
    'ND'                = 'Choose not to disclose'
    'O'                 = 'Other'
    'OT'                = 'Other'
    'U'                 = 'Unknown'
    'UN'                = 'Unknown'
    'X'                 = 'Not implemented'
    'Y'                 = 'Yes'
    '     .' = 'Unknown'
  ;
  value $vars
      'agegroup'            = 'Age of Enrollees'
      'drugcov'             = 'Has at least `some` drug coverage?'
      'enrollment_basis'    = 'Basis for including this person/period in Enrollment'
      'sex_admin'           = 'Administrative Sex'
      'hispanic'            = 'Is Hispanic?'
      'ins_commercial'      = 'Has Commercial Coverage?'
      'ins_highdeductible'  = 'Has coverage in a High Deductible Plan?'
      'ins_medicaid'        = 'Has Medicaid coverage?'
      'ins_medicare'        = 'Has Medicare coverage?'
      'ins_medicare_a'      = 'Has medicare part A coverage?'
      'ins_medicare_b'      = 'Has medicare part B coverage?'
      'ins_medicare_c'      = 'Has medicare part C coverage?'
      'ins_medicare_d'      = 'Has medicare part D coverage?'
      'ins_other'           = 'Has `other` type insurance coverage?'
      'ins_privatepay'      = 'Has Private Pay coverage?'
      'ins_selffunded'      = 'Has Self-Funded coverage?'
      'ins_statesubsidized' = 'Has State-subsidized coverage?'
      'needs_interpreter'   = 'Needs an interpreter?'
      'outside_utilization' = 'Do we know VDW rx/encounter capture is incomplete for this person/period?'
      'pcc_probably_valid'  = 'Valid Primary Care Clinic assigned?'
      'pcp_probably_valid'  = 'Valid Primary Care Physician assigned?'
      'plan_hmo'            = 'Enrolled in an HMO Plan?'
      'plan_indemnity'      = 'Enrolled in an Indemnity plan?'
      'plan_pos'            = 'Enrolled in a Point-Of-Service plan?'
      'plan_ppo'            = 'Enrolled in a Preferred Provider Organization plan?'
      'race'                = 'Race/Ethnicity'
      'incomplete_emr'      = 'Capture of EMR data known incomplete?'
      'incomplete_inpt_enc' = 'Capture of inpatient encounters known incomplete?'
      'incomplete_lab'      = 'Capture of lab results known incomplete?'
      'incomplete_outpt_enc'= 'Capture of outpatient encounters known incomplete?'
      'incomplete_outpt_rx' = 'Capture of outpatient pharmacy known incomplete?'
      'incomplete_tumor'    = 'Capture of tumor data known incomplete?'
      'sexual_orientation1' = 'Sexual Orientation (unknowns elided)'
      'gender_identity'     = 'Gender Identity (unknowns elided)'
      'sex_at_birth'        = 'Sex Assigned At Birth (unknowns elided)'
  ;
  value $varcat
    'agegroup'             = 'Demogs'
    'sex_admin'            = 'Demogs'
    'sex_at_birth'         = 'Demogs'
    'sexual_orientation1'  = 'Demogs'
    'gender_identity'      = 'Demogs'
    'hispanic'             = 'Demogs'
    'race'                 = 'Demogs'
    'needs_interpreter'    = 'Demogs'
    'drugcov'              = 'Benefit'
    'enrollment_basis'     = 'Meta'
    'outside_utilization'  = 'Meta'
    'pcc_probably_valid'   = 'Meta'
    'pcp_probably_valid'   = 'Meta'
    'incomplete_emr'       = 'Meta'
    'incomplete_inpt_enc'  = 'Meta'
    'incomplete_lab'       = 'Meta'
    'incomplete_outpt_enc' = 'Meta'
    'incomplete_outpt_rx'  = 'Meta'
    'incomplete_tumor'     = 'Meta'
    'ins_commercial'       = 'Ins type'
    'ins_highdeductible'   = 'Ins type'
    'ins_medicaid'         = 'Ins type'
    'ins_medicare'         = 'Ins type'
    'ins_medicare_a'       = 'Ins type'
    'ins_medicare_b'       = 'Ins type'
    'ins_medicare_c'       = 'Ins type'
    'ins_medicare_d'       = 'Ins type'
    'ins_other'            = 'Ins type'
    'ins_privatepay'       = 'Ins type'
    'ins_selffunded'       = 'Ins type'
    'ins_statesubsidized'  = 'Ins type'
    'plan_hmo'             = 'Plan type'
    'plan_indemnity'       = 'Plan type'
    'plan_pos'             = 'Plan type'
    'plan_ppo'             = 'Plan type'
    ;
  * from https://communities.sas.com/t5/SAS-Programming/Million-Format/td-p/440121 ;
  picture hicount (round)
    1E03-<1000000='000K' (mult=.001  )
    1E06-<1000000000='000.9M' (mult=.00001)
    1E09-<1000000000000='000.9B' (mult=1E-08)
    1E12-<1000000000000000='000.9T' (mult=1E-11)
  ;
  value $so
    'B' = 'B: Bisexual'
    'T' = 'T: Heterosexual'
    'M' = 'M: Homosexual'
    'A' = 'A: Asexual'
    'P' = 'P: Pansexual'
    'Q' = 'Q: Queer'
    'O' = 'O: Other'
    'D' = 'D: Does not know'
    'N' = 'N: Choose not to disclose'
    'U' = 'U: Not asked/no information'
    other  = 'bad'
  ;
quit ;

%let prgs = \\groups.ghc.org\data\CTRHS\Crn\voc\enrollment\programs ;

libname col "&prgs\submitted_data" ;


proc sort nodupkey data = col.raw_enrollment_counts out = site_last_years ;
  by site year ;
run ;

data site_last_years ;
  set site_last_years ;
  by site ;
  var_name = 'Total Membership' ;
  total = total_count ;
  if last.site ;
  keep site year var_name total ;
run ;

proc sql ;
  create table s.grist as
  select ef.site
        , ef.var_name
        , ef.year
        , put(ef.value, $v.) as value
        , right(put(ef.pct, percent8.1)) as total
  from col.enroll_freqs as ef
    inner join site_last_years as ly on ef.site = ly.site and ef.year = ly.year
  where ef.var_name in ('agegroup', 'sex_admin', 'ins_medicaid', 'ins_medicare', 'ins_other',
                       'ins_privatepay', 'ins_selffunded', 'ins_statesubsidized',
                       'ins_commercial', 'ins_highdeductible', 'race', 'hispanic')
    and value NOT in ('U', 'N', 'M', 'E', 'O', 'X')
  order by ef.site, ef.var_name, ef.value
  ;

  insert into s.grist (site, year, var_name, total)
  select site, year, var_name, put(total, hicount.) as total
  from site_last_years
  ;

  insert into s.grist (site, year, var_name, total)
  select site, ., 'Year submitted' as var_name, put(year, 4.0) as total
  from site_last_years
  ;

quit ;

proc sort nodupkey data = s.grist out = s.gnu ;
  by var_name value site ;
run ;

proc transpose data = s.gnu out = s.tposed (drop = _:) ;
  var total ;
  id site ;
  by var_name value ;
run ;

proc format ;
  value $srt
    'Year submitted'      = ' 0'
    'Total Membership'    = ' 1'
    'agegroup'            = ' 2'
    'sex_admin'           = ' 3'
    'ins_commercial'      = ' 4'
    'ins_medicaid'        = ' 5'
    'ins_medicare'        = ' 6'
    'ins_privatepay'      = ' 7'
    'ins_highdeductible'  = ' 8'
    'ins_selffunded'      = ' 9'
    'ins_statesubsidized' = '10'
    'ins_other'           = '11'
    'race'                = '12'
    'hispanic'            = '13'
  ;
  value $cat
    'Year submitted'      = 'Overall'
    'Total Membership'    = 'Overall'
    'agegroup'            = 'Age'
    'sex_admin'           = 'Sex'
    'ins_commercial'      = 'Insurance'
    'ins_medicaid'        = 'Insurance'
    'ins_medicare'        = 'Insurance'
    'ins_privatepay'      = 'Insurance'
    'ins_highdeductible'  = 'Insurance'
    'ins_selffunded'      = 'Insurance'
    'ins_statesubsidized' = 'Insurance'
    'ins_other'           = 'Insurance'
    'race'                = 'Race'
    'hispanic'            = 'Ethnicity'
  ;
  value $ins
    'ins_commercial'      = 'Commercial'
    'ins_medicaid'        = 'Medicaid'
    'ins_medicare'        = 'Medicare'
    'ins_privatepay'      = 'Private Pay'
    'ins_highdeductible'  = 'High Deductible'
    'ins_selffunded'      = 'Self Funded'
    'ins_statesubsidized' = 'State Subsidized'
    'ins_other'           = 'Other'
    ;
quit ;

data s.hcsrn_population_characteristics ;
  set s.tposed ;
  srt = put(var_name, $srt.) ;
  cat = put(var_name, $cat.) ;
  if var_name =: 'ins_' then value = put(var_name, $ins.) ;
  * long-standing bug in BSWs enrollment makes the membership figure bogus ;
  if var_name = 'Total Membership' then bswh = '?' ;
  if var_name in ('hispanic', 'Total Membership', 'Year submitted') then value = var_name ;
run ;

proc sort data = s.hcsrn_population_characteristics ;
  by srt ;
run ;

data s.hcsrn_population_characteristics ;
  set s.hcsrn_population_characteristics ;
  by cat notsorted ;
  if not first.cat then cat = ' ' ;
run ;

* from http://support.sas.com/kb/23/348.html ;
proc template;
  define style styles.justify;
    Parent=styles.magnify;
    Style Data from Data /
         Just=right;
  end;
run;

options orientation = landscape ;
ods graphics / height = 8in width = 10in imagemap = on ;

* %let out_folder = /C/Users/O578092/Documents/vdw/voc_enroll/admin/frolics/ ;
%let out_folder = %sysfunc(pathname(s)) ;

ods html5 path = "&out_folder" (URL=NONE)
         body   = "pop_char_sketch.html"
         (title = "pop_char_sketch output")
         style = styles.justify
         nogfootnote
         device = svg
         /* options(svg_mode = "embed") */
          ;

  title1 "HCSRN Population Characteristics" ;
  proc print data = s.hcsrn_population_characteristics (drop = var_name srt) ;
    id cat value ;
    label
      cat = ' '
      value = ' '
    ;
  run ;

run ;

ods _all_ close ;




