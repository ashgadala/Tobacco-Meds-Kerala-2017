*********************************************************************************************
* PROGRAM     : P:\Smitha\Keralan Tobacco Pharmacy.sas										*
* DESCRIPTION : 																			*
* PROGRAMMER  : Abigail Baldridge		 	            									*
* DATE		  : June 27, 2017																*
*********************************************************************************************;

Libname RawData "P:\Smitha\Data";

Data Raw; Set RawData.Raw; Run; 

Proc Sort Data = Raw; By PharmacyID; Run;

*Create list of unique pharmacies;
Data Summary (keep = Location Level Pharmacy_Type PharmacyID Any_drugs_); Set Raw;
	By PharmacyID;
	If First.PharmacyID;
Run;

*********************************************************************************************
Table 1																			
*********************************************************************************************;
Proc Freq Data = Summary;
	Table Pharmacy_Type * Any_drugs_ * Level/ nopercent norow;
	ods output crosstabfreqs = Table1;
Run;

Data Table1 Totals; Set Table1;
	If Level = " " then Level = "Total";
	If Any_drugs_ = . then output Totals;
	If Any_drugs_ = 1 then output Table1;
Run;

Proc Sort Data = Table1; By Pharmacy_Type Level; Run;
Proc Sort Data = Totals; By Pharmacy_Type Level; Run;

Data Totals; Set Totals;
	NSurveyed = Frequency;
Run;

Data Table1; 
	Merge
	Table1
	Totals (keep = Pharmacy_Type Level NSurveyed);
	By Pharmacy_Type Level;
Run;

Data Table1 (Drop = Table _TYPE_ Missing Any_drugs_ _TABLE_ Frequency ColPercent); Set Table1;
	Length N_PCT $9.;
	If Level = "Total" then do;
		ColPercent = 100 * Frequency / NSurveyed;
		Order = 9;
	End;
	Else if Level = "General" then Order = 1;
	Else if Level = "District" then Order = 2;
	Else if Level = "Taluk" then Order = 3;
	Else if Level = "Community" then Order = 4;
	Else if Level = "Primary" then Order = 5;
	Else if Level = "Chest/TB" Then Order = 6;
	Else if Level = "Depot" then do;
		Level = "Karunya Depot";
		Order = 7;
	End;
	Else if Level = "Karunya" then do;
		Level = "Karunya Outlet";
		Order = 8;
	End;
	If NSurveyed = 0 then N_PCT = "-";
	else N_PCT = trim(left(put(Frequency,3.)))||" ("||trim(left(put(ColPercent,3.)))||"%)";
Run;

Proc Sort Data = Table1; By Level; Run;

Data Karunya Private Public; Set Table1;
	If Pharmacy_Type = "Karunya" then output Karunya;
	If Pharmacy_Type = "Private" then output Private;
	If Pharmacy_Type = "Public" then output Public;
Run;

Data Table1; 
	Merge
	Public (rename  = (NSurveyed = PubNSurveyed N_PCT = PubN_PCT))
	Private (rename = (NSurveyed = PriNSurveyed N_PCT = PriN_PCT))
	Karunya (rename = (NSurveyed = KarNSurveyed N_PCT = KarN_PCT));
	By Level;
Run;

Proc Sort Data = Table1; By Order; Run;

Data Table1 (Drop = Order Pharmacy_Type);	 Set Table1;
	Total = PubNSurveyed + PriNSurveyed + KarNSurveyed;
Run;

*Print Table 1;
Proc Print Data = Table1 noobs; Run;

*Public Hospitals had no medications available, and are dropped from further analysis;
Data Analysis; Set Raw;
	If Pharmacy_Type = "Public" then delete;
Run;

Data Summary; Set Summary; 
	If Pharmacy_Type = "Public" then delete;
Run;

*Run model for availability by type;
Proc Logistic Data = Summary desc;
	Class Pharmacy_Type (ref='Karunya');
	Model Any_drugs_ = Pharmacy_Type;
Run; 

*Remove extra datasets;
Proc Datasets lib=work nolist;
delete Table1 Totals Karunya Private Public; 
quit; run;

*********************************************************************************************
Table 2																			
*********************************************************************************************;
Proc Freq Data = Summary;
	Table Pharmacy_Type * Any_drugs_ * Location/ nopercent norow;
	ods output crosstabfreqs = Table2;
Run;

Data Table2 Totals; Set Table2;
	If Location = " " then Location = "Total";
	If Any_drugs_ = . then output Totals;
	If Any_drugs_ = 1 then output Table2;
