/*********************************************
* Roy Pardee
* Group Health Research Institute
* (206) 287-2078
* pardee.r@ghc.org
*
* \\groups\data\CTRHS\Crn\voc\enrollment\programs\demog_milestone_three_qa.sas
*
* <<purpose>>
*********************************************/

** ====================== BEGIN EDIT SECTION ======================= ;
** Please comment-out or remove this line if Roy forgets to.  Thanks/sorry! ;
%include "\\home\pardre1\SAS\Scripts\remoteactivate.sas" ;

options linesize = 150 nocenter msglevel = i NOOVP formchar='|-++++++++++=|-/|<>*' dsoptions="note2err" ; ** nosqlremerge ;

libname _all_ clear ;

** Please replace with a reference to your local StdVars file. ;
%**include "\\groups\data\CTRHS\Crn\voc\enrollment\programs\StdVars.sas" ;

%include "\\groups\data\CTRHS\Crn\S D R C\VDW\Macros\StdVars.sas" ;

** A folder spec where HTML output can be written--please make sure you leave a trailing folder separator ;
** character (e.g., a backslash) here--ODS is very picayune about that... ;
%let out_folder = \\ctrhs-sas\SASUser\pardre1\vdw\voc_enroll ;
** ======================= END EDIT SECTION ======================== ;

data new_vars ;
  input
    @1    var_name $char25.
  ;
datalines ;
primary_language
needs_interpreter
;
run ;

data changed_flag_vars ;
  input
    @1    var_name $char25.
  ;
datalines ;
hispanic
;
run ;
data iso_639_2 ;
  input
    @1 abbrev       $char3.
    @8 description  $char200.
  ;
  infile datalines truncover ;
