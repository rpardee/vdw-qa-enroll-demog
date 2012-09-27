/*********************************************
* Roy Pardee
* Group Health Research Institute
* (206) 287-2078
* pardee.r@ghc.org
*
* /C/Documents and Settings/pardre1/My Documents/vdw/voc_enroll/qa_formats.sas
*
* Creates formats needed for the E/D QA program.
*********************************************/

data expected_vars ;
  length name $ 32 ;
  input
    @1   dset      $
    @9   name  $char20.
    @33   type
    @37   recommended_length
  ;
  infile datalines missover ;
datalines ;
demog   gender                  2
demog   birth_date              1   4
demog   hispanic                2
demog   mrn                     2
demog   needs_interpreter       2
demog   primary_language        2
demog   race1                   2
demog   race2                   2
demog   race3                   2
demog   race4                   2
demog   race5                   2
enroll  mrn                     2
enroll  enr_end                 1   4
enroll  enr_start               1   4
enroll  enrollment_basis        2
enroll  drugcov                 2
enroll  ins_commercial          2
enroll  ins_highdeductible      2
enroll  ins_medicaid            2
enroll  ins_medicare            2
enroll  ins_medicare_a          2
enroll  ins_medicare_b          2
enroll  ins_medicare_c          2
enroll  ins_medicare_d          2
enroll  ins_other               2
enroll  ins_privatepay          2
enroll  ins_selffunded          2
enroll  ins_statesubsidized     2
enroll  outside_utilization     2
enroll  pcc                     2
enroll  pcp                     2
enroll  plan_hmo                2
enroll  plan_indemnity          2
enroll  plan_pos                2
enroll  plan_ppo                2
;
run ;

data iso_639_2 ;
  input
    @1 abbrev       $char3.
    @8 description  $char80.
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
nob    Bokmål, Norwegian, Norwegian Bokmål
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
oci    Occitan (post 1500), Provençal
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
pro    Provençal, Old (to 1500)
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
vol    Volapük
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

proc format cntlout = fmt ;
  value vtype
    1 = "numeric"
    2 = "char"
  ;
  value $flg
    "Y"   = "yes"
    "N"   = "no"
    "U"   = "unknown"
    other = "bad"
  ;
  value $eb
    "I"   = "insurance"
    "G"   = "geography"
    "B"   = "both ins + geog"
    "P"   = "patient only"
    other = "bad"
  ;
  value $race
    "HP" = "Native Hawaiian or Other Pacific Islander"
    "IN" = "American Indian/Alaska Native"
    "AS" = "Asian"
    "BA" = "Black or African American"
    "WH" = "White"
    "MU" = "More than one race, particular races unknown or not reported"
    "UN" = "Unknown or Not Reported"
    other = 'bad'
  ;
  value $gend
    'M' = 'Male'
    'F' = 'Female'
    'U' = 'Unknown'
    'O' = 'Other'
    other = 'bad'
  ;
quit ;

proc sql ;

  create table langfmt like fmt ;

  insert into langfmt (fmtname, start, end, label)
  select '$LANG', abbrev, abbrev, description
  from iso_639_2
  ;

  insert into langfmt (start, end, label, fmtname)
  values('unk', 'unk', "Unknown", '$LANG')
  ;

  insert into langfmt (start, end, label, fmtname, hlo)
  values('**OTHER**', '**OTHER**', "bad", '$LANG', 'O')
  ;

quit ;

proc format cntlin = langfmt ;
run ;

proc sql ;
  drop table fmt ;
  drop table iso_639_2 ;
  drop table langfmt ;
quit ;