Run;

Proc Sort Data = Table2; By Pharmacy_Type Location; Run;
Proc Sort Data = Totals; By Pharmacy_Type Location; Run;

Data Totals; Set Totals;
	NSurveyed = Frequency;
Run;

Data Table2; 
	Merge
	Table2
	Totals (keep = Pharmacy_Type Location NSurveyed);
	By Pharmacy_Type Location;
Run;

Data Table2 (Drop = Table _TYPE_ Missing Any_drugs_ _TABLE_ ColPercent); Set Table2;
	Length N_PCT $9.;
	If Location = "Total" then do;
		ColPercent = 100 * Frequency / NSurveyed;
		Order = 6;
	End;
	Else if Location = "Ernakulam" then Order = 1;
	Else if Location = "Kollam" then Order = 2;
	Else if Location = "Kozhikode" then Order = 3;
	Else if Location = "Trivandrum" then Order = 4;
	Else if Location = "Wayanad" then Order = 5;
	N_PCT = trim(left(put(Frequency,3.)))||" ("||trim(left(put(ColPercent,3.)))||"%)";
Run;

Proc Sort Data = Table2; By Location; Run;

Data Karunya Private; Set Table2;
	If Pharmacy_Type = "Karunya" then output Karunya;
	If Pharmacy_Type = "Private" then output Private;
Run;

Data Table2; 
	Merge
	Private (rename = (NSurveyed = PriNSurveyed N_PCT = PriN_PCT Frequency = PriFrequency))
	Karunya (rename = (NSurveyed = KarNSurveyed N_PCT = KarN_PCT Frequency = KarFrequency));
	By Location;
Run;

Data Table2 (Drop = Pharmacy_Type PriFrequency KarFrequency); Set Table2;
	Total = PriNSurveyed + KarNSurveyed;
	N_PCT = trim(left(put(PriFrequency + KarFrequency,3.)))||" ("||trim(left(put((100*(PriFrequency + KarFrequency)/Total),3.)))||"%)";
Run;

*Run model for availability by location;
Proc Logistic Data = Summary desc;
	Class Location (ref='Wayanad');
	Model Any_drugs_ = Location;
	ods output OddsRatios = Estimates;
Run; 

Data Estimates; Set Estimates;
	Location = Scan(Effect,2);
	Odds = trim(left(put(OddsRatioEst,4.1)))||" ("||trim(left(put(LowerCL,4.1)))||", "||trim(left(put(UpperCL,4.1)))||")";
Run;

Data Table2;
	Merge
	Table2
	Estimates (Keep = Location Odds);
	By Location;
	if Location = "Wayanad" then Odds = "Ref";
Run;

Proc Sort Data = table2; By Order; Run;

Data Table2 (Drop = Order); Set Table2; Run; 

*Print Table 2;
Proc Print Data = Table2 noobs; Run;

*Remove extra datasets;
Proc Datasets lib=work nolist;
delete Table2 Karunya Private Temp Totals Estimates; 
quit; run;

*********************************************************************************************
Table 3 Not Created in SAS																			
*********************************************************************************************;

*********************************************************************************************
Table 4 Not Created in SAS																	
*********************************************************************************************;

*********************************************************************************************
Table 5	Created with ACS QUIK Data																
*********************************************************************************************;

*********************************************************************************************
Table 6	Created with ACS QUIK Data																
*********************************************************************************************;

*********************************************************************************************
Table S1 Not Created in SAS																			
*********************************************************************************************;

*********************************************************************************************
Table S2																			
*********************************************************************************************;
Proc Sort Data = Analysis; by PharmacyID; Run;

*Keep pharmacies where some drugs were available;
Data DrugsAvail; Set Analysis;
	If Any_drugs_= 1; 
Run;

*Create ID for drug items;
Data DrugsAvail; set DrugsAvail;
	Length ID $60.;
	ID = trim(left(Chemical_Name)) || trim(left(Brand)) || trim(left(Manufacturer)) || trim(left(Delivery_Route)) || trim(left(Strength)) || trim(left(Pack_Size));
Run;

Proc Freq Data = DrugsAvail;
	Table ID;
Run;

Proc Transpose Data = DrugsAvail out=DrugsWide;
	by PharmacyID;
	Id ID;
	Var Any_drugs_;
Run;

Data DrugsWide (drop = _NAME_ _LABEL_); Set DrugsWide; Run; 