datalines ;
aar    Afar
abk    Abkhazian
ace    Achinese
ach    Acoli
ada    Adangme
ady    Adyghe, Adygei
afa    Afro-Asiatic languages
afh    Afrihili
afr    Afrikaans
ain    Ainu
aka    Akan
akk    Akkadian
alb    Albanian
sqi    Albanian
ale    Aleut
alg    Algonquian languages
alt    Southern Altai
amh    Amharic
ang    English, Old (ca.450-1100)
anp    Angika
apa    Apache languages
ara    Arabic
arc    Official Aramaic (700-300 BCE), Imperial Aramaic (700-300 BCE)
arg    Aragonese
arm    Armenian
hye    Armenian
arn    Mapudungun, Mapuche
arp    Arapaho
art    Artificial languages
arw    Arawak
asm    Assamese
ast    Asturian, Bable, Leonese, Asturleonese
ath    Athapascan languages
aus    Australian languages
ava    Avaric
ave    Avestan
awa    Awadhi
aym    Aymara
aze    Azerbaijani
bad    Banda languages
bai    Bamileke languages
bak    Bashkir
bal    Baluchi
bam    Bambara
ban    Balinese
baq    Basque
eus    Basque
bas    Basa
bat    Baltic languages
bej    Beja, Bedawiyet
bel    Belarusian
bem    Bemba
ben    Bengali
ber    Berber languages
bho    Bhojpuri
bih    Bihari languages
bik    Bikol
bin    Bini, Edo
bis    Bislama
bla    Siksika
bnt    Bantu (Other)
bos    Bosnian
bra    Braj
bre    Breton
btk    Batak languages
bua    Buriat
bug    Buginese
bul    Bulgarian
bur    Burmese
mya    Burmese
byn    Blin, Bilin
cad    Caddo
cai    Central American Indian languages
car    Galibi Carib
cat    Catalan, Valencian
cau    Caucasian languages
ceb    Cebuano
cel    Celtic languages
cha    Chamorro
chb    Chibcha
che    Chechen
chg    Chagatai
chi    Chinese
zho    Chinese
chk    Chuukese
chm    Mari
chn    Chinook jargon
cho    Choctaw
chp    Chipewyan, Dene Suline
chr    Cherokee
chu    Church Slavic, Old Slavonic, Church Slavonic, Old Bulgarian, Old Church Slavonic
chv    Chuvash
chy    Cheyenne
cmc    Chamic languages
cop    Coptic
cor    Cornish
cos    Corsican
cpe    Creoles and pidgins, English based
cpf    Creoles and pidgins, French-based
cpp    Creoles and pidgins, Portuguese-based
cre    Cree
crh    Crimean Tatar, Crimean Turkish
crp    Creoles and pidgins
csb    Kashubian
cus    Cushitic languages
cze    Czech
ces    Czech
dak    Dakota
dan    Danish
dar    Dargwa
day    Land Dayak languages
del    Delaware
den    Slave (Athapascan)
dgr    Dogrib
din    Dinka
div    Divehi, Dhivehi, Maldivian
doi    Dogri
dra    Dravidian languages
dsb    Lower Sorbian
dua    Duala
dum    Dutch, Middle (ca.1050-1350)
dut    Dutch, Flemish
nld    Dutch, Flemish
dyu    Dyula
dzo    Dzongkha
efi    Efik
egy    Egyptian (Ancient)
eka    Ekajuk
elx    Elamite
eng    English
enm    English, Middle (1100-1500)
epo    Esperanto
est    Estonian
ewe    Ewe
ewo    Ewondo
fan    Fang
fao    Faroese
fat    Fanti
fij    Fijian
fil    Filipino, Pilipino
fin    Finnish
fiu    Finno-Ugrian languages
fon    Fon
fre    French
fra    French
frm    French, Middle (ca.1400-1600)
fro    French, Old (842-ca.1400)
frr    Northern Frisian
frs    Eastern Frisian
fry    Western Frisian
ful    Fulah
fur    Friulian
gaa    Ga
gay    Gayo
gba    Gbaya
gem    Germanic languages
geo    Georgian
kat    Georgian
ger    German
deu    German
gez    Geez
gil    Gilbertese
gla    Gaelic, Scottish Gaelic
gle    Irish
glg    Galician
glv    Manx
gmh    German, Middle High (ca.1050-1500)
goh    German, Old High (ca.750-1050)
gon    Gondi
gor    Gorontalo
got    Gothic
grb    Grebo
grc    Greek, Ancient (to 1453)
gre    Greek, Modern (1453-)
ell    Greek, Modern (1453-)
grn    Guarani
gsw    Swiss German, Alemannic, Alsatian
guj    Gujarati
gwi    Gwich'in
hai    Haida
hat    Haitian, Haitian Creole
hau    Hausa
haw    Hawaiian
heb    Hebrew
her    Herero
hil    Hiligaynon
him    Himachali languages, Western Pahari languages
hin    Hindi
hit    Hittite
hmn    Hmong, Mong
hmo    Hiri Motu
hrv    Croatian
hsb    Upper Sorbian
hun    Hungarian
hup    Hupa
iba    Iban
ibo    Igbo
ice    Icelandic
isl    Icelandic
ido    Ido
iii    Sichuan Yi, Nuosu
ijo    Ijo languages
iku    Inuktitut
ile    Interlingue, Occidental
ilo    Iloko
ina    Interlingua (International Auxiliary Language Association)
inc    Indic languages
ind    Indonesian
ine    Indo-European languages
inh    Ingush
ipk    Inupiaq
ira    Iranian languages
iro    Iroquoian languages
ita    Italian
jav    Javanese
jbo    Lojban
jpn    Japanese
jpr    Judeo-Persian
jrb    Judeo-Arabic
kaa    Kara-Kalpak
kab    Kabyle
kac    Kachin, Jingpho
kal    Kalaallisut, Greenlandic
kam    Kamba
kan    Kannada
kar    Karen languages
kas    Kashmiri
kau    Kanuri
kaw    Kawi
kaz    Kazakh
kbd    Kabardian
kha    Khasi
khi    Khoisan languages
khm    Central Khmer
kho    Khotanese, Sakan
kik    Kikuyu, Gikuyu
kin    Kinyarwanda
kir    Kirghiz, Kyrgyz
kmb    Kimbundu
kok    Konkani
kom    Komi
kon    Kongo
kor    Korean
kos    Kosraean
kpe    Kpelle
krc    Karachay-Balkar
krl    Karelian
kro    Kru languages
kru    Kurukh
kua    Kuanyama, Kwanyama
kum    Kumyk
kur    Kurdish
kut    Kutenai
lad    Ladino
lah    Lahnda
lam    Lamba
lao    Lao
lat    Latin
lav    Latvian
lez    Lezghian
lim    Limburgan, Limburger, Limburgish
lin    Lingala
lit    Lithuanian
lol    Mongo
loz    Lozi
ltz    Luxembourgish, Letzeburgesch
lua    Luba-Lulua
lub    Luba-Katanga
lug    Ganda
lui    Luiseno
lun    Lunda
luo    Luo (Kenya and Tanzania)
lus    Lushai
mac    Macedonian
mkd    Macedonian
mad    Madurese
mag    Magahi
mah    Marshallese
mai    Maithili
mak    Makasar
mal    Malayalam
man    Mandingo
mao    Maori
mri    Maori
map    Austronesian languages
mar    Marathi
mas    Masai
may    Malay
msa    Malay
mdf    Moksha
mdr    Mandar
men    Mende
mga    Irish, Middle (900-1200)
mic    Mi'kmaq, Micmac
min    Minangkabau
mis    Uncoded languages
mkh    Mon-Khmer languages
mlg    Malagasy
mlt    Maltese
mnc    Manchu
mni    Manipuri
mno    Manobo languages
moh    Mohawk
mon    Mongolian
mos    Mossi
mul    Multiple languages
mun    Munda languages
mus    Creek
mwl    Mirandese
mwr    Marwari
myn    Mayan languages
myv    Erzya
nah    Nahuatl languages
nai    North American Indian languages
nap    Neapolitan
nau    Nauru
nav    Navajo, Navaho
nbl    Ndebele, South, South Ndebele
nde    Ndebele, North, North Ndebele
ndo    Ndonga
nds    Low German, Low Saxon, German, Low, Saxon, Low
nep    Nepali
new    Nepal Bhasa, Newari
nia    Nias
nic    Niger-Kordofanian languages
niu    Niuean
nno    Norwegian Nynorsk, Nynorsk, Norwegian
nob    Bokm�l, Norwegian, Norwegian Bokm�l
nog    Nogai
non    Norse, Old
nor    Norwegian
nqo    N'Ko
nso    Pedi, Sepedi, Northern Sotho
nub    Nubian languages
nwc    Classical Newari, Old Newari, Classical Nepal Bhasa
nya    Chichewa, Chewa, Nyanja
nym    Nyamwezi
nyn    Nyankole
nyo    Nyoro
nzi    Nzima
oci    Occitan (post 1500), Proven�al
oji    Ojibwa
ori    Oriya
orm    Oromo
osa    Osage
oss    Ossetian, Ossetic
ota    Turkish, Ottoman (1500-1928)
oto    Otomian languages
paa    Papuan languages
pag    Pangasinan
pal    Pahlavi
pam    Pampanga, Kapampangan
pan    Panjabi, Punjabi
pap    Papiamento
pau    Palauan
peo    Persian, Old (ca.600-400 B.C.)
per    Persian
fas    Persian
phi    Philippine languages
phn    Phoenician
pli    Pali
pol    Polish
pon    Pohnpeian
por    Portuguese
pra    Prakrit languages
pro    Proven�al, Old (to 1500)
pus    Pushto, Pashto
que    Quechua
raj    Rajasthani
rap    Rapanui
rar    Rarotongan, Cook Islands Maori
roa    Romance languages
roh    Romansh
rom    Romany
rum    Romanian, Moldavian, Moldovan
ron    Romanian, Moldavian, Moldovan
run    Rundi
rup    Aromanian, Arumanian, Macedo-Romanian
rus    Russian
sad    Sandawe
sag    Sango
sah    Yakut
sai    South American Indian (Other)
sal    Salishan languages
sam    Samaritan Aramaic
san    Sanskrit
sas    Sasak
sat    Santali
scn    Sicilian
sco    Scots
sel    Selkup
sem    Semitic languages
sga    Irish, Old (to 900)
sgn    Sign Languages
shn    Shan
sid    Sidamo
sin    Sinhala, Sinhalese
sio    Siouan languages
sit    Sino-Tibetan languages
sla    Slavic languages
slo    Slovak
slk    Slovak
slv    Slovenian
sma    Southern Sami
sme    Northern Sami
smi    Sami languages
smj    Lule Sami
smn    Inari Sami
smo    Samoan
sms    Skolt Sami
sna    Shona
snd    Sindhi
snk    Soninke
sog    Sogdian
som    Somali
son    Songhai languages
sot    Sotho, Southern
spa    Spanish, Castilian
srd    Sardinian
srn    Sranan Tongo
srp    Serbian
srr    Serer
ssa    Nilo-Saharan languages
ssw    Swati
suk    Sukuma
sun    Sundanese
sus    Susu
sux    Sumerian
swa    Swahili
swe    Swedish
syc    Classical Syriac
syr    Syriac
tah    Tahitian
tai    Tai languages
tam    Tamil
tat    Tatar
tel    Telugu
tem    Timne
ter    Tereno
tet    Tetum
tgk    Tajik
tgl    Tagalog
tha    Thai
tib    Tibetan
bod    Tibetan
tig    Tigre
tir    Tigrinya
tiv    Tiv
tkl    Tokelau
tlh    Klingon, tlhIngan-Hol
tli    Tlingit
tmh    Tamashek
tog    Tonga (Nyasa)
ton    Tonga (Tonga Islands)
tpi    Tok Pisin
tsi    Tsimshian
tsn    Tswana
tso    Tsonga
tuk    Turkmen
tum    Tumbuka
tup    Tupi languages
tur    Turkish
tut    Altaic languages
tvl    Tuvalu
twi    Twi
tyv    Tuvinian
udm    Udmurt
uga    Ugaritic
uig    Uighur, Uyghur
ukr    Ukrainian
umb    Umbundu
und    Undetermined
urd    Urdu
uzb    Uzbek
vai    Vai
ven    Venda
vie    Vietnamese
vol    Volap�k
vot    Votic
wak    Wakashan languages
wal    Walamo
war    Waray
was    Washo
wel    Welsh
cym    Welsh
wen    Sorbian languages
wln    Walloon
wol    Wolof
xal    Kalmyk, Oirat
xho    Xhosa
yao    Yao
yap    Yapese
yid    Yiddish
yor    Yoruba
ypk    Yupik languages
zap    Zapotec
zbl    Blissymbols, Blissymbolics, Bliss
zen    Zenaga
zha    Zhuang, Chuang
znd    Zande languages
zul    Zulu
zun    Zuni
zxx    No linguistic content, Not applicable
zza    Zaza, Dimili, Dimli, Kirdki, Kirmanjki, Zazaki
;
run ;
** ' Terminating the trailing apostrophe to fix syntax highlighting. ;
proc format ;
  value $flg
    'Y' = 'Yes'
    'N' = 'No'
    'U' = 'Unknown'
    other = 'FAIL: Out of spec value!'
  ;
  value $race
    "HP" = "Native Hawaiian or Other Pacific Islander"
    "IN" = "American Indian/Alaska Native"
    "AS" = "Asian"
    "BA" = "Black or African American"
    "WH" = "White"
    "MU" = "More than one race, particular races unknown or not reported"
    "UN" = "Unknown or Not Reported"
    other = 'FAIL: Out of spec value!'
  ;
