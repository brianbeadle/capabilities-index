/* ************************************************************************* * 
* 	CREATORS: Johnson Kansiime, Antje Jantsch, Brian Beadle
*	DATA PREPERATION FILE 
* 	DATE FIRST CREATED: 2024-10-24
* 	DATE LAST MODIFIED: 2026-03-29
* ************************************************************************* */ 


/* ************************************************************************* * 
*	Define global macros
** ************************************************************************* */ 

clear all
set more off 
window manage maintitle "Lettuce prepare data"

********************************************************************************
* Load master dataset
********************************************************************************
use "${path}master.v05.dta", clear

	
/********************************************************************************	
* Regional identifyer

	country         float   %6.0f      country    Country
	macro_region    float   %18.0g     macro_region
												  NUTS II: macro-region
	county          float   %13.0g     county     NUTS III: county
	village         float   %25.0g     village    
****************************************************************************** */ 

tab country,m
tab macro_region,m
tab county,m
tab village,m
	
	
********************************************************************************
* control variables (covariates, levels, etc.)
********************************************************************************

rename int_id id

*** gender
	tab female, m

*** age
	tab age_cat      // 3 categories
	tab age_group    // 8 categories
	tab age  ,m        // continuous

*** kids and household
	tab kids
	tab kids_LT6,m // only use number of kids below 6
		replace kids_LT6 = 0 if kids_LT6 == . 
		//tab kids_OT6
		//gen kids_total = kids_LT6 + kids_OT6 // total kids

*** hh-size	
	tab hhsize, m

*** Employment status
	
		* mat_leave - maternal leave
			recode mat_leave (2=0)
				replace mat_leave = 0 if mat_leave==1 & kids_OT6==0 & kids_LT6==0  & v04_job__6==1 // 7 respondents on maternal leave without having kids and being retired
				replace mat_leave = 0 if mat_leave==1 & kids_OT6==0 & kids_LT6==0 // 3 respondents on maternal leave without having kids
				replace mat_leave = 0 if  mat_leave ==1 & v04_job__6==1
				replace mat_leave = 0 if  mat_leave == .

		* unempl - unumployed
			gen unempl = v04_job__7 
				replace unempl = 0 if student ==1 // I moved those 47 from this category who reported they were students
				
		* student - Student
			recode student (2=0)
			
		* employee - Employee (working contract with salary)
			gen employee = v04_job__1
				replace employee = 1 if ///
					v04_job_oth == "Nënkryetar në Organizatë Joqeveritare." // I assigned the only person who reported to be the Vice President in a Non-Governmental Organization
				replace employee = 1 if v04_job_oth == "Është me leje lindje." // I assigned the only person who reported to be on aternal leave
				count if employee==1 & v04_job__5==1 // 2 respondents report being employee and occ. worker
			
			
		* self_empl - Self-employed
			gen self_empl = v04_job__2+v04_job__3
				recode self_empl (2=1)
				
		* contr_work - Contributing family worker
			gen contr_work = v04_job__4
				count if unempl==1 & contr_work==1 // 16 respondents report being unemployed and contrib.fam.worker

		* occ_work - Occasional worker on demand
			gen occ_work = v04_job__5 
				count if unempl==1 & occ_work==1 // 2 respondents report being unemployed and occ. worker
				
		* retired - Retired
			gen retired = v04_job__6
				replace retired = 1 if v04_job_oth == "Invaliditet" // I assigned the only person who reported to be disabled to this category
				replace retired = 1 if v04_job_oth == "Ndihme ekonomike" // I assigned the only person who reported to receive Invalidity pension to this category
				count if retired==1 & employee==1 // 9 respondents report being retired and employee

		* Assign those with the response "prefer not to say" to other categories if possible
				tab v04_job__99999 student 
					replace v04_job__99999 = 0 if student == 1 
			
	* check the missings		
		count if employee == 0 & self_empl == 0  &  contr_work == 0 &  occ_work == 0 &  retired == 0 &  unempl == 0 & student==0 & mat_leave==0	 // 10 respondents prefer not to say their employment status and are not in any category
  
