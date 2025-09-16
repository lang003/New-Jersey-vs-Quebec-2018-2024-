data NJ2018;
	set work.'2019'n;
	if State= 34;
	Keep State STName County Births2018 Births2019 RBirth2018 RBirth2019 Deaths2018 Deaths2019 RDeath2018 RDeath2019 CTYName Popestimate2018 
	Popestimate2019;
	run;

data NJ2024;
	set '2024'n;
	if State= 34;
	Keep State StName County Births2020  Births2021 Births2022 Births2023 Births2024
	RBirth2021 RBirth2022 RBirth2023 RBirth2024 Deaths2020 Deaths2021 Deaths2022 Deaths2023 Deaths2024
	RDeath2021 RDeath2022 RDeath2023 RDeath2024 CTYName 
	Popestimate2020 Popestimate2021 Popestimate2022 Popestimate2023 Popestimate2024;
	run;
	
proc sql;
	create table fullNJ as 
	select * from NJ2018 full join NJ2024 
	on nj2018.county=NJ2024.county;
	quit;
	
data CleanNJ;
	set FullNJ;
	RBIRTH2020= (Births2020/PopEstimate2020)*1000;
	RDEATH2020= (Deaths2020/PopEstimate2020)*1000;
	drop pop: Death: Birth: ;
	if 2<= _N_ <= 22 then delete;
	
	run;

proc datasets lib=work nolist;
    modify CleanNJ;
    format rDeath: comma8.1 rBirth: comma8.1;
quit; 
proc transpose data=CleanNJ out=long(rename=(col1=Rate _name_=VarName));
    var RBIRTH: RDEATH:;
run;

/* Step 2: Extract measure + year */
data tidy;
    set long;
    length Measure $6;
    if index(VarName,'RBIRTH') then Measure='Birth';
    else if index(VarName,'RDEATH') then Measure='Death';

    Year = compress(VarName,,'kd'); /* keep digits only */
    keep Measure Year Rate;

run;
proc sort data=tidy;
    by Measure Year; 
run;


/* Step 3: Pivot back to wide (years as columns, 2 rows) */
proc transpose data=tidy out=finalNJRate(drop=_name_);
    by Measure;
    id Year;
    var Rate;
run;
data NJRate;
	set finalNJRate;
	rename Measure=Rate;
	run;
data step1;
    set NJRate(rename=(
        "2018"n=Y2018
        "2019"n=Y2019
        "2020"n=Y2020
        "2021"n=Y2021
        "2022"n=Y2022
        "2023"n=Y2023
        "2024"n=Y2024
    ));  /*arrays don't like numbers*/
run;
data FNJRate;
    set step1;
    array nums Y2018-Y2024;             /* numeric vars */
    array chars(7) $ _2018-_2024;     /* new char vars (note: names can’t start with digits) */

    do i = 1 to dim(nums);
        chars(i) = put(nums(i), 8.1);  /* convert to char with width 8 */
    end;

    drop i Y:;
        rename _2018="2018"n _2019="2019"n _2020="2020"n _2021="2021"n _2022="2022"n _2023="2023"n _2024="2024"n;
run;



/*crude calculation since 2020 is decennial census year*/
/*April 1, 2020 Census count*/

data CleanAge2019;
	set age2019;
	if state=34;
	keep Name Age Popest2018_CIV PopEst2019_CIV Sex;
	run;
data Cleanage2024;
	set age2024;
	if State=34;
	keep Name Age Popest2020_CIV Popest2021_CIV Popest2022_CIV Popest2023_CIV 
	Popest2024_CIV Sex;
	run;
	
proc sql;
	create table averageage as
    select distinct sum(age * popest2018_civ) / sum(popest2018_civ) as Avg_Age2018,
    sum(age * popest2019_civ) / sum(popest2019_civ) as Avg_Age2019, Name,Sex
    from CleanAge2019
      where age <= 100
      group by Name, sex;
      
quit;

proc sql;
	create table averageage1 as
    select distinct sum(age * popest2020_civ) / sum(popest2020_civ)as Avg_Age2020,
    sum(age * popest2021_civ) / sum(popest2021_civ) as Avg_Age2021,
    sum(age * popest2022_civ) / sum(popest2022_civ) as Avg_Age2022,
    sum(age * popest2023_civ) / sum(popest2023_civ) as Avg_Age2023,
    sum(age * popest2024_civ) / sum(popest2024_civ) as Avg_Age2024,
    Name,Sex
    from CleanAge2024
      where age <= 100
      group by Name, sex;
      
quit;