quit ;

%macro find_new_vars ;
  %global num_new_vars v1 v2 v3 v4 v5 new_vars ;
  title2 "Checking for existence of new vars." ;
  proc sql ;
    ** describe table dictionary.columns ;
    create table existing_vars as
    select lowcase(name) as var_name, type, label
    from dictionary.columns
    where lowcase(compress(libname || '.' || memname)) = "%lowcase(&_vdw_demographic_m3)" AND
          lowcase(name) in (select var_name from new_vars)
    ;

    select "PASS: Variable exists" as msg, var_name, type, label
    from existing_vars
    where var_name in (select var_name from new_vars)
    ;

    reset noprint ;

    select var_name
    into :v1 - :v2
    from existing_vars
    where var_name in (select var_name from new_vars)
    ;

    select var_name
    into :new_vars separated by ', '
    from existing_vars
    where var_name in (select var_name from new_vars)
    ;

    %let num_new_vars = &sqlobs ;

    reset print ;

    select "FAIL: Variable does not exist!" as msg, var_name
    from new_vars
    where var_name not in (select var_name from existing_vars)
    ;

  quit ;
  %if &sqlobs > 0 %then %do i = 1 %to 10 ;
    %put FAIL: ONE OR MORE MILESTONE 1 VARIABLES MISSING FROM &_vdw_demographic_m3!!!  See output file for details. ;
  %end ;