*Create indicators if a pharmacy had any type of bupropion, nicotine or varenicline available;
Data DrugsWide; Set DrugsWide;
	*Bupropion;
	If BupropionBupron_SRSunTablet150mg = 1 or BupropionBupron_XLSunTablet150mg = 1 or BupropionBupron_XLSunTablet300mg = 1 then Bupropion = 1;
	Else Bupropion = 0;
	If BupropionBupron_XLSunTablet150mg = 1 or BupropionBupron_XLSunTablet300mg = 1 then BupropionXL = 1;
	Else BupropionXL = 0;
	If BupropionBupron_SRSunTablet150mg = . then BupropionBupron_SRSunTablet150mg = 0;
	*Nicotine;
	If NicotineNicogumCiplaGum2mg10 = 1 or NicotineNicogumCiplaGum4mg10 = 1 or NicotineNicotexCiplaGum2mg9 = 1 or NicotineNicotexCiplaGum4mg9 = 1 then Nicotine = 1;
	Else Nicotine = 0;
	If NicotineNicogumCiplaGum2mg10 = 1 or NicotineNicogumCiplaGum4mg10 = 1 then NicotineNicogum = 1;
	Else NicotineNicogum = 0;
	If NicotineNicotexCiplaGum2mg9 = 1 or NicotineNicotexCiplaGum4mg9 = 1 then NicotineNicotex = 1;
	Else NicotineNicotex = 0;
	*Varenicline;
	If VareniclineChampixPfizerTabletMa = 1 or VareniclineChampixPfizerTabletSt = 1 then Varenicline = 1;
	Else Varenicline = 0;
Run;

Proc Sort Data = DrugsWide; by PharmacyID; Run;
Proc Sort Data = Summary; By PharmacyID; Run;
	
Data DrugsWide;
	Merge
	DrugsWide (in=in1)
	Summary (keep = PharmacyID Location Pharmacy_type Level);
	By PharmacyID;
	If in1;
Run;

*Calculate proportion where each drug is available;
Proc Freq Data = DrugsWide;
	Table Nicotine * Pharmacy_type/ nopercent norow;
	Table NicotineNicogum * Pharmacy_type/ nopercent norow;
	Table NicotineNicotex * Pharmacy_type/ nopercent norow;
	Table Bupropion * Pharmacy_type / nopercent norow;
	Table BupropionBupron_SRSunTablet150mg * Pharmacy_type/ nopercent norow;
	Table BupropionXL * Pharmacy_type / nopercent norow;
	Table Varenicline * Pharmacy_type/ nopercent norow;
	ods output crosstabfreqs = TableS2;
Run;

Data TableS2 (Keep = Pharmacy_Type N_PCT DrugType); Set TableS2;
	Length DrugType $20.;
	Where Nicotine = 1 or NicotineNicogum = 1 or NicotineNicotex = 1 or Bupropion = 1 or BupropionBupron_SRSunTablet150mg = 1 or BupropionXL = 1 or Varenicline = 1;
	If Pharmacy_Type = "" then do;
		Pharmacy_Type = "Total";
		ColPercent = 100* Frequency / 75;
	End;
	N_PCT = trim(left(Frequency)) || " (" || trim(left(round(ColPercent,1))) || "%)";
	If Nicotine = 1 then DrugType = "Nicotine";
	If NicotineNicogum = 1 then DrugType = "Nicogum";	
	If NicotineNicotex = 1 then DrugType = "Nicotex";
	If Bupropion = 1 then DrugType = "Bupropion";
	If BupropionBupron_SRSunTablet150mg = 1 then DrugType = "Bupropion SR";
	If BupropionXL = 1 then DrugType = "Bupropion XL";
	If Varenicline = 1 then DrugType = "Varenicline";
Run;

Proc Sort Data = TableS2; By DrugType; Run;

Proc Transpose Data = TableS2 out = TableS2;
	Var N_PCT;
	By DrugType;
	Id Pharmacy_type;
Run;

Data TableS2 (Drop = _NAME_); Set TableS2; 
	If DrugType = "Nicotine" then Order = 1;
	Else if DrugType = "Nicogum" then Order = 2;
	Else if DrugType = "Nicotex" then Order = 3;
	Else if DrugType = "Bupropion" then Order = 4;
	Else if DrugType = "Bupropion SR" then Order = 5;
	Else if DrugType = "Bupropion XL" then Order = 6;
	Else if DrugType = "Varenicline" then Order = 7;
Run;

Proc Sort Data = TableS2; by Order; Run;

Proc Print Data = TableS2 noobs; 
	Var DrugType Private Karunya Total;
Run;