*** BigFive
		 * big5_extra - Extraversion: 1R, 6
			tab v01_bigfive ,m nol
				gen v01_bigfive_r = v01_bigfive
				recode v01_bigfive_r (1=5) (2=4) (4=2) (5=1) (99=.) (.a=.)
			tab v06_bigfive ,m nol
				recode v06_bigfive (99=.) (.a=.)
			gen big5_extra = (v01_bigfive_r + v06_bigfive)/2
		
		* big5_agree - Agreeableness: 2, 7R
			tab v02_bigfive ,m nol
				recode v02_bigfive (99=.) (.a=.)
			tab v07_bigfive ,m nol
				gen v07_bigfive_r = v07_bigfive
				recode v07_bigfive_r (1=5) (2=4) (4=2) (5=1) (99=.) (.a=.)
			gen big5_agree = (v02_bigfive + v07_bigfive_r)/2
		
		* big5_conc - Conscientiousness: 3R, 8	
			 tab v03_bigfive ,m nol
				gen v03_bigfive_r = v03_bigfive
				recode v03_bigfive_r (1=5) (2=4) (4=2) (5=1) (99=.) (.a=.)
			 tab v08_bigfive ,m nol
				recode v08_bigfive (99=.) (.a=.)
			gen big5_conc = (v03_bigfive_r + v08_bigfive)/2
		
		* big5_neuro - Neuroticism: 4R, 9
			tab v04_bigfive ,m nol
				gen v04_bigfive_r = v04_bigfive
				recode v04_bigfive_r (1=5) (2=4) (4=2) (5=1) (99=.) (.a=.)
			tab v09_bigfive ,m nol
				recode v09_bigfive (99=.) (.a=.)
			gen big5_neuro = (v04_bigfive_r + v09_bigfive)/2
		
		* big5_open - Openness to Experience: 5R, 10
			tab v05_bigfive ,m nol
				gen v05_bigfive_r = v05_bigfive
				recode v05_bigfive_r (1=5) (2=4) (4=2) (5=1) (99=.) (.a=.)
			tab v10_bigfive ,m nol
				recode v10_bigfive (99=.) (.a=.)
			gen big5_open = (v05_bigfive_r + v10_bigfive)/2

			
tab1 big5_extra big5_agree big5_conc big5_neuro big5_open
	

/* ******************************************************************************
* SOCIAL DOMAIN
	v04_pa          byte    %6.0f      v04_pa     relationship with family //11 % missings
	v05_pa          byte    %6.0f      v05_pa     Importance of friendships//5 % missings
	v06_pa          byte    %6.0f      v06_pa     belonging and inclusion in to my community
	v07_pa          byte    %6.0f      v07_pa     help within community
	
	v04_social      byte    %6.0f                 no of close friends

	v02_social      long    %6.0f      v02_social
												  no community events
****************************************************************************** */ 

* y1 - relationship with familiy  (TOO MANY MISSINGS)
	tab v04_pa, nol m
	gen y1 = v04_pa
		replace y1 = . if v04_pa == 99
	tab y1, m

* y2 - relationship with friendships  (TOO MANY MISSINGS)
	tab v05_pa, nol m
	gen y2 = v05_pa
		replace y2 = . if v05_pa == 99 | ///
								   v05_pa == .a
	tab y2, m							   

* y3 -  belonging and inclusion in to my community
	tab v06_pa, nol m
	gen y3 = v06_pa
		replace y3 = . if v06_pa == 99 
		
	tab y3, m							   

* y4 -  help within community
	tab v07_pa, nol m
	gen y4 = v07_pa
		replace y4 = . if v07_pa == 99 
		
	tab y4, m							   							
	
	
* y5 - number of close friends (recoding continuous var)
	tab v04_social, m
	gen y5 = .
		replace y5 = 1 if v04_social == 0
		replace y5 = 2 if v04_social > 0 & v04_social < 4
		replace y5 = 3 if v04_social >= 4 & v04_social < 6
		replace y5 = 4 if v04_social >= 6 & v04_social <= 10
		replace y5 = 5 if v04_social > 10
		replace y5 = . if v04_social ==.a

	tab y5, m

* y6 - number of community events (recoding continuous var)
	tab v02_social, nol m
	gen y6 = v02_social
		replace y6 = 1 if v02_social == 0
		replace y6 = 2 if v02_social > 0 & v02_social < 3
		replace y6 = 3 if v02_social >= 3 & v02_social < 5
		replace y6 = 4 if v02_social >= 5 & v02_social <= 12
		replace y6 = 5 if v02_social > 12
		replace y6 = . if v02_social == 99 
		replace y6 = . if v02_social == 88888 
		replace y6 = . if v02_social == .a
		
	tab y6, m


/* ******************************************************************************
* * I - CIVIC ENGAGEMENT

	
	v011_civic      long    %6.0f      v011_civic
												  likelihood to vote
	v012_civic      long    %6.0f      v012_civic
												  likelihood to vote if allowed

	v03_civic       byte    %6.0f      v03_civic
												  freedom of speech
	v05_civic       byte    %6.0f      v05_civic
												  independent press
	v07_civic       byte    %6.0f      v07_civic
												  corruption
****************************************************************************** */ 

* y7 - likelihood to vote (if allowed)

	tab v011_civic, nolabel   // 3 as '99' and 3 "prefer not to say"
	gen y7 = v011_civic
		replace y7 = 1 if v012_civic == 1
		replace y7 = 2 if v012_civic == 2
		replace y7 = 3 if v012_civic == 3
		replace y7 = 4 if v012_civic == 4
		replace y7 = 5 if v012_civic == 5
		replace y7 = . if v012_civic == 99999
		replace y7 = . if v011_civic == 99 | v011_civic == 99999

	tab y7, m

* y8 - freedom of speech
	tab v03_civic, m nol
	gen y8 = v03_civic
		replace y8 = . if v03_civic == 99 | v03_civic == 99999

* y9 - independent press
	tab v05_civic, m nol             // 46 obs of 99
	gen y9 = v05_civic
		replace y9 = . if v05_civic == 99 | v05_civic == 99999