%mend find_new_vars ;

%macro freqs(dset = &_vdw_demographic_m3, n = 20) ;
  title2 "Frequencies on the new and changed vars." ;
  proc format ;
    value msk
      0 - 4 = '< 5'
      other = [comma15.2]
    ;
  quit ;

  ** Adding a shill var just so I can make the freqs xtabs, so SAS will allow me to format the counts w/a masking format. ;
  data gnu ;
    set &dset ;
    site = "&_SiteAbbr" ;
  run ;

  proc freq data = gnu ;
    tables (race: hispanic) * site / missing format = msk. ;
    format race: $race. hispanic $flg. ;
  run ;

  %if %index(%quote(&new_vars), primary_language) > 0 %then %do ;
    proc freq data = gnu ;
      tables primary_language * site / out = lang_counts format = msk. ;
    run ;

    proc sql ;
      create table vdw_lang_spec as select * from iso_639_2 ;
      insert into iso_639_2(abbrev, description) values ('unk', 'Unknown (VDW-specific value)') ;
      alter table vdw_lang_spec add primary key (abbrev) ;
      select 'FAIL: Out-of-spec value!!!' as message, primary_language as value, count format = msk.
      from lang_counts as c LEFT JOIN
            iso_639_2 as s
      on    c.primary_language = s.abbrev
      where s.abbrev IS NULL
      ;
    quit ;

  %end ;
  %if %index(%quote(&new_vars), needs_interpreter) > 0 %then %do ;
    proc freq data = gnu ;
      tables needs_interpreter * site / missing format = msk. ;
      format needs_interpreter $flg. ;
    run ;
  %end ;
%mend freqs ;


%macro demog_m3_qa ;
  %if %symexist(_vdw_demographic_m3) %then %do ;
    %put PASS: Macro variable _vdw_demographic_m3 found! ;
    %find_new_vars ;
    %freqs ;
  %end ;
  %else %do ;
    proc sql ;
      select "FAIL: DEMOG MILESTONE THREE MACRO VAR (_vdw_demographic_m3) NOT DEFINED!!!" as fail_message
      from new_vars
      ;
    quit ;
    %do i = 1 %to 10 ;
      %put FAIL: DEMOG MILESTONE THREE MACRO VAR (_vdw_demographic_m3) NOT DEFINED!!! ;
    %end ;
  %end ;
%mend demog_m3_qa ;

options mprint ;

ods html path = "&out_folder" (URL=NONE)
         body = "demog_milestone_three_qa_&_SiteAbbr..html"
         (title = "Demog M3 &_SiteAbbr output")
          ;
  title1 "Demographics Milestone Three QA output for &_SiteName" ;

  %demog_m3_qa ;

run ;

ods html close ;
