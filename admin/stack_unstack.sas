/*********************************************
* Roy Pardee
* KP Washington Health Research Institute
* (206) 287-2078
* roy.e.pardee@kp.org
*
* C:\Users/o578092/Documents/vdw/voc_enroll/admin/frolics/stack_unstack_sketch.sas
*
* Smooths over the seam caused by the changes in commit 39c09fc, in which I took what
* used to be several different dsets & stacked them at the site. Some of this code
* will be integrated into collate_qa.sas, and some are one-time fixes that dont
* need to leave this program.
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



/*
  The qa now stacks what used to be several output datasets, to make it easier on users to verify there's no PHI.
  The collate routine will still expect the individual datasets.

  So we've got to either make the old dsets look new (and change the collate reporting to use the new) or the new dsets look old.

  Probably easier to explode the stacked dsets into the old structures.

  OLD:
    captures
      siteabbr_emr_v_rates
      siteabbr_emr_s_rates
      siteabbr_rx_rates
      siteabbr_lab_rates
      siteabbr_tumor_rates
      siteabbr_ute_out_rates_by_enctype
      siteabbr_ute_in_rates_by_enctype
    unenrolled
      kpnw_vsn_unenrolled
      kpnw_shx_unenrolled
      kpnw_rx_unenrolled
      kpnw_lab_unenrolled
      kpnw_tum_unenrolled
      kpnw_enc_unenrolled
  NEW:
    capture
      siteabbr_capture_rates
        source_dset
          to_stay.lab_rates
          to_stay.tumor_rates
          to_stay.rx_rates
          to_stay.emr_s_rates
          to_stay.emr_v_rates
          to_stay.ute_out_rates_by_enctype
          to_stay.ute_in_rates_by_enctype
    unenrolled
      siteabbr_unenrl_rates
        dset
          ENC
          LAB
          RX
          SHX
          TUM
          VSN

  SO:
    stack the new rates dsets, then
    unstack into site-and-subject-area-specific dsets, then
    stack again into just subject-area dsets

*/

* practicing on KPNWs output ;
libname _all_ clear ;
libname s "\\groups.ghc.org\data\CTRHS\Crn\voc\enrollment\programs\submitted_data\raw\20200813_KPNW_vdw_enroll_demog_qa" ;
libname realraw "\\groups.ghc.org\data\CTRHS\Crn\voc\enrollment\programs\submitted_data\raw" ;

%macro fix_demog_freqs(dset) ;
  data gnu ;
    set &dset (rename = gender = sex_admin) ;
  run ;

  data &dset ;
    set gnu ;
  run ;

%mend fix_demog_freqs ;


* %stack_datasets(inlib = realraw, nom = demog_freqs, outlib = s) ;


/*
%fix_demog_freqs(realraw.BSWH_DEMOG_FREQS) ;
*/
%fix_demog_freqs(realraw.EIRH_DEMOG_FREQS) ;
%fix_demog_freqs(realraw.FA_DEMOG_FREQS) ;
%fix_demog_freqs(realraw.GHS_DEMOG_FREQS) ;
%fix_demog_freqs(realraw.HFHS_DEMOG_FREQS) ;
%fix_demog_freqs(realraw.HPHC_DEMOG_FREQS) ;
%fix_demog_freqs(realraw.HPI_DEMOG_FREQS) ;
%fix_demog_freqs(realraw.KPCO_DEMOG_FREQS) ;
%fix_demog_freqs(realraw.KPGA_DEMOG_FREQS) ;
%fix_demog_freqs(realraw.KPH_DEMOG_FREQS) ;
%fix_demog_freqs(realraw.KPMA_DEMOG_FREQS) ;
%fix_demog_freqs(realraw.KPSC_DEMOG_FREQS) ;
%fix_demog_freqs(realraw.PAMF_DEMOG_FREQS) ;

endsas ;

%macro reshuffle_unenrl_rates(inset = unenrl_rates, lib = s) ;
  %stack_datasets(inlib = &lib, nom = &inset, outlib = &lib) ;
  proc sql ;
    select distinct upcase(site) as site
        , dset
        , cats("&lib..", lowcase(site), '_', lowcase(dset), '_unenrolled') as destination_dset
    into :s1-:s999, :ds1-:ds999, :dd1-:dd999
    from &lib..&inset
    order by site, dset
    ;
    %let num_rows = &SQLOBS ;
  quit ;
  data
    %do i = 1 %to &num_rows ;
      &&dd&i
    %end ;
  ;
    set &lib..&inset ;
    %do i = 1 %to &num_rows ;
      if upcase(site) = "&&s&i" and dset = "&&ds&i" then output &&dd&i ;
    %end ;
    drop site dset ;
  run ;

%mend reshuffle_unenrl_rates ;

* %reshuffle_unenrl_rates ;

%macro reshuffle_capture_rates(inset = capture_rates, lib = s) ;
  %stack_datasets(inlib = &lib, nom = &inset, outlib = &lib) ;

  proc sql noprint ;
    select distinct upcase(site) as site
        , source_dset
        , cats("&lib..", lowcase(site), '_', substr(source_dset, 9)) as destination_dset
        , capture_var
    into :s1-:s999, :sd1-:sd999, :dd1-:dd999, :cv1-:cv999
    from s.capture_rates
    order by site, source_dset
    ;
    %let num_rows = &SQLOBS ;
  quit ;
  data
    %do i = 1 %to &num_rows ;
      &&dd&i (rename = (capture = &&cv&i))
    %end ;
  ;
    set &lib..&inset ;
    %do i = 1 %to &num_rows ;
      if upcase(site) = "&&s&i" and source_dset = "&&sd&i" then output &&dd&i ;
    %end ;
    drop site source_dset n_unenrolled n_total capture_var ;
  run ;
%mend reshuffle_capture_rates ;

options mprint ;
* %reshuffle_capture_rates ;

%macro fix_rates(inlib = raw, nom = ) ;
  proc sql ;
    * describe table dictionary.tables ;
    select lowcase(cats(libname, '.', memname)) as dset
    into :ds1-:ds999
    from dictionary.tables
    where libname = "%upcase(&inlib)" and memtype = 'DATA' and lowcase(memname) like cats('%', "&nom")
    order by memname
    ;
    %let num_rows = &SQLOBS ;
  quit ;

  %do i = 1 %to &num_rows ;
    data &&ds&i ;
      set &&ds&i (drop = extra) ;
      extra = 'XX' ;
    run ;
  %end ;
%mend fix_rates ;


/*
%fix_rates(inlib = realraw, nom = tumor_rates) ;
%fix_rates(inlib = realraw, nom = rx_rates) ;
%fix_rates(inlib = realraw, nom = emr_s_rates) ;
%fix_rates(inlib = realraw, nom = emr_v_rates) ;
%fix_rates(inlib = realraw, nom = lab_rates) ;
*/

