# HCSRN Enrollment/Demographics/Language Workgroup QA package
Includes both the distributed code and the code for collating the data submitted by sites (under /admin).
## Brief Rationale/Purpose
This package generates a report and datasets from which we will be able to:

* Verify that the enrollment, demographics & language files adhere to the relevant specifications.
* Generates descriptives (frequencies & percents) which we can compare across sites, and possibly detect differences across sites that may indicate not-yet-known problems with one or more site's data.

## Programmers
Roy Pardee (@kaiser-roy) & Paul Hitz

## Instructions

1. Make a local copy of the package by either:
    a. using git to clone [this repository](https://github.com/rpardee/vdw-qa-enroll-demog) (recommended) or
    b. use a browser to download the repository [as a zip file](https://github.com/rpardee/vdw-qa-enroll-demog/archive/master.zip).
2. Make the edits indicated at the beginning of main.sas, and then
3. Run main.sas.

Note git users only need to do step 1. above once.  For any subsequent runs, all you have to do is make sure you have the most recent changes to the code by running ```git pull origin master``` at a command line, or use your preferred git client (e.g., sourcetree, gitkraken) to perform that same operation.

> _A Note On The **incomplete_emr** descriptives_
>
> Optionally, if you have non-EMR data in your Social History, or Vital Signs files, you may want to edit the two calls to %get_rates that stratify on incomplete_emr in order to limit the records considered to those that actually come from your EMR. These calls are on lines 1356 and 1366 of the main program (/lib/vdw_enroll_demog_qa.sas). You can see the syntax to use from the commented-out specifications for the parameter &extrawh (for 'extra WHERE condition').

Please don't hesitate to get in touch with @kaiser-roy if you have any questions about this.

# Data Required
This program requires the following VDW files:

* Enrollments
* Demographics
* Person Languages
* For the completeness variable evaluation & unenrolled utilization portion:
    * Utilization: Encounters
    * Pharmacy fills
    * Tumor
    * Lab Results
    * Social History
    * Vital Signs

## Dependencies
The program depends on the various sas programs that are bundled in the zip and should be found via the &root macro var set in on line 68 in the edit section of the program.
## Outputs
This program produces log output in the /share directory, and several other outputs to that and the /local_only directories, both under &root.

**Outputs that are NOT requested**

This program produces several datasets in the &root/local_only directory.  These will contain raw data (including MRNs) & are for your use in drilling down on any QA problems found.

**Outputs that ARE requested**

Please zip & send to @kaiser-roy via the [KPWHRI Secure File Transfer app](http://projects.kpwashingtonresearch.org/sft/) the following:

* the vdw_enroll_demog_qa.log file, which you will find in the &root directory.
* The 21 files you find in the &root/to_send directory:
    * ::site abbreviation::_vdw_enroll_demog_qa.html - The output report.
    * ::site abbreviation::_demog_freqs.sas7bdat - (Low-count-censored) frequencies & percents on several variables in demographics.
    * ::site abbreviation::_enroll_freqs.sas7bdat - Ditto, for enrollment.
    * ::site abbreviation::_noteworthy_vars.sas7bdat - A list of any vars that are off-spec, or deviate from spec in some way.
    * ::site abbreviation::_tier_one_results.sas7bdat - A list of the checks done in the program, along with pass/fail assessment & other information.
    * ::site abbreviation::_lang_stats.sas7bdat - Language table statistics.
    * ::site abbreviation::_flagcorr.sas7bdat - correlations between the insurance and plan type flags.
    * ::site abbreviation::_enroll_duration_stats.sas7bdat - percentiles, mean & standard deviations for the durations of the enrollment periods at your site.
    * ::site abbreviation::_ute_out_rates_by_enctype - rates of outpatient encounters for enrollees broken out by incomplete_outpt_enc
    * ::site abbreviation::_ute_in_rates_by_enctype - rates of inpatient encounters for enrollees broken out by incomplete_inpt_enc
    * ::site abbreviation::_lab_rates - rates of lab results for enrollees by incomplete_lab
    * ::site abbreviation::_tumor_rates - rates of tumors for enrollees by incomplete_tumor
    * ::site abbreviation::_rx_rates - rates of rx fills for enrollees by incomplete_outpt_rx
    * ::site abbreviation::_emr_s_rates - rates of social history records for enrollees by incomplete_emr
    * ::site abbreviation::_emr_v_rates - rates of vital signs records for enrollees by incomplete_emr
    * ::site abbreviation::_enc_unenrolled - counts of encounters for people not appearing in enrollment on the day of the encounter.
    * ::site abbreviation::_lab_unenrolled - counts of lab results for people not appearing in enrollment on the day of the lab result.
    * ::site abbreviation::_tum_unenrolled - counts of tumors for people not appearing in enrollment on the day of the tumor diagnosis.
    * ::site abbreviation::_rx_unenrolled - counts of rx fills for people not appearing in enrollment on the day of the rx fill.
    * ::site abbreviation::_shx_unenrolled - counts of social history recs for people not appearing in enrollment on the day of the record.
    * ::site abbreviation::_vsn_unenrolled - counts of vital signs for people not appearing in enrollment on the day of the vital sign.
