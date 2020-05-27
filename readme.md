# HCSRN Enrollment/Demographics/Language Workgroup QA package
Includes both the distributed code and the code for collating the data submitted by sites (under /admin).
## Brief Rationale/Purpose
This package generates a report and datasets from which we will be able to:

* Verify that the enrollment, demographics & language files adhere to the relevant specifications.
* Generates descriptives (frequencies & percents) which we can compare across sites, and possibly detect differences across sites that may indicate not-yet-known problems (or just real differences) with one or more site's data.

## Programmers
Roy Pardee (@kaiser-roy) & Paul Hitz

## Instructions

1. Make a local copy of the package by either:
    a. using git to clone [this repository](https://github.com/rpardee/vdw-qa-enroll-demog) (recommended) or
    b. use a browser to download the repository [as a zip file](https://github.com/rpardee/vdw-qa-enroll-demog/archive/master.zip).
2. Make the edits indicated at the beginning of main.sas, and then
3. Run main.sas.

Note git users only need to do step 1. above once.  For any subsequent runs, all you have to do is make sure you have the most recent changes to the code by running ```git pull origin master``` at a command line, or use your preferred git client (e.g., sourcetree, gitkraken) to perform that same operation.

> _A Note On The descriptives for capture of EMR data_
>
> Optionally, if you have non-EMR data in your Social History, or Vital Signs files, you may want to edit the two calls to %get_rates that stratify on incomplete_emr in order to limit the records considered to those that actually come from your EMR. These calls are on lines 1305 and 1315 of the main program (/lib/vdw_enroll_demog_qa.sas). You can see the syntax to use from the commented-out specifications for the parameter &extrawh (for 'extra WHERE condition').

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

Please zip & send to @kaiser-roy via the [KPWHRI Secure File Transfer app](http://projects.kpwashingtonresearch.org/sft/) (use the HCSRN_VIG folder) the following outputs from the /share subdirectory:

* the ::site abbreviation::_vdw_enroll_demog_qa.log file.
* ::site abbreviation::_vdw_enroll_demog_qa.html - The output report.
* The 9 sas datasets you find in the &root/to_send directory:
    * ::site abbreviation::_demog_freqs.sas7bdat - (Low-count-censored) frequencies & percents on several variables in demographics.
    * ::site abbreviation::_enroll_freqs.sas7bdat - Ditto, for enrollment.
    * ::site abbreviation::_noteworthy_vars.sas7bdat - A list of any vars that are off-spec, or deviate from spec in some way.
    * ::site abbreviation::_tier_one_results.sas7bdat - A list of the checks done in the program, along with pass/fail assessment & other information.
    * ::site abbreviation::_lang_stats.sas7bdat - Language table statistics.
    * ::site abbreviation::_flagcorr.sas7bdat - correlations between the insurance and plan type flags.
    * ::site abbreviation::_enroll_duration_stats.sas7bdat - percentiles, mean & standard deviations for the durations of the enrollment periods at your site.
    * ::site abbreviation::capture_rates.sas7bdat - rates of records in other implemented VDW files for enrollees broken out by the appropriate incomplete_* field.
    * ::site abbreviation::_unenrl_rates.sas7bdat - rates of ute, lab, tumor, rx, social hx & vitals records that fall outside of an enrollment period.