* y10 - corruption (reversing order)
	tab v07_civic, m nol             // 26 ...
	gen y10 = v07_civic
		recode y10 (1=5) (2=4) (4=2) (5=1) // reversing order
			
			label define y10 1 "Strongly agree" 2 "Agree" 3 "Neither, nor" ///
				4 "Disagree" 5 "Strongly disagree"
			label values y10 y10


/* ******************************************************************************
*  J - HEALTH
	
	v05_health      long    %6.0f      v05_health
												  overall health
	v06_health      long    %6.0f      v06_health
                                              quality of healthcare services
****************************************************************************** */ 
	
* y11 - overall health	(reversing order)
	tab v05_health, m  // 7
	gen y11 = v05_health
		replace y11 = . if v05_health == 7 | v05_health == 99999
		recode y11 (1=5) (2=4) (4=2) (5=1) // reversing order

		tab y11, m
		
* y12 - quality of healthcare services
	tab v06_health, nol m  // 53
	gen y12 = v06_health
		replace y12 = . if v06_health == 97 | v06_health == 99 | ///
						   v06_health == 88888 | v06_health == 99999
			
		tab y12,m	
			

/* ******************************************************************************			
  * K - HOUSING CHARACTERISTICS (index for amenities)
	
	dwell_sizesuff  byte    %6.0f      dwell_sizesuff
												  Sufficiency of dwelling size
	dwell_cond      byte    %6.0f      dwell_cond
												  Current condition of the living unit
	
	dwell_amen__101 byte    %6.0f                 access to ameneties in house:Water supply for domestic use
	dwell_amen__102 byte    %6.0f                 access to ameneties in house:Electricity
	dwell_amen__103 byte    %6.0f                 access to ameneties in house:Heating
	dwell_amen__104 byte    %6.0f                 access to ameneties in house:Sanitation facilities (e.g. garbage disposal and se
	dwell_amen__105 byte    %6.0f                 access to ameneties in house:Access to internet/Wi-Fi
	dwell_ame~66666 byte    %6.0f                 access to ameneties in house:NONE
****************************************************************************** */ 	

* y13 - Sufficiency of dwelling size
	tab dwell_sizesuff, m //2
	gen y13 =  dwell_sizesuff
		replace y13 =. if dwell_sizesuff == 99
		
* y14 - Current condition of the living unit
	tab dwell_cond, m // 1
	gen y14 = dwell_cond
		replace y14 = . if dwell_cond == 99

* y15 - number of amenities in the house
	gen y15h = dwell_amen__101 + dwell_amen__102 + dwell_amen__103 ///
								+ dwell_amen__104 + dwell_amen__105
		replace y15h = . if 	dwell_amen__99999 == 1
		replace y15h = 0 if 	dwell_amen__66666 == 1
		tab y15h, m
	gen y15 = . 	
		replace y15 = 1 if y15h == 0 | y15h == 1
		replace y15 = 2 if y15h ==2 
		replace y15 = 3 if y15h ==3
		replace y15 = 4 if y15h ==4
		replace y15 = 5 if y15h ==5
	tab y15,m
	
* Amenities index
	mdesc dwell_amen__101 dwell_amen__102 dwell_amen__103 dwell_amen__104 dwell_amen__105 dwell_ame~66666
	tab dwell_amen__66666 // 0.25% none will not help distinguish households, hence do not use var in final assets index  
	global ameneties dwell_amen__101 dwell_amen__102 dwell_amen__103 dwell_amen__104 dwell_amen__105
* Polychoric 
	polychoric $ameneties
* Display number of obs used 
	display r(sum_w)
* Store number of obs in global macro N 
	global N = r(sum_w)
* Store polychoric correlation matrix as r so that we can use it later below 
	matrix r = r(R)
* CATPCA using the correlation matrix r
	pcamat r, n($N) mineigen(1)
* check model diagnostics 
	factortest $ameneties
* Rotate components
	rotate, varimax
* check eigen values in matrix list 
	matrix list e(Ev)
