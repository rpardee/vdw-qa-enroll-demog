# HCSRN Enrollment/Demographics/Language Workgroup QA package
Includes both the distributed code and the code for collating the data submitted by sites (under /admin).
## Brief Rationale/Purpose
This package generates a report and datasets from which we will be able to:

* Verify that the enrollment, demographics & language files adhere to the relevant specifications.
* Generates descriptives (frequencies & percents) which we can compare across sites, and possibly detect differences across sites that may indicate not-yet-known problems (or just real differences) with one or more sites' data.

## Programmers
Roy Pardee (@kaiser-roy) & Paul Hitz

## Instructions

### For git users

#### If you have already cloned the repository:

1. Grab down any updates since the last time you ran by runing ```git pull origin master``` at a command line (or use your preferred git client (e.g., sourcetree, gitkraken) to perform that same operation).
2. (optional) clear any files from previous runs out of the /local_only and /share subdirectories.

#### If you have not yet cloned the repository:

There are 2 authoritative github-based clones of this repo:

|URL | For | How to request access|
|----|-----|----------------------|
|https://github.kp.org/O578092/voc_enroll | Kaiser employees | Everyone with access to KP's github enterprise instance should be able to see/clone this repo.|
|https://github.com/kpwhri/hcsrn-qa-enroll-demog | Anybody with a github.com account| E-mail [Roy](mailto:roy.e.pardee@kp.org) with your github username and he will add you to the <abbr title = "Kaiser Permanente Washington Health Research Institute">KPWHRI<abbr> 'organization', after which point you will be able to see/clone this repo.|

Run the command ```git clone ::repo-you-have-chosen:::``` someplace convenient (i.e., in some directory you can put both the QA code and the data it will write to subdirectories) or use your preferred git client (e.g., sourcetree, gitkraken) to perform that same operation.

### For <abbr title = "<cough>losers</cough>">Others<abbr>

1. download the repository as a zip file from [the HCSRN portal](https://www.hcsrnalfresco.org/#/favorite/libraries/c52a9ea9-5476-42f2-9a5d-8fe18a8106b9/(viewer:view/13dc5a14-4caa-4058-ade6-305c40238afa)?location=%2Ffavorite%2Flibraries%2Fc52a9ea9-5476-42f2-9a5d-8fe18a8106b9)
2. Unzip the contents of that file someplace convenient (i.e., in some directory you can put both the QA code and the data it will write to subdirectories).

### For Everyone

1. Make the edits indicated at the beginning of main.sas.
1. Run main.sas
2. Send the requested contents (listed below) to Roy via [KPWHRI Secure File Transfer app](http://projects.kpwashingtonresearch.org/sft/). Please use the HCSRN_VIG folder

> _A Note On The descriptives for capture of EMR data_
>
> Optionally, if you have non-EMR data in your Social History, or Vital Signs files, you may want to edit the two calls to %get_rates that stratify on incomplete_emr in order to limit the records considered to those that actually come from your EMR. These calls are on lines 1305 and 1315 of the main program (/lib/vdw_enroll_demog_qa.sas). You can see the syntax to use from the commented-out specifications for the parameter &extrawh (for 'extra WHERE condition').

**Please feel free to run this code & submit updated results at any time. It is not difficult to regenerate [the collated QA report](https://www.hcsrn.org/share/page/site/VDW/document-details?nodeRef=workspace://SpacesStore/4be65d3a-c4c0-4952-92d1-d1ba6264e1b4) and I am happy to capture any fixes you make as quickly as you make them.**

Please don't hesitate to get in touch with [Roy](mailto:roy.e.pardee@kp.org) if you have any questions about this.

# Data Required
This program requires the following VDW files:

* Enrollments
* Demographics
* Person Languages
* For the completeness variable evaluation & unenrolled utilization portion (**these are optional**--the program checks for their existence and only runs the related code if they do in fact exist)
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

* the ```[site abbreviation]_vdw_enroll_demog_qa.log``` file.
* ```[site abbreviation]_vdw_enroll_demog_qa.html``` - The output report.
* The 9 sas datasets you find in the &root/to_send directory:
    1. ```[site abbreviation]_demog_freqs.sas7bdat``` - (Low-count-censored) frequencies & percents on several variables in demographics.
    1. ```[site abbreviation]_enroll_freqs.sas7bdat``` - Ditto, for enrollment.
    1. ```[site abbreviation]_noteworthy_vars.sas7bdat``` - A list of any vars that are off-spec, or deviate from spec in some way.
    1. ```[site abbreviation]_tier_one_results.sas7bdat``` - A list of the checks done in the program, along with pass/fail assessment & other information.
    1. ```[site abbreviation]_lang_stats.sas7bdat``` - Language table statistics.
    1. ```[site abbreviation]_flagcorr.sas7bdat``` - correlations between the insurance and plan type flags.
    1. ```[site abbreviation]_enroll_duration_stats.sas7bdat``` - percentiles, mean & standard deviations for the durations of the enrollment periods at your site.
    1. ```[site abbreviation]capture_rates.sas7bdat``` - rates of records in other implemented VDW files for enrollees broken out by the appropriate incomplete_* field.
    1. ```[site abbreviation]_unenrl_rates.sas7bdat``` - rates of ute, lab, tumor, rx, social hx & vitals records that fall outside of an enrollment period.

Sites Requested
----------------

| Site | Status | Completion Date | Comments |
| ---- | ------ | --------------- | -------- |
| Baylor Scott & White |  |  |  |
| Essentia |  |  |  |
| Fallon/Meyers |  |  |  |
| Geisinger |  |  |  |
| Harvard Pilgrim | |  |  |
| HealthPartners | |  |  |
| Henry Ford |  |  |  |
| KP Colorado |  |  |  |
| KP Georgia |  |  |  |
| KP Hawaii |  |  |  |
| KP Mid-Atlantic |  |  |  |
| KP Northern California |  |  |  |
| KP Northwest |  | | |
| KP Southern California |  |  |  |
| KP Washington |  |  | Programming site. |
| Marshfield |  |  | |
| Palo Alto Medical Foundation Research Institute |  |  |
| St. Louis University / AHEAD Institute |  |  |

