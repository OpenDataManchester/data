# Local Political Representation in England Datasets 050918

The datasets are an up date of Open Data Manchester's DEPvsREP dataset created on the 24th April 2018 prior to the local elections in England in May 2018.
The dataset was split into three datasets and expanded to include [Electoral Commission political party identity codes](http://search.electoralcommission.org.uk)
The data was collated by Pamilla Kang using python scraping scripts [Github repository](https://github.com/pkkang/Deprivation-in-England) and manually.

## Datasets
**URL_LAD.csv - Webpage for councillor information, Local Authority District**
Contains the following data for Local Authorities in England
+ LAD18NM - Name of Local authority
+ LAD18CD - Local authority code
+ URL - Web page from which councillor information was collected

**LPR_LSOA_WD_LAD.csv - Local Political Representation, Lower Super Output Area, Ward and Local Authority District**
Contains:
+LSOA11CD - Unique LSOA identifier
+LSOA11NM - LSOA name
+WD18CD - Unique ward identifier
+WD18NM - Name of ward
+LAD18CD - Local Authority District identifier
+LAD18NM - Local Authority District Name
+IMD15 - Indices of Multiple Deprivation 2015 ranking
+COUNC1 - Elected councillor 1. Full party name
+COUNC2 - Elected councillor 2. Full party name
+COUNC3 - Elected councillor 3. Full party name
+REPR - Balance of representation for ward. Normalised to 8 categories see COUNCILLOR POLITICAL AFFILIATION CODING below

**LPR_LSOA_WD_LAD_IMD15.csv - Local Political Representation, Lower Super Output Area, Ward, Local Authority District and Indices of Multiple Deprivation**
Contains
+LSOA11CD - Unique LSOA identifier
+LSOA11NM - LSOA name
+WD18CD - Unique ward identifier
+WD18NM - Name of ward
+LAD18CD - Local Authority District identifier
+LAD18NM - Local Authority District Name
+IMD15 - Indices of Multiple Deprivation 2015 ranking
+COUNC1 - Elected councillor 1. Full party name
+COUNC2 - Elected councillor 2. Full party name
+COUNC3 - Elected councillor 3. Full party name
+REPR - Balance of representation for ward. Normalised to 8 categories see COUNCILLOR POLITICAL AFFILIATION CODING below
+IMD15 - Indices of Multiple Deprivation 2015 ranking

**LPP_LAD_ECID.csv - Political Party, Local Authority District, Electoral Commission Identifier, Regulated Entity Name, Regulated Entity Type, Registration Status, Register and Approved Date**
+Party - Name of party on local authority website
+LAD18NM - Local Authority District Name
+LAD18CD - Local Authority District identifier
+ECRef - Electoral Commission Identifier
+RegulatedEntityName - Name registered at the Electoral Commission
+RegulatedEntityType - Type of political party
+RegistrationStatus - Status of registration
+RegisterName - Territory covered
+ApprovedDate - Date registration approved

*These datasets were compiled using data from the following sources*
+Ministry of Housing, Communities & Local Government English Indices of Deprivation 2015 - [Index of Multiple Deprivation December 2015 Lookup in England](https://data.gov.uk/dataset/index-of-multiple-deprivation-december-2015-lookup-in-england)

+Office for National Statistics - [Interim Lower Layer Super Output Area 2011 to Ward to LAD May 2018 Lookup in England and Wales](http://geoportal.statistics.gov.uk/datasets/interim-lower-layer-super-output-area-2011-to-ward-to-lad-may-2018-lookup-in-england-and-wales)

+Electoral Commission [Registered Party Database](http://search.electoralcommission.org.uk/Search/Registrations?currentPage=1&rows=10&sort=RegulatedEntityName&order=asc&et=pp&et=ppm&et=tp&register=gb&register=ni&register=none&regStatus=registered&optCols=CampaigningName&optCols=EntityStatusName&optCols=ReferendumName&optCols=DesignationStatusName&optCols=CompanyRegistrationNumber&optCols=FieldingCandidatesInEngland&optCols=FieldingCandidatesInScotland&optCols=FieldingCandidatesInWales&optCols=FieldingCandidatesInEurope&optCols=FieldingCandidatesMinorParty&optCols=ReferendumOutcome)

+Various council websites

## COUNCILLOR POLITICAL AFFILIATION CODING
C = Conservative - Including Independent Conservatives and Conservative and Unionist
L = Labour - Including Independent Labour and Labour and Cooperative
LD = Liberal Democrat - Including Liberal Party
UKIP = United Kingdom Independence Party
G = Green
O = Other - Independents, Residents groups and other political affiliations
NOR = No dominant representation
V = Vacant seat

Due to the large numbers of councillors in the England representation changes over time and can only be considered correct as of 9th September 2018
Although the data has been checked there maybe manual keying errors in this dataset - please let us know if you find an error or have any questions hello@opendatamanchester.org.uk

## Data source licenses
National Statistics data © Crown copyright and database right 2018
[Open Government Licence v3.0](https://www.nationalarchives.gov.uk/doc/open-government-licence/version/3/)
Open Data Manchester data CC-BY