proc sql;
	create table USAage as
	select * from averageage full join averageage1
	on averageage.sex=averageage1.sex;
	quit;
proc sql;
    create table USAOrganized as
    select 
        Name,
        Sex,
        put(Avg_Age2018, comma8.2) as Avg_Age2018_char,
        put(Avg_Age2019, comma8.2) as Avg_Age2019_char,
        put(Avg_Age2020, comma8.2) as Avg_Age2020_char,
        put(Avg_Age2021, comma8.2) as Avg_Age2021_char,
        put(Avg_Age2022, comma8.2) as Avg_Age2022_char,
        put(Avg_Age2023, comma8.2) as Avg_Age2023_char,
        put(Avg_Age2024, comma8.2) as Avg_Age2024_char
    from USAage;
quit;

data finalNJ;
	set USAOrganized;
	sex1 = put(sex, format.);
	if sex= 0 then sex1="Total";
	if sex=1 then sex1= "Male";
	if sex=2 then sex1= "Female";
	drop sex;
	rename sex1=sex;
	rename Avg_Age2018_Char= Avg_Age2018;
	rename Avg_Age2019_Char= Avg_Age2019;
	rename Avg_Age2020_Char= Avg_Age2020;
	rename Avg_Age2021_Char= Avg_Age2021;
	rename Avg_Age2022_Char= Avg_Age2022;
	rename Avg_Age2023_Char= Avg_Age2023;
	rename Avg_Age2024_Char= Avg_Age2024;
	run;
	
/*Quebec*/
data QueAge;
	set QuebecAge;
	keep Var50 Var51 Var52 Var53 Var54 Var55 Var56 'Estimations de la population se'n Var2;
	 if 81 <= _N_ <= 100 then delete;
	 if 1<=_N_ <= 3 then delete;
	 if 5<=_N_ <= 28 then delete;
	 if 31<=_N_ <= 53 then delete;
	 if 56<=_N_ <= 78 then delete;
	 drop var2 'Estimations de la population se'n;
	run;
data QueAge1;
	set QueAge;
	if 8 <= _N_ <=29 then delete;
	if Var50= 42.4 then delete;
	if Var50= 41.5 then delete;
	if Var50= 43.3 then delete;
	if Var50= 42.2 then Sex= "Total";
	if var50=41.3 then Sex= "Male";
	if var50= 43 then Sex= "Female";
	if 1=_N_ then delete;
	rename var50='Avg_Age2018'n;
	rename var51='Avg_Age2019'n;
	rename var52='Avg_Age2020'n;
	rename var53='Avg_Age2021'n;
	rename var54='Avg_Age2022'n;
	rename var55='Avg_Age2023'n;
	rename var56='Avg_Age2024'n;
	
	run;
data QueRate;
	set import;
	drop "19"n: "200"n: "2011"n "2012"n "2013"n "2014"n
	"2015"n "2016"n "2017"n "2010"n;
	if 1<=_N_ <=19 then delete;
	if 21<= _N_ <= 38 then delete;
	if "2018"n= "10" then Var1= "Birth";
	if "2018"n= "8.2" then Var1= "Death";
	rename Var1= Rate;
	drop "Code RA"n;
	rename "2023ᵖ"n= "2023"n;
	rename "2024ᵖ"n = "2024"n;
	run;

	

/*final*/
proc sort data=finalNJ; by Sex; run;
proc sort data=queage1; by Sex; run;

data FinalAvgAge;
   set finalNJ QueAge1;
   if Name= " " then Name= "Quebec";
run;

data FinalRate;
	set QueRate FNJRate;
	if "Région administrative¹"n= "" then "Région administrative¹"n= "New Jersey";
	if "Région administrative¹"n = "Ensemble du Québec" then "Région administrative¹"n= "Quebec";
	rename "Région administrative¹"n = "Name"n;
	
	run;
	
proc transpose data=FinalAge out=longdata name=Year;
   by Name Sex;
   var Avg_Age2018-Avg_Age2024;
run;

data FinalAge1;
	set longdata;
	if year= "Avg_Age2018" then year= 2018;
	if year= "Avg_Age2019" then year= 2019;
	if year= "Avg_Age2020" then year= 2020;
	if year= "Avg_Age2021" then year= 2021;
	if year= "Avg_Age2022" then year= 2022;
	if year= "Avg_Age2023" then year= 2023;
	if year= "Avg_Age2024" then year= 2024;
	run;

proc sort data=finalrate out=finalrate_sorted;
    by Name Rate;
run;

proc transpose data=finalrate_sorted out=finalrate1 name=Year;
    by Name Rate;
    var "2018"n-"2024"n;
run;
	