* Proportion of variance explained by each pc 
* Gen eigenvalue var for the first pc 
	gen ev = .
	quietly forval i = 1/1 {
	   replace ev = el(e(Ev), 1, `i') in `i'
	}
* calculate the total (r(sum)) of the eigen values
* NB: Magnitude of evs also means magnitude of variance explained by a pc 
	summarize ev, meanonly
	display r(sum)
* gen proportion explained 
	quietly gen prop = ev / r(sum)
* check proportions and evs 
	list ev prop in 1/1
* Save pcs with mineigen 1 
	predict pc1  
* gen final pc by multiplying each pc with the variance it explains 
	gen pc_final = (pc1 * prop[1])
*check nature of pc_final
	summ pc_final
* Gen final ammenities index y15a 
	xtile y15a = pc_final, n(10) altdef // use nq = 10 due to ties at cutoff boundaries. Any solution for this?  
	label define y15a 1 "Low" 5 "High"
	label values y15a y15a
	label var y15a "Ammenities index"
* Check nature of final ammenities index 
	tab y15a, m
	tabstat pc_final, stat(n mean sd min max p50) by(y15a)
* Drop unneccesary vars 
	drop pc_final ev prop pc1
	

/* ******************************************************************************	
* L - RESIDENTIAL ENVIRONMENT (index for infrastructure) 

	dwell_worr      byte    %6.0f      dwell_worr
												  worries re safety of home and property
	res_env_roads   byte    %6.0f     quality local roads
												  
	min_city        int     %6.0f                 travel time to the nearest city center
	vill_safe       byte    %6.0f     				safety
	
	resenv_serv__~1 byte    %6.0f                 services available in the village:Supermarket
	resenv_serv__~2 byte    %6.0f                 services available in the village:Doctor
	resenv_serv__~3 byte    %6.0f                 services available in the village:Pharmacy
	resenv_serv__~4 byte    %6.0f                 services available in the village:Local administrative office
	resenv_serv__~5 byte    %6.0f                 services available in the village:Kindergarten
	resenv_ser~_106 byte    %6.0f                 services available in the village:Primary school
	resenv_serv__~7 byte    %6.0f                 services available in the village:Gymnasium
	resenv_serv__~8 byte    %6.0f                 services available in the village:Recreational facilities
	resenv_serv__~9 byte    %6.0f                 services available in the village:Public transportation
	resenv_s~_66666 byte    %6.0f                 services available in the village:NONE
	

****************************************************************************** */

*  y16 - worries re safety of home and property (reverse coding)
	tab dwell_worr, m nol //  7
	gen y16 = dwell_worr
		replace y16 = 1 if dwell_worr == 5
		replace y16 = 2 if dwell_worr == 4
		replace y16 = 4 if dwell_worr == 2
		replace y16 = 5 if dwell_worr == 1
		replace y16 = . if dwell_worr == 99
		
		tab y16, m


* y17 - quality local roads
	tab res_env_roads,m // 0
	gen y17 = res_env_roads

* y18 -  travel time to the nearest city center (min)
	tab min_city, m
	gen y18 = .
		replace y18 = 5 if min_city <= 5
		replace y18 = 4 if min_city > 5 & min_city <= 10
		replace y18 = 3 if min_city > 10 & min_city <= 20
		replace y18 = 2 if min_city > 20 & min_city <= 30
		replace y18 = 1 if min_city > 30 & min_city != .a

	tab y18, m

* y19 - safety
	tab vill_safe, m //6
	gen y19 = vill_safe
		replace y19 = . if vill_safe == 99 | vill_safe == .a

	tab y19, m

* y20 - services in the village (index)
	mdesc resenv_serv__101 resenv_serv__102 resenv_serv__103 resenv_serv__104 ///
	resenv_serv__105 resenv_serv__106 resenv_serv__107 resenv_serv__108 ///
	resenv_serv__109 resenv_serv__66666
	tab resenv_serv__101, m
	drop if resenv_serv__101 ==. // drop if missing a value on services available
	mdesc resenv_serv__101 resenv_serv__102 resenv_serv__103 resenv_serv__104 ///
	resenv_serv__105 resenv_serv__106 resenv_serv__107 resenv_serv__108 ///
	resenv_serv__109 resenv_serv__66666
	tab resenv_serv__66666, m // 1.98% too samm to distinguish hh
	global services resenv_serv__101 resenv_serv__102 resenv_serv__103 resenv_serv__104 ///
	resenv_serv__105 resenv_serv__106 resenv_serv__107 resenv_serv__108 ///
	resenv_serv__109
* Polychoric 
	polychoric $services
* Display number of obs used 
	display r(sum_w)
* Store number of obs in global macro N 
	global N = r(sum_w)
* Store polychoric correlation matrix as r so that we can use it later below 
	matrix r = r(R)
* CATPCA using the correlation matrix r
	pcamat r, n($N) mineigen(1)
* check model diagnostics 
	factortest $ameneties
* Rotate components
	rotate, varimax
* check eigen values in matrix list 
	matrix list e(Ev)
* Proportion of variance explained by each pc 
* Gen eigenvalue var for the first 2 pcs 
	gen ev = .
	quietly forval i = 1/2 {
	   replace ev = el(e(Ev), 1, `i') in `i'
	}
* calculate the total (r(sum)) of the eigen values
* NB: Magnitude of evs also means magnitude of variance explained by a pc 
	summarize ev, meanonly
	display r(sum)
* gen proportion explained 
	quietly gen prop = ev / r(sum)
* check proportions and evs 
	list ev prop in 1/2
* Save pcs with mineigen 1 
	predict pc1 pc2  
* gen final pc by multiplying each pc with the variance it explains 
	gen pc_final = (pc1 * prop[1]) + (pc2 * prop[2])
*check nature of pc_final
	summ pc_final
* Gen final services index y20 
	xtile y20 = pc_final, n(5) altdef
	label define y20 1 "Low" 5 "High"
	label values y20 y20
	label var y20 "Services index"
* Check nature of final services index 
	tab y20, m
	tabstat pc_final, stat(n mean sd min max p50) by(y20)
* Drop unneccesary vars 
	drop pc_final ev prop pc1 pc2

/* ******************************************************************************	
* M - NATURAL ENVIRONMENT (index for perceived stressors) 

	natenv_nature01 byte    %6.0f      appreciation of nature
	natenv_Water    byte    %6.0f      natenv_Water
												  Quality of water bodies
	natenv_forests  byte    %6.0f      natenv_forests
												  Quality of forests
	natenv_airqua~y byte    %6.0f      natenv_airquality
												  Air quality
	
	natenv_stre~101 byte    %6.0f                 environmental stressors:Groundwater pollution
	natenv_stre~102 byte    %6.0f                 environmental stressors:Heat waves
	natenv_stre~103 byte    %6.0f                 environmental stressors:Excess rainfall or floods
	natenv_stre~104 byte    %6.0f                 environmental stressors:Agricultural drought
	natenv_stre~105 byte    %6.0f                 environmental stressors:Deforestation
	natenv_stre~106 byte    %6.0f                 environmental stressors:Noise pollution (e.g. traffic, construction sites)
	natenv_stre~107 byte    %6.0f                 environmental stressors:Decline of soil quality
	natenv_stre~108 float   %9.0g                 environmental stressors:Decline in the variety of plants and/or animals (biodi
	natenv_stre~112 byte    %6.0f                 environmental stressors:Others
	natenv_st~66666 byte    %6.0f                 environmental stressors:NONE
	natenv_st~88888 byte    %6.0f                 environmental stressors:(I DO NOT KNOW)
	natenv_stress~h str197  %197s                 Environmental stressors: other

****************************************************************************** */

* y21 - appreciation of nature
	tab natenv_nature01, m //4
	gen y21 = natenv_nature01
		replace y21 = . if natenv_nature01 == 99
		tab y21,m

* y22 - Quality of water bodies	
	tab natenv_Water, m // 17
	gen y22 = natenv_Water
		replace y22 = . if natenv_Water == 99
		tab y22
	
* y23 - Quality of forests	
	tab natenv_forests, m //14
	gen y23 = natenv_forests 
		replace y23 = . if natenv_forests == 99
		tab y23,m
	
* y24 - Quality of air	
	tab natenv_airquality, m // 4
	gen y24 = natenv_airquality 
		replace y24 = . if natenv_airquality == 99
		tab y24,m
	
* y25 - environmental stressors (index)
	mdesc natenv_stressors__101 natenv_stressors__102 natenv_stressors__103 ///
	natenv_stressors__104 natenv_stressors__105 natenv_stressors__106 ///
	natenv_stressors__107 natenv_stressors__112 natenv_stressors__66666 ///
	natenv_stressors__88888 natenv_stressors_oth natenv_stressors__108 // natenv_stressors_oth has less than 2% so does not distinguish obs  
	tab natenv_stressors__88888 // less 1% 
	tab natenv_stressors__66666 // over 11% report no stressors, reverse code if considering them is needed, but see note below
	// NB: If they report no stressors, they should anyway be automatically captured by the binary variables, so do not consider no stressors  
	global stressors natenv_stressors__101 natenv_stressors__102 natenv_stressors__103 ///
	natenv_stressors__104 natenv_stressors__105 natenv_stressors__106 ///
	natenv_stressors__107 natenv_stressors__112 natenv_stressors__108
* Polychoric 
	polychoric $stressors
* Display number of obs used 
	display r(sum_w)
* Store number of obs in global macro N 
	global N = r(sum_w)
* Store polychoric correlation matrix as r so that we can use it later below 
	matrix r = r(R)
* CATPCA using the correlation matrix r
	pcamat r, n($N) mineigen(1)
* check model diagnostics 
	factortest $ameneties
* Rotate components
	rotate, varimax
* check eigen values in matrix list 
	matrix list e(Ev)
* Proportion of variance explained by each pc 
* Gen eigenvalue var for the first 3 pcs 
	gen ev = .
	quietly forval i = 1/3 {
	   replace ev = el(e(Ev), 1, `i') in `i'
	}
* calculate the total (r(sum)) of the eigen values
* NB: Magnitude of evs also means magnitude of variance explained by a pc 
	summarize ev, meanonly
	display r(sum)
* gen proportion explained 
	quietly gen prop = ev / r(sum)
* check proportions and evs 
	list ev prop in 1/3
* Save pcs with mineigen 1 
	predict pc1 pc2 pc3  
* gen final pc by multiplying each pc with the variance it explains 
	gen pc_final = (pc1 * prop[1]) + (pc2 * prop[2]) + (pc3 * prop[3])
*check nature of pc_final
	summ pc_final
* Gen final stressors index y25 
	xtile y25 = pc_final, n(5) altdef
	label define y25 1 "Low" 5 "High"
	label values y25 y25
	label var y25 "Stressors index"
* Check nature of final stressors index 
	tab y25, m
	tabstat pc_final, stat(n mean sd min max p50) by(y25)
* Drop unneccesary vars 
	drop pc_final ev prop pc1 pc2 pc3


/* ******************************************************************************	
* F - EDUCATION (educational attainment for AL, KS, ML and RO needs to be harmonised)

	v01_educ_AL     long    %6.0f      v01_educ_AL
												  AL: educational attainment
	v01_educ_KO     int     %6.0f      v01_educ_KO
												  KO: educational attainment
	educ_other_KO   str39   %9s                   educ_other											  
	v01_educ_ML     byte    %2.0f      labels85   ML: educational attainment
	v01_educ_RO     byte    %39.0f     v01_educ_RO
												  RO: educational attainment
	v04_educ        byte    %6.0f      v04_educ   equal access to educational resources
	v06_educ        byte    %6.0f      v06_educ   education prepares individuals for future employment
												  ****************************************************************************** */ 
												  
* y26 - equal access to educational resources
	
	tab v04_educ, m // 3
		gen y26 = v04_educ 
		replace y26 = . if v04_educ == 99
			tab y26, m 
			
* y27 - education prepares individuals for future employment
	
	tab v06_educ, m // 33
		gen y27 = v06_educ 
		replace y27 = . if v06_educ == 99
			tab y27, m 
			
* y28 - educational attainment
	gen educ = .
		tab v01_educ_AL, m 
		tab v01_educ_AL, nol
		tab v01_educ_KO, m
		tab v01_educ_KO, nol
		tab educ_other_KO, m
		tab v01_educ_ML, m
		tab v01_educ_ML, nol
		tab v01_educ_RO, m
		tab v01_educ_RO, nol
		
			replace educ = . if v01_educ_ML == 99 | v01_educ_RO == 99			
			* ISCED 1 - no formal education, primary
			replace educ = 1 if v01_educ_AL == 1 | v01_educ_AL == 2 | ///  
								v01_educ_KO == 1 | v01_educ_KO == 2 | /// 
								v01_educ_ML == 2 
			* ISCED 2 - lower secondary education
			replace educ = 2 if v01_educ_AL == 3 | ///
								v01_educ_KO == 3 | ///
								v01_educ_ML == 3 | ///
								v01_educ_RO == 3 | v01_educ_RO == 4
			* ISCED 3 - higher secondary education
			replace educ = 3 if v01_educ_AL == 4 | v01_educ_AL == 5 | v01_educ_AL == 6 | ///
								v01_educ_KO == 4 | v01_educ_KO == 5 | ///
								educ_other_KO == "Shkolla e mesme e Lartë Teknike" | ///
								educ_other_KO == "Shkolla e mesme e lartë Ekonomike" | ///
								educ_other_KO == "Shkolla e mesme e lartë Ekonomike." | ///
								educ_other_KO == "Shkolla e mesme e lartë Teknike" | ///
								educ_other_KO == "Shkolla e mesme e lartë Teknike." | ///
								educ_other_KO == "Shkolla e mesme e lartë e mjeksisë" | ///
								educ_other_KO == "shkolla e mesme e lartë Bujqesore" | ///
								educ_other_KO == "shkolla e mesme e lartë Ekonomike" | ///
								educ_other_KO == "shkolla e mesme e lartë Teknike" | ///
								educ_other_KO == "shkolla e mesme e lartë e Bujqësisë." | ///
								v01_educ_ML == 4 | ///
								v01_educ_RO == 5 
			* ISCED 4 - post-secodary, non-tertiary education
			replace educ = 4 if v01_educ_AL == 7 | ///
								v01_educ_KO == 6 | ///
								v01_educ_ML == 5 | v01_educ_ML == 6 | ///
								v01_educ_RO == 6
			* ISCED 5-8 - tertiary education (university and post-graduate education)
			replace educ = 5 if v01_educ_AL == 8 | v01_educ_AL == 9 | ///
								v01_educ_KO == 7 | v01_educ_KO == 8 |  v01_educ_KO == 9 | ///
								v01_educ_ML == 7 | v01_educ_ML == 8 | v01_educ_ML == 9 | ///
								v01_educ_RO == 7 | v01_educ_RO == 8
		
	label variable educ "Educational attainment (ICED 2011)"
	label define educ 1 "ISCED 1" 2 "ISCED 2" 3 "ISCED 3" 4 "ISCED 4" 5 "ISCED 5-8" 
	label values educ educ
	
	tab educ

	gen y28 = educ
		label variable y28 "Educational attainment (ICED 2011)"
		label values y28 educ
	tab y28, m

	
/* ******************************************************************************		
* N - JOB & FINANCIAL SITUATION (index for assets; harmonize income categories across countries)

	v11_job         byte    %6.0f      v11_job    ease of finding a job
	v01_assets__101 byte    %6.0f                 assets:A car
	v01_assets__102 byte    %6.0f                 assets:The house or apartment you live in (your main residence).
	v01_assets__103 byte    %6.0f                 assets:Secondary residence
	v01_assets__105 byte    %6.0f                 assets:Non-agricultural land
	v01_assets__106 byte    %6.0f                 assets:Agricultural land
	v01_assets__108 byte    %6.0f                 assets:Agricultural maschines or any other maschines
	v01_assets__109 byte    %6.0f                 assets:Savings or investments
	v01_assets__110 byte    %6.0f                 assets:A computer / laptop / tablet
	v01_assets__112 byte    %6.0f                 assets:Other
	v01_assets_oth  str26   %26s                  Other assets
	totalAnimals    double  %6.2f                 Calculated total number of animals


	v08_finance     byte    %6.0f    			  sufficiency: income
	v07_finance     byte    %6.0f      			  possibility of losing source of income
	incinequ        byte    %6.0f      incinequ   income inequality	
****************************************************************************** */ 	

*** INCOME
	
	* Check nature of vars for finances and income 
	* sufficiency: income
		tab v08_finance, m // only four categories, order ok! 

	* y29 - possibility of losing source of income
		tab v07_finance, m
		gen y29 = v07_finance
		* reverse code
			recode y29 (1=5) (2=4) (4=2) (5=1) (99=.) (.a=.)
			label define v07_finances 1 "Highly worried" 5 "Not worried at all"
			label values y29 v07_finances
			tab y29,m

	* y30 - income inequality
		tab incinequ, m 
		gen y30 = incinequ
			recode y30 (1=5) (2=4) (4=2) (5=1) (99=.) (.a=.)
			label define incinequs 1 "Strongly agree" 2 "Agree" 3 "Neither, nor" 4 "Disagree" 5 "Strongly disagree" 
			label values y30 incinequs
			tab y30,m


			* Check missingness for finances and income
			mdesc v08_finance y29 y30 // less than 1% on each var

*** ASSETS
		* Check nature of totalAnimals var
		tab totalAnimals, m // no missings

		* Standardize or rescale totalAnimal var so it runs from 0 to 1 
		* Summarize to get the min and max
		summarize totalAnimals
		* Generate rescaled variable 
		gen totalAnimal_st = (totalAnimals - r(min)) / (r(max) - r(min))

		* Confirm nature of new variable
		summarize totalAnimal_st, d

		* check nature of the main asset list 
		local varlist v01_assets__101 v01_assets__102 v01_assets__103 v01_assets__105 v01_assets__106 v01_assets__107 v01_assets__108 v01_assets__109 v01_assets__110 v01_assets__112
		foreach var of local varlist {
			tab `var', m // all mvs decoded 
		}

		* Check missingness in assets list
		tab1 v01_assets__101 v01_assets__102 v01_assets__103 v01_assets__105 v01_assets__106 v01_assets__107 v01_assets__108 v01_assets__109 v01_assets__110 v01_assets__112 totalAnimal_st, m // only 1 obs  

		* Drop obs missing info on any of the vars 
		local varlist v01_assets__101 v01_assets__102 v01_assets__103 v01_assets__105 v01_assets__106 v01_assets__107 v01_assets__108 v01_assets__109 v01_assets__110 v01_assets__112 v07_finance incinequ totalAnimal_st // v08_finance excluded since it has only 4 categories 
		foreach var of local varlist {
			drop if missing(`var')
		}

		* Double check missingness  
		mdesc v01_assets__101 v01_assets__102 v01_assets__103 v01_assets__105 v01_assets__106 v01_assets__107 v01_assets__108 v01_assets__109 v01_assets__110 v01_assets__112 v07_finance incinequ totalAnimal_st

		* Create an assets index using PCA
		global assets v01_assets__101 v01_assets__102 v01_assets__103 ///
		v01_assets__105 v01_assets__106 v01_assets__107 v01_assets__108 ///
		v01_assets__109 v01_assets__110 // v01_assets__112  has a few cases and they cause problems in the correlation structure. See more info below

		tab v01_assets__112 , m // only 0.3% cases so they do not help to distinguish cases, do not include v01_assets__112  in assets list
	
* check model diagnostics 
	factortest $assets
* Polychoric 
	polychoric $assets
* Display number of obs used 
	display r(sum_w)
* Store number of obs in global macro N 
	global N = r(sum_w)
* Store polychoric correlation matrix as r so that we can use it later below 
	matrix r = r(R)
* CATPCA using the correlation matrix r
	pcamat r, n($N) mineigen(1)
* Rotate components
	rotate, varimax
* check eigen values in matrix list 
	matrix list e(Ev)
* Proportion of variance explained by each pc 
* Gen eigenvalue var for the first 2 pcs 
	gen ev = .
	quietly forval i = 1/2 {
	   replace ev = el(e(Ev), 1, `i') in `i'
	}
* calculate the total (r(sum)) of the eigen values
* NB: Magnitude of evs also means magnitude of variance explained by a pc 
	summarize ev, meanonly
	display r(sum)
* gen proportion explained 
	quietly gen prop = ev / r(sum)
* check proportions and evs 
	list ev prop in 1/2
* Save pcs with mineigen 1 
	predict pc1 pc2   
* gen final pc by multiplying each pc with the variance it explains 
	gen pc_final = (pc1 * prop[1]) + (pc2 * prop[2])
*check nature of pc_final
	summ pc_final
* Gen final assets index y30a 
	xtile y30a = pc_final, n(5) altdef
	label define y30a 1 "Low" 5 "High"
	label values y30a y30a
	label var y30a "Assets index"
* Check nature of final assets index 
	tab y30a, m
	tabstat pc_final, stat(n mean sd min max p50) by(y30a)
* Drop unneccesary vars 
	drop pc_final ev prop pc1 pc2

	
********************************************************************************
* attitudes and opinions
********************************************************************************
	* Worries
		gen y31 = v01_concern 
		gen y32 = v03_concern
		gen y33 = v07_concern
		gen y34 = v08_concern
		gen y35 = v10_concern
		
		
		foreach num of numlist 31/35 {
			recode y`num' (5=1) (4=2) (2=4) (1=5) (99=.) (.a=.)
			}
	* Place attachment
		tab1 v16_pa v01_pa v03_pa v02_pa,m
		
		gen y36 = v16_pa 
		gen y37 = v01_pa
		gen y38 = v03_pa
		gen y39 = v02_pa
		
		foreach num of numlist 34/39 {
			recode y`num'  (99=.) (.a=.)
			}


********************************************************************************
* POTENTIAL OUTCOMES FOR POSTESTIMATION REGRESSIONS
********************************************************************************			

* Intention to stay

	tab vill_staying, m
	ren vill_staying si

* Intention to migrate		
	tab v03_mi,m
			gen mi = v03_mi
				replace mi = . if v03_mi==99 |  v03_mi==88888
				replace mi = 0 if v03_mi==2
				lab var mi "Migration intention (0/1)"
			
			
********************************************************************************
* Data prep for R
* Rename vars, save wide file, clean vars, convert to long for IRM
********************************************************************************
global controls 		age female hhsize kids_LT6 mat_leave maritalstat ///
						unempl student employee self_empl contr_work ///
						occ_work retired big5_extra big5_agree big5_conc ///
						big5_neuro big5_open
					
global social_d 		y3 y4 y5 y6  // too many missings y1 y2 
					
					
global civ_engage_d 	y7 y8 y9 y10 
					
					
global health_d 		y11 y12 
					
					
					
global housing_d 		y13 y14 y15 y15a // index: y15a | ammenities
					
					
					
global res_env_d 		y16 y17 y18 y19 y20  	// index:  y20 | services 
					
					
					
global nat_env_d 		y21 y22 y23 y24 y25  	// index: y25 | stressors
					
					
global educ_d 			y26 y27 y28 
					
					
global job_finance_d 	y29 y30 y30a			// index for assets | y30a, income categories are missing
					
					
global att_opinions_d 	y31 y32 y33 y34 y35 y36 y37 y37	y38 y39				
					
					
d $controls $social_d $civ_engage_d $health_d $housing_d $res_env_d $res_env_d $nat_env_d $educ_d $job_finance_d $att_opinions_d

					
* Drop on key variables - reducing data set temporarily to make things easier

	local varlist $controls  $y 

	foreach var of local varlist{
			drop if `var'>=.
	}

tab country, nolabel // still large enough samples after drops

* saving in wide format before converting to long  
saveold stata/dat/ruwell-test1-wide.dta, replace version(12)


*** converting to long
reshape long y, i(id) j(item)
sort id item

*** generating dimension identifier
gen dim = .
	replace dim = 1 if item < 5                  // social domain
	replace dim = 2 if item >= 5 & item < 9      // civic engagement
	replace dim = 3 if item >= 9 & item < 13     // household characteristics
	replace dim = 4 if item >= 13 & item < 17    // natural environment
	replace dim = 5 if item >= 17 & item < 22    // attitudes and opinions
	
count if missing(y)

keep id y item dim country gender age age_group si mi

* Save data 
saveold ${path}ruwell.v01.dta, replace version(12) 

use ${path}ruwell-test1-wide.dta, clear

********************************************************************************
* renaming/dropping vars
********************************************************************************

keep id country y* si mi ///
	age female hhsize kids_LT6 mat_leave maritalstat ///
	unempl student employee self_empl contr_work ///
	occ_work retired big5_extra big5_agree big5_conc ///
	big5_neuro big5_open
	
* Some house keeping 
capture drop y1 y2 y15h

cor y15 y15a // checking differences in asset items (additive vs index)

drop y15 // keeping the index (cor = 1; makes no difference)

* checking categories
foreach var of varlist y* {
	tab `var', m
	drop if `var' == .
	drop if `var' == 99
}

* rename all vars 
rename y3 y1
rename y4 y2
rename y5 y3
rename y6 y4
rename y7 y5
rename y8 y6
rename y9 y7
rename y10 y8
rename y11 y9
rename y12 y10
rename y13 y11
rename y14 y12
rename y15a y13
rename y16 y14
rename y17 y15
rename y18 y16
rename y19 y17
rename y20 y18
rename y21 y19
rename y22 y20
rename y23 y21
rename y24 y22
rename y25 y23
rename y26 y24
rename y27 y25
rename y28 y26
rename y29 y27
rename y30 y28
rename y30a y29
rename y31 y30
rename y32 y31 
rename y33 y32
rename y34 y33
rename y35 y34
rename y36 y35
rename y37 y36
rename y38 y37
rename y39 y38

* dta file for dimension analysis
saveold ${path}ruwell-final-wide.dta, replace version(12)
