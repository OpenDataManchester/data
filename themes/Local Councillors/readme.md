# LSOA to Ward Best Fit with Councillors - England

## Overview

This repository contains data linking Lower Layer Super Output Areas (LSOAs) to Electoral Wards in England, along with information on councillors and deprivation indices. The data is available for the years 2023 and 2024.

## Contents

1. LSOA (2021) to Ward (2024) Best Fit with Councillors (2024) - England
2. LSOA (2021) to Ward (2023) Best Fit with Councillors (2023) - England

## Data Description

Each dataset includes:
- Councillor information for each ward in England
- Party affiliation of councillors
- Best fit mapping of LSOAs to Electoral Wards
- Index and rank of relative deprivation for LSOAs (where available)

## Data Sources

- Councillor data: [Open Council Data](http://opencouncildata.co.uk/productsAndDownloads.php)
- Ward to Local Authority District Lookup: Office for National Statistics (ONS)
- LSOA to Electoral Ward Best Fit Lookup: ONS
- English Indices of Deprivation 2019: UK Government

## Features

- Links LSOAs with Electoral Wards using ONS best fit methodology
- Includes deprivation data from the 2019 English Indices of Deprivation
- Provides party affiliation of councillors using Electoral Commission party codes
- Tallies councillors per party in individual wards

## Limitations

- Does not include County Council Electoral Districts
- Some wards may not have associated deprivation data due to:
  1. Lack of LSOA association in the ONS best fit lookup
  2. LSOA updates since the publication of deprivation indices

## Usage Notes

- Party codes are used to tally councillors per party in each ward
- 'Ind/Other' label is used for councillors not affiliated with registered parties
- Best fit mapping is based on population weighted centroids of LSOAs

## Updates

The data is updated annually, shortly after the May elections.

## License



## Contact

hello@opendatamanchester.org.uk
